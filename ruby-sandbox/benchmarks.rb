require "benchmark"
require "ostruct"
require "set"

def bench_hash_vs_os
  idx_range = 1..1000_000
  entries = idx_range.map { |idx| ["key_#{idx}", idx] }

  hash = entries.to_h
  open_s = OpenStruct.new hash

  Benchmark.bm do |line|
    line.report("hash access:") { hash["key_23"] }
    line.report("_os_ access:") { open_s.key_23 }
  end
end

def bench_find_ips_in_set
  iterations = 1000_000
  num_ips = 85_000

  octet_values = (82..255).to_a
  ips_set = Array.new(num_ips) do
    "#{octet_values.sample}.#{octet_values.sample}.#{octet_values.sample}.#{octet_values.sample}"
  end.to_set

  ips_to_find = Array.new(iterations) do
    "#{octet_values.sample}.#{octet_values.sample}.#{octet_values.sample}.#{octet_values.sample}"
  end

  Benchmark.bm do |line|
    line.report("find #{iterations} IPs in set of #{ips_set.size}:") do
      ips_to_find.each { |ip| ips_set.include? ip }
    end
  end
end

bench_find_ips_in_set
