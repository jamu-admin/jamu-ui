# Jamu Backend (Supabase)

Backend services for Jamu authentication and LLM proxy.

## Structure

```
supabase/
├── migrations/
│   └── 001_initial_schema.sql   - Database schema
├── functions/
│   ├── openrouter-proxy/         - LLM API proxy
│   └── stripe-webhook/           - Payment webhooks
└── deploy.sh                     - Deployment script
```

## Setup

1. Create Supabase project at https://supabase.com
2. Install CLI: `brew install supabase/tap/supabase`
3. Link project: `supabase link --project-ref YOUR_REF`
4. Deploy: `./deploy.sh`

## Environment Variables

Set these in Supabase dashboard or via CLI:

```bash
supabase secrets set OPENROUTER_API_KEY=sk-or-...
supabase secrets set STRIPE_SECRET_KEY=sk_...
supabase secrets set STRIPE_ENDPOINT_SECRET=whsec_...
```

## Edge Functions

### openrouter-proxy
- Authenticates requests
- Checks token balance
- Proxies to OpenRouter
- Deducts tokens
- Logs usage

### stripe-webhook  
- Handles payment events
- Updates subscriptions
- Adds/removes tokens

## Database

Tables:
- `profiles` - User data and token balances
- `usage_logs` - LLM request history
- `token_transactions` - Token audit trail

