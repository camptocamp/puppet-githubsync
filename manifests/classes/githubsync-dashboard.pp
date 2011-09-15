class githubsync::dashboard {

  include githubsync

  file { "/usr/local/bin/githubsync-dashboard.rb":
    source  => "puppet:///githubsync/githubsync-dashboard.rb",
    mode    => 0755,
    require => File["githubsync.rb"],
  }

  cron { "update githubsync dashboard":
    ensure  => present,
    command => "/usr/local/bin/githubsync-update-status.sh 2>&1 > /dev/null; /usr/local/bin/githubsync-dashboard.rb > /var/local/run/githubsync/current-status.txt",
    user    => "githubsync",
    hour    => "*/6",
    minute  => ip_to_cron(),
    require => [Class["githubsync"], File["/usr/local/bin/githubsync-dashboard.rb"]],
  }

}
