class zabbixserver::disableselinux {
  # notify { 'zabbixserver::disableselinux': }
  class { 'selinux':
   mode => 'disabled',
  }
}
