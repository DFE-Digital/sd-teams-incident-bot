# Teams Bot Overview (Rails API)

This document explains how our Microsoft Teams bot integrates with Azure Bot Service and this Rails API to support incident tracking. It includes architecture, message flow, setup, local testing, and troubleshooting.

---

## Table of Contents

1. Architecture at a Glance  
2. End-to-End Message Flow  
3. Controller Logic  
4. Proactive Notifications  
5. Prerequisites  
6. Environment Variables  
7. Local Development  
8. HTTP Testing (curl)  
9. Rails Console Smoke Tests  
10. Security Notes  

---

## Architecture at a Glance

```mermaid
graph LR
    subgraph Teams
      U[Users] --> TEAMS[Microsoft Teams]
    end

    TEAMS --> ABS[Azure Bot Service]

    subgraph Rails App
      C[Api::TeamsController]
      BA[BotAuth]
      BR[BotResponder]
      M[(DB: incidents)]
      PR[TeamsProactive]
    end

    ABS -->|HTTPS POST JWT| C
    C --> BA
    C --> BR
    C --> M
    PR -->|Connector Token| ABS
```

---

## End-to-End Message Flow

```mermaid
sequenceDiagram
    participant U as User (Teams)
    participant T as Microsoft Teams
    participant ABS as Azure Bot Service
    participant R as Rails API (/api/teams/messages)

    U->>T: Types "create"
    T->>ABS: Deliver chat activity
    ABS->>R: POST Activity JSON (Bearer JWT)
    R->>R: BotAuth.valid?(JWT)
    alt JWT valid
        R->>R: Parse activity.type
        R-->>ABS: 200 + Reply activity (Adaptive Card)
        ABS-->>T: Render Adaptive Card
        T-->>U: Create Incident form visible
    else JWT invalid
        R-->>ABS: 401 Unauthorized
        ABS-->>T: Error path
    end
```

---

## Controller Logic

```mermaid
flowchart TD
    A[Receive Activity JSON] --> B{activity.type}
    B -- "message" --> C[text command]
    C -- "create" --> D["Build Create Incident Card"]
    C -- "list" --> E["Build List Incidents Card"]
    C -- other --> F["Build plain text hint"]
    B -- "invoke" --> G{value.action}
    G -- "create_incident" --> H["Persist incident + Confirm text"]
    G -- other --> I["Unsupported action text"]
    B -- otherwise --> J["Return empty JSON"]
    D --> K["200 + Adaptive Card"]
    E --> K
    F --> K
    H --> L["200 + confirmation"]
    I --> L
    J --> M["200 empty JSON"]
```

---

## Proactive Notifications

```mermaid
sequenceDiagram
    participant R as Rails (Model/Job)
    participant TP as TeamsProactive
    participant ABS as Azure Bot Service
    participant T as Microsoft Teams

    R->>R: Incident status changes (after_update)
    R->>TP: TeamsProactive.post_message(ref, text)
    TP->>ABS: POST /conversations/{id}/activities (Connector token)
    ABS->>T: Deliver proactive message
    T->>User: "Incident #123 → Assigned"
```

---

## Prerequisites

- Ruby 3.2+ / 3.3.x  
- Rails (API-only app recommended)  
- PostgreSQL (or preferred DB)  
- ngrok (for local HTTPS tunneling)  
- Azure Bot registration (App ID/Password) and Teams app manifest  

---

## Environment Variables

```
MICROSOFT_APP_ID=00000000-0000-0000-0000-000000000000
MICROSOFT_APP_PASSWORD=super-secret
BOT_OPENID_CONFIG=https://login.botframework.com/v1/.well-known/openidconfiguration
RACK_TIMEOUT_SERVICE_TIMEOUT=12
RAILS_LOG_TO_STDOUT=true
```

---

## Local Development

```bash
bundle install
bin/rails s
ngrok http 3000
curl http://localhost:3000/api/health
```

---

## HTTP Testing (curl)

```bash
# Simulate "create" message
curl -X POST http://localhost:3000/api/teams/messages \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer FAKE" \
  -d '{"type":"message","id":"abc123","serviceUrl":"https://smba.trafficmanager.net/uk/","channelId":"msteams","from":{"id":"user-id"},"recipient":{"id":"bot-id"},"conversation":{"id":"conv-id"},"text":"create"}'

# Simulate invoke submit
curl -X POST http://localhost:3000/api/teams/messages \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer FAKE" \
  -d '{"type":"invoke","id":"abc124","serviceUrl":"https://smba.trafficmanager.net/uk/","channelId":"msteams","from":{"id":"user-id"},"recipient":{"id":"bot-id"},"conversation":{"id":"conv-id"},"value":{"action":"create_incident","title":"Database outage"}}'
```

---

## Rails Console Smoke Tests

```ruby
# 1. Fake activity
activity = {
  "type" => "message",
  "id" => "abc123",
  "serviceUrl" => "https://smba.trafficmanager.net/uk/",
  "channelId" => "msteams",
  "from" => { "id" => "user-id" },
  "recipient" => { "id" => "bot-id" },
  "conversation" => { "id" => "conv-id" },
  "text" => "create"
}

# 2. Build Create Incident card
BotResponder.card_reply(activity, Api::TeamsController.new.send(:create_incident_card))

# 3. Build List Incidents card
BotResponder.card_reply(activity, Api::TeamsController.new.send(:list_incidents_card))

# 4. Simulate invoke submit
invoke_activity = activity.merge(
  "type" => "invoke",
  "value" => { "action" => "create_incident", "title" => "Database outage" }
)
Api::TeamsController.new.send(:handle_invoke, invoke_activity)

# 5. Auth helper
BotAuth.valid?(authorization: "Bearer not-a-real-token", app_id: ENV["MICROSOFT_APP_ID"])
# => false
```

---

## Security Notes

- JWT validation is mandatory outside dev  
- Rate limiting via Rack::Attack  
- Short request timeouts (10–12s)  



