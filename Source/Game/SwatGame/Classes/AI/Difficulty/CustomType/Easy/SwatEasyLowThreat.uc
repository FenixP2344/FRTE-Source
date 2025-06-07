///////////////////////////////////////////////////////////////////////////////
// Low Threat Suspect just like vanilla, we need Following Standard ROE
///////////////////////////////////////////////////////////////////////////////

class SwatEasyLowThreat extends SwatEnemy;

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
// AI Vision
///////////////////////////////////////////////////////////////////////////////

event bool IgnoresSeenPawnsOfType(class<Pawn> SeenType)
{
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