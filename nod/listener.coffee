# This listens for changes in the field, and changes its status
# accordingly while broadcasting it via trigger()
#
class Listener

  constructor: ( el, @get, @field ) ->
    @eventHandlers=[]
    @$el      = $ el
    @delayId  = ""                            # So we can cancel delayed checks
    @status   = null                          # This will be changed to bool
    @checker  = new Checker @$el, @field      # Run this to check a field
    @msg      = new Msg     @$el, @get, @field # Toggles showing/hiding msgs
    @events()                                 # Listen for changes on element

  destroy:=>
    @msg.destroy()
    if @$el.attr( 'type' ) is 'radio'         # Listen to all with same name
      $( '[name="'+@$el.attr("name")+'"]' ).off 'change','**',@eventHandlers.radio
    else
      @$el.off 'change','**',@eventHandlers.change             # For checkboxes and select fields
      @$el.off 'blur'  ,'**', @eventHandlers.blur             # On blur we run the check
      if @field[ 1 ] is 'one-of'
        $( window ).off 'nod-run-one-of','**',@eventHandlers.window
      if @get.delay
        @$el.off 'keyup','**',@eventHandlers.keyup       # delayed check on keypress



  events : =>
    @eventHandlers['radio']=@runCheck
    @eventHandlers['change']=@runCheck
    @eventHandlers['blur']=@runCheck
    @eventHandlers['window']=@runCheck
    @eventHandlers['keyup']=@delayedCheck

    if @$el.attr( 'type' ) is 'radio'         # Listen to all with same name
      $( '[name="'+@$el.attr("name")+'"]' ).on 'change', @eventHandlers.radio
    else
      @$el.on 'change', @eventHandlers.change             # For checkboxes and select fields
      @$el.on 'blur'  , @eventHandlers.blur             # On blur we run the check
      if @field[ 1 ] is 'one-of'
        $( window ).on 'nod-run-one-of', @eventHandlers.window
      if @get.delay
        @$el.on 'keyup' , @eventHandlers.keyup       # delayed check on keypress


  delayedCheck: =>
    clearTimeout @delayId                     # Cancel the previous delay check
    @delayId = setTimeout @runCheck, @get.delay  # Create new setTimeout


  runCheck: =>
    # Uses method described at http://api.jquery.com/deferred.then/ to
    # accomodate ajax callbacks
    $
      .when( @checker.run() )
      .then( @change_status )


  change_status : ( status ) =>
    try
      status = eval status
    isCorrect = !!status                      # Bool
    return if @status is isCorrect            # Stop if nothing changed
    @status = isCorrect                       # Set the new status
    @msg.toggle @status                       # toggle msg with new status
    $( @ ).trigger 'nod_toggle'               # Triggers check on submit btn
                                              # and .control-group
    if @field[ 1 ] is 'one-of' and status
      $( window ).trigger 'nod-run-one-of'
