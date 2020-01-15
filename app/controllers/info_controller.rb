class InfoController < ApplicationController

  def caption_status
    record_id = params[:record_id]
    #caption_locale = params[:caption_locale]
    caption_job = { record_id: record_id,
                    caption_locale: caption_locale }
    caption = Caption.where(record_id: record_id)

    caption = caption.as_json
    render json: JSON.pretty_generate(caption)
  end
    
  def caption_all_status
    password = params[:password]
    props = YAML.load_file('credentials.yaml')
    tts_shared_secret = props['tts_shared_secret']
    if (password == tts_shared_secret)
      caption = Caption.all  
      caption = caption.as_json
      render json: JSON.pretty_generate(caption)
    else
      data = '{"message" : "incorrect password"}'
      render :json=>data
    end
  end
    
  def caption_processed_status
    password = params[:password]
    props = YAML.load_file('credentials.yaml')
    tts_shared_secret = props['tts_shared_secret']
    if (password == tts_shared_secret)
      processed_jobs = Caption.where('status LIKE ?', 'uploaded%')
      processed_jobs = processed_jobs.as_json
      render json: JSON.pretty_generate(processed_jobs)
    else
      data = '{"message" : "incorrect password"}'
      render :json=>data
    end   
  end
    
  def caption_failed_status
    password = params[:password]
    props = YAML.load_file('credentials.yaml')
    tts_shared_secret = props['tts_shared_secret']
    if (password == tts_shared_secret)
      failed_jobs = Caption.where.not('status LIKE ?', 'uploaded%')
      failed_jobs = failed_jobs.as_json
      render json: JSON.pretty_generate(failed_jobs)
    else
      data = '{"message" : "incorrect password"}'
      render :json=>data
    end
  end

  def caption_find_record
    record_id = params[:record_id]
    if record_id.nil?
      data = '{"message" : "no record_id found"}'
      render :json=>data
      return
    end
    
    record = Caption.find_by(record_id: record_id)
    if record.nil?
      data = '{"message" : "no database record found"}'
      render :json=>data
      return
    end
    
    json_record = record.as_json
    render json: JSON.pretty_generate(json_record)
  end

  def delete_record
    record_id = params[:record_id]
    Caption.where(record_id: record_id).destroy_all
  end
    
  def delete_all
    password = params[:password]
    props = YAML.load_file('credentials.yaml')

    tts_shared_secret = props['tts_shared_secret']
    if (password == tts_shared_secret)
      Caption.destroy_all
    else
      data = '{"message" : "incorrect password"}'
      render :json=>data
    end
  end
end
