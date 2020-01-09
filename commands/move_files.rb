require 'json'
require 'open3'

working_dir = "/var/docker/text-track-service/commands"
source_dir = "/var/docker/text-track-service/storage"
dest_dir = "/var/recording_dir"

cmd = "sudo mv  #{source_dir}/* #{dest_dir}"
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

cmd = "sudo chmod u+w #{working_dir}"
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

cmd = "curl https://ritz-tts6.freddixon.ca/tts/status/failed > #{working_dir}/tts-failed.json"
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

file = File.open("#{working_dir}/tts-failed.json", 'r')
data = JSON.load file
file.close

cmd = "sudo rm #{working_dir}/tts-failed.json"
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

i = 0
myarray = []

while i < data.length
  	cmd = "sudo cp #{dest_dir}/#{data[i]['record_id']} #{source_dir}" 
  i += 1
end

