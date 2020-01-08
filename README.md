[![License](https://img.shields.io/:license-apache-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0.html)
[![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/73/badge)](https://bestpractices.coreinfrastructure.org/projects/73)
[![Puppet Forge](https://img.shields.io/puppetforge/v/simp/swap.svg)](https://forge.puppetlabs.com/simp/swap)
[![Puppet Forge Downloads](https://img.shields.io/puppetforge/dt/simp/swap.svg)](https://forge.puppetlabs.com/simp/swap)
[![Build Status](https://travis-ci.org/simp/pupmod-simp-swap.svg)](https://travis-ci.org/simp/pupmod-simp-swap)

#### Table of Contents

<!-- vim-markdown-toc GFM -->

* [Description](#description)
  * [This is a SIMP module](#this-is-a-simp-module)
* [Setup](#setup)
  * [What swap affects](#what-swap-affects)
  * [Beginning with swap](#beginning-with-swap)
* [Limitations](#limitations)
* [Development](#development)
  * [Acceptance tests](#acceptance-tests)

<!-- vim-markdown-toc -->

## Description

This module manages the swappiness of a system, either directly or with a dynamic script.

See [REFERENCE.md](./REFERENCE.md) for API details.


### This is a SIMP module

This module is a component of the [System Integrity Management Platform](https://simp-project.com),
a compliance-management framework built on Puppet.

If you find any issues, they may be submitted to our [bug tracker](https://simp-project.atlassian.net/).

## Setup


### What swap affects

* The sysctl value `vm.swappiness`.
* If enabled, the ability for the system to monitor the amount of free RAM and
  dynamically set the swappiness based on monitored conditions.
  * See [manifests/init.pp](./manifests/init.pp) for details.

### Beginning with swap

To use this class, just include it on your system:

```puppet
include 'swap'
```

## Limitations

SIMP Puppet modules are generally intended for use on Red Hat Enterprise Linux
and compatible distributions, such as CentOS. Please see the [`metadata.json` file](./metadata.json)
for the most up-to-date list of supported operating systems, Puppet versions,
and module dependencies.


## Development

Please read our [Contribution Guide](https://simp.readthedocs.io/en/stable/contributors_guide/index.html).


### Acceptance tests

This module includes [Beaker](https://github.com/puppetlabs/beaker) acceptance
tests using the SIMP [Beaker
Helpers](https://github.com/simp/rubygem-simp-beaker-helpers).  By default the
tests use [Vagrant](https://www.vagrantup.com/) with
[VirtualBox](https://www.virtualbox.org) as a back-end; Vagrant and VirtualBox
must both be installed to run these tests without modification. To execute the
tests run the following:

```shell
bundle install
bundle exec rake beaker:suites
```

Please refer to the [SIMP Beaker Helpers documentation](https://github.com/simp/rubygem-simp-beaker-helpers/blob/master/README.md) for more information.
