#!/usr/bin/ruby
require 'table_print'
require 'json'
require 'open3'
require 'yaml'

working_dir = "/var/docker/text-track-service/commands"
#working_dir = "/home/test2/tts/resque/text-track-service/commands"

cmd = "sudo chmod u+rxw #{working_dir}"
Open3.popen2e(cmd) do |stdin, stdout_err, wait_thr|
  while line = stdout_err.gets
    puts "#{line}"
  end

  exit_status = wait_thr.value
  unless exit_status.success?
    puts '---------------------'
    puts "FAILED to execute --> #{cmd}"
    puts '---------------------'
  end
end

props = YAML.load_file("/var/docker/text-track-service/credentials.yaml")
#props = YAML.load_file('/home/test2/tts/resque/text-track-service/credentials.yaml')
tts_shared_secret = props['tts_shared_secret']
cmd = "curl -X POST http://localhost:4000/status/all/'#{tts_shared_secret}' > #{working_dir}/tts-all.json"
Open3.popen2e(cmd) do |stdin, stdout_err, wait_thr|
  while line = stdout_err.gets
    puts "#{line}"
  end

  exit_status = wait_thr.value
  unless exit_status.success?
    puts '---------------------'
    puts "FAILED to execute --> #{cmd}"
    puts '---------------------'
  end
end

file = File.open("#{working_dir}/tts-all.json", 'r')
data = JSON.load file
file.close

i = 0
myarray = []
unless data.nil?
  while i < data.length
    value = {"id" => "#{data[i]['id']}", 
             "record_id" => "#{data[i]['record_id']}", 
             "service" => "#{data[i]['service']}", 
             "status" => "#{data[i]['status']}", 
             "caption_locale" => "#{data[i]['caption_locale']}", 
             "processtime" => "#{data[i]['processtime']}", 
             "error" => "#{data[i]['error']}", 
             "start_time" => "#{data[i]['start_time']}",
             "end_time" => "#{data[i]['end_time']}"
           }
    myarray[i] = value
    i += 1
  end
end

cmd = "sudo rm #{working_dir}/tts-all.json"
Open3.popen2e(cmd) do |stdin, stdout_err, wait_thr|
  while line = stdout_err.gets
    puts "#{line}"
  end

  exit_status = wait_thr.value
  unless exit_status.success?
    puts '---------------------'
    puts "FAILED to execute --> #{cmd}"
    puts '---------------------'
  end
end

tp.set :max_width, 60
tp myarray






