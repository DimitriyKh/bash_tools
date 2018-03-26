# One liners,simple scripts, etc


### bad_coll.sh
get list of bad collations from mysql, see sql.tasks and loop_send_mysql_cmd.sh , store it to txt
format it and run bad_coll.sh
```bash
awk '{if ($1 ~ /(panda540|forex)/) print "USE",$1,"; ALTER TABLE",$2,"MODIFY",$3,$4,"CHARACTER SET utf8  COLLATE utf8_general_ci;" ; else print}' bad.collation.txt | grep -v CHARACTER_SET_NAME > bad.collation.fix.txt
awk '{$8="\`"$8"\`"; print}' bad.collation.20170926.fix.txt > bad.collation.20170926.fix.ticks.txt
./bad_coll.sh -f bad.collation.20170926.fix.ticks.txt

```
It will simply join multiple MODIFY statements for one folder into single ALTER command


## EXPECT scripts
### loop_send_mysql_cmd.sh
Runs mysql commands in a loop over servers in csv file

## ssh_loop_opens_mysql_runs_cmd.sh
Do ssh on server, open mysql (with localhost user), and run SQL command in a loop over servers in csv file

### ssh_loop_run_bash_cmd.sh
Do ssh on server and run any commnad in a loop over servers in csv file
for inctance, to reconfigure  pmm-client:
```bash
expect "\\$ "
send -- " sudo -i  \r"
sleep 1 
expect "\\# "
send -- " pmm-admin uninstall \r"
send -- "privateip=\\\$(ip a | awk '/inet/ {print \\\$2}' | awk -F'/' '/^10.0/ {print \\\$1}') \r"
send -- " echo \\\$privateip \r"
send -- " pmm-admin config --server PMM_SERVER_IP  --server-user PMM_SERVER_USER --server-password PMM_SERVER_PASSWORD --bind-address \\\$privateip --client-name  $host\r"
send -- " pmm-admin  add mysql --user $mysqlu  --password $mysqlp --create-user --create-user-password PMM_MYSQL_PASSWORD --force \r"
sleep 1 
expect "\\# "
send -- "exit \r"
expect "\\$ "
send -- "exit\r"
```


### ssh_loop_use_dump_hostname.sh
the same script to copy files to target server, run it and copy back with results.
