# frozen_string_literal: true
require "rails_helper"

RSpec.describe "Rack::Attack", type: :request do
  it "allows regular requests under limit" do
    5.times { get "/api/health" }
    expect(response).to have_http_status(:ok)
  end
end