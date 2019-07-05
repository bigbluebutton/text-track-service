require "sinatra"
require "active_record"
require "sqlite3"
require "sequel"
require "table_print"

ActiveRecord::Base.establish_connection(
  :adapter => "sqlite3",
  :database => "transcriptionProgress.sqlite3"
)

class Progress < ActiveRecord::Base
end

get "/" do
   erb :index
end

post "/done" do
   system("ruby text-track-service.rb #{params['service']} recordID")
   erb :done
end

get "/service/:service" do
   if(params[:service] === "google")
       system("ruby text-track-service.rb #{params[:service]} /D/innovation/text-track-service test <put auth file path> bbb-accessibility")
   elsif(params[:service] === "ibm")
       system("ruby text-track-service.rb #{params[:service]} /D/innovation/text-track-service test <put api key here>")
   elsif(params[:service] === "deepspeech")
       system("ruby text-track-service.rb #{params[:service]} /D/innovation/text-track-service test <put deepspeech model path here>")
   elsif(params[:service] === "speechmatics")
       system("ruby text-track-service.rb #{params[:service]} /D/innovation/text-track-service test <put user id here> <put api key here>")
   else
       puts "No such service found"
   end
end

get "/progress" do
    tp Progress.all
end

get "/progress/:recordID" do
        
    if Progress.exists?(recordID: "#{params[:recordID]}")
        u = Progress.find_by(recordID: params[:recordID])
        #puts "Recording with id:#{u.recordID} currently has a progress: #{u.progress} last updated at #{u.updated_at}"
        
        tp u
        #for view not needed
        "Recording with id:#{u.recordID} currently has a progress: #{u.progress} last updated at #{u.updated_at}"
    else
        puts "A recording with this id: #{params[:recordID]} was not found"
        
        #for view not needed
        "A recording with this id: #{params[:recordID]} was not found"
    end
end
