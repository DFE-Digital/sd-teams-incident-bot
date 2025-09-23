# frozen_string_literal: true
require "rails_helper"

RSpec.describe "Health", type: :request do
  it "returns ok true" do
    get "/api/health"
    expect(response).to have_http_status(:ok)
    expect(parsed).to include("ok" => true)
    expect(parsed).to have_key("time")
  end
end