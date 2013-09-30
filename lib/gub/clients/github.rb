require 'octokit'

module Gub
  class Github
    attr_accessor :connection
    
    def initialize opts
      @connection = Octokit::Client.new(opts)
    end
    
    def user
      @connection.user
    end
    
    def method_missing meth, *args, &block
      @connection.send(meth, *args, &block)
    end
  end
end