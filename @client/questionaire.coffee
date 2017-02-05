require './shared'
require './customizations'
require './permissions'

window.Questionaire = ReactiveComponent
  displayName: 'Questionaire'

  render: -> 
    cluster_key = @props.cluster_key

    groups = customization 'groups', cluster_key

    clusters = clustered_proposals true

    current_user = fetch '/current_user'

    if !@local.top_response? && customization('select_top', cluster_key)
      for group in groups
        list_name = group.split('/')[1]
        for response in (clusters[list_name]?.proposals or [])
          if response.your_opinion.published && response.your_opinion.stance == 1.0
            @local.top_response = response.key

    selection_limit = customization('selection_limit', cluster_key)
    if !@local.total_selected?
      @local.total_selected = 0
      for group in groups
        list_name = group.split('/')[1]
        for response in (clusters[list_name]?.proposals or [])
          if response.your_opinion.published
            @local.total_selected += 1


    DIV 
      style: {}

      if !current_user.logged_in
        DIV 
          style: 
            fontSize: 18
            fontWeight: 400
            marginBottom: 24

          'You must '

          BUTTON
            'data-action': 'create'
            onClick: (e) =>
              reset_key 'auth',
                form: 'create account'
                ask_questions: true
            style: 
              backgroundColor: 'transparent'
              border: 'none'
              fontWeight: 700
              textDecoration: 'underline'
              textTransform: 'lowercase'
              padding: 0
            t('create an account')

          ' or '
          BUTTON
            'data-action': 'create'
            onClick: (e) =>
              reset_key 'auth',
                form: 'login'
                ask_questions: true
            style: 
              backgroundColor: 'transparent'
              border: 'none'
              fontWeight: 700
              textDecoration: 'underline'
              padding: 0
              textTransform: 'lowercase'
            t('log_in')

          ' before answering this question.'



      DIV 
        style: 
          opacity: if !current_user.logged_in then .7

        for group in groups
          list_name = group.split('/')[1]

          DIV 
            style: 
              marginBottom: 24

            H4
              style: 
                fontWeight: 400
                fontSize: 16
                marginBottom: 8
                fontStyle: 'italic'

              customization 'list_label', group

            UL 
              style: 
                listStyle: 'none'

              for response in (clusters[list_name]?.proposals or [])
                fetch(response.your_opinion) # register a dependency
                do (response) =>
                  disabled = !current_user.logged_in || (!response.your_opinion.published && selection_limit && selection_limit <= @local.total_selected)
                  LI 
                    style: 
                      opacity: if disabled then .5


                    INPUT 
                      type: 'checkbox'
                      id: slugify(response.name)
                      style: 
                        fontSize: 32
                        cursor: if !disabled then 'pointer'

                      disabled: disabled
                      defaultChecked: response.your_opinion.published
                      onChange: => 
                        opinion = response.your_opinion
                        if $("##{slugify(response.name)}").is(':checked')
                          opinion.published = true 
                          opinion.stance = 0.25
                          @local.total_selected += 1
                          save @local

                        else

                          opinion.published = false
                          @local.total_selected -= 1
                          save @local

                          if @local.top_response == response.key
                            @local.top_response = null
                            save @local

                        save opinion


                    LABEL 
                      htmlFor: slugify(response.name)
                      style: 
                        fontSize: 16
                        cursor: if !disabled then 'pointer'
                      response.name

        if customization('select_top', cluster_key) && current_user.logged_in
          DIV 
            style: {}

            H3 
              style: 
                fontWeight: 800
                fontSize: 24
                marginBottom: 8
              customization 'select_top', cluster_key

            if @local.total_selected == 0 
              DIV 
                style: 
                  fontStyle: 'italic'
                  fontSize: 18
                "First, choose your top 5 priorities above!"
            UL 
              style: 
                listStyle: 'none'

              for group in groups
                list_name = group.split('/')[1]

                for response in (clusters[list_name]?.proposals or [])
                  continue if !response.your_opinion.published

                  do (response) =>
                    LI 
                      style: {}

                      INPUT 
                        type: 'radio'
                        id: 'radio-' + slugify(response.name)
                        style: 
                          fontSize: 32
                          cursor: 'pointer'

                        checked: response.key == @local.top_response
                        onChange: => 
                          for group in groups
                            list_name = group.split('/')[1]
                            for r in (clusters[list_name]?.proposals or [])
                              if r.your_opinion.published && r.id != response.id
                                r.your_opinion.stance = 0.25
                                save r.your_opinion
                          opinion = response.your_opinion
                          opinion.stance = 1.0
                          @local.top_response = response.key 
                          save @local
                          save opinion


                      LABEL 
                        htmlFor: 'radio-' + slugify(response.name)
                        style: 
                          fontSize: 16
                          cursor: 'pointer'
                        response.name

            if @local.top_response
              response = fetch @local.top_response
              DIV 
                key: 'explanation' + @local.top_response
                style: 
                  marginTop: 18
                  marginLeft: 24

                H4
                  style: 
                    fontSize: 16
                    fontWeight: 400
                    marginBottom: 4
                    fontStyle: 'italic'

                  'How would this tool be most useful to you? What would it include? What outcome would you like to achieve from using this tool? Please be as specific as possible.'

                AutoGrowTextArea
                  defaultValue: response.your_opinion.explanation
                  onChange: (e) => 
                    response.your_opinion.explanation = e.target.value
                    if !@pending_save
                      pending_save = true 
                      setTimeout ->
                        @pending_save = false
                        save response.your_opinion
                      , 1000
                  style: 
                    width: '100%'
                    fontSize: 16
                    padding: '4px 8px'
                    border: '1px solid #ddd'
                    maxWidth: 600
                    minHeight: 120

        do => 
          complete = => 
            document.activeElement.blur()
            @local.flash = 'Thanks! Your response has been saved. Feel free to change your answers.' 
            
            setTimeout => 
              @local.saved = true 
              @local.flash = null 
              save @local
            , 5000
            save @local

          DIV 
            style: 
              visibility: if !current_user.logged_in then 'hidden'

            BUTTON 
              className: 'primary_button'
              onClick: complete 
              onKeyPress: (e) => 
                if e.which == 32 || e.which == 13
                  complete()

              if @local.saved
                "Update"
              else 
                "Done!"

            if @local.flash
              DIV 
                style: 
                  fontSize: 16
                  color: 'black'
                  marginTop: 4
                @local.flash


      if current_user.is_admin
        all_proposals = []
        for group in groups
          list_name = group.split('/')[1]
          all_proposals = all_proposals.concat (clusters[list_name]?.proposals or [])
        
        DIV 
          style: 
            marginTop: 20
          filter_sort_options()
          H1 
            style: _.extend {}, customization('list_label_style'),
              fontSize: 32
              fontWeight: 600
            'Results'

          UL null, 
            
            for proposal,idx in sorted_proposals(all_proposals)

              CollapsedProposal 
                key: "collapsed#{proposal.key}"
                proposal: proposal
