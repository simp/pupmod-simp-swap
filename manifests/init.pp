# Set the swappiness of the system either by a cron job or as an absolute value.
#
# The cron job is run every 5 minutes by default. Using the cron job doesn't
# really make a lot of sense unless it is run reasonably often. Therefore, only
# minute steps are supported per crontab(5).
#
# An absolute value setting will always override the cron job.
#
# @params dynamic_script
#   If true, place the dynamic_swappiness script on the system and enable it. Set
#   this to false if you'd like to manage the swappiness of the system manually
#   with $swappiness.
# @params swappiness
#   If dynamic_script is set to false, set the system to run at this swappiness
#   and do not adjust. Take care, whatever value you place in here used as-is!
#
# @params cron_step
#   The crontab(5) minute step value for the swappiness set.
# @params maximum
#   The percentage of memory free on the system above which we will set
#   vm.swappiness to $min_swappiness
# @params median
#   If the percentage of free memory on the system is between this number and
#   $maximum, set vm.swappiness to $low_swappiness.
# @params minimum
#   If the percentage of free memory on the system is between this number and
#   $median, set vm.swappiness to $high_swappiness.  If below this number,
#   set to $max_swappiness.
# @params min_swappiness
#   The minimum swappiness to ever set on the system.
# @params low_swappiness
#   The next level of swappiness to jump to on the system.
# @params high_swappiness
#   The medium-high level of swappiness to set on the sysetm.
# @params max_swappiness
#   The absolute maximum to ever set the swappiness on the system.
#
class swap (
  Boolean        $dynamic_script  = true,
  Integer        $swappiness      = 0,
  Integer[0,59]  $cron_step       = 5,
  Integer[0,100] $maximum         = 30,
  Integer[0,100] $median          = 10,
  Integer[0,100] $minimum         = 5,
  Integer[0,100] $min_swappiness  = 5,
  Integer[0,100] $low_swappiness  = 20,
  Integer[0,100] $high_swappiness = 40,
  Integer[0,100] $max_swappiness  = 80
) {

  if $dynamic_script {
    # NOTE: This script is handy for keeping things alive in environments where
    #       memory availability can fluctuate quite low.  You should read it!
    file { '/usr/local/sbin/dynamic_swappiness.rb':
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      content => template('swap/dynamic_swappiness.erb')
    }
    # NOTE: One reason cron runs this is because in extreme cases, the Puppet
    #       agent won't be able to run until the swappiness is adjusted.
    cron { 'dynamic_swappiness':
      user    => 'root',
      minute  => "*/${cron_step}",
      command => '/usr/local/sbin/dynamic_swappiness.rb',
      require => File['/usr/local/sbin/dynamic_swappiness.rb']
    }
  }
  else {
    sysctl { 'vm.swappiness':
      value  => $swappiness
    }
    cron { 'dynamic_swappiness':
      ensure => absent
    }
  }

}
