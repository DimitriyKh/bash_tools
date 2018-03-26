#!/bin/bash 

expect='which expect'

function hlp () {

echo -ne "\n\t Use $0 -f {FILE_NAME} -c {COMMAND} \n\t where FILE_NAME is *.csv file formatted  as '#(to disable/enable)','hostname','ssh IP / private IP','URL','ssh password(or key_name)','Hosting','','MySQL login','MySQL password','DBname'\n\t"
 exit 0
};

## check usage
if [[ $# -eq 0 ]] ; then
  hlp;
fi

## get config file
while getopts ":hcf:" opt
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
   eval $( echo $LINE | awk 'BEGIN { FS=","}; !/^($|[:space:]*#|[:space:]*;|.*IP|.*ip)/ {gsub(/( ?\/ ?)?10(\.[[:digit:]]+){3}( ?\/ ?)?/,"",$3) ;  gsub(/AWS.*/," -i ~/.ssh/APIServer.id_rsa", $5 ) ; print  "host=\047"$2"\047", "ip="$3, "pass=\047"$5"\047",  "mysqlu=\047"$8"\047", "mysqlp1=\047"$9"\047", "schema=\047"$10"\047" }' )

  if [[ -z $ip ]]; then
     continue
  fi


/usr/bin/expect - << EndMark

spawn ssh $ip

expect "(yes/no)?" { 
			send "yes\n"
			expect "password: "
			send "$pass\n" 
		} "password:" { 
			send "$pass\n" 
		} "timed out" {
		break 
} 

  
sleep 2

expect "\\$ "
send "mysql -u$mysqlu -p   $schema\r"
expect "assword:"
send --  "$mysqlp\n"
expect ">"
send -- "$CMD \r"

expect ">"
send -- "exit\n"
sleep 2


send -- "exit\r"

expect eof
EndMark

##regex is used to get rid of headers and commented lines in csv file
##awk -v "cmd=${CMD}" 'BEGIN   {FS = ","} ; !/^($|[:space:]*#|[:space:]*;|.*IP|.*ip)/  { cmd="ssh -l " $2 " " $1" "cmd; print $1 ;print cmd; system(cmd) }' <<<  ${LINE}
##done <<< `grep -vEi "^($| *#| *;|.*IP)" $FILE`
done < $FILE

## EOF
