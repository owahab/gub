require 'yaml'

require 'gub/extensions'
require 'gub/version'
require 'gub/clients/git'
require 'gub/clients/github'
require 'gub/repository'
require 'gub/issue'
require 'gub/cli'
require 'gub/config'
require 'gub/logger'

module Gub
  # TODO: Understand the following code
  class << self
    attr_accessor :debug, :log, :config, :git, :github
    
    def start debug
      @debug = debug
      # Initialize log first
      @log = Gub::Logger.new
      # Now load the congiuration
      @config = Gub::Config.new
      # The rest of stuff
      @git = Gub::Git.new
      @github = Gub::Github.new(access_token: self.config.token)
      # Invoke our CLI
      Gub::CLI.start
    end
    
    def current_user
      @github.user.login
    end
  end
end