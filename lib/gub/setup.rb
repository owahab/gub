require 'thor'

module Gub
  class Setup < Thor
    default_task :setup
    
    desc 'setup', 'Setup Gub for the first time'
    def setup
      say 'Hello', :red
    end
end