# frozen_string_literal: true

module Posabot
  class Config
    attr_accessor :host, :user, :pass, :port, :room

    def initialize
      set_defaults
    end

    def inspect
      "user: <hidden> pass: <hidden> host: #{host} port: #{port}"
    end

    def set_defaults
      if defined?(Rails) == 'constant' && coin_node_config = Rails.application.secrets.fetch(:posabot, false)
        @host      = coin_node_config.fetch(:host)
        @password  = coin_node_config.fetch(:password)
        @username  = coin_node_config.fetch(:username)
        @node_port = coin_node_config.fetch(:port)
        @room = coin_node_config.fetch(:deafult_room)
      elsif !ENV['RABBITMQ_HOST'].nil?
        @host = ENV['RABBITMQ_HOST']
        @port = ENV['RABBITMQ_PORT']
        @user = ENV['RABBITMQ_USERNAME']
        @pass = ENV['RABBITMQ_PASSWORD']
        @room = ENV['DEFAULT_ROOM']
      elsif Pathname.new('.secrets.yml').exist?
        require 'yaml'
        config = YAML::load_file('.secrets.yml')
        @host = config.fetch('rabbitmq_host')
        @port = config.fetch('rabbitmq_port')
        @user = config.fetch('rabbitmq_user')
        @pass = config.fetch('rabbitmq_pass')
        @room = config.fetch('default_room', nil)
      else
        raise 'omg not configured'
      end
    rescue => e
      puts e
    end
  end
end
