#!/usr/bin/ruby

require 'githubsync'

g = GitHubSync.new("/var/local/run/githubsync/puppetmaster")

modules = $*.empty? ? g.modules : $*

print "Status at: " + Time.new.to_s

modules.sort.each do |m|
  if g.on_github?(m)
    github_missing = g.missing_on_github(m)
    here_missing   = g.missing_on_local_repo(m)

    printf("\n\n%-15s ", m)

    if github_missing.count == 0 and here_missing.count == 0
      print "♡♡♡ in sync"
    else
      print "!!!"
      if github_missing.count != 0
        count = github_missing.count
        head  = g.sha(g.local_head(m))
        print " #{count} commit(s) missing on github (#{head})"
      end
      if here_missing.count != 0
        count = here_missing.count
        head  = g.sha(g.github_head(m))
        print " #{count} commit(s) missing in local repo (#{head})"
      end
      print "\n"; 20.times { print " " }
      print (github_missing + here_missing).collect { |c| c[:author] }.uniq.join(", ")
    end

  else
    printf("\n\n%-15s ??? repository not found on github\n", m)
  end
end

