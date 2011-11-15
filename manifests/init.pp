class githubsync {

  package { "ruby-git":
    ensure => present,
    name   => $operatingsystem ? {
      RedHat => "rubygem-git",
      Debian => "libgit-ruby",
    },
  }

  file { "githubsync.rb":
    name => $operatingsystem ? {
      Debian => "/usr/local/lib/site_ruby/1.8/githubsync.rb",
      RedHat => "/usr/lib/ruby/site_ruby/1.8/githubsync.rb",
    },
    source  => "puppet:///githubsync/githubsync.rb",
    require => Package["ruby-git"],
  }

  user { "githubsync":
    ensure => present,
    shell  => "/bin/sh",
    home   => "/var/local/run/githubsync",
  }

  file { "/var/local/run/githubsync/.ssh":
    ensure => directory,
    mode   => 0700,
    owner  => "githubsync",
    group  => "githubsync",
    require => User["githubsync"],
  }

  sshkey { "github.com":
    ensure => present,
    key    => "AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==",
    type   => "ssh-rsa",
    before => File["/usr/local/bin/githubsync-update-status.sh"],
  }

  file { ["/var/local/run/", "/var/local/run/githubsync/"]:
    ensure => directory,
    owner  => "githubsync",
  }

  #TODO: fix this stupid discrepency !
  $sourcedir = $operatingsystem ? {
    RedHat => "/srv/puppetmaster/staging/puppetmaster/",
    Debian => "/srv/puppetmaster/staging/",
  }

  file { "/usr/local/bin/githubsync-update-status.sh":
    ensure  => present,
    mode    => 0755,
    content => inline_template('#!/bin/sh
WORKDIR="/var/local/run/githubsync/puppetmaster"
SOURCE="<%= sourcedir %>"

if [ -e "$WORKDIR" ]; then
  cd "$WORKDIR" && git pull
else
  git clone "$SOURCE" "$WORKDIR"
fi

cd "$WORKDIR" && \
for module in $(ls modules); do
  git branch -D "local-${module}"
  git remote add --fetch "${module}-on-github" "git@github.com:camptocamp/puppet-${module}.git" || git remote update "${module}-on-github"
  /usr/local/bin/git-subtree split -P "modules/${module}" --branch "local-${module}"
done

cd "$WORKDIR" && git config githubsync.timestamp "$(date)"
find "${WORKDIR}/.git/subtree-cache/" -type f -delete
cd "$WORKDIR" && git repack -A -d && git gc --aggressive
'),
  }

}
