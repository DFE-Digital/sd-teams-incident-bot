class Rack::Attack
  cache.store = ActiveSupport::Cache::MemoryStore.new # swap for Redis in prod

  # Throttle by IP: 60 reqs / 10s (tune for your load)
  throttle("req/ip", limit: 60, period: 10) { |req| req.ip }

  # Basic safelist for Azure Bot Service IPs if you maintain a list (optional)
  # safelist_ip("abs") { |ip| ABS_IP_RANGES.include?(ip) }
end