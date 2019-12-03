require 'yaml'

props = YAML.load_file('credentials.yaml')
puts "info_password: #{props['info_password']}"
puts "tts_shared_secrete: #{props['tts_secret']}"