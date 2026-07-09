# AGENTS.md

This file provides guidance to AI agents when working with code in this repository.

## What this module does

`simp-swap` is a small SIMP Puppet module that tunes Linux **swap behavior** by
managing the `vm.swappiness` kernel parameter. It operates in one of two
mutually exclusive modes, selected by the `$dynamic_script` parameter
(`manifests/init.pp:63-102`):

- **Static mode (default).** It declares a single `sysctl { 'vm.swappiness' }`
  resource set to `$swappiness` (default `60`) and ensures the dynamic cron job
  is `absent` (`init.pp:95-102`). This is the recommended mode for most systems
  — an absolute value that never changes.
- **Dynamic mode (`$dynamic_script = true`).** It installs a standalone Ruby
  script at `/usr/local/sbin/dynamic_swappiness.rb` (rendered from
  `templates/dynamic_swappiness.erb`) and a root `cron` job that runs it every
  `$cron_step` minutes (default every 5). The script adjusts `vm.swappiness`
  based on how much RAM is currently free, raising swappiness as free memory
  drops (`init.pp:76-94`).

The class docstring calls out the key trade-off: **an absolute value always
overrides the cron job**, and the cron approach "doesn't really make a lot of
sense unless it is run reasonably often" (`init.pp:3-7`).

### Business logic

The module is a single public class; there are no defined types and no other
classes.

- **`swap` (`manifests/init.pp:63-103`)** — Public entry class (not
  `assert_private()`'d; consumers `include 'swap'`). All parameters are
  hard-coded defaults in the class signature — **there is no
  `simplib::lookup` / `simp_options` seam** (`init.pp:63-74`):
  - `$swappiness` (`Integer[0,100]`, default `60`) — the static swappiness
    value; used **only** in static mode. Set "as-is" with no validation beyond
    the type bound (`init.pp:64`).
  - `$dynamic_script` (`Boolean`, default `false`) — the mode switch.
  - `$cron_step` (`Integer[0,59]`, default `5`) — crontab minute step for the
    dynamic job (`minute => "*/${cron_step}"`). Dynamic mode only
    (`init.pp:66,90`).
  - `$maximum` / `$median` / `$minimum` (`Integer[0,100]`, defaults `30` / `10`
    / `5`) — free-memory percentage thresholds passed into the ERB script.
    Dynamic mode only (`init.pp:67-69`).
  - `$min_swappiness` / `$low_swappiness` / `$high_swappiness` /
    `$max_swappiness` (`Integer[0,100]`, defaults `5` / `20` / `40` / `80`) —
    the swappiness values the dynamic script chooses between. Dynamic mode only
    (`init.pp:70-73`).

  Control flow and resources:
  - **Dynamic branch** (`init.pp:76-94`): declares
    `file { '/usr/local/sbin/dynamic_swappiness.rb' }` (`0755`, root:root,
    `content => template('swap/dynamic_swappiness.erb')`) and
    `cron { 'dynamic_swappiness' }` (`user => 'root'`,
    `minute => "*/${cron_step}"`, `command =>
    '/usr/local/sbin/dynamic_swappiness.rb'`) which `require`s the file.
  - **Static branch** (`init.pp:95-102`): declares
    `sysctl { 'vm.swappiness': value => $swappiness }` (the
    `augeasproviders_sysctl` provider) and `cron { 'dynamic_swappiness':
    ensure => absent }` to tear down any previously installed cron job.

- **`templates/dynamic_swappiness.erb`** — a self-contained Ruby CLI script
  (shebang `/opt/puppetlabs/puppet/bin/ruby`), not a config-file template. Only
  the threshold/level parameters are interpolated in as script defaults
  (`@maximum`, `@median`, `@minimum`, `@min_swappiness`, `@low_swappiness`,
  `@high_swappiness`, `@max_swappiness` — erb lines 7-24); everything else is
  static Ruby. At runtime it:
  - reads `MemFree` / `MemTotal` from `/proc/meminfo` and computes percent free
    (erb:67-88);
  - clamps/normalizes the thresholds and levels so they stay ordered and in
    range (erb:122-149);
  - selects a swappiness level by which free-memory band the host is in and
    applies it by shelling out to `/sbin/sysctl -w vm.swappiness=<n>`
    (erb:91-100,151-160) — **more free memory → lower swappiness; less free
    memory → higher swappiness**;
  - supports `--verbose`, `--syslog`, and command-line overrides for every
    threshold/level (erb:26-63), though the cron job invokes it with no
    arguments.

### Gotchas / non-obvious details

- **The two modes are mutually exclusive, and switching between them cleans
  up.** Static mode explicitly sets `cron { 'dynamic_swappiness': ensure =>
  absent }` (`init.pp:99-101`), so flipping `$dynamic_script` false removes the
  cron job. There is no matching cleanup of the `sysctl` entry when switching
  the other way — in dynamic mode the `sysctl { 'vm.swappiness' }` resource is
  simply not declared, so an existing augeas-managed entry is left in place.
- **All parameters except `$swappiness` and `$dynamic_script` are inert in
  static mode.** The docstring repeats "Has no effect if `$dynamic_script` is
  `false`" for every threshold/level parameter (`init.pp:22-61`).
- **The dynamic script bypasses Puppet's sysctl provider at runtime.** In
  dynamic mode swappiness is set by the cron job calling `sysctl -w` directly
  (erb:99), *not* by the `augeasproviders_sysctl` provider — so the value is
  not persisted to `/etc/sysctl.conf`/`sysctl.d` and does not survive a reboot
  on its own; the cron job re-applies it. Static mode, by contrast, uses the
  `sysctl` type which does persist.
- **The cron job runs the script with no flags.** The CLI override flags
  (`--max-swap`, etc.) exist for manual/debug use only; the managed schedule
  always uses the ERB-baked defaults (`init.pp:91`).
- **A comment in the manifest explains why cron, not Puppet, drives the dynamic
  path:** in extreme low-memory situations the Puppet agent itself may not be
  able to run until swappiness is adjusted, so the fast cron cadence is
  deliberate (`init.pp:86-87`).
- **`$swappiness` is applied verbatim.** The docstring warns the value is used
  "as-is" (`init.pp:10-11`); the only guard is the `Integer[0,100]` type.

## Dependencies

Module dependencies (from `metadata.json`):

- `puppet/augeasproviders_sysctl` `>= 2.4.0 < 7.0.0` (provides the `sysctl`
  type/provider used by the static branch) (`metadata.json:16-19`).
- `simp/simplib` `>= 4.9.0 < 6.0.0` (`metadata.json:20-23`).
- `puppetlabs/stdlib` `>= 8.0.0 < 10.0.0` (`metadata.json:24-27`).

There are **no optional dependencies** (no `simp.optional_dependencies` block)
and the manifest makes **no `simplib::assert_optional_dependency` calls**.

Runtime requirement (from `metadata.json` `requirements`,
`metadata.json:70-75`): **`openvox >= 8.0.0 < 9.0.0`.** This module has been
migrated from Puppet to OpenVox — OpenVox 8 is the new baseline. As a
transitional shim during the ecosystem migration, the `Gemfile` still installs
**both** the `openvox` and `puppet` gems from a single version range
(`['openvox', 'puppet'].each do |gem_name| ...`, `Gemfile:29-32`; default range
`['>= 8', '< 9']`, `Gemfile:23`); this shim goes away once the `puppet`
dependency is dropped from the other gems.

Supported OS matrix (from `metadata.json:29-69`): CentOS 9/10; RedHat 8/9/10;
OracleLinux 8/9/10; Rocky 8/9/10; AlmaLinux 8/9/10.

## Repository layout

- `manifests/init.pp` — the sole manifest; the `swap` class (all logic). There
  are **no defined types**.
- `templates/dynamic_swappiness.erb` — the Ruby swappiness-adjustment script
  rendered into `/usr/local/sbin/dynamic_swappiness.rb` in dynamic mode.
- `metadata.json` — dependencies, OS matrix, OpenVox requirement.
- `spec/classes/init_spec.rb` — rspec-puppet unit tests for the `swap` class.
- `spec/expected/dynamic_swappiness.rb`,
  `spec/expected/dynamic_swappiness_off_default.rb` — expected rendered-script
  fixtures the unit spec compares the ERB output against.
- `spec/acceptance/suites/default/00_default_spec.rb` — the single beaker
  acceptance suite; nodesets under `spec/acceptance/nodesets/` (15 nodesets).
- `spec/spec_helper.rb` — requires
  `puppetlabs_spec_helper/module_spec_helper` (`spec_helper.rb:11`).
- `REFERENCE.md` — generated Puppet Strings reference.
- No `data/` directory and no `hiera.yaml` — this module ships no module data;
  all defaults live in the class signature. No `types/`, `functions/`, or
  `lib/` — no custom data types, Puppet functions, or Ruby
  types/providers/facts. The `sysctl`/`cron` types and everything else come
  from the dependencies and Puppet core.
- **Acceptance runs in CI:** `.github/workflows/pr_tests.yml` defines six
  standard jobs — `puppet-syntax`, `puppet-style`, `ruby-style`, `file-checks`,
  `releng-checks`, `spec-tests` — **plus an active `acceptance` job**
  (`pr_tests.yml:116-146`). The acceptance job runs a matrix of `almalinux9`
  and `almalinux10` (`pr_tests.yml:122-123`), provisions libvirt/Vagrant, and
  runs `bundle exec rake beaker:suites[default,<node>]` under
  `BEAKER_HYPERVISOR=vagrant_libvirt` (`pr_tests.yml:141-146`). Unit specs run
  against Puppet 8.x on Ruby 3.2 (`pr_tests.yml:97-101`).

## Common commands

```sh
# Install dependencies
bundle install

# Run all unit tests
bundle exec rake spec

# Run the single class spec
bundle exec rspec spec/classes/init_spec.rb

# Puppet lint
bundle exec rake lint

# Ruby lint
bundle exec rake rubocop

# Regenerate REFERENCE.md from puppet-strings docstrings
puppet strings generate --format markdown --out REFERENCE.md

# Run the default beaker acceptance suite
bundle exec rake beaker:suites[default]
```

Relevant gem pins (from `Gemfile`): `puppetlabs_spec_helper ~> 8.0.0`
(`Gemfile:33`), `simp-rake-helpers ~> 5.24.0` (`Gemfile:39`),
`simp-beaker-helpers ~> 2.0.0` (`Gemfile:56`). Rubocop is pinned to
`~> 1.88.0` (`Gemfile:16`). The default OpenVox/Puppet test range is
`['>= 8', '< 9']` (`Gemfile:23`), and both gems are installed during the
migration shim (`Gemfile:29-32`).

## Conventions

- Preserve the `@summary` / `@param` puppet-strings docstrings on the class —
  they drive `REFERENCE.md`. Regenerate `REFERENCE.md` after changing docs or
  parameters.
- Keep the two modes mutually exclusive and self-cleaning: the static branch
  must continue to `ensure => absent` the dynamic cron job so switching modes
  doesn't leave a stray job behind (`init.pp:99-101`).
- When editing `templates/dynamic_swappiness.erb`, update the matching
  fixtures in `spec/expected/` — the unit spec asserts the rendered script
  byte-for-byte.
- Keep parameter defaults in the class signature (this module has no `data/`
  or Hiera layer); don't introduce a `simplib::lookup` seam without a reason.
- `Gemfile`, `spec/spec_helper.rb`, and `.github/workflows/pr_tests.yml` carry
  a **puppetsync** notice — they are baseline-managed and the next sync
  overwrites local edits. Push changes to those files upstream to the baseline,
  not here. `.pdkignore` carries the same notice.
- Match the existing 2-space Puppet indentation and aligned-arrow parameter
  style used in `manifests/init.pp`.
