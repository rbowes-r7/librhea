require 'httparty'
require 'uuid'

class LibRhea
  def auth_bypass(base_url)
    puts "Waiting for an administrator to authenticate..."
    loop do
      result = HTTParty.post(
        "#{base_url}/WebApi/Process",
        verify: false,
        headers: {
          'Content-Type': 'application/json',
          'Srtsessionid': '1',
        },
        body: [{
          "Model": "MxDomServerList",
          "Action":"r",
        }].to_json
      )

      if result.success?
        return '1'
      end

      puts "No access yet! Waiting and trying again..."
      sleep 2
    end
  end

  def auth(base_url, username, password)
    result = HTTParty.post(
      "#{base_url}/WebApi/Login",
      verify: false,
      headers: {
        'Content-Type': 'application/json',
      },
      body: {
        "user": username,
        "pass": password,
        "ticket": nil,
        "showEULA": false
      }.to_json
    )

    if !result.success?
      $stderr.puts "Authentication failed with HTTP/#{result.code}:"
      $stderr.puts result.headers
      exit 1
    end

    result = result.parsed_response
    if !result['auth'] || !result['auth']['IsSuccess']
      $stderr.puts "Authentication failed: #{result['auth']['ErrorStr']}"
      exit 1
    end

    return result['auth']['SessionId']
  end

  def initialize(base_url, username, password)
    @base_url = base_url
    if username && password
      @session_id = auth(base_url, username, password)
    else
      @session_id = auth_bypass(base_url)
    end

    uuids_response = HTTParty.post(
      "#{base_url}/WebApi/Process",
      verify: false,
      headers: {
        'Content-Type': 'application/json',
        'Srtsessionid': @session_id,
      },
      body: [{
        "Model": "MxDomServerList",
        "Action":"r",
      }].to_json
    )

    if !uuids_response.success?
      $stderr.puts "Failed to get server UUIDs: HTTP/#{uuids_response.code}"
      $stderr.puts uuids_response.headers
      exit 1
    end

    response = uuids_response.parsed_response.pop
    las_server = response['LasServerInfo']
    server_details = response['ServerList'].pop
    @las_server_name = las_server['ServerName']
    @las_server_guid = las_server['ServerGUID']
    @server_name     = server_details['ServerName']
    @server_guid     = server_details['ServerGUID']
  end

  def create_user(username:, password:, home_dir:)
    uuid = UUID.generate

    result = HTTParty.post(
      "#{@base_url}/WebApi/Process",
      #"http://localhost/WebApi/Process",
      verify: false,
      headers: {
        'Content-Type': 'application/json',
        'Srtsessionid': @session_id,
      },
      body: [{
        "Model": "MxUsrInfoDetail",
        "Action":"t",
        "Data": {
          "UserGUID": uuid,
          "GeneralParams": {
            "NotifyPrefs": "1",
            "HomeDirInherit": 2,
            "FullName": username,
            "HomeDir": home_dir,
          },
          "AuthGUID": @server_guid,
          "IdentParams": {
            "AcctEnabled":1
          },
          "Username": username,
          "Password":password,
          "ConfirmPassword":password,
          "CreateHomeDirNow": 1,
          "AcctParams":{},
        },
        "ServerGUID": @server_guid,
        "Snackbar":true,
        "AuthGUIDs": [@server_guid],
        "Method":"precreate"
      }].to_json
    )
    if !result.success?
      $stderr.puts "Creating user failed with HTTP/#{result.code}:"
      $stderr.puts result.headers
      exit 1
    end

    return uuid
  end

  def delete_user(username:, uuid:)
    puts
    puts "Deleting the user..."
    result = HTTParty.post(
      "#{@base_url}/WebApi/Process",
      verify: false,
      headers: {
        'Content-Type': 'application/json',
        'Srtsessionid': @session_id,
      },
      body: [{
        "Model":"MxSvrUserList",
        "Action":"d",
        "ServerGUID": @server_guid,
        "AuthGUIDS":[@server_guid],
        "Data":{
          "UserList": {
            uuid => {
              "ServerGUID":@server_guid,
              "AuthGUID": @server_guid,
              "UserGUID": uuid,
              "UserName": username,
            }
          }
        },
      }].to_json
    )

    if !result.success?
      $stderr.puts "Deleting user failed with HTTP/#{result.code}:"
      $stderr.puts result.headers
      exit 1
    end
  end

  def read_file(path)
    result = HTTParty.post(
      "#{@base_url}/WebApi/Process",
      verify: false,
      headers: {
        'Content-Type': 'application/json',
        'Srtsessionid': @session_id,
      },
      body: [{
        "Model":"MxUtilFileAction",
        "ServerGUID": @las_server_guid,
        "Action":"l",
        "Data":{
          "action": "d",
          "fileList": [path],
          "domainLogs": true
        }
      }].to_json
    )

    if !result.success?
      $stderr.puts "Reading file failed with HTTP/#{result.code}:"
      $stderr.puts result.headers
      exit 1
    end

    if result.parsed_response.is_a?(Array)
      $stderr.puts "Reading file failed:"
      $stderr.puts result.parsed_response
      exit 1
    end

    return result.parsed_response
  end
end
