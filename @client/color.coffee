##################
# Colors


window.focus_color = '#456ae4'
window.logo_red = "#B03A44"
window.considerit_red = "#df6264"
window.selected_color = '#DA4570' #pinkish red
window.upgrade_color = '#518eff'
window.attention_orange = "#fb7e26"
window.failure_color = "#F94747"
window.success_color = "#81c765"
window.caution_color = "#ffc92a"

window.slidergram_base_color = "#777777"

text_dark = '#000000'
text_gray = '#333333'    
text_light_gray = '#666666'
text_neutral = '#888888'
text_gray_on_dark = '#cccccc'
text_light = '#ffffff'


bg_dark = '#000000'
bg_dark_gray = '#444444'
bg_neutral_gray = "#888888"
bg_light_gray = '#aaaaaa'
bg_lighter_gray = '#cccccc'
bg_lightest_gray = '#eeeeee'
bg_light = '#ffffff'


bg_container = '#f7f7f7'
bg_item = '#ffffff'
bg_item_separator = '#f3f4f5'
bg_speech_bubble = '#f7f7f7'

brd_dark = '#000000'
brd_dark_gray = '#444444'
brd_neutral_gray = '#888888'
brd_mid_gray = '#aaaaaa' 
brd_light_gray = '#cccccc' 
brd_lightest_gray = '#eeeeee'
brd_light = '#ffffff'


# Color inversion utility functions

window.hexToRgba = (hex) ->
  # Handle 6-digit hex (#RRGGBB)
  result6 = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex)
  if result6
    return {
      r: parseInt(result6[1], 16)
      g: parseInt(result6[2], 16)
      b: parseInt(result6[3], 16)
      a: 255
    }
  
  # Handle 8-digit hex with alpha (#RRGGBBAA)
  result8 = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex)
  if result8
    return {
      r: parseInt(result8[1], 16)
      g: parseInt(result8[2], 16)
      b: parseInt(result8[3], 16)
      a: parseInt(result8[4], 16)
    }
  
  # Handle 3-digit hex (#RGB)
  result3 = /^#?([a-f\d])([a-f\d])([a-f\d])$/i.exec(hex)
  if result3
    return {
      r: parseInt(result3[1] + result3[1], 16)
      g: parseInt(result3[2] + result3[2], 16)
      b: parseInt(result3[3] + result3[3], 16)
      a: 255
    }
  
  # Handle 4-digit hex with alpha (#RGBA)
  result4 = /^#?([a-f\d])([a-f\d])([a-f\d])([a-f\d])$/i.exec(hex)
  if result4
    return {
      r: parseInt(result4[1] + result4[1], 16)
      g: parseInt(result4[2] + result4[2], 16)
      b: parseInt(result4[3] + result4[3], 16)
      a: parseInt(result4[4] + result4[4], 16)
    }
  
  null

rgbaToHex = (r, g, b, a) ->
  # Convert to hex with proper padding
  rHex = Math.round(r).toString(16).padStart(2, '0')
  gHex = Math.round(g).toString(16).padStart(2, '0')
  bHex = Math.round(b).toString(16).padStart(2, '0')
  
  if a? && a < 255
    aHex = Math.round(a).toString(16).padStart(2, '0')
    "##{rHex}#{gHex}#{bHex}#{aHex}"
  else
    "##{rHex}#{gHex}#{bHex}"

# Backward compatibility
hexToRgb = (hex) ->
  rgba = hexToRgba(hex)
  return null unless rgba
  { r: rgba.r, g: rgba.g, b: rgba.b }

invertColor = (hex) ->
  rgba = hexToRgba(hex)
  return hex unless rgba
  # Invert RGB, preserve alpha
  rgbaToHex(255 - rgba.r, 255 - rgba.g, 255 - rgba.b, rgba.a)

colorTransparency = (hex, opacity) -> 
  rgba = hexToRgba(hex)
  return "rgba(#{rgba.r}, #{rgba.g}, #{rgba.b}, #{opacity})"

window.desaturateHexColor = (hexval, amount = 1) ->

  hex = get_css_variable_value(hexval)
  return hexval unless hex?

  rgba = hexToRgba(hex)
  return hex unless rgba?

  hsl = rgb2hsl(rgba)
  hsl.s *= 1 - Math.max(0, Math.min(1, amount))  # Clamp amount to [0,1]

  # Convert HSL back to RGB
  [r, g, b] = hsv2rgb(hsl.h, hsl.s, hsl.l, true)  # Using HSL as HSV is close enough for desaturation here

  rgbaToHex(Math.round(r * 255), Math.round(g * 255), Math.round(b * 255), rgba.a)


# Ugly! Need to have responsive colors or responsive styles. 
if location.href.indexOf('aeroparticipa') > -1
  window.focus_color = "#073682"
  window.selected_color = focus_color



window.generateColorVariableDefs = ->
  """
    :root, :before, :after {
      /* Core colors (theme-independent) */
      --focus_color: #{focus_color};
      --focus_color_rgb: #{hexToRgb(focus_color).r}, #{hexToRgb(focus_color).g}, #{hexToRgb(focus_color).b};
      --focus_color_slightly_transluscent: rgba(var(--focus_color_rgb), 0.68);
      --focus_color_mostly_transluscent: rgba(var(--focus_color_rgb), 0.13);
      --logo_red: #{logo_red};
      --considerit_red: #{considerit_red};
      --selected_color: #{selected_color};
      --upgrade_color: #{upgrade_color};
      --attention_orange: #{attention_orange};
      --failure_color: #{failure_color};
      --success_color: #{success_color};
      --caution_color: #{caution_color};
      --slidergram_base_color: #{slidergram_base_color};

      /* Default Light Theme */
      --text_dark: #{text_dark};
      --text_gray: #{text_gray};
      --text_light_gray: #{text_light_gray};
      --text_neutral: #{text_neutral};
      --text_gray_on_dark: #{text_gray_on_dark};
      --text_light: #{text_light};

      --bg_dark: #{bg_dark};
      --bg_dark_rgb: #{hexToRgb(bg_dark).r}, #{hexToRgb(bg_dark).g}, #{hexToRgb(bg_dark).b};
      --bg_dark_gray: #{bg_dark_gray};
      --bg_neutral_gray: #{bg_neutral_gray};
      --bg_light_gray: #{bg_light_gray};
      --bg_lighter_gray: #{bg_lighter_gray};
      --bg_lightest_gray: #{bg_lightest_gray};
      --bg_light: #{bg_light};
      --bg_light_rgb: #{hexToRgb(bg_light).r}, #{hexToRgb(bg_light).g}, #{hexToRgb(bg_light).b};
      --bg_container: #{bg_container};
      --bg_item: #{bg_item};
      --bg_item_rgb: #{hexToRgb(bg_item).r}, #{hexToRgb(bg_item).g}, #{hexToRgb(bg_item).b};
      --bg_item_separator: #{bg_item_separator};
      --bg_speech_bubble: #{bg_speech_bubble};

      --brd_dark: #{brd_dark};
      --brd_dark_gray: #{brd_dark_gray};
      --brd_neutral_gray: #{brd_neutral_gray};
      --brd_mid_gray: #{brd_mid_gray};
      --brd_light_gray: #{brd_light_gray};
      --brd_lightest_gray: #{brd_lightest_gray};
      --brd_light: #{brd_light};

      /* Background transparency variants */
      --bg_item_transparent: rgba(var(--bg_item_rgb), 0.0);
      --bg_dark_trans_25: rgba(var(--bg_dark_rgb), 0.25);
      --bg_dark_trans_40: rgba(var(--bg_dark_rgb), 0.40);
      --bg_dark_trans_60: rgba(var(--bg_dark_rgb), 0.60);
      --bg_dark_trans_80: rgba(var(--bg_dark_rgb), 0.80);
      --bg_light_transparent: rgba(var(--bg_light_rgb), 0.0);
      --bg_light_trans_25: rgba(var(--bg_light_rgb), 0.25);
      --bg_light_trans_40: rgba(var(--bg_light_rgb), 0.40);
      --bg_light_trans_60: rgba(var(--bg_light_rgb), 0.60);
      --bg_light_trans_80: rgba(var(--bg_light_rgb), 0.80);
      --bg_light_opaque: rgba(var(--bg_light_rgb), 1.0);

      /* Shadow colors */
      --shadow_dark_15: rgba(var(--bg_dark_rgb), 0.15);
      --shadow_dark_20: rgba(var(--bg_dark_rgb), 0.20);
      --shadow_dark_25: rgba(var(--bg_dark_rgb), 0.25);
      --shadow_dark_50: rgba(var(--bg_dark_rgb), 0.50);
      --shadow_light: rgba(var(--bg_light_rgb), 0.40);
    }

  /* Dark Theme - Programmatically Generated Inversions */
  [data-theme="dark"],
  [data-theme="dark"] :before,
  [data-theme="dark"] :after {
    /* Inverted text colors for dark theme */
    --text_dark: #{invertColor(text_dark)};
    --text_gray: #{invertColor(text_gray)};
    --text_light_gray: #{invertColor(text_light_gray)};
    --text_neutral: #{invertColor(text_neutral)};
    --text_gray_on_dark: #{invertColor(text_gray_on_dark)};
    --text_light: #{invertColor(text_light)};

    /* Dark backgrounds */
    --bg_dark: #{invertColor(bg_dark)};
    --bg_dark_gray: #{invertColor(bg_dark_gray)};
    --bg_neutral_gray: #{invertColor(bg_neutral_gray)};
    --bg_light_gray: #{invertColor(bg_light_gray)};
    --bg_lighter_gray: #{invertColor(bg_lighter_gray)};
    --bg_lightest_gray: #{invertColor(bg_lightest_gray)};
    --bg_light: #{invertColor(bg_light)};
    --bg_container: #444444;    
    --bg_item: #171717;
    --bg_item_separator: #{invertColor(bg_item_separator)};
    --bg_speech_bubble: #{invertColor(bg_speech_bubble)};
    --bg_light_opaque: #171717ff;

    /* Dark borders */
    --brd_dark: #{invertColor(brd_dark)};
    --brd_dark_gray: #{invertColor(brd_dark_gray)};
    --brd_neutral_gray: #{invertColor(brd_neutral_gray)};
    --brd_mid_gray: #{invertColor(brd_mid_gray)};
    --brd_light_gray: #{invertColor(brd_light_gray)};
    --brd_lightest_gray: #{invertColor(brd_lightest_gray)};
    --brd_light: #{invertColor(brd_light)};
  }

  /* High Contrast Light Theme */
  [data-theme="high-contrast"],
  [data-theme="high-contrast"] :before,
  [data-theme="high-contrast"] :after {
    /* High contrast text - pure black and white */
    --text_dark: #000000;
    --text_gray: #000000;
    --text_light_gray: #000000;
    --text_gray_on_dark: #ffffff;
    --text_light: #ffffff;

    /* High contrast backgrounds - pure black and white */
    --bg_dark: #000000;
    --bg_dark_gray: #000000;
    --bg_neutral_gray: #666666;
    --bg_light_gray: #999999;
    --bg_lighter_gray: #cccccc;
    --bg_lightest_gray: #eeeeee;
    --bg_light: #ffffff;


    /* High contrast borders */
    --brd_dark: #000000;
    --brd_dark_gray: #000000;
    --brd_neutral_gray: #666666;
    --brd_mid_gray: #999999;
    --brd_light_gray: #cccccc;
    --brd_lightest_gray: #eeeeee;
    --brd_light: #ffffff;

    /* Enhanced visibility colors for high contrast */
    --focus_color: #0000ff;
    --selected_color: #880000;
    --success_color: #008000;
    --failure_color: #ff0000;
    --caution_color: #ff8000;


    --focus_color: #{focus_color};
    --selected_color: #97002c;
    --failure_color: #97002c;
    --success_color: #437C2D;
    --caution_color: #8A6700;

  }

  /* High Contrast Dark Theme */
  [data-theme="high-contrast-dark"],
  [data-theme="high-contrast-dark"] :before,
  [data-theme="high-contrast-dark"] :after {
    /* High contrast dark text - pure white and black */
    --text_dark: #ffffff;
    --text_gray: #ffffff;
    --text_light_gray: #ffffff;
    --text_gray_on_dark: #000000;
    --text_light: #000000;

    /* High contrast dark backgrounds - pure white and black inverted */
    --bg_dark: #ffffff;
    --bg_dark_gray: #ffffff;
    --bg_neutral_gray: #999999;
    --bg_light_gray: #666666;
    --bg_lighter_gray: #333333;
    --bg_lightest_gray: #111111;
    --bg_light: #000000;
    --bg_container: #444444;    
    --bg_item: #171717;
    --bg_item_separator: #0f0f0f;
    --bg_speech_bubble: #{invertColor(bg_speech_bubble)};
    --bg_light_opaque: #171717ff;

    /* High contrast dark borders */
    --brd_dark: #ffffff;
    --brd_dark_gray: #ffffff;
    --brd_neutral_gray: #999999;
    --brd_mid_gray: #666666;
    --brd_light_gray: #333333;
    --brd_lightest_gray: #111111;
    --brd_light: #000000;

    /* Enhanced visibility colors for high contrast dark */
    --focus_color: #00ffff;
    --selected_color: #ff00ff;
    --success_color: #00ff00;
    --failure_color: #ff00ff;
    --caution_color: #ffff00;

    --focus_color: #{focus_color};
    --selected_color: #97002c;
    --failure_color: #97002c;
    --success_color: #437C2D;
    --caution_color: #8A6700;

  }

  /* User-agent style integration */
  [data-theme="dark"],
  [data-theme="dark"] :before,
  [data-theme="dark"] :after {
    color-scheme: dark;
  }

  [data-theme="high-contrast"],
  [data-theme="high-contrast"] :before,
  [data-theme="high-contrast"] :after {
    color-scheme: light;
  }

  [data-theme="high-contrast-dark"],
  [data-theme="high-contrast-dark"] :before,
  [data-theme="high-contrast-dark"] :after {
    color-scheme: dark;
  }


  [data-theme="dark"],
  [data-theme="dark"] :before,
  [data-theme="dark"] :after,
  [data-theme="high-contrast-dark"],
  [data-theme="high-contrast-dark"] :before,
  [data-theme="high-contrast-dark"] :after {
    button.btn, 
    input[type='submit'].btn, 
    button.selector_button.active,
    input[type='submit'].selector_button.active, 
    [data-widget="DropMenu"].bluedrop button.dropMenu-anchor, 
    .toggle_buttons .active button,

    #DASHBOARD-menu a.active {
      color: var(--text_dark);
    }

  }



  """

# Function to regenerate themes when colors change
window.updateThemeColors = ->
  window.color_variable_defs = generateColorVariableDefs()
  # Update the actual CSS in the document if it exists
  existing_style = document.getElementById('color-variables-style')
  if existing_style
    existing_style.textContent = window.color_variable_defs

# Generate the CSS once at startup
window.color_variable_defs = generateColorVariableDefs()

# Theme management functions
window.getCurrentTheme = ->
  document.documentElement.getAttribute('data-theme') || 'light'

window.setTheme = (theme) ->
  valid_themes = ['light', 'dark', 'high-contrast', 'high-contrast-dark']
  if theme in valid_themes
    document.documentElement.setAttribute('data-theme', theme)
    localStorage.setItem('considerit-theme', theme)
    # Trigger a custom event for any components that need to respond to theme changes
    window.dispatchEvent(new CustomEvent('themeChanged', { detail: { theme: theme } }))
  else
    console.warn("Invalid theme: #{theme}. Valid themes are: #{valid_themes.join(', ')}")

window.toggleTheme = ->
  current = getCurrentTheme()
  next_theme = switch current
    when 'light' then 'dark'
    when 'dark' then 'high-contrast'
    when 'high-contrast' then 'high-contrast-dark'
    when 'high-contrast-dark' then 'light'
    else 'light'
  setTheme(next_theme)

window.initializeTheme = ->
  # Check for saved theme preference or default to 'light'
  saved_theme = localStorage.getItem('considerit-theme')
  
  # Check for system preference if no saved theme
  if !saved_theme && window.matchMedia
    if window.matchMedia('(prefers-color-scheme: dark)').matches
      saved_theme = 'dark'
    else if window.matchMedia('(prefers-contrast: high)').matches
      saved_theme = 'high-contrast'
  
  theme = saved_theme || 'light'
  setTheme(theme)

# Initialize theme when the script loads
document.addEventListener 'DOMContentLoaded', ->
  initializeTheme()

# Listen for system theme changes
if window.matchMedia
  window.matchMedia('(prefers-color-scheme: dark)').addEventListener 'change', (e) ->
    # Only auto-switch if user hasn't manually set a theme
    if !localStorage.getItem('considerit-theme')
      setTheme(if e.matches then 'dark' else 'light')
  
  window.matchMedia('(prefers-contrast: high)').addEventListener 'change', (e) ->
    # Only auto-switch if user hasn't manually set a theme
    if !localStorage.getItem('considerit-theme')
      setTheme(if e.matches then 'high-contrast' else 'light')


get_css_variable_value = (str) ->
  # Handle CSS variables like 'var(--focus_color)'
  if str?.match(/^var\(/i)
    # Extract variable name from var(--variable-name)
    var_match = str.match(/^var\(\s*(--[^)]+)\s*\)/i)
    if var_match
      var_name = var_match[1].trim()
      # Remove leading -- to get the JavaScript variable name
      js_var_name = var_name.replace(/^--/, '')
      # Try to get the computed CSS variable value first
      try
        computed_value = getComputedStyle(document.documentElement).getPropertyValue(var_name).trim()
        if computed_value
          return computed_value
        else
          # Fallback to JavaScript variable lookup
          if window[js_var_name]?
            return window[js_var_name]
          else
            console.error "CSS variable #{var_name} not found in computed styles or window as #{js_var_name}"
            return null
      catch error
        # Fallback to JavaScript variable lookup if getComputedStyle fails
        if window[js_var_name]?
          return window[js_var_name]
        else
          console.error "CSS variable #{var_name} not found on window as #{js_var_name}"
          return null
  else
    return str


window.parseCssRgb = (css_color_str) ->
  css_color_str = get_css_variable_value(css_color_str)
  if !css_color_str
    return {
      r: 0
      g: 0
      b: 0
    }

  test = document.createElement('div')
  test.style.color = css_color_str
  css_color_str = test.style.color

  if css_color_str == 'transparent'
    {r: 0, g: 0, b: 0, a: 0}
  else  
    rgb = /^rgba?\s*\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+),?\s*([\.\d]+)?\s*\)$/i.exec(css_color_str)

    if rgb 
      return {
        r: parseInt rgb[1]
        g: parseInt rgb[2]
        b: parseInt rgb[3]
        a: if rgb.length > 4 && rgb[4]? then parseFloat(rgb[4]) else 1
      }
    else 
      console.error "Color #{css_color_str} could not be parsed"      
      return {
        r: 0
        g: 0
        b: 0
      }

window.parseCssHsl = (css_color_str) -> 
  rgb = parseCssRgb css_color_str
  rgb2hsl rgb

window.rgb2hsl = (rgb) ->
  r = rgb.r / 255
  g = rgb.g / 255
  b = rgb.b / 255

  max = Math.max(r, g, b)
  min = Math.min(r, g, b)
  l = (max + min) / 2
  if max is min
    h = s = 0 # achromatic
  else
    d = max - min
    s = (if l > 0.5 then d / (2 - max - min) else d / (max + min))
    switch max
      when r
        h = (g - b) / d + ((if g < b then 6 else 0))
      when g
        h = (b - r) / d + 2
      when b
        h = (r - g) / d + 4
    h /= 6
  h: h
  s: s
  l: l

window.hsv2rgb = (h,s,v, as_array) -> 
  h_i = Math.floor(h*6)
  f = h*6 - h_i
  p = v * (1 - s)
  q = v * (1 - f*s)
  t = v * (1 - (1 - f) * s)
  [r, g, b] = [v, t, p] if h_i==0
  [r, g, b] = [q, v, p] if h_i==1
  [r, g, b] = [p, v, t] if h_i==2
  [r, g, b] = [p, q, v] if h_i==3
  [r, g, b] = [t, p, v] if h_i==4
  [r, g, b] = [v, p, q] if h_i==5

  if as_array
    [r, g, b]
  else 
    "rgb(#{Math.round(r*256)}, #{Math.round(g*256)}, #{Math.round(b*256)})"


# fixed saturation & brightness; random hue
# adapted from http://martin.ankerl.com/2009/12/09/how-to-create-random-colors-programmatically/
golden_ratio_conjugate = 0.618033988749895

window.getNiceRandomHues = (num, seed) -> 
  h = seed or .5

  hues = []
  i = num
  while i > 0
    hues.push h % 1
    h += golden_ratio_conjugate
    i -= 1
  hues

window.getColors = (num, continuous) ->
  if continuous
    group_colors = []
    inc = 1 / (num + 1)
    colors = group_colors
    for idx in [0..num-1]
      hue = inc * idx 
      group_colors.push hsv2rgb hue, .75, .65

  else if num >= 3 && num <= 12
    if num <= 5
      group_colors = colorbrewer.Set1[num]
    else if num <= 8
      group_colors = colorbrewer.Dark2[num]
    else 
      group_colors = colorbrewer.Paired[num]
    # group_colors = _.shuffle group_colors
  else 
    group_colors = []
    hues = getNiceRandomHues num
    colors = group_colors
    for hue,idx in hues 
      group_colors.push hsv2rgb hue, Math.random() / 2 + .5, Math.random() / 2 + .5
  
  group_colors



window.is_light_background = (color) ->
  color ||= bus_fetch('edit_banner').background_css or customization('banner')?.background_css or "var(--focus_color)"
  if color of named_colors
    color = named_colors[color]

  parseCssHsl(color).l > .75

hsp_sample_size = 100
window.is_image_mostly_light = (image_data, width, height) ->
  row_sample = _.sample _.range(height), hsp_sample_size
  light_pixels = 0

  for row in row_sample
    col_sample = _.sample _.range(width), hsp_sample_size
    for col in col_sample

      start = row * (width * 4) + col * 4
      r = image_data[start]
      g = image_data[start + 1]
      b = image_data[start + 2]
      hsp = Math.sqrt( # HSP equation from http://alienryderflex.com/hsp.html
          0.299 * (r * r) +
          0.587 * (g * g) +
          0.114 * (b * b)
        ) 
      if hsp > 127.5
        light_pixels += 1

  light_pixels >= hsp_sample_size * hsp_sample_size / 2







window.named_colors =
  'aliceblue': '#f0f8ff'
  'antiquewhite': '#faebd7'
  'aqua': '#00ffff'
  'aquamarine': '#7fffd4'
  'azure': '#f0ffff'
  'beige': '#f5f5dc'
  'bisque': '#ffe4c4'
  'black': '#000000'
  'blanchedalmond': '#ffebcd'
  'blue': '#0000ff'
  'blueviolet': '#8a2be2'
  'brown': '#a52a2a'
  'burlywood': '#deb887'
  'cadetblue': '#5f9ea0'
  'chartreuse': '#7fff00'
  'chocolate': '#d2691e'
  'coral': '#ff7f50'
  'cornflowerblue': '#6495ed'
  'cornsilk': '#fff8dc'
  'crimson': '#dc143c'
  'cyan': '#00ffff'
  'darkblue': '#00008b'
  'darkcyan': '#008b8b'
  'darkgoldenrod': '#b8860b'
  'darkgray': '#a9a9a9'
  'darkgreen': '#006400'
  'darkkhaki': '#bdb76b'
  'darkmagenta': '#8b008b'
  'darkolivegreen': '#556b2f'
  'darkorange': '#ff8c00'
  'darkorchid': '#9932cc'
  'darkred': '#8b0000'
  'darksalmon': '#e9967a'
  'darkseagreen': '#8fbc8f'
  'darkslateblue': '#483d8b'
  'darkslategray': '#2f4f4f'
  'darkturquoise': '#00ced1'
  'darkviolet': '#9400d3'
  'deeppink': '#ff1493'
  'deepskyblue': '#00bfff'
  'dimgray': '#696969'
  'dodgerblue': '#1e90ff'
  'firebrick': '#b22222'
  'floralwhite': '#fffaf0'
  'forestgreen': '#228b22'
  'fuchsia': '#ff00ff'
  'gainsboro': '#DDDDDD'
  'ghostwhite': '#f8f8ff'
  'gold': '#ffd700'
  'goldenrod': '#daa520'
  'gray': '#808080'
  'green': '#008000'
  'greenyellow': '#adff2f'
  'honeydew': '#f0fff0'
  'hotpink': '#ff69b4'
  'indianred': '#cd5c5c'
  'indigo': '#4b0082'
  'ivory': '#fffff0'
  'khaki': '#f0e68c'
  'lavender': '#e6e6fa'
  'lavenderblush': '#fff0f5'
  'lawngreen': '#7cfc00'
  'lemonchiffon': '#fffacd'
  'lightblue': '#add8e6'
  'lightcoral': '#f08080'
  'lightcyan': '#e0ffff'
  'lightgoldenrodyellow': '#fafad2'
  'lightgrey': '#d3d3d3'
  'lightgreen': '#90ee90'
  'lightpink': '#ffb6c1'
  'lightsalmon': '#ffa07a'
  'lightseagreen': '#20b2aa'
  'lightskyblue': '#87cefa'
  'lightslategray': '#778899'
  'lightsteelblue': '#b0c4de'
  'lightyellow': '#ffffe0'
  'lime': '#00ff00'
  'limegreen': '#32cd32'
  'linen': '#faf0e6'
  'magenta': '#ff00ff'
  'maroon': '#800000'
  'mediumaquamarine': '#66cdaa'
  'mediumblue': '#0000cd'
  'mediumorchid': '#ba55d3'
  'mediumpurple': '#9370d8'
  'mediumseagreen': '#3cb371'
  'mediumslateblue': '#7b68ee'
  'mediumspringgreen': '#00fa9a'
  'mediumturquoise': '#48d1cc'
  'mediumvioletred': '#c71585'
  'midnightblue': '#191970'
  'mintcream': '#f5fffa'
  'mistyrose': '#ffe4e1'
  'moccasin': '#ffe4b5'
  'navajowhite': '#ffdead'
  'navy': '#000080'
  'oldlace': '#fdf5e6'
  'olive': '#808000'
  'olivedrab': '#6b8e23'
  'orange': '#ffa500'
  'orangered': '#ff4500'
  'orchid': '#da70d6'
  'palegoldenrod': '#eee8aa'
  'palegreen': '#98fb98'
  'paleturquoise': '#afeeee'
  'palevioletred': '#d87093'
  'papayawhip': '#ffefd5'
  'peachpuff': '#ffdab9'
  'peru': '#cd853f'
  'pink': '#ffc0cb'
  'plum': '#dda0dd'
  'powderblue': '#b0e0e6'
  'purple': '#800080'
  'rebeccapurple': '#663399'
  'red': '#ff0000'
  'rosybrown': '#bc8f8f'
  'royalblue': '#4169e1'
  'saddlebrown': '#8b4513'
  'salmon': '#fa8072'
  'sandybrown': '#f4a460'
  'seagreen': '#2e8b57'
  'seashell': '#fff5ee'
  'sienna': '#a0522d'
  'silver': '#c0c0c0'
  'skyblue': '#87ceeb'
  'slateblue': '#6a5acd'
  'slategray': '#708090'
  'snow': '#fffafa'
  'springgreen': '#00ff7f'
  'steelblue': '#4682b4'
  'tan': '#d2b48c'
  'teal': '#008080'
  'thistle': '#d8bfd8'
  'tomato': '#ff6347'
  'turquoise': '#40e0d0'
  'violet': '#ee82ee'
  'wheat': '#f5deb3'
  'white': '#ffffff'
  'whitesmoke': '#f5f5f5'
  'yellow': '#ffff00'
  'yellowgreen': '#9acd32'