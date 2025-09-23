# frozen_string_literal: true
require "rails_helper"

RSpec.describe "Teams messages", type: :request do
  let(:auth_header) { { "Authorization" => "Bearer fake.token.here" } }

  context "authorization" do
    it "rejects when token is missing" do
      json_post "/api/teams/messages", { type: "message", text: "create" }
      expect(response).to have_http_status(:unauthorized)
    end

    it "rejects when BotAuth says no" do
      allow(BotAuth).to receive(:valid?).and_return(false)
      json_post "/api/teams/messages", { type: "message", text: "create" }, headers: auth_header
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "authorized requests" do
    before { allow(BotAuth).to receive(:valid?).and_return(true) }

    let(:base_activity) do
      {
        "type" => "message",
        "id" => "abc123",
        "serviceUrl" => "https://smba.trafficmanager.net/uk/",
        "channelId" => "msteams",
        "from" => { "id" => "user-id" },
        "recipient" => { "id" => "bot-id" },
        "conversation" => { "id" => "conv-id" }
      }
    end

    it "responds with an Adaptive Card for `create`" do
      activity = base_activity.merge("text" => "create")
      json_post "/api/teams/messages", activity, headers: auth_header

      expect(response).to have_http_status(:ok)
      body = parsed
      expect(body["type"]).to eq("message")
      expect(body["attachments"]).to be_an(Array)
      expect(body["attachments"].first["contentType"]).to eq("application/vnd.microsoft.card.adaptive")

      card = body["attachments"].first["content"]
      expect(card["type"]).to eq("AdaptiveCard")
      # Teams supports up to 1.5; assert we’re not exceeding
      expect(Gem::Version.new(card["version"])).to be <= Gem::Version.new("1.5")
      # Basic fields present
      ids = card.fetch("body").filter_map { |el| el["id"] }
      expect(ids).to include("title", "severity", "assignee", "details")
    end

    it "responds with an Adaptive Card for `list`" do
      activity = base_activity.merge("text" => "list")
      json_post "/api/teams/messages", activity, headers: auth_header

      expect(response).to have_http_status(:ok)
      card = parsed.dig("attachments", 0, "content")
      expect(card).to be_present
      expect(card["body"].map { |b| b["type"] }).to include("FactSet")
    end

    it "falls back to text for unknown commands" do
      activity = base_activity.merge("text" => "hello bot")
      json_post "/api/teams/messages", activity, headers: auth_header

      expect(response).to have_http_status(:ok)
      expect(parsed["text"]).to match(/try `create`|`list`/i)
      expect(parsed["attachments"]).to be_nil
    end

    it "handles invoke submit for create_incident" do
      activity = base_activity.merge(
        "type" => "invoke",
        "value" => { "action" => "create_incident", "title" => "DB outage" }
      )
      json_post "/api/teams/messages", activity, headers: auth_header

      expect(response).to have_http_status(:ok)
      expect(parsed["text"]).to match(/Incident created/i)
    end

    it "returns empty JSON for unhandled activity types" do
      activity = base_activity.merge("type" => "typing")
      json_post "/api/teams/messages", activity, headers: auth_header
      expect(response).to have_http_status(:ok)
      expect(parsed).to eq({})
    end
  end

  context "input errors" do
    before { allow(BotAuth).to receive(:valid?).and_return(true) }

    it "returns 400 on invalid JSON" do
      post "/api/teams/messages", params: "not-json", headers: json_headers.merge(auth_header)
      expect(response).to have_http_status(:bad_request)
      expect(parsed["error"]).to eq("bad_request")
    end
  end
end