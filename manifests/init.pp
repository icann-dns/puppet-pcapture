# @summary
#   module to configure tcpdump to collect pacap files for DNS traffic
# @param tools
#   where to install the pcap tools
# @param data
#   where to store pcap files
# @param collect_ans
#   collect DNS Answers
# @param collect_qry
#   collect DNS Queries
# @param tcpdump_param
#   additional paramaters for tcpdumps
# @param ip_addresses
#   list of IP adresses for tcpdump to filter on
# @param interval
#   interval to roll pocap files
# @param xz_wrapper
#   path to helper script used to compress files
# @param enable
#   Indicates if the module is enabled or not
# @param interfaces
#   This should be aliased to the network::interfaces object
#   e.g. in yaml set 
class pcapture (
  Stdlib::Absolutepath        $tools             = '/usr/local/bin',
  Stdlib::Absolutepath        $data              = '/opt/pcap',
  Boolean                     $collect_ans       = false,
  Boolean                     $collect_qry       = true,
  Optional[String]            $tcpdump_param     = undef,
  Array[Stdlib::Ip::Address]  $ip_addresses      = [],
  Integer[1,3600]             $interval          = 300,
  Stdlib::Absolutepath        $xz_wrapper        = '/usr/local/bin/xz_wrapper.sh',
  Boolean                     $enable            = true,
  Optional[Array[String]]     $interfaces        = undef,
  Boolean                     $enable_upload     = false,
  Optional[String]            $upload_dir        = undef,
  Optional[Tea::Host]         $upload_host       = undef,
  Optional[Tea::Puppetsource] $upload_key_source = undef,
  String                      $upload_user       = 'pcapture',
) {

  $ensure = $enable ? {
    true    => 'present',
    default => 'absent',
  }
  $_interfaces = $interfaces ? {
    undef   => split($::interfaces, ','),
    default => $interfaces,
  }
  $_directories = [ $data, ]
  File { mode => '0755' }
  ensure_resource(
    'file', $_directories, { 'ensure' => 'directory', mode => '0755' }
  )
  file {
    "${tools}/pcapture":
      ensure  => present,
      content => template('pcapture/bin/pcapture.erb');
    "${tools}/pcaprotate":
      ensure  => present,
      content => template('pcapture/bin/pcaprotate.erb');
    $xz_wrapper:
      ensure => present,
      source => 'puppet:///modules/pcapture/bin/xz_wrapper.sh';
  }
  cron {
    'pcapcapture':
      ensure  => $ensure,
      command => "${tools}/pcapture",
      user    => 'root',
      require => File["${tools}/pcapture"];
    'pcaprotate':
      ensure  => $ensure,
      command => "/usr/bin/flock -n /var/lock/pcaprotate.lock ${tools}/pcaprotate",
      user    => 'root',
      require => File["${tools}/pcaprotate"];
  }
  if $enable_upload {
    if !$upload_dir or !$upload_key_source or !$upload_user or !$upload_host {
      fail('if using enable_upload then you must specify all $upload_dir, $upload_key_source, $upload_user and $upload_host')
    }
    include ::file_upload
    $destination_path = defined('$::node_short_name') ? {
      true    => "${upload_dir}/${service}/${::node_short_name}/incoming",
      default => "${upload_dir}/${service}/${::hostname}/incoming",
    }
    file_upload::upload { 'pcapture':
      ensure           => $ensure,
      data             => $output_dir,
      patterns         => ["${output_file_name}*${output_format}"],
      destination_path => $destination_path,
      destination_host => $upload_host,
      ssh_key_source   => $upload_key_source,
      ssh_user         => $upload_user,
    }
  }
}
