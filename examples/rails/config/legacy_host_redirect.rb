# Permanently redirect browser requests on retired hostnames to the canonical one.
# Webhook deliveries (POST) and health checks keep working on the old hostname, so
# provider configuration can move independently of the public URL.
class LegacyHostRedirect
  def initialize(app, hosts:, canonical:)
    @app = app
    @hosts = hosts
    @canonical = canonical
  end

  def call(env)
    request = Rack::Request.new(env)
    if @canonical.present? && @hosts.include?(request.host) && (request.get? || request.head?) && request.path != "/up"
      return [301, {"location" => "https://#{@canonical}#{request.fullpath}", "cache-control" => "no-store"}, []]
    end
    @app.call(env)
  end
end
