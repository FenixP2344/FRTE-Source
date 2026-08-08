///////////////////////////////////////////////////////////////////////////////
// SummonSettings.uc
//
// Server side knobs for the "come here" order, kept in PlayerInterface_Use.ini
// next to the SummonCompliantAI context so the whole feature is configured in
// one file.
//
// Section: [SwatGame.SummonSettings]
///////////////////////////////////////////////////////////////////////////////

class SummonSettings extends Core.Object
    config(PlayerInterface_Use);

// How far the server will honour a summon order from. Keep this in sync with
// the Range of the [SummonCompliantAI UseInterfaceContext] section, which is
// what decides whether the prompt appears on the client.
var config float SummonMaxRange;

// Effect event played on the summoning officer when the order is given, so a
// custom voice line can be dropped in without touching any code. Add a matching
// entry to the officer's effect events, then name it here.
// Leave empty for no speech.
var config name SummonSpeechEvent;

// Grace period (seconds) a suspect/hostage must have been kneeling before the
// player can call them over.
var config float MinCompliantTimeForSummon;

///////////////////////////////////////////////////////////////////////////////

defaultproperties
{
    SummonMaxRange = 300.0
    SummonSpeechEvent = SummonCompliantSuspect
    MinCompliantTimeForSummon = 1.5
}
