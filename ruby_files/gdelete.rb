# frozen_string_literal: true

require 'google/cloud/storage'

ENV['GOOGLE_APPLICATION_CREDENTIALS'] = '/D/innovation/text-track-service/test/bbb-accessibility-183f2b339bfb.json'

storage = Google::Cloud::Storage.new project_id: 'bbb-accessibility'
bucket  = storage.bucket 'bbb-accessibility'

file = bucket.file 'test.flac'

file.delete
