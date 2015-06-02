class zabbixserver::configurezabbix inherits zabbixserver::params
{
   #
   # Configuration
   #
   notify {"zabbixserver::configurezabbix $zabbix_packages": }
   
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
}