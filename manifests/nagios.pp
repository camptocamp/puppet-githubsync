class githubsync::nagios {

  include githubsync

  file { "/usr/local/bin/githubsync-mknagioschecks.rb":
    source  => "puppet:///githubsync/githubsync-mknagioschecks.rb",
    mode    => 0755,
    require => File["githubsync.rb"],
  }

  file { "/var/local/run/githubsync/nagios-plugins/":
    ensure => directory,
    owner  => "githubsync",
  }
}
