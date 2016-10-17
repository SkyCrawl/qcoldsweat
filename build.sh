#!/bin/sh

<<USAGE
qbuild [--extract QPKG [DIR]] [--create-env NAME] [-s|--section SECTION]
    [--root ROOT_DIR] [--build-arch ARCH] [--build-version VERSION]
	[--build-number NUMBER] [--build-model MODEL] [--build-dir BUILD_DIR]
	[--force-config] [--setup SCRIPT] [--teardown SCRIPT]
	[--pre-build SCRIPT] [--post-build SCRIPT] [--exclude PATTERN]
	[--exclude-from FILE] [--gzip|--bzip2|--7zip] [--sign] [--gpg-name ID]
	[--verify QPKG] [--add-sign QPKG] [--import-key KEY] [--remove-key ID]
	[--list-keys] [--query OPTION QPKG] [-v|--verbose] [-q|--quiet]
	[--strict] [-?|-h|--help] [--usage] [-V|--version]
    
    -s
    --section SECTION
        Add SECTION to the list of searched sections in the configuration file.
        A section is a named set of definitions. By default, the DEFAULT section
        will be searched and then any sections specified on the command line.
    --root ROOT_DIR
        Use files and meta-data in ROOT_DIR when the QPKG is built (default is
        the current directory, '.').
    --build-version VERSION
        Use given version when QPKG is built (also updates the QPKG_VER
        definition in qpkg.cfg).
    --build-number NUMBER
        Use given build number when QPKG is built.
    --build-model MODEL
        Include check for given model in the QPKG package.
    --build-arch ARCH
        Build QPKG for specified ARCH (supported values: arm-x09, arm-x19, arm-x31, arm-x41, x86, x86_ce53xx,
        and x86_64). Only one architecture per option, but you can repeat the
        option on the command line to add multiple architectures.
    --build-dir BUILD_DIR
        Place built QPKG in BUILD_DIR. If a full path is not specified then it
        is relative to the ROOT_DIR (default is ROOT_DIR/build).
    --setup SCRIPT
        Run specified script to setup build environment. Called once before
        build process is initiated.
    --teardown SCRIPT
        Run specified script to cleanup after all builds are finished. Called
        once after all builds are completed.
    --pre-build SCRIPT
        Run specified script before the build process is started. Called before
        each and every build. First argument contains the architecture (one of
        arm-x09, arm-x19, arm-x31, arm-x41,x86, x86_ce53xx, and x86_64) and the second argument contains the
        location of the architecture specific code. For the generic build the
        arguments are empty.
    --post-build SCRIPT
        Run specified script after the build process is finished. Called after
        each and every build. First argument contains the architecture (one of
        arm-x09, arm-x19, arm-x31, arm-x41, x86, x86_ce53xx, and x86_64) and the second argument contains the
        location of the architecture specific code. For the generic build the
        arguments are empty.
    --exclude PATTERN
        Do not include files matching PATTERN in data package. This option is
        passed on to rsync and follows the same rules as rsync's --exclude
        option. Only one exclude pattern per option, but you can repeat the
        option on the command line to add multiple patterns.
    --exclude-from FILE
        Related to --exclude, but specifies a FILE that contains exclude
        patterns (one per line). This option is passed on to rsync and follows
        the same rules as rsync's --exclude-from option.
    --strict
        Treat warnings as errors.
    --force-config
        Ignore missing configuration files specified in QPKG_CONFIG.
    --query OPTION QPKG
        Retrieve information from QPKG. Available options:
          dump		dump settings from qpkg.cfg
          info		summary of settings in qpkg.cfg
          config	list configuration files
          require	list required packages
          conflict	list conflicting packages
          funcs		output package specific functions
    --sign
        Generate and insert digital signature to QPKG. By default the first key
        in the secret keyring is used.
    --add-sign QPKG
        Generate and insert digital signature to QPKG, replacing any existing
        signature.
    --gpg-name ID
        Use specified user ID to sign QPKG.
    --verify QPKG
        Verify digital signature assigned to QPKG.
    --list-keys
        Show keys in public keyring.
    --import-key KEY
        Import ASCII armored key to public keyring.        
    --remove-key ID
        Remove key with specified ID from public keyring.
    -q
    --quiet
        Silent mode. Do not write anything to standard output. Normally only
        error messages will be displayed.
    -v
    --verbose
        Verbose mode. Multiple options increase the verbosity. The maximum is 3.
USAGE

###################################################
# ACTUAL BUILD PROCESS
# NOTES:
# - CLI/scripts override file-based configuration ("~/.qdkrc"); see "--section"
# - file-based configuration overrides the system-wide configuration file ("/etc/config/qdk.conf")

qbuild --force-config --strict --verbose --exclude ".DS_Store"
