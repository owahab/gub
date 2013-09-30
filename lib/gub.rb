require 'yaml'

require 'gub/extensions'
require 'gub/version'
require 'gub/clients/git'
require 'gub/clients/github'
require 'gub/repository'
require 'gub/cli'

module Gub
  def self.config
    @@config
  end
  
  def self.config=
    @@config
  end

  def self.start
    rc = File.expand_path("~/.gubrc")
    if File.exists?(rc)
      @@config = YAML.load_file(rc).symbolize_keys!
    end
    # @@git = Gub::Git.new
    Gub::CLI.start
  end
  
  def self.github
    Gub::Github.new(@@config['token'])
  end
  
  
end