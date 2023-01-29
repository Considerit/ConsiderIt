
GoogleDocEmbed = ReactiveComponent
  displayName: 'GoogleDocEmbed'

  render: -> 

    DIV 
      style: 
        width: '80%'
        margin: 'auto'
        maxWidth: 700
      IFRAME 
        ref: 'iframe'
        width: '100%'
        height: window.innerHeight
        src: @props.link




styles += """
  .Documentation {
    background-color: #eee;
    padding: 56px 0;
  }
  .doc_menu {
  }

  .doc_menu ul {
    display: flex;
    justify-content: center;
  }
  .doc_menu li {
    padding: 6px 12px;
    font-weight: 700;
    display: inline-block;
    list-style: none;
    text-align: center;
  }
  .doc_menu li a {
    text-decoration: none;
    display: inline-block;    
  }
  .doc_menu li.active {
    # background-color: #{focus_color()};
    # color: white;
    background-color: white;
  }

  .Documentation .markdown_doc {
    width: 80%;
    max-width: 1100px;
    margin: 0px auto;
    padding: 36px 86px;
    background-color: white;
    box-shadow: rgba(0, 0, 0, 0.2) 0px 1px 2px;  
  }

  @media #{NOT_LAPTOP_MEDIA} {
    .Documentation .markdown_doc {
      width: 100%;
      padding: 36px 48px;      
    }
    .doc_menu li a {
      font-size: 14px;
      min-width: 76px;
    }

  }

  @media #{PHONE_MEDIA} {
    .Documentation .markdown_doc {
      width: 100%;
      padding: 36px 24px;      
    }
    .doc_menu li {
      padding: 6px 6px;
    }

    .doc_menu li a {
      font-size: 14px;
      min-width: 65px;
    }

  }

  .markdown-body {
    padding: 40px 36px; 
    max-width: 872px;
    margin: auto;       
  }

  .markdown-body a {
    text-decoration: underline; 
    color:#{considerit_red};    
  }
  .markdown-body li {
    list-style-position: outside;
    padding: 0px 0px 8px 12px;
  }


"""

doc_menu = [
  {name: 'Terms of Service', path: 'terms_of_service'}
  {name: 'Privacy Policy', path: 'privacy_policy'}
  {name: 'Hosting Terms', path: 'standard_hosting_terms'}
  {name: 'Use Restrictions', path: 'use_restrictions'}
  {name: 'Deleting Your Data', path: 'deleting_your_data'}
  {name: 'Subprocessors', path: 'subprocessors'}
]

window.Documentation = ReactiveComponent
  displayName: 'Documentation'

  render: ->
    parts = fetch('location').url.split('/')
    path = parts[parts.length - 1]


    html = fetch("/docs/#{path}").html
    return SPAN(null) if !html

    DIV 
      className: 'Documentation'

      DIV 
        className: 'doc_menu'

        UL 
          style: {}

          for item in doc_menu
            fetch "/docs/#{item.path}" # just to preload
            LI 
              className: if item.path == path then 'active'

              A 
                href: "/docs/#{item.path}"
                item.name

        
      DIV 
        className: 'markdown_doc'

        LINK 
          rel: 'stylesheet' 
          type: 'text/css'
          href: asset("../vendor/github-markdown.css")


        DIV className: 'markdown-body', dangerouslySetInnerHTML: {__html: html}

    


