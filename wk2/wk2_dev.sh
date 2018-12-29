#!/bin/bash
JENKINS_HOST=/root/.jenkins/workspace
develop_ip=3.1.1.1
nginx_dir=/usr/local/nginx/sbin
nginx_conf=/root/.jenkins/workspace/develop_config/nginx_config
file_url=/root/.jenkins/workspace/dev_shell


project_name=$1
client_name=$2
domain_name=${client_name}${project_name}
mysql_url=$3

#check project
ssh root@${develop_ip} "[ ! -d /data/wwwroot/${domain_name} ] && mkdir /data/wwwroot/${domain_name}"

#sync Code
/usr/bin/rsync -avz --exclude-from="${file_url}/file.txt"  ${JENKINS_HOST}/${domain_name}-dev/  root@${develop_ip}:/data/wwwroot/${domain_name}

#copy nginx.conf
ssh root@${develop_ip} "[ -f /usr/local/nginx/conf/vhost/${domain_name}.conf ]"
if [ $? -ne 0 ];then
    cp /root/.jenkins/workspace/develop_config/nginx_config/wk2.conf /project/develop/nginx_config/${domain_name}.conf
    sed -ri "s/nginx_name/${domain_name}/" /project/develop/nginx_config/${domain_name}.conf
    sed -ri "s/project_name/${domain_name}/" /project/develop/nginx_config/${domain_name}.conf
    scp /project/develop/nginx_config/${domain_name}.conf root@${develop_ip}:/usr/local/nginx/conf/vhost/
fi

#mysql_config
cp  /root/.jenkins/workspace/develop_config/project_config/config.php /project/develop/project_config/config.php
sed -ri "s/mysql_url/${mysql_url}/" /project/develop/project_config/config.php
sed -ri "s/mysql_name/${client_name}_wk2/" /project/develop/project_config/config.php
sed -ri "s/mysql_user/${client_name}_wk2/" /project/develop/project_config/config.php
sed -ri "s/mysql_pwd/${client_name}@HR.CY2018/" /project/develop/project_config/config.php
scp /project/develop/project_config/config.php root@${develop_ip}:/data/wwwroot/${domain_name}/Application/Appapi/Conf/

#Modify permissions
ssh root@${develop_ip} "chown www. /data/wwwroot/${domain_name} -R"
ssh root@${develop_ip} "find /data/wwwroot/${domain_name} -type d -exec chmod 750 {} \; && find /data/wwwroot/${domain_name} -type f -exec chmod 640 {} \;"

#nginx reload
ssh root@${develop_ip} "${nginx_dir}/nginx -t &&  ${nginx_dir}/nginx -s reload"