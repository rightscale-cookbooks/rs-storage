rs-storage Cookbook CHANGELOG
=============================

This file is used to list changes made in each version of the rs-storage cookbook.

v2.0.1
------
- loosened lvm lock, so that it can keep up with lvm changes.
- updates filesystem cookbook to >= 0.11.1 to use the supermarket version and \
  fix the frozen? issue.

v2.0.0
------

- Add support for Chef 12
- Remove support for Chef 11

v1.2.1
------
- pin Gems and cookbooks using Gemfile.lock and Berksfile.lock


v1.2.0
------

- updated lvm cookbook to 1.6.1

v1.1.0
------

- Support for RL10

v1.0.7
------

- Issue https://github.com/gregsymons/di-ruby-lvm-attrib/issues/22 has been fixed so workaround can be removed.

v1.0.6
------

- On RHEL, depending on cloud, check and wait for RHEL repos to be installed.

v1.0.5
------

- Handle use of XFS when using rs-storage::volume.

v1.0.4
------

- Due to issue https://github.com/gregsymons/di-ruby-lvm-attrib/issues/22, updated gem added to cookbook
  to allow use with RHEL/CentOS 7.1.
- Updated lvm cookbook dependency version to 1.3.6.

v1.0.3
------

- Fix volume type input description since it is not just for vSphere.

v1.0.2
------

- Require the latest [rightscale_volume (v1.2.4)] and [rightscale_backup (v1.1.5)] cookbooks.

[rightscale_volume (v1.2.4)]: https://github.com/rightscale-cookbooks/rightscale_volume/releases/tag/v1.2.4
[rightscale_backup (v1.1.5)]: https://github.com/rightscale-cookbooks/rightscale_backup/releases/tag/v1.1.5

v1.0.1
------

- `rs-storage/device/controller_type` node attribute created and can be passed as an option
  to `rightscale_volume` resource.

v1.0.0
------

- Initial release
