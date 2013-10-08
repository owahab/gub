require 'thor'
require 'terminal-table'
require 'highline'

module Gub
  class CLI < Thor
    include Thor::Actions
    
    trap(:INT) { exit 1 }
    
    default_task :help
    
    desc 'repos', 'List Github repositories'
    def repos
      rows = []
      id = 0
      table = Terminal::Table.new(headings: ['#', 'Repository']) do |t|
        Gub.github.repos.each do |repo|
          id = id.next
          t.add_row [id, repo.full_name]
        end
        Gub.github.orgs.each do |org|
          t.add_separator
          Gub.github.organization_repositories(org.login).each do |repo|
            id = id.next
            t.add_row [id, repo.full_name]
          end
        end
      end
      puts table
    rescue Gub::Unauthorized
      reauthorize
    rescue Gub::Disconnected
      panic 'Unable to connect to Github'
    end
    
    desc 'browse', 'Browse current repository'
    def browse
      repository = Gub::Repository.new(origin_name)
      repository.browse
    end
  
    desc 'issue [id]', 'Show or edit a Github issue'
    method_option :assign, type: :boolean, aliases: '-i', desc: 'Assign the issue'
    method_option :comment, type: :string, aliases: '-m', desc: 'Add a comment to the issue'
    method_option :close, type: :boolean, aliases: '-c', desc: 'Close the issue'
    method_option :reopen, type: :boolean, aliases: '-r', desc: 'Reopen the issue'
    def issue(id)
      repository = Gub::Repository.new(origin_name)
      if options.comment
        repository.issue(id).comment(options.comment)
      elsif options.close
        repository.issue(id).close
      elsif options.assign
        repository.issue(id).assign
      elsif options.reopen
        repository.issue(id).reopen
      else
        issue = repository.issue(id)
        rows = []
        rows << ['Status:', issue.state]
        rows << ['Milestone:', issue.milestone.title]
        rows << ['Author:', issue.user.login]
        rows << ['Assignee:', (issue.assignee.nil? ? '-' : issue.assignee.login)]
        rows << ['Description:', word_wrap(issue.body, line_width: 70)]
        comments = []
        issue.comments.each do |comment|
          comments << [comment.user.login, "On #{comment.updated_at}: #{comment.body}"]
        end
        Gub.log.info "Hint: use 'gub start #{id}' to start working on this issue."
        puts table rows, ["Issue ##{id}:", issue.title]
        puts table comments, ['', 'Comments']
      end
    rescue Gub::Unauthorized
      reauthorize
    rescue Gub::Disconnected
      panic 'Unable to connect to Github'
    end
    
    desc 'issues', 'List Github issues'
    method_option :all, type: :boolean, aliases: '-a', desc: 'Issues in all repositories'
    method_option :mine, type: :boolean, aliases: '-m', desc: 'Only issues assigned to me'
    def issues
      args = {}
      repository = Gub::Repository.new(origin_name)
      if options.all || repository.full_name.nil?
        say "Listing all issues:"
        issues = Gub.github.user_issues
      else
        if options.mine
          args[:assignee] = Gub.github.user.login
        end
        if repository.has_issues?
          say "Listing issues for #{repository.full_name}:"
        else
          say "Issues disabled #{repository.full_name}.", :yellow
          say "Listing issues for #{repository.parent}:"
        end
        issues = repository.issues(args)
      end
      unless issues.nil?
        rows = []
        issues.each do |issue|
          row = []
          row << issue.number
          row << issue.title
          row << issue.user.login
          row << (issue.assignee.nil? ? '' : issue.assignee.login)
          row << issue.state
          rows << row
        end
        say table rows, ['ID', 'Title', 'Author', 'Assignee', 'Status']
        say "Found #{issues.count} issue(s)."
        say 'Hint: use "gub start" to start working on an issue.', :green
      end
    rescue Gub::Unauthorized
      reauthorize
    rescue Gub::Disconnected
      panic 'Unable to connect to Github'
    end
    
    desc 'start [id]', 'Start working on a Github issue'
    def start id
      if id.nil?
        panic 'Issue ID required.'
      else
        repository = Repository.new(origin_name)
        issue = repository.issue(id)
        if repository.branches.include?(issue.branch)
          Gub.git.checkout(issue.branch)
        else
          repository = Repository.new(origin_name)
          repository.sync
          issue.assign
          Gub.git.checkout('-b', issue.branch)
        end
      end
    rescue Gub::Unauthorized
      reauthorize
    rescue Gub::Disconnected
      panic 'Unable to connect to Github'
    end
    
    desc 'finish [id]', 'Finish working on a Github issue'
    def finish id = nil
      id ||= `git rev-parse --abbrev-ref HEAD`.split('-').last.to_s.chop
      if id.nil?
        panic "Unable to guess issue ID from branch name. You might want to specify it explicitly."
      else
        repository = Repository.new(origin_name)
        issue = repository.issue(id)
        say 'Pushing branch...'
        Gub.git.push('origin', issue.branch)
        say "Creating pull-request for issue ##{id}..."
        issue.request_pull
        Gub.git.checkout('master')
      end
    rescue Gub::Unauthorized
      reauthorize
    rescue Gub::Disconnected
      panic 'Unable to connect to Github'
    end
    
    desc 'clone [repo]', 'Clone a Github repository'
    method_option :https, type: :boolean, desc: 'Use HTTPs instead of the default SSH'
    def clone repo
      if options.https
        url = "https://github.com/#{repo}"
      else
        url = "git@github.com:#{repo}"
      end
      Gub.log.info "Cloning from #{url}..."
      Gub.git.clone(url)
      `cd #{repo.split('/').last}`
      repository = Gub::Repository.new(origin_name)
      repository.add_upstream
    rescue Gub::Unauthorized
      reauthorize
    rescue Gub::Disconnected
      panic 'Unable to connect to Github'
    end
    
    desc 'add_upstream', 'Add repo upstream'
    def add_upstream
      repository = Gub::Repository.new(origin_name)
      repository.add_upstream
    rescue Gub::Unauthorized
      reauthorize
    rescue Gub::Disconnected
      panic 'Unable to connect to Github'
    end
    
    desc 'sync', 'Synchronize fork with upstream repository'
    def sync
      Gub.log.info 'Synchroizing with upstream...'
      Gub::Repository.new(origin_name).sync
    rescue Gub::Unauthorized
      reauthorize
    rescue Gub::Disconnected
      panic 'Unable to connect to Github'
    end
    
    desc 'info', 'Show current respository information'
    def info
      repo = Gub::Repository.new(origin_name)
      say "Github repository: #{repo.full_name}"
      say "Forked from: #{repo.parent}" if repo.parent
    rescue Gub::Unauthorized
      reauthorize
    rescue Gub::Disconnected
      panic 'Unable to connect to Github'
    end
    
    desc 'setup', 'Setup Gub for the first time'
    def setup
      unless Gub.config.data && Gub.config.data.has_key?('token')
        hl = HighLine.new
        username = hl.ask 'Github username: '
        password = hl.ask('Github password (we will not store this): ') { |q| q.echo = "*" }
        gh = Gub::Github.new(login: username, password: password)
        token = gh.create_authorization(scopes: [:user, :repo, :gist], note: 'Gub').token
        Gub.config.add('token', token)
      end
    end
    
    desc 'version', 'Show Gub version'
    def version
      say Gub::VERSION
    end
    
    no_commands do
      def reauthorize
        say "Unable to find token. You might need to run 'gub setup'.", :red
      end
      
      def panic message
        say message, :red
        exit 1
      end
    end
    
    private
    def origin_name
      `git remote -v | grep origin | grep fetch | awk '{print $2}' | cut -d ':' -f 2`.to_s
    end
    
    def table rows, header = []
      Terminal::Table.new headings: header, rows: rows
    end
      
    # Source: https://github.com/rails/rails/actionpack/lib/action_view/helpers/text_helper.rb
    def word_wrap(text, options = {})
      line_width = options.fetch(:line_width, 80)
      unless text.nil?
        text.split("\n").collect do |line|
          line.length > line_width ? line.gsub(/(.{1,#{line_width}})(\s+|$)/, "\\1\n").strip : line
        end * "\n"
      end
    end  
  end  
end