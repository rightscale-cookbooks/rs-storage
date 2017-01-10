require_relative 'spec_helper'

describe 'rs-storage::decommission' do
  context 'rs-storage/device/destroy_on_decommission is set to false' do
    let(:chef_run) do
      ChefSpec::SoloRunner.new.converge(described_recipe)
    end

    it 'logs that it is skipping destruction' do
      expect(chef_run).to write_log("rs-storage/device/destroy_on_decommission is set to 'false' skipping...")
    end
  end

  context 'rs-storage/device/destroy_on_decommission is set to true' do
    let(:chef_runner) do
      ChefSpec::SoloRunner.new do |node|
        node.set['rightscale']['decom_reason'] = 'terminate'
        node.set['rs-storage']['device']['destroy_on_decommission'] = true
      end
    end
    let(:nickname) { chef_runner.converge(described_recipe).node['rs-storage']['device']['nickname'] }

    context 'RightScale run state is terminate' do
      context 'LVM is not used' do
        before do
          mount = double
          allow(Mixlib::ShellOut).to receive(:shell_out).with('mount').and_return(mount)
          allow(mount).to receive(:run_command)
          allow(mount).to receive(:error!)
          allow(mount).to receive(:live_stream=)
          allow(mount).to receive(:stdout).and_return('/dev/sda on /mnt/storage type ext4 (auto)')
        end

        let(:chef_run) do
          chef_runner.node.set['rightscale_volume'][nickname]['device'] = '/dev/sda'
          chef_runner.converge(described_recipe)
        end

        it 'unmounts and disables the volume on the instance' do
          expect(chef_run).to write_log('Unmounting /mnt/storage')
          expect(chef_run).to umount_mount('/mnt/storage').with(
            device: '/dev/sda'
          )
          expect(chef_run).to disable_mount('/mnt/storage')
        end

        it 'detaches the volume from the instance' do
          expect(chef_run).to write_log('LVM was not used on the device, simply detaching the deleting the device.')
          expect(chef_run).to detach_rightscale_volume(nickname)
        end

        it 'deletes the volume from the cloud' do
          expect(chef_run).to delete_rightscale_volume(nickname)
        end
      end

      context 'LVM is used' do
        before do
          output = '/dev/mapper/vol-group--logical-volume-1 on /mnt/storage type ext4 (auto)'
          mount = double(run_command: nil, error!: nil, stdout: output, stderr: double(empty?: true), exitstatus: 0, live_stream: nil, 'live_stream=' => nil, status: 0)
          allow(Mixlib::ShellOut).to receive(:new).and_return(mount)

          lvdisplay = double(run_command: nil, error!: nil, stdout: output, stderr: double(empty?: true), exitstatus: 0, live_stream: nil, 'live_stream=' => nil, status: 0)
          allow(Mixlib::ShellOut).to receive(:new).and_return(lvdisplay)
        end

        let(:chef_run) do
          chef_runner.node.set['rs-storage']['device']['count'] = 2
          chef_runner.converge(described_recipe)
        end
        let(:logical_volume_device) do
          "/dev/mapper/#{nickname.gsub('_', '--')}--vg-#{nickname.gsub('_', '--')}--lv"
        end

        it 'unmounts and disables the volume on the instance' do
          expect(chef_run).to umount_mount('/mnt/storage').with(
            device: logical_volume_device
          )
          expect(chef_run).to disable_mount('/mnt/storage')
        end

        it 'cleans up the LVM' do
          expect(chef_run).to write_log('LVM is used on the device(s). Cleaning up the LVM.')
          expect(chef_run).to run_ruby_block('clean up LVM')
        end

        it 'detaches the volumes from the instance' do
          expect(chef_run).to detach_rightscale_volume("#{nickname}_1")
          expect(chef_run).to detach_rightscale_volume("#{nickname}_2")
        end

        it 'deletes the volumes from the cloud' do
          expect(chef_run).to delete_rightscale_volume("#{nickname}_1")
          expect(chef_run).to delete_rightscale_volume("#{nickname}_2")
        end
      end
    end

    %w(reboot stop).each do |state|
      context "RightScale run state is #{state}" do
        let(:chef_run) do
          chef_runner.node.set['rightscale']['decom_reason'] = state
          chef_runner.converge(described_recipe)
        end

        it 'logs that it is skipping destruction' do
          expect(chef_run).to write_log('Skipping deletion of volumes as the instance is either rebooting or entering the stop state...')
        end
      end
    end
  end
end
