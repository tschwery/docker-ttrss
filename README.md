# docker-ttrss

This [Docker](https://www.docker.com) image allows you to run the [Tiny Tiny RSS](http://tt-rss.org) feed reader.
## About Tiny Tiny RSS

## Quickstart

The fastest way to use this image is with `docker-compose`. I use the
following file for an internal deployment:

```
version: '2'

services:
  postgresql:
    restart: on-failure
    image: postgres:9.6.3
    volumes:
      - '/srv/ttrss/postgresql:/var/lib/postgresql/:Z'
    environment:
    - POSTGRES_USER=ttrss
    - POSTGRES_PASSWORD=some_password
    - POSTGRES_DB=ttrss-production

  ttrss:
    restart: on-failure
    build: docker-ttrss
    depends_on:
    - postgresql
    ports:
    - "30080:80"
    environment:
      - DB_HOST=postgresql
      - DB_PORT=5432
      - DB_NAME=ttrss-production
      - DB_USER=ttrss
      - DB_PASS=some_password
      - DB_TYPE=pgsql
      - SELF_URL_PATH=https://ttrss.srv.local

```

Then initialize and launch the containers:

```bash
$ docker-compose -d up
```

Running this command will download the images automatically, create the
containers and start them.

## Accessing your webinterface

The above example exposes the Tiny Tiny RSS webinterface on port 30080,
so that you can browse to http://localhost:30080

The default login credentials are:

* Username: admin
* Password: password

Obviously, change these as soon as possible.

## Environment variables configuration
* `DB_HOST`: Host of the database to use
* `DB_TYPE`: Type of database
* `DB_PORT`: Port used. Set to the default values for MySQL or PostgreSQL
    if not defined
* `DB_NAME`: Name of the database. It must already be created.
* `DB_USER`: User to access the database
* `DB_PASS`: Password to access the database
* `SELF_URL_PATH`: URL to the tt-rss installation (From tt-rss documentation: )
    You need to set this option correctly otherwise several features including
    PUSH, bookmarklets and browser integration will not work properly.

In addition to these variables, every defined value in the `config.php`
file can be overridden using an environment variable.

## Volumes
This container should not have any data to backup. Read the documentation
of the database container for the volumes needed to save the database
content.
