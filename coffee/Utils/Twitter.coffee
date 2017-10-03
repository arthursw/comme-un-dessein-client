window.twttr = ((d, s, id) ->
  js = undefined
  fjs = d.getElementsByTagName(s)[0]
  t = window.twttr or {}
  if d.getElementById(id)
    return t
  js = d.createElement(s)
  js.id = id
  js.src = 'https://platform.twitter.com/widgets.js'
  fjs.parentNode.insertBefore js, fjs
  t._e = []

  t.ready = (f) ->
    t._e.push f
    return

  t
)(document, 'script', 'twitter-wjs')
