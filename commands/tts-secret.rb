require 'yaml'

props = YAML.load_file('/var/docker/text-track-service/credentials.yaml')
puts "info_password: #{props['info_password']}"
puts "tts_shared_secrete: #{props['tts_secret']}"