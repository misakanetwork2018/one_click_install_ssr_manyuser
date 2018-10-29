#!/bin/sh
#说明
show_usage="args: [-s]\
                                  [--supervisor]"

GETOPT_ARGS=`getopt -o sp:h:u:P:n:d: -l supervisor,password:,host:,username:,port:,node:,db, -- "$@"`
eval set -- "$GETOPT_ARGS"
OLD_IFS="$IFS"
IFS=" "
arguments=($*)
IFS="$OLD_IFS"
supervisor=false
password=""
username=""
port=""
host=""
node=""
db=""
random_p=`date +%s%N | md5sum |cut -c 1-16`
echo $random_p

#获取参数
while [ -n "$1" ]
do
	case "$1" in
		-s|--supervisor) supervisor=true;shift 1;;
                -P|--port) port=$2;shift 2;;
                -p|--password) password=$2;shift 2;;
                -h|--host) host=$2;shift 2;;
                -u|--username) username=$2;shift 2;;
                -n|--node) node=$2;shift 2;;
                -d|--db) db=$2;shift 2;;
                --) break ;;
                *) echo $1,$2,$show_usage; break ;;
        esac
done

if [[ -n "$username" ]]; then
sed -i 's/"user": "ss"/"user": "'${username}'"/' usermysql.json
fi
if [[ -n "$password" ]]; then
sed -i 's/"password": "pass"/"password": "'${password}'"/' usermysql.json
fi
if [[ -n "$port" ]]; then
sed -i 's/"port": 3306/"port": '${port}'/' usermysql.json
fi
if [[ -n "$host" ]]; then
sed -i 's/"host": "127.0.0.1"/"host": "'${host}'/"' usermysql.json
fi
if [[ -n "$db" ]]; then
sed -i 's/"db": "sspanel"/"db": "'${host}'/"' usermysql.json
fi
if [[ -n "$node" ]]; then
sed -i 's/"node_id": 0/"node_id": '${node}'/' usermysql.json
fi
