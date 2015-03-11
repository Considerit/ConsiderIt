########
# Helper methods for creating SVGs
# 

window.svg = 

  dropShadow: (props) -> 
    FILTER 
      id: props.id

      FEOFFSET
        in: "SourceAlpha"          
        dx: props.dx
        dy: props.dy
        result: "offsetblur" 

      FEGAUSSIANBLUR
        in: 'offsetblur'
        stdDeviation: props.stdDeviation #how much blur
        result: 'blur2'

      FECOLORMATRIX
        in: 'blur2'
        result: 'color'
        type: 'matrix'
        values: """
          0 0 0 0  0
          0 0 0 0  0 
          0 0 0 0  0 
          0 0 0 #{props.opacity} 0"""


      FEMERGE null,
        FEMERGENODE 
          in: 'color'
        FEMERGENODE 
          in: 'SourceGraphic'


  innerbevel: (props) -> 
    FILTER
      id: props.id
      x0: "-50%" 
      y0: "-50%" 
      width: "200%" 
      height: "200%"

      for shadow, idx in props.shadows

        [FEGAUSSIANBLUR
          in: if idx == 0 then 'SourceAlpha' else "result#{idx}"
          stdDeviation: shadow.stdDeviation 
          result: "blur#{idx}"

        FEOFFSET
          dy: shadow.dy
          dx: shadow.dx

        FECOMPOSITE
          in2: 'SourceAlpha' #if idx == 0 then 'SourceAlpha' else "result#{idx}"
          operator: "arithmetic" 
          k2: "-1" 
          k3: "1" 
          result: "shadowDiff"

        FEFLOOD
          floodColor: shadow.color
          floodOpacity: shadow.opacity

        FECOMPOSITE
          in2: "shadowDiff" 
          operator: "in" 

        FECOMPOSITE
          in2: if idx == 0 then 'SourceGraphic' else "result#{idx - 1}"
          operator: "over" 
          result: "result#{idx}"
        ]    
