.PHONY: all test clean test-setup

export DOCKER_CLI_HINTS=false

DOCKER_RUN = docker run --rm -v $$(pwd):/workspace -w /workspace

tests = $(shell grep -E '^test-.*:' Makefile | sed 's/:$$//')
cleans = $(shell grep -E '^clean-.*:' Makefile | sed 's/:$$//')

serve: clean-public
	docker run --rm -v $$(pwd):/src -w /src -p 127.0.0.1:1313:1313 hugomods/hugo:git hugo server --disableFastRender -DEF --bind 0.0.0.0 --poll 700ms

build: clean-public test
	docker run --rm -v $$(pwd):/src -w /src hugomods/hugo:git hugo --minify

test: setup-tests $(tests)

setup-tests: build/schemas/dependabot-2.0.json build/schemas/github-workflows.json

build/schemas/dependabot-2.0.json:
	mkdir -p build/schemas
	curl -sLo build/schemas/dependabot-2.0.json https://www.schemastore.org/dependabot-2.0.json

build/schemas/github-workflows.json:
	mkdir -p build/schemas
	curl -sLo build/schemas/github-workflows.json https://www.schemastore.org/github-workflow.json

test-dependabot:
	$(DOCKER_RUN) ghcr.io/sourcemeta/jsonschema validate build/schemas/dependabot-2.0.json .github/dependabot.yml

test-editorcheck:
	$(DOCKER_RUN) mstruebing/editorconfig-checker ec -exclude '\.git/|public/|build/|.DS_Store' .

test-github:
	@find .github/workflows -type f \( -iname \*.yaml -o -iname \*.yml \) -print0 | \
		xargs -0 -I {} echo 'echo Checking: {}; docker run --rm -v $$(pwd):/workspace -w /workspace ghcr.io/sourcemeta/jsonschema validate build/schemas/github-workflows.json {}' | \
		sort | sh -e

clean: $(cleans)
	-rm -rf public
	docker system prune -f

clean-public:
	-rm -rf public

shell:
	docker run -it --rm -v $$(pwd):/src -w /src hugomods/hugo:git sh
