///////////////////////////////////////////////////////////////////////////////
// This is Classic AI Based like a Vanilla Career 
///////////////////////////////////////////////////////////////////////////////

class SwatHardClassic extends SwatEnemyExtend
	implements SwatAICommon.ISwatWildGunner;

var bool bIsFiring;
var protected WildGunnerAdjustAimGoal	AdjustAimGoal;

import enum EquipmentSlot from Engine.HandheldEquipment;
import enum Pocket from Engine.HandheldEquipment;

///////////////////////////////////////////////////////////////////////////////
// ISwatWildGunner implementation

function bool isFiring()
{
	return bIsFiring;
}

///////////////////////////////////////////////////////////////////////////////

simulated function OnUsingBegan()
{
	super.OnUsingBegan();
	bIsFiring = true;
}

simulated function OnUsingFinished()
{
	super.OnUsingFinished();
	bIsFiring = false;
}

///////////////////////////////////////////////////////////////////////////////

protected function CleanupClassGoals()
{
	if (AdjustAimGoal != None)
	{
		AdjustAimGoal.Release();
		AdjustAimGoal = None;
	}

	Super.CleanupClassGoals();
}

///////////////////////////////////////////////////////////////////////////////

// Create SwatWildGunner specific abilities
protected function ConstructCharacterAI()
{
    local AI_Resource characterResource;
    characterResource = AI_Resource(characterAI);
    assert(characterResource != none);
	
	characterResource.addAbility(new class'SwatAICommon.WildGunnerAdjustAimAction');

	AdjustAimGoal = new class'WildGunnerAdjustAimGoal'(characterResource);
	assert(AdjustAimGoal != None);
	AdjustAimGoal.AddRef();
	AdjustAimGoal.postGoal(None);

	// call down the chain
    Super.ConstructCharacterAI();
}

///////////////////////////////////////////////////////////////////////////////
// Only the WildGunner's primary weapon fires wildly

function bool FireWhereAiming()
{
	return GetPrimaryWeapon() != None && !GetPrimaryWeapon().IsEmpty();
}

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
    // we can only see SwatOfficers or SwatPlayers
    return (ClassIsChildOf(SeenType, class'SwatGame.SwatEnemy') ||
            ClassIsChildOf(SeenType, class'SwatGame.SwatHardLowThreat') ||	
            ClassIsChildOf(SeenType, class'SwatGame.SwatHardMiddleThreat') ||	
            ClassIsChildOf(SeenType, class'SwatGame.SwatHardHighThreat') ||	
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
// Running Threat
///////////////////////////////////////////////////////////////////////////////

function OnPawnDied(Pawn Pawn, Actor Killer, bool WasAThreat)
{
    //We can use deadly force by running close
    if ( ISwatEnemy(Pawn).GetCurrentState() == EnemyState_Flee )
	{
	if ( VSize(Pawn.Location - Killer.Location) < 0 && !ISwatEnemy(Pawn).GetEnemyCommanderAction().HasFledWithoutUsableWeapon() )
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
        if ( VSize(Pawn.Location - Incapacitator.Location) < 0 && !ISwatEnemy(Pawn).GetEnemyCommanderAction().HasFledWithoutUsableWeapon() )		
        {		
		BecomeAThreat();
        }		
   }
}

///////////////////////////////////////////////////////////////////////////////