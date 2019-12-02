class InfoController < ApplicationController

  def caption_status
    record_id = params[:record_id]
    caption_locale = params[:caption_locale]
    caption_job = { record_id: record_id,
                    caption_locale: caption_locale }
    # TODO:  pass locale as param
    caption = Caption.where(record_id: record_id)
      
    caption = caption.as_json
    render json: JSON.pretty_generate(caption)
  end
    
  def caption_all_status
    # TODO:  pass locale as param
    caption = Caption.all
    caption = caption.as_json
    render json: JSON.pretty_generate(caption)
  end
    
  def caption_processed_status
    # TODO:  pass locale as param
    processed_jobs = Caption.where('status LIKE ?', 'uploaded%')
      
    processed_jobs = processed_jobs.as_json
    render json: JSON.pretty_generate(processed_jobs)
  end
    
  def caption_failed_status
    # TODO:  pass locale as param
    failed_jobs = Caption.where.not('status LIKE ?', 'uploaded%')
      
    failed_jobs = failed_jobs.as_json
    render json: JSON.pretty_generate(failed_jobs)
  end

  def caption_find_record
    # TODO:  pass locale as param
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

    
end
