function log_general(el, action, extra, async){
  if (!async){
    async = true;
  }
  var data = {
    general_log: {
      el_id: $j(el).attr('id'),
      el_class: $j(el).attr('class'),
      tag: el.nodeName.toLowerCase(),
      page: window.location.pathname,
      action: action,
      extra: extra
    }
  };
  
  $j.ajax({
    type: 'POST',
    url: '/study/general_log',
    data: data,
    async: async,
    success: function(){}
  });  
  
}
