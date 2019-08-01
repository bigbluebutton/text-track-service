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
            system("bin/rails runner ./ruby_files/text-track-service.rb #{@service} /D/innovation/text-track-service #{@recordID} <put api key here> <put google bucket name here> #{@language} ")
       elsif(params[:service] === "ibm")
           system("bin/rails runner ./ruby_files/text-track-service.rb #{@service} /D/innovation/text-track-service #{@recordID} <put api key here> #{@language}")
       elsif(params[:service] === "deepspeech")
           system("bin/rails runner ./ruby_files/text-track-service.rb #{@service} /D/innovation/text-track-service #{@recordID} <put deepspeech model path here>")
       elsif(params[:service] === "speechmatics")
           system("bin/rails runner ./ruby_files/text-track-service.rb #{@service} /D/innovation/text-track-service #{@recordID} <put user id here> <put api key here> #{@language}")
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
