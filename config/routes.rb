Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root 'captions#index'

  get '/', to: "captions#index", as: :captions_index

  get '/caption/:record_id/:caption_locale(/:provider)', to: "captions#caption_recording", as: :caption_recording   
    
  #get '/caption/:record_id?locale=:caption_locale(&provider=:provider)', to: "captions#caption_recording", as: :caption_recording

  get '/status/:record_id/:caption_locale', to: "captions#caption_status", as: :caption_status
end
