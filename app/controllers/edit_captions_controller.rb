class EditCaptionsController < ApplicationController

    def download_vtt
      record_id = params[:record_id]
      current_time = (Time.now.to_f * 1000).to_i
      props = YAML.load_file('settings.yaml')
      storage_dir = props['storage_dir']

      if Dir.exist?("#{storage_dir}/#{record_id}")
        vtt_files = Dir["#{storage_dir}/#{record_id}/*.vtt"]
      else
        data = "{\"message\" : \"record_id not found\"}"
        render :json=>data
        return
      end

      if vtt_files[0].nil?
        data = "{\"message\" : \"vtt file not found\"}"
        render :json=>data
        return
      end

      send_file(vtt_files[0],
      filename: "#{record_id}_#{current_time}.vtt",
      type: "application/vtt"
      )
    end

    def download_audio
      record_id = params[:record_id]
      props = YAML.load_file('settings.yaml')
      storage_dir = props['storage_dir']
      current_time = (Time.now.to_f * 1000).to_i

      if Dir.exist?("#{storage_dir}/#{record_id}")
        audio = "#{storage_dir}/#{record_id}/audio_temp.wav"
      else
        data = "{\"message\" : \"record_id not found\"}"
        render :json=>data
        return
      end

      unless File.exist?(audio)
        data = "{\"message\" : \"audio not found\"}"
        render :json=>data
        return
      end

      send_file(audio,
      filename: "#{record_id}_#{current_time}.wav",
      type: "audio/wav"
      )
    end

    def upload_vtt
      vtt_file = params['file']
      record_id = params[:record_id]
      bbb_checksum = params[:bbb_checksum]
      bbb_url = params[:bbb_url]
      kind = params[:kind]
      label = params[:label]
      caption_locale = params[:caption_locale]

      if vtt_file.nil?
        data = "{\"message\" : \"missing param file\"}"
        render :json=>data
        return
      end
      props = YAML.load_file('settings.yaml')
      storage_dir = props['storage_dir']
      recording_dir = "#{storage_dir}/#{record_id}"
      current_time = (Time.now.to_f * 1000).to_i

      if(delete_files(recording_dir))
        File.open("#{recording_dir}/#{record_id}-#{current_time}-track.vtt", 'w') do |file|
          file.write vtt_file.read
        end

        data = {
          'record_id' => record_id.to_s,
          'storage_dir' => recording_dir,
          'current_time' => current_time,
          'caption_locale' => caption_locale,
          'bbb_url' => bbb_url,
          'bbb_checksum' => bbb_checksum,
          'kind' => kind,
          'label' => label
        }

        $redis.lpush('caption_editing_job', data.to_json)

      end
    end

    private
    def delete_files(recording_dir)
      if Dir.exist?(recording_dir)
        vtt_files = Dir["#{recording_dir}/*.vtt"]
      else
        data = "{\"message\" : \"record_id not found\"}"
        render :json=>data
        return false
      end

      unless vtt_files[0].nil?
        system("rm #{vtt_files[0]}")
      end
      return true
    end

end
