# PMM HOW TO

# PMM Server setup


## Creating the pmm-data Container (for persistent PMM data)
```
docker create    -v /opt/prometheus/data    -v /opt/consul-data    -v /var/lib/mysql    -v /var/lib/grafana -v /srv/nginx  --name pmm-data    percona/pmm-server:latest /bin/true
```

## Creating and Launching the PMM Server Container
```
docker run -d \
   -p 80:80 \
   -p 443:443 \
   --volumes-from pmm-data \
   --name pmm-server \
   --restart always \
   -e SERVER_USER=${PMM_USER} \
   -e SERVER_PASSWORD=${PMM_PASS} \
   -e DISABLE_TELEMETRY=true \
   -e METRICS_RESOLUTION=5s \
   -e METRICS_RETENTION=360h \
   -e QUERIES_RETENTION=15
   percona/pmm-server:latest
```

### backup volumes data
```
 for volume in '/opt/prometheus/data' '/opt/consul-data' '/var/lib/mysql' '/var/lib/grafana'; do backup_file=$(echo ${volume} | sed  's#^/##;s#/#_#g;s#$#.tar#') ; docker run --rm --volumes-from pmm-data -v $(pwd):/backup alpine tar -cvf ${backup_file} ${volume} ; done
```
### restore volumes data
```
for file in 'opt_consul-data.tar' 'opt_prometheus_data.tar' 'var_lib_grafana.tar' 'var_lib_mysql.tar' ; do docker run --rm --volumes-from pmm-data -v $(pwd):/backup  alpine tar -xvf /backup/${file} ; done
```

# PMM Client setup

## Prepare mysql slow log
### Put into [mysqld] section:
```
slow_query_log = 1
slow_query_log_file = /var/log/mysql/mysql-slow.log
log_slow_slave_statements = 1
log_slow_admin_statements = 1
long_query_time = 0.01
```

### Apply the same on runtime
```
SET GLOBAL slow_query_log_file="/var/log/mysql/mysql-slow.log";
SET GLOBAL log_slow_slave_statements =1;
SET GLOBAL log_slow_admin_statements =1;
SET GLOBAL long_query_time = 0.01;
```

### check logrotate config /etc/logrotate.d/mysql-server
```
grep '/var/log/mysql/mysql-slow.log\|/var/log/mysql/\*log' /etc/logrotate.d/mysql-server ; if [[ $? -eq 0 ]] ; then /usr/bin/mysqladmin --defaults-file=/etc/mysql/debian.cnf ping ; else echo NO CONFIG ; fi
```

## Allow PMM in iptables
```
iptables -I INPUT -s 1.2.3.4  -p tcp -m tcp --dport 42000 -j ACCEPT -m comment --comment "PMM General"
iptables -I INPUT -s 1.2.3.4  -p tcp -m tcp --dport 42001 -j ACCEPT -m comment --comment "PMM QAN"
iptables -I INPUT -s 1.2.3.4  -p tcp -m tcp --dport 42002 -j ACCEPT -m comment --comment "PMM MySQL"
iptables -I INPUT -s 1.2.3.4  -p tcp -m tcp --dport 42003 -j ACCEPT -m comment --comment "PMM MongoDB"
iptables -I INPUT -s 1.2.3.4  -p tcp -m tcp --dport 42004 -j ACCEPT -m comment --comment "PMM ProxySQL"
iptables-save > /etc/iptables.rules
```

## Get percona repo and install pmm-client from it
```
wget https://repo.percona.com/apt/percona-release_0.1-4.$(lsb_release -sc)_all.deb
dpkg -i percona-release_0.1-4.$(lsb_release -sc)_all.deb
apt update
apt install -y pmm-client
```

##  configure pmm-client
```
publicip=$(curl -Ls http://www.cpanel.net/myip/)
privateip=$(ip a | awk '/inet/ {print $2}' | awk -F'/' '/^10.0/ {print $1}')

pmm-admin config --server 1.2.3.4 --server-user ${PMM_USER} --server-password ${PMM_PASS} --client-address $publicip --bind-address $privateip --client-name ${Client_Name}
pmm-admin add mysql --create-user --create-user-password ${PMM_MYSQL_PASS} --force

mongo_user=$(awk -F"'" '/^\$dbconfig..mongodb....username/ {print $(NF-1)}' config.inc.php)
mongo_pass=$(egrep '/^\$dbconfig..mongodb....password' config.inc.php | tail -1 | awk -F"'" '{print $(NF-1)}')
mongo_db=$(egrep '/^\$dbconfig..mongodb....db_name' config.inc.php | tail -1 | awk -F"'" '{print $(NF-1)}')
mongo_server=$(egrep '/^\$dbconfig..mongodb....db_server' config.inc.php | tail -1 | awk -F"'" '{print $(NF-1)}' | cut -d'/' -f3-)

pmm-admin add mongodb:metrics --uri mongodb://${mongo_user}:${mongo_pass}@${mongo_server}/${mongo_db}
```
### check configs
```
pmm-admin list
```
### check connection to pmmserver works
```
pmm-admin check-network
```
### get help on pmm-admin
```
pmm-admin --help
```


