Rails.application.routes.draw do
  # トップページ
  root 'users#home'

  # リソース：ユーザ
  # Shallowによりindex, new, createはuserから指定可能
  resources :users, only: %i[new index show], shallow: true do
    # リソース：ノート
    resources :notes, shallow: true do
      resources :posts
    end

    # Post派生クラスTwitterPostはcreateのみ許可
    resources :tweetposts, only: %i[create]
  end

  get '/auth/twitter/callback', to: 'users#login'
  get '/switch', to: 'users#switchuser'
  get '/login', to: 'users#new'
  get '/logout', to: 'users#logout'

  # 固定ページ
  get '/about', to: 'static_pages#about'
  get '/manage', to: 'static_pages#manage'

  # ユーザ関連
end
