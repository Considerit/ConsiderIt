##################
# Colors


window.focus_blue = '#2478CC'
window.logo_red = "#B03A44"
window.default_avatar_in_histogram_color = '#999'
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


window.is_light_background = (color) ->
  color ||= fetch('edit_banner').background_css or customization('banner')?.background_css or DEFAULT_BACKGROUND_COLOR
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

named_colors =
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
  'gainsboro': '#dcdcdc'
  'ghostwhite': '#f8f8ff'
  'gold': '#ffd700'
  'goldenrod': '#daa520'
  'gray': '#808080'
  'green': '#008000'
  'greenyellow': '#adff2f'
  'honeydew': '#f0fff0'
  'hotpink': '#ff69b4'
  'indianred ': '#cd5c5c'
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

