
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
    background-color: var(--bg_lightest_gray);
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
    background-color: var(--bg_light);
  }

  .doc_groups {
    display: flex;
    justify-content: center; 
  }

  .doc_group {
    padding: 12px 24px;
  }

  .doc_group h2 {
    font-size: 14px;
  }

  .doc_group ul {
    list-style: none;
  }

  .doc_group li {
    list-style: none;
    padding-top: 8px;
  }

  .doc_group ul a {
    text-decoration: none;
    font-weight: 500;
    color: var(--text_gray);
  }

  .doc_group ul a:hover {
    text-decoration: underline;
  }

  .doc_group ul .active a {
    color: var(--text_dark);
    text-decoration: underline;
  }


  @media #{NOT_PHONE_MEDIA} {
    .doc_groups {
      flex-direction: row;
    }
  }

  @media #{PHONE_MEDIA} {
    .doc_groups {
      flex-direction: column;
    }
    .doc_group li, .doc_group h2 {
      text-align: center;
    }
  }

"""



doc_groups = {
  data: {
    name: ''
    groups: [
      {
        label: ''
        docs: [
          {name: 'Data Export Documentation', path: 'data_export'}
        ]
      }

    ]
  },
  legal: {
    name: ''
    groups: [
      {
        label: 'Terms'
        docs: [
          {name: 'Terms of Service', path: 'terms_of_service'}
          {name: 'Forum Hosting Terms', path: 'standard_hosting_terms'}
          {name: 'Data Processing Addendum', path: 'data_processing_addendum'}
        ]
      }
      {
        label: 'Policies'
        docs: [
          {name: 'Privacy Policy', path: 'privacy_policy'}
          {name: 'Acceptable Use', path: 'use_restrictions'}
          {name: 'Delete Your Data', path: 'deleting_your_data'}
        ]
      }
      {
        label: 'Background'
        docs: [
          {name: 'Security Practices', path: 'security'}                    
          {name: 'Subprocessors', path: 'subprocessors'}   
          {name: 'Accessibility', path: 'accessibility'}          

        ]
      }          
    ]
  }
}

window.DocumentationGroup = ReactiveComponent
  displayName: 'DocumentationGroup'

  render: -> 
    parts = bus_fetch('location').url.split('/')
    group = parts[parts.length - 2]
    doc = parts[parts.length - 1]

    group_config = doc_groups[group]
    return SPAN null if !group_config

    DIV 
      className: 'Documentation'



      if group_config.groups.length == 1 # flat list
        DIV 
          className: 'doc_menu'

          if group_config.groups[0].docs.length > 1

            UL 
              style: {}

              for item in group_config.groups[0].docs
                bus_fetch "/docs/#{item.path}" # just to preload
                LI 
                  className: if item.path == doc then 'active'

                  A 
                    href: "/docs/#{group}/#{item.path}"
                    item.name

      else 
        DIV 
          className: 'doc_groups_container'

          H1
            className: 'doc_center'
            group_config.name

          DIV 
            className: 'doc_groups'

            for ggroup in group_config.groups
              DIV 
                className: 'doc_group'

                H2 null,
                  ggroup.label

                UL null,
                  for item in ggroup.docs
                    bus_fetch "/docs/#{item.path}" # just to preload
                    LI 
                      className: if item.path == doc then 'active'

                      A 
                        href: "/docs/#{group}/#{item.path}"
                        item.name



      Documentation
        doc: doc



styles += """
  .Documentation .markdown_doc {
    width: 80%;
    max-width: 1100px;
    margin: 0px auto;
    padding: 36px 86px;
    background-color: var(--bg_light);
    box-shadow: var(--shadow_dark_20) 0px 1px 2px;  
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
    color: var(--text_dark);    
  }
  .markdown-body li {
    list-style-position: outside;
    padding: 0px 0px 8px 12px;
  }

  .markdown-body b, .markdown-body strong {
    color: var(--text_dark);
  }

"""
window.Documentation = ReactiveComponent
  displayName: 'Documentation'

  render: ->
    html = bus_fetch("/docs/#{@props.doc}").html
    return SPAN(null) if !html
        
    DIV 
      className: 'markdown_doc'

      LINK 
        rel: 'stylesheet' 
        type: 'text/css'
        href: asset("../vendor/github-markdown.css")


      DIV className: 'markdown-body', dangerouslySetInnerHTML: {__html: html}

    


