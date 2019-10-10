# frozen_string_literal: true

Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root 'captions#index'
  get '/', to: 'captions#index', as: :captions_index
  get '/caption/:record_id/:caption_locale(/:provider)', to: 'captions#caption_recording', as: :caption_recording
  get '/status/:record_id/:caption_locale', to: 'captions#caption_status', as: :caption_status
  get 'tts/downloadvtt/:record_id', to: 'edit_captions#download_vtt'
  get 'tts/downloadaudio/:record_id', to: 'edit_captions#download_audio'
  post 'tts/uploadvtt/:record_id', to: 'edit_captions#upload_vtt'
end
