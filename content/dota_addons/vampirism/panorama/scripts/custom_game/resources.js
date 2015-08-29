'use strict';

function UpdateResource(params)
{
  var type = params["resourceType"];
  var newValue = params["value"];

  if (type == "gold")
  {
    $("#PlayerGold").text = newValue;
  }
  else if (type == "wood")
  {
    $("#PlayerWood").text = newValue;
  }
  else if (type == "currentFood")
  {
    $("#PlayerFoodCurrent").text = newValue;
  }
  else if (type == "maxFood")
  {
    $("#PlayerFoodMax").text = newValue;
  }
}
(function () {
  GameEvents.Subscribe( "update_resource", UpdateResource);
})();