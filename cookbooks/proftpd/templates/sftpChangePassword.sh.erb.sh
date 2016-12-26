#!/bin/sh
 
SFTP_HOME='/sftp/home'
SFTP_BASE='/opt/proftpd'
SFTP_PASSWD_FILE="${SFTP_BASE}/etc/sftpd.passwd"
SFTP_GROUP_FILE="${SFTP_BASE}/etc/sftpd.group"
SFTP_ACCOUNT_FILE="${SFTP_BASE}/etc/<prefix>_accounts.txt"
FTPASSWD_CMD='/opt/proftpd/bin/ftpasswd'
 
function notfound {
 CMD=${1}
 MSG=${2}
 RETVAL=${3}
 echo -e "${CMD} is required but cannot be found:\n${MSG}"
 exit ${3}
}
 
 
DATE='date'
if ! DATE_CMD=$(which ${DATE} 2>&1)
then
 notfound "${DATE}" "${DATE_CMD}" $?
fi
 
GREP='grep'
if ! GREP_CMD=$(which ${GREP} 2>&1)
then
 notfound "${GREP}" "${GREP_CMD}" $?
fi
 
PERL='perl'
if ! PERL_CMD=$(which ${PERL} 2>&1)
then
 notfound "${PERL}" "${PERL_CMD}" $?
fi
 
MKPASSWD='mkpasswd'
if ! MKPASSWD_CMD=$(which ${MKPASSWD} 2>&1)
then
 notfound "${MKPASSWD}" "${MKPASSWD_CMD}" $?
fi
 
function usage {
 echo "${0} <USERNAME> <PASSWORD>"
 echo
 echo "Arguments are optional, user will be prompted"
 echo "If args contain spaces or special characters, please"
 echo "enclose in quotes:"
 echo
 echo "${0} username 'P@\$\$w05D'"
 exit
}
 
function read_username {
 while [ -z "${USERNAME}" ]
 do
 clear
 echo "############################"
 echo "Provide Existing Username"
 echo "############################"
 read USERNAME
 done
}
 
function read_password {
 while [ -z "${PASSWORD}" ]
 do
 clear
 echo "############################"
 echo "Provide New Password"
 echo "############################"
 read PASSWORD
 done
}
 
if [ $# -le 0 ]
then
 read_username
 read_password
elif [ $# -eq 2 ]
then
 USERNAME="${1}"
 PASSWORD="${2}"
elif [ $# -eq 1 ]
then
 REGEX='^-+(h|help)$'
 shopt -s nocasematch
 [[ "${1}" =~ ${REGEX} ]] && usage
 USERNAME="${1}"
 read_password
else
 usage
fi
 
REGEX='^GEN|GENERATE$'
shopt -s nocasematch
if [[ "${PASSWORD}" =~ ${REGEX} ]]
then
 #Generate Password. May or may not be used below.
 echo "Generating password..."
 if PASSWORD=$(${MKPASSWD_CMD} -l 8 -s 1 2>&1)
 then
 echo "Done"
 else
 echo -e "Cannot generate password:\n${PASSWORD}"
 exit 1
 fi
fi
shopt -u nocasematch
 
if ! RESULT=$(${GREP_CMD} "^${USERNAME}:" ${SFTP_PASSWD_FILE} 2>&1)
then
 echo "Username ${USERNAME} does not exist in ${SFTP_PASSWD_FILE}, exiting..."
 echo "${RESULT}"
 exit 1
fi
 
CREATECMD="${FTPASSWD_CMD} --passwd --change-password --name '${USERNAME}' --file ${SFTP_PASSWD_FILE} --stdin <<< '${PASSWORD}'"
 
#Debug
#echo "$CREATECMD"
 
if ! RESULT=$(eval ${CREATECMD} 2>&1)
then
 RETVAL=$?
 echo -e "Cannot change password:\n${RESULT}"
 exit ${RETVAL}
fi
 
DATE=$(${DATE_CMD} +%D-%H:%M)
 
echo ""
echo ""
echo "Your updated SFTP account information:"
echo "####################################"
echo "${DATE}"
echo "PROD IP: (<desired IP>)"
#echo "DR IP: (63.235.127.102)"
echo "Username: ${USERNAME}"
echo "NEW Password For ${USERNAME}: ${PASSWORD}"
echo "####################################"
 
${PERL_CMD} -pe "s#^(Password[ \t]+For[ \t]+${USERNAME}.+)\$#\${1}\nPassword changed (${DATE}) to: ${PASSWORD}#" -i ${SFTP_ACCOUNT_FILE}