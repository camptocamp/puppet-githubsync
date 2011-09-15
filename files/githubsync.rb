#!/usr/bin/ruby

require 'rubygems'
require 'git'

class GitHubSync

  def initialize(path)
    raise "invalid path: '#{path}'" unless File.directory? path

    @repodir = path
    @moduledir = "#{@repodir}/modules"
    @git = Git.open(@repodir)

  end

  # retourne true/false si une branche "$module-on-github" existe
  def on_github?(mod)
    @git.branches.remote.collect { |b| b.name }.include? "#{mod}-on-github"
  end

  # retourne les commits d'un module qui sont localement présents et absents de
  # github
  def missing_on_github(mod)
    commits_between(github_head(mod), local_head(mod))
  end

  # retourne les commits d'un module qui sont présents sur github et localement
  # absents
  def missing_on_local_repo(mod)
    commits_between(local_head(mod), github_head(mod))
  end

  # retourne un Array contenant la liste des modules présents dans
  # "puppetmaster/modules"
  def modules
    Dir.entries(@moduledir).delete_if do |d|
      "#{@moduledir}/#{d}".match /\.$/ or
      ! File.directory? "#{@moduledir}/#{d}"
    end
  end

  # retourne le dernier commit local du module
  def local_head(mod)
    @git.gcommit("local-#{mod}")
  end

  # retourne le dernier commit sur github du module
  def github_head(mod)
    @git.gcommit("#{mod}-on-github/master")
  end

  # retourne l'identifiant d'un commit sous une forme raccourcie
  def sha(commit)
    @git.gcommit(commit).sha.slice(0..7)
  end

  # retourne un Array de Hashs contenant les metainfos de chaque commits
  def commits_between(commit1, commit2)
    ret = []
    @git.log.between(commit1, commit2).each do |l|
      ret << {
        :author => l.author.name,
        :email  => l.author.email,
        :msg    => l.message.split("\n")[0],
        :commit => l.sha,
        :date   => l.author.date,
      }
    end
    ret
  end

end

#require 'pp'
#a = GitHubSync.new("/tmp/staging")
#pp a.modules
#pp a.on_github?("augeas")
#pp a.missing_on_local_repo("sudo")
#pp a.missing_on_github("nagios")

