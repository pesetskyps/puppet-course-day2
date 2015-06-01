node /^vpuppetagentcentos\S+$/ {
  include zabbixserver
}
node /^vpuppetagentubun\S+$/ {
  include zabbixagent
}