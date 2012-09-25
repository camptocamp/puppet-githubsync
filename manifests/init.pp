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
    source  => "puppet:///modules/githubsync/githubsync.rb",
    require => Package["ruby-git"],
  }

  user { "githubsync":
    ensure => present,
    shell  => "/bin/sh",
    home   => "/var/local/run/githubsync",
  }

  sshkey { "github.com":
    ensure => absent,
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
  git remote add --fetch "${module}-on-github" "https://github.com/camptocamp/puppet-${module}.git" || git remote update "${module}-on-github"
  /usr/local/bin/git-subtree split -q -P "modules/${module}" --branch "local-${module}"
done

cd "$WORKDIR" && git config githubsync.timestamp "$(date)"
find "${WORKDIR}/.git/subtree-cache/" -type f -delete
cd "$WORKDIR" && git repack -A -d && git gc --aggressive
'),
  }

  cron { "update githubsync status":
    ensure  => present,
    command => "/usr/local/bin/githubsync-update-status.sh 2>&1 | logger -t githubsync-update-status",
    user    => "githubsync",
    hour    => "*/5",
    minute  => fqdn_rand(60),
    require => File["/usr/local/bin/githubsync-dashboard.rb"],
  }

}
