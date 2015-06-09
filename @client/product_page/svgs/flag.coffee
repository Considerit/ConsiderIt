window.flagSVG = (props) ->

  base_width = 100
  base_height = 100

  svg.setSize base_width, base_height, props

  fill_color = props.fill_color or 'black'
  style = props.style or {}

  SVG
    width: props.width 
    height: props.height
    viewBox: "0 0 #{base_width} #{base_height}" 
    version: "1.1" 
    xmlns: "http://www.w3.org/2000/svg" 
    style: style

    G
      strokeWidth: 1
      fill: fill_color

      PATH d: "M52.002,43.221c4.271-4.27,9.365-7.215,14.766-8.852L39.973,7.571c-5.403,1.639-10.497,4.582-14.767,8.854   c-4.271,4.272-7.216,9.365-8.854,14.768L43.147,57.99C44.787,52.587,47.73,47.495,52.002,43.221z"
      PATH d: "M63.127,1c-0.447,0.505-0.908,1.003-1.393,1.486c-4.068,4.066-8.916,6.868-14.056,8.428l27.735,27.737   c5.143-1.561,9.99-4.362,14.055-8.428c0.484-0.483,0.949-0.98,1.398-1.486L63.127,1z"
      PATH d: "M13.484,32.69c-1.254-1.255-3.289-1.255-4.544,0c-1.254,1.254-1.254,3.289,0,4.543l59.165,59.163   c1.254,1.257,3.289,1.257,4.543,0c1.254-1.253,1.254-3.287,0-4.546L13.484,32.69z"