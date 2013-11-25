###
fs = require 'fs'

class CachedStream
  @length : 0
  constructor : (path, @target) ->
    @file = fs.createWriteStream path
    @write = (data) =>
      @length += data.length
      @file.write data
    @pipefrom = (@target, offset) ->
      if @length > 0
###