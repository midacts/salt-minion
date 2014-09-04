# == Class
#
# salt-minion
#
# == Synopsis
#
# This is the main class for managing salt-minions across a domain with Puppet.
#
# == Author
#
# John McCarthy <midactsmystery@gmail.com>
#
# - http://www.midactstech.blogspot.com -
# - https://www.github.com/Midacts -
#
# == Date
#
# 29th of August, 2014
#
# -- Version 1.0 --
#
class salt-minion {

  define apt::key($keyid, $ensure, $command) {
    case $ensure {
      present: {
        exec { "Import $keyid":
          path        => '/bin:/usr/bin',
          environment => 'HOME=/root',
          command     => "$command",
          user        => 'root',
          group       => 'root',
          unless      => "apt-key list | grep $keyid",
          logoutput   => on_failure,
        }
      }
      absent:  {
        exec { "Remove $keyid":
          path        => '/bin:/usr/bin',
          environment => 'HOME=/root',
          command     => "apt-key del $keyid",
          user        => 'root',
          group       => 'root',
          onlyif      => "apt-key list | grep $keyid",
        }
      }
      default: {
        fail "Invalid 'ensure' value '$ensure' for apt::key"
      }
    }
  }

  case $operatingsystem {
    debian: {

      file { '/etc/apt/sources.list.d/salt.list':
        ensure      => present,
        content     => template('salt-minion/salt.list.erb.deb'),
        owner       => root,
        group       => root,
        mode        => 644,
      }

      apt::key { 'F2AE6AB9':
	ensure	   => present,
	command	   => '/usr/bin/wget -q -O- "http://debian.saltstack.com/debian-salt-team-joehealy.gpg.key" | apt-key add -',
	keyid	   => 'F2AE6AB9',
        subscribe  => File['/etc/apt/sources.list.d/salt.list'],
      }

    }

    ubuntu: {

      file { '/etc/apt/sources.list.d/salt.list':
        ensure      => present,
        content     => template('salt-minion/salt.list.erb.ubu'),
        owner       => root,
        group       => root,
        mode        => 644,
      }

      apt::key { '0E27C0A6':
        ensure     => present,
        command    => '/usr/bin/wget -q -O- "http://keyserver.ubuntu.com:11371/pks/lookup?op=get&search=0x4759FA960E27C0A6" | sudo apt-key add -',
        keyid      => '0E27C0A6',
        subscribe  => File['/etc/apt/sources.list.d/salt.list'],
      }

    }

  }

  exec { 'update':
    command     => '/usr/bin/apt-get update',
    unless      => '/usr/bin/dpkg -l | grep salt-minion',
    before	=> Package['salt-minion'],
  }

  package { 'salt-minion':
    ensure      => latest,
    require	=> Exec['update'],
  }

}

