class zabbixserver::rebootlinux {
  # notify { 'zabbixserver::rebootlinux': }
  reboot { 'after':
    apply       => immediately,
  }
}