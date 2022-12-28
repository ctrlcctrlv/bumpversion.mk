#!/usr/bin/env gmake
###############################################################################
#🮞🮟🮞🮟🮞🮟🮞🮟🮞🮟🮞🮟`bumpversion.mk`: bumpversion recipe for GNUmakefiles🮞🮟🮞🮟🮞🮟🮞🮟🮞🮟🮞🮟#
###############################################################################
# Copyright 2020–2023 ——————— ((((((((((((((Fredrick R. Brennan)))))))))))))) #
###############################################################################
# Licensed under the Apache License, Version 2.0 (the "License"); you may not #
# use  this  software  or  any of the provided source code  files  except  in #
# compliance with the License. You may obtain a copy of the License at:➦ ➦ ➦ ⮯#
###############################################################################
#🮞🮟 🮞🮟 🮞🮟 🮞🮟 🮞🮟 🮞🮟 🮞🮟 🮞🮟 🮞🮟 🮞🮟 ➦ <https://www.apache.org/licenses/LICENSE-2.0>#
###############################################################################
# Unless  required  by  applicable  law or agreed  to  in  writing,  software #
# distributed  under the License is distributed on an "as is" basis,  without #
# warranties  or  conditions of any kind, either express or implied. See  the #
# License  for  the specific language governing permissions  and  limitations #
# under the License. 〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜〜 #
###############################################################################

PERCENT=$$'\045'
SHELL:=/bin/bash
.ONESHELL: .env .version
.PHONY: bumppatchversion bumpmidversion bumpmajorversion catversion git_bump%version getrelno
.EXPORT_ALL_VARIABLES: .version

GIT:=git
ifneq (,$(GNUPGHOME))
GITTAGFLAGS:=-S
GITCOMMITFLAGS:=$(GITTAGFLAGS)
endif

.SILENT: git_bumpmajorversion git_bumpmidversion git_bumppatchversion

# $(PERCENT) not needed here as these are not recipes.
VERSION:=$(shell printf %q "$$( $$([ -f .version ] || printf 0.0.0 > .version); cat .version)")
NORELNO:=$(shell printf %q "$$(awk 'BEGIN {FS="-"} {print $$1}' < .version)")
RELNO  :=$(shell printf %q "$$(awk 'BEGIN {FS="-"} {print $$2}' < .version)")

.version:
	VERSION=$$(sed -e 's/-.*$$//' <<< "$$VERSION")
	FIRST=$$(awk 'BEGIN {FS="."} {print $$1}' <<< "$$VERSION")
	  MID=$$(awk 'BEGIN {FS="."} {print $$2}' <<< "$$VERSION")
	 LAST=$$(awk 'BEGIN {FS="."} {print $$3}' <<< "$$VERSION")
	for v in FIRSTN MIDN LASTN; do \
		var=$$(head -c -2 <<< $$v)
		if [[ $${!v} == -1 ]]; then \
			eval "$${var}=0"; \
			eval "$${var}N=0"; \
		fi \
	done
	RELNO_ADD=$$([ ! -z $(RELNO) ] && printf -- -$(PERCENT)s $(RELNO) || printf '')
	VERSION="$$((FIRST+FIRSTN)).$$((MID+MIDN)).$$((LAST+LASTN))$$RELNO_ADD"
	printf $(PERCENT)s "$$VERSION" > $@

.env: .version catversion
	printf VERSION=$(PERCENT)s $(shell cat $<) > $@

.ONESHELL: 
CALLED=$(shell sed -e 's/git_//' <<< "$@")
CALLEDT=$(shell sed -e 's/git_bump\([a-z]\+\)version/\1/' <<< "$@")
git_bump%version:
	$(MAKE) $(MFLAGS) $(CALLED)
	GITCOMMANDS='
	        $(GIT) tag $(GITTAGFLAGS) v$(VERSION) -m "Version $(VERSION)"
	        $(GIT) commit $(GITCOMMITFLAGS) -m "Bumped $(CALLEDT) version to $(VERSION)" --no-edit
	'	
ifeq (,$(GITAUTOEXEC))
	echo "Now run:$$GITCOMMANDS"
else ifeq (,$(GITAUTOEXEC))
	eval $$GITCOMMANDS
endif

bumppatchversion:
	export FIRSTN=0 MIDN=0 LASTN=1
	$(MAKE) $(MFLAGS) .env

bumpmidversion:
	export FIRSTN=0 MIDN=1 LASTN=-1
	$(MAKE) $(MFLAGS) .env

bumpmajorversion:
	export FIRSTN=1 MIDN=-1 LASTN=-1
	$(MAKE) $(MFLAGS) .env

bumprelnoversion:
	export FIRSTN=0 MIDN=0 LASTN=0
	$(MAKE) $(MFLAGS) .env

DIALOG=dialog --backtitle "Bumping version…"
DIALOGRUNBOX=$(DIALOG) --programbox "Running…" 20 71

.ONESHELL:
bumpversion:
	TEMPUI=$$(mktemp -p '' dialog.ui.XXXXX)
	$(DIALOG) \
		--title "Which type of bump shall I do" \
		--checklist $$'Choose one of the following options, assuming a version like 1.2.3:' \
		20 71 4 \
		patch 1.2.x PATCH mid 1.x.3 MID major x.2.3 MAJOR 2>$$TEMPUI && \
	if wc -c $$TEMPUI; then \
		((for choice in `cat $$TEMPUI`; do $(MAKE) -B $(MFLAGS) `awk '{print "bump"$$1"version"}' <<< $${choice}`; done) | \
			$(DIALOGRUNBOX)) \
	fi
	$(MAKE) $(MFLAGS) bumprelno
	rm $$TEMPUI
	[ -z "$(DEBUG)" ] && clear || true

.EXPORT_ALL_VARIABLES:
.ONESHELL:
bumprelno:
	TEMPUI=$$(mktemp -p '' dialog.ui.XXXXX)
	$(DIALOG) \
		--title "Should I add a relno?" \
		--inputbox $$'Should I add a relno (hyphenated) field?\nLeave blank to say «no».\n'"\
			"$(NORELNO)"-$$([ -z $(RELNO) ] && echo x):" 20 71 $(RELNO) \
		2> $$TEMPUI && \
	RELNO=$$(cat $$TEMPUI)
	RELNO=$$RELNO $(MAKE) $(MFLAGS) RELNO=$$RELNO -B .version | $(DIALOGRUNBOX) 
	rm $$TEMPUI
	[ -z "$(DEBUG)" ] && clear || true

catversion:
	echo $(VERSION)

%.EXPORT_ALL_VARIABLES: .env bumppatchversion bumpmidversion bumpmajorversion
