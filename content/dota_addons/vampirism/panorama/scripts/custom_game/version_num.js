function SetVersion (num) {
  var parentPanel = $.ContextPanel();
  var versionNumber = $.CreatePanel("Label", parentPanel, "VersionNumber");
  versionNumber.text = num;
}

(function () { GameEvents.Subscribe("send_version", SetVersion )})();