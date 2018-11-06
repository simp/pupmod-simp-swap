[![License](https://img.shields.io/:license-apache-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0.html)
[![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/73/badge)](https://bestpractices.coreinfrastructure.org/projects/73)
[![Puppet Forge](https://img.shields.io/puppetforge/v/simp/swap.svg)](https://forge.puppetlabs.com/simp/swap)
[![Puppet Forge Downloads](https://img.shields.io/puppetforge/dt/simp/swap.svg)](https://forge.puppetlabs.com/simp/swap)
[![Build Status](https://travis-ci.org/simp/pupmod-simp-swap.svg)](https://travis-ci.org/simp/pupmod-simp-swap)

#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with swap](#setup)
    * [What swap affects](#what-swap-affects)
    * [Beginning with swap](#beginning-with-swap)
4. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)
    * [Acceptance Tests - Beaker env variables](#acceptance-tests)


## Description

This module manages the swappiness of a system, either directly or with a dynamic script.


### This is a SIMP module

This module is a component of the [System Integrity Management Platform](https://simp-project.com),
a compliance-management framework built on Puppet.

If you find any issues, they may be submitted to our [bug tracker](https://simp-project.atlassian.net/).

**FIXME:** Ensure the *This is a SIMP module* section is correct and complete, then remove this message!

This module is optimally designed for use within a larger SIMP ecosystem, but it can be used independently:

 * When included within the SIMP ecosystem, security compliance settings will be managed from the Puppet server.
 * If used independently, all SIMP-managed security subsystems are disabled by default and must be explicitly opted into by administrators.  Please review the `$client_nets`, `$enable_*` and `$use_*` parameters in `manifests/init.pp` for details.


## Setup


### What swap affects

* The sysctl value `vm.swappiness`
* If enabled, a script and a cron job.


### Beginning with swap

The dynamic swappiness script is enabled by default and reccommended. To use this class, just include it on your system:

``` yaml
---
classes:
  - swap

```

There is an example output of the script (which is generated with a template from
puppet) in the `spec/expected` directory. 

## Reference

Please refer to the inline documentation within each source file, or to the module's generated YARD documentation for reference material.


## Limitations

SIMP Puppet modules are generally intended for use on Red Hat Enterprise Linux and compatible distributions, such as CentOS. Please see the [`metadata.json` file](./metadata.json) for the most up-to-date list of supported operating systems, Puppet versions, and module dependencies.


## Development

Please read our [Contribution Guide](http://simp-doc.readthedocs.io/en/stable/contributors_guide/index.html).


### Acceptance tests

This module includes [Beaker](https://github.com/puppetlabs/beaker) acceptance tests using the SIMP [Beaker Helpers](https://github.com/simp/rubygem-simp-beaker-helpers).  By default the tests use [Vagrant](https://www.vagrantup.com/) with [VirtualBox](https://www.virtualbox.org) as a back-end; Vagrant and VirtualBox must both be installed to run these tests without modification. To execute the tests run the following:

```shell
bundle install
bundle exec rake beaker:suites
```

Please refer to the [SIMP Beaker Helpers documentation](https://github.com/simp/rubygem-simp-beaker-helpers/blob/master/README.md) for more information.
