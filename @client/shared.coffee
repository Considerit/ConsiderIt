####
# Make the DIV, SPAN, etc.
for el of React.DOM
  window[el.toUpperCase()] = React.DOM[el]


window.styles = ""

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
window.DECISION_BOARD_WIDTH = BODY_WIDTH + 4 # the four is for the border
window.REASONS_REGION_WIDTH = DECISION_BOARD_WIDTH + 2 * POINT_CONTENT_WIDTH + 76
window.DESCRIPTION_WIDTH = BODY_WIDTH
window.SLIDER_HANDLE_SIZE = 22
window.COMMUNITY_POINT_MOUTH_WIDTH = 17

##################
# Colors
#
# Colors are primarily stored in the database (to allow customers & Kev to self-brand).
# See @server/models/subdomain#branding_info for hardcoding color values
# when doing development. 

window.focus_blue = '#2478CC'
window.default_avatar_in_histogram_color = '#d3d3d3'
#########################

##
# logging

window.on_ajax_error = () ->
  (root = fetch('root')).server_error = true
  save(root)
window.on_client_error = (e) ->
  if navigator.userAgent.indexOf('PhantomJS') >= 0
    # don't care about errors on phtanomjs web crawlers
    return

  save(
    key: '/new/client_error'
    stack: e.stack
    message: e.message or e.description
    name: e.name
    line_number: e.lineNumber
    column_number: e.columnNumber
    )

window.writeToLog = (entry) ->
  _.extend entry, 
    key: '/new/log'
    where: fetch('location').url

  save entry




##
# Helpers


window.inRange = (val, min, max) ->
  return val <= max && val >= min

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

# Computes the width of some text given some styles empirically
width_cache = {}
window.widthWhenRendered = (str, style) -> 
  # This DOM manipulation is relatively expensive, so cache results
  key = JSON.stringify _.extend({str: str}, style)
  if key not of width_cache
    $el = $("<span id='width_test'>#{str}</span>").css(style)
    $('#content').append($el)
    width = $('#width_test').width()
    $('#width_test').remove()
    width_cache[key] = width
  width_cache[key]

# Returns the style for a css triangle
# 
window.cssTriangle = (direction, color, width, height, style) -> 
  style = style or {}

  switch direction
    when 'top'
      border_width = "0 #{width/2}px #{height}px #{width/2}px"
      border_color = "transparent transparent #{color} transparent"
    when 'bottom'
      border_width = "#{height}px #{width/2}px 0 #{width/2}px"
      border_color = "#{color} transparent transparent transparent"
    when 'left'
      border_width = "#{height/2}px #{width}px #{height/2}px 0"
      border_color = "transparent #{color} transparent transparent"
    when 'right'
      border_width = "#{height/2}px 0 #{height/2}px #{width}px"
      border_color = "transparent transparent transparent #{color}"

  _.defaults style, 
    width: 0
    height: 0
    borderStyle: 'solid'
    borderWidth: border_width
    borderColor: border_color

  style

# maps an opinion stance in [-1, 1] to a pixel value [0, width]
window.translateStanceToPixelX = (stance, width) -> (stance + 1) / 2 * width

# Maps a pixel value [0, width] to an opinion stance in [-1, 1] 
window.translatePixelXToStance = (pixel_x, width) -> 2 * (pixel_x / width) - 1



#############################
## Components
################

window.AutoGrowTextArea = ReactiveComponent
  displayName: 'AutoGrowTextArea'  

  # You can pass an onChange() handler in to props that will get
  # called
  onChange: (e) ->
    @props.onChange?(e)
    @checkAndSetHeight()

  componentDidMount : -> @checkAndSetHeight()
  componentDidUpdate : -> @checkAndSetHeight()

  checkAndSetHeight : ->
    scroll_height = @getDOMNode().scrollHeight
    max_height = @props.max_height or 600
    if scroll_height > @getDOMNode().clientHeight
      @local.height = Math.min scroll_height + 5, max_height
      save(@local)

  render : -> 
    if !@local.height
      @local.height = @props.min_height

    @transferPropsTo TEXTAREA
      onChange: @onChange
      style: {height: @local.height}


window.CharacterCountTextInput = ReactiveComponent
  displayName: 'CharacterCountTextInput'
  componentWillMount : -> fetch(@local_key).count = 0
  render : -> 
    class_name = "is_counted"
    DIV style: {position: 'relative'}, 
      @transferPropsTo TEXTAREA className: class_name, onChange: (=>
         @local.count = $(@getDOMNode()).find('textarea').val().length
         save(@local))
      SPAN className: 'count', @props.maxLength - @local.count



window.WysiwygEditor = ReactiveComponent
  displayName: 'WysiwygEditor'

  render : ->

    my_data = fetch @props.key
    subdomain = fetch '/subdomain'
    wysiwyg_editor = fetch 'wysiwyg_editor'

    if !@local.initialized
      # We store the current value of the HTML at
      # this component's key. This allows the  
      # parent component to fetch the value outside 
      # of this generic wysiwyg component. 
      # However, we "dangerously" set the html of the 
      # editor to the original @props.html. This is 
      # because we don't want to interfere with the 
      # wysiwyg editor's ability to manage e.g. 
      # the selection location. 
      my_data.html = @props.html
      @local.initialized = true
      save @local; save my_data

    toolbar_button_style = 
      cursor: 'pointer'
      padding: 8
      backgroundColor: 'white'
      color: '#414141'
      margin: '3px 3px'
      border: '1px solid #aaa'
      borderRadius: 3
      boxShadow: '0 1px 2px rgba(0,0,0,.2)'

    show_placeholder = (!my_data.html || (@editor?.getText().trim().length == 0)) && !!@props.placeholder

    DIV 
      id: @props.key
      style: @props.style
      onClick: (ev) -> 
        # Catch any clicks within the editor area to prevent the 
        # toolbar from being hidden via the root level 
        # show_wysiwyg_toolbar state
        ev.stopPropagation()

      if @local.edit_code
        AutoGrowTextArea
          style: 
            width: '100%'
            fontSize: 18
          defaultValue: fetch(@props.key).html
          onChange: (e) => 
            my_data = fetch(@props.key)
            my_data.html = e.target.value
            save my_data

      else

        # Toolbar
        [DIV 
          id: 'toolbar'
          style: 
            position: 'fixed'
            top: 0
            backgroundColor: '#e7e7e7'
            boxShadow: '0 1px 2px RGBA(0,0,0,.2)'
            zIndex: 999
            padding: '0 12px'
            display: if wysiwyg_editor.showing == @props.key then 'block' else 'none'

          I 
            className: "ql-bullet fa fa-list-ul"
            style: toolbar_button_style
            title: 'Bulleted list'

          I 
            className: "ql-list fa fa-list-ol"
            style: toolbar_button_style
            title: 'Numbered list'

          I 
            className: "ql-bold fa fa-bold"
            style: toolbar_button_style
            title: 'Bold'

          I 
            className: "ql-link fa fa-link"
            style: toolbar_button_style
            title: 'Link'

          # I 
          #   className: "ql-image fa fa-image"
          #   style: toolbar_button_style
          #   title: 'Insert image'

          if fetch('/current_user').is_super_admin
            I
              className: 'fa fa-code'
              style: toolbar_button_style
              onClick: => @local.edit_code = true; save @local


        DIV 
          id: 'editor'
          dangerouslySetInnerHTML:{__html: @props.html}
          'data-placeholder': if show_placeholder then @props.placeholder else ''
          onFocus: => 
            # Show the toolbar on focus
            # showing is global state for the toolbar to be 
            # shown. It gets set to null when someone clicks outside the 
            # editor area. This is handled at the root level
            # in the same way that clicking outside a point closes it. 
            # See Root.resetSelection.
            wysiwyg_editor = fetch 'wysiwyg_editor'
            wysiwyg_editor.showing = @props.key
            save wysiwyg_editor
        ]

  componentDidMount : -> 
    # Attach the Quill wysiwyg editor
    @editor = new Quill $(@getDOMNode()).find('#editor')[0],    
      modules: 
        toolbar: 
          container: $(@getDOMNode()).find('#toolbar')[0]
        'link-tooltip': true
        'image-tooltip': true
      styles: true #if/when we want to define all styles, set to false

    @editor.on 'text-change', (delta, source) => 
      my_data = fetch @props.key
      my_data.html = @editor.getHTML()

      if source == 'user' && my_data.html.indexOf(' style') > -1
        # strip out any style tags the user may have pasted into the html
        removeStyles = (el) ->
          el.removeAttribute 'style'
          if el.childNodes.length > 0
            for child in el.childNodes
              removeStyles child if child.nodeType == 1

        node = $(my_data.html)[0]
        removeStyles node
        @editor.setHTML $(node).html()
        return # the above line will trigger this text-change event 
               # again, w/o the style html

      save my_data

# Some overrides to Quill base styles
styles += """
html .ql-container{
  font-family: inherit;
  font-size: inherit;
  line-height: inherit;
  padding: 0;
  overflow-x: visible;
  overflow-y: visible;
}
.ql-container:after{
  content: attr(data-placeholder);
  left: 0;
  top: 0;
  position: absolute;
  color: #aaa;
  pointer-events: none;
  z-index: 1;
}
"""






##############################
## Styles
############

## CSS functions

# Mixin for mediaquery for retina screens. 
# Adapted from https://gist.github.com/ddemaree/5470343
window.css = {}

css_as_str = (attrs) -> _.keys(attrs).map( (p) -> "#{p}: #{attrs[p]}").join(';') + ';'

css.crossbrowserify = (props, as_str = false) -> 

  prefixes = ['-webkit-', '-ms-', '-mox-', '-o-']
  if props.transform
    for prefix in prefixes
      props["#{prefix}transform"] = props.transform

  if props.transition
    for prefix in prefixes
      props["#{prefix}transition"] = props.transition.replace("transform", "#{prefix}transform")

  if props.userSelect
    _.extend props,
      MozUserSelect: props.userSelect
      WebkitUserSelect: props.userSelect
      msUserSelect: props.userSelect

  if as_str then css_as_str(props) else props

css.grayscale = (props) ->
  _.extend props,
    WebkitFilter: 'grayscale(100%)'
    filter: 'grayscale(100%)'  
  props

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

window.styles += """
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
  content: '';
  content: none; }

table {
  border-collapse: collapse;
  border-spacing: 0; }

td, th {vertical-align: top;}

h1, h2, h3, h4, h5, h6, strong {
  font-weight: bold; }

em, i {
  font-style: italic; }

b, strong { font-weight: bold; }

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
  quotes: '"' '"' "'" "'"; }
  blockquote:before {
    content: open-quote;}
  blockquote:after {
    content: close-quote;}

"""

# some basic styles
window.styles += """

body, h1, h2, h3, h4, h5, h6 {
  color: black; }

body, input, button, textarea {
  font-family: 'Avenir Next W01', 'Avenir Next', 'Lucida Grande', 'Lucida Sans Unicode', 'Helvetica Neue', Helvetica, Verdana, sans-serif; }

.content {
  position: relative;
  font-size: 16px;
  color: black;
  min-height: 500px; }

.button {
  font-size: 16px; }

.button, button, input[type='submit'] {
  outline: none;
  cursor: pointer;
  text-align: center; }


.flipped {
  -moz-transform: scaleX(-1);
  -o-transform: scaleX(-1);
  -webkit-transform: scaleX(-1);
  transform: scaleX(-1);
  filter: FlipH;
  -ms-filter: 'FlipH'; }

.primary_button, .primary_cancel_button {
  border-radius: 16px;
  text-align: center;
  padding: 3px;
  cursor: pointer; }

.primary_button {
  background-color: #{focus_blue};
  color: white;
  font-size: 29px;
  margin-top: 14px;
  box-shadow: 0px 1px 0px black;
  border: none;
  padding: 8px 36px; }

.primary_button.disabled {
  background-color: #eeeeee;
  color: #cccccc;
  box-shadow: none;
  border: none;
  cursor: wait; }

a.primary_cancel_button {
  color: #888888;
  margin-top: 0.5em; }

a.cancel_opinion_button {
  float: right;
  margin-top: 0.5em; }

button.primary_button, input[type='submit'] {
  display: inline-block; }

"""
