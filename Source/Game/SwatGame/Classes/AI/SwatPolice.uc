///////////////////////////////////////////////////////////////////////////////
// Police Officers shoot against enemies only
// See SwatEnemy::ConstructCharacterAIHook
///////////////////////////////////////////////////////////////////////////////

class SwatPolice extends SwatEnemy;

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
			ClassIsChildOf(SeenType, class'SwatGame.SwatHostage') ||
		    ClassIsChildOf(SeenType, class'SwatGame.SwatTrainer') ||
			ClassIsChildOf(SeenType, class'SwatGame.SniperPawn'));
}

///////////////////////////////////////

// Provides the effect event name to use when this ai is being reported to
// TOC. Overridden from SwatAI

simulated function name GetEffectEventForReportingToTOCWhenDead()           { return 'ReportedOfficerDown'; }
simulated function name GetEffectEventForReportingToTOCWhenIncapacitated()  { return 'ReportedOfficerDown'; }
simulated function name GetEffectEventForReportingToTOCWhenArrested()       { return 'ReportedSuspectSecured'; }

// Subclasses should override these functions with class-specific response
// effect event names. Overridden from SwatAI
simulated function name GetEffectEventForReportResponseFromTOCWhenIncapacitated()      { return 'RepliedOfficerDown'; }
simulated function name GetEffectEventForReportResponseFromTOCWhenNotIncapacitated()   { return 'RepliedOfficerDown'; }


// var int i;
// 
// while ( i < 5 )
// {
// 	Do stuff;
// 	i++;
// }
///////////////////////////////////////////////////////////////////////////////