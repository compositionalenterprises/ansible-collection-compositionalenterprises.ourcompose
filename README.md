# Ansible Collection - compositionalenterprises.ourcompose

![OurCompose Productivity Suite](https://gitlab.com/compositionalenterprises/jekyll-ourcomposecast/-/raw/master/assets/logos/banner_logo.jpg)

A handful of open source applications integrated together, making it easy for anyone to deploy a suite of tools with the click of a button.

### [Feature Roadmap](https://compositionalenterprises.ourcompose.com/kanboard/public/board/245d06ce519a4deba6131ea58a65afa9efc0e6de584e04b08a81c4115322)

The above link will take you to our Roadmap Kanboard where we prioritize tasks for the upcoming work. If you see something or DON'T see something on there, feel free to [reach out to us](https://ourcompose.com/commandcenter/contact) or file an issue against the affected repo.

We also prioritize bugfixes and security vulnerabilities separately, which are not displayed on that board. This board is solely for new features and improvements.

# QuickStart

#### NOTE: This is only for a minimal setup. This will leave all data exposed with default passwords, an unsecured OS, and an unsupported method of installing docker. But it works if you just want to get your hands on it really quickly.

1. Start with a current Ubuntu base OS that you have root on (Setting up with DNS is preferable, but not required)
2. Run the included playbook against the host (specify services you want as a list as an argument, or put that in a vars file somewhere)
```bash
$ ansible-playbook -i <server-dns-name-or-ip-addr>, playbooks/dev_setup.yml -e '{"ourcompose_common_services": ["nextcloud"]}'
```

#### NOTE: The comma after the server's DNS name or IP address is required, as it "tricks" ansible to using that single string as a hostname rather as a file for the inventory.

You should now be able to access that host at the DNS name or IP address that was specified above. It will be using a self-signed certificate, so you'll likely have to accept an invalid cert prompt.

# Requirements

## Operating System

- Supported OS:
  - Ubuntu 18.04
  - Ubuntu 20.04

- Swap (optional, but recommended if running with minimal RAM)

## SSL Certificates

By default this role creates its own self-signed certificates.
It allows for SSL certs to be set up somewhere on the server where docker can mount it as a volume to wherever inside of the proxy container it needs to go.
Those can be configured by setting the following variables, shown here set up for Let's Encrypt:

```yaml
ourcompose_common_cert_volume: '/etc/letsencrypt:/etc/letsencrypt'
ourcompose_common_cert_fullchain: "/etc/letsencrypt/live/{{ ourcompose_common_domain }}/fullchain.pem"
ourcompose_common_cert_privkey: "/etc/letsencrypt/live/{{ ourcompose_common_domain }}/privkey.pem"
```

## Python Libraries

On the remote host, [Docker](https://docs.docker.com/engine/install/) needs to be installed.

The additional python packages also need to be installed so that they are made available to the python interpreter that ansible uses on the remote host:
- `docker-py`
- `docker-compose`
- `systemd-python`

# Role Variables

This will always be changing and being added to. However, there are a couple categories that are independent of services, and several that are applicable to all of the services:

## General

```yaml
# OVERRIDE THIS!!!!
ourcompose_mariadb_root_password: 'testpassword'
# The enumeration of the services to be installed.
# You'll probably want to override this with a subset
# of only the services that you want installed.
ourcompose_common_services:
  - 'akaunting'
  - 'bitcoind'
  - 'bitwarden'
  - 'bookstack'
  - 'commandcenter'
  - 'dolibarr'
  - 'firefly'
  - 'kanboard'
  - 'nextcloud'
  - 'rundeck'
  - 'suitecrm'
  - 'wordpress'
```

## Environment

```yaml
# The domain that will be pointing to the server's IP
ourcompose_common_domain: 'example.com'
```

#### NOTE: This will default to the inventory hostname that is used in the ansible-playbook run.

## Services

All of the services have variables with the prefix: `ourcompose_<service name>_`.

### Typical

There are several variables that are typical of all of the services using that prefix. These are all directly associated with their related [docker_compose ansible module](https://docs.ansible.com/ansible/latest/modules/docker_compose_module.html) options:

- [pull](https://docs.ansible.com/ansible/latest/modules/docker_compose_module.html#parameter-pull)
- [state](https://docs.ansible.com/ansible/latest/modules/docker_compose_module.html#parameter-state)

There are two others that are specific to this role:

- `version`: The container image tag version to pull
- `storage`: Whether this should go under `local` or `remote` storage. Note that `remote` storage is simply a directly under `/srv` that is meant to be mounted to an external volume of some kind, but is otherwise functionally the same as `local`.

### Database Backend Services

All services that have a database backend (which is most of them) have a variable to set the password for the account that will be created in that database for them to use.
**THIS IS INSECURE BY DEFAULT AND SHOULD BE OVERRIDDEN FOR INSTANCES DEPLOYED IN PRODUCTION**.
They come in the form of `ourcompose_<service name>_backend_password`.

### Bind Mountpoints

These mountpoints will be able to be set up on any service to be able to bind-mount static assets into the frontend proxy in order to avoid contacting backend servers and speed up the transmission of the assets.
They come in the form of `ourcompose_< service >_bind_mountpoints`.

This variable is in the following format:

```yaml
ourcompose_firefly_bind_mountpoints:
  - {location: '/firefly/v1/css/', directory: '/var/www/firefly-iii/public/v1/css'}
  - {location: '/firefly/v1/fonts/', directory: '/var/www/firefly-iii/public/v1/fonts'}
  - {location: '/firefly/v1/images/', directory: '/var/www/firefly-iii/public/v1/images'}
  - {location: '/firefly/v1/js/', directory: '/var/www/firefly-iii/public/v1/js'}
  - {location: '/firefly/v1/lib/', directory: '/var/www/firefly-iii/public/v1/lib'}
```

So this is a list of dictionaries.
The dictionaries have the keys `location`, and `directory`.
The `location` is the subdomain path that should be intercepted and redirected to the local bindmount.
The `directory` key is the location within the image where the assets are location.
Alternatively, if the path in the `directory` key starts with `/srv`, the role will look at the host's `/srv` directory for that location, rather than inside the image.

#### NOTE: This is hard-coded right now. If it becomes an issue, we can make the `/srv` location a variable, but for now all `directory` keys that point to `/srv` are expected to be exposed at the host's level.

### Domain Redirects

Any site that has its DNS pointing to an instance can have an alternate DNS entry redirected. This comes in the form of:

```yaml
ourcompose_common_domain_redirects:
  - {domain: 'ourcomposecast.com', redirect: 'https://ourcompose.com/jekyll', cert: 'live/ourcomposecast.com/fullchain.pem'}
  - {domain: 'ourcomposesignup.com', redirect: 'https://ourcompose.com/commandcenter', cert: 'live/ourcomposesignup.com/fullchain.pem'}
ourcompose_common_domain_redirects: []
```

If there is no cert, the `HTTPS` requests will _NOT_ be able to be accepted.

#### NOTE: If there is any abuse of this functionality in the future, this could be restricted to redirects pointing to only locations within the `{{ ourcompose_common_domain }}`.

### Jekyll

Jekyll has a couple of others to use:

- `ourcompose_jekyll_git_url`: The URL to use for the Jekyll theme as a git repo
- `ourcompose_jekyll_git_branch`: The branch of that git repo to use
- `ourcompose_jekyll_extra_commands`: This can be used to execute arbitrary commands inside of the container before the command to build the website is given. This is useful for installing additional tools, or copying down additional materials that need to be included in the container at runtime. This allows for us to provide customized runtimes while still utilizing the upstream container.

### Rundeck

- `ourcompose_rundeck_api_tokens_duration_max`: Set to '0' by default, this eliminates any limits on API token lifetime length. Set this to a number of minutes to enforce that limit.
- `ourcompose_rundeck_additional_setup`: This is another place to execute arbitrary commands as root within the container. This is especially useful for installing requirements if scripts are going to be running on the host server's environment. The distro this is based off of is Ubuntu, so make sure to `apt update` before trying to install anything.

### CommandCenter and Portal

CommandCenter and Portal allow us to store their `production_key` and `production.yml.enc` file contents in the following variables:

- `ourcompose_commandcenter_production_key`: Can be found at `config/credentials` folder of commandcenter application, sample keys are passed by default
- `ourcompose_commandcenter_production_yml_enc`: Can be found at `config/credentials` folder of commandcenter application, sample keys are passed by default
- `ourcompose_portal_production_key`: Can be found at `config/credentials` folder of portal application, sample keys are passed by default
- `ourcompose_portal_production_yml_enc`: Can be found at `config/credentials` folder of portal application, sample keys are passed by default

This should probably be vaulted, but as they are by default, you will be able to get an instance spun up and working by default.

See the [CommandCenter Repo - Passing Production Keys](https://gitlab.com/compositionalenterprises/commandcenter/-/blob/master/docs/INSTALL.md#pass-production-keys-to-the-container-in-volumes-when-running-in-production) for more information on updating rails credentials files. Please also note with the default keys setup we run, the keys can be updated from a commandline interface within the container using `EDITOR=vim RAILS_ENV=production rails credentials:edit -e production`

### Dolibar

The modules that are loaded up are passed via the following variable:

- `ourcompose_dolibarr_modules`

This can be any one of the modules available to dolibarr, found [here](https://doxygen.dolibarr.org/develop/modules.html). We MUST have `modApi` enabled to set up the admin users from the CLI, however.

# New Services

Whenever new services are added, we should make sure they are doing the same things that the other ones are.
It's typically easiest to start off finding the service that's most similar to the new one.
The files for the NGINX configuration file and the task file can be copied, renamed, and edited.
Then the variables section can be copied to a new section and renamed, and the service added to the list of services in the `defaults/main.yml` file.

## Setup Steps

New services should include the following setup steps:

- NGINX Configuration Template
- Database initialization check
- Database setup script
- Existing containter check
- `docker_compose` setup
- Bind Mountpoints
- Admin setup
- Default Login Account (Coming Soon)
- Script Execution (Coming Later)
- Unified Account Management (Coming Much Later)

Then after a working service is configured, the rest of the ecosystem needs updating:

- User Admin in [Project](https://gitlab.com/compositionalenterprises/ansible-project-ourcompose_management)
- Add new book into [Bookstack Docs](https://compositionalenterprises.ourcompose.com/bookstack/)
- Add entry into [Portal](https://gitlab.com/compositionalenterprises/portal)
- Add entry into [CommandCenter](https://gitlab.com/compositionalenterprises/commandcenter)
- Add entry into `common.py` in [Project](https://gitlab.com/compositionalenterprises/ansible-project-ourcompose_management)
- Update this README.md

## Requirements

- Open Source
- Able to run in a subdirectory
- Able to use MariaDB/MySQL as a backend or have a self-contained backend (other backends coming later)
- Upstream or otherwise maintained docker image (We maintain our own in special circumstances)

# Examples

```yaml
#
# This playbook sets up a SSL-encrypted server running nextcloud with default
# frontends and backends, and default passwords. FOR TESTING ONLY!!!
#
- name: Roles in Common
  hosts: all
  become: yes

  vars_files:
    - ../environment/group_vars/all/all.yml

  vars:
    docker__pip_packages:
      - "docker"
      - "python-apt"
    certbot_auto_renew_options: "--quiet --no-self-upgrade --pre-hook='docker stop proxy' --post-hook='docker start proxy'"
    certbot_admin_email: "{{ ourcompose_common_admin }}@{{ ourcompose_common_domain }}"
    certbot_create_if_missing: True
    certbot_install_from_source: True
    certbot_create_standalone_stop_services:
      - 'docker'
    certbot_certs:
      - domains:
        - "{{ ourcompose_common_domain }}"

  pre_tasks:
    - name: Update all packages on the system
      apt:
        name: '*'
        state: latest
        update_cache: True

  roles:
    - role: swapfile
      swapfile_size: '4G'
    - role: docker
    - role: certbot
    - role: compositionalenterprises.ourcompose.nextcloud
      ansible_python_interpreter: "/usr/bin/env python3-docker"
```

# License

MIT

# Author Information

Andrew Cziryak
- https://ourcompose.com
