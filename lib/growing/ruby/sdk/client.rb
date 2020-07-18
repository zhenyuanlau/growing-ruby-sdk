require 'date'
require 'faraday'
require 'google/protobuf'
require "growing/ruby/sdk/pb/v1/dto/event_pb"
require "growing/ruby/sdk/pb/v1/dto/user_pb"

::Protocol = ::Io::Growing::Tunnel::Protocol

module Growing
  module Ruby
    module Sdk
      class Client
        attr_reader :account_id, :data_source_id, :api_host

        @instance_mutex = Mutex.new

        private_class_method :new

        def initialize(account_id, data_source_id, api_host)
          @account_id = account_id
          @data_source_id = data_source_id
          @api_host = api_host
        end

        def self.instance(account_id, data_source_id, api_host)
          return @instance if @instance
          @instance_mutex.synchronize do
            @instance ||= new(account_id, data_source_id, api_host)
          end
          @instance
        end

        def collect_user(login_user_id, props = {})
          user = ::Protocol::UserDto.new(
            project_key: @account_id,
            data_source_id: @data_source_id,
            user_id: login_user_id,
            gio_id: login_user_id,
            attributes: props,
            timestamp: current_timestamp)
          send("collect_user", ::Protocol::UserDto.encode_json(user))
        end

        def collect_cstm(login_user_id, event_key, props = {}) 
          event = ::Protocol::EventDto.new(
            project_key: @account_id,
            data_source_id: @data_source_id,
            user_id: login_user_id,
            gio_id: login_user_id,
            event_key: event_key,
            attributes: props,
            timestamp: current_timestamp)
          send("collect_cstm", ::Protocol::EventDto.encode_json(event))
        end

        private
        def send(action, data)
          resp = ::Faraday.post(url(action), "[#{data}]", "Content-Type" => "application/json")
          unless resp.success?
            raise Error
          end
          resp.success?
        end

        def url(action)
          "#{@api_host}/projects/#{@account_id}/#{action.gsub('_', '/')}"
        end

        def current_timestamp
          ::DateTime.now.strftime('%Q').to_i
        end
      end
    end
  end
end
