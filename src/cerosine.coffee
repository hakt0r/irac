$ = global.$

class Dialog
  hidden : yes
  constructor : (opts={}) ->
    me = @
    { @id, @frame, btn, html, form, hide } = opts
    @frame = Dialog.frame unless @frame?
    @hidden = hidden if hidden?
    @frame.append """
      <div class="dialog" id="#{@id}">
        <form role="form" target="#">
        </form>
      </div>"""
    @outer = $ @frame.find('.dialog').toArray().pop()
    @$     = $ @frame.find('.dialog > form').toArray().pop()
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
      new Button opts )  id, click for id, click of btn
    if @hidden then @outer.fadeOut(0)
  close  : (c) => @hide c
  show   : (c) => if @hidden
    @outer.fadeIn  c; @hidden = false
  hide   : (c) => unless @hidden
    @outer.fadeOut c; @hidden = true 
  toggle : (c) => if @hidden then @show c else @hide c

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
  constructor : (opts={}) -> opts.type = 'text'; super opts

class Password extends Field
  constructor : (opts={}) -> opts.type = 'password'; super opts

class eMail extends Field
  constructor : (opts={}) -> opts.type = 'email'; super opts

class File extends Field
  constructor : (opts={}) -> opts.type = 'file'; super opts

module.exports = 
  Text : Text
  eMail : eMail
  Field : Field
  Dialog : Dialog
  Button : Button
  Password : Password
  File : File