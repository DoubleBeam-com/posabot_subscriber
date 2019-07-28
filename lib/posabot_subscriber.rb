# frozen_string_literal: true

require 'posabot_config'
require 'net/ping'
require 'singleton'

class PosabotSubscriber
  include Singleton
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Posabot::Config.new
    yield(configuration) if block_given?
    configuration
  end

  def config
    @config ||= self.class.configure
  end

  def client
    unless @client
      c = Bunny.new(
        host: config.host,
        port: config.port,
        user: config.user,
        pass: config.pass,
      )
      ping_command = Net::Ping::TCP.new(host=config.host, port=config.port)
      until ping_command.ping?
        puts 'Waiting for rabbitmq to come online'
        sleep 1
      end
      c.start
      @client = c

      # We only want to accept one un-acked message
    end
    @client
  end

  def room
    @room ||= config.room
  end

  def room=(room)
    @room = config.room = room
  end

  def channel
    @channel ||= client.create_channel
  end

  def broadcast_exchange
    @boradcast_exchange ||= channel.fanout('posabot.broadcast')
  end

  def inbox_exchange
    @inbox_exchange ||= channel.fanout('posabot.inbox')
  end

  def broadcast_queue
    unless @broadcast_queue
      @broadcast_queue  = channel.queue('posabot.broadcast', exclusive: true, name: 'broadcast')
      @broadcast_queue.bind(broadcast_exchange)
    end
    @broadcast_queue
  end

  def inbox_queue
    unless @inbox_queue
      @inbox_queue = channel.queue('posabot.inbox', exclusive: true, name: 'inbox')
      @inbox_queue.bind(inbox_exchange)
    end
    @inbox_queue
  end

  def post_to_posabot(room: 'laboratory', message: )
    message_to_send = message || 'no message passed'
    inbox_exchange.publish({room: room, message: message_to_send})
  end

  def subcribe_to_posabot
    broadcast_queue.subscribe(block: true) do |_ , _ , body|
      yield body
    end
  end

end
