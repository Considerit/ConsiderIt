#######
# Start the app!
#
# Determines which application to run.
#
# These are the available applications at this time: 
#
#     franklin: The main considerit application
#     saas_landing_page: The considerit homepage for marketing considerit
#

( ->

  # The server indicates which application should be run based on a 
  # meta tag it outputs to the base layout. 
  app = null
  metas = document.getElementsByTagName('meta')
  for meta in metas
    if meta.getAttribute('name') == 'app'
      app = meta.getAttribute 'content'

  if !app
    throw "Application not defined"

  # Add defined styles
  style = document.createElement('style')
  style.type = 'text/css'
  if style.styleSheet
    style.styleSheet.cssText = css
  else
    style.appendChild document.createTextNode(window.styles)

  document.body.appendChild style

  switch app
    when 'franklin'      
      if 'ontouchend' in document #detect touch support
        React.initializeTouchEvents(true)

      React.renderComponent Franklin({key: 'root'}), document.getElementById('content')

    when 'saas_landing_page'
      React.renderComponent Saas({key: 'saas_root'}), document.getElementById('content')

)()