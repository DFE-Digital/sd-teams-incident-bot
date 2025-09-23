# Incidents Bot (Rails API)

This is a **Rails API** service that integrates with **Microsoft Teams** (via **Azure Bot Service**) to support **incident tracking**.  
It listens for Teams activities, responds with text or Adaptive Cards, and can send proactive notifications when incidents change state.

---

## Features

- Receive chat messages from Teams users  
- JWT validation against Microsoft Bot Framework  
- Respond with Adaptive Cards (create form, incident list)  
- Handle card submissions (`invoke` activities)  
- Store incidents in PostgreSQL  
- Proactively notify conversations when incidents update  

---

## Quick Start

### 1. Setup
```bash
# Install dependencies
bundle install

# Run the server
bin/rails s
```

### 2. Expose via HTTPS
```bash
ngrok http 3000
```

Update your Azure Bot registration **Messaging endpoint** to:  
```
https://<ngrok-id>.ngrok-free.app/api/teams/messages
```

### 3. Health Check
```bash
curl http://localhost:3000/api/health
# => { "ok": true, "time": "..." }
```

---

## Environment Variables

Create `.env` locally (and set secrets in prod):

```
MICROSOFT_APP_ID=00000000-0000-0000-0000-000000000000
MICROSOFT_APP_PASSWORD=super-secret
BOT_OPENID_CONFIG=https://login.botframework.com/v1/.well-known/openidconfiguration
RACK_TIMEOUT_SERVICE_TIMEOUT=12
RAILS_LOG_TO_STDOUT=true
```

---

## Example Requests

### Create Incident (Teams "create" message)
```bash
curl -X POST http://localhost:3000/api/teams/messages \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer FAKE" \
  -d '{"type":"message","text":"create"}'
```

### Invoke Submit (form postback)
```bash
curl -X POST http://localhost:3000/api/teams/messages \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer FAKE" \
  -d '{"type":"invoke","value":{"action":"create_incident","title":"Database outage"}}'
```

---

## Development

- Ruby 3.2+ / 3.3.x  
- Rails (API-only mode)  
- PostgreSQL  
- Recommended editor: VS Code or RubyMine  
- Tests:  
  ```bash
  bundle exec rspec
  ```

---

## Documentation

👉 See [docs/teams-bot-overview.md](docs/teams-bot-overview.md) for:  
- Architecture diagrams  
- Message flow sequences  
- Controller decision logic  
- Proactive notifications  
- Troubleshooting  