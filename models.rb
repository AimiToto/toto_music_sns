require 'bundler/setup'
Bundler.require

ActiveRecord::Base.establish_connection

class User < ActiveRecord::Base
  validates :name,
    presence: true
  has_secure_password
  validates :password,
    format: {with:/(?=.*?[a-z])(?=.*?[A-Z])(?=.*?[0-9])/},
    length: {minimum: 8}
  has_many :posts
  has_many :likes
  has_many :like_posts, :through => :likes, source: :post
end

class Post < ActiveRecord::Base
  validates :comment,
    presence: true,
    length: {maximum: 140}
  belongs_to :user
  has_many :likes
  has_many :like_users, :through => :likes, source: :user
end

class Like < ActiveRecord::Base
  validates :user_id,
    presence: true
  validates :post_id,
    presence: true
  belongs_to :user
  belongs_to :post
end
