# == Class:pcapture::filter
# 
class pcapture::filter (
  Stdlib::Absolutepath  $pcapfilter = '/usr/local/bin/pcapture-filter.sh',
  Boolean               $enable     = true,
  Stdlib::Absolutepath  $srcdir     = '/opt/pcap',
  Stdlib::Absolutepath  $dstdir     = '/opt/pcap-filtered',
  String                $regexf     = '*.ignored.pcap.xz',
  String                $filter     = '(dst host 199.7.83.42 or dst host 2001:500:9f::42)'
) {
  $ensure = $enable ? {
    true    => 'present',
    default => 'absent',
  }
  file { $dstdir:
    ensure => directory,
  }
  file { $pcapfilter:
    ensure => $ensure,
    source => 'puppet:///modules/pcapture/bin/pcapture-filter.sh',
    mode   => '0755';
  }
  cron { 'pcapfilter':
    ensure  => $ensure,
    command => "/usr/bin/flock -n /var/lock/pcapfilter.lock ${pcapfilter} -s ${srcdir} -d ${dstdir} -r ${regexf} -f ${filter}",
    user    => 'root',
    require => File[$pcapfilter];
  }
}
