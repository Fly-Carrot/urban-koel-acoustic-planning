R := Rscript --vanilla
PROFILE ?= verify

.PHONY: setup smoke verify full reproduce test contract clean

setup:
	$(R) tools/setup.R

smoke:
	$(R) tools/run_pipeline.R --profile=smoke

verify:
	$(R) tools/run_pipeline.R --profile=verify

full:
	$(R) tools/run_pipeline.R --profile=full

reproduce:
	$(R) analysis/reproduce_retained.R

test:
	$(R) tests/run_tests.R

contract:
	$(R) tools/validate_contract.R

clean:
	rm -rf outputs/*
	touch outputs/.gitkeep

