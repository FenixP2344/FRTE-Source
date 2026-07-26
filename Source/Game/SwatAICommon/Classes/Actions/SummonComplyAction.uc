///////////////////////////////////////////////////////////////////////////////
// SummonComplyAction.uc
//
// A compliant, un-cuffed suspect or hostage shuffles over to the officer who
// called them on their knees, using the same direct movement mechanic as when
// a player bumps into a kneeling compliant AI.
//
// Deliberately avoids MoveToActorGoal (pathfinding), because compliant AI is
// kneeling and pathfinding in cramped rooms often fails. Instead, we use the
// native Actor::Move() which triggers the animation system so the compliant
// animation set plays the kneeling-shuffle animation automatically.
//
// Safety: only posted from SwatAI::OnSummonedByPlayer(), which refuses
// incapacitated / restrained / unconscious characters.
///////////////////////////////////////////////////////////////////////////////

class SummonComplyAction extends SwatCharacterAction
    config(AI);

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// How close we want to end up to the officer (Unreal units).
var config float SummonStopDistance;

// Maximum speed the AI shuffles toward the summoner (units/sec).
var config float SummonShuffleSpeed;

// Hard cap so a summoned pawn can never chase the player across the map.
var config float SummonMaxTravelTime;

var private float StartTime;

///////////////////////////////////////////////////////////////////////////////
//
// Safety checks

// The summon is only valid while the pawn stays a conscious, compliant,
// un-restrained character and the summoner is still around.
private function bool IsSummonStillValid()
{
    local Pawn Summoner;

    if (!class'Pawn'.static.checkConscious(m_Pawn))
        return false;

    if (ISwatAI(m_Pawn).IsArrested() || ISwatAI(m_Pawn).IsArrestedOnFloor())
        return false;

    if (!ISwatAI(m_Pawn).IsCompliant())
        return false;

    Summoner = SummonComplyGoal(achievingGoal).Summoner;
    if (!class'Pawn'.static.checkConscious(Summoner))
        return false;

    return true;
}

///////////////////////////////////////////////////////////////////////////////
//
// Movement — use native Move() so the animation system detects movement and
// plays the kneeling shuffle animation from the compliant anim set.

private latent function ShuffleTowardSummoner()
{
    local Pawn Summoner;
    local vector Dir;
    local float Dist, Step, Speed;
    local float LastTickTime;

    Summoner = SummonComplyGoal(achievingGoal).Summoner;
    assert(Summoner != None);

    LastTickTime = Level.TimeSeconds;
    Speed = SummonShuffleSpeed;

    while (true)
    {
        if (!IsSummonStillValid())
            break;

        if ((Level.TimeSeconds - StartTime) >= SummonMaxTravelTime)
            break;

        Dir = Summoner.Location - m_Pawn.Location;
        Dir.Z = 0;          // stay on the ground
        Dist = VSize(Dir);

        if (Dist <= SummonStopDistance)
            break;

        Step = (Level.TimeSeconds - LastTickTime) * Speed;
        if (Step > Dist - SummonStopDistance)
            Step = Dist - SummonStopDistance;

        // Set velocity so the compliant animation set plays the kneeling
        // shuffle rather than the stationary idle. Actor::Move() handles
        // collision; Velocity tells the animation graph we are in motion.
        Dir = Normal(Dir);
        m_Pawn.Velocity = Dir * Speed;

        // Move() processes the movement through the engine's normal character
        // pipeline (collision, touch triggers, animation blending).
        m_Pawn.Move(Dir * Step);

        // Face the summoner while shuffling.
        m_Pawn.DesiredRotation = rotator(Dir);
        m_Pawn.DesiredRotation.Pitch = 0;
        m_Pawn.DesiredRotation.Roll = 0;

        LastTickTime = Level.TimeSeconds;
        yield();
    }

    // Stop velocity so the animation returns to idle.
    m_Pawn.Velocity = vect(0, 0, 0);
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

state Running
{
Begin:
    StartTime = Level.TimeSeconds;

    if (!IsSummonStillValid())
    {
        instantFail(ACT_GENERAL_FAILURE);
    }

    // Same resources the compliant idle holds, so it lets go of us cleanly.
    useResources(class'AI_Resource'.const.RU_ARMS | class'AI_Resource'.const.RU_LEGS);

    ShuffleTowardSummoner();

    // Back to kneeling wherever we ended up: the compliance goal is still
    // posted underneath us, so simply succeeding hands control back to it.
    succeed();
}

///////////////////////////////////////////////////////////////////////////////

defaultproperties
{
    satisfiesGoal = class'SummonComplyGoal'

    SummonStopDistance  = 96.0
    SummonShuffleSpeed  = 75.0
    SummonMaxTravelTime = 20.0
}
