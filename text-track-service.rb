#!/usr/bin/ruby
require 'json'
require 'date'
require 'time'
require 'logger'
require './lib/texttrack'
require 'speech_to_text'

#log_dir = "/var/log/text-track-service"
logger = Logger.new(STDOUT)
#logger = Logger.new("#{log_dir}/text-track-service.log", 'daily', 14)
logger.level = Logger::INFO

TextTrack.logger = logger

def set_parameters(params)

  if (params[0] == "ibm" && params.length == 4)
    data = {
     :service => "#{params[0]}",
     :published_file_path => "#{params[1]}",
     :recordID => "#{params[2]}",
     :auth_key => "#{params[3]}",
     :status => "success",
     :message => "successfully created json file for IBM"
     #:google_bucket_name => ("#{params[4]}" if "#{params[0]}" == "google").delete_if{ |k,v| v.nil?}
    }
  elsif (params[0] == "google" && params.length == 5)
    data = {
     :service => "#{params[0]}",
     :published_file_path => "#{params[1]}",
     :recordID => "#{params[2]}",
     :auth_key => "#{params[3]}",
     :google_bucket_name => "#{params[4]}",
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
  elsif (params[0] == "speechmatics" && params.length == 5)
      data = {
       :service => "#{params[0]}",
       :published_file_path => "#{params[1]}",
       :recordID => "#{params[2]}",
       :userID => "#{params[3]}",
       :auth_key => "#{params[4]}",
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


def create_json(data)
  file = File.open("#{data[:recordID]}.json","w")
    file.puts "{"
    file.puts "\"service\" : \"#{data[:service]}\","
    file.puts "\"published_file_path\" : \"#{data[:published_file_path]}\","
    file.puts "\"recordID\" : \"#{data[:recordID]}\","

    if data[:service] == "ibm"
      file.puts "\"auth_key\" : \"#{data[:auth_key]}\","
    elsif data[:service] == "google"
      file.puts "\"auth_key\" : \"#{data[:auth_key]}\","
      file.puts "\"google_bucket_name\" : \"#{data[:google_bucket_name]}\","
    elsif data[:service] == "mozilla_deepspeech"
      file.puts "\"deepspeech_model_path\" : \"#{data[:deepspeech_model_path]}\","
    elsif data[:service] == "speechmatics"
      file.puts "\"auth_key\" : \"#{data[:auth_key]}\","
      file.puts "\"userID\" : \"#{data[:userID]}\","
    else
      file.puts "\"auth_key\" : \"auth_key not found\,"
    end
    file.puts "\"message\" : \"#{data[:message]}\""
    file.puts "}"
  file.close
end

def start_service(recordID)
  dataFile = File.open("#{recordID}.json","r")
  data = JSON.load(dataFile)
  if data["service"] == "google"
    WM::AudioWorker.perform_async(data)
  elsif data["service"] == "ibm"
    WM::AudioWorker.perform_async(data)
  else
    puts "no such service found..."
  end
end


#main code starts from here

data = set_parameters(ARGV)
print ARGV
create_json(data)

start_service(data[:recordID])
