# frozen_string_literal: true

require 'google/cloud/storage'

auth_path = '/D/innovation/text-track-service/test'
google_auth = 'bbb-accessibility-183f2b339bfb.json'

ENV['GOOGLE_APPLICATION_CREDENTIALS'] = "#{auth_path}/#{google_auth}"

storage = Google::Cloud::Storage.new project_id: 'bbb-accessibility'
bucket  = storage.bucket 'bbb-accessibility'

file = bucket.file 'test.flac'

file.delete
