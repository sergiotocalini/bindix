# bindix
Bind Monitoring

This script is part of a monitoring solution that allows to monitor several
services and applications.

For more information about this monitoring solution please check out this post
on my [site](https://sergiotocalini.github.io/project/monitoring).

# Dependencies
Bind has to have the statistics enable to make it work, please add the following options in named.conf:

```
#~ cat named.conf
...
statistics-channels {
        inet 127.0.0.1 port 8653 allow { 127.0.0.1; };
};
...
#~
```

Also we need to enable the statistics in every zone that we want to get stats, please add these options on every zone definition:

```
#~ cat zones.conf
...
zone "example.net" in {
        type master;
        file "master/example.net";
        zone-statistics yes;
};
...
#~
```

## Packages
* ksh
* xmlstarlet

### Debian/Ubuntu
```
#~ sudo apt install ksh xmlstarlet
#~
```

### Red Hat
```
#~ sudo yum install ksh
#~
```

# Deploy
Default variables:

NAME|VALUE
----|-----
BIND_URL|http://localhost:8653/xml

*Note: these variables have to be saved in the config file (bindix.conf) in the same directory than the script.*

## Zabbix
```
#~ git clone https://github.com/sergiotocalini/bindix.git
#~ sudo ./bindix/deploy_zabbix.sh -u "${BIND_URL}"
#~ sudo systemctl restart zabbix-agent
```

*Note: the installation has to be executed on the zabbix agent host and you have to import the template on the zabbix web.*
