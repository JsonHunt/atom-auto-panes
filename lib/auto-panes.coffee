path = require 'path'
fs = require 'fs'

AtomAutoPanesView = require './auto-panes-view'
{CompositeDisposable} = require 'atom'

module.exports = AtomAutoPanes =
  atomAutoPanesView: null
  modalPanel: null
  subscriptions: null
  toIgnore: []
  enabled: false

  config:
    autoClose:
      type: 'boolean'
      default: true
      title: 'When a file is opened, all other editors save and close'
    multiEditors:
      type: 'string'
      default: 'Open in new pane'
      title: 'When a file is opened, files with the same name will:'
      enum: ['Not open','Open in new pane']

  activate: (state) ->
    @atomAutoPanesView = new AtomAutoPanesView(state.atomAutoPanesViewState)
    @modalPanel = atom.workspace.addModalPanel(item: @atomAutoPanesView.getElement(), visible: false)

    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace', 'auto-panes:toggle': => @toggle()

  onNewEditor: (editor) =>
    filePath = editor.getPath()
    self = atom.packages.loadedPackages['atom-auto-panes'].mainModule

    if filePath in self.toIgnore
      self.toIgnore.splice(self.toIgnore.indexOf(filePath),1)
      return

    activePane = atom.workspace.getActivePane()
    if atom.config.get('atom-auto-panes.autoClose')
      atom.workspace.getPanes().forEach (pane)->
        if pane isnt activePane
          pane.getItems().forEach (item)->
            if item.save and item.isModified and item.isModified()
              item.save()
          pane.destroy()
      obs = activePane.onDidChangeActiveItem ()->
        activePane.getItems().forEach (item)->
          if item.save and item.isModified and item.isModified() and item isnt activePane.getActiveItem()
            item.save()
        activePane.destroyInactiveItems()
        obs.dispose()

    if atom.config.get('atom-auto-panes.multiEditors') is 'Open in new pane'
      obj = path.parse(filePath)
      curPane = activePane
      direction = "right"

      fs.readdir obj.dir, (err,files)->
        files.forEach (filename)->
          return if obj.base is filename
          return if filename.split('.')[0] isnt obj.name
          extPath = "#{obj.dir}#{path.sep}#{filename}"
          if fs.existsSync(extPath)
            self.toIgnore.push(extPath)
            curPane = curPane.splitRight() if direction is 'right'
            curPane = curPane.splitDown() if direction is 'down'
            direction = 'down'
            atom.workspace.openURIInPane(extPath,curPane,{activatePane: false})

        activePane.activate()


  deactivate: ->
    @modalPanel.destroy()
    @subscriptions.dispose()
    @atomAutoPanesView.destroy()
    if @editorObserver
      @editorObserver.dispose()
      delete @editorObserver

  serialize: ->
    atomAutoPanesViewState: @atomAutoPanesView.serialize()

  toggle: ->
    #@modalPanel.state = if @modalPanel.state is 'ON' then 'OFF' else 'ON'
    if @enabled
      @enabled = false
      @atomAutoPanesView.message.textContent = "Auto Panes is OFF"
      if @editorObserver
        @editorObserver.dispose()
    else
      @enabled = true
      @atomAutoPanesView.message.textContent = "Auto Panes is ON"
      @toIgnore = []
      activePane = atom.workspace.getActivePane()
      if atom.config.get('atom-auto-panes.autoClose')
        atom.workspace.getPanes().forEach (pane)->
          pane.getItems().forEach (item)->
            if pane isnt activePane
              pane.getItems().forEach (item)->
                if item.save and item.isModified and item.isModified()
                  item.save()
              pane.destroy()
        activePane.getItems().forEach (item)->
          if item.save and item.isModified and item.isModified() and item isnt activePane.getActiveItem()
            item.save() 
        activePane.destroyInactiveItems()

      @editorObserver = atom.workspace.observeTextEditors(@onNewEditor)

    @modalPanel.show()
    setTimeout ()=>
      @modalPanel.hide()
    ,2000
