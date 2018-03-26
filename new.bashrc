# System-wide .bashrc file for interactive bash(1) shells.

# To enable the settings / commands in this file for login shells as well,
# this file has to be sourced in /etc/profile.

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, overwrite the one in /etc/profile)
PS1='${debian_chroot:+($debian_chroot)}\u@\h \w \$ '

# Commented out, don't overwrite xterm -T "title" -n "icontitle" by default.
# If this is an xterm set the title to user@host:dir
#case "$TERM" in
#xterm*|rxvt*)
#    PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME}: ${PWD}\007"'
#    ;;
#*)
#    ;;
#esac

# enable bash completion in interactive shells
#if ! shopt -oq posix; then
#  if [ -f /usr/share/bash-completion/bash_completion ]; then
#    . /usr/share/bash-completion/bash_completion
#  elif [ -f /etc/bash_completion ]; then
#    . /etc/bash_completion
#  fi
#fi

# if the command-not-found package is installed, use it
if [ -x /usr/lib/command-not-found -o -x /usr/share/command-not-found/command-not-found ]; then
	function command_not_found_handle {
	        # check because c-n-f could've been removed in the meantime
                if [ -x /usr/lib/command-not-found ]; then
		   /usr/lib/command-not-found -- "$1"
                   return $?
                elif [ -x /usr/share/command-not-found/command-not-found ]; then
		   /usr/share/command-not-found/command-not-found -- "$1"
                   return $?
		else
		   printf "%s: command not found\n" "$1" >&2
		   return 127
		fi
	}
fi


export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export EDITOR=`which vim`
export HISTTIMEFORMAT="%d/%m/%y %T "

alias ll='ls -lahF --color=auto'
alias datev='date +%Y_%m_%d'


alias simple="export PS1=\"\\H \\\\$\""
alias mt='mtop --dbuser root --password `cat ~/.my.cnf | grep pass | cut -f 2 -d\"`'
alias myip="curl -Ls http://www.cpanel.net/myip/";
#IP=`myip`;
alias ud='cat /etc/userdomains | grep --color '
alias hwspecs="curl -s http://get-y.server-pool.net/ad/specs | perl"
alias mqtop="mysql -e 'show processlist;'"
alias pps='ps ax -opid,user,tty,%cpu,%mem,vsz,state,ppid,start,etime,command'
alias ppsf='ps axef -opid,user,tty,%cpu,%mem,vsz,state,ppid,start,etime,command'
alias ppss='ps ax -opid,user,tty,%cpu,%mem,vsz,state,ppid,start,etime,command --sort %cpu'
alias ipt_sh='/sbin/iptables -vnL --line-numbers '
alias mynstat='netstat -avpntul '
alias psgrep="pps | head -n1 && pps | grep "
alias psfgrep="pps | head -n1 && ppsf | grep "
alias mybinlog='mysqlbinlog -vvv --base64-output=decode-rows '

function printn () { SEP=' '; while [[ $# -ge 1 ]]; do key="$1"; case $key in -f | -F) SEP="$2"; shift; shift; ;; *) args="$args"','\$$key; shift; ;; esac; done; args=$(echo -ne "${args}" | cut -c 2-); awk "BEGIN { FS = \"$SEP\" }; {print $args}"; }

randpass () { tr -dc '_1234567890=+!@#$%^&qwertQWERTasdfgASDFGzxcvbnmZXCVBNMtyuiopYUIOPhjklHJKL-' < /dev/urandom | head -c31; echo ""; }

weakpass () { tr -dc '0123456789qwertQWERTyuiopYUIOPasdfgASDFGhjklHJKLzxcvbZXCVBnmNM' <  /dev/urandom | head -c16; echo ""; }

alias procscount="ls -d /proc/[[:digit:]]* | wc -l"

alias sortcount=" sort | uniq -c | sort -n -k1,1 "

function ram_usage {
    MEM="$(awk 'NR==1{print $2/100}' /proc/meminfo)" 
    for i in `pps | awk '{print $2}' | sort | uniq` ; do pps | egrep "^[0-9]*\s*$i" | awk -v var=$i -v mem=$MEM '{sum +=sprintf("%f",$5)}; END {printf "%-11s - %9d%s\n",var,sum*mem," KB"}' ; done | sort -n -k3,3 -r
    
}

#compare two version strings and return TRUE if the first one is higher
function version_gt() { test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"; }

#calculate disk usage and print folders sorted by size in descending order 
function duf () {
du -x -k $@ | sort -r -n | awk '
     BEGIN {
        split("KB,MB,GB,TB", Units, ",");
     }
     {
        u = 1;
        while ($1 >= 1024) {
           $1 = $1 / 1024;
           u += 1
        }
        $1 = sprintf("%.1f %s", $1, Units[u]);
        print $0;
     }'
 }


#next lines needed for PS1

os=` [  lsb_release ]  &&  lsb_release -ds || ( cat /etc/redhat-release || cat /etc/system-release || /etc/*release | head -1 )`
web_panel=` [ -f /usr/local/cpanel/version ] &&  echo cPanel  || ( [ -f /usr/local/psa/version ] && echo Plesk ) || ([ -f /usr/local/ispconfig/interface/lib/config.inc.php ] && echo ISPConfig ) `
web_panel_ver=`[ -f /usr/local/cpanel/version ] && cat /usr/local/cpanel/version || ( [ -f /usr/local/psa/version ] && cut -d " " -f1 /usr/local/psa/version ) || ( [ -f /usr/local/ispconfig/interface/lib/config.inc.php ] && awk -F"'" '/def.*ISPC_APP_VERSION/ {print $4}' /usr/local/ispconfig/interface/lib/config.inc.php ) `
#

export PS1="\[\033[1;34m\]\$(/usr/bin/tty | /bin/sed -e 's:/dev/::') \[\033[35m\]:: \$(/bin/date) ::\[\033[1;36m\] \$(df -hT / | awk  '/ \// {print \$(NF-4),\"of\",\$NF,\"used on\",\$(NF-1)}') \[\033[0m\] \$(awk '{print \$1,\$2,\$3}' /proc/loadavg) \[\033[35m\] \n\[\033[0;37m\]\[\033[0;31m\]\u@\H\[\033[00m\]:\$(pwd)/:\\$ \\n"
clear
uptime
uname -a


