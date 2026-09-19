.PHONY: verify validate links generated manifests sync bootstrap work-item

# Same checks CI runs, locally.
verify: validate links generated manifests

validate:
	./scripts/validate-skills.sh
	./scripts/validate-agents.sh

links:
	./scripts/check-links.sh

generated:
	./scripts/sync.sh --check

manifests:
	./scripts/validate-manifests.sh

sync:
	./scripts/sync.sh

bootstrap:
	./scripts/bootstrap.sh

# Example: make work-item ARGS='create "Investigate flaky export test"'
work-item:
	./scripts/work-item.sh $(ARGS)
