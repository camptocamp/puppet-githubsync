#!/usr/bin/ruby

require 'githubsync'
require 'tempfile'

g = GitHubSync.new("/var/local/run/githubsync/puppetmaster/")

destdir = "/var/local/run/githubsync/nagios-plugins"
target  = "#{destdir}/check-github-module-sync.sh"
tmpfile = Tempfile.new("githubsync-nagiosplugin", destdir)

File.open(tmpfile.path, "w") do |file|

  file.print "#!/bin/sh\n\n"

  status = {:ok => [], :warning => [], :critical => []}

  g.modules.each do |m|

      if g.on_github?(m)
        github_missing = g.missing_on_github(m)
        here_missing   = g.missing_on_local_repo(m)

        if github_missing.length == 0 and here_missing.length == 0
          status[:ok] << m
        else
          msg = m
          msg << " +#{github_missing.length} local" if github_missing.length != 0
          msg << " +#{here_missing.length} github" if here_missing.length != 0
          status[:critical] << msg
        end
      else
        status[:warning] << m
      end
  end

  if !status[:critical].empty?
    file.print "/bin/echo '#{status[:critical].length} modules not in sync: #{status[:critical].join(", ")}'\n"
    file.print "exit 2\n"
  elsif !status[:warning].empty?
    file.print "/bin/echo '#{status[:warning].length} modules missing: #{status[:warning].join(", ")}'\n"
    file.print "exit 1\n"
  elsif status[:ok].length == g.modules.length
    file.print "/bin/echo 'all modules in sync with github'\n"
    file.print "exit 0\n"
  else
    file.print "/bin/echo 'something unexpected happened with githubsync'\n"
    file.print "exit 3\n"
  end

end

File.chmod(0755, tmpfile.path)
File.rename(tmpfile.path, target) unless File.zero?(tmpfile.path)
