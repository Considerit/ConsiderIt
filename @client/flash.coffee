require './shared'


styles += """
  #flash-container {
    width: 100%;
    display: flex;
    justify-content: center;
    z-index: 9999999;
    position: fixed;
    font-size: 15px;
  }
  #flash {
    color: var(--text_light);
    background-color: var(--bg_dark);
    border-radius: 3px;
    cursor: default;
    max-width: 400px;
    display: flex;
    font-weight: 600;
    align-items: center;
  }

  #flash.error {
    background-color: var(--failure_color);
  }

  #flash .flash-message {
    padding: 8px 18px;
    border-right: 1px solid transparent;
  }

  #flash .flash-close button {
    padding: 8px 18px;
  }


  @keyframes flashfadein {
    from {bottom: 0; opacity: 0;}
    to {bottom: 12px; opacity: 1;}
  }

  @keyframes flashfadeout {
    from {bottom: 12px; opacity: 1;}
    to {bottom: 0; opacity: 0;}
  }


"""


clear_flash = ->
  flash = bus_fetch('flash')
  flash.message = flash.time = flash.args = null 
  save flash

window.show_flash_error = (message, time_in_ms) ->
  time_in_ms ?= 999999
  show_flash message, time_in_ms, 
    error: true

current_flash_message = null

window.show_flash = (message, time_in_ms, args) ->
  time_in_ms ?= 3000

  flash = bus_fetch('flash')
  flash.message = message
  flash.time = time_in_ms
  flash.args = args
  save flash

  if current_flash_message
    clearTimeout current_flash_message
    
  current_flash_message = setTimeout ->
    clear_flash()
  , time_in_ms


window.Flash = ReactiveComponent
  displayName: 'Flash'

  render : -> 
    flash = bus_fetch('flash')
  
    is_error = flash.args?.error 

    DIV
      id: "flash-container"
      style: 
        animation: if flash.message then "flashfadein 500ms, flashfadeout 500ms #{flash.time - 500}ms"
        visibility: if flash.message then 'visible' else 'hidden'
        opacity: if flash.message then 1 else 0 
        bottom: if flash.message then 12 else 0

      DIV
        id: 'flash'
        className: if is_error then 'error'
        'aria-live': "polite"
        role: 'status'
        tabIndex: -1

        DIV 
          className: 'flash-message'
          dangerouslySetInnerHTML: if flash.message then {__html: flash.message}

        DIV
          className: 'flash-close'

          BUTTON 

            'aria-label': translator 'aria.close_flast', "Close flash message"
            className: 'icon'
            onClick: clear_flash
            iconX 16, "var(--text_light)"
