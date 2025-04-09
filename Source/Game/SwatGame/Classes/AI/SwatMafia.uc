///////////////////////////////////////////////////////////////////////////////
// Mafia can flee, investigate and neutralize both officers and suspects.
// See SwatEnemy::ConstructCharacterAIHook
///////////////////////////////////////////////////////////////////////////////

class SwatMafia extends SwatEnemy;

import enum EquipmentSlot from Engine.HandheldEquipment;
import enum Pocket from Engine.HandheldEquipment;

const            LowSkillMinTimeBeforeShooting = 0.9;
const            LowSkillMaxTimeBeforeShooting = 1.6;
const            MediumSkillMinTimeBeforeShooting = 0.8;
const            MediumSkillMaxTimeBeforeShooting = 1.2;
const            HighSkillMinTimeBeforeShooting = 0.6;
const            HighSkillMaxTimeBeforeShooting = 0.8;

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
    return (ClassIsChildOf(SeenType, class'SwatGame.SwatMafia') ||
			ClassIsChildOf(SeenType, class'SwatGame.SwatHighThreat') ||
            ClassIsChildOf(SeenType, class'SwatGame.SwatMIddleThreat') ||
            ClassIsChildOf(SeenType, class'SwatGame.SwatLowThreat') ||
            ClassIsChildOf(SeenType, class'SwatGame.SwatBomber') ||
            ClassIsChildOf(SeenType, class'SwatGame.SwatUndercover') || 
            ClassIsChildOf(SeenType, class'SwatGame.SwatWildGunner') ||
            ClassIsChildOf(SeenType, class'SwatGame.SwatEscaper') ||
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

///////////////////////////////////////////////////////////////////////////////