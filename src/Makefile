all: subdirs bundle.js # Textbook subdirectory recursion

FILES = \
	init.js \

bundle.js: $(FILES)
	cat $(FILES) > bundle.js

# Clean files from subdirs and this dir
.PHONY: clean
clean:
#	@$(MAKE) -sC dirname clean # ADD DIRS AS NEEDED
	@-rm -f bundle.js

# Textbook subdirectory recursion
SUBDIRS = $(wildcard */)
.PHONY: subdirs $(SUBDIRS)
subdirs: $(SUBDIRS)
$(SUBDIRS):
	@$(MAKE) -C $@

