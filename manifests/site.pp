node default {
  case $osfamily {
    'Ubuntu','Debian': {
      notify { 'Debian systems': }
      class { 'apache2' :}
    }
    'RedHat','CentOS': {
      notify { 'RedHat systems': }
      include httpd
      httpd::vhost { 'puppettest1.com':
        name => 'puppettest1.com',
      }

      httpd::vhost { 'puppettest2.com':
        name => 'puppettest2.com'
      }

    }
    default: {
      notify { 'I don\'t know what kind of system you have!': }
    }
  }
}
class httpd {
  service {'httpd':
    ensure => running,
    enable  => manual,
    require => Package['httpd'],
  }
  package {'httpd':
    ensure => installed,
  }
}

class apache2 {
  exec { 'apt-update':
    command => '/usr/bin/apt-get update'
  }
  package { 'apache2':
    require => Exec['apt-update'],
    ensure  => installed,
  }

  service { 'apache2':
    ensure => running,
    enable  => true,
    require => Package['apache2'],
  }
}

define httpd::vhost ($name='puppettest1.com') {
  file {"/etc/httpd/conf.d/$name.conf":
    content => "<VirtualHost *:80>\n\tServerName $name\n\tDocumentRoot /var/www/$name\n</VirtualHost>\n",
    require => Package['httpd'],
    notify => Service['httpd'],
  }
  file {"/var/www/$name":
    ensure => directory,
  }
  file {"/var/www/$name/index.html":
    content => "<html><h1>Hello World! $name </h1></html>\n",
    require => File["/var/www/$name"],
  }
}

# Manage an Apache virtual host on Ubuntu
# define apache::vhost($domain='UNSET',$root='UNSET') {
#   include apache2

#   if $domain == 'UNSET' {
#     $vhost_domain = $name
#   } else {
#     $vhost_domain = $domain
#   }

#   if $root == 'UNSET' {
#     $vhost_root = "/var/www/${name}"
#   } else {
#     $vhost_root = $root
#   }

#   file { "/etc/apache2/sites-available/${vhost_domain}.conf":
#     content => template('apache/vhost.erb'),
#     require => Package['apache2-mpm-prefork'],
#     notify  => Exec["enable-${vhost_domain}-vhost"],
#   }

#   exec { "enable-${vhost_domain}-vhost":
#     command     => "/usr/sbin/a2ensite ${vhost_domain}.conf",
#     require     => File["/etc/apache2/sites-available/${vhost_domain}.conf"],
#     refreshonly => true,
#     notify      => Service['apache2'],
#   }
# }