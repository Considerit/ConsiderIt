

styles += """
  [data-name="/dashboard/customizations"] #DASHBOARD-main {
    max-width: 85vw;
  }
"""

window.CustomizationsDash = ReactiveComponent
  displayName: 'CustomizationsDash'

  render : -> 

    subdomain = fetch '/subdomain'
    current_user = fetch '/current_user'
    subdomains = fetch '/subdomains'

    if !@local.compare_to?
      @local.compare_to = ''
      save @local

    other_subs = []
    for sub in subdomains.subs when sub.customizations && sub.name != subdomain.name
      other_subs.push [sub.name.toLowerCase(), sub.customizations]
      if sub.name.toLowerCase() == @local.compare_to
        compare_to = JSON.stringify(sub.customizations or "\n\n\n\n\n\n\n", null, 2)

    other_subs.sort (a,b) -> 
      if a[0] < b[0]
        return -1
      else if a[0] > b[0]
        return 1
      else 
        return 0

    return SPAN null if !subdomain.name || !current_user.is_super_admin || !subdomains.subs

    if !CodeMirror?
      location.reload()
      return SPAN null

    @local.stringified_current_value ?= JSON.stringify(subdomain.customizations or "\n\n\n\n\n\n\n", null, 2)
    @local.customization_filter ?= ''
    @local.property_changes ?= {}

    try
      code_properties = ( [k,v] for k,v of subdomain.customizations when typeof(v) == 'string' && v.startsWith(FUNCTION_IDENTIFIER) )
    catch error 
      code_properties = []
      console.error error




    DIV 
      className: 'customizations'

      STYLE 
        dangerouslySetInnerHTML: {__html: """
          .customizations .CodeMirror {
            height: 500px;
            font-size: 14px;
            border: 1px solid #ddd;
          }

        """}

      DIV className: 'input_group',



        DIV 
          style: 
            display: 'inline-block'
            width: if @local.compare_to != '' then '58%' else '75%'
            verticalAlign: 'top'

          DIV null, 
            CodeMirrorTextArea 
              id: 'customizations'
              key: md5(subdomain.customizations) # update text area if subdomain.customizations changes elsewhere
              default_value: JSON.stringify(subdomain.customizations or "\n\n\n\n\n\n\n", null, 2)
              onChange: (val) => 
                @local.stringified_current_value = val

          DIV 
            className: 'input_group'
            BUTTON 
              className: 'primary_button button'
              onClick: => @submit()
              style: 
                backgroundColor: focus_color()
              'Save'

          if @local.save_complete
            DIV style: {color: 'green'}, 'Saved.'

          if @local.errors
            if @local.errors && @local.errors.length > 0
              DIV 
                style: 
                  borderRadius: 8
                  margin: 20
                  padding: 20
                  backgroundColor: '#FFE2E2'

                H1 style: {fontSize: 18}, 'Ooops!'

                for error in @local.errors
                  DIV 
                    style: 
                      marginTop: 10
                    error

        DIV 
          style: 
            display: 'inline-block'
            width:  if @local.compare_to == '' then '22%' else '38%'
            verticalAlign: 'top'
            marginLeft: '2%'

          INPUT 
            style: 
              width: '100%'
            placeholder: 'Filter to subs with customization containing...'
            ref: 'customization_filter'
            type: 'text'
            defaultValue: ''
            onKeyUp: (e) => 
              @local.customization_filter = @refs.customization_filter.getDOMNode().value
              save @local

          DIV 
            style: 
              fontStyle: 'italic'
            "Compare to "
            SELECT 
              value: @local.compare_to
              style: 
                width: 80
              onChange: (ev) => 
                @local.compare_to = ev.target.value 
                save @local
                console.log @local

              for [sub, id] in other_subs when @local.customization_filter.length == 0 || id.toLowerCase().indexOf(@local.customization_filter.toLowerCase()) > -1
                OPTION 
                  value: sub
                  sub 
            ".consider.it:"

          if !!compare_to
            CodeMirrorTextArea 
              key: compare_to
              id: 'comparison'
              default_value: compare_to


      if code_properties.length > 0 
        DIV 
          style: 
            marginTop: 50
          H2 
            style: 
              fontSize: 36

            "Easier code-editing sections"

          for k,v of subdomain.customizations
            if typeof(v) == 'string' && v.startsWith(FUNCTION_IDENTIFIER)
              js = v.substring(FUNCTION_IDENTIFIER.length)

              DIV null, 
                H3 
                  style: 
                    fontSize: 24
                    marginTop: 36

                  k 

                DIV null, 
                  CodeMirrorTextArea 
                    key: "#{md5(subdomain.customizations)}-#{k}" # update text area if subdomain.customizations changes elsewhere
                    default_value: js
                    onChange: do (k) => (val) => 
                      @local.property_changes[k] = val
                      save @local

                DIV 
                  className: 'input_group'

                  BUTTON 
                    className: 'primary_button button'
                    onClick: do (k) => => 
                      if k of @local.property_changes
                        @submit_change(k, @local.property_changes[k], true)
                    style: 
                      backgroundColor: focus_color()
                      opacity: if k not of @local.property_changes then .5
                      cursor: if k not of @local.property_changes then 'default'
                    disabled: if k not of @local.property_changes then true
                    'Save'



      DIV null, 

        DIV 
          style: 
            marginTop: 20
            marginBottom: 5
            cursor: 'pointer'
            fontWeight: 600
            color: '#666'
            textDecoration: 'underline'
            
          onClick: => @local.show_shared = !@local.show_shared; save @local

          "Shared code and variables to use in customizations"

        if @local.show_shared

          CodeMirrorTextArea 
            key: 'shared_code'
            default_value: subdomain.shared_code

      DIV null, 

        DIV 
          style: 
            marginTop: 20
            marginBottom: 5
            cursor: 'pointer'
            fontWeight: 600
            color: '#666'
            textDecoration: 'underline'

          onClick: => @local.show_doc = !@local.show_doc; save @local

          "Variable documentation"

        if @local.show_doc
          DIV 
            style: 
              marginTop: 10

            A 
              href: "https://docs.google.com/spreadsheets/d/1gn1PuF98i4eD8x0E4YHmtBAcEdau9W13cJ7fh6MF3u8/edit#gid=0"
              target: '_blank'
              style: 
                display: 'block'
                textDecoration: 'underline'
                color: focus_color()
                marginBottom: 5
              "Load documentation in own tab"
            "."


            IFRAME
              width: '100%' 
              height: 1500 
              src: "https://docs.google.com/spreadsheets/d/1gn1PuF98i4eD8x0E4YHmtBAcEdau9W13cJ7fh6MF3u8/pubhtml?widget=true&amp;headers=false"







  submit_change : (property, value, is_javascript) -> 
    subdomain = fetch '/subdomain'
    if is_javascript 
      value = "#{FUNCTION_IDENTIFIER}#{value}"

    subdomain.customizations[property] = value
    @_save_changes()


  submit : -> 
    subdomain = fetch '/subdomain'
    subdomain.customizations = JSON.parse @local.stringified_current_value
    @_save_changes()

  _save_changes : ->
    subdomain = fetch '/subdomain'

    @local.save_complete = false
    save @local

    save subdomain, => 
      if subdomain.errors
        @local.errors = subdomain.errors

      @local.save_complete = true
      save @local




CodeMirrorTextArea = ReactiveComponent
  displayName: 'CodeMirrorTextArea'

  render: -> 
    TEXTAREA 
      id: @props.id
      name: @props.id
      ref: 'field'
      defaultValue: @props.default_value 

  componentDidMount: -> 
    betterTab = (cm) ->

      if cm.somethingSelected()
        cm.indentSelection 'add'
      else
        o = if cm.getOption("indentWithTabs")
              "\t"
            else 
              Array(cm.getOption("indentUnit") + 1).join(" ")

        cm.replaceSelection o, "end", "+input"

    @m = CodeMirror.fromTextArea @refs.field.getDOMNode(), _.defaults (@props.opts or {}),        
          lineNumbers: true
          matchBrackets: true
          indentUnit: 2
          mode: 'coffeescript'
          extraKeys: 
            Tab: betterTab
    if @props.onChange
      @m.on 'change', => 
        @props.onChange @m.getValue()

  componentWillUnmount: -> 
    @m.getTextArea().remove()
