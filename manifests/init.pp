# @summary
#   module to configure tcpdump to collect pacap files for DNS traffic
# @param tools
#   where to install the pcap tools
# @param dstdir
#   where to store pcap files
# @param collect_ans
#   collect DNS Answers
# @param collect_qry
#   collect DNS Queries
# @param filter
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
  Stdlib::Absolutepath       $tools        = '/usr/local/bin',
  Stdlib::Absolutepath       $dstdir       = '/opt/pcap',
  Boolean                    $collect_ans  = false,
  Boolean                    $collect_qry  = true,
  Optional[String]           $filter       = undef,
  Array[Stdlib::Ip::Address] $ip_addresses = [],
  Integer[1,3600]            $interval     = 300,
  Stdlib::Absolutepath       $xz_wrapper   = '/usr/local/bin/xz_wrapper.sh',
  Boolean                    $enable       = true,
  Optional[Array[String]]    $interfaces   = undef,
) {

  $ensure = $enable ? {
    true    => 'present',
    default => 'absent',
  }
  $_interfaces = $interfaces ? {
    undef   => split($::interfaces, ','),
    default => $interfaces,
  }
  $_directories = [ $dstdir, ]
  File { mode => '0755' }
  ensure_resource(
    'file', $_directories, { 'ensure' => 'directory', mode => '0755' }
  )
  file { "${tools}/pcapture":
    ensure  => $ensure,
    content => template('pcapture/bin/pcapture.erb');
  }
  file { "${tools}/pcaprotate":
    ensure  => $ensure,
    content => template('pcapture/bin/pcaprotate.erb');
  }
  file { $xz_wrapper:
    ensure => $ensure,
    source => 'puppet:///modules/pcapture/bin/xz_wrapper.sh';
  }
  cron { 'pcapcapture':
    ensure  => $ensure,
    command => "${tools}/pcapture",
    user    => 'root',
    require => File["${tools}/pcapture"];
  }
  cron { 'pcaprotate':
    ensure  => $ensure,
    command => "/usr/bin/flock -n /var/lock/pcaprotate.lock ${tools}/pcaprotate",
    user    => 'root',
    require => File["${tools}/pcaprotate"];
  }
}
