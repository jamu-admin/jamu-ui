-- Jamu Database Schema
-- Version: 0.0.1
-- Date: 2025-10-10

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- User profiles table
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT,
    tier TEXT DEFAULT 'free' CHECK (tier IN ('free', 'pro', 'enterprise')),
    tokens_remaining INTEGER DEFAULT 10000,
    tokens_used_total BIGINT DEFAULT 0,
    daily_token_limit INTEGER DEFAULT 10000,
    stripe_customer_id TEXT UNIQUE,
    stripe_subscription_id TEXT,
    stripe_subscription_status TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Usage logs
CREATE TABLE IF NOT EXISTS public.usage_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    timestamp TIMESTAMPTZ DEFAULT NOW(),
    operation_type TEXT NOT NULL CHECK (operation_type IN ('llm_query', 'mcp_call')),
    model TEXT,
    tokens_used INTEGER DEFAULT 0,
    cost_cents INTEGER DEFAULT 0,
    latency_ms INTEGER,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'completed', 'failed')),
    error_message TEXT,
    request_data JSONB,
    response_data JSONB
);

-- Token transactions
CREATE TABLE IF NOT EXISTS public.token_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    transaction_type TEXT NOT NULL CHECK (transaction_type IN ('purchase', 'usage', 'refund', 'grant')),
    amount INTEGER NOT NULL,
    balance_after INTEGER NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_usage_logs_user ON public.usage_logs(user_id, timestamp DESC);
CREATE INDEX idx_token_transactions_user ON public.token_transactions(user_id, created_at DESC);

-- Row Level Security
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.usage_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.token_transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile" ON public.profiles
    FOR ALL USING (auth.uid() = id);

CREATE POLICY "Users can view own usage" ON public.usage_logs
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can view own transactions" ON public.token_transactions
    FOR SELECT USING (auth.uid() = user_id);

-- Token management function
CREATE OR REPLACE FUNCTION public.deduct_tokens(
    p_user_id UUID,
    p_tokens INTEGER,
    p_description TEXT DEFAULT NULL
) RETURNS BOOLEAN 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_current_balance INTEGER;
BEGIN
    SELECT tokens_remaining INTO v_current_balance
    FROM profiles
    WHERE id = p_user_id
    FOR UPDATE;
    
    IF v_current_balance < p_tokens THEN
        RETURN FALSE;
    END IF;
    
    UPDATE profiles
    SET tokens_remaining = tokens_remaining - p_tokens,
        tokens_used_total = tokens_used_total + p_tokens,
        updated_at = NOW()
    WHERE id = p_user_id;
    
    INSERT INTO token_transactions (user_id, transaction_type, amount, balance_after, description)
    VALUES (p_user_id, 'usage', -p_tokens, v_current_balance - p_tokens, p_description);
    
    RETURN TRUE;
END;
$$;

-- Trigger to create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO public.profiles (id, email, full_name)
    VALUES (new.id, new.email, new.raw_user_meta_data->>'full_name');
    RETURN new;
END;
$$;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

