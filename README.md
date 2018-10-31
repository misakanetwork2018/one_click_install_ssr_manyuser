# one_click_install_ssr_manyuser

该脚本会把ssr安装到/root下，所以请在root用户下执行

目前已知能够正常运行在Centos6 x64中，其他系统请自行测试

一键命令：wget --no-check-certificate -O ./install.sh https://raw.githubusercontent.com/misakanetwork2018/one_click_install_ssr_manyuser/master/install.sh && sh install.sh

本脚本可接收以下参数，以便全自动部署：  
-s|--supervisor  安装后台守护程序  
-S|--setport 设置additional_ports，默认为13590  
-r|--run 安装完毕后立刻运行守护程序  
-P|--port= 修改usermysql.json中的port  
-p|--password= 修改usermysql.json中的password  
-h|--host= 修改usermysql.json中的host  
-u|--username 修改usermysql.json中的username  
-n|--node 修改usermysql.json中的node  
-d|--db 修改usermysql.json中的db  
