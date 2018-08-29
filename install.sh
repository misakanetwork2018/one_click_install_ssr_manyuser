#!/bin/sh

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

echo "Install completely."
