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
    color: white;
    background-color: rgba(0, 0, 0, 0.88);
    border-radius: 3px;
    box-shadow: 0 1px 2px rgba(0, 0, 0, 0.1);
    cursor: default;
    max-width: 400px;
    display: flex;
    font-weight: 600;
  }

  #flash.error {
    background-color: rgba(216, 62, 62, 0.9);
  }

  #flash .flash-message {
    padding: 12px 24px;
    border-right: 1px solid rgba(255,255,255,.5);
  }

  #flash .flash-close {
  }

  #flash .flash-close button {
    background-color: transparent;
    color: white;
    border: none;
    padding: 12px 24px;
  }


  @keyframes flashfadein {
    from {bottom: 0; opacity: 0;}
    to {bottom: 50px; opacity: 1;}
  }

  @keyframes flashfadeout {
    from {bottom: 50px; opacity: 1;}
    to {bottom: 0; opacity: 0;}
  }


"""


clear_flash = ->
  flash = fetch('flash')
  flash.message = flash.time = flash.args = null 
  save flash

window.show_flash_error = (message, time_in_ms) ->
  time_in_ms ?= 999999
  show_flash message, time_in_ms, 
    error: true

current_flash_message = null

window.show_flash = (message, time_in_ms, args) ->
  time_in_ms ?= 3000

  flash = fetch('flash')
  flash.message = translator "flash.#{message}", message
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
    flash = fetch('flash')
  
    is_error = flash.args?.error 

    DIV
      id: "flash-container"
      style: 
        animation: if flash.message then "flashfadein 500ms, flashfadeout 500ms #{flash.time - 500}ms"
        visibility: if flash.message then 'visible' else 'hidden'
        opacity: if flash.message then 1 else 0 
        bottom: if flash.message then 50 else 0

      DIV
        id: 'flash'
        className: if is_error then 'error'
        'aria-live': "off"
        role: 'status'
        tabIndex: -1

        DIV 
          className: 'flash-message'
          dangerouslySetInnerHTML: if flash.message then {__html: flash.message}

        DIV
          className: 'flash-close'

          BUTTON 
            onClick: clear_flash
            'x'





