R = React.DOM

Top = NonReactiveComponent
  displayName: 'Top component'

  getDefaultData : ->
    moo : 'bar'

  render : -> 
    @get('Damn!')
    R.div style: { margin: '100px', 'padding': '20px', 'background-color': '#fefdfd' }, 
      'hello'
      Bottom (key: '/point/1')

Bottom = NonReactiveComponent
  displayName: 'BOttom'
  render: ->
    @get('oh yeah dude')
    point = @get()
    R.div(style: {margin: '50px', 'background-color': '#e5e5e5', padding: '20px'},
      "Yeah man!  I'm a component, mounted at key ",
      R.span style : {'font-weight':'bold' }, "#{@props.key}"
      '.'
      R.div null, 'My nutshell is:'
      R.div style: {'margin': '10px', 'font-style':'italic'},
        point.nutshell)
$(document).ready ->
  React.renderComponent Top({'moo', 'bar'}), document.getElementById('content')
