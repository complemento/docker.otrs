# --
# Copyright (C) 2001-2019 OTRS AG, https://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --
#  Note:
#
#  -->> Most OTRS configuration should be done via the OTRS web interface
#       and the SysConfig. Only for some configuration, such as database
#       credentials and customer data source changes, you should edit this
#       file. For changes do customer data sources you can copy the definitions
#       from Kernel/Config/Defaults.pm and paste them in this file.
#       Config.pm will not be overwritten when updating OTRS.
# --

package Kernel::Config;

use strict;
use warnings;
use utf8;
use Env;

sub Load {
    my $Self = shift;

    # ---------------------------------------------------- #
    # database settings                                    #
    # ---------------------------------------------------- #

    # The database host
    $Self->{DatabaseHost} = defined($ENV{APP_DatabaseHost}) ? $ENV{APP_DatabaseHost} : 'database';

    # The database name
    $Self->{Database} = defined($ENV{APP_Database}) ? $ENV{APP_Database} : 'otrs';

    # The database user
    $Self->{DatabaseUser} = defined($ENV{APP_DatabaseUser}) ? $ENV{APP_DatabaseUser} : 'otrs';

    # The password of database user. You also can use bin/otrs.Console.pl Maint::Database::PasswordCrypt
    # for crypted passwords
    $Self->{DatabasePw} = defined($ENV{APP_DatabasePw}) ? $ENV{APP_DatabasePw} : '';

    my $dbType = defined($ENV{APP_DatabaseType}) ? $ENV{APP_DatabaseType} : 'mysql';

    # The database DSN for MySQL ==> more: "perldoc DBD::mysql"
    if($dbType eq 'mysql') {
        $Self->{'DatabaseDSN'} = "DBI:mysql:database=$Self->{Database};host=$Self->{DatabaseHost}";
    }
    
    # The database DSN for PostgreSQL ==> more: "perldoc DBD::Pg"
    # if you want to use a local socket connection
    #$Self->{DatabaseDSN} = "DBI:Pg:dbname=$Self->{Database};";
    # if you want to use a TCP/IP connection
    if($dbType eq 'postgresql') {
        $Self->{DatabaseDSN} = "DBI:Pg:dbname=$Self->{Database};host=$Self->{DatabaseHost};";
    }
    # The database DSN for Microsoft SQL Server - only supported if OTRS is
    # installed on Windows as well
    if($dbType eq 'odbc') {
        $Self->{DatabaseDSN} = "DBI:ODBC:driver={SQL Server};Database=$Self->{Database};Server=$Self->{DatabaseHost},1433";
    }
    # The database DSN for Oracle ==> more: "perldoc DBD::oracle"
    # TODO: install DBD::oracle
    #if($ENV{APP_DatabaseType}=='oracle') {
        #$Self->{DatabaseDSN} = "DBI:Oracle://$Self->{DatabaseHost}:1521/$Self->{Database}";
        #$ENV{ORACLE_HOME}     = '/path/to/your/oracle';
        #$ENV{NLS_DATE_FORMAT} = 'YYYY-MM-DD HH24:MI:SS';
        #$ENV{NLS_LANG}        = 'AMERICAN_AMERICA.AL32UTF8';
    #}
    # ---------------------------------------------------- #
    # fs root directory
    # ---------------------------------------------------- #
    $Self->{Home} = '/opt/otrs';

    # ---------------------------------------------------- #
    # insert your own config settings "here"               #
    # config settings taken from Kernel/Config/Defaults.pm #
    # ---------------------------------------------------- #
    # $Self->{SessionUseCookie} = 0;
    # $Self->{CheckMXRecord} = 0;

    # ---------------------------------------------------- #

    # ---------------------------------------------------- #
    # data inserted by installer                           #
    # ---------------------------------------------------- #
    # $DIBI$

    $Self->{'FQDN'} = defined($ENV{APP_FQDN}) ? $ENV{APP_FQDN} : `hostname -f`;

    # Node ID from ENV
    $Self->{'NodeID'} = defined($ENV{APP_NodeID}) ? $ENV{APP_NodeID} : 1;

    # ---------------------------------------------------- #
    # ---------------------------------------------------- #
    #                                                      #
    # end of your own config options!!!                    #
    #                                                      #
    # ---------------------------------------------------- #
    # ---------------------------------------------------- #

    return 1;
}

# ---------------------------------------------------- #
# needed system stuff (don't edit this)                #
# ---------------------------------------------------- #

use Kernel::Config::Defaults; # import Translatable()
use parent qw(Kernel::Config::Defaults);

# -----------------------------------------------------#

1;
