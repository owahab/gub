module Gub
  class Repository
    attr_accessor :full_name, :info
    
    def initialize full_name
      self.full_name = full_name
      # Strip .git from the name
      self.full_name = self.full_name.split('.').first
      if self.full_name.nil? || self.full_name.empty?
        Gub.log.fatal 'Unable to find repo name'
        exit 1
      else
        Gub.log.debug "Loading information for #{self.full_name}"
        self.info = Gub.github.repo(repo: self.full_name)
      end
    end
    
    def name
      self.full_name.split('/').last
    end
    
    def has_issues?
      self.info.has_issues
    end
    
    def issues params = {}
      issues = []
      issues << Gub.github.issues(self.full_name, params) if self.has_issues?
      issues << Gub.github.issues(self.parent, params)
      issues.flatten!
    end
    
    def issue id, action = :fetch, extra_args = nil
      if self.has_issues?
        name = self.full_name
      else
        name = self.parent
      end
      Gub::Issue.new(name, id)
    end
    
    def owner
      @full_name.split('/').first
    end
    
    def add_upstream
      Gub.git.remote('add', 'upstream', "https://github.com/#{self.parent}")
    end
    
    def is_fork?
      self.info.fork
    end
    
    def parent
      self.info.parent.full_name.split('.').first if self.info.parent
    end
    
    def sync
      Gub.git.sync('upstream')
    end
    
    def branches
      Gub.git.branch()
    end
    
    def browse
      require 'launchy'
      ::Launchy.open("#{Gub.github.url}#{self.full_name}")
    end
  end
end