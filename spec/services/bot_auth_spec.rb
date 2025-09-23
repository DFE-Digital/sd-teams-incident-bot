# frozen_string_literal: true
require "rails_helper"

RSpec.describe BotAuth do
  it "returns false for missing or malformed header" do
    expect(described_class.valid?(authorization: nil, app_id: "x")).to be(false)
    expect(described_class.valid?(authorization: "Basic abc", app_id: "x")).to be(false)
  end

  it "returns false if JWKS fetch fails" do
    allow(ENV).to receive(:fetch).with("BOT_OPENID_CONFIG").and_return("https://example/openid")
    allow(described_class).to receive(:fetch_json).and_raise(StandardError)
    expect(described_class.valid?(authorization: "Bearer token", app_id: "x")).to be(false)
  end
end