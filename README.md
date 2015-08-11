Ansible role for Mutalyzer
==========================


Requirements
------------

- Debian 8 (Jessie) with a configured MTA
- Ansible version 1.9.2


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
- [PostgreSQL](http://www.postgresql.org/) for the database.
- [Redis](http://redis.io/) for stat counters and other in-memory stores.

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

### `postgresql`

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
        database_privileges:
          - database: mutalyzer
            privileges: ALL

### `redis`

https://git.lumc.nl/humgen-devops/ansible-role-redis

### `nginx`

https://git.lumc.nl/humgen-devops/ansible-role-nginx


Variables
---------

Also see variables of dependencies.

### `mutalyzer_certificate`

Default: `localhost-insecure.crt` (self-signed certificate for `localhost`)

SSL certificate file.

### `mutalyzer_certificate_key`

Default: `localhost-insecure.key`

SSL certificate keyfile.

### `mutalyzer_database_password`

Default: `insecure_password`

Password for the PostgreSQL database user.

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
`vagrant` directory.
