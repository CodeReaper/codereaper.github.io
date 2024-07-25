.DEFAULT_GOAL := run

clean:
	rm -rf public || true

run: clean
	hugo --disableFastRender -D server

build: clean
	hugo --minify
