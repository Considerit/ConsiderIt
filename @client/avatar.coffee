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
  if e.target.getAttribute('data-user') && e.target.getAttribute('data-showtooltip') == 'true'
    user = fetch(e.target.getAttribute('data-user'))
    anonymous = e.target.getAttribute('data-anonymous') == 'true'

    name = user_name user, anonymous

    if !anonymous && filters = customization 'opinion_filters'
      for filter in filters 
        if filter.pass(user) && filter.icon
          if typeof(filter.icon) != 'string'
            icon = filter.icon(user)
          else
            icon = filter.icon 
          name += '<span style="padding: 0 0 0 12px">' + icon + "</span>"


    tooltip = fetch 'tooltip'
    tooltip.coords = $(e.target).offset()
    tooltip.tip = name
    save tooltip

hide_tooltip = (e) ->
  if e.target.getAttribute('data-user') && e.target.getAttribute('data-showtooltip') == 'true'
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

  add_initials = !user.avatar_file_name
  
  if add_initials
    style.textAlign = 'center'

  name = user_name user, anonymous
  if name == 'Anonymous'
    name = '?'

  attrs = _.extend {}, props,
    className: "avatar #{props.className or ''}"
    id: id
    'data-user': user.key
    'data-showtooltip': !props.hide_tooltip
    'data-anon': anonymous      
    style: style
    rel: props.rel?.replace('<user>', name) or name
    tabIndex: if props.focusable then 0 else -1



  # IE9 gets confused if there is an image without a src
  # Chrome puts a weird gray border around IMGs without a src
  tag = if !props.src? then SPAN else IMG


  tag attrs,
    if add_initials
      fontsize = style.width / 2
      ff = 'monaco,Consolas,"Lucida Console",monospace'
      if name.length == 2
        name = "#{name[0][0]}#{name[1][0]}"
      else 
        name = "#{name[0][0]}"

      SPAN 
        style: 
          color: 'white'
          pointerEvents: 'none'
          fontSize: fontsize
          display: 'block'
          position: 'relative'
          fontFamily: ff
          top: .3 * fontsize #style.height / 2 - heightWhenRendered(name, {fontSize: fontsize, fontFamily: ff}) / 2

        name



window.Avatar = ReactiveComponent
  displayName: 'Avatar'
  
  render : ->
    avatar @data(), @props 

       

styles += """
.avatar {
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

"""


# Fetches b64 encoded avatar thumbnails and puts them in a style sheet
# window.Avatars = ReactiveComponent
#   displayName: 'Avatars'
#   render: -> 
#     avatars = fetch('/avatars')

#     STYLE 
#       type: 'text/css'
#       id: 'b64-avatars'
#       dangerouslySetInnerHTML: 
#         __html: if avatars.avatars then avatars.avatars else ''

