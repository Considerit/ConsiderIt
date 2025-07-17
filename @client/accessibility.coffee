require './shared'

# Screen reader announcement system for accessibility
# Provides a reactive component for making announcements to screen readers

styles += """
  .sr-only {
    position: absolute;
    width: 1px;
    height: 1px;
    padding: 0;
    margin: -1px;
    overflow: hidden;
    clip: rect(0, 0, 0, 0);
    white-space: nowrap;
    border: 0;
  }
  
  #sr-announcements-polite,
  #sr-announcements-assertive {
    position: absolute;
    left: -10000px;
    width: 1px;
    height: 1px;
    overflow: hidden;
  }
  
  /* Ensure screen reader announcements don't interfere with layout */
  .screen-reader-announcements * {
    position: static !important;
    width: auto !important;
    height: auto !important;
  }
"""

# Generate unique ID for announcements
generate_announcement_id = ->
  "announcement_#{Date.now()}_#{Math.random().toString(36).substr(2, 9)}"

# Remove expired announcements
clean_expired_announcements = ->
  announcements = bus_fetch('screen_reader_announcements')
  announcements.queue ?= []
  
  now = Date.now()
  announcements.queue = announcements.queue.filter (announcement) ->
    announcement.expires_at > now
  
  save announcements

# Main function to announce messages to screen readers
# Usage: 
#   announceToScreenReader("Filter updated")
#   announceToScreenReader("Error occurred", {priority: 'assertive', ttl: 5000})
window.announceToScreenReader = (message, options = {}) ->
  return unless message
  
  # Handle legacy time_in_ms parameter
  if typeof options == 'number'
    options = {ttl: options}
  
  # Default options
  ttl = options.ttl ? options.time_in_ms ? 3000
  priority = options.priority ? (if options.assertive then 'assertive' else 'polite')
  aria_live = if priority == 'assertive' || priority == true then 'assertive' else 'polite'
  
  announcements = bus_fetch('screen_reader_announcements')
  announcements.queue ?= []
  
  # Clean expired announcements first
  clean_expired_announcements()
  
  # Create new announcement
  announcement = 
    id: generate_announcement_id()
    message: message
    aria_live: aria_live
    role: if aria_live == 'assertive' then 'alert' else 'status'
    created_at: Date.now()
    expires_at: Date.now() + ttl
  
  # Add to queue
  announcements.queue.push(announcement)
  save announcements
  
  # Set timeout to clean this specific announcement
  setTimeout ->
    clean_expired_announcements()
  , ttl

# Convenience function for assertive announcements
window.announceToScreenReaderAssertive = (message, ttl = 2000) ->
  announceToScreenReader(message, {priority: 'assertive', ttl: ttl})

# ReactiveComponent for screen reader announcements
# Include this in your main app layout to enable announcements
window.ScreenReaderAnnouncement = ReactiveComponent
  displayName: 'ScreenReaderAnnouncement'
  
  componentDidMount: ->
    # Clean expired announcements periodically
    @cleanup_interval = setInterval ->
      clean_expired_announcements()
    , 1000
  
  componentWillUnmount: ->
    if @cleanup_interval
      clearInterval @cleanup_interval
  
  render: ->
    announcements = bus_fetch('screen_reader_announcements')
    announcements.queue ?= []
    
    # Group announcements by aria-live type
    polite_announcements = announcements.queue.filter (a) -> a.aria_live == 'polite'
    assertive_announcements = announcements.queue.filter (a) -> a.aria_live == 'assertive'
    
    DIV
      className: 'screen-reader-announcements'
      
      # Polite announcements region
      if polite_announcements.length > 0
        DIV
          id: 'sr-announcements-polite'
          className: 'sr-only'
          'aria-live': 'polite'
          'aria-atomic': 'true'
          role: 'status'
          
          for announcement in polite_announcements
            SPAN
              key: announcement.id
              dangerouslySetInnerHTML: {__html: announcement.message}
      
      # Assertive announcements region  
      if assertive_announcements.length > 0
        DIV
          id: 'sr-announcements-assertive'
          className: 'sr-only'
          'aria-live': 'assertive'
          'aria-atomic': 'true'
          role: 'alert'
          
          for announcement in assertive_announcements
            SPAN
              key: announcement.id
              dangerouslySetInnerHTML: {__html: announcement.message}
