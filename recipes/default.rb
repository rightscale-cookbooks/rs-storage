#
# Cookbook Name:: rs-storage
# Recipe:: default
#
# Copyright (C) 2014 RightScale, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

marker "recipe_start_rightscale" do
  template "rightscale_audit_entry.erb"
end

# Due to issue https://github.com/gregsymons/di-ruby-lvm-attrib/issues/22
# an update for LVM 2.0.2.115 was needed to work on RHEL/CentOS 7.1.
# Once pull request is merged, issue closed, and rubygems updated,
# this section and the source file can be removed.
cookbook_file '/tmp/di-ruby-lvm-attrib-0.0.17.gem' do
  source "di-ruby-lvm-attrib-0.0.17.gem"
  action :nothing
end.run_action(:create)
chef_gem 'di-ruby-lvm-attrib' do
  source '/tmp/di-ruby-lvm-attrib-0.0.17.gem'
  action :install
end

include_recipe 'rightscale_volume::default'
include_recipe 'rightscale_backup::default'
