#######
# Start the app!
#
# Determines which application to run.
#
# These are the available applications at this time: 
#
#     franklin: The main considerit application
#     proposal_embed: an embedable, read-only representation of a proposal

( ->

  # The server indicates which application should be run based on a 
  # meta tag it outputs to the base layout. 
  app = 'franklin'
  metas = document.getElementsByTagName('meta')
  app_meta = null
  for meta in metas
    if meta.getAttribute('name') == 'app'
      app = meta.getAttribute 'content'
      app_meta = meta 
      break

  if !app
    throw "Application not defined"

  return if app not in ['franklin', 'proposal_embed']

  # Add defined styles

  style = document.createElement('style')
  style.type = 'text/css'
  if style.styleSheet
    style.styleSheet.cssText = window.styles
  else
    style.appendChild document.createTextNode(window.styles)

  document.body.appendChild style

  container = document.getElementById('content')

  root = ReactDOM.createRoot(container)

  switch app

    when 'franklin'      
      root.render Franklin()

    when 'proposal_embed'
      root.render ProposalEmbed({proposal: app_meta.getAttribute('proposal')})


)()