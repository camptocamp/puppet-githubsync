class githubsync {

  file { '/usr/local/bin/githubsync.sh':
    ensure => present,
    mode   => '0755',
    source => 'puppet:///modules/githubsync/githubsync.sh',
  }

  file { ['/var/local/run/', '/var/local/run/githubsync/']:
    ensure => directory,
    owner  => 'githubsync',
  }

  package { 'jgrep':
    ensure   => installed,
    provider => 'gem',
  }

}
