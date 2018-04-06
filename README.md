# bindix
Zabbix Agent - Bind

# Dependencies
## Packages
* ksh
* xmlstarlet

### Debian/Ubuntu

    #~ sudo apt install ksh xmlstarlet
    #~

### Red Hat

    #~ sudo yum install ksh
    #~

# Deploy
## Zabbix

    #~ git clone https://github.com/sergiotocalini/bindix.git
    #~ sudo ./bindix/deploy_zabbix.sh
    #~ sudo systemctl restart zabbix-agent
    
*Note: the installation has to be executed on the zabbix agent host and you have to import the template on the zabbix web.*
