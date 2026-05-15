Mentor Hub mh
# System Tour

Welcome to the Mentor Hub System - a poly-repo, backend for frontend, microservice architecture application. This is a tour-guide that will help you familiarize yourself with the codebase. Don't feel too overwhelmed, you will only work on a single repo at a time, this tour will introduce you to all of them. 

## Developer Edition
If you haven't already installed the Developer Edition cli ``mh`` you should do so now. Then let's take a look at what that tool actually does. 

``mh`` is just a bash script - that largely just wraps some ``docker compose`` commands. You should browse that script, and the [docker-compose.yaml](../docker-compose.yaml) to understand how the application is divided into services, and how they are run altogether or one at a time. 

Now - let's use ``mh`` to pull the latest containers from our GitHub Container Registry. Use 
```sh
# pull all of the latest containers from GitHub
mh pull all  
``` 

Now - let's use ``mh`` to start the whole system. Use
```sh
# Start all containers
mh up all
```
and then visit [localhost:8080](http://localhost:8080/) and explore the system. Note that the database is currently empty, so a lot of screens will be empty as well. After you run black-box and cypress tests as described below there will be data in the database that is left behind by the testing. All data is lost when you down/up services. When you are done exploring use 
```sh
# Stop all containers (database data is lost)
mh down
```

## Clone Everything
Ok - now to look at all of the different repo's. You will first need to clone them down to your computer - you can do so using the stage0 launch UI. Use these commands:
```sh
# to shut down the app if it's running
mh down

# to start the launch tools
make stage0-launch-ui
```
Now open your browser to [localhost:8080](http://localhost:8080/) and click the "all" checkbox, and click the "Clone" button. When you are done, click **Exit** and the launch utility container will stop automatically.

## Tour common code libraries
With the Backend for Frontend pattern, all of our services consist of a single API that supports a single SPA. Common code that is used by multiple API's or SPA's is shared in utility repo's. Review these repo's to see the overall patterns used.

### mentorhub_api_utils
Review the README - and then try these developer commands. 
```sh
# to install dependencies
pipenv install --dev

# to run unit testing     
pipenv run test

# to run a backing MongoDB database
pipenv run db

# to run the API Demo Server (requires a db, captures command line)
pipenv run dev

# to run black-box e2e testing (requires dev mode server)
pipenv run e2e
```
Leave the dev server running while we move on to the SPA

### mentorhub_spa_utils
Review the README - and then try these developer commands
```sh
# to install dependencies
npm install --include=dev

# to run unit testing
npm run test

# to run UI Demo Server (captures command line, requires API dev server)
npm run dev

# to run black-box cypress tests (requires SPA dev server)
npm run cypress:run
```
You can now stop the API and SPA dev servers before moving on

## Tour mentorhub Services

Each service in the system has a paired API and SPA. Review the README's in each Repo (they all rhyme) and then try these developer commands - they should work in every API/SPA repo.

### mentorhub_*_api
```sh
# install dependencies
pipenv install --dev

# run unit testing
pipenv run test

# start a backing MongoDB Database
pipenv run db

# start the API Server in dev mode (requires db, captures command line)
pipenv run dev

# run black-box e2e testing (requires API running)
pipenv run e2e

# build the API container 
pipenv run container

# run the API container (and backing database)
pipenv run api
```

### mentorhub_*_spa
```sh
# install dependencies
npm install --include=dev

# run unit testing
npm run test

# run the backing API and Database
npm run api

# run the UI in Dev Mode (requires api, captures command line)
npm run dev

# run the Cypress tests (requires UI)
npm run cypress:run

# build a container
npm run container

# run the Database + API + SPA containers
npm run service
```

## Schema editor
As we work on this system we will be using the Schema Configurator tool to describe data structures, generate JSON Schema for use with Task Automation, and configure MongoDB for use with the system. From the launchpad folder run 
```sh
cd mentorhub_mongodb_api
make dev
```
to start the Configurator in Edit mode. This should open Chrome, Click the ? icon and review the help screens. 

## Task Automation 
Every repo has a /Tasks folder, with a README that describes the Task Automation framework. This framework is used to create re-usable LLM tasks for working in a repo. You can review existing tasks, or ask your AI Code Assistant to review the Task Automation README.md and help you create a new task for something you want to accomplish. 

## Merge Templates and launch automation
**Extra Credit** If you want to understand the tooling that was used to help launch this product, you can review the README at [stage0_launch](https://github.com/agile-learning-institute/stage0_launch) which uses [stage0_runbook_merge](https://github.com/agile-learning-institute/stage0_runbook_merge) to automate repository provisioning.