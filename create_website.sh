#!/bin/bash

#   title          : create_website
#   description    : Script to create a website configuration for a given domain
#   author         : Dominic Pratt
#   date           : 20191112
#   version        : 0.4
#   usage          : ./create_website.sh
#   notes          : tested with and depends on nginx
#   notes:         : this script comes without any error handling
#   license:       : MIT
#   bash_version   : 5.0.3(1)-release

userpwd=$(pwgen 12 1)

# Check if script is being run by root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# =======================
# function blocks
# =======================

function make_database
{
    mysql --defaults-extra-file=/root/.my.cnf -e "CREATE DATABASE ${uname}";
    mysql --defaults-extra-file=/root/.my.cnf -e "GRANT ALL ON ${uname}.* TO ${uname} IDENTIFIED BY '${userpwd}';"
    mysql --defaults-extra-file=/root/.my.cnf -e "flush privileges;"
}

function make_vhost
{
cat <<- _EOF_
server {
        listen 80;

        server_name $dname www.$dname;
        root /srv/www/$dname/web/;
        index index.php index.html index.htm;

        location / {
            try_files \$uri \$uri/ /index.php?$uri&\$args;
        }

        location ~ ^/(phpfpmstatus|phpfpmping)$ {
            include fastcgi_params;
            fastcgi_pass unix:/srv/www/$dname/run/php-fpm.sock;
            fastcgi_param SCRIPT_FILENAME /srv/www/$dname/web$fastcgi_script_name;
        }

        location ~ \.php$ {
            try_files \$uri =404;
            fastcgi_pass   unix:/srv/www/$dname/run/php-fpm.sock;
            fastcgi_index  index.php;
            include fastcgi_params;
            fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
            fastcgi_buffer_size 128k;
            fastcgi_buffers 256 16k;
            fastcgi_read_timeout 600;
            fastcgi_busy_buffers_size 256k;
            fastcgi_temp_file_write_size 256k;
        }
}
_EOF_
}

function make_phppool
{
cat <<- _EOF_
[$uname]
prefix = /srv/www/$dname
user = $uname
group = $uname
listen = run/php-fpm.sock
listen.backlog = 500
listen.owner = $uname
listen.group = www-data
pm = static
pm.max_children = 32
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
pm.status_path = /phpfpmstatus
ping.path = /phpfpmping
slowlog = log/\$pool.log.slow
request_slowlog_timeout = 30s
request_terminate_timeout = 600s
rlimit_files = 10124
chdir = /
php_admin_value[open_basedir] = /srv/www/$dname/web
_EOF_
}

function add_user
{
    adduser --quiet --disabled-password --shell /bin/sh --home /srv/www/"$dname" --gecos "$uname" --no-create-home "$uname"
    echo "$uname:$userpwd" | chpasswd
}

# =======================
#         header
# =======================
clear
echo "***      Site Setup      ***"

# =======================
# get needed variables (user input)
# =======================
echo -n "==> Enter new domain name (domain.com):  "
read -r dname

echo -n "==> Enter new user name (domaincom):  "
read -r uname

# =======================
# create user account
# =======================
add_user

# =======================
# create needed directories
# =======================
mkdir -p /srv/www/"$dname"
mkdir -p /srv/www/"$dname"/log
mkdir -p /srv/www/"$dname"/web
mkdir -p /srv/www/"$dname"/run
chown "$uname":"$uname" /srv/www/"$dname"/web

# =======================
# build vhost config file
# =======================
make_vhost > /etc/nginx/sites-available/"$dname.conf"

# =======================
# build php config file
# =======================
make_phppool > /etc/php/7.3/fpm/pool.d/"$dname.conf"

# =======================
# create mysql-database
# =======================
make_database

# =======================
#   start let's encrypt
# =======================
# if [[ "$sslchoice" =~ ^([yY][eE][sS]|[yY])+$ ]]; then
#     get_letsencrypt
# fi

# =======================
# generate login data
# =======================
echo "  ***      Domain:      $dname"

echo "  ***      User:        $uname"
echo "  ***      Password:    $userpwd"

# =======================
# restart services
# =======================
ln -s /etc/nginx/sites-available/"$dname".conf /etc/nginx/sites-enabled/"$dname.conf"

/usr/sbin/service php7.3-fpm restart
/usr/sbin/service nginx restart

exit

# =======================
#    exit
# =======================