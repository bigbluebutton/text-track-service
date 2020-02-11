# frozen_string_literal: true

require 'faktory_worker_ruby'
require 'connection_pool'
require 'faktory'
require 'securerandom'
require 'speech_to_text'

rails_environment_path =
  File.expand_path(File.join(__dir__, '..', '..', 'config', 'environment'))
require rails_environment_path

module TTS
  class DeepspeechCreateJob # rubocop:disable Style/Documentation
    include Faktory::Job
    faktory_options retry: 0, concurrency: 1

    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/AbcSize
    def self.to_audio(param_json)
      puts "Deepspeech worker --> to audio method"
      params = JSON.parse(param_json, symbolize_names: true)
      u = nil
      # needed as activerecord leaves connection open when worker dies
      
      ActiveRecord::Base.connection_pool.with_connection do
        if Caption.exists?(record_id: (params[:record_id]).to_s)
          u = Caption.find_by(record_id: (params[:record_id]).to_s)
          u.update(status: 'start_audio_conversion',
                   service: (params[:provider][:name]).to_s,
                   caption_locale: (params[:caption_locale]).to_s)
        else
          Caption.create(record_id: (params[:record_id]).to_s,
                         status: 'started_audio_conversion',
                         service: (params[:provider][:name]).to_s,
                         caption_locale: (params[:caption_locale]).to_s)
        end

        u = Caption.find_by(record_id: (params[:record_id]).to_s)
      end

      audio_type = 'wav'
        
      final_dest_dir = "#{params[:storage_dir]}/#{params[:record_id]}"
      audio_file = "#{params[:record_id]}.#{audio_type}"
      
      unless Dir.exist?(final_dest_dir)
        FileUtils.mkdir_p(final_dest_dir)
        FileUtils.chmod('u=wrx,g=wrx,o=r', final_dest_dir)
      end

      if params[:start_time].nil? && params[:end_time].nil?
          SpeechToText::Util.video_to_audio(
            video_file_path: final_dest_dir.to_s,
            video_name: 'audio_temp',
            video_content_type: 'wav',
            audio_file_path: final_dest_dir.to_s,
            audio_name: params[:record_id],
            audio_content_type: audio_type
          )
      else
         SpeechToText::Util.video_to_audio(
            video_file_path: final_dest_dir.to_s,
            video_name: 'audio_temp',
            video_content_type: 'wav',
            audio_file_path: final_dest_dir.to_s,
            audio_name: params[:record_id],
            audio_content_type: audio_type,
            start_time: params[:start_time],
            end_time: params[:end_time]
          )
      end
      
      if params[:start_time].nil?
        params[:start_time] = '0'
      end

      TTS::DeepspeechCreateJob.create_job(params.to_json,
                 u.id,
                 audio_type)
    end

    def self.create_job(params_json, id, audio_type)
      puts "Deepspeech worker --> create_job method"
      params = JSON.parse(params_json, symbolize_names: true)
      u = nil
      
      #ActiveRecord::Base.connection_pool.with_connection do
        #u = Caption.find(id)
        #u.update(status: 'finished audio conversion')
      #end

      storage_dir = "#{params[:storage_dir]}/#{params[:record_id]}"

      job_name = rand(36**8).to_s(36)
      start_time = Time.now.getutc.to_i
        
      job_id = SpeechToText::MozillaDeepspeechS2T.create_job(
        "#{storage_dir}/#{params[:record_id]}.#{audio_type}",
        params[:provider][:auth_file_path],
        "#{storage_dir}/#{job_name}_jobdetails.json",
          params[:provider][:apikey]
      )
      
      ActiveRecord::Base.connection_pool.with_connection do
        u = Caption.find(id)
        u.update(status: "created job with #{u.service}")
      end

      TTS::DeepspeechGetJob.perform_async(params.to_json,
                                          u.id,
                                          job_id,
                                          job_name,
                                          start_time)
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength
  end


  class DeepspeechGetJob # rubocop:disable Style/Documentation
    include Faktory::Job
    faktory_options retry: 0, concurrency: 1

    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/AbcSize
    def perform(params_json, id, job_id, job_name, start_time)
      puts "DeepspeechGetJob worker --> perform method"
      params = JSON.parse(params_json, symbolize_names: true)
      u = nil

      auth_file_path = params[:provider][:auth_file_path]

      status = SpeechToText::MozillaDeepspeechS2T.checkstatus(job_id,
                                                              auth_file_path,
                                                              params[:provider][:apikey])
      if status != 'completed'
        puts '-------------------'
        puts "status is #{status}"
        puts '-------------------'
        puts job_id.to_s
        puts '-------------------'
        if status['message'] == 'No jobID found'
          puts 'Job does not exist'
          ActiveRecord::Base.connection_pool.with_connection do
            u = Caption.find(id)
            u.update(status: 'failed')
          end
          return
        end

        # break if status['message'] == 'No jobID found'
        DeepspeechGetJob.perform_in(30, params.to_json, id, job_id, job_name, start_time)
        return
      end
        
      callback_json =
        SpeechToText::MozillaDeepspeechS2T.order_transcript(job_id,
                                                            auth_file_path,
                                                            params[:provider][:apikey])
      
      myarray =
        SpeechToText::MozillaDeepspeechS2T.create_mozilla_array(callback_json)
        
      end_time = Time.now.getutc.to_i
      processing_time = end_time - start_time
      processing_time =  SpeechToText::Util.seconds_to_timestamp(processing_time)
        
      ActiveRecord::Base.connection_pool.with_connection do
        u = Caption.find(id)
        u.update(processtime: "#{processing_time}")
      end
        
      puts '-------------------'
      puts "Processing time: #{processing_time} hr:min:sec.millsec"
      puts '-------------------'
          
      current_time = (Time.now.to_f * 1000).to_i

      data = {
        'record_id' => (params[:record_id]).to_s,
        'storage_dir' => "#{params[:storage_dir]}/#{params[:record_id]}",
        'temp_track_vtt' => "#{params[:record_id]}-#{current_time}-track.vtt",
        'temp_track_json' => "#{params[:record_id]}-#{current_time}-track.json",
        'myarray' => myarray,
        'current_time' => current_time,
        'caption_locale' => (params[:caption_locale]).to_s,
        'database_id' => id.to_s,
        'bbb_url' => params[:bbb_url],
        'bbb_checksum' => params[:bbb_checksum],
        'kind' => params[:kind],
        'label' => params[:label],
        'start_time' => params[:start_time],
        'end_time' => params[:end_time]
      }

      TTS::DeepspeechGetJob.create_vtt(data.to_json)

    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength
    def self.create_vtt(params)
      puts "DeepspeechCreateJob worker --> create_vtt method"
      data = JSON.load params
      record_id = data['record_id']
      storage_dir = data['storage_dir']
      temp_track_vtt = data['temp_track_vtt']
      temp_track_json = data['temp_track_json']
      myarray = data['myarray']
      current_time = data['current_time']
      caption_locale = data['caption_locale']
      id = data['database_id']
      bbb_url = data['bbb_url']
      bbb_checksum = data['bbb_checksum']
      kind = data['kind']
      label = data['label']
      start_time = data['start_time']

      u = nil       
      ActiveRecord::Base.connection_pool.with_connection do
        u = Caption.find(id)
        u.update(status: "writing subtitle file from #{u.service}")
      end

      TTS::DeepspeechGetJob.delete_files(storage_dir)
      SpeechToText::Util.write_to_webvtt(
          vtt_file_path: storage_dir.to_s,
          vtt_file_name: temp_track_vtt.to_s,
          text_array: myarray,
          start_time: start_time
        )

      #SpeechToText::Util.recording_json(
      #  file_path: storage_dir.to_s,
      #  record_id: record_id,
      #  timestamp: current_time,
      #  language: data[:caption_locale]
      #)
      ActiveRecord::Base.connection_pool.with_connection do
        u.update(status: "done with #{u.service}")
      end

      data = {
        'record_id' => record_id.to_s,
        'storage_dir' => storage_dir,
        'current_time' => current_time,
        'caption_locale' => caption_locale,
        'bbb_url' => bbb_url,
        'bbb_checksum' => bbb_checksum,
        'kind' => kind,
        'label' => label,
        'id' => id
      }

      TTS::DeepspeechGetJob.callback(data.to_json)
    end

    def self.callback(params)
      puts "DeepspeechCreateJob worker --> callback method"
      data = JSON.load params
        record_id = data['record_id']
        storage_dir = data['storage_dir']
        caption_locale = data['caption_locale']
        current_time = data['current_time']
        bbb_url = data['bbb_url']
        bbb_checksum = data['bbb_checksum']
        kind = data['kind']
        label = data['label']
        id = data['id']
        caption_locale = caption_locale.sub('-', '_')
          

        # prepare post data
        uri = URI("#{bbb_url}/bigbluebutton/api/putRecordingTextTrack?recordID=#{record_id}&kind=#{kind}&lang=#{caption_locale}&label=#{label}&checksum=#{bbb_checksum}")
        request = Net::HTTP::Post.new(uri)
        form_data = [['file', File.open("#{storage_dir}/#{record_id}-#{current_time}-track.vtt")]] # or File.open() in case of local file
        request.set_form form_data, 'multipart/form-data'
        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: false) do |http| # pay attention to use_ssl if you need it
          http.request(request)
        end

        ActiveRecord::Base.connection_pool.with_connection do
          u = Caption.find(id)
          u.update(status: "uploaded to #{u.bbb_url}")
        end
        # print response
        puts response.body.to_s
    end

    def self.delete_files(recording_dir)
        if Dir.exist?(recording_dir)
          vtt_files = Dir["#{recording_dir}/*.vtt"]
          json_files = Dir["#{recording_dir}/*.json"]
        end

        unless vtt_files.nil?
            system("rm #{vtt_files[0]}")
        end

        unless json_files.nil?
            system("rm #{json_files[0]}")
        end
    end
  end
end
