#!/usr/bin/ruby

require 'json'
require 'date'
require 'time'
require 'logger'
require './lib/texttrack'
require 'speech_to_text'
require "./app"


#log_dir = "/var/log/text-track-service"
logger = Logger.new(STDOUT)
#logger = Logger.new("#{log_dir}/text-track-service.log", 'daily', 14)
logger.level = Logger::INFO

TextTrack.logger = logger

def set_parameters(*params)
  if(params.length == 4 || params.length == 5)
  data = { :service => "#{params[0]}",
           :published_file_path => "#{params[1]}",
           :recordID => "#{params[2]}",
           :auth_key => "#{params[3]}",
           :status => "success",
           :message => "successfully created json file",
           :google_bucket_name => ("#{params[4]}" if "#{params[0]}" == "google")}.delete_if{ |k,v| v.nil?
  }
  else
    data = {
      :status => "failed",
      :message => "Wrong number of arguments"
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
    file.puts "\"auth_key\" : \"#{data[:auth_key]}\","
    if data[:service] == "google"
      file.puts "\"google_bucket_name\" : \"#{data[:google_bucket_name]}\","
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
if(ARGV.length == 5)
  data = set_parameters(ARGV[0],ARGV[1],ARGV[2],ARGV[3],ARGV[4])
elsif(ARGV.length == 4)
  data = set_parameters(ARGV[0],ARGV[1],ARGV[2],ARGV[3])
else
end
create_json(data)

start_service(data[:recordID])
