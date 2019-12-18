#!/usr/bin/ruby
# frozen_string_literal: true

#
# BigBlueButton open source conferencing system - http://www.bigbluebutton.org/
#
# Copyright (c) 2013 BigBlueButton Inc. and by respective authors (see below).
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU Lesser General Public License as published by the Free
# Software Foundation; either version 3.0 of the License, or (at your option)
# any later version.
#
# BigBlueButton is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more
# details.
#
# You should have received a copy of the GNU Lesser General Public License along
# with BigBlueButton; if not, see <http://www.gnu.org/licenses/>.
#

require 'trollop'
require "rest-client"
require 'yaml'
require "speech_to_text"

require File.expand_path('../../lib/recordandplayback', __dir__)

opts = Trollop.options do
  opt :meeting_id, 'Meeting id to archive', type: String
end

meeting_id = opts[:meeting_id]

bbb_props = YAML.load_file('/usr/local/bigbluebutton/core/scripts/bigbluebutton.yml')

log_dir = bbb_props['log_dir']
logger = Logger.new("#{log_dir}/post_publish.log", 'weekly')
logger.level = Logger::INFO
BigBlueButton.logger = logger

presentation_dir = bbb_props['presentation_dir']
published_files = "#{presentation_dir}/#{meeting_id}"

recording_dir = bbb_props['recording_dir']
archived_files = "#{recording_dir}/raw/#{meeting_id}"
meeting_metadata = BigBlueButton::Events.get_meeting_metadata("#{recording_dir}/raw/#{meeting_id}/events.xml")
events_xml = "#{archived_files}/events.xml"
audio_dir = "#{archived_files}/audio"

#published_files_video = "/var/bigbluebutton/published/presentation/#{$meeting_id}/video"
#scripts = "/usr/local/bigbluebutton/core/scripts/post_publish"

############################CUSTOM SCRIPT STARTS HERE#######################################
#[{"localeName": "English (United States)", "locale": "en-US"}]


# response = RestClient::Request.execute(
# method: :get,
# url:    "http://localhost:4000/caption/#{$meeting_id}/en-US",
# )


temp_storage = bbb_props['temp_storage']
final_dest_dir = "#{temp_storage}/#{meeting_id}"
audio_file = "#{meeting_id}.wav"

unless Dir.exist?(final_dest_dir)
  FileUtils.mkdir_p(final_dest_dir)
  FileUtils.chmod('u=wrx,g=wrx,o=r', final_dest_dir)
end

#unless File.exist?("#{final_dest_dir}/#{audio_file}")
SpeechToText::Util.video_to_audio(
  video_file_path: "#{published_files}/video",
  video_name: 'webcams',
  video_content_type: 'webm',
  audio_file_path: final_dest_dir.to_s,
  audio_name: meeting_id,
  audio_content_type: "wav",
  start_time: 0,
  end_time: 600 
)
#end

site = "http://#{bbb_props['playback_host']}"
secret = bbb_props['shared_secret']
kind = "subtitles"
lang = "en_US"
label = "English"
request = "putRecordingTextTrackrecordID=#{meeting_id}&kind=#{kind}&lang=#{lang}&label=#{label}"
request += secret
checksum = Digest::SHA1.hexdigest(request)

start_time = nil 
end_time = nil 

tts_secret = bbb_props['tts_shared_secret']

payload = { :bbb_url => site,
            :bbb_checksum => checksum,
            :kind => kind,
            :label => label,
            :start_time => start_time,
            :end_time => end_time
          }

token = JWT.encode payload, "#{tts_secret}", 'HS256'

request = RestClient::Request.new(
    method: :get,
    url: "https://ritz-tts6.freddixon.ca/tts/caption/#{meeting_id}/en-US",
    payload: { :file => File.open("#{temp_storage}/#{meeting_id}/#{meeting_id}.wav", 'rb'),
               :token => token }
)

response = request.execute


if(response.code != 200)
  BigBlueButton.logger.info("#{response.code} error")
end

exit 0