require 'octokit'
require 'gub/exceptions'

module Gub
  class Github
    attr_accessor :connection
    
    def initialize opts
      @connection = Octokit::Client.new(opts)
    end
    
    def url
      'https://github.com/'
    end
    
    def user
      @connection.user
    end
    
    def method_missing meth, *args, &block
      Gub.log.debug "Running command #{meth} with arguments #{args}"
      @connection.send(meth, *args, &block)
      rescue Octokit::Unauthorized, Octokit::NotFound
        raise Gub::Unauthorized
      rescue Faraday::Error::ConnectionFailed
        raise Gub::Disconnected
    end
  end
end