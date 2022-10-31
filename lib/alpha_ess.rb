require "httparty"
require "digest"

class AlphaEss

    AUTHPREFIX = "al8e4s"
    AUTHCONSTANT = "LS885ZYDA95JVFQKUIUUUV7PQNODZRDZIS4ERREDS0EED8BCWSS"
    AUTHSUFFIX = "ui893ed"

    def initialize(sn = ENV["ess_serial"], u = ENV["ess_username"], p = ENV["ess_password"])
        @serial, @username, @password = sn, u, p
        get_token()
    end

    def get_stics_by_day()
        body = {
            "sn" => @serial,
            "userId" => @serial,
            "szDay" => Time.now.strftime("%Y-%m-%d"),
            "isOEM" => 0,
            "sDate" => Time.now.strftime("%Y-%m-%d")
        }
        url = "https://cloud.alphaess.com/api/Power/SticsByDay"
        res = HTTParty.post(url, headers: header(), body: body.to_json)
        res.parsed_response["data"]
    end

    def get_last_power_data()
        body = {
            "sys_sn" => @serial,
            "noLoading" => true
        }
        url = "https://cloud.alphaess.com/api/ESS/GetLastPowerDataBySN"
        res = HTTParty.post(url, headers: header(), body: body.to_json)
        res.parsed_response["data"]
    end

    def get_stics_by_period(beginDay = Time.now.strftime("%Y-%m-%d"), endDay = Time.now.strftime("%Y-%m-%d"))
        body = {
            "beginDay" => beginDay,
            "endDay" => endDay,
            "tday" => Time.now.strftime("%Y-%m-%d"),
            "isOEM" => 0,
            "SN" => @serial,
            "noLoading" => true
        }
        url = "https://cloud.alphaess.com/api/Power/SticsByPeriod"
        res = HTTParty.post(url, headers: header(), body: body.to_json)
        res.parsed_response["data"]
    end

    def get_custom_use_ess_setting()
        url = "https://cloud.alphaess.com/api/Account/GetCustomUseESSSetting"
        res = HTTParty.get(url, headers: header())
        res.parsed_response["data"]
    end

    def set_custom_use_ess_setting(hash={})
        data = self.get_custom_use_ess_setting
        data.update(hash)
        url = "https://cloud.alphaess.com/api/Account/CustomUseESSSetting"
        res = HTTParty.post(url, headers: header(), body: data.to_json)
    end

    def send_pushover_alarm_by_soc(message, po_user = ENV["po_user"], po_token = ENV["po_token"])
        # po_user: pushover username
        # po_token: pushover token
        body = {
            "user" => po_user,
            "token" => po_token,
            "message" => message
        }
        url = "https://api.pushover.net/1/messages.json"
        res = HTTParty.post(url, headers: {
            "Content-Type" => "application/json;charset=UTF-8"
        }, body: body.to_json)
    end

    private 

    def get_token()
        Dir.mkdir "#{ENV["HOME"]}/.alpha_ess" if ! (Dir.exists?"#{ENV["HOME"]}/.alpha_ess")
        read_token() if File.exists?"#{ENV["HOME"]}/.alpha_ess/token"
        if !(defined?@token_valid_to) or @token_valid_to.to_i < (Time.now.to_i+10)
            create_token()
        end
    end

    def save_token()
        cmd = %(echo "#{@token_valid_to}:#{@token}" > #{ENV["HOME"]}/.alpha_ess/token)
        `#{cmd}`
    end

    def read_token()
        token_valid_to, @token = File.open("#{ENV["HOME"]}/.alpha_ess/token").readline.chop.split(/:/)
        @token_valid_to = token_valid_to.to_i
    end

    def create_token()
        url = "https://cloud.alphaess.com/api/Account/Login"
        body = {
            "username" => @username,
            "password" => @password
        }
        res = HTTParty.post(url, headers: {
            "Accept" => "application/json",
            "Content-Type" => "application/json;charset=UTF-8"
        }.update(secure_header_addon()), body: body.to_json)
        @token = res.parsed_response["data"]["AccessToken"]
        @token_valid_to = Time.now.to_i+36000
        save_token()
    end

    def secure_header_addon()
        # thanks to https://github.com/CharlesGillanders
        t = Time.now.to_i
        { 
            "authtimestamp" => t,
            "authsignature" => "#{AUTHPREFIX}#{Digest::SHA2.new(512).hexdigest("#{AUTHCONSTANT}#{t}")}#{AUTHSUFFIX}"
        }
    end

    def header(hash={})
        get_token()
        {
            "Accept" => "application/json",
            "Content-Type" => "application/json;charset=UTF-8",
            "Authorization" => "Bearer #{@token}"
        }.update(hash).update(secure_header_addon())
    end
end

# some extensions for easier visualise data in irb

module Jsonpretty
    def jp
        # return in json_pretty
        JSON.pretty_generate(self)
    end
    def jpp
        # print in json_pretty
        puts JSON.pretty_generate(self)
    end
end

class Hash
    include Jsonpretty
end

class Array
    include Jsonpretty
end  

