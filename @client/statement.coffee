
window.BUBBLE_WRAP = ReactiveComponent
  displayName: 'BUBBLE_WRAP'

  render: -> 

    left_or_right = 'right' 
    ioffset = -10

    w = @props.width or POINT_WIDTH()
    mouth_w = (@props.mouth_style or {}).width or POINT_MOUTH_WIDTH

    mouth_style = _.defaults (@props.mouth_style or {}),
      top: 8
      position: 'absolute'
      left: -mouth_w + 1
      transform: 'rotate(270deg) scaleX(-1)'

    pic_style = _.defaults {}, (@props.avatar_style or {}),
      position: 'absolute'
      top: 0
      width: 50
      height: 50
      left: -64
      boxShadow: '-1px 2px 0 0 #eeeeee'

    DIV
      style: 
        position: 'relative'
        listStyle: 'none outside none'
        marginBottom: '0.5em'

      if @props.user 
        Avatar
          key: @props.user.key or @props.user 
          style: pic_style
          hide_popover: false 
          anonymous: @props.anon
      else if @props.pic 
        IMG 
          style: pic_style
          src: @props.pic

      DIV 
        style : _.defaults {}, (@props.bubble_style or {}),
          width: w
          borderWidth: 3
          borderStyle: 'solid'
          borderColor: 'transparent'
          position: 'relative'
          zIndex: 1
          outline: 'none'
          padding: 8
          borderRadius: 16
          backgroundColor: considerit_gray
          boxShadow: '#b5b5b5 0 1px 1px 0px'


        DIV 
          style: mouth_style

          Bubblemouth 
            apex_xfrac: 0
            width: mouth_w
            height: mouth_w
            fill: considerit_gray
            stroke: 'none'
            box_shadow: _.defaults {}, (@props.mouth_shadow or {}),   
              dx: 3
              dy: 0
              stdDeviation: 2
              opacity: .5


        @props.children or STATEMENT @props






window.STATEMENT = ReactiveComponent
  displayName: 'Statement'

  render : ->
    title = @props.title 
    body = @props.body

    DIV 
      style: 
        wordWrap: 'break-word'

      DIV 
        style: _.defaults {}, (@props.title_style or {}),
          fontSize: POINT_FONT_SIZE()

        className: 'statement'

        title

      if body 

        DIV 
          className: "statement"

          style: _.defaults {}, (@props.body_style or {}),
            wordWrap: 'break-word'
            marginTop: '0.5em'
            fontSize: POINT_FONT_SIZE()
            fontWeight: 300

          dangerouslySetInnerHTML:{__html: body}


styles += """

.statement a {
  text-decoration: underline;
  // word-break: break-all; 
}

.statement p {
  margin-bottom: 12px; }
"""
