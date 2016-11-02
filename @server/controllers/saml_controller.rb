# coding: utf-8
require 'securerandom'
require 'uri'

class SamlController < ApplicationController
  skip_before_action :verify_authenticity_token, :only => [:acs]

  def sso
    session[:redirect_subdomain] = params[:subdomain].downcase
    session[:sso_idp] = sso_idp = params[:sso_idp].downcase
    if !sso_idp
      raise 'No SSO IdP specified'
    end

    session[:redirect_back_to] = request.referer
    
    settings = User.get_saml_settings(get_url_base, sso_idp)

    if settings.nil?
      raise "No IdP Settings!"
    end
    req = OneLogin::RubySaml::Authrequest.new
    if session[:sso_idp] == 'dtu'
      # link for ADSF for DTU. Some versions of ADFS allow SSO initiated login and some do not. 
      # Self generating the link for IdP initiated login here to sidestep issue
      dtu_adsf = "https://sts.ait.dtu.dk/adfs/ls/idpinitiatedsignon.aspx?loginToRp=https://saml_auth.consider.it/saml/dtu"
      redirect_to(dtu_adsf)
    else
      redirect_to(req.create(settings))
    end
  end

  def acs
    errors = []

    # TODO NATHAN REMOVE, FOR TESTING DTU LOCALLY
    #session[:sso_idp] = 'dtu'
    #puts session[:sso_idp]

    settings = User.get_saml_settings(get_url_base, session[:sso_idp])

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
      if session[:redirect_back_to]
        uri = URI(session[:redirect_back_to])
      else
        # TODO REMOVE!!!!! For Nathan testing
        uri = URI('/?q=testing')
      end

      uri.query = {:u => user.email, :t => token}.to_query + '&' + uri.query.to_s
      redirect_to uri.to_s
    else
      log("Response Invalid from IdP. Errors: #{response.errors}")
      raise "Response Invalid from IdP. Errors: #{response.errors}"
    end

  end

  def metadata
    # TODO: when is this method called?
    #       The below assumes that #sso was called in this session
    settings = User.get_saml_settings(get_url_base, session[:sso_idp])
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