module Gub
  class Issue
    attr_accessor :parent, :id, :info
    
    
    def self.all parent, params = {}
      Gub.github.issues(parent params)
    end
    
    def initialize parent, id
      self.parent = parent
      self.id = id
      self.info = Gub.github.issue(self.parent, self.id)
    end
    
    def repository
      Gub::Repository.new(self.parent)
    end
    
    def reopen
      Gub.github.reopen_issue(self.parent, self.id)
    end
    
    def close
      Gub.github.close_issue(self.parent, self.id)
    end
    
    def comment body
      Gub.github.add_comment(self.parent, self.id, body)
    end
    
    def comments
      Gub.github.issue_comments(self.parent, self.id)
    end
    
    def assignee
      self.info[:user]
    end
    
    def assign login = nil
      assignee = login || Gub.github.user.login
      Gub.github.update_issue self.parent, self.id, self.info[:title], self.info[:body], { assignee: assignee }
    end
    
    def branch
      "issue-#{self.id}"
    end
    
    def request_pull
      Gub.github.create_pull_request_for_issue(self.parent, 'master', "#{Gub.current_user}:#{self.branch}", self.id)
    end
  end
end