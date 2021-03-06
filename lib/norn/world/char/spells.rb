module Norn
  class Spells
    attr_reader :active, :known

    def initialize()
      @active   = Hash.new
      @known    = Hash.new
      @prepared = nil
    end

    def prepare(spell)
      @prepared = spell
    end

    def learn(num, spell)
      @known[num] = spell
    end

    def add(name, hours, minutes)
      @active[name] = [hours, minutes]
    end

    def flush!()
      @active.clear
    end
  end
end