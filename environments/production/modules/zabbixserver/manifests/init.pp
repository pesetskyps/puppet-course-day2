class zabbixserver (
  $mysqlpassword      = $zabbixserver::params::mysql_password,
  $zabbix_db_name     = $zabbixserver::params::zabbix_db_name,
  $zabbix_db_user     = $zabbixserver::params::zabbix_db_user,
  $zabbix_db_password = $zabbixserver::params::zabbix_db_password,
) inherits zabbixserver::params
{
  class { '::zabbixserver::install':
    mysqlpassword  => $mysqlpassword,
  }

  include zabbixserver::configuremysql
  include zabbixserver::configurezabbix
}
