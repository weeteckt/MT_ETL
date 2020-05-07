#!/usr/bin/ruby

require "optparse"

# Print the first n lines from STDIN
def n_lines_from_stdin(n)
  STDIN.each do |line|
    puts line
    n -= 1
    break if n.zero?
  end
end

if __FILE__ == $0
  OptionParser.new do |opts|
    opts.banner = <<EOS
ncat.rb [--help] [N]
    
This script prints the first N lines from STDIN.  If N is not specified, STDIN
is printed until exhausted.
EOS
  end.parse!
  
  n_lines_from_stdin(ARGV.empty? ? -1 : ARGV[0].to_i)
end
