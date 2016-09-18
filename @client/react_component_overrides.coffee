
# Note that browser_location overrides the A element


old_IMG = IMG
window.IMG = React.createClass
  render : -> 

    props = @props
    if !props.rel?
      console.error "Accessibility: IMG doesn't have REL attribute set!", @props

    old_IMG props, props.children
