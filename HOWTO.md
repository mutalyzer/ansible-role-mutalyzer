How to use the Mutalyzer Ansible role
=====================================

[Ansible](http://www.ansible.com/) is an automation platform for application
and systems deployment. Deployments are described by *playbooks* which
leverage *roles* for composition and reuse.

The Mutalyzer Ansible role can be used to deploy a complete Mutalyzer
environment from an Ansible playbook. The environment will include the
Mutalyzer website, SOAP and HTTP/RPC+JSON webservices, batch scheduler, HTTPS
configuration, etcetera. Here we describe the steps needed to get a Mutalyzer
environment using this role.

If you're just looking for a quick deployment on a local virtual machine
without any configuration needed, have a look at the [vagrant](vagrant)
directory.


Install Ansible
---------------

We need Ansible 1.9.2 or higher.

    pip install ansible


Get the role and its dependencies
---------------------------------

Download all needed Ansible roles in the `roles` directory.

```bash
mkdir roles
git clone https://github.com/mutalyzer/ansible-role-mutalyzer.git roles/mutalyzer
git clone https://git.lumc.nl/humgen-devops/ansible-role-exim.git roles/exim
git clone https://git.lumc.nl/humgen-devops/ansible-role-mail-service-status.git roles/mail-service-status
git clone https://git.lumc.nl/humgen-devops/ansible-role-nginx.git roles/nginx
git clone https://git.lumc.nl/humgen-devops/ansible-role-postgresql.git roles/postgresql
git clone https://git.lumc.nl/humgen-devops/ansible-role-redis.git roles/redis
```


Provision a host machine
------------------------

Find or create a machine with Debian 8 (Jessie) installed and an SSH
server. We will refer to its IP address as `MUTALYZER_IP`.

The machine must also have a user with sudo rights, which we will refer to as
`MUTALYZER_USER`.


Create a playbook
-----------------

Create a file `playbook.yml` with contents like the following:

```yml
---
- name: deploy mutalyzer
  hosts: mutalyzer
  sudo: yes
  roles: [exim, mutalyzer]
  pre_tasks:
  - name: update apt cache
    apt: update_cache=yes
```


Create an inventory
-------------------

An inventory file is where you define your infrastructure for Ansible. In this
case, we have just one machine which we call `mutalyzer`. In the inventory, we
define its IP address and the user to login as:

    mutalyzer ansible_ssh_host=MUTALYZER_IP ansible_ssh_user=MUTALYZER_USER

Save this file as `inventory`.


Run the playbook
----------------

Now run the playbook, specifying the inventory and having Ansible ask for the
`MUTALYZER_USER` password:

    ansible-playbook -i inventory -k playbook.yml

This will take quite a while.


Enjoy your Mutalyzer
--------------------

You can now open a browser and go to https://MUTALYZER_IP to use your new
Mutalyzer installation.


Customize the deployment
------------------------

Above we used default settings for all roles, but many of them provide
variables we can customize. We can do this by creating a host vars file:

```bash
mkdir host_vars
touch host_vars/mutalyzer.yml
```

For example, we can have the following in `host_vars/mutalyzer.yml` to use a
custom hostname, another SSL certificate than the default insecure one, and a
certain Git branch to get the Mutalyzer source code from:

```yml
---
mutalyzer_server_name: mutalyzer.example.com
mutalyzer_certificate: "{{ inventory_dir }}/mutalyzer.example.com.crt"
mutalyzer_certificate_key: "{{ inventory_dir }}/mutalyzer.example.com.key"
mutalyzer_git_branch: release
```

Please consult the role documentation for a list of variables each role
provides.
