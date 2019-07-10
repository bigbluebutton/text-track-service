Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root 'captions#index'
    
    
  get '/', to: "captions#index", as: :captions_index
    
  get '/service/:service/:recordID', to: "captions#service", as: :captions_service
    
  get '/progress', to: "captions#progress", as: :captions_progress
  get '/progress/:id', to: "captions#progress_id", as: :captions_progress_id
end
