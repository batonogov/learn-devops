reqs:
	rm ./requirements.txt || true
	uv pip compile --generate-hashes pyproject.toml --output-file ./requirements.txt

venv:
	uv venv --python 3.13
	uv pip install --require-hashes --requirements ./requirements.txt
	. .venv/bin/activate

build:
	time docker build --no-cache --file Dockerfile -t uv .
	docker images

build-pip:
	time docker build --no-cache --file Dockerfile.pip -t pip .
	docker images

outdated:
	uv pip list --outdated
