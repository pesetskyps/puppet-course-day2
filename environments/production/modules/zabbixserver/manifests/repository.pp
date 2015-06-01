class zabbixserver::repository (
      $baseurl = "http://repo.zabbix.com/zabbix/2.4/rhel/7/x86_64/",
      $gpgkey = "http://repo.zabbix.com/zabbix-official-repo.key")
{
  # notify {"zabbixserver::repository $baseurl === $gpgkey": }
  # $baseurl =
  file { "zabbixserver-repository":
        path    => "/etc/yum.repos.d/zabbix.repo",
        owner   => 'root',
        group   => 'root',
        mode    => 'go+r,u+rw',
        content => template('zabbixserver/zabbix.repo.erb'),
      }
}