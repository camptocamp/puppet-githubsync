class githubsync::nagios {

  include githubsync

  file { "/usr/local/bin/githubsync-mknagioschecks.rb":
    source  => "puppet:///modules/githubsync/githubsync-mknagioschecks.rb",
    mode    => 0755,
    require => File["githubsync.rb"],
  }

  file { "/var/local/run/githubsync/nagios-plugins/":
    ensure => directory,
    owner  => "githubsync",
  }

  cron { "update githubsync nagios plugin":
    ensure  => present,
    command => "/usr/local/bin/githubsync-mknagioschecks.rb",
    user    => "githubsync",
    hour    => "*/6",
    minute  => fqdn_rand(60),
    require => [Class["githubsync"], File["/usr/local/bin/githubsync-mknagioschecks.rb"]],
  }

}
