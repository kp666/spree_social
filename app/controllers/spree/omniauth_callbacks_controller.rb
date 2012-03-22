class Spree::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  include Spree::Core::CurrentOrder
  include Spree::Core::ControllerHelpers
  helper 'spree/users', 'spree/base'


  SpreeSocial::OAUTH_PROVIDERS.each do |provider|
    method_name = (provider[1]).to_sym
    send :define_method, method_name do
      social_setup(provider[0])
    end
  end

  def failure
    set_flash_message :alert, :failure, :kind => failed_strategy.name.to_s.humanize, :reason => failure_message
    redirect_to spree.login_path
  end

  private

  def social_setup(provider)
    p omniauth = request.env["omniauth.auth"]

    if request.env["omniauth.error"].present?
      flash[:error] = I18n.t("devise.omniauth_callbacks.failure", :kind => provider, :reason => I18n.t(:reason_user_was_not_valid))
      redirect_back_or_default(root_url)
      return
    end

    existing_auth = Spree::UserAuthentication.where(:provider => omniauth['provider'], :uid => omniauth['uid'].to_s).first

    #signing back in from a social source
    if existing_auth
      user = existing_auth.user
    else # adding a social source
      user = current_user
    end
  
    user ||= Spree::User.anonymous!
    user.associate_auth(omniauth)
    if current_order
      current_order.associate_user!(user)
      session[:guest_token] = nil
    end
    session[:name] = omniauth["user_info"]["name"]
    if user.anonymous?
      session[:user_access_token] = user.token #set user access token so we can edit this user again later
      user.email = omniauth["extra"]["user_hash"]["email"]
      user.save
      sign_in_and_redirect(user, :event => :authentication)
     # flash.now[:notice] = t("one_more_step", :kind => omniauth['provider'].capitalize)
     # render(:template => "spree/user_registrations/social_edit", :locals => {:user => user, :omniauth => omniauth})
    elsif current_user
      flash[:error] = t("attach_error", :kind => omniauth['provider'].capitalize) if existing_auth && (existing_auth.user != current_user)
      redirect_back_or_default(account_url)
    else
      sign_in_and_redirect(user, :event => :authentication)
    end
  end

end