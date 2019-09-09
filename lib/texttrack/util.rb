# frozen_string_literal: true

# Set encoding to utf-8
# encoding: UTF-8

#
# BigBlueButton open source conferencing system - http://www.bigbluebutton.org/
#
# Copyright (c) 2019 BigBlueButton Inc. and by respective authors (see below).
#

module TextTrack
  module Util # rubocop:disable Style/Documentation
    def self.valid_json?(json)
      JSON.parse(json)
      true
    rescue Exception => e # rubocop:disable Lint/RescueException
      false
    end

    def self.scrub_line_to_remove_illegal_chars(line)
      # https://stackoverflow.com/questions/24036821/ruby-2-0-0-stringmatch-argumenterror-invalid-byte-sequence-in-utf-8
      line.scrub
    end
  end
end
