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
# layout constants
# 
#    |    whitespace   |                    $content_width                       |   whitespace  |
#                      |      $gutter  |      $body_width        |      $gutter  |

setResponsive = -> 
  responsive = fetch('responsive_vars')

  w = window.innerWidth

  two_col = w < 1080 || browser.is_mobile

  gutter = Math.max(25, w / 10)
  whitespace = Math.max(100, w/10)

  content_width = Math.max(900, w) - 2 * gutter

  body_width = if two_col then content_width - 2 * whitespace else content_width - 4 * whitespace
  body_width = Math.min(body_width, 700)

  decision_board_width = body_width + 4 # the four is for the border

  point_content_width = if two_col then body_width / 2 - 38 else decision_board_width / 2 - 30

  reasons_region_width = if !two_col
                           decision_board_width + 2 * point_content_width + 76
                         else 
                           decision_board_width

  point_font_size = if point_content_width > 300
                      18
                    else if point_content_width > 250
                      16
                    else
                      14

  _.extend responsive, 
    WINDOW_WIDTH: w  
    GUTTER: gutter
    WHITESPACE: whitespace
    PAGE_WIDTH: content_width + 2 * gutter
    CONTENT_WIDTH: content_width
    BODY_WIDTH: body_width
    DECISION_BOARD_WIDTH: decision_board_width
    POINT_CONTENT_WIDTH: point_content_width
    REASONS_REGION_WIDTH: reasons_region_width
    POINT_FONT_SIZE: point_font_size
    AUTH_WIDTH: if browser.is_mobile then content_width else Math.max decision_board_width, 544
    TWO_COL: two_col
    SLIDER_HANDLE_SIZE: if two_col then 65 else 25
    SIMPLE_HOMEPAGE_WIDTH: Math.min content_width, 850

  save responsive

# Initialize the responsive variables on page load.
setResponsive()

# Whenever the window resizes, we need to recalculate the variables.
$(window).on "resize.responsive_vars", setResponsive

# Convenience method for programmers to access responsive variables.
responsive = fetch('responsive_vars')
for lvar in _.keys(responsive)
  do (lvar) ->
    window[lvar] = -> fetch('responsive_vars')[lvar]

