(function($){
/*
 * jquery.borderImage - partial cross-browser implementation of CSS3's borderImage property
 *
 * Copyright (c) 2009 lrbabe (/ɛlɛʁbab/ lrbabe.com)
 * Dual licensed under the MIT (MIT-LICENSE.txt)
 * and GPL (GPL-LICENSE.txt) licenses.
 *
 */

/* TODO:
 * - Empty elements (img, canvas, ...) can't use borderImage without beeing wrapped first.
 * - Use alphaImageLoader instead of VML
 */

$.fn.borderImage = function(value){
  // Test border-image and canvas support on first use
  if(!$.fn.borderImage.initialized) {
    if(document.defaultView && document.defaultView.getComputedStyle) {
      var s = document.defaultView.getComputedStyle(document.body, '');
      if(typeof(document.body.style['-webkitBorderImage']) == 'string') {
        $.browser.support.borderImage = true;
        $.fn.borderImage.prefix = '-webkit';
      } else if(s.getPropertyValue('-moz-border-image') !== '') {
        $.browser.support.borderImage = true;
        $.fn.borderImage.prefix = '-moz';
      }
    }
    if(!$.browser.support.borderImage && document.createElement('canvas').getContext) {
      $.browser.support.canvas = true;
      // Create a global canvas that will be used to draw the slices.
      $.fn.borderImage.bicanvas = document.createElement('canvas');
    }
    $.fn.borderImage.initialized = true;
  }
  
  // Use browsers native implemantation when available.
  if($.browser.support.borderImage) {
    // For single borderImage only
    return (arguments[1] && arguments[1].constructor == String)? $(this) : $(this).css($.fn.borderImage.prefix+'BorderImage', value).css('backgroundColor', 'transparent');
  }
  
  var result = /url\(\s*"(.*?)"\s*\)\s*(\d+)(%)?\s*(\d*)(%)?\s*(\d*)(%)?\s*(\d*)(%)?/.exec(value);
    if(result && ($.browser.support.canvas || $.browser.support.vml)) {    
        
    arguments[0] = result[1];
      var _this = this,
        imageWrapper = document.createDocumentFragment().appendChild(document.createElement('div')),
        argsLength = arguments.length,
        // Use the last argument as resolution if it is a number, otherwise use defaults.
        resolution = arguments[argsLength -1].constructor == Number? arguments[argsLength -1] : $.fn.borderImage.defaults.resolution;
      for(var i = 0; i < argsLength && arguments[i].constructor == String; ++i){
        var img = document.createElement('img');
          img.src = arguments[i];
          // If we don't clone the image, load event may not fire in IE
          imageWrapper.appendChild(img.cloneNode(true));
      }
      imageWrapper.style.position = 'absolute';
      imageWrapper.style.visibility = 'hidden';
      $('body').prepend(imageWrapper);
    
    var $img = $('img:first', imageWrapper).load(function(){
      // Compute cuts
      var imgHeight   = $img.height(),
        imgWidth  = $img.width(),
        topCut    = parseInt(result[2]) * (result[3]? imgHeight/100 : 1),
        rightCut  = result[4]? parseInt(result[4]) * (result[5]? imgWidth/100 : 1) : topCut,
        bottomCut   = result[6]? parseInt(result[6]) * (result[7]? imgHeight/100 : 1) : topCut,
        leftCut   = result[8]? parseInt(result[8]) * (result[9]? imgWidth/100 : 1) : rightCut,
        centerHeight= imgHeight -topCut -bottomCut,
        centerWidth = imgWidth -leftCut -rightCut,
        image = imageWrapper.getElementsByTagName('img'),
        bicanvas = $.fn.borderImage.bicanvas,
        // Draw all the slices
        slice0 = drawSlice(0,           0,            leftCut,    topCut,     image, imgHeight, imgWidth, bicanvas, resolution),
        slice1 = drawSlice(leftCut,       0,            centerWidth,  topCut,     image, imgHeight, imgWidth, bicanvas, resolution),
        slice2 = drawSlice(leftCut+centerWidth, 0,            rightCut,     topCut,     image, imgHeight, imgWidth, bicanvas, resolution),
        slice3 = drawSlice(0,           topCut,         leftCut,    centerHeight, image, imgHeight, imgWidth, bicanvas, resolution),
        slice4 = drawSlice(leftCut,       topCut,         centerWidth,  centerHeight, image, imgHeight, imgWidth, bicanvas, resolution),
        slice5 = drawSlice(leftCut+centerWidth, topCut,         rightCut,     centerHeight, image, imgHeight, imgWidth, bicanvas, resolution),
        slice6 = drawSlice(0,           topCut+centerHeight,  leftCut,    bottomCut,    image, imgHeight, imgWidth, bicanvas, resolution),
        slice7 = drawSlice(leftCut,       topCut+centerHeight,  centerWidth,  bottomCut,    image, imgHeight, imgWidth, bicanvas, resolution),
        slice8 = drawSlice(leftCut+centerWidth, topCut+centerHeight,  rightCut,     bottomCut,    image, imgHeight, imgWidth, bicanvas, resolution),
        borderTop, borderRight, borderBottom, borderLeft,
        prevFragment;
        
      _this.each(function(i, el){
        var $this = $(el),
          thisStyle = {
            position: 'relative',
            borderColor: 'transparent',
            //background: 'none',
            padding: 0
          },
          innerWrapper = document.createElement('div'),
          reuse = true,
          thisDisplay = $this.css('display');
          
        // There is many case where "display: 'inline'" actually is a problem.
        if(thisDisplay == 'inline')
          thisStyle.display = 'inline-block';         
        // IE7 Should be served inline instead of inline-block
        else if((($.browser.msie && $.browser.version == 7) 
          || (document.documentMode && document.documentMode == 7)) 
        && $this.css('display') == 'inline-block')
            thisStyle.display = 'inline';
        
        /* When the element is absolute positionned but has a relative
         * a relative postionned ancestor, don't change its position.
         */       
        if($this.css('position') == 'absolute') {
          do {
            if ($.curCSS(el, 'position') == 'relative') {
              thisStyle.position = 'absolute';
              break;
            }
          } while (el = el.parentNode);
        }     
          
        innerWrapper.style.paddingTop = $this.css('paddingTop');
        innerWrapper.style.paddingLeft = $this.css('paddingLeft');
        innerWrapper.style.paddingBottom = $this.css('paddingBottom');
        innerWrapper.style.paddingRight = $this.css('paddingRight');
        innerWrapper.style.position = 'relative';
        innerWrapper.className = 'biWrapper';
        $this.css(thisStyle).wrapInner(innerWrapper);
        
        if(borderTop != $this.css('borderTopWidth')) {
          borderTop = $this.css('borderTopWidth');
          reuse = false;
        }
        if(borderBottom != $this.css('borderBottomWidth')) {
          borderBottom = $this.css('borderBottomWidth');
          reuse = false;
        }
        if(borderRight != $this.css('borderRightWidth')) {
          borderRight = $this.css('borderRightWidth');
          reuse = false;
        }
        if(borderLeft != $this.css('borderLeftWidth')) {
          borderLeft = $this.css('borderLeftWidth');
          reuse = false;
        }
        
        // Reuse previous fragment if borderWidths are the same.
        if(!reuse) {
          var fragment = document.createDocumentFragment();         
          
          // Create the magical tiles
          drawBorder({top:'-'+borderTop, left:'-'+borderLeft, height: borderTop, width: borderLeft},        slice0, fragment);
          drawBorder({top:'-'+borderTop, left: 0, width: '100%', height: borderTop},                slice1, fragment);
          drawBorder({top:'-'+borderTop, right:'-'+borderRight, height: borderTop, width: borderRight},       slice2, fragment);                  
          drawBorder({top: 0, bottom:0, left:'-'+borderLeft, width: borderLeft, height: '100%'},          slice3, fragment);          
          drawBorder({left: 0, top: 0, right: 0, bottom: 0, height: '100%', width: '100%'},           slice4, fragment);
          drawBorder({top: 0, bottom:0, right:'-'+borderRight, width: borderRight, height: '100%'},         slice5, fragment);                  
          drawBorder({bottom:'-'+borderBottom, left:'-'+borderLeft, width: borderLeft, height: borderBottom},   slice6, fragment);
          drawBorder({bottom:'-'+borderBottom, left: 0, width:'100%', height: borderBottom},            slice7, fragment);
          drawBorder({bottom:'-'+borderBottom, right:'-'+borderRight, height: borderBottom, width: borderRight},  slice8, fragment);
          
          prevFragment = fragment;
        }
        $this.prepend(prevFragment.cloneNode(true));              
      });
    });
    // Is there an explanation why we need this line to have all the slices actually drawn?
    if($.browser.support.vml)
      $('body')[0].appendChild(document.createElement('biv:image'));
  }
  return $(this); 
};

// Test vml support as early as possible.
if(!$.browser.support)
  $.browser.support = {}; 
if (document.namespaces && !document.namespaces['biv']) {
  document.namespaces.add('biv', 'urn:schemas-microsoft-com:vml', "#default#VML");
  document.createStyleSheet().addRule('biv\\: *', "behavior: url(#default#VML);");
  $.browser.support.vml = true;
  $.fn.borderImage.initialized = true;
 }

$.fn.borderImage.defaults = {
  resolution: 20
};

function drawSlice(sx, sy, sw, sh, image, imgHeight, imgWidth, bicanvas, resolution) {
  var slice = document.createDocumentFragment();
  // Don't waste time drawing slice with null dimension
  if(sw > 0 && sh > 0) {
    if($.browser.support.canvas)
      bicanvas.setAttribute('height', resolution+'px');
    
    for(var i = 0; i < image.length; ++i) {
      if($.browser.support.canvas) {
        // Clear the global canvas and use it to draw a new slice
        bicanvas.setAttribute('width', resolution+'px');
        bicanvas.getContext('2d').drawImage(image[i], sx, sy, sw, sh, 0, 0, resolution, resolution);
        // Store the slice in an image in order to reuse it
        var el = document.createElement('img');
        el.src = bicanvas.toDataURL();
      } else {
        // Could you explain me why we can't just use "document.createElement('biv:image')"?
        var el = document.createElement('div');
        el.insertAdjacentHTML('BeforeEnd', 
          '<biv:image src="'+image[i].src+'" cropleft="'+sx/imgWidth+'" croptop="'+sy/imgHeight+'" cropright="'+(imgWidth-sw-sx)/imgWidth+'" cropbottom="'+(imgHeight-sh-sy)/imgHeight+'" />' );
        el = el.firstChild;
      }
      el.style.width = el.style.height = '100%';
      el.style.position = 'absolute';
      el.style.border = 'none';
      el.className = 'biSlice image'+i;
      slice.appendChild(el);
    }
  }
  return slice;
}

function drawBorder(style, slice, fragment) {
  // Don't waste time drawing borders with null dimension
  if(parseInt(style.width) != 0 && parseInt(style.height) != 0) {
    var el = document.createElement('div');
    for(var i in style)
      el.style[i] = style[i];
    el.style.position = 'absolute';
    el.style.textAlign = 'left';
    el.appendChild(slice.cloneNode(true));
    fragment.appendChild(el);
  }           
}

/*
 * Helper function to resize an element potentially decorated with an emulated border-image, using an animation.
 */
$.fn.biResize = function(newDimensions, options) {
  return this.each(function(i, el){
    var $el = $(el),
      $biWrap = $el.find('.biWrapper');
      // If the content is wrapped, it means the browser is emulating borderImage
        if($biWrap.length) {
            // transfer dimensions to the internal wrapper
            $biWrap.css({ width: $el.css('width'), height: $el.css('height') });
            $el.css({ width: 'auto', height: 'auto' });
            // Resize the internal wrapper instead
            $biWrap.animate(newDimensions, options);
        // If the native implementation is used, you can resize the element itself
        } else
        $el.animate(newDimensions, options);
  });
};
})(jQuery);