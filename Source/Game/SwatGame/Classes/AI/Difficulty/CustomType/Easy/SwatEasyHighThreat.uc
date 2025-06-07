///////////////////////////////////////////////////////////////////////////////
// High threat suspect,Usually equipped with RPG or grenade launchers and suicide vests
// Authorized to use lethal force at any time
///////////////////////////////////////////////////////////////////////////////

class SwatEasyHighThreat extends SwatEnemy;

import enum EquipmentSlot from Engine.HandheldEquipment;
import enum Pocket from Engine.HandheldEquipment;

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
// Move To Attack Officer
///////////////////////////////////////////////////////////////////////////////

protected function ConstructMovementAI()
{
    local AI_Resource movementResource;
		BecomeAThreat();
    
	movementResource = AI_Resource(movementAI);
    assert(movementResource != none);

    super.constructMovementAI();

	movementResource.addAbility(new class'SwatAICommon.MoveToAttackOfficerAction');
}

///////////////////////////////////////////////////////////////////////////////
// AI Weapon Action
///////////////////////////////////////////////////////////////////////////////

protected function ConstructWeaponAI()
{	
    local AI_Resource weaponResource;
		BecomeAThreat();

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
	weaponResource.addAbility(new class'SwatAICommon.UseGrenadeAction');
}

///////////////////////////////////////////////////////////////////////////////
// AI Vision
///////////////////////////////////////////////////////////////////////////////

event bool IgnoresSeenPawnsOfType(class<Pawn> SeenType)
{

		BecomeAThreat();
	
    // we can only see SwatOfficers or SwatPlayers
    return (ClassIsChildOf(SeenType, class'SwatGame.SwatEnemy') ||
            ClassIsChildOf(SeenType, class'SwatGame.SwatEasyLowThreat') ||	
            ClassIsChildOf(SeenType, class'SwatGame.SwatEasyMiddleThreat') ||	
            ClassIsChildOf(SeenType, class'SwatGame.SwatEasyHighThreat') ||	
            ClassIsChildOf(SeenType, class'SwatGame.SwatWildGunner') ||			
			ClassIsChildOf(SeenType, class'SwatGame.SwatHostage') ||
		    ClassIsChildOf(SeenType, class'SwatGame.SwatTrainer') ||
			ClassIsChildOf(SeenType, class'SwatGame.SniperPawn'));
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
// Attacking
///////////////////////////////////////////////////////////////////////////////
// we try to use the burst mode first, then the single shot mode, and then,
// if we have to, the auto fire mode
///////////////////////////////////////////////////////////////////////////////

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
	
		BecomeAThreat();
	

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