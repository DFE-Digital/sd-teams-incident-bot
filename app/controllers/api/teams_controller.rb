class Api::TeamsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def messages
    @bot_activity_type = request.request_parameters["type"] rescue nil

    unless BotAuth.valid?(authorization: request.headers["Authorization"],
                           app_id: ENV["MICROSOFT_APP_ID"])
      return head :unauthorized
    end

    activity = JSON.parse(request.raw_post)

    case activity["type"]
    when "message"
      render json: handle_message(activity)
    when "invoke" # Adaptive Card Action.Submit
      render json: handle_invoke(activity)
    else
      render json: {}, status: :ok
    end
  rescue JSON::ParserError
    render json: { error: "bad_request" }, status: :bad_request
  end

  private

  def handle_message(act)
    text = (act["text"] || "").strip.downcase

    if text.start_with?("create")
      BotResponder.card_reply(act, create_incident_card)
    elsif text.start_with?("list")
      BotResponder.card_reply(act, list_incidents_card)
    else
      BotResponder.text_reply(act, "Try `create` or `list` to manage incidents.")
    end
  end

  def handle_invoke(act)
    data = act["value"] || {}

    case data["action"]
    when "create_incident"
      # TODO: persist to DB (Incident.create!(...))
      BotResponder.text_reply(act, "✅ Incident created: #{data["title"]}")
    else
      BotResponder.text_reply(act, "Unsupported action.")
    end
  end

  # --- Card builders ---

  def create_incident_card
    {
      "type" => "AdaptiveCard",
      "$schema" => "http://adaptivecards.io/schemas/adaptive-card.json",
      "version" => "1.5",
      "body" => [
        { "type" => "TextBlock", "text" => "🚨 Create New Incident", "size" => "Large", "weight" => "Bolder" },
        { "type" => "Input.Text", "id" => "title", "label" => "Title", "isRequired" => true, "errorMessage" => "Title is required" },
        { "type" => "Input.ChoiceSet", "id" => "severity", "label" => "Severity", "style" => "expanded",
          "choices" => [
            { "title" => "P1 - Critical", "value" => "P1" },
            { "title" => "P2 - High", "value" => "P2" },
            { "title" => "P3 - Medium", "value" => "P3" }
          ], "isRequired" => true, "errorMessage" => "Select a severity"
        },
        { "type" => "Input.Text", "id" => "assignee", "label" => "Assignee", "placeholder" => "e.g. @alice" },
        { "type" => "Input.Text", "id" => "details", "label" => "Details", "isMultiline" => true }
      ],
      "actions" => [
        { "type" => "Action.Submit", "title" => "Create", "data" => { "action" => "create_incident" } }
      ]
    }
  end

  def list_incidents_card
    {
      "type" => "AdaptiveCard",
      "$schema" => "http://adaptivecards.io/schemas/adaptive-card.json",
      "version" => "1.5",
      "body" => [
        { "type" => "TextBlock", "text" => "📋 Open Incidents", "size" => "Large", "weight" => "Bolder" },
        { "type" => "FactSet", "facts" => [
          { "title" => "#101:", "value" => "Database outage (P1, Open)" },
          { "title" => "#102:", "value" => "Login errors (P2, Investigating)" }
        ]}
      ],
      "actions" => [
        { "type" => "Action.Submit", "title" => "Refresh", "data" => { "action" => "list_incidents" } }
      ]
    }
  end
end