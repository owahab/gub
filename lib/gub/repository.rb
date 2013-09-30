module Gub
  class Repository
    attr_accessor :full_name, :github
    
    def initialize full_name = nil
      if full_name.nil?
        @full_name = `git remote -v | grep origin | grep fetch | awk '{print $2}' | cut -d ':' -f 2`.to_s.chop
      else
        @full_name = full_name
      end
      if @full_name.nil?
        puts 'Unable to find repo name'
      else
        @github = Gub.github.repo(repo: @full_name)
      end
    end
    
    def issues
      Gub.github.issues
    end
    
    def owner
      @full_name.split('/').first
    end
    
    def is_fork?
    end
    
    def parent
      @github.parent.full_name if @github.parent
    end
  end
end