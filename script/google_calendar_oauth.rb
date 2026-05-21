require "bundler/setup"
require "dotenv/load"

require "googleauth"
require "launchy"

scope = "https://www.googleapis.com/auth/calendar.readonly"

client_id = ENV.fetch("GOOGLE_CLIENT_ID")
client_secret = ENV.fetch("GOOGLE_CLIENT_SECRET")

authorizer = Google::Auth::UserAuthorizer.new(
  Google::Auth::ClientId.new(client_id, client_secret),
  scope,
  nil
)

url = authorizer.get_authorization_url(
  base_url: "http://localhost:3000/oauth2callback",
  access_type: "offline",
  prompt: "consent"
)

puts "Opening Google OAuth page..."
Launchy.open(url)

puts
puts "Paste the authorization code here:"
code_input = STDIN.gets

if code_input.nil?
  warn "No authorization code was provided on standard input. Exiting."
  exit 1
end

code = code_input.strip

if code.empty?
  warn "Authorization code cannot be blank. Exiting."
  exit 1
end

credentials = authorizer.get_credentials_from_code(
  code: code,
  base_url: "http://localhost:3000/oauth2callback"
)

puts
puts "GOOGLE_REFRESH_TOKEN=#{credentials.refresh_token}"
