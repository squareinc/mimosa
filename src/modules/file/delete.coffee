"use strict"

_delete = (config, options, next) ->
  fs = require 'fs'

  # has no discernable output file
  unless options.destinationFile
    return next()

  fileName = options.destinationFile(options.inputFile)
  fs.exists fileName, (exists) ->
    unless exists
      return next()

    fs.unlink fileName, (err) ->
      if err
        config.log.error "Failed to delete file [[ #{fileName} ]]"
      else
        config.log.success "Deleted file [[ #{fileName} ]]", options
      next()

exports.registration = (config, register) ->
  e = config.extensions
  register ['remove','cleanFile'], 'delete', _delete, [e.javascript..., e.css..., e.copy..., e.misc...]