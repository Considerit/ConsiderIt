# We detect mobile browsers by inspecting the user agent. This check isn't perfect.
rxaosp = window.navigator.userAgent.match /Android.*AppleWebKit\/([\d.]+)/ 

is_android_browser = !!(rxaosp && rxaosp[1]<537)
window.browser = 
  is_android_browser : is_android_browser  # stock android browser (not chrome)
  is_opera_mini : !!navigator.userAgent.match /Opera Mini/
  is_ie9 : !!(document.documentMode && document.documentMode == 9)
  is_iOS : !!navigator.platform.match(/(iPad|iPhone)/)
  touch_enabled : 'ontouchend' in document
  high_density_display : ((window.matchMedia && 
                           (window.matchMedia('''
                              only screen and (min-resolution: 124dpi), 
                              only screen and (min-resolution: 1.3dppx), 
                              only screen and (min-resolution: 48.8dpcm)''').matches || 
                            window.matchMedia('''
                              only screen and (-webkit-min-device-pixel-ratio: 1.3), 
                              only screen and (-o-min-device-pixel-ratio: 2.6/2), 
                              only screen and (min--moz-device-pixel-ratio: 1.3), 
                              only screen and (min-device-pixel-ratio: 1.3)''').matches
                            )) || 
                          (window.devicePixelRatio && window.devicePixelRatio > 1.3))
  is_mobile :  is_android_browser ||
                navigator.userAgent.match(/Android/i) || 
                navigator.userAgent.match(/webOS/i) ||
                navigator.userAgent.match(/iPhone/i) ||
                navigator.userAgent.match(/iPad/i) ||
                navigator.userAgent.match(/iPod/i) ||
                navigator.userAgent.match(/BlackBerry/i) ||
                navigator.userAgent.match(/Windows Phone/i)


# Displays warnings for some browsers
# Stores state about the current device. 
# Note that IE<9 users are redirected at
# an earlier point to an MS upgrade site. 
window.BrowserHacks = ReactiveComponent
  displayName: 'BrowserHacks'

  render : ->
    browser = fetch 'browser'
    if  browser.is_opera_mini #|| browser.is_android_browser
      DIV 
        style: 
          backgroundColor: 'red'
          padding: 10
          textAlign: 'center'
          color: 'white'
          fontSize: 24

        "This website does not work well with "
        if browser.is_android_browser then 'the Android Browser' else 'Opera Mini'
        ". Please use "
        A 
          href: "https://play.google.com/store/apps/details?id=com.android.chrome&hl=en"
          style: 
            color: 'white'
            textDecoration: 'underline'
          'Chrome for Android' 
        ' if you experience difficulty. Thanks, and sorry for the inconvenience!'

    else 
      # Use third party script for detecting and warning users
      # of other outdated browsers. Sticking with
      # third party for now because of some complexities
      # in detecting some of these browser versions. In 
      # the future, probably want to extract the logic. 
      # "https://browser-update.org/update.html"
      SCRIPT type: 'text/javascript', src: '//browser-update.org/update.js'
