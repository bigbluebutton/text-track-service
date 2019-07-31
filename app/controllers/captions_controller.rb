
class CaptionsController < ApplicationController
  def index
    puts "Hello World!"
    #puts $redis.llen("foo")
  end
    
  def caption_recording
    record_id = params[:record_id]
    caption_locale = params[:caption_locale]
         
    # TODO: Need to find how to get the key from settings.yaml
    #props = YAML::load(File.open('settings.yaml'))
    #puts "REDIS HOST=#{redis_host} PORT=#{redis_port} PASS=#{redis_password}"

    #redis_namespace = props["redis_list_namespace"]       
    #   
    caption_job = {record_id: record_id, 
      caption_locale: caption_locale}
    $redis.lpush("caption_recordings_job", caption_job.to_json)
  end
    
  def caption_status
    record_id = params[:record_id]
    caption_locale = params[:caption_locale]
    caption_job = {record_id: record_id, 
      caption_locale: caption_locale}
    # TODO:
    # pass locale as param
    caption = Caption.where(recordID: record_id)
    tp caption
  end
    
    def service
        @service = params[:service]
        @recordID = params[:recordID]
        @language = params[:language]
        
        puts "#{@service} #{@recordID}"
        
       if(params[:service] === "google")
            system("bin/rails runner ./ruby_files/text-track-service.rb #{@service} /D/innovation/text-track-service #{@recordID} /D/innovation/text-track-service/auth/bbb-accessibility-183f2b339bfb.json bbb-accessibility #{@language}")
       elsif(params[:service] === "ibm")
           system("bin/rails runner ./ruby_files/text-track-service.rb #{@service} /D/innovation/text-track-service #{@recordID} hEieEKi5ABhGYY01FYLh7swZcghEw3izdpan3Piqpa5V #{@language}")
       elsif(params[:service] === "deepspeech")
           system("bin/rails runner ./ruby_files/text-track-service.rb #{@service} /D/innovation/text-track-service #{@recordID} <put deepspeech model path here>")
       elsif(params[:service] === "speechmatics")
           system("bin/rails runner ./ruby_files/text-track-service.rb #{@service} /D/innovation/text-track-service #{@recordID} 67998 YzRiYzNhZWYtODk5OC00M2FjLThhYTItNmI0NTdmNTFiZTU4 #{@language}")
       else
           puts "No such service found"
       end
        
    end
    
    def progress
        @captions = Caption.all
        
        tp @captions
        puts @captions.to_json
    end
    
    def progress_id
        @recordID = params[:id]
        @caption = Caption.where(record_id: @recordID)
        tp @caption
        puts @caption.to_json
    end
    
    
  private
    def find_record_by_id
      @captionfile = Captions.find(params[:id])
    end
end
