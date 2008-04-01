require 'benchmark'

module Benchmark
  remove_method :realtime

  # The original Benchmark.realtime[http://stdlib.rubyonrails.org/libdoc/benchmark/rdoc/classes/Benchmark.html#M000011]
  # from the standard library does some unnecessary work. Since this method is used
  # in a few places in Rails this simpler and faster implementation is worthwhile.
  def realtime
    r0 = Time.now
    yield
    r1 = Time.now
    r1.to_f - r0.to_f
  end
  module_function :realtime
end