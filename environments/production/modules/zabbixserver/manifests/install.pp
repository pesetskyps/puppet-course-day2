class zabbixserver::install (
    $mysqlpassword      = $zabbixserver::params::mysql_password,
  ) inherits zabbixserver::params
{
  # notify {"zabbixserver::install $mysqlpassword": }
  class { '::mysql::server':
    root_password           => $mysqlpassword,
    remove_default_accounts => true,
  }
  file { "zabbixserver-repository":
        path    => "/etc/yum.repos.d/zabbix.repo",
        owner   => 'root',
        group   => 'root',
        mode    => 'go+r,u+rw',
        content => template('zabbixserver/zabbix.repo.erb'),
  }
  package {'epel-release':
    ensure => installed,
    require => File["zabbixserver-repository"],
  }
  package {$zabbix_packages:
    ensure => installed,
    require => [ Package["epel-release"],
                 Package["mariadb-server"]
               ]
  }
  service { 'httpd':
    ensure     => 'running',
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
    subscribe  => Package['httpd', 'php'],
  }
  service { 'zabbix-server':
    ensure     => 'running',
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
    subscribe  => Package[$zabbix_packages],
  }
}