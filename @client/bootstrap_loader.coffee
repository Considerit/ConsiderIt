#######
# Start the app!
#
# Determines which application to run.
#
# These are the available applications at this time: 
#
#     franklin: The main considerit application
#     product_page: The considerit homepage for marketing considerit
#     proposal_embed: an embedable, read-only representation of a proposal

( ->

  # The server indicates which application should be run based on a 
  # meta tag it outputs to the base layout. 
  app = null
  metas = document.getElementsByTagName('meta')
  app_meta = null
  for meta in metas
    if meta.getAttribute('name') == 'app'
      app = meta.getAttribute 'content'
      app_meta = meta 
      break

  if !app
    throw "Application not defined"

  # Add defined styles

  style = document.createElement('style')
  style.type = 'text/css'
  if style.styleSheet
    style.styleSheet.cssText = window.styles
  else
    style.appendChild document.createTextNode(window.styles)

  document.body.appendChild style

  switch app
    when 'franklin'      
      if 'ontouchend' in document #detect touch support
        React.initializeTouchEvents(true)

      React.renderComponent Franklin({key: 'root'}), document.getElementById('content')

    when 'product_page'
      React.renderComponent Saas({key: 'saas_root'}), document.getElementById('content')

    when 'proposal_embed'
      console.log app_meta, app_meta.getAttribute('proposal')
      React.renderComponent ProposalEmbed({key: app_meta.getAttribute('proposal')}), document.getElementById('content')

)()