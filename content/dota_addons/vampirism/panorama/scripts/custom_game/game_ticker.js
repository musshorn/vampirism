'use strict';

function UpdateGameTicker( params )
{
  $.Msg(params);
  $.Msg("Ticker updated");
}


(function()
{
  GameEvents.Subscribe( "ticker_message", UpdateGameTicker );
})();