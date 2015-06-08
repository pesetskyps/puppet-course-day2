## Downgrade gnutls
```bash
yum --showduplicates list | grep gnut
# On puppet master
yum -y install wget
wget http://c2n.me/3imH9ro.rpm
mv 3imH9ro.rpm gnutls-3.1.18-10.el7_0.x86_64.rpm
yum -y downgrade gnutls-3.1.18-10.el7_0.x86_64.rpm
```
enforcing, permissive, or disabled

# Add the Zabbix repository
```bash
vi /etc/yum.repos.d/zabbix.repo
[Zabbix]
name=Zabbix
baseurl=http://repo.zabbix.com/zabbix/2.4/rhel/7/x86_64/
gpgcheck=1
gpgkey=http://repo.zabbix.com/zabbix-official-repo.key
```
Check available verision of zabbix.
```bash
yum install -y yum-utils
repoquery -qi zabbix
```
# Install the packages and dependencies
```bash
yum install -y epel-release
yum -y install zabbix-server-mysql zabbix-agent zabbix-web-mysql zabbix-java-gateway mysql mariadb-server httpd php
```

#Configure the database
1. Install mysql module
    puppet module install puppetlabs-mysql

systemctl start mariadb
mysql_secure_installation

mysql -u root -p
create database zabbix;
grant all privileges on zabbix.* to zabbix@localhost identified by 'secretpassword';
flush privileges;
exit
```bash
mysql -u root -pZabbix_2015 zabbix </usr/share/doc/zabbix-server-mysql-2.4.5/create/schema.sql
mysql -u root -pZabbix_2015 zabbix </usr/share/doc/zabbix-server-mysql-2.4.5/create/images.sql
mysql -u root -pZabbix_2015 zabbix </usr/share/doc/zabbix-server-mysql-2.4.5/create/data.sql
```
https://github.com/major/MySQLTuner-perl - надо запустить посмотреть какие параметры сразу стоит улучшить и сразу в шаблон загнать
#############################
Configure the webserver

sed -i 's/^max_execution_time.*/max_execution_time=600/' /etc/php.ini
sed -i 's/^max_input_time.*/max_input_time=600/' /etc/php.ini
sed -i 's/^memory_limit.*/memory_limit=256M/' /etc/php.ini
sed -i 's/^post_max_size.*/post_max_size=32M/' /etc/php.ini
sed -i 's/^upload_max_filesize.*/upload_max_filesize=16M/' /etc/php.ini
sed -i "s/^\;date.timezone.*/date.timezone=\'Europe\/Brussels\'/" /etc/php.ini

Конфиг для apache for zabbix /etc/httpd/conf.d/zabbix.conf - поправить
#
# Zabbix monitoring system php web frontend
#

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

######################################
Configure Zabbix parameters:
######################################
sed -i 's/^# DBPassword=.*/DBPassword=secretpassword/' /etc/zabbix/zabbix_server.conf
sed -i 's/^# CacheSize=.*/CacheSize=32M/' /etc/zabbix/zabbix_server.conf
sed -i 's/^# StartPingers=.*/StartPingers=5/' /etc/zabbix/zabbix_server.conf

######################################
Security considerations
######################################

#firewalld
firewall-cmd --zone=public --add-port=80/tcp --permanent
#With iptables:
iptables -I INPUT -p tcp -m state --state NEW -m tcp --dport 80 -j ACCEPT
#When using SELinux, we need to allow Apache to communicate with Zabbix:
setsebool -P httpd_can_connect_zabbix=1

######################################
Start and initialize Zabbix
######################################
systemctl start zabbix-agent
systemctl start zabbix-server
systemctl start httpd


/var/lib/mysql/mysql.sock

=======
# puppet-course-day2
examples of configuration for EPAM puppet course. Module2