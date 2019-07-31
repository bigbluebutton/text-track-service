#!/usr/bin/ruby
require 'json'
require 'date'
require 'time'
require 'logger'
require_relative './lib/texttrack'
require 'speech_to_text'

#log_dir = "/var/log/text-track-service"
logger = Logger.new(STDOUT)
#logger = Logger.new("#{log_dir}/text-track-service.log", 'daily', 14)
logger.level = Logger::INFO

TextTrack.logger = logger

def set_parameters(params)

  if (params[0] == "ibm" && params.length == 5)
    data = {
     :service => "#{params[0]}",
     :published_file_path => "#{params[1]}",
     :recordID => "#{params[2]}",
     :auth_key => "#{params[3]}",
     :language_code => "#{params[4]}",
     :status => "success",
     :message => "successfully created json file for IBM"
     #:google_bucket_name => ("#{params[4]}" if "#{params[0]}" == "google").delete_if{ |k,v| v.nil?}
    }
  elsif (params[0] == "google" && params.length == 6)
    data = {
     :service => "#{params[0]}",
     :published_file_path => "#{params[1]}",
     :recordID => "#{params[2]}",
     :auth_key => "#{params[3]}",
     :google_bucket_name => "#{params[4]}",
     :language_code => "#{params[5]}",
     :status => "success",
     :message => "successfully created json file for Google"
    }
  elsif (params[0] == "mozilla_deepspeech" && params.length == 4)
    data = {
     :service => "#{params[0]}",
     :published_file_path => "#{params[1]}",
     :recordID => "#{params[2]}",
     :deepspeech_model_path => "#{params[3]}",
     :status => "success",
     :message => "successfully created json file for Google"
    }
  elsif (params[0] == "speechmatics" && params.length == 6)
      data = {
       :service => "#{params[0]}",
       :published_file_path => "#{params[1]}",
       :recordID => "#{params[2]}",
       :userID => "#{params[3]}",
       :auth_key => "#{params[4]}",
       :language_code => "#{params[5]}",
       :status => "success",
       :message => "successfully created json file for IBM"
       #:google_bucket_name => ("#{params[4]}" if "#{params[0]}" == "google").delete_if{ |k,v| v.nil?}
      }
  else
    data = {
      :status => "failed",
      :message => "Wrong service or check number of arguments.."
    }
  end
  return data
end

def start_service(data)
  if data[:service] == "google" || data[:service] == "ibm" || data[:service] == "deepspeech" || data[:service] == "speechmatics"
    WM::AudioWorker.perform_async(data)
  else
    puts "no such service found..."
  end
end


#main code starts from here

data = set_parameters(ARGV)
print ARGV

start_service(data)
