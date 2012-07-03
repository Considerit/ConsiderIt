defined?(AssetSync) do
  AssetSync.configure do |config|
    config.fog_provider = 'AWS'
    config.aws_access_key_id = APP_CONFIG.has_key?(:aws) ? APP_CONFIG[:aws][:access_key_id] : ''
    config.aws_secret_access_key = APP_CONFIG.has_key?(:aws) ? APP_CONFIG[:aws][:secret_access_key] : ''
    config.fog_directory = APP_CONFIG.has_key?(:aws) ? APP_CONFIG[:aws][:fog_directory] : ''
    
    # Increase upload performance by configuring your region
    config.fog_region = 'us-west-2'
    #
    # Don't delete files from the store
    # config.existing_remote_files = "keep"
    #
    # Automatically replace files with their equivalent gzip compressed version
    config.gzip_compression = true
    #
    # Use the Rails generated 'manifest.yml' file to produce the list of files to 
    # upload instead of searching the assets directory.
    # config.manifest = true
    #
    # Fail silently.  Useful for environments such as Heroku
    # config.fail_silently = true
  end
end