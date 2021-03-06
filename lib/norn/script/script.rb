require "cgi"
require "norn/util/memory-store"
require "norn/util/worker"
Dir[File.dirname(__FILE__) + '/../world/**/*.rb'].each do |file| require file end

class Script < Thread
  def self.label(*prefixes)
    "[" + prefixes.flatten.compact.map(&:to_s)
      .join(".")
      .gsub(/\s+/, "") + "]"
  end

  attr_reader :name, :code, :mode, :callbacks, :db_ref, :commands
  attr_accessor :result, :package, :game
  
  def initialize(game, name, mode: :normal, args: [])
    @game      = game
    @name      = name
    @callbacks = []
    @mode      = mode
    @commands  = Commands.new
    @code      = 0
    @start     = Time.now
    script     = self
    game.scripts.register(@name, self)
    super do
      work = Try.new do
        yield self
      end
      @code = 1 if work.failed?
      Try.dump(script, work)
      teardown
    end
  end
  ##
  ## add a callback Object
  ## directly to the parser
  ## so a script can receive
  ## parsed XML
  ##
  def add_callbacks(obj)
    @callbacks << obj
    @game.world.callbacks << obj
  end

  def delete_callbacks(obj)
    @callbacks.delete(obj)
    @game.world.callbacks.delete(obj)
  end

  def raise_cannot_make_db!
    raise Exception.new <<~ERROR
      Exec scripts should not create databases
    ERROR
  end

  def db
    raise_cannot_make_db! if exec?
    return @db_ref unless @db_ref.nil?
    @db_ref = Norn::Storage::DB.open(@name)
    return @db_ref
  end

  def exit_info
    log(%{<script.exit status:#{@code} time:#{self.uptime.as_time}>}) unless silent?
  end

  def teardown
    @callbacks.each do |service|
      delete_callbacks service
    end
    exit_info
  end

  def debug?
    mode == :debug
  end

  def silent?
    mode == :silent
  end

  def exec?
    @package.nil?
  end

  def siblings
    @game.scripts.values.reject do |script|
      script == self
    end
  end

  def ok?
    @code = 0
  end

  def die!
    @code = 1
    teardown
    kill
  end

  def await
    sleep 0.1 while alive?
    @result
  end

  def view(obj, label: nil)
    left_col = Script.label(@name, label)
    escaped  = obj.to_s.gsub(/(<|>&)/) do CGI.escape_html $1 end
    [left_col, escaped].join(" ")
  end
  ##
  ## send a string to a client
  ##
  def safe_log(*lines, label: nil)
    return if @game.nil?
    return if lines.empty?
    @game.clients.each do |client|
      unless client.is_a?(Downstream::Receiver) or client.is_a?(Downstream::Mutator)
        lines.each do |line|
          client.puts view(line, label: label)
        end
      end
    end
  end
  alias_method :safe_write, :safe_log

  def write(*lines)
    return if @game.nil?
    return if lines.empty?
    @game.clients.each do |client|
      unless client.is_a?(Downstream::Receiver) or client.is_a?(Downstream::Mutator)
        lines.each do |line|
          client.puts line
        end
      end
    end
  end

  def put(cmd)
    safe_log %{>#{cmd}}
    @game.write_game_command cmd
  end

  alias_method :log, :safe_log
  alias_method :inspect, :safe_log
  
  def dead?
    !alive?
  end

  def error(message = nil)
    safe_log(message, label: :error) unless message.nil?
    kill
  end

  def exit(message = nil)
    safe_log(message, label: :exit) unless message.nil?
    kill
  end
  
  def keepalive!
    loop do sleep() end
  end

  def to_s
    "<Script:#{@name} @uptime=#{uptime.as_time}>"
  end

  def uptime
    (Time.now - @start).to_i
  end
end