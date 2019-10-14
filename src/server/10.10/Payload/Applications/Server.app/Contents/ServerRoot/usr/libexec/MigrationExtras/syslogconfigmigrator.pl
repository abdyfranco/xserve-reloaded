#!/usr/bin/perl

# Copyright (c) 2013-2015 Apple Inc. All Rights Reserved.
#
# IMPORTANT NOTE: This file is licensed only for use on Apple-branded
# computers and is subject to the terms and conditions of the Apple Software
# License Agreement accompanying the package this file is a part of.
# You may not port this file to another platform without Apple's written consent.
#

BEGIN {
    if ( -e "/Applications/Server.app/Contents/ServerRoot/usr/libexec/MigrationExtras/" ) {
        push @INC,"/Applications/Server.app/Contents/ServerRoot/usr/libexec/MigrationExtras/";
    }
    else {
        printf("Server Migration perl lib can not be found.\n");
    }
}
use MigrationUtilities;

my $mu = new MigrationUtilities;

## Cleanup Script for syslog.conf

##################   Input Parameters  #######################
# --purge <0 | 1>   "1" means remove any files from the old system after you've migrated them, "0" means leave them alone.
# --sourceRoot <path> The path to the root of the system to migrate
# --sourceType <System | TimeMachine> Gives the type of the migration source, whether it's a runnable system or a
#                  Time Machine backup.
# --sourceVersion <ver> The version number of the old system (like 10.6 - 10.10). Since we support migration from 10.6 - 10.10.
# --targetRoot <path> The path to the root of the new system.
# --language <lang> A language identifier, such as \"en.\" Long running scripts should return a description of what they're doing
#                   (\"Migrating Open Directory users\"), and possibly provide status update messages along the way. These messages
#                   need to be localized (which is not necessarily the server running the migration script).
#                   This argument will identify the Server Assistant language. As an alternative to doing localization yourselves
#                   send them in English, but in case the script will do this it will need this identifier.
#
# Example: /Applications/Server.app/Contents/ServerRoot/System/Library/ServerSetup/MigrationExtras/111-syslogconfigmigrator.pl --purge 0 --language en --sourceType System --sourceVersion 10.6 --sourceRoot "/Library/Server/Previous" --targetRoot "/"

#################################   Constants  #################################
$CP = "/bin/cp";
$ECHO = "/bin/echo";
$MV = "/bin/mv";

#################################   PATHS  #################################
$SYSTEM_PLIST = "/System/Library/CoreServices/SystemVersion.plist";
$SERVER_PLIST = "/System/Library/CoreServices/ServerVersion.plist";
$MIGRATION_LOG = "/Library/Logs/ServerSetup.log";

### ###
$syslog_path = "/private/etc/syslog.conf";

#################################  GLOBALS #################################
$gPurge="0";		# Default is don't purge
$gSourceRoot="";
$gSourceType="";
$gSourceVersion="";
$gTargetRoot="";
$gLanguage="en";	# Default is english

$DEBUG = 0;
$FUNC_LOG = 0;

$SRV_MAJOR="0";  #10
$SRV_MINOR="0";  # 6
$SRV_UPDATE="-"; #00

$MINVER="10.6"; # => 10.6
$MAXVER="10.10.0"; # <  10.10.0

$LANGUAGE = "en"; # Should be Tier-0 only in iso format [en, fr, de, ja], we default this to English, en.
$PURGE = 0;       # So we will be default copy the items if there's no option specified.
$VERSION = "";    # This is the version number of the old system passed into us by Server Assistant. [10.6.x, 10.7.x, and potentially 10.8.x]
$PREV_EXT = ".previous";

if($ENV{DEBUG} eq 1) {$DEBUG = '1';}
if($ENV{FUNC_LOG} eq 1) {$FUNC_LOG = '1';}

if (${DEBUG}) { print("args count := " . $#ARGV . "\n"); }  #needs to be 11!

if($#ARGV != 11) {
	Usage();
	exit(1);
}

@Items=$mu->ParseOptions(@ARGV);

validateOptionsAndDispatch(@Items);
exit();

##################   Functions   #######################
sub migrateSysLog()
{
    if (${FUNC_LOG}) { print("migrateSysLog : S\n"); }

	$srcPath="$gSourceRoot" . "${syslog_path}";
	$dstPath="$gTargetRoot" . "${syslog_path}";

	#Now remove the item specified at the path.
	if(-e "${srcPath}") {
		#If the dst path exists, move it aside.
		if (-e "${dstPath}") {
			if (${DEBUG}) {
				printf("%s\n", qq(${MV} -f ${dstPath} ${dstPath}${PREV_EXT}));
			} else {
				qx(${MV} -f \"${dstPath}\" \"${dstPath}${PREV_EXT}\");
			}
		}
        #Copy the source file to destination.
		if (${DEBUG}) {
			printf("%s\n", qq(${CP} "${srcPath}" "${dstPath}"));
		} else {
			qx(${CP} \"${srcPath}\" \"${dstPath}\");
		}
	} else {
        printf("Missing: %s\n", ${srcPath});
	}
    if (${FUNC_LOG}) { print("migrateSysLog : E\n"); }
}


################################################################################
## This is to address issue: 7080665
## Making sure we have necessary entries in the configuration for syslog.
##
sub fixUpFile()
{
    if (${FUNC_LOG}) { print("migrateSysLog : S\n"); }

	$DaFile="$gTargetRoot" . '/private/etc/syslog.conf';
	$DaNewFile="$gTargetRoot" . '/private/etc/new_syslog.conf';
	$MatchLine='*.notice;authpriv,remoteauth,ftp,install.none;kern.debug;mail.crit	/var/log/system.log';
	$NewLine1='*.notice;kern,authpriv,remoteauth,ftp,install,mail.none;mail.crit	/var/log/system.log';
	$NewLine2='kern.*	/var/log/kernel.log';
	$DidModify='0';
	$Ext='.previous';
	open(InFile, "< $DaFile") or die ("Couldn't open the file $DaFile for reading.\n");
	@Lines = <InFile>;
	close(InFile);
	
	open (OUTFILE, "> $DaNewFile");
	for($cnt = 0; $cnt<=$#Lines; $cnt++) {
		$Line = $Lines[$cnt]; chomp($Line);
		if ($Line eq ${MatchLine}){
			print OUTFILE ${NewLine1} . "\n";
			print OUTFILE ${NewLine2} . "\n";
			$DidModify="1";
		} else {
			print OUTFILE "$Line" , "\n";
		}
	}
	close (NEWFILE);
	
	if (${DidModify} == "1") {
		system("mv", "${DaFile}", "${DaFile}${Ext}");
		system("mv", "${DaNewFile}", "${DaFile}");
		if (${DEBUG}) {
			printf("Did modify %s.\n", "${DaFile}");
		}
	} else {
		unlink("${DaNewFile}");
		if (${DEBUG}) {
			printf("Removed tmp file %s.\n", "${DaNewFile}");
		}
	}

    if (${FUNC_LOG}) { print("migrateSysLog : E\n"); }
}

################################################################################
sub validateOptionsAndDispatch()
{
    if (${FUNC_LOG}) { print("validateOptionsAndDispatch : S\n"); }
	%BigList = @_;
	
	#Set the globals with the options passed in.
	$gPurge=$BigList{"--purge"};
	$gSourceVersion=$BigList{"--sourceVersion"};
	$gLanguage=$BigList{"--language"};
	$gSourceType=$BigList{"--sourceType"};
	$gSourceRoot=$BigList{"--sourceRoot"};
	$gTargetRoot=$BigList{"--targetRoot"};
	
    if (${DEBUG}) {
        qx(${ECHO} purge: "${gPurge}" >> "${MIGRATION_LOG}");
        qx(${ECHO} sourceRoot: "${gSourceRoot}" >> "${MIGRATION_LOG}");
        qx(${ECHO} sourceType: "${gSourceType}" >> "${MIGRATION_LOG}");
        qx(${ECHO} sourceVersion: "${gSourceVersion}" >> "${MIGRATION_LOG}");
        qx(${ECHO} targetRoot: "${gTargetRoot}" >> "${MIGRATION_LOG}");
        qx(${ECHO} language: "${gLanguage}" >> "${MIGRATION_LOG}");
    }
	
	#If our sourceRoot is not from "/Library/Server/Previous" then we will not purge the source no matter what!
	if (! ("${gSourceRoot}" =~ "/Library/Server/Previous") ) {
        printf("Overriding purge option: %s\n", ${gPurge});
		$gPurge = 0;
	}
	
	# Get source system version parts
   	if (${DEBUG}) {printf("sourceVersion := %s\n", $gSourceVersion);}
	($SRV_MAJOR, $SRV_MINOR, $SRV_UPDATE)=$mu->serverVersionParts(${gSourceVersion});

	## Need to fix up the paths we care about with the --sourceRoot we received
	$OLD_SYSTEM_PLIST =  "$gSourceRoot" . "${SYSTEM_PLIST}";
	$OLD_SERVER_PLIST =  "$gSourceRoot" . "${SERVER_PLIST}";
	
    if (${DEBUG}) { 
		print("${OLD_SYSTEM_PLIST}\n");
		print("${OLD_SERVER_PLIST}\n");
	}
	
SWITCH: {
	if( ($mu->pathExists("${gSourceRoot}")) && ($mu->pathExists("${gTargetRoot}")) ) {
		if ($mu->isValidLanguage($gLanguage)) {
			if ($mu->isValidVersion($gSourceVersion)) {
				$valid = 1;
				migrateSysLog();
				fixUpFile();
			} else {
				printf("Did not supply a valid version for the --sourceVersion parameter, needs to be >= %s and < %s\n", $MINVER, $MAXVER);
				Usage(); exit(1);
			}
		} else {
			print("Did not supply a valid language for the --language parameter, needs to be one of [en|fr|de|ja]\n");
			Usage(); exit(1);
		}
	} else {
		print("Source and|or destination for upgrade/migration does not exist.\n");
		Usage(); exit(1);
	} last SWITCH;
	$nothing = 1;
}
    if($nothing eq 1)
	{ print("Legal options were not supplied!\n"); Usage(); exit(1); }
    if (${FUNC_LOG}) { print("validateOptionsAndDispatch : E\n"); }
}

################################################################################
# Show proper usage
sub Usage()
{
	print("--purge <0 | 1>   \"1\" means remove any files from the old system after you've migrated them, \"0\" means leave them alone." . "\n");
	print("--sourceRoot <path> The path to the root of the system to migrate" . "\n");
	print("--sourceType <System | TimeMachine> Gives the type of the migration source, whether it's a runnable system or a " . "\n");
	print("                  Time Machine backup." . "\n");
	print("--sourceVersion <ver> The version number of the old system (like 10.6 - 10.10). Since we support migration from 10.6" . "\n");
	print("                  through 10.10 installs." . "\n");
	print("--targetRoot <path> The path to the root of the new system." . "\n");
	print("--language <lang> A language identifier, such as \"en.\" Long running scripts should return a description of what they're doing " . "\n");
	print("                  (\"Migrating Open Directory users\"), and possibly provide status update messages along the way. These messages " . "\n");
	print("                  need to be localized (which is not necessarily the server running the migration script). " . "\n");
	print("                  This argument will identify the Server Assistant language. As an alternative to doing localization yourselves " . "\n");
	print("                  send them in English, but in case the script will do this it will need this identifier." . "\n");
	print(" " . "\n");
}