///////////////////////////////////////////////////////////////////////////////
// Gangster can flee, investigate and neutralize both officers and suspects.
// See SwatEnemy::ConstructCharacterAIHook
///////////////////////////////////////////////////////////////////////////////

class SwatGangsterA extends SwatEnemy
	implements SwatAICommon.ISwatWildGunner;

var bool bIsFiring;
var protected WildGunnerAdjustAimGoal	AdjustAimGoal;

import enum EquipmentSlot from Engine.HandheldEquipment;
import enum Pocket from Engine.HandheldEquipment;

const            LowSkillMinTimeBeforeShooting = 1.4;
const            LowSkillMaxTimeBeforeShooting = 1.6;
const            MediumSkillMinTimeBeforeShooting = 1.0;
const            MediumSkillMaxTimeBeforeShooting = 1.4;
const            HighSkillMinTimeBeforeShooting = 0.6;
const            HighSkillMaxTimeBeforeShooting = 1.2;

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
// AI Reload Action
///////////////////////////////////////////////////////////////////////////////

protected function ConstructWeaponAI()
{
	local AI_Resource weaponResource;
    weaponResource = AI_Resource(weaponAI);
    assert(weaponResource != none);

	weaponResource.addAbility(new class'SwatAICommon.ReloadAction');

	// call down the chain
	Super.ConstructWeaponAI();
}

///////////////////////////////////////////////////////////////////////////////
// AI Vision
///////////////////////////////////////////////////////////////////////////////

event bool IgnoresSeenPawnsOfType(class<Pawn> SeenType)
{
    // we see everyone except our own
    return (ClassIsChildOf(SeenType, class'SwatGame.SwatGangsterA') ||
            ClassIsChildOf(SeenType, class'SwatGame.SwatBomber') ||
            ClassIsChildOf(SeenType, class'SwatGame.SwatHighThreat') ||
            ClassIsChildOf(SeenType, class'SwatGame.SwatMIddleThreat') ||
            ClassIsChildOf(SeenType, class'SwatGame.SwatLowThreat') ||
            ClassIsChildOf(SeenType, class'SwatGame.SwatUndercover') || 
			ClassIsChildOf(SeenType, class'SwatGame.SwatHostage') ||
		    ClassIsChildOf(SeenType, class'SwatGame.SwatTrainer') ||
			ClassIsChildOf(SeenType, class'SwatGame.SniperPawn'));
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
