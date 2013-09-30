require 'logger'

module Gub
  class Logger
    attr_accessor :log
    
    def initialize
      self.log = ::Logger.new(STDOUT)
      if Gub.debug
        self.log.level = ::Logger::DEBUG
      else
        self.log.level = ::Logger::INFO
      end
      self.log.formatter = proc do |severity, datetime, progname, msg|
        if ['INFO'].include?(severity)
          "#{msg}\n"
        elsif ['FATAL'].include?(severity)
            "#{severity}: #{msg}\n"
        else
          "#{severity} #{progname} #{datetime}: #{msg}\n"
        end
      end
    end
    
    def start_debugging
    end
    
    def method_missing meth, *args, &block
      self.log.send(meth, *args, &block)
    end
    
  end
end