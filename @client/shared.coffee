####
# Make the DIV, SPAN, etc.
for el of React.DOM
  window[el.toUpperCase()] = React.DOM[el]


####
# Constants, especially used for layout styling
window.TRANSITION_SPEED = 700   # Speed of transition from results to crafting (and vice versa) 
window.BIGGEST_POSSIBLE_AVATAR_SIZE = 50

# layout constants
# Pictoral summary of layout variables:
# 
#    |                                        $page_width                                           |   
#    |  content_gutter |                    $content_width                       |   content_gutter |
#                      |      gutter   |      $body_width        |       gutter  |             

window.PAGE_WIDTH = 1152
window.CONTENT_WIDTH = 960
window.BODY_WIDTH = 540
window.POINT_WIDTH = 250
window.POINT_CONTENT_WIDTH = 197
window.HISTOGRAM_WIDTH = BODY_WIDTH    # Width of the slider / histogram base 
window.DECISION_BOARD_WIDTH = BODY_WIDTH + 4 # the four is for the border
window.REASONS_REGION_WIDTH = DECISION_BOARD_WIDTH + 2 * POINT_CONTENT_WIDTH + 76
window.MAX_HISTOGRAM_HEIGHT = 200
window.DESCRIPTION_WIDTH = BODY_WIDTH
window.SLIDER_HANDLE_SIZE = 22
window.COMMUNITY_POINT_MOUTH_WIDTH = 17

##################
# Colors
#
# Colors are primarily stored in the database (to allow customers & Kev to self-brand).
# See @server/models/subdomain#branding_info for hardcoding color values
# when doing development. 

window.considerit_blue = '#2478CC'
window.default_avatar_in_histogram_color = '#999'
#########################


##
# Helpers that should probably go elsewhere

window.capitalize = (string) -> string.charAt(0).toUpperCase() + string.substring(1)

window.L = window.loading_indicator = DIV null, 'Loading...'

window.splitParagraphs = (user_content) ->
  if !user_content
    return SPAN null
    
  user_content = user_content.replace(/(<li>|<br\s?\/?>|<p>)/g, '\n') #add newlines
  user_content = user_content.replace(/(<([^>]+)>)/ig, "") #strips all tags

  # autolink. We'll insert a delimiter ('(*-&)') to use for splitting later.
  # regex adapted from https://github.com/bryanwoods/autolink-js, MIT license, author Bryan Woods
  hyperlink_pattern = ///
    (^|[\s\n]) # Capture the beginning of string or line or leading whitespace
    (
      (?:https?):// # Look for a valid URL protocol (non-captured)
      [\-A-Z0-9+\u0026\u2019@#/%?=()~_|!:,.;]* # Valid URL characters (any number of times)
      [\-A-Z0-9+\u0026@#/%=~()_|] # String must end in a valid URL character
    )
  ///gi
  user_content = user_content.replace(hyperlink_pattern, "$1(*-&)link:$2(*-&)")
  paragraphs = user_content.split(/(?:\r?\n)/g)

  for para,idx in paragraphs
    P key: "para-#{idx}", 
      # now split around all links
      for text,idx in para.split '(*-&)'
        if text.substring(0,5) == 'link:'
          A key: idx, href: text.substring(5, text.length), target: '_blank',
            text.substring(5, text.length)
        else
          SPAN key: idx, text


##############################
## Styles
############

## CSS functions

# Mixin for mediaquery for retina screens. 
# Adapted from https://gist.github.com/ddemaree/5470343
window.css = {}

css_as_str = (attrs) -> _.keys(attrs).map( (p) -> "#{p}: #{attrs[p]}").join(';') + ';'

css.crossbrowserify = (props, as_str = false) -> 
  if props.transform
    _.extend props,
      '-webkit-transform' : props.transform
      '-ms-transform' : props.transform
      '-moz-transform' : props.transform
      '-o-transform' : props.transform

  if as_str then css_as_str(props) else props

css.grab_cursor = (selector)->
  """
  #{selector} {
    cursor: move;
    cursor: ew-resize;
    cursor: -webkit-grab;
    cursor: -moz-grab;
  } #{selector}:active {
    cursor: move;
    cursor: ew-resize;
    cursor: -webkit-grabbing;
    cursor: -moz-grabbing;
  }
  """


## CSS reset

window.styles = """
/* RESET
 * Eric Meyer's Reset CSS v2.0 (http://meyerweb.com/eric/tools/css/reset/)
 * http://cssreset.com
 */
html, body, div, span, applet, object, iframe,
h1, h2, h3, h4, h5, h6, p, blockquote, pre,
a, abbr, acronym, address, big, cite, code,
del, dfn, em, img, ins, kbd, q, s, samp,
small, strike, strong, sub, sup, tt, var,
b, u, i, center,
dl, dt, dd, ol, ul, li,
fieldset, form, label, legend,
table, caption, tbody, tfoot, thead, tr, th, td,
article, aside, canvas, details, embed,
figure, figcaption, footer, header, hgroup,
menu, nav, output, ruby, section, summary,
time, mark, audio, video {
  margin: 0;
  padding: 0;
  border: 0;
  font-size: 100%;
  font: inherit;
  vertical-align: baseline;
  line-height: 1.4; }

hr {
  display: block;
  height: 1px;
  border: 0;
  border-top: 1px solid #cccccc;
  margin: 0;
  padding: 0; }

body {
  min-height: 100%; }

ol, ul {
  list-style: none;
  list-style-position: inside; }

blockquote, q {
  quotes: none; }

blockquote:before, blockquote:after,
q:before, q:after {
  content: "";
  content: none; }

table {
  border-collapse: collapse;
  border-spacing: 0; }

td, th {vertical-align: top;}

h1, h2, h3, h4, h5, h6, strong {
  font-weight: bold; }

em, i {
  font-style: italic; }

/* ELEMENT DEFAULTS */
* {
  -webkit-box-sizing: border-box;
  -moz-box-sizing: border-box;
  box-sizing: border-box; }

a {
  color: inherit;
  outline: none;
  cursor: pointer;
  text-decoration: none; }
  a img {
    border: none; }

table {
  border-collapse: separate; }

ul {
  margin: 0;
  list-style-type: disc; }

ol {
  margin: 0;
  list-style-type: decimal; }

blockquote {
  quotes: "\201C" "\201D"; }
  blockquote:before {
    content: open-quote;
    font-weight: bold; }
  blockquote:after {
    content: close-quote;
    font-weight: bold; }

"""

# some basic styles
window.styles += """

body, h1, h2, h3, h4, h5, h6 {
  color: black; }

body, input, button, textarea {
  font-family: "Avenir Next W01", "Avenir Next", "Lucida Grande", "Lucida Sans Unicode", "Helvetica Neue", Helvetica, Verdana, sans-serif; }

.content {
  position: relative;
  font-size: 16px;
  color: black;
  min-height: 500px; }

.button {
  font-size: 16px; }

.button, button, input[type="submit"] {
  outline: none;
  cursor: pointer;
  text-align: center; }


.flipped {
  -moz-transform: scaleX(-1);
  -o-transform: scaleX(-1);
  -webkit-transform: scaleX(-1);
  transform: scaleX(-1);
  filter: FlipH;
  -ms-filter: "FlipH"; }

.hover_pointer {
  cursor: pointer; }

.primary_button, .primary_cancel_button {
  border-radius: 16px;
  text-align: center;
  padding: 3px;
  cursor: pointer; }

.primary_button {
  background-color: #{considerit_blue};
  color: white;
  font-size: 29px;
  margin-top: 20px;
  box-shadow: 0px 1px 0px black;
  border: none;
  padding: 6px 18px;
  font-weight: 600; }

.primary_button.disabled {
  background-color: #eeeeee;
  color: #cccccc;
  box-shadow: none;
  border: none;
  cursor: wait; }

a.primary_cancel_button {
  color: #888888;
  margin-top: 0.5em; }

a.cancel_opinion_button, a.cancel_auth_button {
  float: right;
  margin-top: 0.5em; }

button.primary_button, input[type="submit"] {
  display: inline-block; }

"""
