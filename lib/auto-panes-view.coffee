module.exports =
class AtomAutoPanesView
  constructor: (serializeState) ->
    @element = document.createElement('div')
    @element.classList.add('auto-panes')
    @element.classList.add('highlight-success')
    @message = document.createElement('div')
    @message.classList.add('message')
    @element.appendChild(@message)

  # Returns an object that can be retrieved when package is activated
  serialize: ->

  # Tear down any state and detach
  destroy: ->
    @element.remove()

  getElement: ->
    @element
