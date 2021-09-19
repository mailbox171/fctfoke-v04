##### globals ##### 

fr-dir="100-fr"
core-dir="200-core"


#IF ENABLE WAF, EXTERNAL LB WLL
#BE REACHABLE ONLY AFTER CONFIGURING
#WEB APPLICATION FIREWALL 
waf_enabled = false


allow_node_port_access = true

allow_worker_ssh_access = true

calico_enabled = true
operator_instance_principal = true

metricserver_enabled = true
