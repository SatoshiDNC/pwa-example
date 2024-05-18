# Theory of Operation
#
# * When no target is specified, recursively make all subdirectories.
# * When "clean" target is specified, recursively clean all subdirectories.
# * When "rel" target is specified, recursively make all subdirectories and
#   the release version (with compressed JavaScript).
# * This makefile just copies the appropriate result from the src directory
#   to the final output filename index.html in this directory.
# * All subdirectory Makefiles should follow the same recursion pattern for
#   when no target is specified and for the "clean" target, and they should
#   combine their subtree into their own all.js file.

CLOSURE = java -jar lib/closure-compiler.jar

all: subdirs debug # Textbook subdirectory recursion

# "rel" target should build the release version in addition to everything else.
.PHONY: rel relbuild
rel: $(CLOSURE) relbuild release
$(CLOSURE):
	wget -O $(CLOSURE) https://repo1.maven.org/maven2/com/google/javascript/closure-compiler/v20230802/closure-compiler-v20230802.jar
relbuild: subdirs
	@$(MAKE) -C src rel

# Build the intended version.
debug:
release:
# debug: src/program-debug.html src/pwa/worker.js src/pwa/manifest.json
# 	cp src/program-debug.html index.html
# 	cp src/worker.js worker.js
# release: src/program-release.html src/pwa/worker.js src/pwa/manifest.json
# 	cp src/program-release.html index.html
# 	$(CLOSURE) \
# 		--js src/worker.js \
# 		--js_output_file worker.js

# Recursive cleanup.
.PHONY: clean
clean:
	@$(MAKE) -sC fwiw clean
	@$(MAKE) -sC lib clean
	@$(MAKE) -sC src clean
	@-rm -f index.html worker.js

# Textbook subdirectory recursion
SUBDIRS = fwiw lib src
.PHONY: subdirs $(SUBDIRS)
subdirs: $(SUBDIRS)
$(SUBDIRS):
	@$(MAKE) -C $@

