
class CaptionsController < ApplicationController
  def index
    puts "Hello World!"
    puts $redis.llen("foo")
  end
    
  def service
    record_id = params[:record_id]
         
    # TODO: Need to find how to get the key from settings.yaml
    #props = YAML::load(File.open('settings.yaml'))
    #puts "REDIS HOST=#{redis_host} PORT=#{redis_port} PASS=#{redis_password}"

    #redis_namespace = props["redis_list_namespace"]       
    #   
    $redis.lpush("recordings", record_id)
  end
    
  def progress_id
    @recordID = params[:id]
    @caption = Caption.where(recordID: @recordID)
    tp @caption
  end
    
  private
    def find_record_by_id
      @captionfile = Captions.find(params[:id])
    end
end
