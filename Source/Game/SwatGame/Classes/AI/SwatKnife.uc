///////////////////////////////////////////////////////////////////////////////
// Police Officers shoot against enemies only
// See SwatEnemy::ConstructCharacterAIHook
///////////////////////////////////////////////////////////////////////////////

class SwatKnife extends SwatEnemy;

import enum EquipmentSlot from Engine.HandheldEquipment;
import enum Pocket from Engine.HandheldEquipment;

///////////////////////////////////////////////////////////////////////////////

protected function ConstructCharacterAIHook(AI_Resource characterResource)
{
    characterResource.addAbility(new class'SwatAICommon.InvestigateAction');
	characterResource.addAbility(new class'SwatAICommon.BarricadeAction');	
	characterResource.addAbility(new class'SwatAICommon.AttackOfficerAction');		
	characterResource.addAbility(new class'SwatAICommon.InitialReactionAction');
	characterResource.addAbility(new class'SwatAICommon.FleeAction');
	characterResource.addAbility(new class'SwatAICommon.AvoidLocationAction');		
	characterResource.addAbility(new class'SwatAICommon.PepperSprayedAction');
	characterResource.addAbility(new class'SwatAICommon.GassedAction');
	characterResource.addAbility(new class'SwatAICommon.FlashbangedAction');
	characterResource.addAbility(new class'SwatAICommon.TasedAction');
	characterResource.addAbility(new class'SwatAICommon.StunnedByC2Action');
	characterResource.addAbility(new class'SwatAICommon.StungAction');
	characterResource.addAbility(new class'SwatAICommon.EnemyCowerAction');		
}

///////////////////////////////////////////////////////////////////////////////
// Move To Attack Officer
///////////////////////////////////////////////////////////////////////////////

protected function ConstructMovementAI()
{
    local AI_Resource movementResource;
    if (! IsAThreat())
	{
		BecomeAThreat();
	}
    
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
    // we see everyone except our own
    return (ClassIsChildOf(SeenType, class'SwatGame.SwatPlayer') ||
			ClassIsChildOf(SeenType, class'SwatGame.SwatOfficer') ||
			ClassIsChildOf(SeenType, class'SwatGame.SwatPolice') ||
            ClassIsChildOf(SeenType, class'SwatGame.SwatEnemy') ||
            ClassIsChildOf(SeenType, class'SwatGame.SwatLowThreat') ||	
            ClassIsChildOf(SeenType, class'SwatGame.SwatMiddleThreat') ||	
            ClassIsChildOf(SeenType, class'SwatGame.SwatHighThreat') ||	
            ClassIsChildOf(SeenType, class'SwatGame.SwatWildGunner') ||		
			ClassIsChildOf(SeenType, class'SwatGame.SwatHostage') ||
		    ClassIsChildOf(SeenType, class'SwatGame.SwatTrainer') ||
			ClassIsChildOf(SeenType, class'SwatGame.SniperPawn'));
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

// var int i;
// 
// while ( i < 5 )
// {
// 	Do stuff;
// 	i++;
// }
///////////////////////////////////////////////////////////////////////////////