require 'gub/version'
require 'thor'
require 'terminal-table'
require 'highline'

module Gub
  class CLI < Thor
    include Thor::Actions
    
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
    end
  
    desc 'issue [id]', 'Show a Github issue'
    def issue(id)
      repository = Gub::Repository.new
      issue = repository.issue(id)
      rows = []
      rows << ['Status:', issue.state]
      rows << ['Milestone:', issue.milestone.title]
      rows << ['Author:', issue.user.login]
      rows << ['Assignee:', (issue.assignee.nil? ? '-' : issue.assignee.login)]
      rows << ['Description:', word_wrap(issue.body, line_width: 70)]
      Gub.log.info "Hint: use 'gub start #{id}' to start working on this issue."
      say table rows, ["Issue ##{id}:", issue.title]
    end
    
    desc 'issues', 'List Github issues'
    method_option :all, type: :boolean, aliases: '-a', desc: 'Issues in all repositories'
    method_option :mine, type: :boolean, aliases: '-m', desc: 'Only issues assigned to me'
    def issues
      args = {}
      repository = Gub::Repository.new
      if options.mine
        args[:assignee] = Gub.github.user.login
      end
      if options.all || repository.full_name.nil?
        Gub.log.info "Listing issues assigned to you:"
        issues = Gub.github.user_issues
      else
        if repository.has_issues?
          Gub.log.info "Listing issues for #{repository.full_name}:"
        else
          Gub.log.info "Issues disabled #{repository.full_name}."
          Gub.log.info "Listing issues for #{repository.parent}:"
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
          row << issue.status
          rows << row
        end
        say table rows, ['ID', 'Title', 'Author', 'Assignee', 'Status']
        Gub.log.info "Found #{issues.count} issue(s)."
        Gub.log.info 'Hint: use "gub start" to start working on an issue.'
      end
    end
    
    desc 'start [id]', 'Start working on a Github issue'
    def start id
      if id.nil?
        Gub.log.fatal 'Issue ID required.'
        exit 1
      else
        repository = Repository.new
        Gub.git.sync
        repository.assign_issue id
        Gub.git.checkout('-b', "issue-#{id}")
      end
    end
    
    desc 'finish [id]', 'Finish working on a Github issue'
    def finish id = nil
      id ||= `git rev-parse --abbrev-ref HEAD`.split('-').last.to_s.chop
      if id.nil?
        Gub.log.fatal "Unable to guess issue ID from branch name. You might want to specify it explicitly."
        exit 1
      else
        repository = Repository.new
        Gub.log.info 'Pushing branch...'
        Gub.git.push('origin', "issue-#{id}")
        Gub.log.info "Creating pull-request for issue ##{id}..."
        repository.issue_pull_request(id)
        Gub.git.checkout('master')
      end
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
      repository = Repository.new
      repository.add_upstream
    end
    
    desc 'add_upstream', 'Add repo upstream'
    def add_upstream
      repository = Repository.new
      repository.add_upstream
    end
    
    desc 'sync', 'Synchronize fork with upstream repository'
    def sync
      Gub.log.info 'Synchroizing with upstream...'
      Gub.git.sync
    end
    
    desc 'info', 'Show current respository information'
    def info
      repo = Gub::Repository.new
      say "Github repository: #{repo.full_name}"
      say "Forked from: #{repo.parent}" if repo.parent
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
    
    
    private
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