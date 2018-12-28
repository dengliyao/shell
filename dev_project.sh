#!/bin/bash
JENKINS_HOST=/root/.jenkins/workspace
develop_ip=112.74.42.26
nginx_dir=/usr/local/nginx/sbin
nginx_conf=/root/.jenkins/workspace/develop_config/nginx_config
file_url=/root/.jenkins/workspace/dev_shell

#$1参数为基础项目代码,$2为域名,$3为客户分支
project_name=$1
nginx_name=$2
client_name=$3


#同步nginx配置文件流程
NGINX_CONF(){
    #修改项目路径
    sed -ri "s/project_name/${project_name}/" /project/develop/nginx_config/${project_name}.conf
    #修改nginx域名
if [  -z ${nginx_name} ];then
    sed -ri "s/nginx_name/${project_name}/" /project/develop/nginx_config/${project_name}.conf
else
    sed -ri "s/nginx_name/${nginx_name}/" /project/develop/nginx_config/${project_name}.conf
fi
    #传nginx配置文件
    ssh root@${develop_ip} "[ -f /usr/local/nginx/conf/vhost/${project_name}.conf ]"
    [ $? -ne 0 ] && scp /project/develop/nginx_config/${project_name}.conf root@${develop_ip}:/usr/local/nginx/conf/vhost/
    #重新加载nginx配置文件
    ssh root@${develop_ip} "${nginx_dir}/nginx -t &&  ${nginx_dir}/nginx -s reload"
}

#发布代码流程
SOURCE(){
/usr/bin/rsync -avz  --exclude-from="${file_url}/file.txt" $JENKINS_HOST/${project_name}-dev/  www@${develop_ip}:/data/wwwroot/${project_name}
[[ ${project_name} =~ [a-zA-Z]*-api ]]
if [ $? -eq 0 ];then
    #修改文件权限
    ssh root@${develop_ip}  "find /data/wwwroot/${project_name} -type f -exec chmod 640 {} \; && find /data/wwwroot/${project_name} -type d -exec chmod 750 {} \;"
    #清除php代码缓存
    ssh www@${develop_ip} "rm -rf /data/wwwroot/${project_name}/runtime/cache/*"
    cp ${nginx_conf}/api.conf /project/develop/nginx_config/${project_name}.conf
    #修改项目权限
    ssh root@${develop_ip} "chown www. /data/wwwroot/${project_name} -R"
    #调用同步nginx配置文件流程
    NGINX_CONF
else
    #修改文件权限
    ssh root@${develop_ip}  "find /data/wwwroot/${project_name} -type f -exec chmod 640 {} \; && find /data/wwwroot/${project_name} -type d -exec chmod 750 {} \;"
    cp ${nginx_conf}/h5.conf /project/develop/nginx_config/${project_name}.conf
    #修改项目权限
    ssh root@${develop_ip} "chown www. /data/wwwroot/${project_name} -R"
    #调用同步nginx配置文件流程
    NGINX_CONF
fi
}

if [ -z $client_name ];then
    SOURCE
else
    project_name=${client_name}-${project_name}
    SOURCE
fi
