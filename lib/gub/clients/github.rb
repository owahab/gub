require 'octokit'

module Gub
  class Github
    def initialize token
      Octokit::Client.new(access_token: token)
    end
  end
end