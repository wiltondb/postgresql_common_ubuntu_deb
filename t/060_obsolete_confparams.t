# Test upgrading from the oldest version to all majors with all possible
# configuration parameters set. This checks that they are correctly
# transitioned.

use strict; 

use lib 't';
use TestLib;

use Test::More tests => ($#MAJORS == 0) ? 1 : (12 + $#MAJORS * 9);

if ($#MAJORS == 0) {
    pass 'only one major version installed, skipping upgrade tests';
    exit 0;
}

# postgresql.conf configuration file with all available options turned on
my %fullconf;
$fullconf{'7.4'} = "tcpip_socket = true
max_connections = 100
superuser_reserved_connections = 2
port = 5432
unix_socket_directory = '/var/run/postgresql'
unix_socket_group = ''
unix_socket_permissions = 0777
virtual_host = ''
rendezvous_name = ''
authentication_timeout = 60
ssl = false
password_encryption = true
krb_server_keyfile = ''
db_user_namespace = false
shared_buffers = 1000
sort_mem = 1024
vacuum_mem = 8192
max_fsm_pages = 20000
max_fsm_relations = 1000
max_files_per_process = 1000
preload_libraries = ''
fsync = true
wal_sync_method = fsync
wal_buffers = 8
checkpoint_segments = 3
checkpoint_timeout = 300
checkpoint_warning = 30
commit_delay = 0
commit_siblings = 5
enable_hashagg = true
enable_hashjoin = true
enable_indexscan = true
enable_mergejoin = true
enable_nestloop = true
enable_seqscan = true
enable_sort = true
enable_tidscan = true
effective_cache_size = 1000
random_page_cost = 4
cpu_tuple_cost = 0.01
cpu_index_tuple_cost = 0.001
cpu_operator_cost = 0.0025
geqo = true
geqo_threshold = 11
geqo_effort = 1
geqo_generations = 0
geqo_pool_size = 0
geqo_selection_bias = 2.0
default_statistics_target = 10
from_collapse_limit = 8
join_collapse_limit = 8
syslog = 0
syslog_facility = 'LOCAL0'
syslog_ident = 'postgres'
client_min_messages = notice
log_min_messages = notice
log_error_verbosity = default
log_min_error_statement = panic
log_min_duration_statement = -1
silent_mode = false
debug_print_parse = false
debug_print_rewritten = false
debug_print_plan = false
debug_pretty_print = false
log_connections = true
log_duration = false
log_pid = true
log_statement = true
log_timestamp = true
log_hostname = true
log_source_port = true
log_parser_stats = false
log_planner_stats = false
log_executor_stats = false
stats_start_collector = true
stats_command_string = false
stats_block_level = false
stats_row_level = true
stats_reset_on_server_start = true
search_path = '\$user,public'
default_transaction_isolation = 'read committed'
default_transaction_read_only = false
statement_timeout = 0
datestyle = 'ISO,European'
australian_timezones = false
extra_float_digits = 0
dynamic_library_path = '/usr/share/postgresql:/usr/lib/postgresql'
max_expr_depth = 10000
deadlock_timeout = 1000
max_locks_per_transaction = 64
add_missing_from = true
regex_flavor = advanced
sql_inheritance = true
transform_null_equals = false
";

$fullconf{'8.0'} = "port = 5432
max_connections = 100
superuser_reserved_connections = 2
unix_socket_directory = '/var/run/postgresql'
unix_socket_group = ''
unix_socket_permissions = 0777	
rendezvous_name = ''		
authentication_timeout = 60	
ssl = false
password_encryption = true
krb_server_keyfile = ''
db_user_namespace = false
shared_buffers = 1000		
work_mem = 1024		
maintenance_work_mem = 16384	
max_stack_depth = 2048		
max_fsm_pages = 20000		
max_fsm_relations = 1000	
max_files_per_process = 1000	
preload_libraries = ''
vacuum_cost_delay = 0		
vacuum_cost_page_hit = 1	
vacuum_cost_page_miss = 10	
vacuum_cost_page_dirty = 20	
vacuum_cost_limit = 200	
bgwriter_delay = 200		
bgwriter_percent = 1		
bgwriter_maxpages = 100	
fsync = true			
wal_sync_method = fsync	
wal_buffers = 8		
commit_delay = 0		
commit_siblings = 5		
checkpoint_segments = 3	
checkpoint_timeout = 300	
checkpoint_warning = 30	
archive_command = ''		
enable_hashagg = true
enable_hashjoin = true
enable_indexscan = true
enable_mergejoin = true
enable_nestloop = true
enable_seqscan = true
enable_sort = true
enable_tidscan = true
effective_cache_size = 1000	
random_page_cost = 4		
cpu_tuple_cost = 0.01		
cpu_index_tuple_cost = 0.001	
cpu_operator_cost = 0.0025	
geqo = true
geqo_threshold = 12
geqo_effort = 5		
geqo_pool_size = 0		
geqo_generations = 0		
geqo_selection_bias = 2.0	
from_collapse_limit = 8
join_collapse_limit = 8	
log_destination = 'stderr'	
redirect_stderr = false    
log_directory = '.'   
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log' 
log_truncate_on_rotation = false  
log_rotation_age = 1440    
log_rotation_size = 10240  
syslog_facility = 'LOCAL0'
syslog_ident = 'postgres'
client_min_messages = notice	
log_min_messages = notice	
log_error_verbosity = default	
log_min_error_statement = panic 
log_min_duration_statement = -1 
silent_mode = false		 
debug_print_parse = false
debug_print_rewritten = false
debug_print_plan = false
debug_pretty_print = false
log_connections = false
log_disconnections = false
log_duration = false
log_line_prefix = ''		
log_statement = 'none'		
log_hostname = false
log_parser_stats = false
log_planner_stats = false
log_executor_stats = false
log_statement_stats = false
stats_start_collector = true
stats_command_string = false
stats_block_level = false
stats_row_level = true
stats_reset_on_server_start = true
search_path = '\$user,public'	
default_tablespace = ''	
check_function_bodies = true
default_transaction_isolation = 'read committed'
default_transaction_read_only = false
statement_timeout = 0		
datestyle = 'iso, mdy'
timezone = unknown		
australian_timezones = false
extra_float_digits = 0		
client_encoding = sql_ascii	
lc_messages = 'ru_RU.UTF-8'		
lc_monetary = 'ru_RU.UTF-8'		
lc_numeric = 'ru_RU.UTF-8'		
lc_time = 'ru_RU.UTF-8'			
explain_pretty_print = true
dynamic_library_path = '\$libdir'
deadlock_timeout = 1000	
max_locks_per_transaction = 64	
add_missing_from = true
regex_flavor = advanced	
sql_inheritance = true
default_with_oids = true
transform_null_equals = false
";

$fullconf{'8.1'} = "port = 5432
max_connections = 100
superuser_reserved_connections = 2
unix_socket_directory = ''
unix_socket_group = ''
unix_socket_permissions = 0777
bonjour_name = ''
authentication_timeout = 60
ssl = off
password_encryption = on
db_user_namespace = off
krb_server_keyfile = ''
krb_srvname = 'postgres'
krb_server_hostname = ''
krb_caseins_users = off
tcp_keepalives_idle = 0
tcp_keepalives_interval = 0
tcp_keepalives_count = 0
shared_buffers = 1000
temp_buffers = 1000
max_prepared_transactions = 5
work_mem = 1024
maintenance_work_mem = 16384
max_stack_depth = 2048
max_fsm_pages = 20000
max_fsm_relations = 1000
max_files_per_process = 1000
preload_libraries = ''
vacuum_cost_delay = 0
vacuum_cost_page_hit = 1
vacuum_cost_page_miss = 10
vacuum_cost_page_dirty = 20
vacuum_cost_limit = 200
bgwriter_delay = 200
bgwriter_lru_percent = 1.0
bgwriter_lru_maxpages = 5
bgwriter_all_percent = 0.333
bgwriter_all_maxpages = 5
fsync = on
wal_sync_method = fsync
full_page_writes = on
wal_buffers = 8
commit_delay = 0
commit_siblings = 5
checkpoint_segments = 3
checkpoint_timeout = 300
checkpoint_warning = 30
archive_command = ''
enable_bitmapscan = on
enable_hashagg = on
enable_hashjoin = on
enable_indexscan = on
enable_mergejoin = on
enable_nestloop = on
enable_seqscan = on
enable_sort = on
enable_tidscan = on
effective_cache_size = 1000
random_page_cost = 4
cpu_tuple_cost = 0.01
cpu_index_tuple_cost = 0.001
cpu_operator_cost = 0.0025
geqo = on
geqo_threshold = 12
geqo_effort = 5
geqo_pool_size = 0
geqo_generations = 0
geqo_selection_bias = 2.0
default_statistics_target = 10
constraint_exclusion = off
from_collapse_limit = 8
join_collapse_limit = 8
log_destination = 'stderr'
redirect_stderr = off
log_directory = '.'
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
log_truncate_on_rotation = off
log_rotation_age = 1440
log_rotation_size = 10240
syslog_facility = 'LOCAL0'
syslog_ident = 'postgres'
client_min_messages = notice
log_min_messages = notice
log_error_verbosity = default
log_min_error_statement = panic
log_min_duration_statement = -1
silent_mode = off
debug_print_parse = off
debug_print_rewritten = off
debug_print_plan = off
debug_pretty_print = off
log_connections = off
log_disconnections = off
log_duration = off
log_line_prefix = ''
log_statement = 'none'
log_hostname = off
log_parser_stats = off
log_planner_stats = off
log_executor_stats = off
log_statement_stats = off
stats_start_collector = on
stats_command_string = off
stats_block_level = off
stats_row_level = off
stats_reset_on_server_start = off
autovacuum = off
autovacuum_naptime = 60
autovacuum_vacuum_threshold = 1000
autovacuum_analyze_threshold = 500
autovacuum_vacuum_scale_factor = 0.4
autovacuum_analyze_scale_factor = 0.2
autovacuum_vacuum_cost_delay = -1
autovacuum_vacuum_cost_limit = -1
search_path = '\$user,public'
default_tablespace = ''
check_function_bodies = on
default_transaction_isolation = 'read committed'
default_transaction_read_only = off
statement_timeout = 0
datestyle = 'iso, mdy'
timezone = unknown
australian_timezones = on
extra_float_digits = 0
client_encoding = sql_ascii
lc_messages = 'C'
lc_monetary = 'C'
lc_numeric = 'C'
lc_time = 'C'
explain_pretty_print = on
dynamic_library_path = '\$libdir'
deadlock_timeout = 1000
max_locks_per_transaction = 64
add_missing_from = off
backslash_quote = safe_encoding
default_with_oids = off
escape_string_warning = off
regex_flavor = advanced
sql_inheritance = on
transform_null_equals = off
custom_variable_classes = 'foo'
";

# create cluster for oldest version
is ((system "pg_createcluster $MAJORS[0] main >/dev/null"), 0, "pg_createcluster $MAJORS[0] main");

# Loop over all but the latest major version
my @testversions = sort @MAJORS;
while ($#testversions) {
    my $cur = shift @testversions;
    my $new = $testversions[0];

    # Write configuration file and start
    open F, ">/etc/postgresql/$cur/main/postgresql.conf" or 
        die "could not open /etc/postgresql/$cur/main/postgresql.conf";
    die "\$fullconf{$cur} is not defined" unless exists $fullconf{$cur};
    print F $fullconf{$cur};
    is ((exec_as 'postgres', "pg_ctlcluster $cur main start 2>/dev/null"), 0,
        'pg_ctlcluster start');
    like_program_out 'postgres', 'pg_lsclusters -h', 0, qr/$cur.*online/, 
        "Old $cur cluster is online";
        
    # Upgrade cluster
    like_program_out 0, "pg_upgradecluster -v $new $cur main", 0, qr/^Success/im;
    like_program_out 'postgres', 'pg_lsclusters -h', 0, qr/$new.*online/,
        "New $new cluster is online";

    is ((system "pg_dropcluster $cur main"), 0, "pg_dropcluster $cur main");

    is ((exec_as 'postgres', "pg_ctlcluster $new main stop 2>/dev/null"), 0,
        "Stopping new $new pg_ctlcluster");
}

# remove latest cluster and directory
is ((system "pg_dropcluster $testversions[0] main"), 0, 'Dropping remaining cluster');

check_clean;

# vim: filetype=perl
