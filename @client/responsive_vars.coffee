require './browser_hacks'

#########
#  Responsive
#
# Controls changes to shared system variables based upon characteristics of the device. 
# Primarily changes based on window width. 
#
# Publishes via StateBus "responsive_vars" that has all the variables. 
#
# A convenience method for accessing those variables is provided. Say you want to do 
# fetch('responsive_vars').CONTENT_WIDTH. Instead you can just write CONTENT_WIDTH().  
#
#

######
# setResponsive
#
# Updates the responsive variables. Called once on system load, and then subsequently
# whenever there is a relevant system event that would demand the variables to be 
# recalculated (e.g. window resizing)



window.PHONE_BREAKPOINT = 545 
window.TABLET_BREAKPOINT = 990


setResponsive = -> 
  responsive = fetch('responsive_vars')

  w = Math.max 350, document.documentElement.clientWidth
  h = window.innerHeight

  one_col = w < TABLET_BREAKPOINT
  phone_size = w < PHONE_BREAKPOINT

  portrait = h > w

  # There will be at least 80px of whitespace on either side of the document
  doc_gutter = if phone_size then 16 else if one_col then 40 else Math.max(80, .09 * w )
  content_width = w - 2 * doc_gutter
  homepage_width = Math.round Math.min content_width, 1200


  new_vals = 
    WINDOW_WIDTH: w    
    DOC_GUTTER: doc_gutter
    DASHBOARD_WIDTH: Math.max(900, w)
    AUTH_WIDTH: if browser.is_mobile then content_width else 820
    TABLET_SIZE: one_col
    PHONE_SIZE: phone_size    
    CONTENT_WIDTH: content_width
    PORTRAIT_MOBILE: portrait && browser.is_mobile
    LANDSCAPE_MOBILE: !portrait && browser.is_mobile
    HOMEPAGE_WIDTH: homepage_width
    SAAS_PAGE_WIDTH: Math.min(1120, w - 2 * 24)

  for registry in responsive_style_registry
    _.extend new_vals, registry(new_vals)

  # only update if we have a change
  # (something like this should go into statebus)
  needs_save = false
  for k,v of new_vals

    # Convenience method for programmers to access responsive variables.
    window[k] ?= do(k) -> -> fetch('responsive_vars')[k]

    needs_save ||= responsive[k] != v

  if needs_save
    _.extend responsive, new_vals
    save responsive


styles += """

  @media (min-width: #{TABLET_BREAKPOINT}px) {
    :after, :root {
      --DOC_GUTTER: max(80px, 9vw);
    }
  }

  @media (min-width: #{PHONE_BREAKPOINT}px) and (max-width: #{TABLET_BREAKPOINT}px) {
    :after, :root {
      --DOC_GUTTER: 40px;
    }

  }

  @media (max-width: #{PHONE_BREAKPOINT}px) {
    :after, :root {
      --DOC_GUTTER: 16px;
    }
  }

  :after, :root {
    --WINDOW_WIDTH: max(350px, 100vw);
    --SAAS_PAGE_WIDTH: min(1120px, 100vw - 2 * 24px);
    --HOMEPAGE_WIDTH:  min(1200px, 100vw - 2 * var(--DOC_GUTTER));
    --CONTENT_WIDTH: calc(var(--WINDOW_WIDTH) - 2 * var(--DOC_GUTTER));
  }

"""

window.responsive_style_registry = []



# Initialize the responsive variables on page load.
setTimeout setResponsive

# Whenever the window resizes, we need to recalculate the variables.
window.addEventListener "resize", setResponsive


# Trying to make sure to catch events (like initial auto zoom) that lead to viewport changes
window.addEventListener "gestureend", setResponsive
window.matchMedia('screen and (min-resolution: 2dppx)').addEventListener "change", setResponsive






