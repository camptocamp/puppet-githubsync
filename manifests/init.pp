class githubsync {

  file { '/usr/local/bin/githubsync.sh':
    ensure => present,
    mode   => 0755,
    source => 'puppet:///githubsync/githubsync.sh',
  }

  file { ["/var/local/run/", "/var/local/run/githubsync/"]:
    ensure => directory,
    owner  => "githubsync",
  }

  file { "githubsync.rb":
    ensure => absent,
    name => $::operatingsystem ? {
      Debian => "/usr/local/lib/site_ruby/1.8/githubsync.rb",
      RedHat => "/usr/lib/ruby/site_ruby/1.8/githubsync.rb",
    },
  }

  file { "/usr/local/bin/githubsync-update-status.sh":
    ensure => absent,
  }

  cron { "update githubsync dashboard":
    ensure => absent,
    user   => "githubsync",
  }

  cron { "update githubsync nagios plugin":
    ensure => absent,
    user   => "githubsync",
  }

}
