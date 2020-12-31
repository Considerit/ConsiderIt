require './shared'
require './tooltip'
require './customizations'


# globally accessible method for getting the URL of a user's avatar
window.avatarUrl = (user, img_size) -> 
  user = fetch(user)
  (fetch('/application').asset_host or '') + \
        "/system/avatars/" + \
        "#{user.key.split('/')[2]}/#{img_size}/#{user.avatar_file_name}"  



user_name = (user, anon) -> 
  user = fetch user
  if anon || !user.name || user.name.trim().length == 0 
    'Anonymous' 
  else 
    user.name

##########
# Performance hack.
# Was seeing major slowdown on pages with lots of avatars simply because we
# were attaching a mouseover and mouseout event on each and every Avatar for
# the purpose of showing a tooltip name. So we use event delegation instead. 
show_tooltip = (e) ->
  if e.target.getAttribute('data-user') && e.target.getAttribute('data-tooltip')
    user = fetch(e.target.getAttribute('data-user'))
    anonymous = e.target.getAttribute('data-anonymous') == 'true'

    current_user = fetch('/current_user')
    name = e.target.getAttribute('data-tooltip')
    # if name.indexOf(', ') > -1 
    #   updated = ''
    #   for part in name.split(', ')
    #     updated += "<p>#{part}</p>"
    #   name = updated
      
    if !anonymous && (filters = customization('opinion_filters')) 
      for filter in filters when (filter.visibility == 'open' || current_user.is_admin)
        if filter.icon && filter.pass(user)
          if typeof(filter.icon) != 'string'
            icon = filter.icon(user)
          else
            icon = filter.icon 
          name += '<div style="font-style: italic; padding: 4px 0 0 0px">' + icon + "</div>"

    tooltip = fetch 'tooltip'
    tooltip.coords = $(e.target).offset()
    tooltip.tip = name
    save tooltip
    e.preventDefault()

hide_tooltip = (e) ->
  if e.target.getAttribute('data-user') && e.target.getAttribute('data-tooltip')
    if e.target.getAttribute('data-title')
      e.target.setAttribute('title', e.target.getAttribute('data-title'))
      e.target.removeAttribute('data-title')

    tooltip = fetch 'tooltip'
    tooltip.coords = null
    save tooltip



document.addEventListener "mouseover", show_tooltip
document.addEventListener "mouseout", hide_tooltip

$('body').on 'focusin', '.avatar', show_tooltip
$('body').on 'focusout', '.avatar', hide_tooltip

# focus/blur don't seem to work at document level
# document.addEventListener "focus", show_tooltip, true
# document.addEventListener "blur", hide_tooltip, true


##
# Avatar
# Displays a user's avatar
#
# Higher resolution images are available ('large' and 'original'). These can 
# be specified by setting the img_size property of Avatar.
#
# Additionally, Avatar will automatically upgrade the image resolution if 
# the style specifies a width greater than the size of the thumbnails. 
#
# Avatar will output either a SPAN or IMG. The choice of which tag is used 
# is fraught based upon the browser and how React replaces elements. In the 
# future we can refactor this for a cleaner implementation.
#
# Properties set on Avatar will be transferred to the outputted SPAN or IMG.
#
# Props
#   img_size (default = 'small')
#      The size of the embedded image. 'small' or 'large' or 'original'
#   hide_tooltip (default = false)
#      Suppress the tooltip on hover. 
#   anonymous (default = false)
#      Don't show a real picture and show "anonymous" in the tooltip. 


window.avatar = (user, props) ->
  props = _.extend {}, props

  if !user.key 
    if user == arest.cache['/current_user']?.user 
      user = fetch(user)
    else if arest.cache[user]
      user = arest.cache[user]
    else 
      fetch user
      return SPAN null

  anonymous = props.anonymous? && props.anonymous 

  id = if anonymous 
         "avatar-hidden" 
       else 
         "avatar-#{user.key.split('/')[2]}"

  style = _.extend {}, props.style
  img_size = props.img_size or 'small'

  show_avatar = !anonymous && !!user.avatar_file_name
  # Automatically upgrade the avatar size to 'large' if the width of the image is 
  # greater than the size of the b64 encoded image
  if img_size == 'small' && style?.width >= 50 && !browser.is_ie9
    img_size = 'large' 
  # ...but we only use a larger image if this user actually has one and isn't anonymous
  use_large_image = img_size != 'small' && show_avatar

  if use_large_image
    props.src = avatarUrl user, img_size
  else if show_avatar
    props.src = avatarUrl user, img_size
  else
    current_user = fetch('/current_user')
    if current_user.user == user.key
      thumbnail = current_user.b64_thumbnail
      if !thumbnail && user.avatar_file_name
         thumbnail = avatarUrl(user,'small')
      
      if thumbnail? && img_size == 'small' 
        props.src = thumbnail
    else
      # prevents a weird webkit outlining issue
      # http://stackoverflow.com/questions/4743127
      style.content = "''" 

  # Override the gray default avatar color if we're showing an image. 
  # In most cases the white will allow for a transparent look. It 
  # isn't set to transparent because a transparent icon in many cases
  # will reveal content behind it that is undesirable to show.  
  style.backgroundColor = 'white' if show_avatar

  add_initials = false && !user.avatar_file_name && style.width > 8
  
  if add_initials
    style.textAlign = 'center'


  # IE9 gets confused if there is an image without a src
  # Chrome puts a weird gray border around IMGs without a src
  tag = if !props.src? then SPAN else IMG

  name = user_name user, anonymous
  alt = props.alt 
  delete props.alt if props.alt? 
  tooltip = alt?.replace('<user>', name) or name

  attrs = _.extend {}, props,
    key: user.key
    className: "avatar #{props.className or ''}"
    'data-user': user.key
    'data-tooltip': if !props.hide_tooltip then tooltip 
    'data-anon': anonymous  
    style: style
    tabIndex: if props.focusable then 0 else -1

  if tag == IMG
    # attrs.alt = if props.hide_tooltip then '' else tooltip 
    # the above fails too much on broken images, and 
    # screenreaders would probably be overwhelmed with saying all these stances.
    # If in future it turns out we want alt text for accessibility, we can address
    # the broken text ugliness by using img { text-indent: -10000px } to 
    # hide the alt text / broken image
    attrs.alt = ""
  
  tag attrs,
    if add_initials
      fontsize = style.width / 2
      ff = 'monaco,Consolas,"Lucida Console",monospace'
      if name == 'Anonymous'
        name = '?'

      if name.length == 2
        name = "#{name[0][0]}#{name[1][0]}"
      else 
        name = "#{name[0][0]}"

      DIV
        style: 
          color: 'white'
          pointerEvents: 'none'
          fontSize: fontsize
          position: 'relative'
          fontFamily: ff
          top: .3 * fontsize #style.height / 2 - heightWhenRendered(name, {fontSize: fontsize, fontFamily: ff}) / 2
          overflow: 'hidden'
        name

        DIV 
          className: 'hidden'
          tooltip




window.Avatar = ReactiveComponent
  displayName: 'Avatar'
  
  render : ->
    avatar @data(), @props 

       

styles += """
.avatar {
  position: relative;
  vertical-align: top;
  background-color: transparent;
  border: none;
  display: inline-block;
  margin: 0;
  padding: 0;
  border-radius: 50%;
  background-size: cover;
  background-color: #{default_avatar_in_histogram_color}; 
  user-select: none; 
  -moz-user-select: none; 
  -webkit-user-select: none;
  -ms-user-select: none;}
  .avatar.avatar_anonymous {
    cursor: default; 
}
/* for styling icon of broken images */
img.avatar:after { 
  position: absolute;
  z-index: 2;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-color: #f7954c; 
  border-radius: 50%;
  content: "";
}

"""
