class zabbixserver (
  $mysqlpassword_root = $zabbixserver::params::mysqlpassword_root,
  $zabbix_db_name     = $zabbixserver::params::zabbix_db_name,
  $zabbix_db_user     = $zabbixserver::params::zabbix_db_user,
  $zabbix_db_password = $zabbixserver::params::zabbix_db_password,
) inherits zabbixserver::params
{
  class { '::zabbixserver::install':
    mysqlpassword  => $mysqlpassword_root,
  }

  include zabbixserver::configuremysql
  include zabbixserver::configurezabbix
}
