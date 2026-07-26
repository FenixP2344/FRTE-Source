///////////////////////////////////////////////////////////////////////////////
// SummonComplyGoal.uc
//
// Ordering a already-compliant (kneeling, un-cuffed) suspect or hostage to
// shuffle over to the officer who called them.
//
// Only ever posted from SwatAI::OnSummonedByPlayer(), which itself is guarded
// so that incapacitated / restrained / unconscious characters can never be
// summoned.
///////////////////////////////////////////////////////////////////////////////

class SummonComplyGoal extends SwatCharacterGoal;

// The player who called us over.
var(parameters) Pawn Summoner;

///////////////////////////////////////////////////////////////////////////////
//
// Constructor

overloaded function construct( AI_Resource r, Pawn inSummoner )
{
	super.construct( r );

	assert(inSummoner != None);
	Summoner = inSummoner;
}

///////////////////////////////////////////////////////////////////////////////

defaultproperties
{
	// Just above ComplianceGoal (96) so we can interrupt the kneeling idle,
	// but below RestrainedGoal / RestrainedFloorGoal (98) and
	// IncapacitatedGoal (100) so cuffing and going down always win.
	priority   = 97
	goalName   = "SummonComplyGoal"
	bPermanent = false
}
