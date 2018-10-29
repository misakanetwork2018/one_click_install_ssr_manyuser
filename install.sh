#!/bin/sh

GETOPT_ARGS=`getopt -o sp:h:u:P:n:d:r:a: -l supervisor,password:,host:,username:,port:,node:,db:,run,autorestart -- "$@"`
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
autorestart=false
run=false

#获取参数
while [ -n "$1" ]
do
	case "$1" in
		-s|--supervisor) supervisor=true;shift 1;;
		-r|--run) run=true;shift 1;;
		-a|--autorestart) autorestart=true;shift 1;;
                -P|--port) port=$2;shift 2;;
                -p|--password) password=$2;shift 2;;
                -h|--host) host=$2;shift 2;;
                -u|--username) username=$2;shift 2;;
                -n|--node) node=$2;shift 2;;
                -d|--db) db=$2;shift 2;;
                --) break ;;
                *) break ;;
        esac
done

#获得系统类型
Get_Dist_Name()
{
    if grep -Eqi "CentOS" /etc/issue || grep -Eq "CentOS" /etc/*-release; then
        DISTRO='CentOS'
        PM='yum'
    elif grep -Eqi "Red Hat Enterprise Linux Server" /etc/issue || grep -Eq "Red Hat Enterprise Linux Server" /etc/*-release; then
        DISTRO='RHEL'
        PM='yum'
    elif grep -Eqi "Aliyun" /etc/issue || grep -Eq "Aliyun" /etc/*-release; then
        DISTRO='Aliyun'
        PM='yum'
    elif grep -Eqi "Fedora" /etc/issue || grep -Eq "Fedora" /etc/*-release; then
        DISTRO='Fedora'
        PM='yum'
    elif grep -Eqi "Debian" /etc/issue || grep -Eq "Debian" /etc/*-release; then
        DISTRO='Debian'
        PM='apt'
    elif grep -Eqi "Ubuntu" /etc/issue || grep -Eq "Ubuntu" /etc/*-release; then
        DISTRO='Ubuntu'
        PM='apt'
    elif grep -Eqi "Raspbian" /etc/issue || grep -Eq "Raspbian" /etc/*-release; then
        DISTRO='Raspbian'
        PM='apt'
    else
        DISTRO='unknow'
    fi
}

#安装依赖
function instdpec()
{
	if [ "$1" == "CentOS" ] || [ "$1" == "CentOS7" ];then
		$PM -y install wget
		TEST=`git --version`
		if  [ ! -n "$TEST" ] ;then
		$PM -y install git
		fi
		$PM -y groupinstall "Development Tools"
		$PM -y update nss curl
	elif [ "$1" == "Debian" ] || [ "$1" == "Raspbian" ] || [ "$1" == "Ubuntu" ];then
		$PM update
		$PM -y install wget
		TEST=`git --version`
		if  [ ! -n "$TEST" ] ;then
		$PM -y install git
		fi
		$PM -y install build-essential
	else
		echo "The shell can be just supported to install ssr on Centos, Ubuntu and Debian."
		exit 1
	fi
}

Get_Dist_Name

echo "Your OS is $DISTRO"

echo -e "\033[42;34mInstall dependent packages\033[0m"
instdpec $DISTRO;

cd /root
wget https://github.com/jedisct1/libsodium/releases/download/1.0.15/libsodium-1.0.15.tar.gz
if [ ! -f "./libsodium-1.0.15.tar.gz" ]; then
echo "Download fail. Please try again."
exit 1;
fi
tar xf libsodium-1.0.15.tar.gz && cd libsodium-1.0.15
./configure && make -j2 && make install
echo /usr/local/lib > /etc/ld.so.conf.d/usr_local_lib.conf
ldconfig
cd /root
rm -rf libsodium-1.0.15.tar.gz
rm -rf libsodium-1.0.15

git clone -b manyuser https://github.com/misakanetwork2018/shadowsocksr.git
if [ ! -d "./shadowsocksr" ]; then
echo "Download fail. Please try again."
exit 1;
fi
cd shadowsocksr
./setup_cymysql.sh
./initcfg.sh
random_p=`date +%s%N | md5sum |cut -c 1-16`
sed -i 's/"additional_ports" : {}/"additional_ports" : {"9000":{"password":"'$random_p'"}}' user-config.json

if $supervisor; then
   echo "Installing supervisor..."
cd /usr/local/src
wget https://pypi.python.org/packages/7b/17/88adf8cb25f80e2bc0d18e094fcd7ab300632ea00b601cbbbb84c2419eae/supervisor-3.3.2.tar.gz
tar -zxvf supervisor-3.3.2.tar.gz
cd supervisor-3.3.2
python setup.py install
   echo_supervisord_conf > /etc/supervisord.conf
file=<<EOF
[include]
files=/etc/supervisor/*.conf #若你本地无/etc/supervisor目录，请自建
EOF
echo $file>> /etc/supervisord.conf
mkdir -p /etc/supervisor
file=<<EOF
; 设置进程的名称，使用 supervisorctl 来管理进程时需要使用该进程名
[program:shadowsocksr]
command=python server.py
;numprocs=1 ; 默认为1 
;process_name=%(program_name)s ; 默认为 %(program_name)s，即 [program:x] 中的 x 
directory=/root/shadowsocksr ; 执行 command 之前，先切换到工作目录
user=root ; 使用 oxygen 用户来启动该进程
; 程序崩溃时自动重启，重启次数是有限制的，默认为3次 autorestart=true 
redirect_stderr=true
; 重定向输出的日志
stdout_logfile = /var/log/supervisord/tornado_server.log
loglevel=info
EOF
echo $file>/etc/supervisor/ssr.conf
fi

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

if $run; then
supervisord -c /etc/supervisord.conf
supervisorctl reload
fi

if $autorestart; then
sed -i 's/\/var\/spool\/cron\/root//' /var/spool/cron/root
echo "0 4 * * * supervisorctl reload" >> /var/spool/cron/root
fi

echo "Install completely."
