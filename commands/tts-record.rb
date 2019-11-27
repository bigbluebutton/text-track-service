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


length = ARGV.length
record_id = ''
if length == 1
  record_id = ARGV[0]
elseif length == 2
  if ARGV[0] == '-r'
    record_id = ARGV[1]
  end
else

end


cmd = "curl http://localhost:3000/caption/record_id/#{ARGV[0]} > tts-record.json"
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

file = File.open('tts-record.json', 'r')
data = JSON.load file
file.close

cmd = "rm tts-record.json"
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

puts data