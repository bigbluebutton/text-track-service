require "sinatra"

get "/" do
   erb :index
end

post "/done" do
   system("ruby text-track-service.rb #{params['service']} recordID")
   erb :done
end

get "/service/:service" do
   if(params[:service] === "google")
       system("ruby text-track-service.rb #{params[:service]} /D/innovation/text-track-service test <put google auth file here> bbb-accessibility")
   elsif(params[:service] === "ibm")
       system("ruby text-track-service.rb #{params[:service]} /D/innovation/text-track-service test <put apikey here>")
   else
       puts "No such service found"
   end
end
