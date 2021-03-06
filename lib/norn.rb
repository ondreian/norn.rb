require "json"
require "rugged"
##
## a scripting layer for Gemstone IV
##
module Norn
  ## never silently fail
  Thread.report_on_exception = true
  Dir[File.dirname(__FILE__) + '/norn/ext/**/*.rb'].each do |file| require file end
  Dir[File.dirname(__FILE__) + '/norn/**/*.rb'].each do |file| require file end
  ##
  ## @brief      generates a non-blocking connection to a game
  ##
  ## @param      args  The arguments
  ##
  def self.connect(port = Norn::Game::PORT, *args)
    Handshake.connect port, *args
  end

  def self.clobber(patt)
    $LOADED_FEATURES
      .select do |path| path =~ /#{patt}/ && path.end_with?(".rb") end
      .each do |stale| load(stale) end
  end
end
