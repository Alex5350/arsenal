.PHONY: verify validate links bootstrap work-item

# Same checks CI runs, locally.
verify: validate links

validate:
	./scripts/validate-skills.sh

links:
	./scripts/check-links.sh

bootstrap:
	./scripts/bootstrap.sh

# Example: make work-item ARGS='create "Investigate flaky export test"'
work-item:
	./scripts/work-item.sh $(ARGS)
