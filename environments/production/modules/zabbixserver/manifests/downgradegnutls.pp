class zabbixserver::downgradegnutls {
  notify { 'zabbixserver::downgradegnutls': }
  $packagenamegutls = "gnutls-3.1.18-10.el7_0.x86_64"
# yum downgrade gnutls-3.1.18-10.el7_0.x86_64.rpm
  file { "/tmp/gnutls-3.1.18-10.el7_0.x86_64.rpm":
      mode   => "o+w,a+r",
      owner  => root,
      group  => root,
      source => "puppet:///modules/zabbixserver/$packagenamegutls.rpm"
  }
  package { "gnutls.x86_64":
    ensure => "absent"
  }
  package { $packagenamegutls:
    source  => "/tmp/$packagenamegutls.rpm",
    require => [ File["/tmp/$packagenamegutls.rpm"],
                 Package["gnutls.x86_64"]
                 ]
  }
}