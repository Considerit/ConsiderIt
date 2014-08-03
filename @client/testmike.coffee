R = React.DOM

Top = NonReactiveComponent
  displayName: 'Top component'

  getDefaultData : ->
    moo : 'bar'

  render : -> 
    @get('Damn!')
    R.div id: 'body', style : { margin: '100px' }, 
      R.div id: 'inner_body',
        'hello'
        Bottom key: '/point/1'

Bottom = NonReactiveComponent
  displayName: 'BOttom'
  render: ->
    @get('oh yeah dude')
    point = @get()
    R.div style : {margin: '50px'},
      "Yeah man!  I'm key #{@props.key}",
      R.div style : {'margin': '10px 0'},
        point.nutshell
$(document).ready ->
  React.renderComponent Top({'moo', 'bar'}), document.getElementById('content')
