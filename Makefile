# Self-Documented Makefile see https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html

.DEFAULT_GOAL := help

PYTHON 			:= /usr/bin/env python
PYTHON_VERSION  := $(PYTHON) --version
MANAGE_PY 		:= $(PYTHON) manage.py
PYTHON_PIP  	:= /usr/bin/env pip
PIP_COMPILE 	:= /usr/bin/env pip-compile
PART 			:= patch
PACKAGE_VERSION = $(shell $(PYTHON) setup.py --version)

# Put it first so that "make" without argument is like "make help".
help:
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-32s-\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: help

guard-%: ## Checks that env var is set else exits with non 0 mainly used in CI;
	@if [ -z '${${*}}' ]; then echo 'Environment variable $* not set' && exit 1; fi

# --------------------------------------------------------
# ------- Python package (pip) management commands -------
# --------------------------------------------------------
clean-build: ## Clean project build artifacts.
	@echo "Removing build assets..."
	@$(PYTHON) setup.py clean
	@rm -rf build/
	@rm -rf dist/
	@rm -rf *.egg-info

install: clean-build  ## Install project dependencies.
	@echo "Installing project in dependencies..."
	@$(PYTHON_PIP) install -r requirements.txt

install-lint: clean-build  ## Install lint extra dependencies.
	@echo "Installing lint extra requirements..."
	@$(PYTHON_PIP) install -e .'[lint]'

install-test: clean-build clean-test-all ## Install test extra dependencies.
	@echo "Installing test extra requirements..."
	@$(PYTHON_PIP) install -e .'[test]'

install-dev: clean-build  ## Install development extra dependencies.
	@echo "Installing development requirements..."
	@$(PYTHON_PIP) install -e .'[development]' -r requirements.txt

update-requirements:  ## Updates the requirement.txt adding missing package dependencies
	@echo "Syncing the package requirements.txt..."
	@$(PIP_COMPILE)

# --------------------------------------------------------
# ------- Django manage.py commands ---------------------
# --------------------------------------------------------
migrations:
	@$(MANAGE_PY) makemigrations

migrate:
	@$(MANAGE_PY) migrate

run: migrate
	@echo "Starting server..."
	@$(MANAGE_PY) runserver

default-user: migrate
	@echo "Creating a default user..."
	@$(MANAGE_PY) create_default_user
	@echo "Username: admin@admin.com"
	@echo "Password: admin"

makemessages: clean-build  ## Runs over the entire source tree of the current directory and pulls out all strings marked for translation.
	@$(MANAGE_PY) makemessages --locale=en_US  --ignore=sample
	@$(MANAGE_PY) makemessages --locale=fr  --ignore=sample

compilemessages: clean-build  ## Compiles .po files created by makemessages to .mo files for use with the built-in gettext support.
	@$(MANAGE_PY) compilemessages --ignore=.tox,sample

test:
	@echo "Running `$(PYTHON_VERSION)` test..."
	@$(MANAGE_PY) test

# ----------------------------------------------------------
# ---------- Upgrade project version (bumpversion)  --------
# ----------------------------------------------------------
increase-version: clean-build makemessages compilemessages guard-PART  ## Bump the project version (using the $PART env: defaults to 'patch').
	@git checkout main
	@echo "Increasing project '$(PART)' version..."
	@$(PYTHON_PIP) install -q -e .'[deploy]'
	@bumpversion --verbose $(PART)
	@git-changelog . > CHANGELOG.md
	@git add .
	@[ -z "`git status --porcelain`" ] && echo "No changes found." || git commit -am "Updated CHANGELOG.md."

release:  increase-version  ## Release project to pypi
	@$(PYTHON_PIP) install -U twine
	@$(PYTHON) setup.py sdist bdist_wheel
	@twine upload -r pypi dist/*
	@git-changelog . > CHANGELOG.md
	@git add .
	@[ -z "`git status --porcelain`" ] && echo "No changes found." || git commit -am "Updated CHANGELOG.md."
	@git pull
	@git push
	@git push --tags

# ----------------------------------------------------------
# --------- Run project Test -------------------------------
# ----------------------------------------------------------
tox: install-test  ## Run tox test
	@tox

clean-test-all: clean-build  ## Clean build and test assets.
	@rm -rf .tox/
	@rm -rf test-results
	@rm -rf .pytest_cache/
	@rm -f test.db
	@rm -f ".coverage.*" .coverage coverage.xml


# -----------------------------------------------------------
# --------- Fix lint errors ---------------------------------
# -----------------------------------------------------------
lint-fix:  ## Run black with inplace for model_clone and sample/models.py.
	@pip install black autopep8
	@black model_clone sample/models.py sample_driver sample_assignment sample_company --line-length=95
	@autopep8 -ir model_clone sample/models.py sample_driver sample_assignment sample_company --max-line-length=95

# -----------------------------------------------------------
# --------- Docs ---------------------------------------
# -----------------------------------------------------------
serve-docs:
	@npm i -g docsify-cli
	@npx docsify serve ./docs
