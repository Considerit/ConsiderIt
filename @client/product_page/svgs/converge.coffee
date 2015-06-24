window.convergeSVG = (props) ->

  base_width = 46
  base_height = 46

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
      strokeWidth: 8
      fill: fill_color

      PATH d: "M0,41 L5,46 L13.7,37.4 L17.5,41.2 L16.6,29.4 L4.9,28.6 L8.7,32.4 L0,41 Z"
      PATH d: "M41.1,28.6 L29.4,29.4 L28.5,41.2 L32.3,37.4 L41,46 L46,41 L37.3,32.4 L41.1,28.6 Z"
      PATH d: "M26.6,0 L19.4,0 L19.4,12.2 L14.1,12.2 L23,19.9 L31.9,12.2 L26.6,12.2 L26.6,0 Z"
