function SetVersion ( LuaVersion ) {
  var version = LuaVersion["version"];
  $("#VersionNumberText").text = "Version: " + version;
}

(function () { GameEvents.Subscribe("send_version", SetVersion )})();