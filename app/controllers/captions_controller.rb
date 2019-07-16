class CaptionsController < ApplicationController
    def index
        puts "Hello World!"
    end
    
    def service
        @service = params[:service]
        @recordID = params[:recordID]
        
        puts "#{@service} #{@recordID}"
        
       if(params[:service] === "google")
            system("bin/rails runner ./ruby_files/text-track-service.rb #{@service} /D/innovation/text-track-service #{@recordID} /D/innovation/text-track-service/test2/bbb-accessibility-183f2b339bfb.json bbb-accessibility")
       elsif(params[:service] === "ibm")
           system("bin/rails runner ./ruby_files/text-track-service.rb #{@service} /D/innovation/text-track-service #{@recordID} hEieEKi5ABhGYY01FYLh7swZcghEw3izdpan3Piqpa5V")
       elsif(params[:service] === "deepspeech")
           system("bin/rails runner ./ruby_files/text-track-service.rb #{@service} /D/innovation/text-track-service #{@recordID} <put deepspeech model path here>")
       elsif(params[:service] === "speechmatics")
           system("bin/rails runner ./ruby_files/text-track-service.rb #{@service} /D/innovation/text-track-service #{@recordID} <put user id here> <put api key here>")
       else
           puts "No such service found"
       end
        
    end
    
    def progress
        @captions = Caption.all
        
        tp @captions
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
