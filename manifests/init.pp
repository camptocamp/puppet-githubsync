class githubsync(
  $user = 'githubsync',
) {

  file { '/usr/local/bin/githubsync.sh':
    ensure  => present,
    mode    => '0755',
    content => template('githubsync/githubsync.sh.erb'),
  }

  file { ['/var/local/run/', '/var/local/run/githubsync/']:
    ensure => directory,
    owner  => $user,
  }

  package { 'jgrep':
    ensure   => installed,
    provider => 'gem',
  }

}
