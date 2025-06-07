///////////////////////////////////////////////////////////////////////////////
// Gangster can flee, investigate and neutralize both officers and suspects.
// See SwatEnemy::ConstructCharacterAIHook
///////////////////////////////////////////////////////////////////////////////

class SwatNormalGangsterA extends SwatEnemy;

import enum EquipmentSlot from Engine.HandheldEquipment;
import enum Pocket from Engine.HandheldEquipment;

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
    return (ClassIsChildOf(SeenType, class'SwatGame.SwatNormalGangsterA') ||
            ClassIsChildOf(SeenType, class'SwatGame.SwatNormalBomber') ||
            ClassIsChildOf(SeenType, class'SwatGame.SwatNormalHighThreat') ||
            ClassIsChildOf(SeenType, class'SwatGame.SwatNormalMIddleThreat') ||
            ClassIsChildOf(SeenType, class'SwatGame.SwatNormalLowThreat') ||
            ClassIsChildOf(SeenType, class'SwatGame.SwatUndercover') || 
			ClassIsChildOf(SeenType, class'SwatGame.SwatNormalClassic') ||
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
