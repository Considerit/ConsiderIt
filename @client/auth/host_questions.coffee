require './auth'

# TODO: this form should also show the community pledge
window.HostQuestions = ReactiveComponent
  displayName: 'CreateAccount'
  mixins: [AuthForm, Modal]

  render: -> 
    i18n = @i18n()
    auth = fetch 'auth'
    current_user = fetch '/current_user'

    @Draw
      task: translator 'auth.host_questions.heading', 'Your hosts request more info'
      disallow_cancel: disallow_cancel()
      goal: if auth.goal then translator "auth.login_goal.#{auth.goal.toLowerCase()}", auth.goal
      on_submit: (ev) =>
        @Submit ev, 
          action: 'user questions'
          has_host_questions: true
          check_considerit_terms: true

      ShowHostQuestions()      

      if customization('auth_footer')
        DIV 
          style:
            fontSize: 13
            color: auth_text_gray
            padding: '16px 0'
          dangerouslySetInnerHTML: {__html: customization('auth_footer')}

      @ShowErrors()


window.errors_in_host_questions = (responses) -> 
  questions = customization('auth_questions')
  errors = []

  for tag, vals of (customization('user_tags') or {})
    continue if !vals.self_report
    question = vals.self_report
    if question.required
      has_response = question.input in ['boolean', 'checklist'] || !!responses[tag]

      if !has_response || (question.require_checked && !responses[tag])
        errors.push translator 
                       id: 'auth.validation.missing_answer'
                       question: question.question
                       "\"{question}\" is required!" 

      is_valid_input = true
      if question.validation
        is_valid_input = question.validation(responses[tag])
      if !is_valid_input && has_response
        errors.push translator 
                       id: 'auth.validation.invalid_answer'
                       response: responses[tag]
                       question: question.question  
                       "{response} isn't a valid answer to \"{question}\"!" 
  errors



window.ShowHostQuestions = ReactiveComponent
  displayName: 'ShowHostQuestions'

  render: ->

    host_questions = @HostQuestionInputs()
    return SPAN null if host_questions.length == 0


    host_framing = customization 'host_questions_framing'

    DIV
      style: 
        padding: "24px 33px"
        backgroundColor: "#eee"
        marginTop: 18
        width: AUTH_WIDTH() - 18 * 2
        marginLeft: -50 + 18

      DIV 
        style: 
          marginBottom: 12     

        LABEL
          className: 'AUTH_field_label' 
          translator('auth.host_questions.heading', 'Questions from the forum host') 

        if host_framing 
          DIV 
            style: 
              fontSize: 14
              marginTop: 8
            dangerouslySetInnerHTML: __html: host_framing


      UL 
        style: 
          padding: "6px 0px"
          listStyle: 'none'

        for [label, render] in host_questions
          field_id = render?.props?.id or render?[0]?.props?.id
          LI 
            style: 
              marginBottom: 16

            LABEL
              htmlFor: field_id
              style:
                display: 'block'
                fontWeight: 600

              dangerouslySetInnerHTML: __html: label 


            render


  ####
  # HostQuestionInputs
  #
  # Creates the ui inputs for answering user questions for this subdomain
  HostQuestionInputs : -> 
    subdomain = fetch('/subdomain')
    current_user = fetch('/current_user')
    auth = fetch('auth')

    return DIV() if !current_user.tags

    questions = []
    for tag, vals of (customization('user_tags') or {})
      if vals.self_report
        questions.push _.extend {}, vals.self_report, {tag}

    if @local.tags != current_user.tags
      @local.tags = current_user.tags
      save @local
      return SPAN null


    inputs = []
    for question in questions
      label = "#{question.question}"      

      switch question.input

        when 'text'
          input = INPUT
            style: _.defaults question.input_style or {}, 
              marginBottom: 6
              width: 300
              border: "1px solid #a1a1a1"
              padding: '5px 10px'
              fontSize: 18            
            key: "#{question.tag}_inputBox"
            id: slugify("#{question.tag}inputBox")
            type: 'text'
            value: @local.tags[question.tag]

            onChange: do(question) => (event) =>
              @local.tags = @local.tags or {}
              @local.tags[question.tag] = current_user.tags[question.tag] = event.target.value
              save @local
            onKeyPress: (event) =>
              # submit on enter
              if event.which == 13
                @submitAuth(event)

        when 'boolean'
          input = 

            DIV 
              style: 
                marginBottom: 10

              INPUT
                id: slugify("#{question.tag}inputBox")
                key: "#{question.tag}_inputBox"
                type:'checkbox'
                className: 'bigger'
                style: 
                  fontSize: 24
                  verticalAlign: 'top'
                  marginTop: 7
                  marginLeft: 0
                checked: @local.tags[question.tag]
                onChange: do(question) => (event) =>
                  @local.tags = @local.tags or {}
                  @local.tags[question.tag] = current_user.tags[question.tag] = event.target.checked
                  save @local

              LABEL 
                htmlFor: slugify("#{question.tag}inputBox")
                style: 
                  display: 'inline-block'
                  width: '90%'
                  paddingLeft: 8
                dangerouslySetInnerHTML: __html: question.question


          label = ''

        when 'checklist'
          input = DIV 
            style: 
              margin: "10px 18px"

            for option in question.options
              key = "#{question.tag}-#{option}"

              DIV null,

                INPUT
                  id: slugify("#{key}-inputBox")
                  key: "#{key}_inputBox"
                  type:'checkbox'
                  className: 'bigger'
                  style: 
                    fontSize: 24
                    verticalAlign: 'baseline'
                    marginLeft: 0
                  checked: current_user.tags[question.tag]?.split(',').indexOf(option) > -1
                  onChange: do(question, option) => (event) =>
                    @local.tags = @local.tags or {}

                    currently_checked = current_user.tags[question.tag]?.split(',') or []

                    if event.target.checked
                      currently_checked.push option
                    else 
                      idx = currently_checked.indexOf(option)
                      if idx > -1
                        currently_checked.splice idx, 1
                    
                    @local.tags[question.tag] = current_user.tags[question.tag] = currently_checked.join(',')
                    save @local

                LABEL 
                  htmlFor: slugify("#{key}-inputBox")
                  style: 
                    display: 'inline-block'
                    width: '90%'
                    paddingLeft: 8
                  dangerouslySetInnerHTML: __html: option

        when 'dropdown'
          input = SELECT
            id: slugify("#{question.tag}inputBox")
            key: "#{question.tag}_inputBox"            
            style: _.defaults question.input_style or {},
              fontSize: 18
              marginTop: 4
              maxWidth: '100%'
            value: @local.tags[question.tag] or ''
            onChange: do(question) => (event) =>
              @local.tags = @local.tags or {}
              @local.tags[question.tag] = current_user.tags[question.tag] = event.target.value
              save @local
            [
              OPTION 
                value: ''
                disabled: true 
                hidden: true
              for value in question.options
                OPTION  
                  value: value
                  value
            ]

        else
          throw "Unsupported question type: #{question.input} for #{question.tag}"

      # if !question.required && question.input not in ['boolean', 'checklist']
      #   op = DIV 
      #         style: 
      #           color: '#888'
      #           fontSize: 12
      #         translator('optional')

      #   label = [op, label] 

      inputs.push [label,input]
    inputs
