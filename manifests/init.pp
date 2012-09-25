class githubsync {

  file { '/usr/local/bin/githubsync.sh':
    ensure => present,
    mode   => 0755,
    source => 'puppet:///githubsync/githubsync.sh',
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

  file { "githubsync.rb":
    ensure => absent,
    name => $operatingsystem ? {
      Debian => "/usr/local/lib/site_ruby/1.8/githubsync.rb",
      RedHat => "/usr/lib/ruby/site_ruby/1.8/githubsync.rb",
    },
  }

  file { "/usr/local/bin/githubsync-update-status.sh":
    ensure => absent,
  }

}
