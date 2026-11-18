require "test_helper"
require_relative "../examples/rails/config/legacy_host_redirect"

class LegacyHostRedirectTest < ActiveSupport::TestCase
  setup do
    inner = ->(_env) { [200, {}, ["app"]] }
    @app = LegacyHostRedirect.new(inner, hosts: ["pay.whoptools.com"], canonical: "pay-rails.whoptools.com")
  end

  def call(method, url)
    @app.call(Rack::MockRequest.env_for(url, method: method))
  end

  test "browser requests on the retired host redirect permanently with path and query" do
    status, headers, = call("GET", "https://pay.whoptools.com/billing?x=1")
    assert_equal 301, status
    assert_equal "https://pay-rails.whoptools.com/billing?x=1", headers["location"]
  end

  test "webhooks, health checks and the canonical host are served in place" do
    assert_equal 200, call("POST", "https://pay.whoptools.com/pay/whop/webhooks").first
    assert_equal 200, call("GET", "https://pay.whoptools.com/up").first
    assert_equal 200, call("GET", "https://pay-rails.whoptools.com/").first
  end
end
