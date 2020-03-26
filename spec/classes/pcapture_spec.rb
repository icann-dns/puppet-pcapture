require 'spec_helper'

describe 'pcapture' do
  let(:node) { 'pcapture.example.com' }
  let(:params) do
    {
      # tools: "/usr/local/bin",
      # data: "/opt/pcap",
      # collect_ans: false,
      # collect_qry: true,
      # ip_addresses: [],
      # interval: "300",
      # xz_wrapper: "/usr/local/bin/xz_wrapper.sh",
      # enable: true,

      interfaces: { 'eth0' => { 'addr4' => '192.0.2.1' } },
    }
  end

  # Puppet::Util::Log.level = :debug
  # Puppet::Util::Log.newdestination(:console)
  # This will need to get moved
  # it { pp catalogue.resources }
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }

      describe 'check default config' do
        it { is_expected.to compile.with_all_deps }
        it do
          is_expected.to contain_file('/usr/local/bin/pcapture').with_ensure(
            'present',
          ).with_content(
            %r{INTERFACES="eth0"},
          ).with_content(
            %r{DIR=/opt/pcap},
          ).with_content(
            %r{INTERVAL=300},
          ).with_content(
            %r{/usr/local/bin/pcapture -nt},
          ).with_content(
            %r{'dst net \(},
          )
        end
        it do
          is_expected.to contain_file('/usr/local/bin/pcaprotate').with_ensure(
            'present',
          ).with_content(
            %r{DIR=/opt/pcap},
          )
        end
        it do
          is_expected.to contain_file('/usr/local/bin/xz_wrapper.sh').with(
            ensure: 'present',
            source: 'puppet:///modules/pcapture/bin/xz_wrapper.sh',
          )
        end
        it do
          is_expected.to contain_cron('pcapcapture').with(
            ensure: 'present',
            command: '/usr/local/bin/pcapture',
            user: 'root',
            require: 'File[/usr/local/bin/pcapture]',
          )
        end
        it do
          is_expected.to contain_cron('pcaprotate').with(
            ensure: 'present',
            command: '/usr/bin/flock -n /var/lock/pcaprotate.lock /usr/local/bin/pcaprotate',
            user: 'root',
            require: 'File[/usr/local/bin/pcaprotate]',
          )
        end
      end
      describe 'Change Defaults' do
        context 'tools' do
          before(:each) { params.merge!(tools: '/foo/bar') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file('/foo/bar/pcapture').with_ensure(
              'present',
            )
          end
          it do
            is_expected.to contain_file('/foo/bar/pcaprotate').with_ensure(
              'present',
            )
          end
          it do
            is_expected.to contain_cron('pcapcapture').with(
              ensure: 'present',
              command: '/foo/bar/pcapture',
              user: 'root',
              require: 'File[/foo/bar/pcapture]',
            )
          end
          it do
            is_expected.to contain_cron('pcaprotate').with(
              ensure: 'present',
              command: '/usr/bin/flock -n /var/lock/pcaprotate.lock /foo/bar/pcaprotate',
              user: 'root',
              require: 'File[/foo/bar/pcaprotate]',
            )
          end
          it do
            is_expected.to contain_file('/foo/bar/pcapture').with_ensure(
              'present',
            ).with_content(
              %r{/foo/bar/pcapture -nt},
            )
          end
        end
        context 'data' do
          before(:each) { params.merge!(data: '/foo/bar') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file('/usr/local/bin/pcapture').with_ensure(
              'present',
            ).with_content(
              %r{DIR=/foo/bar},
            )
          end
          it do
            is_expected.to contain_file('/usr/local/bin/pcaprotate').with_ensure(
              'present',
            ).with_content(
              %r{DIR=/foo/bar},
            )
          end
        end
        context 'collect_ans' do
          before(:each) { params.merge!(collect_ans: true, collect_qry: false) }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file('/usr/local/bin/pcapture').with_ensure(
              'present',
            ).with_content(
              %r{INTERFACES="eth0"},
              %r{'src net \(},
            )
          end
        end
        context 'collect_ans and qry' do
          before(:each) { params.merge!(collect_ans: true, collect_qry: true) }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file('/usr/local/bin/pcapture').with_ensure(
              'present',
            ).with_content(
              %r{INTERFACES="eth0"},
              %r{' net \(},
            )
          end
        end
        context 'interval' do
          before(:each) { params.merge!(interval: 42) }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file('/usr/local/bin/pcapture').with_ensure(
              'present',
            ).with_content(
              %r{INTERVAL=42},
            )
          end
        end
        context 'xz_wrapper' do
          before(:each) { params.merge!(xz_wrapper: '/foo/bar') }
          it { is_expected.to compile }
          it do
            is_expected.to contain_file('/foo/bar').with(
              ensure: 'present',
              source: 'puppet:///modules/pcapture/bin/xz_wrapper.sh',
            )
          end
        end
        context 'enable' do
          before(:each) { params.merge!(enable: false) }
          it { is_expected.to compile }
          it { is_expected.to contain_cron('pcapcapture').with_ensure('absent') }
          it { is_expected.to contain_cron('pcaprotate').with_ensure('absent') }
        end
        context 'interfaces' do
          before(:each) do
            params.merge!(interfaces: { 'foobar' => { 'foo' => 'bar' } })
          end
          it { is_expected.to compile }
          it do
            is_expected.to contain_file('/usr/local/bin/pcapture').with_ensure(
              'present',
            ).with_content(
              %r{INTERFACES="foobar"},
            )
          end
        end
      end
      describe 'check bad type' do
        context 'tools' do
          before(:each) { params.merge!(tools: true) }
          it { is_expected.to raise_error(Puppet::Error) }
        end
        context 'data' do
          before(:each) { params.merge!(data: true) }
          it { is_expected.to raise_error(Puppet::Error) }
        end
        context 'collect_ans' do
          before(:each) { params.merge!(collect_ans: 'foobar') }
          it { is_expected.to raise_error(Puppet::Error) }
        end
        context 'collect_qry' do
          before(:each) { params.merge!(collect_qry: 'foobar') }
          it { is_expected.to raise_error(Puppet::Error) }
        end
        context 'ip_addresses' do
          before(:each) { params.merge!(ip_addresses: true) }
          it { is_expected.to raise_error(Puppet::Error) }
        end
        context 'interval' do
          before(:each) { params.merge!(interval: true) }
          it { is_expected.to raise_error(Puppet::Error) }
        end
        context 'xz_wrapper' do
          before(:each) { params.merge!(xz_wrapper: true) }
          it { is_expected.to raise_error(Puppet::Error) }
        end
        context 'enable' do
          before(:each) { params.merge!(enable: 'foobar') }
          it { is_expected.to raise_error(Puppet::Error) }
        end
        context 'interfaces' do
          before(:each) { params.merge!(interfaces: true) }
          it { is_expected.to raise_error(Puppet::Error) }
        end
      end
    end
  end
end
