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
# Helpers

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

# Handles router navigation for links so that a page reload doesn't happen
window.clickInternalLink = (event) ->
  href = $(event.currentTarget).attr('href')

  # Allow shift+click for new tabs, etc.
  if !event.altKey && !event.ctrlKey && !event.metaKey && !event.shiftKey
    event.preventDefault()
    # Instruct Backbone to trigger routing events
    window.app_router.navigate href, { trigger : true }
    return false

# Computes the width of some text given some styles empirically
window.realWidth = (str, style) -> 
  $el = $("<span id='width_test'>#{str}</span>").css(style)
  $('#content').append($el)
  width = $('#width_test').width()
  $('#width_test').remove()
  width


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
            display: if @root.show_wyswyg_toolbar == @props.key then 'block' else 'none'

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
            # show_wyswyg_toolbar is global state for the toolbar to be 
            # shown. It gets set to null when someone clicks outside the 
            # editor area. This is handled at the root level
            # in the same way that clicking outside a point closes it. 
            # See Root.resetSelection.
            @root.show_wyswyg_toolbar = @props.key; save(@root)
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

.primary_button, .primary_cancel_button {
  border-radius: 16px;
  text-align: center;
  padding: 3px;
  cursor: pointer; }

.primary_button {
  background-color: #{considerit_blue};
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

button.primary_button, input[type="submit"] {
  display: inline-block; }

"""
