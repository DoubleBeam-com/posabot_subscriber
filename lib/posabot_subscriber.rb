class PosabotSubscriber
  class << self
    attr_accessor :configuration

    def configure
      configuration ||= Posabot::Config.new
      yield(configuration) if block_given?
      configuration
    end
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
        pass: config.user,
      )
      c.start
      @client = c

      # We only want to accept one un-acked message
      @client.qos :prefetch_count => 1
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
    @reply_exchange ||= channel.fanout('posabot.reply')
  end

  def broadcast_queue
    unless @broadcast_queue
      @broadcast_queue  ||= channel.queue('posabot.broadcast', exclusive: true)
      @broadcast_queue.bind(broadcast_exchange)
    end
    @broadcast_queue
  end

  def replay_queue
    unless @replay_queue
      @replay_queue ||= channel.queue('posabot.reply', exclusive: true)
      @replay_queue.bind(reply_exchange)
    end
    @replay_queue
  end

  def post_to_posabot(room: 'laboratory', message: )
    reply_exchange.publish({room: room, message: message})
  end

  def subcribe_to_posabot
    broadcast_queue.subscribe(block: true) do |_ , _ , body|
      yield body
    end
  end

end
