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

rm -fr $WORKDIR
git clone $SOURCE $WORKDIR

cd $WORKDIR && \
for module in $(ls modules); do
  git remote add --fetch "${module}-on-github" "git://github.com/camptocamp/puppet-${module}.git"
  git subtree split -P "modules/${module}" --branch "local-${module}"
done
'),
  }

}
