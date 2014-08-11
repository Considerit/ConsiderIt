R = React.DOM

Top = ReactiveComponent
  displayName: 'Top component'

  getDefaultData : ->
    moo : 'bar'

  render : -> 
    @get('Damn!')
    R.div style: { margin: '100px', 'padding': '20px', 'background-color': '#fefdfd' }, 
      "hello I am #{@local_key}"
      Bottom (key: '/point/1')

Bottom = ReactiveComponent
  displayName: 'BOttom'
  render: ->
    @get('oh yeah dude')
    
    R.div style: {margin: '50px', 'background-color': '#e5e5e5', padding: '20px'},
      "Yeah man!  I'm a component #{@local_key}, mounted at key ",
      R.span style : {'font-weight':'bold' }, "#{@props.key}"
      '.'
      R.div null, 'My nutshell is:',
      R.div null, "Am I anonymous to ya? ",
        R.span style : {'font-weight':'bold' },
           "#{@bottom.hide_name}"
      R.div style: {'margin': '10px', 'font-style':'italic'},
        @bottom.nutshell
      if @props.key == '/point/1'
        'once more?'
        Bottom (key: '/point/2')


$(document).ready ->
  React.renderComponent Top({'moo', 'bar'}), document.getElementById('content')
