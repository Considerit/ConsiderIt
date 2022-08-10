
######
# Modal
#
# Mixin for handling some aspects of accessible modal forms
# Currently makes the first element with role=dialog exclusively focusable, unless there exists an @refs.dialog
# Will cancel on ESC if there exists a cancel button with @ref=cancel_dialog
# Code influenced by: 
#    - https://uxdesign.cc/how-to-trap-focus-inside-modal-to-make-it-ada-compliant-6a50f9a70700
#    - https://bitsofco.de/accessible-modal-dialog/
window.styles += """
#lightbox {
  position: fixed;
  top: 0;
  left: 0;
  background: rgba(0,0,0,.6);

  
  width: 100vw;
  height: 100vh;
  z-index: 99999;
}

#modal-wrapper {
  margin: 0 auto;
  position: relative;
  z-index: 0;
  padding: 3em 0;
}

#modal-body {
  padding: 2.5em 125px 3.5em 125px;
  font-size: 16px;
  box-shadow: 0 2px 4px rgba(0,0,0,.4), 0 0 100px rgb(255 255 255 / 40%);
  background-color: white; /* #f1f1f1; */
  position: relative;
  border-radius: 16px;
}

"""

window.Modal =

  accessibility_on_keydown: (e) ->
    # cancel on ESC if a cancel button has been defined
    if e.key == 'Escape' || e.keyCode == 27
      @refs.cancel_dialog?.click()

    # trap focus
    is_tab_pressed = e.key == 'Tab' or e.keyCode == 9
    if !is_tab_pressed
      return
    if e.shiftKey
      # if shift key pressed for shift + tab combination
      if document.activeElement == @first_focusable_element
        @last_focusable_element.focus()
        # add focus for the last focusable element
        e.preventDefault()
    else
      # if tab key is pressed
      if document.activeElement == @last_focusable_element
        # if focused has reached to last focusable element then focus first focusable element after pressing tab
        @first_focusable_element.focus()
        # add focus for the first focusable element
        e.preventDefault()

    return

  UNSAFE_componentWillMount: ->
    @scroll_Y = window.scrollY

  componentDidMount: ->
    @componentDidUpdate()
    
  componentDidUpdate: ->
    modal = @refs?.dialog or document.querySelector '[role=dialog]'
    return if !modal || @mounted
    @mounted = true

    @focused_element_before_opening = document.activeElement

    ######################################
    # For capturing focus inside the modal
    # add all the elements inside modal which you want to make focusable
    focusable_elements = 'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])'

    # select the modal by it's id
    @first_focusable_element = modal.querySelectorAll(focusable_elements)[0]
    # get first element to be focused inside modal
    focusable_content = modal.querySelectorAll(focusable_elements)
    @last_focusable_element = focusable_content[focusable_content.length - 1]

    # get last element to be focused inside modal
    document.addEventListener 'keydown', @accessibility_on_keydown

    try 
      modal.querySelector('input:not([disabled])')?.focus()
    catch e 
      console.error e

    #####################
    # For preventing scroll outside of the modal, and allowing scroll within, 
    # all while making it seem like the whole page is scrollable. 
    _.extend modal.style,
      position: 'fixed'
      top: "0px"
      left: "0px"
      width: '100vw'
      height: '100vh'
      overflow: 'auto'
      zIndex: 99999
      paddingBottom: if browser.is_mobile then "150px"

    scroll_bar_width = window.innerWidth - document.body.offsetWidth
    _.extend document.body.style,
      marginRight: scroll_bar_width
      overflow: 'hidden'
      position: 'fixed'
      top: "-#{@scroll_Y}px"
      width: '100vw'




  
  componentWillUnmount: -> 
    # return the focus to the element that had focus when the modal was launched
    if @focused_element_before_opening && document.body.contains(@focused_element_before_opening)
      @focused_element_before_opening.focus()
    document.removeEventListener 'keydown', @accessibility_on_keydown

    _.extend document.body.style,
      marginRight: null
      overflow: null
      position: null
      top: 0
      width: null

    # restore scroll position
    window.scroll(0, @scroll_Y)


window.wrap_in_modal = (width, click_lightbox_callback, children) -> 
  DIV null,

    DIV 
      id: 'lightbox'

    DIV
      id: 'modal'
      ref: 'dialog'
      role: 'dialog'
      # 'aria-labelledby': 'AUTH_task'
      # 'aria-describedby': if options.goal then 'AUTH_goal'

      onClick: if click_lightbox_callback then click_lightbox_callback

      DIV
        id: 'modal-wrapper'
        style: 
          maxWidth: width or AUTH_WIDTH()

        onClick: if click_lightbox_callback then (e) ->
          e.stopPropagation()

        DIV
          id: 'modal-body'

          children

