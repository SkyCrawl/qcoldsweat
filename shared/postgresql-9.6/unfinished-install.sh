#!/bin/bash

#
# This script installs the bundled PostgreSQL v9.6.2 and takes the following arguments:
# 	$1 - installation prefix (where to put the database).
# If installation prefix is not given, '/share/<default-mount>/.qpkg/.pgsql-9.6.2.' is
# used by default, where '<default-mount>' is something like:
#	- MD0_DATA
#	- HDA_DATA
#	- CACHEDEV1_DATA
# 
# IMPORTANT NOTES: 
# - This script requires Entware-ng and QColdsweat to be installed.
# - When choosing the installation prefix, remember to leave these folders alone:
#	'/mnt/ext'
#	'/home/.../'
# - Even if compilation succeeds, it's very difficult to execute the database. More information:
#	https://github.com/SkyCrawl/QColdsweat/wiki/Befriend-QColdsweat-with-a-PostgreSQL-database
#

# Make the script stop at first error:
# set -e

# Determine important configuration:
QPKG_CONF="/etc/config/qpkg.conf"
QPKG_NAME="QColdsweat"
QPKG_ROOT="$(/sbin/getcfg $QPKG_NAME Install_Path -f $QPKG_CONF)"

# Alias the prefix:
PG_ROOT="$1"
if [ -z "$PG_ROOT" ]; then
	# use default prefix
	PG_ROOT="$QPKG_ROOT/../.pgsql-9.6.2"
fi

# Wherever we are, switch to a temporary folder next to the installation script:
PATH_SELF="$(dirname $0)"
if [ -d "$PATH_SELF/tmp" ]; then
	# clean the folder first
	rm -rf "$PATH_SELF/tmp"
fi
mkdir "$PATH_SELF/tmp"
cd "$PATH_SELF/tmp"

####################
# DETECT AND HANDLE ARCHITECTURE
####################

# Detect architecture:
ARCH_INFO=$(uname -m)
ARM5=$(echo "$ARCH_INFO" | grep -i "armv5")
ARM7=$(echo "$ARCH_INFO" | grep -i "armv7")
X32=$(echo "$ARCH_INFO" | grep "32")
X64=$(echo "$ARCH_INFO" | grep "64")

# Check that we successfully detected an architecture:
if [ -z "$ARM5" ] && [ -z "$ARM7" ] && [ -z "$X32" ] && [ -z "$X64" ]; then
	echo "Error: architecture '$ARCH_INFO' is unknown"
	exit 1
fi

# Convert architecture into a download URL of development headers:
DH_URL=""
if [ ! -z "$ARM5" ]; then
	DH_URL="http://pkg.entware.net/binaries/armv5/include/include.tar.gz"
elif [ ! -z "$ARM7" ]; then
	DH_URL="http://pkg.entware.net/binaries/armv7/include/include.tar.gz"
elif [ ! -z "$X32" ]; then
	DH_URL="http://pkg.entware.net/binaries/x86-32/include/include.tar.gz"
elif [ ! -z "$X64" ]; then
	DH_URL="http://pkg.entware.net/binaries/x86-64/include/include.tar.gz"
fi

####################
# CONFIGURE POSTGRE
####################

# Concise compilation guide of the database:
# https://www.postgresql.org/docs/9.6/static/install-short.html

# update & upgrade Entware packages
opkg update
opkg upgrade

# Install utilities:
echo -e "\n[Installing utilities...]"
opkg install tar wget ca-certificates

# Install development headers, if necessary...
if [ ! -d "/opt/include" ] || [ ! -f "/opt/include/zlib.h" ] || [ ! -f "/opt/include/zconf.h" ]; then
	# download development headers for Entware-ng
	echo -e "\n[Downloading development headers...]"
	wget "$DH_URL"

	# extract development headers into the "include" subfolder
	echo -e "\n[Extracting development headers...]"
	mkdir "include"
	tar -xf "include.tar.gz" -C "include"
	
	# install the required headers into Entware-ng's "include" folder
	echo -e "\n[Installing required development headers...]"
	mkdir /opt/include 2> /dev/null
	mv include/readline /opt/include/readline 2> /dev/null
	mv include/zlib.h /opt/include/zlib.h 2> /dev/null
	mv include/zconf.h /opt/include/zconf.h 2> /dev/null
fi

# Extract PostgreSQL and go inside:
echo -e "\n[PostgreSQL: extracting...]"
tar -xf "../postgresql-9.6.2.tar.gz"
cd "postgresql-9.6.2"

# Install tool required or recommended for compilation:
echo -e "\n[PostgreSQL: installing compilation dependencies...]"
opkg install busybox ldd gawk grep sed	# needed to generate Makefile or recommended for compilation
opkg install gcc zlib libreadline	# direct compilation dependencies

# Prepare environment for compilation:
# Note: this is the single most important command in the whole script! :)
source "/opt/bin/gcc_env.sh"

# Finally, let's configure and generate Makefile:
echo -e "\n[PostgreSQL: configuring...]"
./configure --prefix="$PG_ROOT"

# Note: currently unneeded code to register our own prefix (/opt/local) into Entware...
<<NOTNEEDEDANYMORE
{
	# first, check that Entware's linker comes first
	if [[ ! "$(which ldconfig)" == /opt/* ]]; then
		echo "Error: the database will not compile successfully if your PATH doesn't point to '/opt/bin' before it points to the system folders. By default, you should not see this error so something or someone likely changed your PATH."
		exit 1
	fi
	
	# if it is, ensure the linker's config file exists
	if [ ! -f "/opt/etc/ld.so.conf" ]; then
		touch "/opt/etc/ld.so.conf"
	fi
	
	# once that's done, add our path to the config (unless it's already there)
	if [ -z "$(grep -i '/opt/local/lib' /opt/etc/ld.so.conf)" ]; then
		echo "/opt/local/lib" >> "/opt/etc/ld.so.conf"
	fi
	
	# and now, only rebuilding the cache remains
	ldconfig
}
NOTNEEDEDANYMORE

####################
# COMPILE POSTGRE
####################

# Install prerequisites:
echo -e "\n[PostgreSQL: installing compilation dependencies...]"
opkg install make

# Compile the database:
echo -e "\n[PostgreSQL: compiling... entertain yourself for the next 10-110 minutes :)]"
make --silent

####################
# INSTALL POSTGRE
####################

# Install the database:
# Note: due to a bug somewhere, installation is not successful on the first try. It fails
# on trying to move individual files into erroneous locations, e.g.:
#	./bin/postgres/postgres
# You see, 'postgres' is a binary tool and the correct installation location is './bin', not
# './bin/postgres'. Somehow, the last path component is duplicated sometimes. Nevertheless,
# each successive call comes closer and closer to successful installation. Does that make
# sense to anyone?
#
# So, let's call the installation command until it finally succeeds :). Hard limit shall be
# 30 iterations in total. As for me, 13th iteration was the lucky one. Weird, 13 usually
# isn't thought of as a lucky number :).
#
echo -e "\n[PostgreSQL: installing and launching...]"
ITER=1
RET_CODE=1
until [ $RET_CODE -eq 0 ];
do
	echo "--- Commencing iteration #$ITER"
	make --silent install
	RET_CODE=$?
	ITER=$((ITER+1))
done

# Get out of the postgre root folder (into the 'tmp' folder created above):
cd ..

# Handle the 'postgres' user:
if [ $(id -u postgres > /dev/null 2>&1; echo $?) -eq 1 ]; then
	echo -e "--- Creating the 'postgres' user"
	useradd postgres
else
	echo -e "--- The 'postgres' user exists already... skipping"
fi

# Set up the 'sudo' command:
opkg install sudo
if [ ! -z "$(sudo -u postgres whoami | grep -i 'is not in the sudoers file')" ]; then
	# the current user doesn't have privilege to use sudo... first, make a copy of /opt/etc/sudoers
	cp /opt/etc/sudoers sudoers.mod

	# then edit the copied sudoers file
	if [ "$(whoami)" = "admin" ]; then
		# change the default 'root ALL=(ALL) ALL' line into 'admin ALL=(ALL) ALL'
		sed -i "s:root ALL=(ALL) ALL:admin ALL=(ALL) ALL:" sudoers.mod
	else
		# add the '<current-user> ALL=(ALL) ALL' line
		echo "$(whoami) ALL=(ALL) ALL" >> sudoers.mod
	fi
	
	# finally, check the edited sudoers file for any mishaps
	if [ -z "$(visudo -c -f sudoers.mod | grep -i 'parsed OK')" ]; then
		# something went wrong when editing the file
		echo "Error: failed to ensure sudo privileges for '$(whoami)'."
		exit 1
	else
		# otherwise, we can safely replace the original file
		mv /opt/etc/sudoers /opt/etc/sudoers.bckp
		mv sudoers.mod /opt/etc/sudoers
		chown admin /opt/etc/sudoers
		chmod 440 /opt/etc/sudoers
	fi
fi

# TODO: this is only temporary !!!!!!!!!!!!!!!!!
echo "Done: okay... that's it for now :)."
exit 1

# Verify that we setup the sudo command correctly:
if [ "$(sudo -u postgres whoami)" != "postgres" ]; then
	echo "Error: failed to properly configure the 'postgres' user with 'sudo'."
	exit 1
fi

# Define, create and chown the database's data folder:
echo -e "--- Setting up the data folder"
PG_DATA="$PG_ROOT-data"
mkdir "$PG_DATA"
chown postgres "$PG_DATA"

# Initiate the installed database as 'postgres':
echo -e "--- Initiating the database"
sudo -u postgres "$PG_ROOT/bin/initdb" -D "$PG_DATA"

# Start the installed database:
echo -e "--- Starting the database"
"$PG_ROOT/bin/pg_ctl" -D "$PG_DATA" -l "$PG_DATA/log" start

####################
# FINALIZE INSTALLATION
####################

# TODO: create the Coldsweat database...
echo -e "--- Testing the database"
"$PG_ROOT/bin/createdb" coldsweat
"$PG_ROOT/bin/psql" coldsweat

# Install the 'psycopg2' python module to support the database from within Coldsweat:
# Note: the module must find 'libpg' and 'pq_config' in the environment
echo -e "\n[Installing 'psycopg2' python module...]"
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$PG_ROOT/lib"
export PATH="$PATH:$PG_ROOT/bin"
pip install psycopg2

# TODO:
# Another script to uninstall the database...
# Another script to run the database from within Coldsweat's <data-folder>...
# Another file in Coldsweat's <data-folder> that contains the database to run/stop...

# TODO: this is only temporary !!!!!!!!!!!!!!!!!
echo "Done: okay... that's it for now :)."
exit 1

# cleanup
cd ..
rm -rf "tmp"

<<COMMENT
command -v patchelf >/dev/null 2>&1 || {
	# install patchelf...
	opkg update
	opkg upgrade # otherwise, things might complain for missing libraries
	opkg install gawk sed # otherwise, ./configure complains it can not create Makefile
	opkg install autoconf automake

	autoreconf --install
	aclocal
	autoconf
	automake --add-missing
	./configure --prefix=/opt/local
	make

	# this script is not included with +x in the tarball...
	chmod +x build-aux/install-sh 
	make install
	
	# update Entware's profile to know the location of our own compiled & installed software
	sed -i "s:^export PATH.*$:export PATH=/opt/bin:/opt/sbin:/opt/local/bin:$PATH" /opt/etc/profile
	sh /opt/etc/profile
}
COMMENT

