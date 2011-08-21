#!/bin/bash

# ===========================================
#          LuboCP Install script
# Install and configure the server for lubocp
# nginx + php5-fpm + mysql + Symfony2
# ===========================================


#
# Constants
#

# Find ubuntu distro name
source /etc/lsb-release
ubuntu_distro=$DISTRIB_CODENAME || lucid
# Commands
apt="apt-get -y"
# Paths
symfony_dir=/usr/local/lib/symfony-2
skeleton_dir=/usr/share/symfony/skeleton
lubocp_dir=/var/www/lubocp


#
# Configure apt repository
#

echo Configuring apt repositories...

cat <<EOT >/etc/apt/sources.list.d/nginx.list

## Additional package sources
# nginx stable
deb http://ppa.launchpad.net/nginx/stable/ubuntu $ubuntu_distro main
deb-src http://ppa.launchpad.net/nginx/stable/ubuntu $ubuntu_distro main
# php 5.3
deb http://ppa.launchpad.net/nginx/php5/ubuntu $ubuntu_distro main
deb-src http://ppa.launchpad.net/nginx/php5/ubuntu $ubuntu_distro main
EOT

apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C300EE8C
$apt update


#
# Install packages (the mysql-server package will ask you for a password!)
# and bring the system up-to-date
#

echo Installing required packages...

$apt install nginx mysql-server-5.1 mysql-client-5.1 php5-fpm php5-cli \
             php5-suhosin php5-mysql php5-sqlite php5-intl php5-gd php-apc \
             git-core
$apt upgrade


#
# Create users
#

echo Install user-management script create-user...

# Install create-user script
cat <<EOT >/usr/bin/create-user
#!/bin/bash

# ======================================
# Create user and setup user environment
# ======================================
# Usage: create-user USERNAME
useradd -b /var/www -k $skeleton_dir -U -m -s /bin/bash $1
chown -R www-data:$1 /var/www/$1
chown -R www-data:www-data /var/www/$1/conf
chmod -R u=rw,g=rw,o= /var/www/$1
EOT
chmod u+x,g+x /usr/bin/create-user


#
# Configure Nginx
#

echo Configuring Nginx...

cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.orig
cat <<EOT >/etc/nginx/nginx.conf
user www-data;
worker_processes 4;
pid /var/run/nginx.pid;

events {
    worker_connections 768;
}

http {
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;
    
    gzip on;
    gzip_disable "msie6";
    
    include /etc/nginx/conf.d/*.conf;
    include /var/www/*/conf/vhost.conf;
}
EOT

cp /etc/nginx/fastcgi_params /etc/nginx/fastcgi_params.orig
cat <<EOT >/etc/nginx/fastcgi_params
fastcgi_param  QUERY_STRING       $query_string;
fastcgi_param  REQUEST_METHOD     $request_method;
fastcgi_param  CONTENT_TYPE       $content_type;
fastcgi_param  CONTENT_LENGTH     $content_length;

fastcgi_param  SCRIPT_NAME        $fastcgi_script_name;
fastcgi_param  SCRIPT_FILENAME    $document_root$fastcgi_script_name;
fastcgi_param  REQUEST_URI        $request_uri;
fastcgi_param  DOCUMENT_URI       $document_uri;
fastcgi_param  DOCUMENT_ROOT      $document_root;
fastcgi_param  SERVER_PROTOCOL    $server_protocol;

fastcgi_param  GATEWAY_INTERFACE  CGI/1.1;
fastcgi_param  SERVER_SOFTWARE    nginx/$nginx_version;

fastcgi_param  REMOTE_ADDR        $remote_addr;
fastcgi_param  REMOTE_PORT        $remote_port;
fastcgi_param  SERVER_ADDR        $server_addr;
fastcgi_param  SERVER_PORT        $server_port;
fastcgi_param  SERVER_NAME        $server_name;

# PHP only, required if PHP was built with --enable-force-cgi-redirect
#fastcgi_param  REDIRECT_STATUS    200;
fastcgi_connect_timeout 60;
fastcgi_send_timeout 180;
fastcgi_read_timeout 180;
fastcgi_buffer_size 128k;
fastcgi_buffers 4 256k;
fastcgi_busy_buffers_size 256k;
fastcgi_temp_file_write_size 256k;
fastcgi_intercept_errors on;
EOT


#
# Configure php5-fpm
#

echo Configuring php-fpm...

cp /etc/php5/fpm/main.conf /etc/php5/fpm/main.conf.orig
cat <<EOT >/etc/php5/fpm/main.conf
[global]
pid = /var/run/php5-fpm.pid
error_log = /var/log/php5-fpm.log
include=/var/www/*/conf/php-pool.conf
EOT


#
# Configure Mysql
#

echo Configuring Mysql...


#
# Install Symfony
#

echo Installing Symfony...

if [ -d "$symfony_dir" ]; then
    rm -rf $symfony_dir
fi

mkdir -p $symfony_dir

git clone git://github.com/lbotsch/symfony-standard.git $symfony_dir

php $symfony_dir/bin/vendors install
chown -R root:www-data $symfony_dir
chmod -R u+rw,g+rw,o=r $symfony_dir


#
# Create symfony skeleton
#

if [ -d "$skeleton_dir" ]; then
    rm -rf $skeleton_dir
fi
mkdir -p $skeleton_dir

mv $symfony_dir/app $skeleton_dir/
mv $symfony_dir/src $skeleton_dir/
mv $symfony_dir/web $skeleton_dir/
chown -R root:www-data $skeleton_dir
chmod -R u+rw,g+rw,o= $skeleton_dir


#
# Install LuboCP
#

echo Setting up LuboCP...

if [ -d "/var/www/lubocp" ]; then
    rm -rf /var/www/lubocp
fi

id lubocp > /dev/null 2>&1
if [ "$?" -eq "0" ]; then
    userdel lubocp
fi

# Create user for lubocp
useradd -b /var/www -k $skeleton_dir -m -U -G www-data -s /bin/bash lubocp
# Add lubocp user to sudoers (for user/group creation from the cp)
cat <<EOT >/etc/sudoers.d/lubocp
# Grant lubocp sudo access to custom create-user script
lubocp localhost=/usr/bin/create-user
# Grant lubocp sudo access to start scripts for nginx and php-fpm
lubocp localhost=/etc/init.d/nginx
lubocp localhost=/etc/init.d/php5-fpm
EOT

mkdir -p /var/www/lubocp/conf
cat <<EOT >/var/www/lubocp/conf/vhost.conf

EOT
cat <<EOT >/var/www/lubocp/conf/php-pool.conf
[lubocp]

EOT

git clone git://github.com/lbotsch/LuboControlPanelBundle.git $lubocp_dir/src/Lubo/ControlPanelBundle
cp -R $lubocp_dir/src/Lubo/ControlPanelBundle/Resources/app $lubocp_dir

echo Done!
echo Open http://LUBOCP_DOMAIN/config.php in your browser to check the configuration!



