### -*-Makefile-*- to prepare "A Foray Into the Insurance of Things,
### Or Pricing Individual Objects Without Prior Data"
##
## Copyright (C) 2017 Vincent Goulet
##
## 'make doc' compiles the slides;
## 'make release' creates a release on GitHub and uploads the slides
##
## Author: Vincent Goulet
##
## This file is part of project "A Foray Into the Insurance of Things,
## Or Pricing Individual Objects Without Prior Data - 21st
## International Congress on Insurance: Mathematics and Economics (IME
## 2017)"
## http://github.com/vigou3/ime-2017-insurance-of-things

## Key files
MASTER = ime-2017-insurance-of-things.pdf
README = README.md

## Version number
VERSION = $(shell cat VERSION)

# Toolset
TEXI2DVI = LATEX=xelatex texi2dvi -b
RM = rm -r

## GitHub repository and authentication
REPOSURL = https://api.github.com/repos/vigou3/ime-2017-insurance-of-things
OAUTHTOKEN = $(shell cat ~/.github/token)


doc: ${MASTER}

${MASTER}: *.tex
	${TEXI2DVI} ${MASTER:.pdf=.tex}

release: create-release upload

create-release:
	@echo ----- Creating release on GitHub...
	@if [ -n "$(shell git status --porcelain | grep -v '^??')" ]; then \
	    echo "uncommitted changes in repository; not creating release"; exit 2; fi
	@if [ -n "$(shell git log origin/master..HEAD)" ]; then \
	    echo "unpushed commits in repository; pushing to origin"; \
	     fi
	if [ -e relnotes.in ]; then rm relnotes.in; fi
	touch relnotes.in
	awk 'BEGIN { ORS=" "; print "{\"tag_name\": \"v${VERSION}\"," } \
	      /^$$/ { next } \
	      /^## Changelog/ { state=0; next } \
              (state==0) && /^### / { state = 1; out = $$2; \
	                             for(i=3; i<=NF; i++) { out = out" "$$i }; \
	                             printf "\"name\": \"Version %s\", \"body\": \"", out; \
	                             next } \
	      (state==1) && /^### / { exit } \
	      state==1 { printf "%s\\n", $$0 } \
	      END { print "\", \"draft\": false, \"prerelease\": false}" }' \
	      ${README} >> relnotes.in
	curl --data @relnotes.in ${REPOSURL}/releases?access_token=${OAUTHTOKEN}
	rm relnotes.in
	@echo ----- Done creating the release

upload:
	@echo ----- Getting upload URL from GitHub...
	$(eval upload_url=$(shell curl -s ${REPOSURL}/releases/latest \
	 			  | awk -F '[ {]' '/^  \"upload_url\"/ \
	                                    { print substr($$4, 2, length) }'))
	@echo ${upload_url}
	@echo ----- Uploading PDF and archive to GitHub...
	curl -H 'Content-Type: application/zip' \
	     -H 'Authorization: token ${OAUTHTOKEN}' \
	     --upload-file ${MASTER} \
             -i "${upload_url}?&name=${MASTER}" -s
	@echo ----- Done uploading files
