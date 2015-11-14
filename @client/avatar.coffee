require './shared'
require './tooltip'


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
document.addEventListener "mouseover", (e) ->
  if e.target.getAttribute('data-user') && e.target.getAttribute('data-showtooltip') == 'true'
    user = fetch(e.target.getAttribute('data-user'))

    name = user_name user, e.target.getAttribute('data-anonymous') == 'true'

    tooltip = fetch 'tooltip'
    tooltip.coords = $(e.target).offset()
    tooltip.tip = name
    save tooltip

document.addEventListener "mouseout", (e) ->
  if e.target.getAttribute('data-user') && e.target.getAttribute('data-showtooltip') == 'true'
    tooltip = fetch 'tooltip'
    tooltip.coords = null
    save tooltip

##
# Avatar
# Displays a user's avatar
#
# We primarily download all avatar images as part of a CSS file specifying a 
# b64 encoded background-image small 50x50 thumbnails for each user 
# (under #avatar-{id}). 
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
#   img_size (default = 'thumb')
#      The size of the embedded image. 'thumb' or 'large' or 'original'
#   hide_tooltip (default = false)
#      Suppress the tooltip on hover. 
#   anonymous (default = false)
#      Don't show a real picture and show "anonymous" in the tooltip. 


window.Avatar = ReactiveComponent
  displayName: 'Avatar'
  
  render : ->
    anonymous = @props.anonymous? && @props.anonymous 

    user = @data()

    id = if anonymous 
           "avatar-hidden" 
         else 
           "avatar-#{user.key.split('/')[2]}"

    style = _.extend {}, @props.style
    img_size = @props.img_size or 'thumb'

    show_avatar = !anonymous && !!user.avatar_file_name
    # Automatically upgrade the avatar size to 'large' if the width of the image is 
    # greater than the size of the b64 encoded image
    if img_size == 'thumb' && style?.width >= 50 && !browser.is_ie9
      img_size = 'large' 
    # ...but we only use a larger image if this user actually has one and isn't anonymous
    use_large_image = img_size != 'thumb' && show_avatar

    if use_large_image
      @props.src = avatarUrl user, img_size
    else

      current_user = fetch('/current_user')
      if current_user.user == user.key
        thumbnail = current_user.b64_thumbnail
        if thumbnail? && img_size == 'thumb' 
          @props.src = thumbnail
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

    attrs =
      className: "avatar #{@props.className or ''}"
      id: id
      'data-user': user.key
      'data-showtooltip': !@props.hide_tooltip
      'data-anon': anonymous      
      style: style


    # IE9 gets confused if there is an image without a src
    tag = if !thumbnail? && browser.is_ie9 && img_size == 'thumb' || add_initials then SPAN else IMG


    @transferPropsTo tag attrs,
      if add_initials
        name = user_name user, anonymous
        if name == 'Anonymous'
          name = '?'
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
            top: style.height / 2 - heightWhenRendered(name, {fontSize: fontsize, fontFamily: ff}) / 2

          name
          

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
window.Avatars = ReactiveComponent
  displayName: 'Avatars'
  render: -> 
    avatars = fetch('/avatars')

    STYLE 
      type: 'text/css'
      id: 'b64-avatars'
      dangerouslySetInnerHTML: 
        __html: if avatars.avatars then avatars.avatars else ''

