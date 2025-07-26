require './shared'
require './popover'
require './customizations'
require './murmurhash'

# globally accessible method for getting the URL of a user's avatar
window.avatarUrl = (user, img_size) -> 
  user = bus_fetch(user)
  if user.avatar_file_name.endsWith('svg') 
    img_size = 'original' # paperclip mangles svg files

  if !!user.avatar_file_name
    app = arest.cache['/application'] or bus_fetch('/application')
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
  user = bus_fetch user
  if !user.name || user.name.trim().length == 0 
    anonymous_label() 
  else 
    user.name



window.AvatarPopover = ReactiveComponent
  displayName: 'AvatarPopover' 

  render: -> 
    {user, anon, opinion} = @props
    user = bus_fetch user
    anonymous = arest.key_id(user.key) < 0 or anon or customization('anonymize_permanently')
    opinion_views = bus_fetch 'opinion_views'


    name = user_name user, anonymous

    has_opinion = opinion?
    if has_opinion
      opinion = bus_fetch(opinion)    
      stance = opinion.stance 
      if stance > .01
        alt = "#{(stance * 100).toFixed(0)}%"
      else if stance < -.01
        alt = "–#{(stance * -100).toFixed(0)}%"
      else 
        alt = translator "engage.histogram.user_is_neutral", "is neutral"

      anonymous ||= opinion.hide_name

    pixelate_anon_current_user = user.key == bus_fetch('/current_user').user && anonymous


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
            className: if pixelate_anon_current_user then 'pixelated-avatar'

            style: 
              width: 120
              height: 120
              borderRadius: '50%'
              marginRight: 24
              display: 'inline-block' 
              filter: if pixelate_anon_current_user then "blur(#{.025 * (120)}px)"
            src: if anonymous && !pixelate_anon_current_user then user.avatar_file_name else avatarUrl user, 'large'


        DIV null,
          

          DIV 
            style:
              letterSpacing: -1
              fontSize: 18  
              fontWeight: 'bold'       
            name
          if pixelate_anon_current_user
            I null,

              your_opinion_i18n.anon_assurance()


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
                      fontSize: 14
                      fontStyle: 'italic'

                    attribute.name 

                  for val in user_val

                    SPAN 
                      key: val or unreported
                      style: 
                        fontSize: 14
                        backgroundColor: if is_grouped then get_color_for_group(val or unreported)
                        color: if is_grouped then "var(--text_light)"
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
          popover = bus_fetch 'popover'
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
                point = bus_fetch reason 

                LI 
                  style: 
                    paddingTop: 12
                    maxWidth: 450
                    borderRadius: 16
                    padding: '0.5em 16px'
                    backgroundColor: "var(--bg_speech_bubble)"
                    boxShadow: "var(--shadow_dark_25) 0 1px 1px 0px"
                    margin: '0px 16px 12px 16px'

                  SPAN 
                    style: 
                      textTransform: 'uppercase'
                      color: "var(--text_gray)"
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
                    "~ #{bus_fetch(point.user).name}"



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
      user = bus_fetch(user)
    else if arest.cache[user]
      user = arest.cache[user]
    else 
      bus_fetch user
      return SPAN {key: Math.random()}

  style = {}
  if attrs.style
    for k,v of attrs.style
      style[k] = v

  # Setting avatar image
  #   Don't show one if it should be anonymous or the user doesn't have one
  #   Default to small size if the width is small 
  anonymous = attrs.anonymous || (user && arest.key_id(user.key) < 0) || customization('anonymize_permanently')
  src = null

  if !attrs.custom_bg_color && user.avatar_file_name   
    if style?.width >= 50
      img_size = 'large'
    else 
      img_size = attrs.img_size or 'small'

    if anonymous && user.avatar_file_name.indexOf('/') > -1
      src = user.avatar_file_name
    else  
      src = avatarUrl user, img_size

    # Override the gray default avatar color if we're showing an image. 
    # In most cases the white will allow for a transparent look. It 
    # isn't set to transparent because a transparent icon in many cases
    # will reveal content behind it that is undesirable to show.  
    style.backgroundColor = "var(--bg_item)"

  else if attrs.set_bg_color && !attrs.custom_bg_color 
    user.bg_color ?= hsv2rgb(Math.random() / 5 + .6, Math.random() / 8 + .025, Math.random() / 4 + .4)
    style.backgroundColor = user.bg_color

  name = user_name user, anonymous

  if attrs.alt 
    alt = attrs.alt.replace('<user>', name) 
  else 
    alt = "Image of #{name}" 

  classes = "avatar#{if attrs.className then ' ' + attrs.className else ''}"
  if anonymous 
    if user.key == arest.cache['/current_user']?.user
      classes += " pixelated-avatar"
      style.filter = "blur(#{.025 * (style.width or 50)}px)"

  attrs = _.extend attrs,
    key: user.key
    className: classes
    'data-user': user.key
    "aria-haspopup": 'dialog'
    'data-popover': if !props.hide_popover && !anonymous && !screencasting() then alt 
    'alt': alt     
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
  background-color: var(--bg_light_gray); 
  transition: width 750ms, height 750ms, transform 750ms, background-color 750ms, opacity 50ms;
  user-select: none; 
  -moz-user-select: none; 
  -webkit-user-select: none;
  -ms-user-select: none;
}

/* for styling icon of broken images */
img.avatar:after { 
  position: absolute;
  z-index: 2;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-color: var(--attention_orange); 
  border-radius: 50%;
  content: "";
}


.pixelated-avatar::before {
  content: "?";
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  color: var(--text_dark);
  font-size: 24px;
  font-weight: bold;
}

"""






cached_avatars = {}
cached_anonymous_avatars = {}
missing_images = {}
loaded_images = {}
users2images = {}

window.getCanvasAvatar = (user, anonymous=false) ->
  key = user.key or user

  if anonymous && key == arest.cache['/current_user']?.user
    if key of cached_avatars
      if key not of cached_anonymous_avatars
        cached_anonymous_avatars[key] = create_pixelated_avatar(cached_avatars[key])
      return cached_anonymous_avatars[key]
    else
      return cached_avatars.default

  cached_avatars[key] or cached_avatars.default

group_colored_icons = {}
window.getGroupIcon = (key, color) ->
  if key not of group_colored_icons
    group_colored_icons[key] = createUserIcon color
  group_colored_icons[key]

# Note: this is actually kinda expensive on large forums, in memory and cpu
icon_cache = {}
window.createUserIcon = (fill) ->
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

create_avatar = (img, clip = true) -> 
  canv = document.createElement('canvas')
  canv.width = img.width
  canv.height = img.height
  ctx = canv.getContext('2d')

  if clip
    ctx.arc(img.width / 2, img.height / 2, img.height / 2, 0, Math.PI * 2)
    ctx.clip()

  ctx.drawImage img, 0, 0
  canv.original_image = img
  canv


create_pixelated_avatar = (canv, showQuestionMarkOverlay = false) ->
  return cached_avatars.default if !canv.original_image
  
  anon_canv = create_avatar(canv.original_image, false)

  w = anon_canv.width
  h = anon_canv.height

  ctx = anon_canv.getContext('2d')

  # Apply anonymization technique: pixelate
  pixelSize = w / 10  # Adjust the pixel size as desired
  tempCanvas = document.createElement('canvas')
  tempCanvas.width = w / pixelSize
  tempCanvas.height = h / pixelSize
  tempCtx = tempCanvas.getContext('2d')

  tempCtx.imageSmoothingEnabled = false
  tempCtx.drawImage(anon_canv, 0, 0, w / pixelSize, h / pixelSize)

  ctx.drawImage(tempCanvas, 0, 0, w / pixelSize, h / pixelSize, 0, 0, w, h)

  # Apply question_mark overlay if requested
  if showQuestionMarkOverlay
    size = w / 2
    ctx.drawImage(my_question_mark_icon, w / 2 - size / 2, h / 2 - size / 2, size, size)

  canv = document.createElement('canvas')
  canv.width = w
  canv.height = h
  ctx = canv.getContext('2d')

  ctx.arc(w / 2, h / 2, h / 2, 0, Math.PI * 2)
  ctx.clip()

  ctx.drawImage(anon_canv, 0, 0)

  canv


question_mark_icon = () ->
  # Set the desired size of the question_mark icon
  iconWidth = 24
  iconHeight = 24

  qm_canv = document.createElement('canvas')
  qm_canv.width = iconWidth
  qm_canv.height = iconHeight
  qm_ctx = qm_canv.getContext('2d')


  # SVG path data for the question_mark icon
  svgPath1 = "M9.11241 7.82201C9.44756 6.83666 10.5551 6 12 6C13.7865 6 15 7.24054 15 8.5C15 9.75946 13.7865 11 12 11C11.4477 11 11 11.4477 11 12L11 14C11 14.5523 11.4477 15 12 15C12.5523 15 13 14.5523 13 14L13 12.9082C15.203 12.5001 17 10.7706 17 8.5C17 5.89347 14.6319 4 12 4C9.82097 4 7.86728 5.27185 7.21894 7.17799C7.0411 7.70085 7.3208 8.26889 7.84366 8.44673C8.36653 8.62458 8.93457 8.34488 9.11241 7.82201ZM12 20C12.8285 20 13.5 19.3284 13.5 18.5C13.5 17.6716 12.8285 17 12 17C11.1716 17 10.5 17.6716 10.5 18.5C10.5 19.3284 11.1716 20 12 20Z"
  # svgPath2 = "M13.2271 16.9535C13.2271 17.6313 12.6777 18.1807 11.9999 18.1807C11.3221 18.1807 10.7726 17.6313 10.7726 16.9535C10.7726 16.2757 11.3221 15.7262 11.9999 15.7262C12.6777 15.7262 13.2271 16.2757 13.2271 16.9535Z"

  # Draw the question_mark icon onto the question_mark canvas
  qm_ctx.fillStyle = "var(--bg_dark)"
  qm_ctx.strokeStyle = "var(--text_light)"
  qm_ctx.lineWidth = 1

  path1 = new Path2D(svgPath1)

  qm_ctx.fill(path1)
  qm_ctx.stroke(path1)

  qm_canv

my_question_mark_icon = question_mark_icon()




window.LoadAvatars = ReactiveComponent
  displayName: "LoadAvatars" 
  render: ->
    users = bus_fetch '/users'
    loading = bus_fetch('avatar_loading')
    SPAN null

  load: (timeout_len) -> 
    users = bus_fetch '/users'
    current_user = bus_fetch '/current_user'  # subscribe for changes to login status & avatar
    return if !users.users || bus_fetch('location').url.match('/dashboard')

    loading = bus_fetch('avatar_loading')

    app = arest.cache['/application'] or bus_fetch('/application')

    avatars_to_load = {}
    all_users = users.users.slice() or []
    if current_user.user not in all_users
      all_users.push current_user.user

    if !cached_avatars.default
      cached_avatars.default = createFallbackIcon({key: 'default'})

    for user in all_users
      user = bus_fetch user # subscribe to changes to avatar
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
        setTimeout => 
          @load(timeout_len * 2)
        , timeout_len

  componentDidMount: -> @load(10)
  componentDidUpdate: -> @load(10)