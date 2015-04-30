window.serverSVG = (props) ->

  base_width = 70
  base_height = 81

  svg.setSize base_width, base_height, props

  fill_color = props.fill_color or 'black'
  style = props.style or {}

  attrs = _.extend {}, style, 
    width: props.width 
    height: props.height 
    viewBox: "0 0 #{base_width} #{base_height}" 
    version: "1.1" 
    xmlns: "http://www.w3.org/2000/svg" 

  SVG attrs,
    G
      strokeWidth: 1
      fill: fill_color

      G 
        transform: "translate(0.000000, 16.000000)"
        
        PATH d: "M68.8,19.2 L0,19.2 L0,0 L68.8,0 L68.8,19.2 L68.8,19.2 Z M4.8,14.4 L64,14.4 L64,4.8 L4.8,4.8 L4.8,14.4 L4.8,14.4 Z"
        CIRCLE 
          cx: "15.7536" 
          cy: "9.2768" 
          r:  "3.3792"
        ELLIPSE 
          cx: "26.4528" 
          cy: "9.2768" 
          rx: "3.3776" 
          ry: "3.3776"
        RECT 
          x: "46.4" 
          y:  "6.4" 
          width: "4.8" 
          height: "6.4"
      
      G 
        transform: "translate(0.000000, 36.800000)"
        
        PATH d: "M68.8,20.8 L0,20.8 L0,0 L68.8,0 L68.8,20.8 L68.8,20.8 Z M4.8,16 L64,16 L64,4.8 L4.8,4.8 L4.8,16 L4.8,16 Z"
        ELLIPSE 
          cx: "15.7536" 
          cy: "10.3968" 
          rx: "3.3792" 
          ry: "3.3792"
        ELLIPSE 
          cx: "26.4528" 
          cy: "10.3968" 
          rx: "3.3776" 
          ry: "3.3776"
        RECT 
          x: "46.4" 
          y: "8" 
          width: "4.8" 
          height: "6.4"

      G 
        transform: "translate(0.000000, 59.200000)"
        PATH d: "M68.8,20.8 L0,20.8 L0,0 L68.8,0 L68.8,20.8 L68.8,20.8 Z M4.8,16 L64,16 L64,4.8 L4.8,4.8 L4.8,16 L4.8,16 Z"
        ELLIPSE 
          cx: "15.7536" 
          cy: "9.92" 
          rx: "3.3792" 
          ry: "3.3792"
        ELLIPSE 
          cx: "26.4528" 
          cy: "9.92" 
          rx: "3.3776" 
          ry: "3.3776"
        RECT 
          x: "46.4" 
          y: "8" 
          width: "4.8" 
          height: "4.8"

      PATH d: "M67.4976,12.8 L1.1424,12.8 L16.5552,0 L52.0816,0 L67.4976,12.8 Z"