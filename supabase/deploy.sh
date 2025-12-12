#!/bin/bash
# Jamu Supabase Deployment Script

set -e

echo "Deploying Jamu backend to Supabase..."

# Check if supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    echo "Error: Supabase CLI not installed"
    echo "Install with: brew install supabase/tap/supabase"
    exit 1
fi

# Link to project (run this once)
# supabase link --project-ref your-project-ref

# Push database migrations
echo "📊 Applying database migrations..."
supabase db push

# Deploy edge functions
echo "⚡ Deploying edge functions..."
supabase functions deploy openrouter-proxy
supabase functions deploy stripe-webhook

# Set secrets (you'll need to provide these)
echo "🔐 Setting secrets..."
echo "Run these commands manually with your actual keys:"
echo "  supabase secrets set OPENROUTER_API_KEY=sk-or-..."
echo "  supabase secrets set STRIPE_SECRET_KEY=sk_..."
echo "  supabase secrets set STRIPE_ENDPOINT_SECRET=whsec_..."

echo "✅ Deployment complete!"

