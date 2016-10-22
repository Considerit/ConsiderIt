# coding: utf-8
require 'securerandom'
require 'uri'

class SamlController < ApplicationController
  skip_before_action :verify_authenticity_token, :only => [:acs]

  def sso
    session[:redirect_subdomain] = params[:subdomain]
    session[:sso_domain] = sso_domain = params[:domain]
    if !sso_domain
      raise 'No SSO domain specified'
    end

    session[:redirect_back_to] = request.referer
    
    settings = User.get_saml_settings(get_url_base, sso_domain)
    if settings.nil?
      raise "No IdP Settings!"
    end
    req = OneLogin::RubySaml::Authrequest.new
    redirect_to(req.create(settings))
  end

  def acs
    errors = []

    settings = User.get_saml_settings(get_url_base, session[:sso_domain])
    response = OneLogin::RubySaml::Response.new(params[:SAMLResponse], :settings => settings)
    if response.is_valid?
      session[:nameid] = response.nameid
      session[:attributes] = response.attributes
      @attrs = session[:attributes]
      log("Sucessfully logged")
      log("NAMEID: #{response.nameid}")

      # log user. in TODO allow for incorrect login and new user with name field
      email = response.nameid.downcase #TODO: error out gracefully if no email
      user = User.find_by_email(email)

      if !user || !user.registered

        if !email || email.length == 0 || !/\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i.match(email)
          raise 'Bad email address'
        end

        # TODO when IdP Delft gives us assertion statement spec, add name field below if not already present
        name = nil
        if response.attributes.include?('Name')
          name = response.attributes['name']
        elsif response.attributes.include?('First Name')
          name = response.attributes['First Name']
          if response.attributes.include?('Last Name')
            name += " #{response.attributes['Last Name']}"
          end 
        elsif email
          name = email.split('@')[0]
        end

        user ||= User.new 

        # TODO: does SAML sometimes give avatars?
        user.update_attributes({
          :email => email,
          :password => SecureRandom.urlsafe_base64(60),
          :name => name,
          :registered => true,
          :verified => true,
          :complete_profile => true 
        })

      end 

      token = user.auth_token Subdomain.find_by_name(session[:redirect_subdomain])
      uri = URI(session[:redirect_back_to])
      uri.query ||= '?'
      uri.query += [user.email, token].join('&')
      redirect_to uri.to_s
    else
      log("Response Invalid from IdP. Errors: #{response.errors}")
      raise "Response Invalid from IdP. Errors: #{response.errors}"
    end

  end

  def metadata
    # TODO: when is this method called?
    #       The below assumes that #sso was called in this session
    settings = User.get_saml_settings(get_url_base, session[:sso_domain])
    meta = OneLogin::RubySaml::Metadata.new
    render :xml => meta.generate(settings, true)
  end

  def get_url_base
    "#{request.protocol}#{request.host_with_port}"
  end

  def log (what)
    write_to_log({:what => what, :where => request.fullpath, :details => nil})
  end
end