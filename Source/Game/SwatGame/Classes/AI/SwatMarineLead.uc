///////////////////////////////////////////////////////////////////////////////
// Marine leads 
///////////////////////////////////////////////////////////////////////////////

class SwatMarineLead extends SwatEnemy;

import enum EquipmentSlot from Engine.HandheldEquipment;
import enum Pocket from Engine.HandheldEquipment;

const            LowSkillMinTimeBeforeShooting = 0.1;
const            LowSkillMaxTimeBeforeShooting = 0.3;
const            MediumSkillMinTimeBeforeShooting = 0.1;
const            MediumSkillMaxTimeBeforeShooting = 0.3;
const            HighSkillMinTimeBeforeShooting = 0.1;
const            HighSkillMaxTimeBeforeShooting = 0.3;

///////////////////////////////////////////////////////////////////////////////
// Variables
///////////////////////////////////////////////////////////////////////////////

// State Variables
var config bool ForcePenalties;

///////////////////////////////////////////////////////////////////////////////
// Use Flashlight
///////////////////////////////////////////////////////////////////////////////

function EnteredZone(ZoneInfo Zone)
{
	Super.EnteredZone(Zone);
	
//	log(Name $ " Entered Zone " $ Zone $ " Zone.bUseFlashlight: " $ Zone.bUseFlashlight);

    // don't toggle flashlight when dead/incapacitated
    if (IsConscious())
    {
		// set our flashlight state to whatever the zone says
		SetDesiredFlashlightState(Zone.bUseFlashlight);
	}
	else
    if (IsIncapacitated())	
    {
		// set our flashlight state to whatever the zone says
        SetDesiredFlashlightState(false);
	}
}

///////////////////////////////////////////////////////////////////////////////
// Move To Attack Officer
///////////////////////////////////////////////////////////////////////////////

protected function ConstructMovementAI()
{
    local AI_Resource movementResource;
    
	movementResource = AI_Resource(movementAI);
    assert(movementResource != none);

    super.constructMovementAI();

	movementResource.addAbility(new class'SwatAICommon.MoveToAttackOfficerAction');
}

///////////////////////////////////////////////////////////////////////////////
// AI Reload Action
///////////////////////////////////////////////////////////////////////////////

protected function ConstructWeaponAI()
{
    local AI_Resource weaponResource;
    weaponResource = AI_Resource(weaponAI);
    assert(weaponResource != None);

    // Create Tyrion abilities
    weaponResource.addAbility(new class'Tyrion.AI_DummyWeapon');
    
    // Create Swat specific abilities
    weaponResource.addAbility(new class'SwatAICommon.ReloadAction');
    weaponResource.addAbility(new class'SwatAICommon.AimAroundAction');
    weaponResource.addAbility(new class'SwatAICommon.AimBetweenPointsAction');
    weaponResource.addAbility(new class'SwatAICommon.AttackTargetAction');    
	weaponResource.addAbility(new class'SwatAICommon.AimAtTargetAction');
	weaponResource.addAbility(new class'SwatAICommon.AimAtPointAction');
	weaponResource.addAbility(new class'SwatAICommon.IdleAimAroundAction');
}

///////////////////////////////////////////////////////////////////////////////
// AI Vision
///////////////////////////////////////////////////////////////////////////////

event bool IgnoresSeenPawnsOfType(class<Pawn> SeenType)
{
    // we can only see SwatOfficers or SwatPlayers
    return (ClassIsChildOf(SeenType, class'SwatGame.SwatMarine') ||
            ClassIsChildOf(SeenType, class'SwatGame.SwatWildGunner') ||
            ClassIsChildOf(SeenType, class'SwatGame.SwatBomber') ||
            ClassIsChildOf(SeenType, class'SwatGame.SwatHighThreat') ||
            ClassIsChildOf(SeenType, class'SwatGame.SwatMIddleThreat') ||
            ClassIsChildOf(SeenType, class'SwatGame.SwatLowThreat') ||
            ClassIsChildOf(SeenType, class'SwatGame.SwatUndercover') || 
			ClassIsChildOf(SeenType, class'SwatGame.SwatMarineLead') ||
			ClassIsChildOf(SeenType, class'SwatGame.SwatMarineBomber') ||				
			ClassIsChildOf(SeenType, class'SwatGame.SwatHostage') ||
		    ClassIsChildOf(SeenType, class'SwatGame.SwatTrainer') ||
			ClassIsChildOf(SeenType, class'SwatGame.SniperPawn'));
}

///////////////////////////////////////////////////////////////////////////////
//
// Doors

protected function InitializeDoorKnowledge(Door inDoor, PawnDoorKnowledge DoorKnowledge)
{
	assert(inDoor != None);
	assert(inDoor.IsA('SwatDoor'));
	assert(DoorKnowledge != None);

	// if the door was initially locked, we belive that already (whether it's currently true or not)
	DoorKnowledge.SetBelievesDoorLocked(SwatDoor(inDoor).WasDoorInitiallyLocked());
}

// Enemies force locked doors to open
function bool ShouldForceOpenLockedDoors()
{
	return true;
}

///////////////////////////////////////////////////////////////////////////////
// Patrolling
///////////////////////////////////////////////////////////////////////////////
protected function InitializePatrolling(PatrolList Patrol)
{
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
// Attacking
///////////////////////////////////////////////////////////////////////////////
// by default we try to use the burst mode first,
// then the single shot mode,
// and then, if we have to, the auto fire mode
function FireMode GetDefaultAIFireModeForWeapon(FiredWeapon Weapon)
{

    BecomeAThreat();
	
	assert(Weapon != None);

	if (Weapon.HasFireMode(FireMode_Burst))
	{
		return FireMode_Burst;
	}
	else if (Weapon.HasFireMode(FireMode_Auto))
	{
		return FireMode_Auto;
	}
	else if (Weapon.HasFireMode(FireMode_DoubleTaser))
	{
		return FireMode_DoubleTaser;
	}
	else
	{
		// sanity check!
		assert(Weapon.HasFireMode(FireMode_Single) || Weapon.HasFireMode(FireMode_SingleTaser));

		return FireMode_Single;
	}
}

// return weapon specific time values for this AI
function float GetTimeToWaitBetweenFiring(FiredWeapon Weapon)
{
	local FireMode CurrentFireMode;

	CurrentFireMode = Weapon.GetCurrentFireMode();

	if (Weapon.IsA('Handgun'))
	{
		return RandRange(MinTimeBetweenFireHG, MaxTimeBetweenFireHG);
	}
	else if (Weapon.IsA('SubMachineGun'))
	{
		if (CurrentFireMode == FireMode_Single)
		{
			return RandRange(MinTimeBetweenFireSMGSingleShot, MaxTimeBetweenFireSMGSingleShot);
		}
		else if (CurrentFireMode == FireMode_Burst)
		{
			return RandRange(MinTimeBetweenFireSMGBurst, MaxTimeBetweenFireSMGBurst);
		}
		else
		{
			return RandRange(MinTimeBetweenFireSMGFullAuto, MaxTimeBetweenFireSMGFullAuto);
		}
	}
	else if (Weapon.IsA('MachineGun'))
	{
		if (CurrentFireMode == FireMode_Single)
		{
			return RandRange(MinTimeBetweenFireMGSingleShot, MaxTimeBetweenFireMGSingleShot);
		}
		else if (CurrentFireMode == FireMode_Burst)
		{
			return RandRange(MinTimeBetweenFireMGFullBurst, MaxTimeBetweenFireMGFullBurst);
		}
		else
		{
			return RandRange(MinTimeBetweenFireMGFullAuto, MaxTimeBetweenFireMGFullAuto);
		}
	}
	else
	{
		return RandRange(MinTimeBetweenFireShotgun, MaxTimeBetweenFireShotgun);
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
	if ( VSize(Pawn.Location - Killer.Location) < 1000 && !ISwatEnemy(Pawn).GetEnemyCommanderAction().HasFledWithoutUsableWeapon() )
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
        if ( VSize(Pawn.Location - Incapacitator.Location) < 1000 && !ISwatEnemy(Pawn).GetEnemyCommanderAction().HasFledWithoutUsableWeapon() )		
        {		
		BecomeAThreat();
        }		
   }
}

///////////////////////////////////////////////////////////////////////////////