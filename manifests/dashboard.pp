class githubsync::dashboard {

  include githubsync

  file { "/usr/local/bin/githubsync-dashboard.rb":
    source  => "puppet:///modules/githubsync/githubsync-dashboard.rb",
    mode    => 0755,
    require => File["githubsync.rb"],
  }

  cron { "update githubsync dashboard":
    ensure  => present,
    command => "/usr/local/bin/githubsync-update-status.sh > /dev/null 2>&1; /usr/local/bin/githubsync-dashboard.rb > /var/local/run/githubsync/current-status.txt",
    user    => "githubsync",
    hour    => "*/6",
    minute  => ip_to_cron(),
    require => [Class["githubsync"], File["/usr/local/bin/githubsync-dashboard.rb"]],
  }

  file { "/var/local/run/githubsync/current-status.txt":
    owner  => "githubsync",
    group  => "githubsync",
    mode   => 0644,
    ensure => present,
  }

}
