#!/bin/bash


function hlp () {
echo -ne "\n\t Use $0 -f {FILE_NAME} \n\n" 
 exit 0
};

## check usage
if [[ $# -eq 0 ]] ; then
  hlp;
fi

## get config file
while getopts ":hf:" opt
  do 
    case $opt in
      f) FILE=$OPTARG ;;
      h|*) hlp ;;
    esac
done


##check if FILE exists and readable
if [[ ! -r ${FILE} ]] ; then
  echo "Cant't read ${FILE}"
  exit 1
fi


## I'm too lazy, so used lines count and one more echo to print last line
lines=$( wc -l ${FILE} | awk '{print $1}')
while read -r LINE ; do 

 db=$(echo $LINE | awk '{print $2}' );
 table=$(echo $LINE | awk '{print $6}' );

  
  if [[ -z "$olddb" ]] ; 
    then 
      echo "use $db ; ";
  fi


  if [[ "$oldtable" != "$table" ]] && [[ -n "$oldtable" ]]; 
    then  
      echo "ALTER $oldtable $modify ;"
      unset modify
  fi

  if [[ -z "$modify" ]] ;
    then
      modify=$(echo "$LINE" |  sed -E 's/.*(MODIFY.*);/\1/')
    else
      modify=$modify", "$(echo $LINE | sed -E 's/.*(MODIFY.*);/\1/')
  fi

  if [[ "$olddb" != "$db" ]] && [[ -n "$olddb" ]];
    then
      echo "use $db ;"
  fi

  if [[ "$lines" -eq 1 ]];
    then
      if [[ -z "$olddb" ]] ;
        then 
          echo "use $db ; ";
      fi
    echo "ALTER $table $modify ;"
  fi

 ((lines--))

 oldtable=$table
 olddb=$db

done < "$FILE"

exit 0
