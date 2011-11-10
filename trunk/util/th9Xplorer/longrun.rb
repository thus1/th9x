#! /usr/bin/env ruby


t0=Time.new
dt=(ARGV[0] || "10").to_i
dt1=1
while (Time.new-t0)<dt
  if (Time.new-t0)> (dt1*0.1)
    print "#"; STDOUT.flush
    if dt1%10 == 0
      puts 
      STDERR.puts "error"
    end
    dt1+=1
  end
end
puts "finished"
exit 1
