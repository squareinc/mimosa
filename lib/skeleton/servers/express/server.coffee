express =        require 'express'
reloadOnChange = require 'watch-connect'
gzip =           require 'gzippo'

routes  =        require './routes'

exports.startServer = (config) ->

  publicPath = config.watch.compiledDir
  useReload = config.server.useReload

  viewDirectory = "#{__dirname}/views"

  app = express()
  server = app.listen 3000, ->
     console.log "Express server listening on port %d in %s mode", server.address().port, app.settings.env

  app.configure ->
    app.set 'port', process.env.PORT || 3000
    app.set 'views', viewDirectory
    app.set 'view engine', 'jade'
    app.use express.favicon()
    app.use express.bodyParser()
    app.use express.methodOverride()
    if useReload
      options =
        server:server
        watchdir:publicPath
        verbose: false
        skipAdding:true
        exclude:["almond\.js"]
        additionaldirs:[viewDirectory]
      app.use reloadOnChange(options)
    app.use app.router
    app.use gzip.staticGzip(publicPath)

  app.configure 'development', ->
    app.use express.errorHandler()

  app.get '/', routes.index(useReload, config.optimize)
