# frozen_string_literal: true

require "date"
require "json"
require "faraday"
require "google/protobuf"
require "growing/ruby/sdk/pb/v1/dto/event_pb"
require "growing/ruby/sdk/pb/v1/dto/user_pb"
require "active_support/core_ext/array/grouping"
require "timers"

::Protocol = ::Io::Growing::Tunnel::Protocol

module Growing
  module Ruby
    module Sdk
      class Client
        attr_reader :account_id, :data_source_id, :api_host, :event_queue

        @instance_mutex = Mutex.new

        private_class_method :new

        def initialize(account_id, data_source_id, api_host)
          @account_id = account_id
          @data_source_id = data_source_id
          @api_host = api_host
          @event_queue = {}
          @timers = Timers::Group.new
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
          @event_queue["collect_user"] ||= []
          @event_queue["collect_user"] << user
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
          @event_queue["collect_cstm"] ||= []
          @event_queue["collect_cstm"] << event
        end

        def send_data
          @event_queue["collect_user"].to_a.in_groups_of(100) do |group|
            user_list = ::Protocol::UserList.new
            group.each do |user|
              user_list["values"] << user
            end
            _send_data("collect_user", JSON.parse(::Protocol::UserList.encode_json(user_list))["values"])
          end
          @event_queue["collect_cstm"].to_a.in_groups_of(100) do |group|
            event_list = ::Protocol::EventList.new
            group.each do |event|
              event_list["values"] << event
            end
            _send_data("collect_cstm", JSON.parse(::Protocol::EventList.encode_json(event_list))["values"])
          end
          @event_queue = {}
        end

        # thread unsafe
        def auto_track
          Thread.new do
            @timers.every(60) { send_data }
            loop { @timers.wait }
          end
        end

        private
          def _send_data(action, data)
            Faraday.post(url(action), "#{data}", "Content-Type" => "application/json")
          rescue
            pp "Error"
          end

          def url(action)
            "#{@api_host}/projects/#{@account_id}/#{action.gsub('_', '/')}"
          end

          def current_timestamp
            ::DateTime.now.strftime("%Q").to_i
          end
      end
    end
  end
end
