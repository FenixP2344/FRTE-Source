///////////////////////////////////////////////////////////////////////////////
// ZombieChargeAction.uc
//
// Zombie-only movement behaviour: once a zombie has a target it closes the
// distance and keeps closing until it is right on top of them. Unlike
// MoveToAttackOfficerAction it never stops early because it has line of sight,
// never crouches, and never gives up after a fixed travel distance.
//
// Only SwatZombie registers this ability, so no other AI is affected.
///////////////////////////////////////////////////////////////////////////////

class ZombieChargeAction extends MoveToAttackOfficerAction
    config(AI);

// How close the zombie wants to get before it stops advancing.
var config float ChargeStopDistance;

// Zombies only give up the chase when the target is this far away and out of
// sight; anything closer keeps them coming.
var config float ChargeMaxPursuitDistance;

///////////////////////////////////////////////////////////////////////////////
//
// Movement test

// Zombies charge: keep running until we are in melee range of the target.
function bool ShouldStopMovingToOfficer(Pawn MovingPawn)
{
    local Pawn CurrentEnemy;
    local float DistanceToEnemy;

    CurrentEnemy = ISwatEnemy(m_Pawn).GetEnemyCommanderAction().GetCurrentEnemy();

    // No living target: stop and let the commander pick a new one.
    if (!class'Pawn'.static.checkConscious(CurrentEnemy))
        return true;

    DistanceToEnemy = VSize(CurrentEnemy.Location - m_Pawn.Location);

    // Right on top of them, stop so the attack action can swing.
    if (DistanceToEnemy <= ChargeStopDistance)
        return true;

    // Too far away and no line of sight at all: let normal AI take over so the
    // zombie does not sprint across the whole map through walls.
    if (DistanceToEnemy > ChargeMaxPursuitDistance && !m_Pawn.LineOfSightTo(CurrentEnemy))
        return true;

    // Otherwise: keep charging. We deliberately ignore CanHit() here, which is
    // what makes zombies rush instead of stopping to shoot.
    return false;
}

///////////////////////////////////////////////////////////////////////////////

defaultproperties
{
    satisfiesGoal=class'MoveToAttackOfficerGoal'

    ChargeStopDistance=60.0
    ChargeMaxPursuitDistance=3000.0

    // never crouch mid-charge
    CrouchWhileAttackingChance=0.0

    // effectively unlimited travel: the distance check must not stop a charge
    MinDistanceToTravel=100000.0
    MaxDistanceToTravel=100000.0
}
