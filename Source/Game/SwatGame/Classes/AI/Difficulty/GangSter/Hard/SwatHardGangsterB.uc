///////////////////////////////////////////////////////////////////////////////
// Gangster can flee, investigate and neutralize both officers and suspects.
// See SwatEnemy::ConstructCharacterAIHook
///////////////////////////////////////////////////////////////////////////////

class SwatHardGangsterB extends SwatEnemy;

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
    return (ClassIsChildOf(SeenType, class'SwatGame.SwatHardGangsterB') ||
            ClassIsChildOf(SeenType, class'SwatGame.SwatHardBomber') ||
            ClassIsChildOf(SeenType, class'SwatGame.SwatHardHighThreat') ||
            ClassIsChildOf(SeenType, class'SwatGame.SwatHardMIddleThreat') ||
            ClassIsChildOf(SeenType, class'SwatGame.SwatHardLowThreat') ||
            ClassIsChildOf(SeenType, class'SwatGame.SwatUndercover') || 
			ClassIsChildOf(SeenType, class'SwatGame.SwatHardClassic') ||
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