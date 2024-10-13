.PHONY: all test clean

export DOCKER_CLI_HINTS=false

COMPOSE_RUN = docker compose run --rm --quiet-pull

tests = $(shell grep -E '^test-.*:' Makefile | sed 's/:$$//')
cleans = $(shell grep -E '^clean-.*:' Makefile | sed 's/:$$//')

run: clean-build
	docker compose up --quiet-pull render

build: clean-build test
	$(COMPOSE_RUN) builder hugo --minify

test: $(tests)

test-dependabot:
	$(COMPOSE_RUN) tester check-jsonschema --schemafile /schemas/dependabot-2.0.json .github/dependabot.yml

test-docker:
	$(COMPOSE_RUN) dockerlint --ignore DL3018 Dockerfile.hugo
	$(COMPOSE_RUN) dockerlint --ignore DL3018 Dockerfile.tester
	docker compose config -q

test-editorcheck:
	$(COMPOSE_RUN) tester ec

test-github:
	$(COMPOSE_RUN) tester make _test-github
_test-github:
	@find .github/workflows -type f \( -iname \*.yaml -o -iname \*.yml \) -print0 | xargs -0 -I {} echo 'echo Checking: {}; check-jsonschema --builtin-schema github-workflows {}' | sort | sh -e

test-makefile:
	$(COMPOSE_RUN) makelint

clean: $(cleans)

clean-build:
	-$(COMPOSE_RUN) builder rm -rf public

clean-docker:
	docker compose down --rmi all --remove-orphans

shell:
	@$(COMPOSE_RUN) builder sh
