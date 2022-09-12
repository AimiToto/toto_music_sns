require 'bundler/setup'
Bundler.require
require 'sinatra/reloader' if development?
require './models'
require 'dotenv/load'

require 'net/http'
require 'uri'

enable :sessions

helpers do
  def current_user
    User.find_by(id: session[:user])
  end
end

before do
  Dotenv.load
  Cloudinary.config do |config|
    config.cloud_name = ENV['CLOUD_NAME']
    config.api_key = ENV['CLOUDINARY_API_KEY']
    config.api_secret = ENV['CLOUDINARY_API_SECRET']
  end
end

get '/' do
  @posts = Post.all
  erb :index
end

post '/signin' do
  user = User.find_by(name: params[:name])
  if user && user.authenticate(params[:password])
    session[:user] = user.id
  end
  redirect '/'
end

get '/signup' do
    erb :sign_up
end

post '/signup' do
  img_url = ''
  if params[:image]
    img = params[:image]
    tempfile = img[:tempfile]
    upload = Cloudinary::Uploader.upload(tempfile.path)
    img_url = upload['url']
  end
  @user = User.create(name: params[:name],
                      password: params[:password],
                      password_confirmation: params[:password_confirmation],
                      image: img_url)
  if @user.persisted?
    session[:user] = @user.id
  end
  redirect '/'
end

get '/signout' do
  session[:user] = nil
  redirect '/'
end

get '/home' do
  if current_user.nil?
    redirect '/'
  else
  @posts = current_user.posts
  @liked_posts = current_user.like_posts
  erb :home
  end
end

get '/search' do
  keyword = params[:keyword]
  uri = URI("http://itunes.apple.com/search")
  uri.query = URI.encode_www_form({ term: keyword, country: "JP", media: "music", limit: 10})
  res = Net::HTTP.get_response(uri)
  returned_JSON = JSON.parse(res.body)
  @musics = returned_JSON["results"]
  erb :search
end

post '/post' do
  if current_user.nil?
    redirect '/'
  end
  new_post = Post.new(user_id: session[:user],
              image: params[:image],
              artist: params[:artist],
              album: params[:album],
              song: params[:song],
              sample: params[:sample],
              comment: params[:comment])
  new_post.save
  redirect '/home'
end

get '/post/:post_id/edit' do
  if current_user.nil?
    redirect '/'
  else
    @post = Post.find(params[:post_id])
    if @post.user_id == current_user.id
    erb :edit
    else
      redirect '/'
    end
  end
end

post '/post/:post_id/edit' do
  this_post = Post.find(params[:post_id])
  if this_post.user_id == current_user.id
    this_post.comment = params[:comment]
    this_post.save
    redirect '/home'
  else
    redirect '/'
  end
end

get '/post/:post_id/delete' do
  if current_user.nil?
    redirect '/'
  else
    this_post = Post.find(params[:post_id])
    if this_post.user_id == current_user.id
      this_post.delete
      redirect '/home'
    else
      redirect '/'
    end
  end
end

get '/post/:post_id/favorite' do
  if current_user.nil?
    redirect '/'
  else
    this_post = Post.find(params[:post_id])
    like = Like.new(user_id: session[:user],
                    post_id: params[:post_id])
    like.save
    redirect '/home'
  end
end

get '/post/:post_id/favorite/delete' do
  if current_user.nil?
    redirect '/'
  else
    this_post = Post.find(params[:post_id])
    like = Like.find_by(user_id: session[:user],
                        post_id: params[:post_id])
    like.delete
    redirect '/home'
  end
end