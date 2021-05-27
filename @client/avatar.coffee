require './shared'
require './tooltip'
require './customizations'


# globally accessible method for getting the URL of a user's avatar
window.avatarUrl = (user, img_size) -> 
  user = fetch(user)
  if !!user.avatar_file_name
    (fetch('/application').asset_host or '') + \
          "/system/avatars/" + \
          "#{user.key.split('/')[2]}/#{img_size}/#{user.avatar_file_name}"  
  else 
    null


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
  attrs = _.clone props

  if !user.key 
    if user == arest.cache['/current_user']?.user 
      user = fetch(user)
    else if arest.cache[user]
      user = arest.cache[user]
    else 
      fetch user
      return SPAN null

  attrs.style ||= {}
  style = attrs.style

  # Setting avatar image
  #   Don't show one if it should be anonymous or the user doesn't have one
  #   Default to small size if the width is small  
  anonymous = attrs.anonymous? && attrs.anonymous 
  src = null
  if !anonymous && user.avatar_file_name 
    if style?.width >= 50 && !browser.is_ie9
      img_size = 'large'
    else 
      img_size = attrs.img_size or 'small'

    src = avatarUrl user, img_size

    # Override the gray default avatar color if we're showing an image. 
    # In most cases the white will allow for a transparent look. It 
    # isn't set to transparent because a transparent icon in many cases
    # will reveal content behind it that is undesirable to show.  
    style.backgroundColor = 'white'

  id = if anonymous 
         "avatar-hidden" 
       else 
         "avatar-#{user.key.split('/')[2]}"

  name = user_name user, anonymous

  if attrs.alt 
    alt = attrs.alt.replace('<user>', name) 
    delete attrs.alt
  else 
    alt = name 

  attrs = _.extend attrs,
    key: user.key
    className: "avatar #{props.className or ''}"
    'data-user': user.key
    'data-tooltip': if !props.hide_tooltip then alt 
    'data-anon': anonymous  
    tabIndex: if props.focusable then 0 else -1

  if src
    # attrs.alt = if props.hide_tooltip then '' else tooltip 
    # the above fails too much on broken images, and 
    # screenreaders would probably be overwhelmed with saying all these stances.
    # If in future it turns out we want alt text for accessibility, we can address
    # the broken text ugliness by using img { text-indent: -10000px } to 
    # hide the alt text / broken image
    attrs.alt = ""
    attrs.src = src
    IMG attrs
  else 
    # IE9 gets confused if there is an image without a src
    # Chrome puts a weird gray border around IMGs without a src
    attrs.style.backgroundColor ?= 'transparent'
    SPAN attrs
  




window.Avatar = ReactiveComponent
  displayName: 'Avatar'
  
  render : ->
    avatar @data(), @props 

       

styles += """
.avatar {
  position: relative;
  vertical-align: top;
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
  -ms-user-select: none;
}
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
