#!/usr/bin/ruby

require 'githubsync'

def printmsg(m, status, msg)
  s = { :insync   => "♡♡♡ in sync",
        :desync   => "!!!",
        :notfound => "??? repo not found on github" }

  unless $*.empty? and status == :insync
    printf("\n\n%-15s %s %s", m, s[status], msg)
  end
end

g = GitHubSync.new("/var/local/run/githubsync/puppetmaster")

modules = $*.empty? ? g.modules : $*

print "\n   @@@ GitHub sync status at: " + Time.new.to_s

modules.sort.each do |m|
  msg = ''

  if g.on_github?(m)
    github_missing = g.missing_on_github(m)
    here_missing   = g.missing_on_local_repo(m)

    if github_missing.length == 0 and here_missing.length == 0
      status = :insync
    else
      status = :desync
      if github_missing.length != 0
        count = github_missing.length
        head  = g.sha(g.local_head(m))
        msg << "#{count} commit(s) missing on github (#{head}) "
      end
      if here_missing.length != 0
        count = here_missing.length
        head  = g.sha(g.github_head(m))
        msg << "#{count} commit(s) missing in local repo (#{head}) "
      end
      msg << "\n"; 20.times { msg << " " }
      msg << (github_missing + here_missing).collect { |c| c[:author] }.uniq.join(", ")
    end

  else
    status = :notfound
  end

  printmsg(m, status, msg)
end

print "\n\n"
