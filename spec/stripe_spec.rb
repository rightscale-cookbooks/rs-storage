require_relative 'spec_helper'

describe 'rs-storage::stripe' do
  let(:chef_runner) do
    ChefSpec::SoloRunner.new do |node|
      node.set['rightscale_volume']['data_storage_1']['device'] = '/dev/sda'
      node.set['rightscale_volume']['data_storage_2']['device'] = '/dev/sdb'
      node.set['rightscale_backup']['data_storage']['devices'] = ['/dev/sda', '/dev/sdb']
    end
  end
  let(:nickname) { chef_run.node['rs-storage']['device']['nickname'] }
  let(:nickname_1) { "#{nickname}_1" }
  let(:nickname_2) { "#{nickname}_2" }
  let(:volume_group) { "#{nickname.tr('_', '-')}-vg" }
  let(:logical_volume) { "#{nickname.tr('_', '-')}-lv" }
  let(:detach_timeout) do
    chef_runner.converge(described_recipe).node['rs-storage']['device']['detach_timeout'].to_i
  end

  context 'rs-storage/restore/lineage is not set' do
    let(:chef_run) { chef_runner.converge(described_recipe) }

    it 'creates two new volumes and attaches them' do
      expect(chef_run).to create_rightscale_volume(nickname_1).with(
        size: 5,
        options: {}
      )
      expect(chef_run).to create_rightscale_volume(nickname_2).with(
        size: 5,
        options: {}
      )
      expect(chef_run).to attach_rightscale_volume(nickname_1)
      expect(chef_run).to attach_rightscale_volume(nickname_2)
    end

    it 'creates an LVM volume' do
      expect(chef_run).to create_lvm_volume_group(volume_group).with(physical_volumes: ['/dev/sda', '/dev/sdb'])
      expect(chef_run).to create_lvm_logical_volume(logical_volume).with(
        group: volume_group,
        size: '100%VG',
        filesystem: 'ext4',
        mount_point: '/mnt/storage',
        stripes: 2,
        stripe_size: 512
      )
    end

    context 'iops is set to 100' do
      let(:chef_run) do
        chef_runner.node.set['rs-storage']['device']['iops'] = 100
        chef_runner.converge(described_recipe)
      end

      it 'creates two new volumes with iops set to 100 and attaches them' do
        expect(chef_run).to create_rightscale_volume(nickname_1).with(
          size: 5,
          options: { iops: 100 }
        )
        expect(chef_run).to create_rightscale_volume(nickname_2).with(
          size: 5,
          options: { iops: 100 }
        )
        expect(chef_run).to attach_rightscale_volume(nickname_1)
        expect(chef_run).to attach_rightscale_volume(nickname_2)
      end
    end
  end

  context 'rs-storage/restore/lineage is set' do
    let(:chef_runner_restore) do
      chef_runner.node.set['rs-storage']['restore']['lineage'] = 'testing'
      chef_runner
    end
    let(:chef_run) do
      chef_runner_restore.converge(described_recipe)
    end

    it 'creates volumes from the backup' do
      expect(chef_run).to restore_rightscale_backup(nickname).with(
        lineage: 'testing',
        timestamp: nil,
        size: 5,
        options: {}
      )
    end

    it 'creates an LVM volume' do
      expect(chef_run).to create_lvm_volume_group(volume_group).with(physical_volumes: ['/dev/sda', '/dev/sdb'])
      expect(chef_run).to create_lvm_logical_volume(logical_volume).with(
        group: volume_group,
        size: '100%VG',
        filesystem: 'ext4',
        mount_point: '/mnt/storage',
        stripes: 2,
        stripe_size: 512
      )
    end

    context 'iops is set to 100' do
      let(:chef_run) do
        chef_runner_restore.node.set['rs-storage']['device']['iops'] = 100
        chef_runner_restore.converge(described_recipe)
      end

      it 'creates volumes from the backup with iops' do
        expect(chef_run).to restore_rightscale_backup(nickname).with(
          lineage: 'testing',
          timestamp: nil,
          size: 5,
          options: { iops: 100 }
        )
      end
    end

    context 'timestamp is set' do
      let(:timestamp) { Time.now.to_i }
      let(:chef_run) do
        chef_runner_restore.node.set['rs-storage']['restore']['timestamp'] = timestamp
        chef_runner_restore.converge(described_recipe)
      end

      it 'creates volumes from the backup with the timestamp' do
        expect(chef_run).to restore_rightscale_backup(nickname).with(
          lineage: 'testing',
          timestamp: timestamp,
          size: 5,
          options: {}
        )
      end
    end
  end
end
