class zabbixserver::params
{
  $baseurl            = "http://repo.zabbix.com/zabbix/2.4/rhel/7/x86_64/"
  $gpgkey             = "http://repo.zabbix.com/zabbix-official-repo.key"
  $zabbix_packages    = ["zabbix-server-mysql", "zabbix-agent", "zabbix-web-mysql", "zabbix-java-gateway","httpd", "php"]
  $mysqlpassword      = 'Zabbix_2015'
  $zabbix_db_name     = 'zabbix'
  $zabbix_db_user     = 'zabbix'
  $zabbix_db_password = 'zabbix'
  $timezone           = 'America/New_York'
}