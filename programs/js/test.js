function hoistWhitespace(str) {
  return str.replace(/(<[^>]+>)(\s+)/g, '$2$1');
}

console.log(hoistWhitespace("<b> 70%</b>"))
