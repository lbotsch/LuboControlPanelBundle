LuboCP - Symfony Control Panel
==============================

## Installation

### Prerequisits

LuboCP needs some priviledges to be able to write client configuration files,
install Symfony bundles, write Symfony configuration files, etc...

We use the linux file attributes for access control. Each client gets a system
user uxxxx that ownes the clients files.

The files are also owned by the group www-data, that has write-access to config
files etc..

For security reasons, the php worker processes of the clients are executed with
low priviledges (i.e. as user uxxxx) to prevent client code to access other
clients resources or to overwrite his configuration.

### Directory Structure

    /
    |-- etc
      |-- nginx
        |-- nginx.conf root:root -rw-r-----     # nginx main config
                                                # Include /var/www/u*/conf/vhost.conf
      |-- php5
        |-- fpm
          |-- main.conf                         # php-fpm main config
                                                # Include /var/www/u*/conf/php-pool.conf
    |-- usr
      |-- local
        |-- lib
          |-- symfony root:www-data drwxrwxr-x  # Symfony framework
            |-- ...                             # Symfony vendor directory content
    |-- var
      |-- www root:www-data drwxrwx---
        |-- lubocp www-data:lubocp drwxrwx---   # lubocp
        |-- u0001 www-data:u0001 drwxrwx---     # Client u0001
          |-- app www-data:u0001 drwxrwx---     # Symfony app folder
          |-- conf www-data:www-data drwxrwx---             # Server configurations
            |-- vhost.conf www-data:www-data -rw-r-----     # nginx vhost configuration
            |-- php-pool.conf www-data:www-data -rw-r-----  # php-fpm pool configuration
          |-- log www-data:u0001 drwxrwx---     # Log files
          |-- src www-data:u0001 drwxrwx---     # custom client bundles
          |-- tmp www-data:u0001 drwxrwx---     # Temp directory
          |-- web www-data:u0001 drwxrwx---     # vhost root folder
        |-- u0002 www-data:u0002 drwxrwx---     # Additional client

### 
