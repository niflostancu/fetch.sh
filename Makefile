# Simple make script used for deployment / testing

DEBUG=
DOCKER=docker
TEST_BATS_IMAGE=niflostancu/fetch-test:latest

help:
	@echo "Available targets:"
	@echo "	 test 	Runs all tests using bats."

.PHONY: test
test:
	docker build -q -t "$(TEST_BATS_IMAGE)" test/
	$(DOCKER) run -t -v "$$(pwd):/code:ro" -e "DEBUG=$(DEBUG)" \
		"$(TEST_BATS_IMAGE)" --print-output-on-failure /code/test/

