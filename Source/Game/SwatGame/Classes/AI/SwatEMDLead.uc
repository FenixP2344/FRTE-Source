///////////////////////////////////////////////////////////////////////////////
// Dispatch Mode suspect Has strong aggressiveness
// They will Threaton hostages and Killed
// Authorized to use lethal force at any time
///////////////////////////////////////////////////////////////////////////////

class SwatEMDLead extends SwatEnemy;

import enum EquipmentSlot from Engine.HandheldEquipment;
import enum Pocket from Engine.HandheldEquipment;

const            LowSkillMinTimeBeforeShooting = 0.4;
const            LowSkillMaxTimeBeforeShooting = 0.6;
const            MediumSkillMinTimeBeforeShooting = 0.2;
const            MediumSkillMaxTimeBeforeShooting = 0.4;
const            HighSkillMinTimeBeforeShooting = 0.1;
const            HighSkillMaxTimeBeforeShooting = 0.3;


///////////////////////////////////////////////////////////////////////////////
// Use Flashlight
///////////////////////////////////////////////////////////////////////////////


function EnteredZone(ZoneInfo Zone)
{
	Super.EnteredZone(Zone);
	
//	log(Name $ " Entered Zone " $ Zone $ " Zone.bUseFlashlight: " $ Zone.bUseFlashlight);

    // toggle flashlight when is Conscious
    if (IsConscious())
    {
		// set our flashlight state to whatever the zone says
		SetDesiredFlashlightState(Zone.bUseFlashlight);
	}
	else
    if (IsIncapacitated())	
    {
		// don't toggle flashlight when dead/incapacitated
        SetDesiredFlashlightState(false);
	}
}

///////////////////////////////////////////////////////////////////////////////
// AI Vision
///////////////////////////////////////////////////////////////////////////////

event bool IgnoresSeenPawnsOfType(class<Pawn> SeenType)
{

	BecomeAThreat();
	
    // we can only see SwatOfficers or SwatPlayers
    return (ClassIsChildOf(SeenType, class'SwatGame.SwatEnemy') ||
            ClassIsChildOf(SeenType, class'SwatGame.SwatLowThreat') ||	
            ClassIsChildOf(SeenType, class'SwatGame.SwatMiddleThreat') ||	
            ClassIsChildOf(SeenType, class'SwatGame.SwatHighThreat') ||	
            ClassIsChildOf(SeenType, class'SwatGame.SwatWildGunner') ||			
			ClassIsChildOf(SeenType, class'SwatGame.SwatHostage') ||
		    ClassIsChildOf(SeenType, class'SwatGame.SwatTrainer') ||
			ClassIsChildOf(SeenType, class'SwatGame.SniperPawn'));
}

///////////////////////////////////////////////////////////////////////////////
// Doors
///////////////////////////////////////////////////////////////////////////////

protected function InitializeDoorKnowledge(Door inDoor, PawnDoorKnowledge DoorKnowledge)
{

	BecomeAThreat();

	assert(inDoor != None);
	assert(inDoor.IsA('SwatDoor'));
	assert(DoorKnowledge != None);

	// if the door was initially locked, we belive that already (whether it's currently true or not)
	DoorKnowledge.SetBelievesDoorLocked(SwatDoor(inDoor).WasDoorInitiallyLocked());
}

// Enemies force locked doors to open
function bool ShouldForceOpenLockedDoors()
{
	return False;
}

///////////////////////////////////////////////////////////////////////////////
// Patrolling
///////////////////////////////////////////////////////////////////////////////
protected function InitializePatrolling(PatrolList Patrol)
{

	BecomeAThreat();
	
    // only give the enemy patrolling if we have a patrol
    if (Patrol != None)
    {
		// we are able to patrol
		CharacterAI.addAbility(new class'SwatAICommon.PatrolAction');

		// set the patrol on the commander (since the commander action hasn't been created yet)
		Commander.SetPatrol(Patrol);
    }
}

///////////////////////////////////////////////////////////////////////////////
// IReactToC2Detonation implementation
///////////////////////////////////////////////////////////////////////////////

function ReactToC2Detonation(Actor C2Charge, float StunRadius, float AIStunDuration)
{
	  BecomeAThreat();
	
	if (IsConscious())
	{
		BecomeAThreat();
		LastTimeStunnedByC2 = Level.TimeSeconds;
		BecomeAThreat();
		StunnedByC2Duration = AIStunDuration;
		BecomeAThreat();

		GetCommanderAction().NotifyStunnedByC2Detonation(C2Charge.Location, AIStunDuration);
		BecomeAThreat();
	}
}

// automatically become a threat if we discharge our weapon
protected function NotifyEnemyStunned()
{
	if (! IsAThreat())
	{
		BecomeAThreat();
	}
}

///////////////////////////////////////////////////////////////////////////////
// Running Threat
///////////////////////////////////////////////////////////////////////////////

function OnPawnDied(Pawn Pawn, Actor Killer, bool WasAThreat)
{
    //We can use deadly force by running close
    if ( ISwatEnemy(Pawn).GetCurrentState() == EnemyState_Flee )
	{
	if ( VSize(Pawn.Location - Killer.Location) < 9999 && !ISwatEnemy(Pawn).GetEnemyCommanderAction().HasFledWithoutUsableWeapon() )
	   {
		BecomeAThreat();
	   }
	}
}	

function OnPawnIncapacitated(Pawn Pawn, Actor Incapacitator, bool WasAThreat)
{	
    //running close in front of an officer with a gun is considered a threat		
    if ( ISwatEnemy(Pawn).GetCurrentState() == EnemyState_Flee )		
	{			
        if ( VSize(Pawn.Location - Incapacitator.Location) < 9999 && !ISwatEnemy(Pawn).GetEnemyCommanderAction().HasFledWithoutUsableWeapon() )		
        {		
		BecomeAThreat();
        }		
   }
}

///////////////////////////////////////////////////////////////////////////////