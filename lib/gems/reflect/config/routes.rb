
Rails.application.routes.draw do

  namespace :reflect do
    match "/data" => "reflect_bullet#index", :via => :get
    match "/bullet_new" => 'reflect_bullet#create', :via => :post
    match "/bullet_update" => 'reflect_bullet#update', :via => :post
    match "/bullet_delete" => 'reflect_bullet#destroy', :via => :post
    match "/response_new" => 'reflect_response#create', :via => :post
    match "/response_update" => 'reflect_response#update', :via => :post
    match "/response_delete" => 'reflect_response#destroy', :via => :post              
  end

end