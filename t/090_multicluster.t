# Check operation with multiple clusters

use strict; 

use lib 't';
use TestLib;
use Socket;

use Test::More tests => 59;

# create fake socket at 5433 to verify that this port is skipped
socket (SOCK, PF_INET, SOCK_STREAM, getprotobyname('tcp')) or die "socket: $!";
bind (SOCK, sockaddr_in(5433, INADDR_ANY)) || die "bind: $! ";

# create clusters
is ((system "pg_createcluster $MAJORS[0] old --start >/dev/null"), 0, "pg_createcluster $MAJORS[0] old");
is ((system "pg_createcluster $MAJORS[-1] new1 --start >/dev/null"), 0, "pg_createcluster $MAJORS[-1] new1");
is ((system "pg_createcluster $MAJORS[-1] new2 --start -p 5440 >/dev/null"), 0, "pg_createcluster $MAJORS[-1] new2");
like_program_out 'postgres', 'pg_lsclusters -h', 0, qr/.*5432.*5434.*5440.*/s,
    'clusters have the correct ports, skipping used 5433';

my $old = "$MAJORS[0]/old";
my $new1 = "$MAJORS[-1]/new1";
my $new2 = "$MAJORS[-1]/new2";

# move user_clusters aside for the test; this will ensure that client programs
# work correctly without any file at all
if (-f '/etc/postgresql-common/user_clusters') {
    ok ((rename '/etc/postgresql-common/user_clusters',
    '/etc/postgresql-common/user_clusters.psqltestsuite'),
    'Temporarily moving away /etc/postgresql-common/user_clusters');
} else {
    pass '/etc/postgresql-common/user_clusters does not exist';
}

# check basic cluster selection
like_program_out 0, 'psql --version', 0, qr/^psql \(PostgreSQL\) $MAJORS[0]\.\d+\b/, 
    'pg_wrapper selects port 5432 as default cluster';
like_program_out 0, "psql --cluster $new1 --version", 0, 
    qr/^psql \(PostgreSQL\) $MAJORS[-1]\.\d+\b/, 
    'pg_wrapper --cluster works';
like_program_out 0, "psql --cluster $MAJORS[-1]/foo --version", 1, 
    qr/Cluster specified with --cluster does not exist/, 
    'pg_wrapper --cluster errors out for invalid cluster';

# create a database in new1 and check that it doesn't appear in new2
is_program_out 'postgres', "createdb --cluster $new1 test", 0, 
    "CREATE DATABASE\n";
like_program_out 'postgres', "psql -Atl --cluster $new1", 0, 
    qr/test\|postgres\|/,
    'test db appears in cluster new1';
unlike_program_out 'postgres', "psql -Atl --cluster $new2", 0, 
    qr/test\|postgres\|/,
    'test db does not appear in cluster new2';
unlike_program_out 'postgres', "psql -Atl", 0, qr/test\|postgres\|/,
    'test db does not appear in default cluster';

# check that environment variables work
$ENV{'PGCLUSTER'} = $new1;
like_program_out 'postgres', "psql -Atl", 0, qr/test\|postgres\|/, 
    'PGCLUSTER selection (1)';
$ENV{'PGCLUSTER'} = $new2;
unlike_program_out 'postgres', "psql -Atl", 0, qr/test\|postgres\|/, 
    'PGCLUSTER selection (2)';
$ENV{'PGCLUSTER'} = 'foo';
like_program_out 'postgres', "psql -l", 1, 
    qr/Invalid version specified with \$PGCLUSTER/, 
    'invalid PGCLUSTER value';
delete $ENV{'PGCLUSTER'};

# check that PGPORT works
$ENV{'PGPORT'} = '5434';
is_program_out 'postgres', 'psql -Atc "show port" template1', 0, "5434\n", 
    'PGPORT selection (1)';
$ENV{'PGPORT'} = '5432';
is_program_out 'postgres', 'psql -Atc "show port" template1', 0, "5432\n", 
    'PGPORT selection (2)';
$ENV{'PGCLUSTER'} = $new2;
delete $ENV{'PGPORT'};
$ENV{'PGPORT'} = '5432';
like_program_out 'postgres', 'psql --version', 0, qr/^psql \(PostgreSQL\) $MAJORS[-1]\.\d+\b/, 
    'PGPORT+PGCLUSTER, PGCLUSTER selects version';
is_program_out 'postgres', 'psql -Atc "show port" template1', 0, "5432\n", 
    'PGPORT+PGCLUSTER, PGPORT selects port';
delete $ENV{'PGPORT'};
delete $ENV{'PGCLUSTER'};

# check cluster selection with an empty user_clusters
open F, '>/etc/postgresql-common/user_clusters' or die "Could not create user_clusters: $!";
close F;
chmod 0644, '/etc/postgresql-common/user_clusters';
like_program_out 0, 'psql --version', 0, qr/^psql \(PostgreSQL\) $MAJORS[0]\.\d+\b/, 
    'pg_wrapper selects port 5432 as default cluster with empty user_clusters';
like_program_out 0, "psql --cluster $new1 --version", 0, 
    qr/^psql \(PostgreSQL\) $MAJORS[-1]\.\d+\b/, 
    'pg_wrapper --cluster works with empty user_clusters';

# check default cluster selection with user_clusters
open F, '>/etc/postgresql-common/user_clusters' or die "Could not create user_clusters: $!";
print F "* * 8.1 new1 *\n";
close F;
chmod 0644, '/etc/postgresql-common/user_clusters';
like_program_out 'postgres', 'psql --version', 0, qr/^psql \(PostgreSQL\) $MAJORS[-1]\.\d+\b/, 
    "pg_wrapper selects correct cluster with user_clusters '* * $MAJORS[-1] new1 *'";

# check by-user cluster selection with user_clusters
# (also check invalid cluster reporting)
open F, '>/etc/postgresql-common/user_clusters' or die "Could not create user_clusters: $!";
print F "postgres * $MAJORS[-1] new1 *\nnobody * $MAJORS[0] old *\n* * 5.5 * *";
close F;
chmod 0644, '/etc/postgresql-common/user_clusters';
like_program_out 'postgres', 'psql --version', 0, qr/^psql \(PostgreSQL\) $MAJORS[-1]\.\d+\b/, 
    'pg_wrapper selects correct cluster with per-user user_clusters';
like_program_out 'nobody', 'psql --version', 0, qr/^psql \(PostgreSQL\) $MAJORS[0]\.\d+\b/, 
    'pg_wrapper selects correct cluster with per-user user_clusters';
like_program_out 0, 'psql --version', 1, qr/user_clusters.*line 3.*cluster.*not exist/i, 
    'pg_wrapper selects correct cluster with per-user user_clusters';

# check invalid user_clusters
open F, '>/etc/postgresql-common/user_clusters' or die "Could not create user_clusters: $!";
print F 'foo';
close F;
chmod 0644, '/etc/postgresql-common/user_clusters';
like_program_out 'postgres', 'psql --version', 0, qr/ignoring invalid line 1/, 
    'pg_wrapper ignores invalid lines in user_clusters';

# remove test user_clusters
unlink '/etc/postgresql-common/user_clusters' or die
    "unlink user_clusters: $!";

# restore original user_clusters
if (-f '/etc/postgresql-common/user_clusters.psqltestsuite') {
    ok ((rename '/etc/postgresql-common/user_clusters.psqltestsuite',
    '/etc/postgresql-common/user_clusters'),
    'Restoring original /etc/postgresql-common/user_clusters');
} else {
    pass '/etc/postgresql-common/user_clusters did not exist, not restoring';
}

# clean up
is ((system "pg_dropcluster $MAJORS[-1] new1 --stop"), 0, "dropping $new1");
is ((system "pg_dropcluster $MAJORS[-1] new2 --stop"), 0, "dropping $new2");
is ((system "pg_dropcluster $MAJORS[0] old --stop"), 0, "dropping $old");

check_clean;

# vim: filetype=perl
