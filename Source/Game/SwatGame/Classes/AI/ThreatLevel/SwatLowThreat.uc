///////////////////////////////////////////////////////////////////////////////
// Low Threat Suspect just like vanilla, we need Following Standard ROE
///////////////////////////////////////////////////////////////////////////////

class SwatLowThreat extends SwatEnemy
	implements SwatAICommon.ISwatWildGunner;

var bool bIsFiring;
var protected WildGunnerAdjustAimGoal	AdjustAimGoal;

import enum EquipmentSlot from Engine.HandheldEquipment;
import enum Pocket from Engine.HandheldEquipment;

const            LowSkillMinTimeBeforeShooting = 1.2;
const            LowSkillMaxTimeBeforeShooting = 1.7;
const            MediumSkillMinTimeBeforeShooting = 0.9;
const            MediumSkillMaxTimeBeforeShooting = 1.4;
const            HighSkillMinTimeBeforeShooting = 0.6;
const            HighSkillMaxTimeBeforeShooting = 1.0;

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
            ClassIsChildOf(SeenType, class'SwatGame.SwatLowThreat') ||	
            ClassIsChildOf(SeenType, class'SwatGame.SwatMiddleThreat') ||	
            ClassIsChildOf(SeenType, class'SwatGame.SwatHighThreat') ||	
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