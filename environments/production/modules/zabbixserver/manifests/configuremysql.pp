class zabbixserver::configuremysql inherits zabbixserver
{
  mysql::db { "$zabbix_db_name":
      user     => "$zabbix_db_user",
      password => "$zabbix_db_password",
      host     => 'localhost',
      grant    => ['ALL'],
  }
  #
  # Install zabbix databases
  #
  exec { 'schema.sql':
    path    => '/usr/bin:/usr/sbin:/bin',
    command => "mysql -u $zabbix_db_user -p$zabbix_db_password $zabbix_db_name <  /usr/share/doc/zabbix-server-mysql-2.4.5/create/schema.sql",
    onlyif  => "mysql -u $zabbix_db_user -p$zabbix_db_password $zabbix_db_name -e 'SHOW TABLES FROM $zabbix_db_name' | grep -c acknowledges | grep '0' > /dev/null 2>&1",
    require =>  Mysql::Db["$zabbix_db_name"],
  }
  exec { 'images.sql':
    path    => '/usr/bin:/usr/sbin:/bin',
    command => "mysql -u $zabbix_db_user -p$zabbix_db_password $zabbix_db_name < /usr/share/doc/zabbix-server-mysql-2.4.5/create/images.sql",
    unless  => "mysql -u $zabbix_db_user -p$zabbix_db_password $zabbix_db_name -e 'SELECT COUNT(*) FROM images;' | grep -c 0 | grep '0' > /dev/null 2>&1",
    require =>  Exec['schema.sql'],
  }
  exec { 'data.sql':
    path    => '/usr/bin:/usr/sbin:/bin',
    command => "mysql -u $zabbix_db_user -p$zabbix_db_password $zabbix_db_name <  /usr/share/doc/zabbix-server-mysql-2.4.5/create/data.sql",
    onlyif  => "mysql -u $zabbix_db_user -p$zabbix_db_password $zabbix_db_name -e 'SELECT itemid FROM items' | grep -c 100 | grep '0' > /dev/null 2>&1",
    require =>  Exec['images.sql'],
  }
}