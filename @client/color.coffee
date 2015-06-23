##################
# Colors
#
# Colors are primarily stored in the database (to allow customers & Kev to self-brand).
# See @server/models/subdomain#branding_info for hardcoding color values
# when doing development. 

window.focus_blue = '#2478CC'
window.logo_red = "#B03A44"
window.default_avatar_in_histogram_color = '#d3d3d3'
window.considerit_gray = '#f6f7f9'

window.parseCssRgb = (css_color_str) ->
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

window.hsv2rgb = (h,s,v) -> 
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

  "rgb(#{Math.round(r*256)}, #{Math.round(g*256)}, #{Math.round(b*256)})"


window.addOpacity = (color, opacity) -> 
  c = parseCssRgb color
  "rgba(#{c.r},#{c.g},#{c.b},#{opacity}"

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