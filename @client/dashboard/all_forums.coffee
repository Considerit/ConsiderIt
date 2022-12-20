require '../customizations'


styles += """

.AllYourForums h1 {
  margin: 36px 0px 18px 0px;
  font-size: 24px;
}

.AllYourForums .forum {
  list-style: none;
  align-items: center;
  display: flex;
  padding: 18px 0;
  min-height: 70px;
  width: 100%;
}

.AllYourForums .forum.odd {
  background-color: #fcfcfc;
}


.AllYourForums .logo {
  width: 120px;
  text-align: right;

  margin-right: 24px;
}

.AllYourForums .text {

}

.AllYourForums .forum_title {
  display: block;
  font-size: 18px;
  text-decoration: none;
}

.AllYourForums .forum_link {
  color: #888;
  font-weight: 400;
  font-size: 15px;
}

.AllYourForums .host-row {
  margin-left: 24px;
  visibility: hidden;
}

.AllYourForums .forum:hover .host-row,
.AllYourForums .forum:focus-within .host-row {
  visibility: visible;
}

"""


window.AllYourForums = ReactiveComponent
  displayName: 'AllYourForums'


  drawForums : (forums, is_host) -> 
    UL null,
      for forum,idx in forums
        do (forum) =>
          LI 
            className: "forum #{if idx % 2 then 'odd' else 'even'}"

            DIV 
              className: 'logo'

              if forum.logo 
                IMG 
                  src: forum.logo
                  style: 
                    maxWidth: 120
                    maxHeight: 70
              else 
                DIV 
                  style: 
                    border: '1px dashed #ccc'
                    borderRadius: 8
                    width: 120
                    height: 70

            DIV 
              className: 'text'


              A
                className: 'forum_title'
                href: "https://#{forum.name}.consider.it"
                forum.title or forum.name

              A
                className: 'forum_link'
                href: "https://#{forum.name}.consider.it"
                "https://#{forum.name}.consider.it"



            if is_host
              DIV 
                className: 'host-row'



                BUTTON 
                  style:
                    backgroundColor: 'transparent'
                    border: 'none'
                    cursor: 'pointer'
                    padding: '4px'
                  'data-tooltip': "Import Configuration from #{forum.name} to this forum"

                  onKeyPress: (e) =>
                    if e.which == 32 || e.which == 13
                      e.currentTarget.click()

                  onClick: => 
                    if confirm("Are you sure you want to import this configuration? It will overwrite the configuration of this forum.")

                      frm = new FormData()
                      frm.append "authenticity_token", fetch('/current_user').csrf
                      frm.append "subdomain_to_import_configuration", forum.id

                      cb = =>
                        location.reload()

                      xhr = new XMLHttpRequest
                      xhr.addEventListener 'readystatechange', cb, false
                      xhr.open 'PUT', '/import_configuration_from_subdomain', true
                      xhr.send frm

                  import_icon 18, '#444'


                BUTTON 
                  style:
                    backgroundColor: 'transparent'
                    border: 'none'
                    cursor: 'pointer'
                    padding: '4px'
                  'data-tooltip': 'Delete forum'

                  onKeyPress: (e) =>
                    if e.which == 32 || e.which == 13
                      e.currentTarget.click()

                  onClick: => 
                    if confirm("Are you sure you want to delete this entire forum? You cannot undo it.")

                      frm = new FormData()
                      frm.append "authenticity_token", fetch('/current_user').csrf
                      frm.append "subdomain_to_destroy", forum.id

                      cb = =>
                        arest.serverFetch '/your_forums'

                      xhr = new XMLHttpRequest
                      xhr.addEventListener 'readystatechange', cb, false
                      xhr.open 'PUT', '/destroy_forum', true
                      xhr.send frm

                  trash_icon 18, 18, '#888'






  render : ->

    subdomain = fetch '/subdomain'
    current_user = fetch '/current_user'


    forums = fetch '/your_forums'

    hosted = forums.hosted
    participated_in = forums.participated_in

    return SPAN null if !hosted? || !participated_in?


    DIV 
      className: 'AllYourForums'

      H1 null, 
        'Forums you\'ve hosted'

      if hosted.length > 0 
        @drawForums(hosted, true)

      else 
        DIV null,
          "You have not yet hosted a forum. "
          A 
            href: 'https://consider.it/create_forum'
            'Create your own'
          " if you wish."


      H1 null,
        'Forums you\'ve participated in'


      if participated_in.length > 0 
        @drawForums(participated_in, false)

      else 
        "You have not yet participated in a forum"



