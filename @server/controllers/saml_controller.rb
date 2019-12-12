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

    if params.has_key?('redirect')  
      session[:redirect_back_to] = params['redirect'] 
    else 
      session[:redirect_back_to] = request.referer
    end

    settings = get_saml_settings(get_url_base, sso_idp)

    if settings.nil?
      raise "No IdP Settings!"
    end
    req = OneLogin::RubySaml::Authrequest.new
    if session[:sso_idp] == 'dtu'
      # link for ADSF for DTU. Some versions of ADFS allow SSO initiated login and some do not. 
      # Self generating the link for IdP initiated login here to sidestep issue
      dtu_adsf = "https://sts.ait.dtu.dk/adfs/ls/idpinitiatedsignon.aspx?loginToRp=https://saml-auth.consider.it/saml/dtu"
      redirect_to(dtu_adsf)
    else
      redirect_to(req.create(settings))
    end
  end

  def acs
    errors = []
    settings = get_saml_settings(get_url_base, session[:sso_idp])

    response = OneLogin::RubySaml::Response.new(params[:SAMLResponse], :settings => settings, :allowed_clock_drift => 60.second)
    

    if response.is_valid?

      session[:nameid] = response.nameid
      session[:attributes] = response.attributes
      @attrs = session[:attributes]
      log("Sucessfully logged")
      log("NAMEID: #{response.nameid}")

      # response.attributes.each do |k,v| 
      #   puts "#{k}: #{v}" 
      # end


      # log user. in TODO allow for incorrect login and new user with name field

      #TODO: error out gracefully if no email
      if response.attributes.include?(:email)
        email = response.attributes[:email]
      else 
        email = response.nameid 
      end 

      email = email.downcase

      

      user = User.find_by_email(email)

      if !user || !user.registered

        if !email || email.length == 0 || !/\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i.match(email)
          raise 'Bad email address'
        end

        # TODO when IdP Delft gives us assertion statement spec, add name field below if not already present
        name = nil

        if response.attributes.include?('nickname')
          name = response.attributes['nickname']
        elsif response.attributes.include?('Name')
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


      if response.attributes.include?('picture') && !user.avatar_file_name
        user.avatar  = URI.parse(response.attributes['picture'])
        puts 'avatar...'
        puts URI.parse(response.attributes['picture'])
        user.avatar_remote_url = response.attributes['picture']        
        user.save
      end


      token = user.auth_token Subdomain.find_by_name(session[:redirect_subdomain])
      uri = URI(session[:redirect_back_to])
      uri.query = {:u => user.email, :t => token}.to_query + '&' + uri.query.to_s
      redirect_to uri.to_s
    else
      log("Response Invalid from IdP. Errors: #{response.errors}")
      raise "Response Invalid from IdP. Errors: #{response.errors}. "
    end

  end

  def metadata
    # TODO: when is this method called?
    #       The below assumes that #sso was called in this session
    settings = get_saml_settings(get_url_base, session[:sso_idp])
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

def get_saml_settings(url_base, sso_idp)
  # should retrieve SAML-settings based on subdomain, IP-address, NameID or similar

  conf = APP_CONFIG[:SSO_domains][sso_idp.to_sym]

  

  if conf[:metadata]
    idp_metadata_parser = OneLogin::RubySaml::IdpMetadataParser.new
    settings = idp_metadata_parser.parse_remote(conf[:metadata])
  else 
    settings = OneLogin::RubySaml::Settings.new(conf)
  end


  url_base ||= "http://localhost:3000"



  settings.name_identifier_format = "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress"
  settings.soft = true

  # mozilla configuration not working with sp_entity_id = /saml/metadata, expecting /saml/acs instead. 
  # not sure if that a configuration problem on their end, or a problem with the code 
  # here from the start. sp_entity_id used to be issuer, so I would have expected metadata
  # to be correct. 
  # settings.sp_entity_id ||= url_base + "/saml/metadata"
  settings.sp_entity_id ||= url_base + "/saml/acs"
  settings.assertion_consumer_service_url   ||= url_base + "/saml/acs"
  settings.assertion_consumer_logout_service_url ||= url_base + "/saml/logout"
  
  settings.security[:digest_method] ||= XMLSecurity::Document::SHA1
  settings.security[:signature_method] ||= XMLSecurity::Document::RSA_SHA1

  # settings.request_attributes ||= [
  #   { :name => 'email', :name_format => 'urn:oasis:names:tc:SAML:2.0:attrname-format:basic', :friendly_name => 'Email address' },
  #   { :name => 'name', :name_format => 'urn:oasis:names:tc:SAML:2.0:attrname-format:basic', :friendly_name => 'Full name' },
  #   { :name => 'first_name', :name_format => 'urn:oasis:names:tc:SAML:2.0:attrname-format:basic', :friendly_name => 'Given name' },
  #   { :name => 'last_name', :name_format => 'urn:oasis:names:tc:SAML:2.0:attrname-format:basic', :friendly_name => 'Family name' }
  # ]


  settings

end