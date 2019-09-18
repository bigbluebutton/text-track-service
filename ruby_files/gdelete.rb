# frozen_string_literal: true

require 'google/cloud/storage'

auth_path = '/D/innovation/text-track-service/auth'
google_auth = 'bbb-accessibility-183f2b339bfb.json'

ENV['GOOGLE_APPLICATION_CREDENTIALS'] = "#{auth_path}/#{google_auth}"

storage = Google::Cloud::Storage.new project_id: 'bbb-accessibility'
bucket  = storage.bucket 'bbb-accessibility'

file = bucket.file '6e35e3b2778883f5db637d7a5dba0a427f692e91-1558618209994.flac'

file.delete
