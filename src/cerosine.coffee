###

  | irac |

    2010-2013 [GPL] / version 0.9 - kreem
    github.com/hakt0r/irac

    anx    [ ulzq.de ] 2010-2013
    flyc0r [ ulzq.de ] 2010,2013

###

{ $, gui } = ( api = global.api )

class Dialog
  @__id : -1
  hidden : yes
  constructor : (opts={}) ->
    me = @
    { @id, className, @frame, btn, html, form, hidden, onetime } = opts
    className = 'dialog' unless className?
    @frame   = Dialog.frame unless @frame?
    @onetime = if onetime?
        @hidden = no if onetime
        onetime
      else no
    @hidden = hidden if hidden?
    @id = Dialog.__id++ unless @id?
    @frame.append """
      <div class="#{className}" id="#{@id}">
        <form role="form" target="#">
        </form>
      </div>"""
    @outer = $ @frame.find('.'+className).toArray().pop()
    @$ = $ @frame.find('.'+className+' > form').toArray().pop()
    @$.append html if html?
    ( _new_fld = (id, opts) =>
      opts.id = id unless opts.id?
      opts.frame = @$ unless opts.frame?
      new opts.type opts ) id, opts  for id, opts of form
    ( _new_btn = (id, click) =>
      if typeof click is 'function'
        opts = {click:click}
      else opts = click
      opts.id = id    unless opts.id?
      opts.frame = @$ unless opts.frame?
      opts.parent = me
      new Button opts ) id, click for id, click of btn
    @$.append """<div style="clear:both"></div>"""
    @outer.fadeOut(0) if @hidden
  close : (c) => @hide =>
    setTimeout ( => @outer.remove() ) if @onetime
    c() if c?
  show : (c) => if @hidden
    #@outer.css 'display', 'block'; @hidden = false; c() if c?
    @outer.fadeIn  c; @hidden = false
  hide   : (c) => unless @hidden
    #@outer.css 'display', 'none'; @hidden = false; c() if c?
    @outer.fadeOut c; @hidden = true
  toggle : (c) => if @hidden then @show c else @hide c

$().ready ->
  $('body').append '<div id="dialogs"></div>'
  Dialog.frame = $('#dialogs')

class Progress
  constructor : (opts={}) ->
    { @id, @title, @frame, @description, val, click } = opts
    @title = @id unless @title?
    val = 0 unless val?
    @frame.prepend """
      <div class="notify-progress">
        <h4>#{@title} <i>#{@description}</i></h4>
        <div class="progress active"><div class="progress-bar"  role="progressbar" aria-valuenow="#{val}" aria-valuemin="0" aria-valuemax="100" style="width: 0%"><span class="sr-only">0%</span></div></div>
      </div>"""
    @$ = $ @frame.find('> div').toArray().shift()
    @bar = $ @$.find('.progress-bar').toArray().pop()
    @status = $ @$.find('.sr-only').toArray().pop()
  value : (val, description) =>
    @bar.css 'width', val + '%'
    @status.html val + '%'
    ( @$.fadeOut => @$.remove() ) if val is 100
    @$.find('i').html description if description?
  remove : =>
    console.log @$
    @$.remove()

class Button
  constructor : (opts={}) ->
    { @id, @title, @frame, @parent, click } = opts
    @title = @id unless @title?
    css = 'pull-right' if @id is 'default'
    css = 'pull-left'  if @id is 'cancel'
    @frame.append """<button class="btn btn-#{@id} #{css}">#{@title}</button>"""
    @$ = $ @frame.find('> button').toArray().pop()
    @$.on 'click', (e) =>
      e.preventDefault()
      click.apply(@parent,arguments)

class HTML
  constructor : (opts={}) ->
    { @id, @title, @frame, value, type } = opts
    @title = @id unless @title?
    @frame.append """
      <div class="form-group">
        <label for="#{@id}">#{@title}</label>
        <div id="#{@id}" placeholder="#{@placeholder}">#{value}</div>
      </div>"""
    @$ = $ @frame.find('> div').toArray().pop()
    @value = $ @$.find('> div').toArray().pop()

class Field
  constructor : (opts={}) ->
    { @id, @title, @frame, @change, @placeholder, value, type } = opts
    value = """ value="#{value}" """ if value?
    @title = @id unless @title?
    @placeholder = '' unless @placeholder?
    @frame.append """
      <div class="form-group">
        <label for="#{@id}">#{@title}</label>
        <input type="#{type}" class="form-control" id="#{@id}" placeholder="#{@placeholder}" #{value}>
      </div>"""
    @$ = $ @frame.find('div > input').toArray().pop()
    @$.on 'change', @change

class Text extends Field
  constructor : (opts={}) -> opts.type = 'text';     super opts

class Password extends Field
  constructor : (opts={}) -> opts.type = 'password'; super opts

class eMail extends Field
  constructor : (opts={}) -> opts.type = 'email';    super opts

class File extends Field
  constructor : (opts={}) -> opts.type = 'file';     super opts

class Numeric extends Field
  constructor : (opts={}) -> opts.type = 'number';   super opts

module.exports =
  Text : Text
  eMail : eMail
  Field : Field
  Dialog : Dialog
  Button : Button
  Password : Password
  Numeric : Numeric
  File : File
  HTML : HTML
  Progress : Progress