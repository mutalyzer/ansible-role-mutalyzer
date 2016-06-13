Ansible role for Mutalyzer
==========================

This role deploys the HGVS variant nomenclature checker
[Mutalyzer](https://mutalyzer.nl/).

New here? Check out [How to use the Mutalyzer Ansible role](HOWTO.md).


Table of contents
-----------------

- [Requirements](#requirements)
- [Description](#description)
- [Dependencies](#dependencies)
- [Variables](#variables)
- [Local deployment with Vagrant](#local-deployment-with-vagrant)


Requirements
------------

- Debian 8 (Jessie) with a configured MTA
- Ansible version 2.0.1


Description
-----------

The deployment uses the following tools:

- [nginx](http://nginx.org/) as reverse proxy for Gunicorn and for serving
  static files.
- [systemd](http://freedesktop.org/wiki/Software/systemd/) for process
  control.
- [Gunicorn](http://gunicorn.org/) as WSGI HTTP server.
- [virtualenv](http://virtualenv.readthedocs.org/) for isolation of the Mutalyzer
  package and its Python dependencies.
- [PostgreSQL](http://www.postgresql.org/) for the database (can be customized).
- [Redis](http://redis.io/) for stat counters and other in-memory stores (can
  be customized).

Three applications are served by nginx:

- Website: `https://<servername>/`
- HTTP/RPC+JSON webservice: `https://<servername>/json`
- SOAP webservice: `https://<servername>/services`


### Files and directories

Logging is done at several levels in this stack:

- Mutalyzer log: `/opt/mutalyzer/log/mutalyzer.log`
- Mutalyzer website Gunicorn log: `/opt/mutalyzer/versions/*/log/website.log`
- Mutalyzer HTTP/RPC+JSON webservice Gunicorn log: `/opt/mutalyzer/versions/*/log/service-json.log`
- Mutalyzer SOAP webservice Gunicorn log: `/opt/mutalyzer/versions/*/log/service-soap.log`
- nginx access and error logs: `/var/log/nginx/`
- redis server logs: `/var/log/redis/`
- PostgreSQL server logs: `/var/log/postgresql/`

Tool configurations can be found here (but you should never manually touch
them):

- Mutalyzer configuration: `/opt/mutalyzer/versions/*/conf/settings.py`
- Mutalyzer website Gunicorn configuration: `/opt/mutalyzer/versions/*/conf/website.conf`
- Mutalyzer HTTP/RPC+JSON webservice Gunicorn configuration: `/opt/mutalyzer/versions/*/conf/service-json.conf`
- Mutalyzer SOAP webservice Gunicorn configuration: `/opt/mutalyzer/versions/*/conf/service-soap.conf`
- nginx configuration: `/etc/nginx/sites-available/mutalyzer-*`

All Mutalyzer processes run as user `mutalyzer`, which is also the owner of
everything under `/opt/mutalyzer`. Some other Mutalyzer related locations are:

- Mutalyzer cache: `/opt/mutalyzer/cache/`
- Mutalyzer Git clone: `/opt/mutalyzer/src/mutalyzer/`
- Mutalyzer versions: `/opt/mutalyzer/versions/`


### Zero-downtime deployments

In order to obtain zero-downtime deployments, we fix and isolate deployment
versions. A version is identified by its Git commit hash and contains a Python
virtual environment, configuration files, log files, and unix sockets for the
website and webservices. Several versions can co-exist, but only one version
is active (published).

The deployment of a new version is done when the Mutalyzer Git repository
checkout changes:

1. Create the new version in `/opt/mutalyzer/versions/<git commit hash>/`.
2. Run unit tests (if enabled, see variables below).
3. Run database migrations.
4. Start the new Gunicorn website and services.
5. Test the availability of the website and services.
6. Stop running batch processor and start a new one.
7. Reload nginx with the new Gunicorn upstreams.
8. Stop the old Gunicorn website and services (first completing all their
   pending requests).

In step 7, nginx will complete all existing requests from the old
configuration while accepting requests with the new configuration, so this is
zero-downtime.

The order above also means database migrations must always keep compatibility
with the existing codebase, so some may have to be broken down into several
steps and completed over several deployments.

Migrations that should be completed over several deployments are grouped per
Mutalyzer release. It is therefore advised to always update Mutalyzer one
release at a time and never skip a release to ensure database consistency and
zero-downtime deployments. This can be controled by setting the
`mutalyzer_git_branch` role variable to a release tag.


### User environment

The `~/.bashrc` file for user `mutalyzer` activates the Mutalyzer Python
virtual environment and sets the `MUTALYZER_SETTINGS` environment
variable. Administrative work is best done as that user:

    sudo -u mutalyzer -i

Please note that you should re-source `~/.bashrc` in any existing shell
sessions after deploying a new Mutalyzer version, to switch to the current virtual
environment.


Dependencies
------------

This role depends on the following roles:

### `postgresql` (optional)

https://git.lumc.nl/humgen-devops/ansible-role-postgresql

Variable overrides:

    postgresql_databases:
      - name: mutalyzer
        encoding: UTF8
        lc_collate: 'en_US.UTF-8'
        lc_ctype: 'en_US.UTF-8'
        backup: true
    postgresql_users:
      - name: mutalyzer
        password: "{{ mutalyzer_database_password }}"
        attributes: NOSUPERUSER,NOCREATEDB
        databases:
          - name: mutalyzer
            privileges: ALL

This role is only needed when the `mutalyzer_database_url` variable is `null`
(default).

### `redis`

https://git.lumc.nl/humgen-devops/ansible-role-redis

This role is only needed when the `mutalyzer_redis_url` variable is `null`
(default).

### `nginx`

https://git.lumc.nl/humgen-devops/ansible-role-nginx

### `mail-service-status`

https://git.lumc.nl/humgen-devops/ansible-role-mail-service-status


Variables
---------

Also see variables of dependencies.

### `mutalyzer_certificate`

Default: `localhost-insecure.crt` (self-signed certificate for `localhost`)

SSL certificate file.

### `mutalyzer_certificate_key`

Default: `localhost-insecure.key`

SSL certificate keyfile.

### `mutalyzer_database_url`

Default: `null`

URL to use for connecting to a database in a form accepted by SQLAlchemy (see
[SQLAlchemy Database Urls](http://docs.sqlalchemy.org/en/latest/core/engines.html#database-urls)).

If `null`, a local PostgreSQL database is used (managed by this role). If a
database server is specified, it should be running when applying this role.

### `mutalyzer_database_password`

Default: `insecure_password`

Password for the database user. Only used when `mutalyzer_database_url` is
`null` (the password is part of the URL otherwise).

### `mutalyzer_redis_url`

Default: `null`

URL to use for connecting to a Redis server in a form accepted by
[redis-py](https://github.com/andymccurdy/redis-py) (see
[redis-py documentation](https://github.com/andymccurdy/redis-py/blob/2.10.5/redis/client.py#L371-L389)).

If `null`, a local Redis server is used (managed by this role). If another
Redis server is specified, it should be running when applying this role.

### `mutalyzer_server_name`

Default: `localhost`

Server name by which Mutalyzer can be reached.

### `mutalyzer_website_proxy_read_timeout`

Default: 60

Nginx read timeout for the website Gunicorn upstream.

### `mutalyzer_website_worker_class`

Default: `sync`

Type of Gunicorn worker for the website. Must be one of `sync`, `eventlet`,
`gevent`.

### `mutalyzer_website_workers`

Default: 2

Number of Gunicorn workers for the website.

### `mutalyzer_website_timeout`

Default: 30

Timeout before killing silent Gunicorn workers for the website.

### `mutalyzer_service_json_proxy_read_timeout`

Default: 60

Nginx read timeout for the HTTP/RPC+JSON webservice Gunicorn upstream.

### `mutalyzer_service_json_worker_class`

Default: `sync`

Type of Gunicorn worker for the HTTP/RPC+JSON webservice. Must be one of
`sync`, `eventlet`, `gevent`.

### `mutalyzer_service_json_workers`

Default: 1

Number of Gunicorn workers for the HTTP/RPC+JSON webservice.

### `mutalyzer_service_json_timeout`

Default: 30

Timeout before killing silent Gunicorn workers for the HTTP/RPC+JSON
webservice.

### `mutalyzer_service_soap_proxy_read_timeout`

Default: 60

Nginx read timeout for the SOAP webservice Gunicorn upstream.

### `mutalyzer_service_soap_worker_class`

Default: `sync`

Type of Gunicorn worker for the SOAP webservice. Must be one of `sync`,
`eventlet`, `gevent`.

### `mutalyzer_service_soap_workers`

Default: 1

Number of Gunicorn workers for the SOAP webservice.

### `mutalyzer_service_soap_timeout`

Default: 30

Timeout before killing silent Gunicorn workers for the SOAP webservice.

### `mutalyzer_batch_notification_email`

Default: `noreply@localhost`

Address used as sender in batch job notification emails.

### `mutalyzer_max_cache_size`

Default: 52428800  (50 MB)

Maximum size of the cache directory (in bytes).

### `mutalyzer_extractor_max_input_length`

Default: 50000 (50 Kbp)

Maximum sequence length for the description extractor (in bases).

### `mutalyzer_remote_caches`

Default: `[]`

List of remotes to sync the cache with, where each remote is a dictionary with
the following fields:

- `name`: Remote name (should contain only letters, digits, `-`, and `_`).
- `wsdl`: Location of the remote WSDL description.
- `url_template`: URL for remote downloads, in which the filename is to be
  substituted for `{file}`.

### `mutalyzer_piwik`

Default: `null`

Piwik web analytics configuration as a dictionary with the following fields:

- `base_url`: Piwik server base URL (include protocol, no trailing slash).
- `site_id`: Piwik site ID.

### `mutalyzer_prune_versions`

Default: `true`

Whether or not to remove old Mutalyzer versions, including their Python virtual
environment, log files, and configuration.

### `mutalyzer_unit_tests`

Default: `false`

Whether or not to run Mutalyzer unit tests. Deployment will be aborted if they
fail.

### `mutalyzer_git_repository`

Default: `https://github.com/mutalyzer/mutalyzer.git`

Mutalyzer Git repository URL to clone.

### `mutalyzer_git_branch`

Default: `master`

Mutalyzer Git repository branch to checkout.


Local deployment with Vagrant
-----------------------------

Easy deployment on a local virtual machine using Vagrant is provided in the
[vagrant](vagrant) directory.
