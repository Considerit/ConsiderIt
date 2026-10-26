require './color'

# Theme switcher component for testing the different themes
window.ThemeSwitcher = ReactiveComponent
  displayName: 'ThemeSwitcher'

  render: ->
    current_theme = getCurrentTheme()
    
    DIV
      style:
        position: 'fixed'
        top: 10
        right: 10
        zIndex: 9999
        padding: '8px 12px'
        backgroundColor: "var(--bg_item)"
        border: "1px solid var(--brd_light_gray)"
        borderRadius: 8
        boxShadow: "0 2px 4px var(--shadow_dark_25)"
        fontSize: 14
        fontFamily: 'system-ui, -apple-system, sans-serif'

      DIV
        style:
          marginBottom: 8
          fontWeight: 600
          color: "var(--text_dark)"
        "Theme:"

      SELECT
        value: current_theme
        onChange: (e) => setTheme(e.target.value)
        style:
          padding: '4px 8px'
          fontSize: 14
          backgroundColor: "var(--bg_light)"
          color: "var(--text_dark)"
          border: "1px solid var(--brd_light_gray)"
          borderRadius: 4

        OPTION value: 'light', 'Light'
        OPTION value: 'dark', 'Dark'
        OPTION value: 'high-contrast', 'High Contrast Light'
        OPTION value: 'high-contrast-dark', 'High Contrast Dark'

      DIV
        style:
          marginTop: 8
          fontSize: 12
          color: "var(--text_light_gray)"
        "Ctrl+T to toggle"

  componentDidMount: ->
    # Add keyboard shortcut to toggle themes
    @handleKeyPress = (e) =>
      if (e.ctrlKey || e.metaKey) && e.key.toLowerCase() == 't'
        e.preventDefault()
        toggleTheme()
        @forceUpdate()

    document.addEventListener('keydown', @handleKeyPress)

    # Listen for theme changes to update the component
    @handleThemeChange = =>
      @forceUpdate()

    window.addEventListener('themeChanged', @handleThemeChange)

  componentWillUnmount: ->
    document.removeEventListener('keydown', @handleKeyPress)
    window.removeEventListener('themeChanged', @handleThemeChange)

# CSS for the theme switcher
styles += """
  /* Ensure theme switcher stays visible in all themes */
  .theme-switcher {
    font-family: system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
  }
"""