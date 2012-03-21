Spree::User.class_eval do
  token_resource
  attr_accessor :provider
  has_many :user_authentications

  # Associates user to auth source
  def associate_auth(source)
    user_authentication = user_authentications.where(:provider => source['provider'], :uid => source['uid'].to_s).first rescue nil
    self.provider = source['provider']
    if user_authentication
      user_authentication.update_attributes(:access_token => source["credentials"]["token"],:user_name => source["extra"]["user_hash"]["username"])
      return
    else
      self.user_authentications.create!(:provider => source['provider'],
        :uid => source['uid'], :nickname => source["user_info"]['nickname'],
        :access_token =>source["credentials"]["token"],
        :user_name =>["extra"]["user_hash"]["username"]
      )
    end

  end

  # Thx Ryan
  def password_required?
    (user_authentications.empty? || !password.blank?) && super
  end


end
