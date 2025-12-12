// Jamu Stripe Webhook Handler
// Copyright (c) 2025 Jamu Team

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import Stripe from 'https://esm.sh/stripe@13.10.0?target=deno'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0'

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY')!, {
  apiVersion: '2023-10-16',
  httpClient: Stripe.createFetchHttpClient(),
})

serve(async (req) => {
  const signature = req.headers.get('stripe-signature')
  if (!signature) {
    return new Response('No signature', { status: 400 })
  }
  
  const body = await req.text()
  const endpointSecret = Deno.env.get('STRIPE_ENDPOINT_SECRET')!
  
  let event: Stripe.Event
  try {
    event = stripe.webhooks.constructEvent(body, signature, endpointSecret)
  } catch (err) {
    return new Response(`Webhook Error: ${err.message}`, { status: 400 })
  }
  
  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )
  
  switch (event.type) {
    case 'checkout.session.completed': {
      const session = event.data.object as Stripe.Checkout.Session
      
      const { data: user } = await supabase
        .from('profiles')
        .select('id')
        .eq('email', session.customer_email)
        .single()
      
      if (user && session.mode === 'subscription') {
        await supabase
          .from('profiles')
          .update({
            tier: 'pro',
            stripe_customer_id: session.customer,
            stripe_subscription_id: session.subscription,
            tokens_remaining: 500000,
            updated_at: new Date().toISOString()
          })
          .eq('id', user.id)
      }
      break
    }
    
    case 'customer.subscription.deleted': {
      const subscription = event.data.object as Stripe.Subscription
      
      await supabase
        .from('profiles')
        .update({
          tier: 'free',
          tokens_remaining: 10000,
          stripe_subscription_id: null,
          updated_at: new Date().toISOString()
        })
        .eq('stripe_subscription_id', subscription.id)
      break
    }
  }
  
  return new Response(JSON.stringify({ received: true }), {
    headers: { 'Content-Type': 'application/json' }
  })
})

