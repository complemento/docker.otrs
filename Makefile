# HELP
# This will output the help for each task
# thanks to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: help

help: ## This help.
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.DEFAULT_GOAL := help


# DOCKER TASKS

# Build the container
create: ## construct the containers
	docker login dockerhub.complemento.net.br
	docker-compose create 

dev: ## run container in development mode
	docker login dockerhub.complemento.net.br
	docker-compose build --no-cache \
	&& docker-compose run 

up: ## build and run the container
	docker login dockerhub.complemento.net.br
	docker-compose up 

start: ## stop all containers 
	docker-compose start 

stop: ## stop all containers 
	docker-compose stop 

rm: stop ## stop and remove containers
	docker-compose rm 

clean: stop ## clean the generated containers and volumes
	   docker-compose rm -f -v 