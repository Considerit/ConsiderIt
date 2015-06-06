require './shared'
require './tooltip'


# globally accessible method for getting the URL of a user's avatar
window.avatarUrl = (user, img_size) -> 
  user = fetch(user)
  (fetch('/application').asset_host or '') + \
        "/system/avatars/" + \
        "#{user.key.split('/')[2]}/#{img_size}/#{user.avatar_file_name}"  


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
    @props.anonymous = @props.anonymous? && @props.anonymous 

    user = @data()

    id = if @props.anonymous 
           "avatar-hidden" 
         else 
           "avatar-#{user.key.split('/')[2]}"

    style = _.extend {}, @props.style
    img_size = @props.img_size or 'thumb'

    show_avatar = !@props.anonymous && !!user.avatar_file_name
    # Automatically upgrade the avatar size to 'large' if the width of the image is 
    # greater than the size of the b64 encoded image
    if img_size == 'thumb' && style?.width > 50 && !browser.is_ie9
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
      
    attrs =
      className: "avatar #{@props.className or ''}"
      id: id
      style: style
      onMouseEnter: => 
        if !@props.hide_tooltip
          name = if @props.anonymous || user.name?.length == 0 
                   'Anonymous' 
                 else 
                   user.name
          tooltip = fetch 'tooltip'
          tooltip.coords = $(@getDOMNode()).offset()
          tooltip.tip = name
          save tooltip
      onMouseLeave: => 
        if !@props.hide_tooltip      
          tooltip = fetch 'tooltip'
          tooltip.coords = null
          save tooltip

    # IE9 gets confused if there is an image without a src
    tag = if !thumbnail? && browser.is_ie9 && img_size == 'thumb' then SPAN else IMG

    @transferPropsTo tag attrs

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


# Fetches avatar definitions and puts them in a style sheet
window.Avatars = ReactiveComponent
  displayName: 'Avatars'
  render: -> 
    avatars = fetch('/avatars')

    STYLE 
      type: 'text/css'
      id: 'b64-avatars'
      dangerouslySetInnerHTML: 
        __html: if avatars.avatars then avatars.avatars else ''

