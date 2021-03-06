class User < ActiveRecord::Base

  devise :database_authenticatable, :registerable,
    :recoverable, :rememberable, :trackable, :validatable,
    :token_authenticatable,
    :omniauthable, :omniauth_providers => [:facebook,:google_oauth2]

  attr_accessible :email, :password, :password_confirmation, :remember_me, :nome, :provider, :uid

  has_and_belongs_to_many :compras

  validates :nome, :presence => true, :length => { :minimum => 3 }
  validates :email, :presence => true

  before_save :ensure_authentication_token

  def resource_name
  	:user
  end

  def resource
  	@resource ||= User.new
  end

  def devise_mapping
  	@devise_mapping ||= Devise.mappings[:user]
  end

  def skip_confirmation!
    self.confirmed_at = Time.now
  end

  def self.new_with_session(params, session)
    super.tap do |user|
      if data = session["devise.facebook_data"] && session["devise.facebook_data"]["extra"]["raw_info"]
        user.email = data["email"] if user.email.blank?
      end
    end
  end

  #Cadastro de usuario apartir da conta do facebook
  def self.find_for_facebook_oauth(auth, signed_in_resource=nil)
    user = User.where(:provider => auth.provider, :uid => auth.uid).first
    unless user
      user = User.create(nome:auth.extra.raw_info.name,
                           provider:auth.provider,
                           uid:auth.uid,
                           email:auth.info.email,
                           password:Devise.friendly_token[0,20]
                           )
    end
    user
  end

  #Cadastro de usuario apartir da conta do googlr
  #O método tenta encontrar um usuário existente partir do e-mail ou criar um com uma senha aleatória.
  def self.find_for_google_oauth2(access_token, signed_in_resource=nil)
    data = access_token.info
    user = User.where(:email => data["email"]).first

    unless user
        user = User.create(nome: data["name"],
             email: data["email"],
             password: Devise.friendly_token[0,20]
            )
    end
    user
  end

end
