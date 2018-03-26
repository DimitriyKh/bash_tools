#!/bin/bash 


function hlp () {
echo -ne "\n\t Use $0 -f {FILE_NAME} -c {COMMAND} -r \n\t where FILE_NAME is *.csv file formatted  as '#(to disable/enable)','hostname','ssh IP / private IP','URL','ssh password(or key_name)','Hosting','','MySQL login','MySQL password','DBname'\n\t forked from expect script to run it with -r flag to fast select from servers\n\n" 
 exit 0
};

## check usage
if [[ $# -eq 0 ]] ; then
  hlp;
fi

#set default values
RO=0;
dbport=3306
CMD='show databases;'

## get config file
while getopts ":hf:rc:" opt
  do 
    case $opt in
      c) CMD=$OPTARG ;;
      f) FILE=$OPTARG ;;
      r) RO=1 ;;
      h|*) hlp ;;
    esac
done

#ro credentials (going to move it to csv or ARGS as well)
mysqlrou=''
mysqlrop=''

##check if FILE exists and readable
if [[ ! -r ${FILE} ]] ; then
  echo "Cant't read ${FILE}"
  exit 1
fi

## Here's we parse csv

while read -r LINE
  do
   eval $( echo $LINE | awk 'BEGIN { FS=","}; !/^($|[:space:]*#|[:space:]*;|.*IP|.*ip)/ {gsub(/( ?\/ ?)?10(\.[[:digit:]]+){3}( ?\/ ?)?/,"",$3) ;  gsub(/AWS.*/," -i ~/.ssh/AWSServer.id_rsa", $5 ) ; print  "host=\047"$2"\047", "ip="$3, "pass=\047"$5"\047",  "mysqlu=\047"$8"\047", "mysqlp=\047"$9"\047", "schema=\047"$10"\047" }' )

  if [[ -z $ip ]]; then
     continue
  fi

echo "<<<=================== Query on $host / $ip ===================>>>"

  if [[ $RO -eq 0 ]]; then
echo    mysql -h$ip -P$dbport -u$mysqlrou -p$mysqlrop -D $schema -e \' $CMD \'
  else
    mysql -h$ip -P$dbport -u$mysqlrou -p$mysqlrop -D $schema -e " $CMD " 
  fi

unset ip

done < "$FILE" 

## EOF
