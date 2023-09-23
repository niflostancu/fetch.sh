# Simple make script used for deployment / testing

DEBUG?=
VERBOSE?=
V?=$(VERBOSE)
DOCKER?=docker

TEST_BATS_IMAGE?=niflostancu/fetch-test:latest
DELAY?=1
TEST_BATS_ARGS?= --jobs 1 --print-output-on-failure --formatter pretty
TEST_BATS_ARGS+=$(if $(V),--show-output-of-passing-tests --verbose-run)

help:
	@echo "Available targets:"
	@echo "	 test 	Runs all tests using bats."

.PHONY: test
test:
	docker build -q -t "$(TEST_BATS_IMAGE)" test/
	$(DOCKER) run -it -v "$$(pwd):/code:ro" -e "DEBUG=$(DEBUG)" -e BATS_DELAY=$(DELAY) \
		"$(TEST_BATS_IMAGE)" $(TEST_BATS_ARGS) /code/test/

