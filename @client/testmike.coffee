# Make the DIV, SPAN, etc.
for el of React.DOM
  window[el.toUpperCase()] = React.DOM[el]

Top = ReactiveComponent
  displayName: 'Top component'
  render : -> 
    @get('Damn!')
    DIV style: { margin: '100px', 'padding': '20px', 'background-color': '#fefdfd' }, 
      "hello I am #{@local_key}"
      Bottom (key: '/point/1')

Bottom = ReactiveComponent
  displayName: 'BOttom'
  render: ->
    @get('oh yeah dude')
    
    DIV style: {margin: '50px', 'background-color': '#e5e5e5', padding: '20px'},
      "Yeah man!  I'm a component #{@local_key}, mounted at key ",
      SPAN style : {'font-weight':'bold' }, "#{@props.key}"
      '.'
      DIV null, 'My nutshell is:',
      DIV null, "Am I anonymous to ya? ",
        SPAN style : {'font-weight':'bold' },
          "#{@bottom.hide_name}"
      DIV style: {'margin': '10px', 'font-style':'italic'},
        @bottom.nutshell
      if @props.key == '/point/1'
        'once more?'
        Bottom (key: '/point/2')

$(document).ready ->
  React.renderComponent Top({'moo', 'bar'}), document.getElementById('content')
