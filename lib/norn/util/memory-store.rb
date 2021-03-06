class MemoryStore
  include Enumerable
  
  attr_reader :name
  
  def initialize(name = self.class.name, initial = Hash.new)
    unless initial.is_a?(Hash)
      raise Exception.new %{
        cannot create a memory store without Hash
        was : #{initial.class.name}"
      }
    end
    @name  = name.to_sym
    @store = initial
    @lock  = Mutex.new
  end

  def access()
    @lock.synchronize do
      yield @store
    end
  end

  def to_json(opts = {})
    @store.to_json(opts)
  end

  def sync(value = {})
    access do
      @store = value
    end
    self
  end

  def put(key, val)
    access do
      @store[key.to_sym] = val
    end
    self
  end

  def merge(other)
    access do
      @store = @store.merge(other)
    end
    self
  end

  def each
    access do |store|
      @store.keys.each do |k|
        yield k, @store[k], @store
      end
    end
  end

  def values
    vals = []
    access do |store|
      vals = store.values
    end
    vals
  end

  def keys
    keys = []
    access do |store|
      keys = store.keys
    end
    keys
  end

  def delete(key)
    access do
      @store.delete(key.to_sym)
    end
    self
  end

  def clear
    access(&:clear)
  end

  def fetch(key=nil, default=nil, &block)
    initial = default
    access do
      if key.nil?
        initial = @store
      else
        initial = @store[key.to_sym].nil? ? default : @store[key.to_sym]
      end
    end
    block.call(initial) if block and initial
    initial
  end

  def method_missing(method, fallback = nil)
    fetch(method, fallback)
  end

  def respond_to_missing?(method, include_private = false)
    @store.has_key?(method) || super
  end

  def to_s
    "<Store:#{@name}:#{fetch}>"
  end
end