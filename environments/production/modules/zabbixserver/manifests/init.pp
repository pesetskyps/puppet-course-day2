class zabbixserver (
  $mysqlpassword  = 'Zabbix_2015',
  $timezone       = 'America/New_York',
  $zabbix_db_name        = 'zabbix',
  $zabbix_db_user        = 'zabbix',
  $zabbix_db_password    = 'zabbix',
) {
  include zabbixserver::repository
  package {'epel-release':
    ensure => installed,
    require => Class["zabbixserver::repository"],
  }
  $zabbix_packages = ["zabbix-server-mysql", "zabbix-agent", "zabbix-web-mysql", "zabbix-java-gateway","httpd", "php"]
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

  class { '::mysql::server':
    root_password           => $mysqlpassword,
    remove_default_accounts => true,
  }
  mysql::db { "$zabbix_db_name":
      user     => "$zabbix_db_user",
      password => "$zabbix_db_password",
      host     => 'localhost',
      grant    => ['ALL'],
  }
  #
  # Install zabbix databases
  #
  exec { 'mysql -u root -pZabbix_2015 zabbix<  /usr/share/doc/zabbix-server-mysql-2.4.5/create/schema.sql':
    path    => '/usr/bin:/usr/sbin:/bin',
    onlyif  => "mysql -u root -pZabbix_2015 zabbix -e 'SHOW TABLES FROM zabbix' | grep -c acknowledges | grep '0' > /dev/null 2>&1",
    require =>  Mysql::Db["$zabbix_db_name"],
  }
  exec { 'mysql -u root -pZabbix_2015 zabbix<  /usr/share/doc/zabbix-server-mysql-2.4.5/create/images.sql':
    path    => '/usr/bin:/usr/sbin:/bin',
    unless  => "mysql -u root -pZabbix_2015 zabbix -e 'SELECT COUNT(*) FROM images;' | grep -c 0 | grep '0' > /dev/null 2>&1",
    require =>  Exec['mysql -u root -pZabbix_2015 zabbix<  /usr/share/doc/zabbix-server-mysql-2.4.5/create/schema.sql'],
  }
  exec { 'mysql -u root -pZabbix_2015 zabbix<  /usr/share/doc/zabbix-server-mysql-2.4.5/create/data.sql':
    path    => '/usr/bin:/usr/sbin:/bin',
    onlyif  => "mysql -u root -pZabbix_2015 zabbix -e 'SELECT itemid FROM items' | grep -c 100 | grep '0' > /dev/null 2>&1",
    require =>  Exec['mysql -u root -pZabbix_2015 zabbix<  /usr/share/doc/zabbix-server-mysql-2.4.5/create/images.sql'],
   }
   #
   # Configuration
   #
   file { '/etc/httpd/conf.d/zabbix.conf':
        content => template('zabbixserver/httpdconfig.erb'),
        notify  => Service['httpd'],
        require => Package['httpd'],
   }
   file { '/etc/zabbix/zabbix_server.conf':
        content => template('zabbixserver/zabbixserverconfig.erb'),
        notify  => Service['zabbix-server'],
        require => Package[$zabbix_packages],
   }
   # enabling this will fix problem with zabbix server not monitored on dashboard
   exec { 'setsebool httpd_can_network_connect on':
     path   => '/usr/bin:/usr/sbin:/bin',
     onlyif => "/usr/sbin/getsebool -a | grep -c 'httpd_can_network_connect --> off' | grep '1' > /dev/null 2>&1",
    }
# mysql -u root -pEpam_2010 zabbix </usr/share/doc/zabbix-server-mysql-2.4.5/create/data.sql
}
