#!/bin/sh

# This script installs the PostgreSQL v9.5.5 database and takes the following arguments:
# 	$1 - path to where to put the installation (i.e. prefix).
# Requirements:
# - Entware-ng version >= 0.97 installed.
# - QColdsweat installed.
#

# IMPORTANT NOTE: ideally, set the prefix to '/share/<default-mount>/<target-folder>',
# where '<default-mount>' is something like:
#	- MD0_DATA
#	- HDA_DATA
#	- CACHEDEV1_DATA
# and '<target-folder>' something like:
#	- pgsql-9.5.5
# Leave the system and '/mnt/ext' alone. Use the suggested prefix, unless your QNAP has
# an external disk not managed by the system and you'd like to install the database there.
#

# Alias the prefix:
PREFIX="$1"

# Safety check:
if [ -z "$PREFIX" ]; then
	echo "Error: missing argument denoting installation prefix."
	exit 1
fi

# Make a special folder for this operation:
mkdir "tmp"
cd "tmp"

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
# CONFIGURE
####################

# Concise compilation guide of the database:
# https://www.postgresql.org/docs/9.5/static/install-short.html

# Install utilities:
echo -e "\n[Installing utilities...]"
opkg install tar wget ca-certificates

# Download PostgreSQL sources:
echo -e "\n[Downloading PostgreSQL sources...]"
wget "https://ftp.postgresql.org/pub/source/v9.5.5/postgresql-9.5.5.tar.gz"

# Download development headers for Entware-ng:
echo -e "\n[Downloading development headers...]"
wget "$DH_URL"

# Extract development headers into the "include" subfolder:
echo -e "\n[Extracting development headers...]"
mkdir "include"
tar -xf "include.tar.gz" -C "include"

# Move the required headers into Entware-ng's "include" folder:
# Note: if the stuff already exists, nevermind...
echo -e "\n[Installing required development headers...]"
mkdir /opt/include
# mv include/readline /opt/include/readline
mv include/zlib.h /opt/include/zlib.h
mv include/zconf.h /opt/include/zconf.h

# Extract PostgreSQL and go inside:
echo -e "\n[Extracting PostgreSQL sources...]"
tar -xf "postgresql-9.5.5.tar.gz"
cd "postgresql-9.5.5"

echo -e "\n[Installing configure dependencies...]"

# This is needed to generate Makefile with the configure command:
opkg install gawk sed

# This is needed for configure/make:
opkg install gcc zlib # libreadline

# Finally, let's configure and generate Makefile:
echo -e "\n[Configuring PostgreSQL...]"
./configure --prefix="$PREFIX"

####################
# COMPILE
####################

# Install prerequisites:
echo -e "\n[Installing compilation dependencies...]"
opkg install make

# Compile the database:
echo -e "\n[Compiling PostgreSQL... entertain yourself for the next 30-110 minutes :)]"
make

####################
# INSTALL
####################

# Create the target directory if needed:
if [ ! -d "$PREFIX" ]; then
	mkdir "$PREFIX"
fi

# Install the database:
# echo -e "\n[Installing PostgreSQL...]"
# make install

# Install the 'psycopg2' python module to support the database from within Coldsweat:
# Note: must patch the environment to find 'libpg' and 'pq_config' that come with the database
# echo -e "\n[Installing 'psycopg2' python module...]"
# export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$SYS_QPKG_INSTALL_PATH/PostgreSQL/lib"
# export PATH="$PATH:$SYS_QPKG_INSTALL_PATH/PostgreSQL/bin"
# pip install psycopg2

# cleanup
cd ./../..
rm -rf "tmp"
