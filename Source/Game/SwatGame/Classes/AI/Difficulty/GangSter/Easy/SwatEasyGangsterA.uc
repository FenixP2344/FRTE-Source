///////////////////////////////////////////////////////////////////////////////
// Gangster can flee, investigate and neutralize both officers and suspects.
// See SwatEnemy::ConstructCharacterAIHook
///////////////////////////////////////////////////////////////////////////////

class SwatEasyGangsterA extends SwatEnemy;

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
    return (ClassIsChildOf(SeenType, class'SwatGame.SwatEasyGangsterA') ||
            ClassIsChildOf(SeenType, class'SwatGame.SwatEasyBomber') ||
            ClassIsChildOf(SeenType, class'SwatGame.SwatEasyHighThreat') ||
            ClassIsChildOf(SeenType, class'SwatGame.SwatEasyMIddleThreat') ||
            ClassIsChildOf(SeenType, class'SwatGame.SwatEasyLowThreat') ||
            ClassIsChildOf(SeenType, class'SwatGame.SwatUndercover') || 
			ClassIsChildOf(SeenType, class'SwatGame.SwatEasyClassic') ||
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
