///////////////////////////////////////////////////////////////////////////////
// TryDoorGoal.uc - TryDoorGoal class
// this goal is given to a Officer to test and see if the door is blocked

class TryDoorGoal extends OfficerCommandGoal;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
// 
// Variables

// copied to our action
var(parameters) Door TargetDoor;
var(parameters) bool bTriggerReportResultsSpeech;
var(parameters) bool bPeekDoor;


///////////////////////////////////////////////////////////////////////////////
// 
// Constructors

overloaded function construct( AI_Resource r )
{
    // don't use this constructor
	assert(false);
}

overloaded function construct( AI_Resource r, Door inTargetDoor, bool bInTriggerReportResultsSpeech , optional bool bInPeekDoor )
{
    Super.construct(r);

    assert(inTargetDoor != None);
    TargetDoor = inTargetDoor;

	bTriggerReportResultsSpeech = bInTriggerReportResultsSpeech;
	bPeekDoor=bInPeekDoor;
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    priority   = 80
    goalName   = "TryDoor"
}