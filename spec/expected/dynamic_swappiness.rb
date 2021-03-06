#!/opt/puppetlabs/puppet/bin/ruby

require 'optparse'

# $maximum:   The percentage of memory free on the system above which we will
#             set vm.swappiness to @min_swappiness
@maximum = 30
# $median:    If the percentage of free memory on the system is between this
#             number and @maximum, set vm.swappiness to @low_swappiness.
@median = 10
# $minimum:   If the percentage of free memory on the system is between this
#             number and @median, set vm.swappiness to @high_swappiness.
#             If below this number, set to @max_swappiness.
@minimum = 5

# $min_swappiness:  The minimum swappiness to ever set on the system.
@min_swappiness = 5
# $low_swappiness:  The next level of swappiness to jump to on the system.
@low_swappiness = 20
# $high_swappiness: The medium-high level of swappiness to set on the sysetm.
@high_swappiness = 40
# $max_swappiness:  The absolute maximum to ever set the swappiness on the
#                   system.
@max_swappiness = 80

opts = OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]"
  opts.on("--mp", "--max-percent PERCENT", "Set the max swappiness percent.") do |mp|
    @maximum = mp.to_f
  end
  opts.on("--med", "--median-percent PERCENT", "Set the increase swappiness percent.") do |ip|
    @median = ip.to_f
  end
  opts.on("--mi", "--min-percent PERCENT", "Set the minimum swappiness percent.") do |mi|
    @minimum = mi.to_f
  end
  opts.on("--min-swap SWAPPINESS", "Set the lowest level to ever set the swappiness.") do |ms|
    @min_swappiness = ms.to_i
  end
  opts.on("--low-swap SWAPPINESS", "Set the next swappiness step.") do |ls|
    @low_swappiness = ls.to_i
  end
  opts.on("--high-swap SWAPPINESS", "Set the next swappiness step.") do |hs|
    @high_swappiness = hs.to_i
  end
  opts.on("--max-swap SWAPPINESS", "Set the highest level to ever set the swappiness.") do |maxs|
    @max_swappiness = maxs.to_i
  end
  opts.on("-v", "--verbose", "Increase verbosity.") do
    @verbose = true
  end
  opts.on("-s", "--syslog", "Write output to syslog.") do
    @syslog = true
    require 'syslog'
    Syslog.open('dynamic_swappiness')
  end
  opts.on("-h", "--help", "Show this message") do
    puts opts
    exit
  end
end

opts.parse!(ARGV)

# Get the memory on the system.
# Default type is free memory.
def getmem( type = "free" )
  meminfo = File.open("/proc/meminfo","r")
  memtype = "MemFree"

  if not type.eql?("free") then
    memtype = "MemTotal"
  end

  ret = nil
  meminfo.each do |line|
    if line =~ /^#{memtype}:\s*(\d+).*/ then
      ret = $1.to_f
      break
    end
  end
  meminfo.close
  return ret
end

# Return the percentage of the free memory on the system.
def percent_memfree
  return ((getmem/@memtotal) * 100).to_i
end

# Modify the swappiness of the system.
def mod_swappiness(swappiness)
  if @verbose then
    puts "Setting vm.swappiness = #{swappiness}"
  end
  if @syslog then
    Syslog.notice("Setting vm.swappiness = #{swappiness}")
  end

  `/sbin/sysctl -w vm.swappiness=#{swappiness}`
end

@memtotal = getmem("total")

memfree = percent_memfree

if @verbose then
  puts "Maximum: #{@maximum}"
  puts "Median: #{@median}"
  puts "Minimum: #{@minimum}"
  puts
  puts "Min Swappiness: #{@min_swappiness}"
  puts "Low Swappiness: #{@low_swappiness}"
  puts "High Swappiness: #{@high_swappiness}"
  puts "Max Swappiness: #{@max_swappiness}"
  puts
  puts "Free Memory: #{memfree}%"
end
if @syslog then
  Syslog.notice("Free Memory: #{memfree}%")
end

if @maximum > 100 then
  @maximum = 100
end
if @median > @maximum then
  @median = @maximum - 1
end
if @minimum > @median then
  @minimum = @median -1
end
if @minimum < 1 then
  @minimum = 1
end

if @min_swappiness < 1 then
  @min_swappiness = 1
end
if @low_swappiness < @min_swappiness then
  @low_swappiness = @min_swappiness + 1
end
if @high_swappiness < @low_swappiness then
  @high_swappiness = @low_swappiness + 1
end
if @max_swappiness < @high_swappiness then
  @max_swappiness = @high_swappiness + 1
end
if @max_swappiness > 100 then
  @max_swappiness = 100
end

case memfree
  when @maximum...100
    mod_swappiness(@min_swappiness)
  when @median...@maximum
    mod_swappiness(@low_swappiness)
  when @minimum...@median
    mod_swappiness(@high_swappiness)
  else
    mod_swappiness(@max_swappiness)
end

if @syslog then
  Syslog.close
end
