require 'json'
require 'open3'

cmd = ''
unless ARGV[0].nil?
    record_id = ARGV[0]
    cmd = "curl http://localhost:3000/caption/delete/#{record_id}"
else
  puts "ERROR: no record_id passed"
end

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

