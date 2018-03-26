#!/bin/bash 

expect='which expect'

function hlp () {
echo -ne "\n\t Use $0 -f {FILE_NAME} -c {COMMAND} \n\t where FILE_NAME is *.csv file formatted  as '#(to disable/enable)','hostname','ssh IP / private IP','URL','ssh password(or key_name)','Hosting','','MySQL login','MySQL password','DBname'\n\n"
 exit 0
};

## check usage
if [[ $# -eq 0 ]] ; then
  hlp;
fi

## get config file
while getopts ":hf:c" opt
  do 
    case $opt in
      f) FILE=$OPTARG ;;
      c) CMD=$OPTARG ;;
      h|*) hlp ;;
    esac
done

##check if FILE exists and readable
if [[ ! -r ${FILE} ]] ; then
  echo "Cant't read ${FILE}"
  exit 1
fi


## set cmd (sql) to use
if [[ -z $CMD ]] ; then 
##  CMD='echo "hello, $(whoami)"'
    CMD='show databases;'
fi

## Here's we parse csv

while read -r LINE
  do
   eval $( echo $LINE | awk 'BEGIN { FS=","}; !/^($|[:space:]*#|[:space:]*;|.*IP|.*ip)/ {gsub(/( ?\/ ?)?10(\.[[:digit:]]+){3}( ?\/ ?)?/,"",$3) ;  gsub(/AWS.*/," -i ~/.ssh/AWSServer.id_rsa", $5 ) ; print  "host=\047"$2"\047", "ip="$3, "pass=\047"$5"\047",  "mysqlu=\047"$8"\047", "mysqlp1=\047"$9"\047", "schema=\047"$10"\047" }' )

  if [[ -z $ip ]]; then
     continue
  fi
#geenrate config to dump.php
cat << END > ./dump/config.inc
[database]
driver = mysql
host = localhost
;port = 3306
schema = "$schema"
username = "$mysqlu"
password = "$mysqlp1"
END


/usr/bin/expect << EndMark

if  { "$pass" ne " -i ~/.ssh/AWSServer.id_rsa"} {

 spawn rsync -a ./dump/ root@${ip}:~/dump/
  expect "(yes/no)?" { 
                        send "yes\n"
                        expect "password: "
                        send "$pass\n" 
                } "password:" { 
                        send "$pass\n"
                       }


 spawn ssh -o NumberOfPasswordPrompts=1 -o ConnectTimeout=6 root@$ip 
  expect  "assword:" { send "$pass\n" 
} 

expect "\\# "
send -- " php ~/dump/Dump.php \n"
sleep 1
expect "\\# "

send -- "exit\r"

spawn rsync --remove-source-files -a root@$ip~/dump "./DUMP/${host}/"
  expect  "assword:" { send "$pass\n" 
     }

expect eof
} else { 

#spawn ssh -o NumberOfPasswordPrompts=1 -o ConnectTimeout=6 $pass ubuntu@$ip
# id rsa key has been configured in ~/.ssh/config

 spawn rsync -a ./dump/ ubuntu@$ip:~/dump/
  expect "(yes/no)?" {  send "yes\n"
                }
 spawn ssh -o NumberOfPasswordPrompts=1 -o ConnectTimeout=6 ubuntu@$ip

expect "\\$ "
send -- " php ~/dump/Dump.php \n"
sleep 1
expect "\\$ "
send -- "exit\r"

spawn rsync --remove-source-files -a ubuntu@$ip:~/dump/ "./DUMP/${host}/"

expect eof 
}

EndMark

##regex is used to get rid of headers and commented lines in csv file
##awk -v "cmd=${CMD}" 'BEGIN   {FS = ","} ; !/^($|[:space:]*#|[:space:]*;|.*IP|.*ip)/  { cmd="ssh -l " $2 " " $1" "cmd; print $1 ;print cmd; system(cmd) }' <<<  ${LINE}
##done <<< `grep -vEi "^($| *#| *;|.*IP)" $FILE`

done < "$FILE"

## EOF
