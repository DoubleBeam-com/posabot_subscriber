require 'posabot_config'
require 'net/ping'
class PosabotSubscriber
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

  def channel
    @channel ||= client.create_channel
  end

  def broadcast_exchange
    @boradcast_exchange ||= channel.fanout('posabot.broadcast')
  end

  def replay_exchange
    @replay_exchange ||= channel.fanout('posabot.reply')
  end

  def broadcast_queue
    unless @broadcast_queue
      @broadcast_queue  = channel.queue('', exclusive: true)
      @broadcast_queue.bind(broadcast_exchange)
    end
    @broadcast_queue
  end

  def replay_queue
    unless @replay_queue
      @replay_queue = channel.queue('', exclusive: true)
      @replay_queue.bind(replay_exchange)
    end
    @replay_queue
  end

  def post_to_posabot(room: 'laboratory', message: )
    replay_exchange.publish({room: room, message: message})
  end

  def subcribe_to_posabot
    broadcast_queue.subscribe(block: true) do |_ , _ , body|
      yield body
    end
  end

end
