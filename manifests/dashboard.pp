class githubsync::dashboard {

  include githubsync

  file { "/usr/local/bin/githubsync-dashboard.rb":
    source  => "puppet:///modules/githubsync/githubsync-dashboard.rb",
    mode    => 0755,
    require => File["githubsync.rb"],
  }

  cron { "update githubsync dashboard":
    ensure  => present,
    command => "(/usr/local/bin/githubsync-dashboard.rb && /bin/echo \"Tip: try running 'githubsync-dashboard.rb <module>'\") > /var/local/run/githubsync/current-status.txt",
    user    => "githubsync",
    hour    => "*/6",
    minute  => fqdn_rand(60),
    require => [Class["githubsync"], File["/usr/local/bin/githubsync-dashboard.rb"]],
  }

  file { "/var/local/run/githubsync/current-status.txt":
    owner  => "githubsync",
    group  => "githubsync",
    mode   => 0644,
    ensure => present,
  }

}
