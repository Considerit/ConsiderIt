####
# AvatarInput
#
# Manages a file input for uploading (and previewing) an avatar.
#
window.AvatarInput = ReactiveComponent
  displayName: 'AvatarInput'

  render: -> 
    # We're not going to bother with letting IE9 users set a profile picture. Too much hassle. 
    return SPAN(null) if !window.FormData

    # hack for submitting file data in ActiveREST for now
    # we'll just submit the file form after user is signed in

    current_user = fetch '/current_user'
    user = fetch(fetch('/current_user').user)
    @local.preview ?= user.avatar_file_name || current_user.b64_thumbnail || current_user.avatar_remote_url

    img_preview_src =  if @local.newly_uploaded
                          @local.newly_uploaded
                       else if user.avatar_file_name
                          avatarUrl user, 'large'
                       else if current_user.b64_thumbnail 
                          current_user.b64_thumbnail 
                       else if current_user.avatar_remote_url
                          current_user.avatar_remote_url 
                       else 
                          null
    FORM 
      id: 'user_avatar_form'
      action: '/current_user'

      DIV 
        style: 
          height: 60
          width: 60
          borderRadius: '50%'
          backgroundColor: '#e6e6e6'
          overflow: 'hidden'
          display: 'inline-block'
          marginRight: 18
          marginTop: 3

        IMG 
          alt: ''
          id: 'avatar_preview'
          style: 
            width: 60
            display: if !@local.preview then 'none'
          src: img_preview_src

        if !@local.preview  
          SVG 
            width: 60
            viewBox: "0 0 100 100" 
            style:
              position: 'relative'
              top: 8

            PATH 
              fill: "#ccc" 
              d: "M64.134,50.642c-0.938-0.75-1.93-1.43-2.977-2.023c8.734-6.078,10.867-18.086,4.797-26.805  c-6.086-8.727-18.086-10.875-26.82-4.797c-8.719,6.086-10.867,18.086-4.781,26.812c1.297,1.867,2.922,3.484,4.781,4.789  c-1.039,0.594-2.039,1.273-2.977,2.023c-6.242,5.031-11.352,11.312-15.023,18.438c-0.906,1.75-1.75,3.539-2.555,5.344  c17.883,16.328,45.266,16.328,63.133,0c-0.789-1.805-1.641-3.594-2.547-5.344C75.509,61.954,70.384,55.673,64.134,50.642z"

      INPUT 
        id: 'user_avatar'
        name: "avatar"
        type: "file"
        style: {marginTop: 24, verticalAlign: 'top'}
        onChange: (ev) => 
          input = $('#user_avatar')[0]
          if input.files && input.files[0]
            reader = new FileReader()
            reader.onload = (e) =>
              @local.preview = true 
              @local.newly_uploaded = e.target.result
              save @local
              $("#avatar_preview").attr 'src', e.target.result
            reader.readAsDataURL input.files[0]
          else
            $("#avatar_preview").attr('src', asset('no_image_preview.png'))

window.upload_avatar = ->
  current_user = fetch '/current_user'
  avatar_file_input = document.getElementById('user_avatar')
  if avatar_file_input?.files.length > 0
    ajax_submit_files_in_form 
      type: 'PUT'
      form: '#user_avatar_form'
      additional_data:  
        authenticity_token: current_user.csrf
        trying_to: 'update_avatar_hack'
      success: -> 
        # It is important that a user that just submitted a user picture see the picture
        # on the results and in the header. However, this is a bit tricky because the avatars
        # are cached on the server and the image is processed in a background task. 
        # Therefore, we'll wait until the image is available and then make it available
        # in the avatar cache.  
        time_between = 1000
        update_user = -> 
          arest.serverFetch '/current_user'
          time_between *= 2
          if time_between < 100000
            setTimeout update_user, time_between 
        update_user()
      error: (problem) ->
        console.error "Error uploading avatar", problem  
