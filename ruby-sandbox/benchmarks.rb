require "benchmark"
require "ostruct"

idx_range = 1..1000_000
entries = idx_range.map { |idx| ["key_#{idx}", idx] }

hash = entries.to_h
open_s = OpenStruct.new hash

Benchmark.bm do |line|
  line.report("hash access:") { hash["key_23"] }
  line.report("_os_ access:") { open_s.key_23 }
end
