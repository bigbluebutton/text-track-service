# frozen_string_literal: true

require 'faktory_worker_ruby'

require 'connection_pool'
require 'faktory'
require 'securerandom'
require 'speech_to_text'
require 'json'

rails_environment_path =
  File.expand_path(File.join(__dir__, '..', '..', 'config', 'environment'))
require rails_environment_path

module TTS
  class ThreeplaymediaCreateJob # rubocop:disable Style/Documentation
    include Faktory::Job
    faktory_options retry: 5, concurrency: 1
    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/AbcSize

    def self.to_audio(param_json)
      puts "3playmedia create job -----------------to audio"
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

      audio_type = 'mp3'

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

      TTS::ThreeplaymediaCreateJob.create_job(params.to_json,
                                              u.id,
                                              audio_type)
    end

    def self.create_job(params_json, id, audio_type)
      params = JSON.parse(params_json, symbolize_names: true)
      u = nil
        
      start_time = Time.now.getutc.to_i
      # TODO
      # Need to handle locale here. What if we want to generate caption
      # for pt-BR, etc. instead of en-US?
      storage_dir = "#{params[:storage_dir]}/#{params[:record_id]}"

      job_name = rand(36**8).to_s(36)
      job_id = SpeechToText::ThreePlaymediaS2T.create_job(
        params[:provider][:auth_file_path],
        "#{storage_dir}/#{params[:record_id]}.#{audio_type}",
        job_name,
        "#{storage_dir}/job_file.json"
      )

      ActiveRecord::Base.connection_pool.with_connection do
        u = Caption.find(id)
        u.update(status: "created job with #{u.service}")
      end

      transcript_id = SpeechToText::ThreePlaymediaS2T.order_transcript(
        params[:provider][:auth_file_path],
        job_id,
        6
      )

      TTS::ThreeplaymediaGetJob.perform_async(params.to_json,
                                              u.id,
                                              job_id,
                                              transcript_id,
                                              start_time)
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength
  end

  class ThreeplaymediaGetJob # rubocop:disable Style/Documentation
    include Faktory::Job
    faktory_options retry: 0, concurrency: 1

    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/AbcSize
    def perform(params_json, id, job_id, transcript_id, start_time)
      params = JSON.parse(params_json, symbolize_names: true)
      u = nil

      status = SpeechToText::ThreePlaymediaS2T.check_status(
        params[:provider][:auth_file_path],
        transcript_id
      )
      status_msg = "status is #{status}"
      if status == 'cancelled'
        puts '-------------------'
        puts status_msg
        puts '-------------------'
        ActiveRecord::Base.connection_pool.with_connection do
          u = Caption.find(id)
          u.update(status: 'failed')
        end
        return
      elsif status != 'complete'
        puts '-------------------'
        puts status_msg
        puts '-------------------'

        ThreeplaymediaGetJob.perform_in(30,
                                        params.to_json,
                                        id,
                                        job_id,
                                        transcript_id,
                                        start_time)
        return

      elsif status == 'complete'

        current_time = (Time.now.to_f * 1000).to_i
        TTS::ThreeplaymediaGetJob.delete_files("#{params[:storage_dir]}/#{params[:record_id]}")
        SpeechToText::ThreePlaymediaS2T.get_vttfile(
          params[:provider][:auth_file_path],
          139,
          transcript_id,
          "#{params[:storage_dir]}/#{params[:record_id]}",
          "#{params[:record_id]}-#{current_time}-track.vtt"
        )

        SpeechToText::Util.recording_json(
          file_path: "#{params[:storage_dir]}/#{params[:record_id]}",
          record_id: params[:record_id],
          timestamp: current_time,
          language: params[:caption_locale]
        )
          
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

        ActiveRecord::Base.connection_pool.with_connection do
          u.update(status: "done with #{u.service}")
        end

        data = {
          'record_id' => params[:record_id].to_s,
          'storage_dir' => "#{params[:storage_dir]}/#{params[:record_id]}",
          'current_time' => current_time,
          'caption_locale' => (params[:caption_locale]).to_s,
          'bbb_url' => params[:bbb_url],
          'bbb_checksum' => params[:bbb_checksum],
          'kind' => params[:kind],
          'label' => params[:label],
          'id' => id
        }

        TTS::ThreeplaymediaGetJob.callback(data.to_json)
      end
    end

    def self.callback(params)
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
        puts "storage => #{storage_dir}"
        if Dir.exist?(storage_dir)
          FileUtils.rm_rf(storage_dir)
        end
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
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength
  end
end
