///////////////////////////////////////////////////////////////////////////////
// TeamMarkerSettings.uc
//
// Non-native config data for PVP team identification markers.
// The two bools used to live on NetPlayer (a native class) but caused a
// native-class-size mismatch. They live here instead, read via
//   class'TeamMarkerSettings'.default.bEnableTeamMarkers
///////////////////////////////////////////////////////////////////////////////

class TeamMarkerSettings extends Core.Object
    config(PlayerInterface_Use);

// glowstick on the head + light strip on the back (red/blue per faction)
var config bool bEnableTeamMarkers;

// team markers are also shown in COOP when this is true
var config bool bTeamMarkersInCoop;

///////////////////////////////////////////////////////////////////////////////

defaultproperties
{
    bEnableTeamMarkers=true
    bTeamMarkersInCoop=false
}
