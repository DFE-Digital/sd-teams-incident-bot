# frozen_string_literal: true
require "rails_helper"

RSpec.describe BotResponder do
  let(:activity) do
    {
      "id" => "abc",
      "serviceUrl" => "https://example",
      "channelId" => "msteams",
      "from" => { "id" => "user" },
      "recipient" => { "id" => "bot" },
      "conversation" => { "id" => "conv" }
    }
  end

  describe ".text_reply" do
    it "builds a message with text and correct addresses" do
      msg = described_class.text_reply(activity, "hi")
      expect(msg[:type]).to eq("message")
      expect(msg[:text]).to eq("hi")
      expect(msg[:from]).to eq(activity["recipient"])
      expect(msg[:recipient]).to eq(activity["from"])
      expect(msg[:replyToId]).to eq(activity["id"])
    end
  end

  describe ".card_reply" do
    it "wraps an Adaptive Card attachment" do
      card = { "type" => "AdaptiveCard", "version" => "1.5", "body" => [] }
      msg = described_class.card_reply(activity, card)

      expect(msg[:attachments]).to be_an(Array)
      att = msg[:attachments].first
      expect(att[:contentType]).to eq("application/vnd.microsoft.card.adaptive")
      expect(att[:content]).to eq(card)
    end
  end
end