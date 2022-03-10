require './shared'


styles += """
  #flash-container {
    width: 100%;
    display: flex;
    justify-content: center;
    z-index: 9999999;
    position: fixed;
    bottom: 50px;    
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
"""

flash = fetch('flash')

clear_flash = ->
  flash.message = flash.args = null 
  save flash

window.show_flash_error = (message, time_in_ms) ->
  time_in_ms ?= 999999
  show_flash message, time_in_ms, 
    error: true

window.show_flash = (message, time_in_ms, args) ->
  time_in_ms ?= 3000

  flash = fetch('flash')
  flash.message = message
  flash.args = args
  save flash
  setTimeout ->
    clear_flash()
  , time_in_ms


window.Flash = ReactiveComponent
  displayName: 'Flash'

  render : -> 
    flash = fetch('flash')
    return SPAN(null) if !flash.message
  
    is_error = flash.args?.error 

    DIV
      id: "flash-container"

      DIV
        id: 'flash'
        className: if is_error then 'error'
        ariaLive: "off"
        role: 'status'
        tabIndex: -1

        DIV 
          className: 'flash-message'
          dangerouslySetInnerHTML: {__html: flash.message}

        DIV
          className: 'flash-close'

          BUTTON 
            onClick: clear_flash
            'x'





