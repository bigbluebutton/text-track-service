require 'table_print'
require 'json'
require 'open3'

cmd = "sudo chmod u+w ."
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

cmd = "curl http://localhost:3000/status/failed > tts-failed.json"
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

file = File.open('tts-failed.json', 'r')
data = JSON.load file
file.close

cmd = "rm tts-failed.json"
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

tp data