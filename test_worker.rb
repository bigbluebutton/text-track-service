require 'connection_pool'
require 'faktory'
require 'securerandom'

class SomeWorker
  include Faktory::Job

  def perform(*args)
    puts "Hello, I am #{jid} with args #{args}"
    sleep 1
  end
end

# schedule a job to execute ASAP
SomeWorker.perform_async(1,2,3)
# schedule a bunch of jobs to execute a few seconds in the future
10.times {|idx| SomeWorker.perform_in(idx, 1, 2, 3) }