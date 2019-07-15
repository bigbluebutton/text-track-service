Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root 'captions#index'

  get '/', to: "captions#index", as: :captions_index

  get '/caption/:record_id', to: "captions#caption_recording", as: :caption_recording

  get '/status/:record_id', to: "captions#caption_status", as: :caption_status
end
