require './browser_hacks'

#########
#  Responsive
#
# Controls changes to shared system variables based upon characteristics of the device. 
# Primarily changes based on window width. 
#
# Publishes via StateBus "responsive_vars" that has all the variables. 
#
# A convenience method for accessing those variables is provided. Say you want to do 
# fetch('responsive_vars').CONTENT_WIDTH. Instead you can just write CONTENT_WIDTH().  
#
#

######
# setResponsive
#
# Updates the responsive variables. Called once on system load, and then subsequently
# whenever there is a relevant system event that would demand the variables to be 
# recalculated (e.g. window resizing)
#
# layout variables
#    |                                 document_width                                   |
#    |    gutter   |                    content_width                       |   gutter  |
#                  |   whitespace  |     body_width    |      whitespace    |
#
# layout constraints:
#    whitespace >= 100
#    gutter >= 25
#    content_width <= 1300
#    body_width <= 700
#    
#
setResponsive = -> 
  responsive = fetch('responsive_vars')

  w = window.innerWidth
  h = window.innerHeight

  portrait = h > w
  two_col = w < 1080 || browser.is_mobile

  # The document will be at least 900px
  document_width = Math.max(900, w)

  # There will be at least 80px of whitespace on either side of the document
  gutter = Math.max(80, w / 10)
  content_width = document_width - 2 * gutter

  whitespace = Math.max(100, w / 10)

  body_width = if two_col 
                 content_width - 2 * gutter
               else 
                 content_width - 2 * gutter - 2 * whitespace


  body_width = Math.min(body_width, 700)

  # UI components
  proposal_histo_width = 60 * Math.floor(body_width / 60)

  decision_board_width = body_width + 4 # the four is for the border

  point_width = if two_col then body_width / 2 - 38 else decision_board_width / 2 - 30

  reasons_region_width = if !two_col
                           decision_board_width + 2 * point_width + 76
                         else 
                           decision_board_width

  point_font_size = if point_width > 250
                      15
                    else
                      14

  homepage_width = Math.min content_width, 900
  homepage_width = 60 * Math.floor(homepage_width / 60)
    
  if browser.is_mobile && portrait
    point_font_size += 4

  new_vals = 
    DOCUMENT_WIDTH: document_width
    WINDOW_WIDTH: w
    GUTTER: gutter
    WHITESPACE: whitespace
    BODY_WIDTH: body_width
    PROPOSAL_HISTO_WIDTH: proposal_histo_width
    DECISION_BOARD_WIDTH: decision_board_width
    POINT_WIDTH: point_width
    REASONS_REGION_WIDTH: reasons_region_width
    POINT_FONT_SIZE: point_font_size
    AUTH_WIDTH: if browser.is_mobile then content_width else Math.max decision_board_width, 544
    TWO_COL: two_col
    SLIDER_HANDLE_SIZE: if two_col then 65 else 25
    CONTENT_WIDTH: content_width
    PORTRAIT_MOBILE: portrait && browser.is_mobile
    LANDSCAPE_MOBILE: !portrait && browser.is_mobile
    HOMEPAGE_WIDTH: homepage_width

  # only update if we have a change
  # (something like this should go into statebus)
  for k,v of new_vals
    if responsive[k] != v
      _.extend responsive, new_vals
      save responsive
      break
      
# Initialize the responsive variables on page load.
setResponsive()

# Whenever the window resizes, we need to recalculate the variables.
$(window).on "resize.responsive_vars", setResponsive

# Convenience method for programmers to access responsive variables.
responsive = fetch('responsive_vars')
for lvar in _.keys(responsive)
  do (lvar) ->
    window[lvar] = -> fetch('responsive_vars')[lvar]

