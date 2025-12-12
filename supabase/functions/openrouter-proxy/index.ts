// Jamu OpenRouter Proxy
// Copyright (c) 2025 Jamu Team

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseKey)
    
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: 'No authorization header' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }
    
    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: authError } = await supabase.auth.getUser(token)
    
    if (authError || !user) {
      return new Response(
        JSON.stringify({ error: 'Invalid token' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }
    
    const { data: profile } = await supabase
      .from('profiles')
      .select('tokens_remaining')
      .eq('id', user.id)
      .single()
    
    if (!profile || profile.tokens_remaining <= 0) {
      return new Response(
        JSON.stringify({ error: 'Insufficient tokens' }),
        { status: 402, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }
    
    const body = await req.json()
    const { messages, model = 'anthropic/claude-3.5-sonnet', max_tokens = 4000 } = body
    
    const openRouterKey = Deno.env.get('OPENROUTER_API_KEY')
    const startTime = Date.now()
    
    const response = await fetch('https://openrouter.ai/api/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${openRouterKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ messages, model, max_tokens })
    })
    
    const result = await response.json()
    const tokensUsed = result.usage?.total_tokens || 500
    
    await supabase.rpc('deduct_tokens', {
      p_user_id: user.id,
      p_tokens: tokensUsed,
      p_description: `LLM query: ${model}`
    })
    
    await supabase.from('usage_logs').insert({
      user_id: user.id,
      operation_type: 'llm_query',
      model,
      tokens_used: tokensUsed,
      latency_ms: Date.now() - startTime,
      status: 'completed'
    })
    
    return new Response(
      JSON.stringify({
        ...result,
        _metadata: {
          tokens_used: tokensUsed,
          tokens_remaining: profile.tokens_remaining - tokensUsed
        }
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
    
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})

