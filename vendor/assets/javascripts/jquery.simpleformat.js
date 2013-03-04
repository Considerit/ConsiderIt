// from https://makandracards.com/makandra/1395-simple_format-helper-for-javascript & https://gist.github.com/huned/865391

$.fn.simpleFormat = function() {
  str = $.trim(str.replace(/\r\n?/, "\n"));
  if (str.length > 0) {
    str = '<p>' + str.replace(/\n\n+/g, '</p><p>').replace(/\n/g, '<br />') + '</p>';
  }
  return str;
}