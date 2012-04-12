ThemesForRails.config do |config|
  # themes_dir is used to allow ThemesForRails to list available themes. It is not used to resolve any paths or routes.
  config.themes_dir = ":root/app/assets/themes"

  # assets_dir is the path to your theme assets.
  config.assets_dir = ":root/app/assets/themes/:name"

  # views_dir is the path to your theme views
  config.views_dir =  ":root/app/views/themes/:name"

  # themes_routes_dir is the asset pipeline route base. 
  # Because of the way the asset pipeline resolves paths, you do
  # not need to include the 'themes' folder in your route dir.
  #
  # for example, to get application.css for the default theme, 
  # your URL route should be : /assets/default/stylesheets/application.css
  config.themes_routes_dir = "assets"
end