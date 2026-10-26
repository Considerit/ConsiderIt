require './color'

# A toggle button for switching between the default light theme and the
# high-contrast theme. Rendered in the footer.

styles += """
  .HighContrastToggle {
    display: inline-flex;
    align-items: center;
    gap: 8px;
    min-height: 32px;
    padding: 4px 8px;
    background: none;
    border: none;
    color: inherit;
    font-size: 14px;
    cursor: pointer;
  }

  .HighContrastToggle .track {
    position: relative;
    flex-shrink: 0;
    width: 36px;
    height: 20px;
    border: 2px solid currentColor;
    border-radius: 10px;
  }

  .HighContrastToggle .knob {
    position: absolute;
    top: 2px;
    left: 2px;
    width: 12px;
    height: 12px;
    border-radius: 50%;
    background-color: currentColor;
    transition: left .15s;
  }

  .HighContrastToggle[aria-pressed="true"] .knob {
    left: 18px;
  }

  .HighContrastToggle:focus-visible {
    outline: 2px solid currentColor;
    outline-offset: 2px;
  }
"""

window.HighContrastToggle = ReactiveComponent
  displayName: 'HighContrastToggle'

  render: ->
    active = getCurrentTheme().startsWith 'high-contrast'

    BUTTON
      className: 'HighContrastToggle'
      'aria-pressed': active
      onClick: => setTheme(if active then 'light' else 'high-contrast')

      SPAN
        className: 'track'
        'aria-hidden': true

        SPAN
          className: 'knob'

      translator 'footer.high_contrast', 'High contrast'

  componentDidMount: ->
    @handleThemeChange = => @forceUpdate()
    window.addEventListener 'themeChanged', @handleThemeChange

  componentWillUnmount: ->
    window.removeEventListener 'themeChanged', @handleThemeChange
