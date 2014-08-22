
do (_) ->
  _.extend window, 

    getTileSize : (width, height, tileCount) ->
      # come up with an initial guess
      aspect = height/width
      xf = Math.sqrt(tileCount/aspect)
      yf = xf*aspect
      x = Math.max(1.0, Math.floor(xf))
      y = Math.max(1.0, Math.floor(yf))
      x_size = Math.floor(width/x)
      y_size = Math.floor(height/y)
      tileSize = Math.min(x_size, y_size)

      # test our guess:
      x = Math.floor(width/tileSize)
      y = Math.floor(height/tileSize)
      if x*y < tileCount # we guessed too high
      
        if ((x+1)*y < tileCount) && (x*(y+1) < tileCount) 
          # case 2: the upper bound is correct
          #         compute the tileSize that will
          #         result in (x+1)*(y+1) tiles
          x_size = Math.floor(width/(x+1))
          y_size = Math.floor(height/(y+1))
          tileSize = Math.min(x_size, y_size)
        else
          # case 3: solve an equation to determine
          #         the final x and y dimensions
          #         and then compute the tileSize
          #         that results in those dimensions
          test_x = Math.ceil(tileCount/y)
          test_y = Math.ceil(tileCount/x)
          x_size = Math.min(Math.floor(width/test_x), Math.floor(height/y))
          y_size = Math.min(Math.floor(width/x), Math.floor(height/test_y))
          tileSize = Math.max(x_size, y_size)
        
      tileSize - 1

    trace : ->
      try
        throw new Error("myError")
      catch e
        console.log e.stack


$(document).ready () ->

  # google analytics
  ( () ->
    ga = document.createElement('script')
    ga.type = 'text/javascript'
    ga.async = true
    ga.src = (if 'https:' == document.location.protocol then 'https://ssl' else 'http://www') + '.google-analytics.com/ga.js'
    s = document.getElementsByTagName('script')[0] 
    s.parentNode.insertBefore(ga, s)

  )()


