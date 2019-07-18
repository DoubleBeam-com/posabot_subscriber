module Posabot
  class Config
    attr_accessor :host, :username, :password, :port

    def initialize
      set_defaults
    end

    def inspect
      <<~BLOCK
        user: <hidden>
        pass: <hidden>
        host: #{host}
        port: #{port}
      BLOCK
    end

    def set_defaults
      if defined?(Rails) == 'constant' && coin_node_config = Rails.application.secrets.fetch(:posabot, false)
        @host      = coin_node_config.fetch(:host)
        @password  = coin_node_config.fetch(:password)
        @username  = coin_node_config.fetch(:username)
        @node_port = coin_node_config.fetch(:port)
      else
        @host = ENV['RABBITMQ_URL']
        @port = ENV['RABBITMQ_PORT']
        @user = ENV['RABBITMQ_USERNAME']
        @pass = ENV['RABBITMQ_PASSWORD']
      end
    rescue => e
      binding.pry
      puts e
    end
  end
end
