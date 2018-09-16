#!/bin/sh

# reference of QDK's build script variables
<<BSV
These variables override command line arguments and should be accessible from package specific functions.
- QDK_VERSION
	QDK version.
- QDK_PATH
	Path to QDK installation.
- QDK_USER_CONFIG_FILE
	Path to the user's configuration file. Default: '~/.qdkrc'.
- QDK_QPKG_CONFIG
	Path to the QPKG configuration file. Default: 'qpkg.cfg'.
- QDK_PACKAGE_ROUTINES
	Path to the file with package specific functions. Default: 'package_routines'.
- QDK_SCRIPTS_DIR
	Path to the script directory, used by 'qbuild'. Default: '$QDK_PATH/scripts'.
- QDK_TEMPLATE_DIR
	Path to directory with '--create-env' templates. Default:' $QDK_PATH/template'.
- QDK_INSTALL_SCRIPT
	Path to the generic installation script. Default: '$QDK_SCRIPTS_DIR/qinstall.sh'.
- QDK_VERBOSE
	Indicates qbuild's level of verbosity.
	0: quiet mode
	1: normal mode (default)
	2: verbose mode
	3: debug mode
	4: extra verbose debug mode
- QDK_STRICT
	Should warnings be treated as errors? Default: 'FALSE'.
- QDK_FORCE_CONFIG
	Should qbuild ignore missing configuration files (useful for dynamic ones)? Default: 'FALSE'.
- QDK_COMPRESS_METHOD
	Sets compression method for the included files. Values: gzip (default), bzip2, 7zip.
- QDK_COMPRESS_FILE
	Name for the compressed data archive. Default: 'data'.
	gzip -> 'data.tar.gz'
	bzip2 -> 'data.tar.bz2'
	7zip -> 'data.tar.7z'.
- QDK_CONTROL_FILE
	Name for the included metadata archive. Default: 'control.tar'. Only used internally by qbuild.
- QDK_SETUP
	Location of the setup script.
- QDK_TEARDOWN
	Location of the teardown script.
- QDK_PRE_BUILD
	Location of the pre-build script.
- QDK_POST_BUILD
	Location of the post-build script.
- QDK_ROOT_DIR
	Location of the QPKG being built. Default: current working directory.
- QDK_BUILD_DIR
	Output location for qbuild. Default: '$QDK_ROOT_DIR/build'.
- QDK_BUILD_VERSION
	QDK version to build against. Default: 'QPKG_VER' from the QPKG configuration file.
	Side effect: this variable will overwrite 'QPKG_VER' value in the QPKG configuration file.
- QDK_BUILD_MODEL
	Target QNAP models. Default: any model.
	Note: installation of a QPKG package on the command line will not check models.
- QDK_BUILD_ARCH
	Target QNAP architectures, comma-separated. Values: 'arm-x09', 'arm-x19', 'x86' and 'x86_64'.
	By default, qbuild tries to determine this automatically based on available directories in $QDK_ROOT_DIR.
	Architecture check is done automatically when installing QPKG packages.
- QDK_RSYNC_EXCLUDE
	Exclude files from being bundled in the compressed data file. Specify patterns:
	Example: QDK_RSYNC_EXCLUDE="--exclude=PATTERN1 --exclude=PATTERN2 ...".
- QDK_RSYNC_EXCLUDE_FROM
	Take the exclusion patterns from a file (one per line).
	Example: QDK_RSYNC_EXCLUDE_FROM="--exclude-from=FILE".
- QDK_SIGN
	Should a digital signature be added to the QPKG? Requires 'gpg2' to be installed and available.
- QDK_GPG_APP
	Path to 'gpg2'. Default: 'usr/bin' probably.
- QDK_GPG_NAME
	Identity of private key that shall be used for the digital signature.
- QDK_GPG_PUBKEYRING
	Path to public keyring to be used for verifying signatures. Default: '/etc/config/qpkg.gpg'.
	Note: in practice, better set it to '/root/.gnupg/pubring.gpg'. QNAP is being funny.
- QDK_GPG_KEYPATH
	Path to default keyrings to be used for adding signatures. Default: '$GNUPGHOME'.
- QDK_SIGNATURE
	Use only specified type of digital signature. Currently, only 'gpg' is supported.
- QDK_DATA_DIR_CONFIG
	Path to directory with full-path configuration files. Default: '$QDK_ROOT_DIR/config'.
	Example: './etc/config/myApp.conf' will be automatically moved to '/etc/config/myApp.conf'.
- QDK_DATA_DIR_ICONS
	Path to the QPKG's icons. Default: '$QDK_ROOT_DIR/icons'. Expected icons:
	'${QPKG_NAME}.gif' (64x64) - QPKG is enabled.
	'${QPKG_NAME}_80.gif' (80x80) - QPKG overview in App Center.
	'${QPKG_NAME}_gray.gif' (64x64) - QPKG is disabled.
- QDK_DATA_DIR_X09
	Path to files specific for 'arm-x09' packages. Default: '$QDK_ROOT_DIR/arm-x09'.
- QDK_DATA_DIR_X19
	Path to files specific for 'arm-x19' packages. Default: '$QDK_ROOT_DIR/arm-x19'.
- QDK_DATA_DIR_X86
	Path to files specific for 'x86' packages. Default: '$QDK_ROOT_DIR/x86'.
- QDK_DATA_DIR_X86_64
	Path to files specific for 'x86_64' packages. Default: '$QDK_ROOT_DIR/x86_64'.
- QDK_DATA_DIR_SHARED
	Path to files common to all architectures. Platform-dependent files overwrite these in case of a conflict.
	Default: '$QDK_ROOT_DIR/shared'.
- QDK_DATA_FILE
	The contain-it-all data file. If set, the previous 6 variables (paths) are ignored.
	Files specified through '$QDK_EXTRA_FILE' are still included, though.
- QDK_EXTRA_FILE
	Extra files to be included in the QPKG. Paths must be absolute or relative to '$QDK_ROOT_DIR'.
	Unlike other options, these files must be extracted manually by package specific functions.
	Multiple QDK_EXTRA_FILE may be specified.
- QDK_QPKG_FILE
	Name of the last built QPKG package (stored in '$QDK_BUILD_DIR'). Useful for post-processing.
BSV

# usage of the 'gbuild' command
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
# THE ACTUAL BUILDING PROCESS
# NOTES:
# - CLI/scripts override file-based configuration ("~/.qdkrc"); see "--section"
# - file-based configuration overrides the system-wide configuration file ("/etc/config/qdk.conf")

# - QDK_SIGN
#	Should a signature be added to the QPKG? Requires 'gpg2' to be installed and available.
# - QDK_GPG_APP
#	Path to 'gpg2'. Default: '/usr/bin' probably.
# - QDK_GPG_NAME
#	Identity of the signer (leading to their private key)
# - QDK_GPG_PUBKEYRING
#	Path to public keyring to be used for verifying signatures. Default: '/etc/config/qpkg.gpg'.
#	Note: in practice, better set it to '/root/.gnupg/pubring.gpg'. QNAP is being funny.
# - QDK_GPG_KEYPATH
#	Path to default keyrings to be used for adding signatures. Default: '$GNUPGHOME'.
# - QDK_SIGNATURE
#	Use only specified type of digital signature. Currently, only 'gpg' is supported.
# - QDK_DATA_DIR_ICONS
#	Path to the QPKG's icons. Default: '$QDK_ROOT_DIR/icons'. Expected icons:
#	'${QPKG_NAME}.gif' (64x64) - QPKG is enabled.
#	'${QPKG_NAME}_80.gif' (80x80) - QPKG overview in App Center.
#	'${QPKG_NAME}_gray.gif' (64x64) - QPKG is disabled.


qbuild --strict --verbose --exclude ".git" --exclude ".gitignore" --exclude ".gitkeep" --exclude ".DS_Store" --exclude "README.md" --exclude "icons/QColdsweat_80.art3" --exclude "icons/QColdsweat_gray.art3" 
