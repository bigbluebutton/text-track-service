require 'yaml'

props = YAML.load_file('/var/docker/text-track-service/credentials.yaml')
puts "tts_shared_secrete: #{props['tts_shared_secret']}"