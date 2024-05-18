all: subdirs bundle.js # Textbook subdirectory recursion

bundle.js: APP_LICENSE.js timecalc.json
	sed -e '/^ [*]\/$$/e cat timecalc.json' APP_LICENSE.js > bundle.js

timecalc.json: timecalc.sh
	./timecalc.sh

# Clean files from subdirs and this dir
.PHONY: clean
clean:
#	@$(MAKE) -sC dirname clean # ADD DIRS AS NEEDED
	@-rm -f bundle.js timecalc.json

# Textbook subdirectory recursion
SUBDIRS = $(wildcard */)
.PHONY: subdirs $(SUBDIRS)
subdirs: $(SUBDIRS)
$(SUBDIRS):
	@$(MAKE) -C $@

