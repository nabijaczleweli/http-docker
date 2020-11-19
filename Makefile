# The MIT License (MIT)

# Copyright (c) 2020 наб <nabijaczleweli.xyz>

# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


SRCDIR ?= ../http/
TGTDIR ?= $(SRCDIR)target
OUTDIR ?= out/

PREFIX ?=

DOCKER ?= docker
CARGO ?= cargo

VERSION := $(shell awk '/^version/ {gsub("\"", ""); print $$3; exit}' $(SRCDIR)Cargo.toml)


all: prep
	{                                                                    \
	  echo 'FROM scratch';                                               \
	  echo 'LABEL maintainer="наб <nabijaczleweli@nabijaczleweli.xyz>"'; \
	  echo 'ENTRYPOINT ["/http"]'; \
	  echo 'ADD $(OUTDIR) /';                                            \
	} | $(DOCKER) build -t $(PREFIX)http:$(VERSION) -f - .

prep: clean $(TGTDIR)release/http
	@mkdir -p $(OUTDIR)
	ln $(SRCDIR)target/release/http $(OUTDIR)http 2>/dev/null || cp $(SRCDIR)target/release/http $(OUTDIR)http
	ldd $(OUTDIR)http |                                                                                                                                 \
	  awk '/=>/ {print $$3}  /^[[:space:]]*\// {print $$1}' |                                                                                           \
	  awk -F/ 'BEGIN {OFS=FS} {print "ln " $$0 " $(OUTDIR)" $$0 " 2>/dev/null || cp " $$0 " $(OUTDIR)" $$0; $$NF=""; print "mkdir -p $(OUTDIR)" $$0}' | \
	  sort -r |                                                                                                                                         \
	  uniq |                                                                                                                                            \
	  sh -x

clean:
	rm -rf $(OUTDIR)


$(TGTDIR)release/http : $(SRCDIR)Cargo.toml $(SRCDIR)build.rs $(wildcard $(SRCDIR)src/*.rs $(SRCDIR)src/**/*.rs $(SRCDIR)src/**/**/*.rs)
	cd $(SRCDIR) && $(CARGO) build --release
