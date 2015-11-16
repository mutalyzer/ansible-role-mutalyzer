Local deployment with Vagrant
=============================

Tested with Vagrant 1.7.4.

This provides easy deployment on a local virtual machine using Vagrant. The
configuration is based on a
[Debian 8 (Jessie) box](https://atlas.hashicorp.com/debian/boxes/jessie64).


Usage
-----

Role dependencies are configured using git submodules, so fetch those first:

    git submodule init
    git submodule update

To get a machine up, run:

    vagrant up

If you just want to re-play the Ansible playbook, run:

    vagrant provision

You can SSH into the machine with:

    vagrant ssh

Running Ansible manually can be done like this:

    ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i inventory playbook.yml

(Unfortunately, there seems to be no easier way to disable host key checking
for the Vagrant host only.)


Configuration
-------------

The machine configuration can be changed by setting the following environment
variables:

### `MUTALYZER_IP`

Default: 192.168.111.222

IP address of the virtual machine.

### `MUTALYZER_PORT_FORWARD_SSH`

Default: 2522

Local port forward for SSH (VM port 22).

### `MUTALYZER_PORT_FORWARD_HTTP`

Default: 8088

Local port forward for HTTP (VM port 80).

### `MUTALYZER_PORT_FORWARD_HTTPS`

Default: 8089

Local port forward for HTTPS (VM port 443).

### `MUTALYZER_MEMORY`

Default: 1024

Memory for the VM (in megabytes).

### `MUTALYZER_CORES`

Default: 1

Number of cores for the VM.


Notes
-----

The Mutalyzer website can be accessed over HTTPS on
[localhost port 8089](https://localhost:8089/) or
[VM port 443](https://192.168.111.222/).

The self-signed SSL certificate is valid for:

- `mutalyzer.local`
- `localhost`
- 192.168.111.222
- 127.0.0.1

Since Mutalyzer needs an MTA, Exim is installed and configured for local
delivery only.
