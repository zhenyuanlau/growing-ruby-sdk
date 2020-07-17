require "growing/ruby/sdk/version"
require "growing/ruby/sdk/pb/messages_pb"
require 'google/protobuf'
require 'faraday'
require 'date'

module Growing
  module Ruby
    module Sdk
      class Error < StandardError; end
      class Client
        attr_reader :account_id
      
        @instance_mutex = Mutex.new
      
        private_class_method :new
      
        def initialize(account_id)
          @account_id = account_id
        end
      
        def self.instance(account_id)
          raise Error if account_id.length != 16 && account_id.length != 32
          return @instance if @instance
          @instance_mutex.synchronize do
            @instance ||= new(account_id)
          end
          @instance
        end
      
        def track(login_user_id, event_key, event_props = {})
          event = ::Io::Growing::Vds::Event.new(t: "cstm", cs1: login_user_id, n: event_key, var: event_props, tm: current_timestamp)
          send(::Io::Growing::Vds::Event.encode_json(event))
        end

        private
        def send(message)
          resp = ::Faraday.post(url, "[#{message}]", "Content-Type" => "application/json")
          unless resp.success?
            raise Error
          end
          resp.success?
        end

        def url
          "https://api.growingio.com/v3/#{@account_id}/s2s/cstm?stm=#{current_timestamp}"
        end

        def current_timestamp
          ::DateTime.now.strftime('%Q').to_i
        end
      end
    end
  end
end
