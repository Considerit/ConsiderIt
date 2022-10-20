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





window.SUPER_SMALL_BREAKPOINT = 545 
window.SLIDERGRAM_ON_SIDE_BREAKPOINT = 950
window.PROPOSAL_AUTHOR_AVATAR_SIZE = 40
window.PROPOSAL_AVATAR_GUTTER = 18
window.PROPOSAL_AUTHOR_AVATAR_SIZE_SMALL = 20
window.PROPOSAL_AVATAR_GUTTER_SMALL = 9


setResponsive = -> 
  responsive = fetch('responsive_vars')

  w = document.documentElement.clientWidth
  h = window.innerHeight

  one_col = w < SLIDERGRAM_ON_SIDE_BREAKPOINT
  super_small = w < SUPER_SMALL_BREAKPOINT

  portrait = h > w
  two_col = w < 1080 || browser.is_mobile

  # The document will be at least 600px
  document_width = w # Math.max(600, w)
  banner_width = Math.max(900, w)


  # There will be at least 80px of whitespace on either side of the document
  gutter = if super_small then 16 else if one_col then 40 else Math.max(80, .09 * w )
  content_width = document_width - 2 * gutter

  whitespace = Math.max(100, w / 10)

  body_width = if two_col 
                 content_width - 2 * gutter
               else 
                 content_width - 2 * gutter - 2 * whitespace


  body_width = Math.min(body_width, 700)

  # UI components
  decision_board_width = body_width + 4 # the four is for the border


  point_width = if super_small then body_width / 2 else if two_col then body_width / 2 - 38 else decision_board_width / 2 - 30


  reasons_region_width = if super_small
                          "100%"
                         else if !two_col
                           decision_board_width + 2 * point_width + 76
                         else 
                           decision_board_width

  point_font_size = 14

  homepage_width = Math.round Math.min content_width, 1100
    


  if browser.is_mobile && portrait
    point_font_size += 4


  if super_small 
    list_gutter = PROPOSAL_AUTHOR_AVATAR_SIZE_SMALL + PROPOSAL_AVATAR_GUTTER_SMALL
  else 
    list_gutter = PROPOSAL_AUTHOR_AVATAR_SIZE + PROPOSAL_AVATAR_GUTTER
  

  new_vals = 
    BANNER_WIDTH: banner_width
    WINDOW_WIDTH: w
    BODY_WIDTH: body_width
    DECISION_BOARD_WIDTH: decision_board_width
    POINT_WIDTH: point_width
    REASONS_REGION_WIDTH: reasons_region_width
    POINT_FONT_SIZE: point_font_size
    AUTH_WIDTH: if browser.is_mobile then content_width else Math.max decision_board_width, 820
    NO_CRAFTING: two_col
    SLIDERGRAM_BELOW: one_col
    SUPER_SMALL: super_small    
    CONTENT_WIDTH: content_width
    PORTRAIT_MOBILE: portrait && browser.is_mobile
    LANDSCAPE_MOBILE: !portrait && browser.is_mobile
    HOMEPAGE_WIDTH: homepage_width
    SAAS_PAGE_WIDTH: Math.min(1120, w - 2 * 24)

    LIST_ITEM_EXPANSION_SCALE: if one_col then 1 else 1.5

    # keep in sync with css variables of same name defined in list.coffee
    LIST_GUTTER: list_gutter
    ITEM_TEXT_WIDTH:    if one_col then homepage_width - list_gutter else if embedded_demo() then .6 * homepage_width else .6 * (homepage_width - 2 * list_gutter)
    ITEM_OPINION_WIDTH: if one_col then homepage_width - list_gutter else if embedded_demo() then .4 * homepage_width else .4 * (homepage_width - 2 * list_gutter)

  # only update if we have a change
  # (something like this should go into statebus)
  for k,v of new_vals
    if responsive[k] != v
      _.extend responsive, new_vals
      save responsive
      break

styles += """
  :after,
  :root {
    --WINDOW_WIDTH: 100vw;
    --SAAS_PAGE_WIDTH: min(1120px, calc(100vw - 2 * 24px));
    --HOMEPAGE_WIDTH:  min(1100px, max(900px, 100vw) - calc(2 * max(80px, 9vw)));
  }
"""

# Initialize the responsive variables on page load.
setResponsive()

# Whenever the window resizes, we need to recalculate the variables.
window.addEventListener "resize", setResponsive


# Trying to make sure to catch events (like initial auto zoom) that lead to viewport changes
window.addEventListener "gestureend", setResponsive
window.matchMedia('screen and (min-resolution: 2dppx)').addEventListener "change", setResponsive
if browser.is_mobile
  setTimeout setResponsive, 1



# Convenience method for programmers to access responsive variables.
responsive = fetch('responsive_vars')
for lvar in _.keys(responsive)
  do (lvar) ->
    window[lvar] = -> fetch('responsive_vars')[lvar]

