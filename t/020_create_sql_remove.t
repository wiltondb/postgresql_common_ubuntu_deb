#!/usr/bin/perl -w
# We create a cluster, execute some basic SQL commands, drop it again, and
# check that we did not leave anything behind.

use strict; 

use lib 't';
use TestLib;

use lib '/usr/share/postgresql-common';
use PgCommon;

use Test::More tests => 32 * ($#MAJORS+1);

sub check_major {
    my $v = $_[0];

    # create cluster
    ok ((system "pg_createcluster $v main --start >/dev/null") == 0,
	"pg_createcluster $v main");

    # verify that pg_autovacuum is running if it is available
    my $pg_autovacuum = get_program_path 'pg_autovacuum', $v;

    if ($pg_autovacuum) {
	like ((ps 'pg_autovacuum'), qr/$pg_autovacuum/, 'pg_autovacuum is running');
    } else {
	is ((ps 'pg_autovacuum'), '', "No pg_autovacuum available for version $v");
    }

    # verify that the correct client version is selected
    like_program_out 'postgres', 'psql --version', 0, qr/^psql \(PostgreSQL\) $v\.\d/,
        'pg_wrapper selects version number of cluster';

    # verify that the cluster is displayed
    my $ls = `pg_lsclusters -h`;
    $ls =~ s/\s*$//;
    is $ls, "$v     main      5432 online postgres /var/lib/postgresql/$v/main       /var/log/postgresql/postgresql-$v-main.log",
	'pg_lscluster reports online cluster on port 5432';

    ok_dir '/var/run/postgresql', ['.s.PGSQL.5432', '.s.PGSQL.5432.lock'], 'Socket is in /var/run/postgresql';

    # verify that the postmaster does not have an associated terminal
    unlike_program_out 0, 'ps -o tty -U postgres h', 0, qr/tty|pts/,
        'postmaster processes do not have an associated terminal';

    # Create user nobody, a database 'nobodydb' for him, check the database list
    my $outref;
    is ((exec_as 'nobody', 'psql -l 2>/dev/null', $outref), 2, 'psql -l fails for nobody');
    is ((exec_as 'postgres', 'createuser nobody -D ' . (($v ge '8.1') ? '-R -s' : '-A')), 0, 'createuser nobody');
    is ((exec_as 'postgres', 'createdb -O nobody nobodydb'), 0, 'createdb nobodydb');
    is ((exec_as 'nobody', 'psql -ltA', $outref), 0, 'psql -ltA succeeds for nobody');
    if ($v ge '8.1') {
	is ($$outref, 'nobodydb|nobody|UTF8
postgres|postgres|UTF8
template0|postgres|UTF8
template1|postgres|UTF8
', 'psql -ltA output');
    } else {
	is ($$outref, 'nobodydb|nobody|UNICODE
template0|postgres|UNICODE
template1|postgres|UNICODE
', 'psql -ltA output');
}

    # Then fill nobodydb with some data.
    is ((exec_as 'nobody', 'psql nobodydb -c "create table phone (name varchar(255) PRIMARY KEY, tel int NOT NULL)" 2>/dev/null'), 
	0, 'SQL command: create table');
    is ((exec_as 'nobody', 'psql nobodydb -c "insert into phone values (\'Bob\', 1)"'), 0, 'SQL command: insert into table values');
    is ((exec_as 'nobody', 'psql nobodydb -c "insert into phone values (\'Alice\', 2)"'), 0, 'SQL command: insert into table values');
    is ((exec_as 'nobody', 'psql nobodydb -c "insert into phone values (\'Bob\', 3)"'), 1, 'primary key violation');

    # Check table contents
    is_program_out 'nobody', 'psql -tAc "select * from phone order by name" nobodydb', 0,
        'Alice|2
Bob|1
', 'SQL command output: select';

    # Check pg_maintenance
    if ($pg_autovacuum || $v ge '8.1') {
        like_program_out 0, 'pg_maintenance', 0, qr/^Skipping/, 'pg_maintenance skips autovacuumed cluster';
    } else {
        like_program_out 0, 'pg_maintenance', 0, qr/^Doing/, 'pg_maintenance handles non-autovacuumed cluster';
    }
    like_program_out 0, 'pg_maintenance --force', 0, qr/^Doing/, 
        'pg_maintenance --force always handles cluster';

    # Drop database and user again.
    sleep 1;
    is ((exec_as 'nobody', 'dropdb nobodydb', $outref, 0), 0, 'dropdb nobodydb', );
    is ((exec_as 'postgres', 'dropuser nobody', $outref, 0), 0, 'dropuser nobody');

    # stop server, clean up, check for leftovers
    ok ((system "pg_dropcluster $v main --stop-server") == 0, 
	'pg_dropcluster removes cluster');

    ok_dir "/etc/postgresql/$v", [], "No files in /etc/postgresql/$v left behind";
    ok_dir "/var/lib/postgresql/$v", [], "No files in /var/lib/postgresql/$v left behind";
    ok_dir '/var/run/postgresql', [], 'No files in /var/run/postgresql left behind';
    ok_dir '/var/log/postgresql', [], 'No files in /var/log/postgresql left behind';
    is ((ps 'postmaster'), '', 'No postmaster processes left behind');
    is ((ps 'pg_autovacuum'), '', 'No pg_autovacuum processes left behind');
}

foreach (@MAJORS) { 
    check_major $_;
}

# vim: filetype=perl
