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

marker 'recipe_start_rightscale' do
  template 'rightscale_audit_entry.erb'
end

# RHEL on some clouds take some time to add RHEL repos.
# Check and wait a few seconds if RHEL repos are not yet installed.
if node['platform'] == 'redhat'
  if !node.attribute?('cloud') || !node['cloud'].attribute?('provider') || !node.attribute?(node['cloud']['provider'])
    log 'Not running on a known cloud - skipping check for RHEL repo'
  else
    # Depending on cloud, add string returned by 'yum --cacheonly repolist' to determine if RHEL repo has been added.
    repo_id_partial = case node['cloud']['provider']
                      when 'rackspace'
                        'rhel-x86_64-server'
    end

    unless repo_id_partial.nil?
      Timeout.timeout(300) do
        loop do
          check_rhel_repo = Mixlib::ShellOut.new("yum --cacheonly repolist | grep #{repo_id_partial}").run_command
          check_rhel_repo.exitstatus == 0 ? break : sleep(1)
        end
      end
    end

  end
end

include_recipe 'rightscale_volume::default'
include_recipe 'rightscale_backup::default'
