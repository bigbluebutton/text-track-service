require 'connection_pool'
require 'faktory'
require 'securerandom'

class SomeWorker
  include Faktory::Job
  faktory_options retry: 0, concurrency: 1
  
  def perform(*args)
    puts "Hello, I am #{jid} with args #{args}"
    sleep 1
  end
end
