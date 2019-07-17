class CaptionsController < ApplicationController
    def index
        puts "Hello World!"
    end
    
    def service
        @service = params[:service]
        @recordID = params[:recordID]
        @language = params[:language]
        
        puts "#{@service} #{@recordID}"
        
       if(params[:service] === "google")
            system("bin/rails runner ./ruby_files/text-track-service.rb #{@service} /D/innovation/text-track-service #{@recordID} /D/innovation/text-track-service/test2/bbb-accessibility-183f2b339bfb.json bbb-accessibility #{@language}")
       elsif(params[:service] === "ibm")
           system("bin/rails runner ./ruby_files/text-track-service.rb #{@service} /D/innovation/text-track-service #{@recordID} <put api key here>")
       elsif(params[:service] === "deepspeech")
           system("bin/rails runner ./ruby_files/text-track-service.rb #{@service} /D/innovation/text-track-service #{@recordID} <put deepspeech model path here>")
       elsif(params[:service] === "speechmatics")
           system("bin/rails runner ./ruby_files/text-track-service.rb #{@service} /D/innovation/text-track-service #{@recordID} 67998 YzRiYzNhZWYtODk5OC00M2FjLThhYTItNmI0NTdmNTFiZTU4")
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
        @caption = Caption.where(record_id: @recordID)
        tp @caption
    end
    
    private
        def find_record_by_id
            @captionfile = Captions.find(params[:id])
        end
    
end
