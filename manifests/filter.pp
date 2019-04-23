# == Class:pcapture::filter
# 
class pcapture::filter (
  Stdlib::Absolutepath  $pcapfilter = '/usr/local/bin/pcapture-filter.sh',
  Boolean               $enable     = true,
) {
  $ensure = $enable ? {
    true    => 'present',
    default => 'absent',
  }

  file {
    $pcapfilter:
      ensure => $ensure,
	  source => 'puppet:///modules/pcapture/bin/pcapture-filter.sh',
	  mode   => '0755';
  }
  cron {
    'pcapfilter':
      ensure  => $ensure,
      command => "/usr/bin/flock -n /var/lock/pcapfilter.lock ${pcapfilter}",
      user    => 'root',
      require => File["${pcapfilter}"];
  
}
