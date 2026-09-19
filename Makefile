.PHONY: verify test-unit test-integration validate links generated manifests script-tests sync bootstrap work-item

# Same checks CI runs, locally. The two test targets are the contract every
# consumer repository implements (docs/standards/testing.md); here they run
# the hub's own checks.
verify: test-unit test-integration

test-unit: validate generated manifests script-tests

test-integration: links

validate:
	./scripts/validate-skills.sh
	./scripts/validate-agents.sh

links:
	./scripts/check-links.sh

generated:
	./scripts/sync.sh --check

manifests:
	./scripts/validate-manifests.sh

script-tests:
	./tests/work-item.test.sh

sync:
	./scripts/sync.sh

bootstrap:
	./scripts/bootstrap.sh

# Example: make work-item ARGS='create "Investigate flaky export test"'
work-item:
	./scripts/work-item.sh $(ARGS)
