require 'open3'
require 'yaml'

#props = YAML.load_file('/var/docker/text-track-service/credentials.yaml')
props = YAML.load_file('/home/parthik/tts/final/text-track-service/credentials.yaml')
tts_secret = props['tts_secret']
cmd = "curl -X POST http://localhost:3000/caption/delete/all/#{tts_secret}"
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







