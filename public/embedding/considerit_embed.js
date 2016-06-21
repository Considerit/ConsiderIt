// insert iframeResizer into DOM
var resizer = document.createElement("script")
resizer.src = '//cdnjs.cloudflare.com/ajax/libs/iframe-resizer/3.5.3/iframeResizer.min.js'
resizer.id = 'iframeresizer'
var fjs = document.getElementsByTagName('script')[0]
fjs.parentNode.insertBefore(resizer, fjs)

// get all the desired embeds
var embeds = document.querySelectorAll('[data-considerit-embed]')
var loaded_iframes = 0
for (var i = 0; i < embeds.length; i++){
  var embed = embeds[i]
  
  var parts = embed.href.split('/')
  var slug = parts.pop()
  
  iframe = document.createElement("iframe")
  iframe.id = 'considerit-embed-' + i
  iframe.className = 'considerit-embed'
  iframe.src = parts.join('/') + '/embed/proposal/' + slug
  iframe.style = "overflow:hidden"
  iframe.frameBorder = '0'
  iframe.width = '700'

  if (iframe.attachEvent)
    iframe.attachEvent("onload", function(){loaded_iframes++})
  else
    iframe.onload = function(){loaded_iframes++}
  
  embed.parentNode.insertBefore(iframe,embed)
}

// engage iframe resizing when available
var considerit_iframe_int = setInterval(function(){
  var iframes = document.querySelectorAll('.considerit-embed')
  if (typeof iFrameResize != 'undefined' && loaded_iframes == iframes.length){
    for (var i=0; i < iframes.length; i++){
      iframe = iframes[i]
      iFrameResize({log:false, checkOrigin: false}, iframe)
      iframe.iFrameResizer.sendMessage('Houston, we have contact!')
    }
    clearInterval(considerit_iframe_int)
  }
}, 40)
