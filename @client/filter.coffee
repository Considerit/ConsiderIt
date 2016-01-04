require './shared'
require './customizations'

UserFilter = ReactiveComponent
  displayName: 'UserFilter'

  render : -> 
    filters = customization 'user_filters'
    users = fetch '/users'
    filter_out = fetch 'filtered'
    current_user = fetch '/current_user'
    subdomain = fetch '/subdomain'

    set_filtered_users = => 
      filter_out.users = {}
      filter_out.checked = {}
      filter_funcs = []
      for filter,idx in filters 
        if @refs[idx].getDOMNode().checked
          filter_funcs.push filter.pass
          filter_out.checked[filter.label] = true

      if filter_funcs.length > 0
        for user in users.users
          passes = false 
          for func in filter_funcs
            passes ||= func(user)

          if !passes
            filter_out.users[user.key] = 1

      save filter_out


    DIV 
      style: _.extend {}, (@props.style or {})

      SPAN 
        style: 
          textStyle: 'italics'
          marginRight: 10

        'Filter to:'

      for filter,idx in filters 
        id = "filter-#{slugify(filter.label)}"
        DIV 
          style: 
            display: 'inline-block'
            marginRight: 10

          INPUT 
            type: 'checkbox'
            ref: idx
            id: id
            style: 
              fontSize: 24
              marginRight: 6
              display: 'inline-block'
            defaultChecked: filter_out.checked?[filter.label]
            onChange: set_filtered_users

          LABEL 
            htmlFor: id

            filter.label

      if subdomain.name == 'bitcoin' && \
         current_user.logged_in && \
         (!current_user.tags['verified']? || current_user.tags['verified'] in ['no', 'false'])
        
        DIV 
          style: 
            fontSize: 14 
            color: logo_red

          """You are unverified! Photograph yourself holding a bitcoin.consider.it \
             sign and email it to """
          A 
            mailTo: 'verify@consider.it'
            style: 
              textDecoration: 'underline'
            'verify@consider.it' 

          '.'






window.UserFilter = UserFilter