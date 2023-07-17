require './shared'
require './popover'
require './customizations'
require './murmurhash'

# globally accessible method for getting the URL of a user's avatar
window.avatarUrl = (user, img_size) -> 
  user = fetch(user)
  if user.avatar_file_name.endsWith('svg') 
    img_size = 'original' # paperclip mangles svg files

  if !!user.avatar_file_name
    app = arest.cache['/application'] or fetch('/application')
    (app.asset_host or '') + \
          "/system/avatars/" + \
          "#{user.key.split('/')[2]}/#{img_size}/#{user.avatar_file_name}"  
  else 
    null


window.user_is_organization_account = (user) -> 
  (user.key or user) in (customization('organizational_account') or [])

window.anonymous_label = ->
  translator 'anonymous', 'Anonymous'

user_name = (user, anon) -> 
  user = fetch user
  if !user.name || user.name.trim().length == 0 
    anonymous_label() 
  else 
    user.name



window.AvatarPopover = ReactiveComponent
  displayName: 'AvatarPopover' 

  render: -> 
    {user, anon, opinion} = @props
    user = fetch user
    anonymous = arest.key_id(user.key) < 0 or anon
    opinion_views = fetch 'opinion_views'


    name = user_name user, anonymous

    has_opinion = opinion?
    if has_opinion
      opinion = fetch(opinion)    
      stance = opinion.stance 
      if stance > .01
        alt = "#{(stance * 100).toFixed(0)}%"
      else if stance < -.01
        alt = "–#{(stance * -100).toFixed(0)}%"
      else 
        alt = translator "engage.histogram.user_is_neutral", "is neutral"

    DIV 
      style: 
        padding: '8px 4px'
        position: 'relative'
        maxWidth: "min(80vw, 800px)"


      DIV 
        style: 
          display: 'flex'
          # alignItems: 'center'

        if user.avatar_file_name
          IMG 
            alt: @props.alt or alt or "Image of #{if anonymous then 'Image of an anonymous user "#{user.name}"' else user.name}"
            style: 
              width: 120
              height: 120
              borderRadius: '50%'
              marginRight: 24
              display: 'inline-block' 
            src: if anonymous then user.avatar_file_name else avatarUrl user, 'large'


        DIV null,
          

          DIV 
            style:
              letterSpacing: -1
              fontSize: 18  
              fontWeight: 'bold'       
            name


          if get_participant_attributes? && !anonymous && !user_is_organization_account(user)
            attributes = get_participant_attributes()
            grouped_by = opinion_views.active_views.group_by

            unreported = missing_attribute_info_label()

            UL 
              style:
                listStyle: 'none'
                marginTop: 4

              for attribute in attributes
                is_grouped = grouped_by && grouped_by.name == attribute.name


                if attribute.pass 
                  user_val = attribute.pass(user)
                  user_val ?= unreported
                  if typeof user_val == "string" && user_val?.indexOf CHECKLIST_SEPARATOR > -1 
                    user_val = user_val.split(CHECKLIST_SEPARATOR)          
                  else 
                    user_val = ["#{user_val}"]
                else 
                  user_val = user.tags[attribute.key] 
                  user_val ?= unreported

                  if typeof user_val == "string" && user_val?.indexOf CHECKLIST_SEPARATOR > -1 
                    user_val = user_val.split(CHECKLIST_SEPARATOR)
                  else if is_grouped
                    user_val = [user_val]

                continue if !is_grouped && !user_val

                

                LI 
                  key: attribute.name
                  style: 
                    padding: '3px 0'

                  DIV 
                    key: 'attribute name'
                    style: 
                      # letterSpacing: -1
                      fontSize: 14
                      fontStyle: 'italic'
                      # display: 'inline-block'
                      # paddingRight: 8 
                      # textTransform: 'uppercase'   
                      # color: '#555'              
                    attribute.name 

                  for val in user_val

                    SPAN 
                      key: val or unreported
                      style: 
                        fontSize: 14
                        backgroundColor: if is_grouped then get_color_for_group(val or unreported)
                        color: if is_grouped then 'white'
                        display: 'inline-block'
                        marginRight: 8
                        padding: if is_grouped then '2px 8px'
                      val or unreported
      if has_opinion
        inclusions = opinion.point_inclusions or []
        cnt = inclusions.length
        toggle_reasons = (e) =>
          @local.show_reasons = !@local.show_reasons
          save @local
          popover = fetch 'popover'
          popover.hide_triangle = @local.show_reasons
          save popover
          e.stopPropagation()
          e.preventDefault()

        o_trans = translator('opinion', 'Opinion')
        reasons_trans = translator {id: 'avatar_popover.reason_count', cnt: cnt}, '{cnt, plural, one {# reason} other {# reasons}} given'

        DIV 
          style: 
            marginTop: 8 
          DIV 
            style: 
              fontWeight: 'bold' 
              textAlign: 'center'
            
            "#{o_trans}: #{alt} • #{reasons_trans}"                      


            if cnt > 0
              BUTTON
                tabIndex: 1
                className: 'like_link'
                style: 
                  paddingLeft: 8 
                  # color: focus_color()
                onClick: toggle_reasons
                if @local.show_reasons                 
                  translator 'avatar_popover.hide_reasons', 'Hide reasons'
                else 
                  translator 'avatar_popover.show_reasons', 'Show reasons'

          if @local.show_reasons
            UL 
              style: 
                listStyle: 'none'
                margin: '12px auto'
              for reason in inclusions
                point = fetch reason 

                LI 
                  style: 
                    paddingTop: 12
                    maxWidth: 450
                    borderRadius: 16
                    padding: '0.5em 16px'
                    backgroundColor: '#f6f7f9'
                    boxShadow: '#b5b5b5 0 1px 1px 0px'
                    margin: '0px 16px 12px 16px'

                  SPAN 
                    style: 
                      textTransform: 'uppercase'
                      color: '#555'
                      paddingRight: 8
                    if point.is_pro 
                      get_point_label 'pro'
                    else 
                      get_point_label 'con'
                    ':'

                  SPAN 
                    style: {}
                    point.nutshell

                  SPAN 
                    style: 
                      fontStyle: 'italic'
                      marginLeft: 12
                    "~ #{fetch(point.user).name}"



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
#   hide_popover (default = false)
#      Suppress the popover on hover. 
#   anonymous (default = false)
#      Don't show a real picture and show "anonymous" in the popover. 


props_to_strip = ['user', 'anonymous', 'set_bg_color', 'custom_bg_color', 'hide_popover', 'parents', 'img_size']
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

  style = {}
  if attrs.style
    for k,v of attrs.style
      style[k] = v

  # Setting avatar image
  #   Don't show one if it should be anonymous or the user doesn't have one
  #   Default to small size if the width is small 
  anonymous = attrs.anonymous || (user && arest.key_id(user.key) < 0)
  src = null

  if !props.custom_bg_color && user.avatar_file_name   
    if style?.width >= 50
      img_size = 'large'
    else 
      img_size = attrs.img_size or 'small'

    if anonymous
      src = user.avatar_file_name
    else  
      src = avatarUrl user, img_size

    # Override the gray default avatar color if we're showing an image. 
    # In most cases the white will allow for a transparent look. It 
    # isn't set to transparent because a transparent icon in many cases
    # will reveal content behind it that is undesirable to show.  
    style.backgroundColor = 'white'

  else if props.set_bg_color && !props.custom_bg_color 
    user.bg_color ?= hsv2rgb(Math.random() / 5 + .6, Math.random() / 8 + .025, Math.random() / 4 + .4)
    style.backgroundColor = user.bg_color

  name = user_name user, anonymous

  if attrs.alt 
    alt = attrs.alt.replace('<user>', name) 
  else 
    alt = name 

  attrs = _.extend attrs,
    key: user.key
    className: "avatar #{props.className or ''}"
    'data-user': if anonymous then -1 else user.key
    'data-popover': if !props.hide_popover && !anonymous && !screencasting() then alt 
    'data-tooltip': if anonymous then alt
    'data-anon': anonymous  
    tabIndex: if props.focusable then 0 else -1
    width: style?.width
    height: style?.width
    style: style

  for prop_to_strip in props_to_strip
    if prop_to_strip of attrs
      delete attrs[prop_to_strip]

  if src
    # attrs.alt = if props.hide_popover then '' else popover 
    # the above fails too much on broken images, and 
    # screenreaders would probably be overwhelmed with saying all these stances.
    # If in future it turns out we want alt text for accessibility, we can address
    # the broken text ugliness by using img { text-indent: -10000px } to 
    # hide the alt text / broken image
    attrs.src = src
    IMG attrs
  else 
    # IE9 gets confused if there is an image without a src
    # Chrome puts a weird gray border around IMGs without a src
    SPAN attrs
  




window.Avatar = ReactiveComponent
  displayName: 'Avatar'
  
  render : ->
    avatar @data(), @props 

       

styles += """
.avatar {
  position: relative; /* for containing the :after image */
  border: none;
  display: inline-block;
  margin: 0;
  padding: 0;
  border-radius: 50%;
  background-size: cover;
  background-color: #{default_avatar_in_histogram_color}; 
  transition: width 750ms, height 750ms, transform 750ms, background-color 750ms, opacity 50ms;
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






cached_avatars = {}
missing_images = {}
loaded_images = {}
users2images = {}

window.getCanvasAvatar = (user) ->
  key = user.key or user

  cached_avatars[key] or cached_avatars.default


colors_used = {}
window.createHitRegionAvatar = (user) -> 
  
  while !color? || color of colors_used
    r = Math.round(Math.random() * 255)
    g = Math.round(Math.random() * 255)
    b = Math.round(Math.random() * 255)
    color = "rgb(#{r},#{g},#{b})"
  colors_used[color] = true

  user.hit_region_color = color
  createUserIcon user.hit_region_color


group_colored_icons = {}
window.getGroupIcon = (key, color) ->
  if key not of group_colored_icons
    group_colored_icons[key] = createUserIcon color
  group_colored_icons[key]

# Note: this is actually kinda expensive on large forums, in memory and cpu
icon_cache = {}
createUserIcon = (fill) ->
  if fill of icon_cache
    return icon_cache[fill]

  # create a gray-ish avatar for folks who don't have an avatar (or if its broken)
  # Note: this is actually kinda expensive on large forums, in memory and cpu
  canv = document.createElement('canvas')
  canv.width = canv.height = 50 * window.devicePixelRatio
  rx = canv.width / 2
  ctx = canv.getContext("2d")
  ctx.arc(rx, rx, rx, 0, 2 * Math.PI)            
  ctx.fillStyle = fill
  ctx.fill()
  icon_cache[fill] = canv

  canv

window.getCompositeGroupIcon = (key, groups, colors) -> 
  if key not of group_colored_icons
    group_colored_icons[key] = createCompositeGroupIcon groups, colors
  group_colored_icons[key]

createCompositeGroupIcon = (groups, colors) -> 
  num = groups.length

  canv = document.createElement('canvas')
  canv.width = canv.height = 50 * window.devicePixelRatio
  rx = canv.width / 2
  ctx = canv.getContext("2d")

  for group, idx in groups
    color = colors[group]
    # ctx.save()
    ctx.beginPath()
    ctx.moveTo(rx,rx)
    ctx.arc rx, rx, rx, idx * 2 * Math.PI / num, (idx + 1) * 2 * Math.PI / num
    ctx.fillStyle = color
    ctx.fill()
    # ctx.restore()
  canv


createFallbackIcon = (user) ->
  if !user.bg_color?
    h = Math.random() / 5 + .6
    s = Math.random() / 8 + .025
    v = Math.random() / 4 + .4
    h = Math.round(h * 15) / 15
    s = Math.round(s * 15) / 15
    v = Math.round(v * 15) / 15 
    user.bg_color = hsv2rgb(h,s,v)  # create a gray-ish avatar for folks who don't have an avatar (or if its broken)

  createUserIcon user.bg_color


create_avatar = (img) -> 
  canv = document.createElement('canvas')
  canv.width = img.width
  canv.height = img.height
  ctx = canv.getContext('2d')

  ctx.arc(img.width / 2, img.height / 2, img.height / 2, 0, Math.PI * 2)
  ctx.clip()

  ctx.drawImage img, 0, 0
  canv

window.LoadAvatars = ReactiveComponent
  displayName: "LoadAvatars" 
  render: ->
    users = fetch '/users'
    loading = fetch('avatar_loading')
    SPAN null

  load: -> 
    users = fetch '/users'
    current_user = fetch '/current_user'  # subscribe for changes to login status & avatar
    return if !users.users || fetch('location').url.match('/dashboard')

    loading = fetch('avatar_loading')
    app = arest.cache['/application'] or fetch('/application')

    avatars_to_load = {}
    all_users = users.users.slice() or []
    if current_user.user not in all_users
      all_users.push current_user.user

    if !cached_avatars.default
      cached_avatars.default = createFallbackIcon({key: 'default'})

    for user in all_users
      user = fetch user # subscribe to changes to avatar
      id = arest.key_id(user.key)

      if user.avatar_file_name
        if id < 0
          img_url = user.avatar_file_name
        else
          img_url = avatarUrl(user, 'large')

        if (users2images[user.key] != img_url ||
           img_url not of loaded_images) && \
           img_url not of missing_images
           
          avatars_to_load[img_url] ?= []
          avatars_to_load[img_url].push user 
          users2images[user.key] = img_url

      cached_avatars[user.key] ?= createFallbackIcon(user)

    if Object.keys(avatars_to_load).length > 0 
      if !loading.loading
        loading.loading = true 
        save loading 

        @loading_cnt = 0

        for img, users of avatars_to_load
          @loading_cnt += 1

          pic = new Image()
          pic.onload = do(img, users, pic) => => 
            cached_avatar = create_avatar pic
            for user in users
              loaded_images[img] = cached_avatars[user.key] = cached_avatar
            @loading_cnt -= 1
            if @loading_cnt == 0
              loading.loading = false
              loading.loaded = murmurhash "#{JSON.stringify(Object.keys(loaded_images))}-#{JSON.stringify((u.name for u in avatars_to_load))}", 0
              save loading
          pic.onerror = do(user) => =>
            @loading_cnt -= 1
            missing_images[user.avatar_file_name] = 1

          pic.src = img
      else 
        setTimeout @load, 10   

  componentDidMount: -> @load()
  componentDidUpdate: -> @load()