require "norn/world/callbacks"

class World
  attr_reader :callbacks,
              :roundtime, :status,
              :room, :hands, :containers,
              :stance, :char, :mind,
              :scars, :injuries, :encumb,
              :spells
              
  def initialize()
    @callbacks  = World::Callbacks.new(self)
    @roundtime  = Roundtime.new
    @status     = Status.new
    @room       = Room.new
    @hands      = Hands.new
    @containers = Containers.new
    @stance     = Stance.new
    @char       = Char.new
    @injuries   = Injuries.new
    @scars      = Scars.new
    @mind       = Mind.new
    @encumb     = Encumb.new
    @spells     = Spells.new
  end

  def context()
    instance_variables.map do |prop|
      instance_variable_get(prop)
    end
  end
end