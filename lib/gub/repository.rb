module Gub
  class Repository
    attr_accessor :full_name, :info
    
    def initialize full_name = nil
      if full_name.nil?
        self.full_name = `git remote -v | grep origin | grep fetch | awk '{print $2}' | cut -d ':' -f 2`.to_s.chop
      else
        self.full_name = full_name
      end
      if self.full_name.nil? || self.full_name.empty?
        Gub.log.fatal 'Unable to find repo name'
        exit 1
      else
        Gub.log.debug "Loading information for #{self.full_name}"
        @info = Gub.github.repo(repo: self.full_name)
      end
    end
    
    def name
      @full_name.split('/').last
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
    
    def issue id
      if self.has_issues?
        Gub.github.issue(self.full_name, id)
      else
        Gub.github.issue(self.parent, id)
      end
    end
    
    def assign_issue id, login = nil
      issue = self.issue(id)
      assignee = login || Gub.github.user.login
      if self.has_issues?
        name = self.full_name
      else
        name = self.parent
      end
      Gub.github.update_issue name, issue.number, issue.title, issue.body, { assignee: assignee }
    end
    
    def issue_pull_request id
      issue = self.issue(id)
      if self.has_issues?
        repo = self.full_name
      else
        repo = self.parent
      end
      Gub.github.create_pull_request_for_issue(repo, 'master', "#{self.owner}:issue-#{id}", id)
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
      self.info.parent.full_name if self.info.parent
    end
    
    def sync
      Gub.git.sync('upstream')
    end
  end
end