#!/bin/bash
################################################################################
# Script for installing Odoo on Ubuntu 14.04, 15.04, 16.04 and 18.04 (could be used for other version too)
# Author: Clément Mutz
#-------------------------------------------------------------------------------
# This script will install Odoo on your Ubuntu 16.04 server. It can install multiple Odoo instances
# in one Ubuntu because of the different xmlrpc_ports
#-------------------------------------------------------------------------------
# Make a new file:
# sudo nano odoo-install.sh
# Place this content in it and then make the file executable:
# sudo chmod +x odoo-install.sh
# Execute the script to install Odoo:
# ./odoo-install
################################################################################

# Choose the Odoo version which you want to install. For example: 13.0, 12.0, 11.0 or saas-18. When using 'master' the master version will be installed.
# IMPORTANT! This script contains extra libraries that are specifically needed for Odoo 13.0
OE_DIR_VERSION="v10"
OE_VERSION="10.0"

OE_SYSTEM_NAME=`lsb_release -cs`

OE_USER="odoo"
OE_HOME="/opt/$OE_USER"
OE_HOME_ENV="$OE_HOME/odoo_$OE_DIR_VERSION"
OE_HOME_SERVER="/opt/$OE_USER/odoo_$OE_DIR_VERSION/server"
# The default port where this Odoo instance will run under (provided you use the command -c in the terminal)
# Set to true if you want to install it, false if you don't need it or have it already installed.

# Set the user and password Postgresql
OE_PG_USER="odoo_$OE_DIR_VERSION"
OE_PG_PWD="odoo_$OE_DIR_VERSION"

INSTALL_WKHTMLTOPDF="True"
# Set the default Odoo port (you still have to use -c /etc/odoo-server.conf for example to use this.)
OE_PORT="8069"
# Set this to True if you want to install the Odoo enterprise version!
IS_ENTERPRISE="False"
# set the superadmin password
OE_SUPERADMIN="admin_2019"
OE_CONFIG="odoo_$OE_DIR_VERSION"

update_server(){
#--------------------------------------------------
# Update Server
#--------------------------------------------------
echo -e "\n---- Update Server ----"
# universe package is for Ubuntu 18.x
sudo add-apt-repository universe
# libpng12-0 dependency for wkhtmltopdf
sudo add-apt-repository "deb http://mirrors.kernel.org/ubuntu/ xenial main"
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get --purge autoremove -y
}

install_pg(){
#--------------------------------------------------
# Install PostgreSQL Server
#--------------------------------------------------
echo -e "\n---- Install PostgreSQL Server ----"
sudo apt-get install postgresql postgresql-server-dev-all -y

echo -e "\n---- Creating the ODOO PostgreSQL User  ----"
#sudo su - postgres -c "createuser -s $OE_PG_USER" 2> /dev/null || true
sudo service postgresql start
sudo -u postgres bash -c "psql -c \"CREATE USER $OE_PG_USER WITH PASSWORD '$OE_PG_PWD';\""
sudo -u postgres bash -c "psql -c \"ALTER USER $OE_PG_USER WITH SUPERUSER;\""

}

install_dependencies(){
#--------------------------------------------------
# Install Dependencies
#--------------------------------------------------
echo -e "\n--- Installing Python 3 + pip3 --"
sudo apt install git python-pip build-essential wget python-dev python-virtualenv python-wheel libxslt-dev libzip-dev libldap2-dev libsasl2-dev python-setuptools node-less -y

echo -e "\n---- Install python packages/requirements ----"
sudo pip install -r https://github.com/OCA/OCB/raw/${OE_VERSION}/requirements.txt

echo -e "\n---- Installing nodeJS NPM and rtlcss for LTR support ----"
sudo apt-get install nodejs npm -y
sudo npm install -g rtlcss
sudo npm install -g less
#sudo npm install -g less-plugin-clean-cs
}

install_wkhtmltopdf(){
#--------------------------------------------------
# Install Wkhtmltopdf if needed
#--------------------------------------------------
if [ $INSTALL_WKHTMLTOPDF = "True" ]; then
  echo -e "\n---- Install wkhtml and place shortcuts on correct place for ODOO $OE_VERSION ----"
##
###  WKHTMLTOPDF download links
## === Ubuntu Trusty x64 & x32 === (for other distributions please replace these two links,
## in order to have correct version of wkhtmltopdf installed, for a danger note refer to 
## https://github.com/odoo/odoo/wiki/Wkhtmltopdf ):
WKHTMLTOX_X64="https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.${OE_SYSTEM_NAME}_amd64.deb"
WKHTMLTOX_X32="https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1.${OE_SYSTEM_NAME}_i386.deb"

  #pick up correct one from x64 & x32 versions:
  if [ "`getconf LONG_BIT`" == "64" ];then
      _url=$WKHTMLTOX_X64
  else
      _url=$WKHTMLTOX_X32
  fi
  sudo wget $_url -P /tmp/
  sudo dpkg -i /tmp/`basename $_url`
  sudo apt-get -fy install
  sudo ln -s /usr/local/bin/wkhtmltopdf /usr/bin
  sudo ln -s /usr/local/bin/wkhtmltoimage /usr/bin
else
  echo "Wkhtmltopdf isn't installed due to the choice of the user!"
fi
}

install_env_odoo(){
echo -e "\n---- Create ODOO system user ----"
sudo adduser --system --quiet --shell=/bin/bash --home=$OE_HOME --gecos 'ODOO' --group $OE_USER
#The user should also be added to the sudo'ers group.
sudo adduser $OE_USER sudo

echo -e "\n---- Create custom directories ----"

sudo su $OE_USER -c "mkdir  $OE_HOME/conf $OE_HOME/filestore $OE_HOME/log $OE_HOME/odoo_$OE_DIR_VERSION"
sudo su $OE_USER -c "mkdir $OE_HOME_ENV/dev_addons $OE_HOME_ENV/extra_addons $OE_HOME_ENV/muk_addons $OE_HOME_ENV/oca_addons $OE_HOME_ENV/sources $OE_HOME_ENV/vraja_addons/"
sudo su $OE_USER -c "mkdir $OE_HOME_ENV/sources/dev_addons $OE_HOME_ENV/sources/extra_addons $OE_HOME_ENV/sources/muk_addons $OE_HOME_ENV/sources/oca_addons $OE_HOME_ENV/sources/vraja_addons/"

}

install_server_odoo(){
#--------------------------------------------------
# Install ODOO
#--------------------------------------------------
echo -e "\n==== Installing ODOO Server ===="
sudo git clone --depth 1 --branch $OE_VERSION https://www.github.com/OCA/OCB $OE_HOME_SERVER/

#if [ $IS_ENTERPRISE = "True" ]; then
#    # Odoo Enterprise install!
#    echo -e "\n--- Create symlink for node"
#    sudo ln -s /usr/bin/nodejs /usr/bin/node
#    sudo su $OE_USER -c "mkdir $OE_HOME/enterprise"
#    sudo su $OE_USER -c "mkdir $OE_HOME/enterprise/addons"
#
#    GITHUB_RESPONSE=$(sudo git clone --depth 1 --branch $OE_VERSION https://www.github.com/odoo/enterprise "$OE_HOME/enterprise/addons" 2>&1)
#    while [[ $GITHUB_RESPONSE == *"Authentication"* ]]; do
#        echo "------------------------WARNING------------------------------"
#        echo "Your authentication with Github has failed! Please try again."
#        printf "In order to clone and install the Odoo enterprise version you \nneed to be an offical Odoo partner and you need access to\nhttp://github.com/odoo/enterprise.\n"
#        echo "TIP: Press ctrl+c to stop this script."
#        echo "-------------------------------------------------------------"
#        echo " "
#        GITHUB_RESPONSE=$(sudo git clone --depth 1 --branch $OE_VERSION https://www.github.com/odoo/enterprise "$OE_HOME/enterprise/addons" 2>&1)
#    done
#
#    echo -e "\n---- Added Enterprise code under $OE_HOME/enterprise/addons ----"
#    echo -e "\n---- Installing Enterprise specific libraries ----"
#    sudo pip3 install num2words ofxparse dbfread ebaysdk firebase_admin pyOpenSSL
#    sudo npm install -g less
#    sudo npm install -g less-plugin-clean-css
#fi

echo -e "\n---- Setting permissions on home folder ----"
sudo chown -R $OE_USER:$OE_USER $OE_HOME/*

echo -e "* Create server config file"

sudo touch $OE_HOME/conf/${OE_CONFIG}.conf
echo -e "* Creating server config file"
sudo su root -c "printf '[options] \n; This is the password that allows database operations:\n' >> ${OE_HOME}/conf/${OE_CONFIG}.conf"
sudo su root -c "printf 'admin_passwd = ${OE_SUPERADMIN}\n' >> ${OE_HOME}/conf/${OE_CONFIG}.conf"
sudo su root -c "printf 'data_dir = ${OE_HOME}/filestore\n' >> ${OE_HOME}/conf/${OE_CONFIG}.conf"
sudo su root -c "printf 'xmlrpc_port = ${OE_PORT}\n' >> ${OE_HOME}/conf/${OE_CONFIG}.conf"
sudo su root -c "printf 'xmlrpc_interface = 0.0.0.0\n' >> ${OE_HOME}/conf/${OE_CONFIG}.conf"
sudo su root -c "printf 'logfile = ${OE_HOME}/log/${OE_CONFIG}.log\n' >> ${OE_HOME}/conf/${OE_CONFIG}.conf"
sudo su root -c "printf 'db_host = localhost\n' >> ${OE_HOME}/conf/${OE_CONFIG}.conf"
sudo su root -c "printf 'db_port = False\n' >> ${OE_HOME}/conf/${OE_CONFIG}.conf"
sudo su root -c "printf 'db_user = ${OE_PG_USER}\n' >> ${OE_HOME}/conf/${OE_CONFIG}.conf"
sudo su root -c "printf 'db_password = ${OE_PG_PWD}\n' >> ${OE_HOME}/conf/${OE_CONFIG}.conf"

if [ $IS_ENTERPRISE = "True" ]; then
    sudo su root -c "printf 'addons_path=${OE_HOME}/enterprise/addons,${OE_HOME_SERVER}/addons\n' >> ${OE_HOME}/conf/${OE_CONFIG}.conf"
else
    sudo su root -c "printf 'addons_path=${OE_HOME_SERVER}/addons' >> ${OE_HOME}/conf/${OE_CONFIG}.conf"
fi
sudo chown $OE_USER:$OE_USER $OE_HOME/conf/${OE_CONFIG}.conf
sudo chmod 640 $OE_HOME/conf/${OE_CONFIG}.conf

echo -e "* Create startup file"
sudo su root -c "echo '#!/bin/sh' >> $OE_HOME_SERVER/start.sh"
sudo su root -c "echo 'sudo -u $OE_USER $OE_HOME_SERVER/odoo-bin --config=/etc/${OE_CONFIG}.conf' >> $OE_HOME_SERVER/start.sh"
sudo chmod 755 $OE_HOME_SERVER/start.sh

#--------------------------------------------------
# Adding ODOO as a deamon (initscript)
#--------------------------------------------------

echo -e "* Create init file"
cat <<EOF > ~/$OE_CONFIG
#!/bin/sh
### BEGIN INIT INFO
# Provides: $OE_CONFIG
# Required-Start: \$remote_fs \$syslog
# Required-Stop: \$remote_fs \$syslog
# Should-Start: \$network
# Should-Stop: \$network
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: Enterprise Business Applications
# Description: ODOO Business Applications
### END INIT INFO
PATH=/bin:/sbin:/usr/bin
DAEMON=$OE_HOME_SERVER/odoo-bin
NAME=$OE_CONFIG
DESC=$OE_CONFIG
# Specify the user name (Default: odoo).
USER=$OE_USER
# Specify an alternate config file (Default: /etc/openerp-server.conf).
CONFIGFILE="${OE_HOME}/conf/${OE_CONFIG}.conf"
# pidfile
PIDFILE=/var/run/\${NAME}.pid
# Additional options that are passed to the Daemon.
DAEMON_OPTS="-c \$CONFIGFILE"
[ -x \$DAEMON ] || exit 0
[ -f \$CONFIGFILE ] || exit 0
checkpid() {
[ -f \$PIDFILE ] || return 1
pid=\`cat \$PIDFILE\`
[ -d /proc/\$pid ] && return 0
return 1
}
case "\${1}" in
start)
echo -n "Starting \${DESC}: "
start-stop-daemon --start --quiet --pidfile \$PIDFILE \
--chuid \$USER --background --make-pidfile \
--exec \$DAEMON -- \$DAEMON_OPTS
echo "\${NAME}."
;;
stop)
echo -n "Stopping \${DESC}: "
start-stop-daemon --stop --quiet --pidfile \$PIDFILE \
--oknodo
echo "\${NAME}."
;;
restart|force-reload)
echo -n "Restarting \${DESC}: "
start-stop-daemon --stop --quiet --pidfile \$PIDFILE \
--oknodo
sleep 1
start-stop-daemon --start --quiet --pidfile \$PIDFILE \
--chuid \$USER --background --make-pidfile \
--exec \$DAEMON -- \$DAEMON_OPTS
echo "\${NAME}."
;;
*)
N=/etc/init.d/\$NAME
echo "Usage: \$NAME {start|stop|restart|force-reload}" >&2
exit 1
;;
esac
exit 0
EOF

echo -e "* Security Init File"
sudo mv ~/$OE_CONFIG /etc/init.d/$OE_CONFIG
sudo chmod 755 /etc/init.d/$OE_CONFIG
sudo chown root: /etc/init.d/$OE_CONFIG

echo -e "* Start ODOO on Startup"
sudo update-rc.d $OE_CONFIG defaults

echo -e "* Starting Odoo Service"
sudo su root -c "/etc/init.d/$OE_CONFIG start"
echo "-----------------------------------------------------------"
echo "Done! The Odoo server is up and running. Specifications:"
echo "Port: $OE_PORT"
echo "User service: $OE_USER"
echo "User PostgreSQL: $OE_USER"
echo "Code location: $OE_USER"
echo "Addons folder: $OE_USER/$OE_CONFIG/addons/"
echo "Start Odoo service: sudo service $OE_CONFIG start"
echo "Stop Odoo service: sudo service $OE_CONFIG stop"
echo "Restart Odoo service: sudo service $OE_CONFIG restart"
echo "-----------------------------------------------------------"
}

install_sources_oca_modules() {
DIRNAME=$(dirname $0)
python $DIRNAME/insert_module_oca_v10.py
}


update_server
install_dependencies
install_pg
install_wkhtmltopdf
install_env_odoo
install_server_odoo
install_sources_oca_modules
