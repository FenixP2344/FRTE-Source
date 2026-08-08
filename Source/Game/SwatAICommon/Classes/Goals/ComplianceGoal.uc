///////////////////////////////////////////////////////////////////////////////
// ComplianceGoal.uc - ComplianceGoal class
// The goal that causes the AI to be compliant

class ComplianceGoal extends SwatCharacterGoal;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

var private bool	bHasCompliedAlready;
var private bool	bCanBeArrested;
var private float	CompliantStartTime;

///////////////////////////////////////////////////////////////////////////////
//
// State Tracking

// Marc: apparently not used
function bool CanBeArrested()
{
	return bCanBeArrested;
}

function SetCanBeArrested()
{
	bCanBeArrested = true;
}

function SetCompliantStartTime(float Time)
{
	CompliantStartTime = Time;
}

function float GetCompliantStartTime()
{
	return CompliantStartTime;
}

function bool HasCompliedAlready()
{
	return bHasCompliedAlready;
}

function SetHasCompliedAlready()
{
	bHasCompliedAlready = true;
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
	priority = 96
	goalName = "Compliance"
}