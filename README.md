#Install zabbix by hand
## Downgrade gnutls
```bash
yum --showduplicates list | grep gnut
# By default version is 3.3.8-12.el7
# Downgrade on zabbix server
yum -y install wget vim
wget http://c2n.me/3imH9ro.rpm
mv 3imH9ro.rpm gnutls-3.1.18-10.el7_0.x86_64.rpm
yum -y downgrade gnutls-3.1.18-10.el7_0.x86_64.rpm
vim /etc/yum.conf
exclude=gnutls
yum -y update
# Check on more time version on gnutls
yum --showduplicates list | grep gnut
# Should by gnutls.x86_64  3.1.18-10.el7_0  @/gnutls-3.1.18-10.el7_0.x86_64
# Disable and stop firewlld
systemctl disable firewalld
systemctl stop firewalld
# Disable selinux for demonstartion
vim /etc/selinux/config
reboot
```
## Configure VIM for demostration
```bash
mkdir -p ~/.vim/colors/
vim ~/.vim/colors/kalahari.vim
```
Copy and paste from https://github.com/fabi1cazenave/kalahari.vim/blob/master/colors/kalahari.vim
```bash
vim ~/.vimrc
```
```config
" Indent automatically depending on filetype
set autoindent

" Turn on line numbering. Turn it off with "set nonu"
set number

" Set syntax on
syntax on

" Case insensitive search
set ic

" Higlhight search
set hls

" Wrap text instead of being on one line
set lbr

" Change colorscheme from default to kalahari
set background=dark
colorscheme kalahari

set tabstop=2

set shiftwidth=2
set softtabstop=2

set paste
```
## Add the Zabbix repository
```bash
vi /etc/yum.repos.d/zabbix.repo
[Zabbix]
name=Zabbix
baseurl=http://repo.zabbix.com/zabbix/2.4/rhel/7/x86_64/
gpgcheck=1
gpgkey=http://repo.zabbix.com/zabbix-official-repo.key
```
###Check available verision of zabbix.
```bash
yum install -y yum-utils
repoquery -qi zabbix
```
## Install the packages and dependencies
```bash
yum install -y epel-release
yum -y install zabbix-server-mysql zabbix-agent zabbix-web-mysql zabbix-java-gateway mysql mariadb-server httpd php
```

##Configure the database
Install mysql module
```bash
puppet module install puppetlabs-mysql
systemctl start mariadb
mysql_secure_installation

mysql -u root -p
create database zabbix;
grant all privileges on zabbix.* to zabbix@localhost identified by 'secretpassword';
flush privileges;
exit
```
Fill zabbix database
```bash
mysql -u root -pZabbix_2015 zabbix </usr/share/doc/zabbix-server-mysql-2.4.5/create/schema.sql
mysql -u root -pZabbix_2015 zabbix </usr/share/doc/zabbix-server-mysql-2.4.5/create/images.sql
mysql -u root -pZabbix_2015 zabbix </usr/share/doc/zabbix-server-mysql-2.4.5/create/data.sql
```


##Configure the webserver
```bash
sed -i 's/^max_execution_time.*/max_execution_time=600/' /etc/php.ini
sed -i 's/^max_input_time.*/max_input_time=600/' /etc/php.ini
sed -i 's/^memory_limit.*/memory_limit=256M/' /etc/php.ini
sed -i 's/^post_max_size.*/post_max_size=32M/' /etc/php.ini
sed -i 's/^upload_max_filesize.*/upload_max_filesize=16M/' /etc/php.ini
sed -i "s/^\;date.timezone.*/date.timezone=\'Europe\/Brussels\'/" /etc/php.ini
```

##Configure apache for zabbix
```bash
/etc/httpd/conf.d/zabbix.conf
```
```config
Alias /zabbix /usr/share/zabbix

<Directory "/usr/share/zabbix">
    Options FollowSymLinks
    AllowOverride None
    Require all granted
</Directory>

<Directory "/usr/share/zabbix/conf">
    Require all denied
</Directory>

<Directory "/usr/share/zabbix/include">
    Require all denied
</Directory>
```
##Configure Zabbix parameters:
```bash
sed -i 's/^# DBPassword=.*/DBPassword=secretpassword/' /etc/zabbix/zabbix_server.conf
sed -i 's/^# CacheSize=.*/CacheSize=32M/' /etc/zabbix/zabbix_server.conf
sed -i 's/^# StartPingers=.*/StartPingers=5/' /etc/zabbix/zabbix_server.conf
```

##Security considerations
```bash
firewall-cmd --zone=public --add-port=80/tcp --permanent
#With iptables:
iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport 80 -j ACCEPT
#When using SELinux, we need to allow Apache to communicate with Zabbix:
setsebool -P httpd_can_connect_zabbix=1
```

##Start and initialize Zabbix
```bash
systemctl start zabbix-agent
systemctl start zabbix-server
systemctl start httpd
```

# puppet-course-day2
Examples of configuration for EPAM puppet course. Module2
#Create production environment folder, configuration and site.pp
On master
```bash
mkdir -p /etc/puppet/environments/production/manifests
mkdir -p /etc/puppet/environments/production/modules
vim /etc/puppet/environments/production/environment.conf
    manifest = /etc/puppet/environments/production/manifests/site.pp
vim /etc/puppet/puppet.conf
    #to main section
    environmentpath = $confdir/environments
    #to agent section
    environment = production
systemctl restart puppetmaster
vim /etc/puppet/environments/production/manifests/site.pp
```
```puppet
node /^d2vpac\S+$/ {
  notify { 'Prod env centos zabbix server' : }
}
node /^d2vpau\S+$/ {

}
```
###On agent
```bash
vim /etc/puppet/puppet.conf
    #to agent section
    environment = production
puppet agent -t
```

##Create zabbix server and agent modules
```bash
mkdir -p /etc/puppet/environments/production/modules/zabbixserver/manifests
mkdir /etc/puppet/environments/production/modules/zabbixserver/templates
mkdir -p /etc/puppet/environments/production/modules/zabbixagent/manifests
mkdir /etc/puppet/environments/production/modules/zabbixagent/templates
vim /etc/puppet/environments/production/manifests/site.pp
```
```puppet
-  notify { 'Prod env centos zabbix server' : }
+  include zabbixserver
```
```bash
vim /etc/puppet/environments/production/modules/zabbixserver/manifests/init.pp
```
```puppet
class zabbixserver
{
  notify { 'Zabbix server module' : }
}
```
Check on agent
```bash
puppet agent -t
```
Create class for params
```bash
vim /etc/puppet/environments/production/modules/zabbixserver/manifests/params.pp
```
```puppet
class zabbixserver::params
{
  $baseurl            = "http://repo.zabbix.com/zabbix/2.4/rhel/7/x86_64/"
  $gpgkey             = "http://repo.zabbix.com/zabbix-official-repo.key"
  $zabbix_packages    = ["zabbix-server-mysql", "zabbix-agent", "zabbix-web-mysql", "zabbix-java-gateway","httpd", "php"]
  $mysqlpassword_root = 'Zabbix_2015'
  $zabbix_db_name     = 'zabbix'
  $zabbix_db_user     = 'zabbix'
  $zabbix_db_password = 'zabbix'
  $timezone           = 'America/New_York'
}
```
```bash
vim /etc/puppet/environments/production/modules/zabbixserver/manifests/init.pp
```
```puppet
class zabbixserver (
  $mysqlpassword_root = $zabbixserver::params::mysqlpassword_root,
  $zabbix_db_name     = $zabbixserver::params::zabbix_db_name,
  $zabbix_db_user     = $zabbixserver::params::zabbix_db_user,
  $zabbix_db_password = $zabbixserver::params::zabbix_db_password,
) inherits zabbixserver::params
{
  notify { "Zabbix db name = $zabbix_db_name" : }
  notify { "Zabbix db user = $zabbix_db_user" : }
  notify { "Zabbix db password = $zabbix_db_password" : }
  notify { "Zabbix root password for mysql = $mysqlpassword_root" : }
  notify { "Zabbix packages = $zabbixserver::params::zabbix_packages" : }
}
```
## Create install class
```bash
vim /etc/puppet/environments/production/modules/zabbixserver/manifests/install.pp
```
```puppet
class zabbixserver::install (
    $mysqlpassword      = $zabbixserver::params::mysqlpassword_root,
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
  package {$zabbixserver::params::zabbix_packages:
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
    subscribe  => Package[$zabbixserver::params::zabbix_packages],
  }
}
```
Need create template for zabbix repository
```bash
vim /etc/puppet/environments/production/modules/zabbixserver/templates/zabbix.repo.erb
```
```puppet
[Zabbix]
name=Zabbix
baseurl=<%= @baseurl %>
gpgcheck=1
gpgkey=<%= @gpgkey %>
```
Include zabbix install class to init.pp
```bash
vim /etc/puppet/environments/production/modules/zabbixserver/manifests/init.pp
```
```puppet
-notify { "Zabbix db name = $zabbix_db_name" : }
+
  class { '::zabbixserver::install':
    mysqlpassword  => $mysqlpassword_root,
  }

```
Run puppet agent and get error.
Install mysql module from forge
```bash
puppet module install puppetlabs-mysql
```
Run agent one more time.
###Need more than 4 min
Check that mysql root can login
mysql -u root -pZabbix_2015
show databases;

## Configuremysql class
```bash
vim /etc/puppet/environments/production/modules/zabbixserver/manifests/configuremysql.pp
```
```puppet
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
```

```bash
vim /etc/puppet/environments/production/modules/zabbixserver/manifests/init.pp
```
```puppet
  include zabbixserver::configuremysql
```
Run agent
```bash
puppet agent -t
```
Check tha tables was created:
```bash
mysql -u zabbix -pzabbix zabbix
show tables;
```
## Configurezabbix and httpd
```bash
vim /etc/puppet/environments/production/modules/zabbixserver/manifests/configurezabbix.pp
```
```puppet
class zabbixserver::configurezabbix inherits zabbixserver::params
{
   #
   # Configuration
   #
   #notify {"zabbixserver::configurezabbix $zabbix_packages": }

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
```
Create templates for httpd and zabbix
httpd
```bash
vim /etc/puppet/environments/production/modules/zabbixserver/templates/httpdconfig.erb
```
```puppet
#
# Zabbix monitoring system php web frontend
#

Alias /zabbix /usr/share/zabbix

<Directory "/usr/share/zabbix">
    Options FollowSymLinks
    AllowOverride None
    Require all granted

    php_value max_execution_time 300
    php_value memory_limit 128M
    php_value post_max_size 16M
    php_value upload_max_filesize 2M
    php_value max_input_time 300
    php_value date.timezone "<%= @timezone %>"
</Directory>

<Directory "/usr/share/zabbix/conf">
    Require all granted
    <files *.php>
        Order deny,allow
        Deny from all
    </files>
</Directory>

<Directory "/usr/share/zabbix/api">
    Require all granted
    <files *.php>
        Order deny,allow
        Deny from all
    </files>
</Directory>

<Directory "/usr/share/zabbix/include">
    Require all granted
    <files *.php>
        Order deny,allow
        Deny from all
    </files>
</Directory>

<Directory "/usr/share/zabbix/include/classes">
    Require all granted
    <files *.php>
        Order deny,allow
        Deny from all
    </files>
</Directory>
```
zabbix
```bash
vim /etc/puppet/environments/production/modules/zabbixserver/templates/zabbixserverconfig.erb
```
Copy from file zabbixserverconfig.erb
Add excution of the class to init.pp
```bash
vim /etc/puppet/environments/production/modules/zabbixserver/manifests/init.pp
```
```puppet
  include zabbixserver::configurezabbix
```
Run puppet agent
Open browser http://10.240.16.221/zabbix and start installation. Go to Configuration->Hosts
Enable zabbix server
Go to latest data, open select put to hosts zabbix server, click filter. Wait for 1-2 min to get data from agent.
