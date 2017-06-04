######
# Draws a bubble mouth svg. 
# 
#           
#          p3
#         •  
#       /  \ 
#     (     \_
#     \       `\___
#  p1  `•          `- • p2
#
#       <-^----------->
#       apex =~ .15
#
# Props:
#  width: width of the element
#  height: height of the element
#  svg_w: controls the viewbox width
#  svg_h: controls the viewbox height
#  skew_x: the amount the mouth juts out to the side
#  skew_y: the focal location of the jut
#  apex_xfrac: see diagram. The percent between the p1 & p2 that p3 is. 
#  fill, stroke, stroke_width, dash_array, box_shadow

require './shared'
require './svg'
# md5 = require './vendor/md5' 

window.Bubblemouth = (props) -> 

  # width/height of bubblemouth in svg coordinate space
  _.defaults props,
    svg_w: 85
    svg_h: 100
    skew_x: 15
    skew_y: 80
    apex_xfrac: .5
    fill: 'white', 
    stroke: focus_color(), 
    stroke_width: 10
    dash_array: "none"   
    box_shadow: null

  full_width = props.svg_w + 4 * props.skew_x * Math.max(.5, Math.abs(.5 - props.apex_xfrac))

  _.defaults props, 
    width: full_width
    height: props.svg_h

  apex = props.apex_xfrac
  svg_w = props.svg_w
  svg_h = props.svg_h
  skew_x = props.skew_x
  skew_y = props.skew_y

  cx = skew_x + svg_w / 2

  [x1, y1]   = [  skew_x - apex * skew_x,              svg_h ] 
  [x2, y2]   = [  skew_x + apex * svg_w,                   0 ]
  [x3, y3]   = [      x1 + svg_w + skew_x,             svg_h ]

  [qx1, qy1] = [ -skew_x + apex * ( cx + 2 * skew_x), skew_y ] 
  [qx2, qy2] = [  qx1 + cx,                           skew_y ]                           

  bubblemouth_path = """
    M  #{x1}  #{y1}
    Q #{qx1} #{qy1}
       #{x2}  #{y2}
    Q #{qx2} #{qy2}
       #{x3}  #{y3}
    
  """

  id = "x#{md5(JSON.stringify(props))}-#{(Math.random() * 100000).toFixed(0)}"

  x_pad = 0 
  if props.box_shadow
    x_pad = (props.box_shadow.dx or 0) + (props.box_shadow.stdDeviation or 0)

  SVG 
    version: "1.1" 
    xmlns: "http://www.w3.org/2000/svg"
    width: props.width
    height: props.height
    viewBox: "#{x_pad} 0 #{full_width} #{svg_h}"
    preserveAspectRatio: "none"
    style: if props.style then props.style

    DEFS null,

      # enforces border drawn exclusively inside
      CLIPPATH
        id: id
        PATH
          strokeWidth: props.stroke_width * 2
          d: bubblemouth_path

      if props.box_shadow
        svg.dropShadow _.extend props.box_shadow, 
          id: "#{id}-shadow"

    if props.box_shadow
      # can't apply drop shadow to main path because of 
      # clip path. So we'll apply it to a copy. 
      PATH
        key: 'shadow'
        fill: props.fill
        style: 
          filter: "url(##{id}-shadow)"
        d: bubblemouth_path
        
    PATH
      key: 'stroke'
      fill: props.fill
      stroke: props.stroke
      strokeWidth: props.stroke_width * 2
      clipPath: "url(##{id})"
      strokeDasharray: props.dash_array
      d: bubblemouth_path


 