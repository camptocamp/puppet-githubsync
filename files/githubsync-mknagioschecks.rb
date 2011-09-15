#!/usr/bin/ruby

require 'githubsync'

g = GitHubSync.new("/var/local/run/githubsync/puppetmaster/")

destdir = "/var/local/run/githubsync/nagios-plugins"

g.modules.each do |m|

  File.open("#{destdir}/check-github-module-#{m}.sh", "w") do |file|

    file.print "#!/bin/sh\n\n"

    if g.on_github?(m)
      github_missing = g.missing_on_github(m)
      here_missing   = g.missing_on_local_repo(m)

      if github_missing.length == 0 and here_missing.length == 0
        file.print "echo '#{m}: in sync'\n"
        file.print "exit 0\n"
      else
        file.print "echo '#{m}:"
        file.print " #{github_missing.length} commit(s) missing on github" if github_missing.length != 0
        file.print " #{here_missing.length} commit(s) missing in local repo" if here_missing.length != 0
        file.print "'\nexit 2\n"
      end
    else
      file.print "echo '#{m}: not found on github'\n"
      file.print "exit 1\n"
    end
    file.chmod(0755)
  end
end
