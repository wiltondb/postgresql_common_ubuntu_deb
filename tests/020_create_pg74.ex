Creating new cluster (configuration: /etc/postgresql/7.4/pg74, data: /var/lib/postgresql/7.4/pg74)...
Moving configuration file /var/lib/postgresql/7.4/pg74/pg_hba.conf to /etc/postgresql/7.4/pg74...
Moving configuration file /var/lib/postgresql/7.4/pg74/pg_ident.conf to /etc/postgresql/7.4/pg74...
Moving configuration file /var/lib/postgresql/7.4/pg74/postgresql.conf to /etc/postgresql/7.4/pg74...
Configuring postgresql.conf to use port 5432...
Error: The cluster is owned by user id 99 which does not exist any more
Error: The cluster is owned by user id 99 which does not exist any more
Version Cluster   Port Status Owner    Data directory                     Log file                       
7.4     pg74      5432 online postgres /var/lib/postgresql/7.4/pg74       /var/log/postgresql/postgresql-7.4-pg74.log 
Default socket directory /var/run/postgresql:
.
..
This cluster's socket directory /tmp/postgresql-testsuite/:
.
..
.s.PGSQL.5432
.s.PGSQL.5432.lock
psql (PostgreSQL) 7.4.8
contains support for command-line editing
        List of databases
   Name    |  Owner   | Encoding  
-----------+----------+-----------
 template0 | postgres | SQL_ASCII
 template1 | postgres | SQL_ASCII
(2 rows)

