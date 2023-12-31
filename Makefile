POD2MAN=pod2man --center "Debian PostgreSQL infrastructure" -r "Debian"
POD1PROGS = pg_backupcluster.1 \
	    pg_conftool.1 \
	    pg_createcluster.1 \
	    pg_ctlcluster.1 \
	    pg_dropcluster.1 \
	    pg_getwal.1 \
	    pg_lsclusters.1 \
	    pg_renamecluster.1 \
	    pg_restorecluster.1 \
	    pg_upgradecluster.1 \
	    pg_wrapper.1
POD1PROGS_POD = pg_buildext.1 \
		pg_virtualenv.1 \
		debhelper/dh_pgxs_test.1 \
		dh_make_pgxs/dh_make_pgxs.1
POD8PROGS = pg_updatedicts.8

all: man sub-pgdg

man: $(POD1PROGS) $(POD1PROGS_POD) $(POD8PROGS)

%.1: %.pod
	$(POD2MAN) --quotes=none --section 1 $< $@

%.1: %
	$(POD2MAN) --quotes=none --section 1 $< $@

%.8: %
	$(POD2MAN) --quotes=none --section 8 $< $@

clean:
	rm -f *.1 *.8 debhelper/*.1 dh_make_pgxs/*.1

sub-pgdg:
	$(MAKE) -C pgdg
