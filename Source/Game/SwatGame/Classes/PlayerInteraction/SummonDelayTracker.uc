///////////////////////////////////////////////////////////////////////////////
// SummonDelayTracker.uc
//
// Client-side helper for the "come here" summon. The commander action is not
// replicated to clients, so on a client (or a listen-server host) we can't ask
// the AI how long it has been kneeling. This tracker reconstructs that time
// from the replicated bIsCompliant flag: the first time we see a pawn kneeling
// we remember the timestamp, and GetTimeSinceCompliant() reports the elapsed
// seconds since.
//
// Spawned lazily by SwatGamePlayerController and owned by it; it is never
// replicated (RemoteRole=ROLE_None), so it is purely local.
///////////////////////////////////////////////////////////////////////////////

class SummonDelayTracker extends Engine.Actor;

var array<Pawn> TrackedPawns;
var array<float> FirstCompliantTimes;

// A pawn that stops kneeling (gets up) must be dropped from the tracked list
// even if the player is not currently aiming at it. Otherwise the old entry
// lingers and the next time the same pawn re-kneels the delay is measured from
// the FIRST kneel, so a second surrender can be summoned instantly.
simulated function Tick(float DeltaTime)
{
	local int i;

	for (i = TrackedPawns.Length - 1; i >= 0; --i)
	{
		if (TrackedPawns[i] == None || TrackedPawns[i].bDeleteMe ||
			!TrackedPawns[i].IsCompliant())
		{
			TrackedPawns.Remove(i, 1);
			FirstCompliantTimes.Remove(i, 1);
		}
	}
}

simulated function float GetTimeSinceCompliant(Pawn P)
{
	local int i;

	if (P == None || P.bDeleteMe)
		return -1.0;

	if (!P.IsCompliant())
	{
		// no longer kneeling - forget what we recorded
		for (i = TrackedPawns.length - 1; i >= 0; --i)
		{
			if (TrackedPawns[i] == P)
			{
				TrackedPawns.Remove(i, 1);
				FirstCompliantTimes.Remove(i, 1);
			}
		}
		return -1.0;
	}

	for (i = 0; i < TrackedPawns.length; ++i)
	{
		if (TrackedPawns[i] == P)
			return Level.TimeSeconds - FirstCompliantTimes[i];
	}

	// first time we've seen this pawn kneeling
	TrackedPawns[TrackedPawns.length] = P;
	FirstCompliantTimes[FirstCompliantTimes.length] = Level.TimeSeconds;
	return 0.0;
}

///////////////////////////////////////////////////////////////////////////////

defaultproperties
{
	bHidden=true
	RemoteRole=ROLE_None
	// tick so a re-kneel is treated as a fresh compliance episode
	AlwaysTick=true
}
