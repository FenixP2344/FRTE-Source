///////////////////////////////////////////////////////////////////////////////
// PickUpWeaponAction.uc 
// The Action that causes an enemy to pick up a weapon
// (lots of code copied from SecureEvidenceAction)

class PickUpWeaponAction extends SwatCharacterAction;
///////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////
//
// Variables

// copied from our goal
var(parameters) private HandHeldEquipmentModel WeaponModel;

// behaviors we use
var private MoveToActorGoal				CurrentMoveToActorGoal;
var private RotateTowardRotationGoal	CurrentRotateTowardRotationGoal;

const kSecureOnFloorThreshold = 48;

///////////////////////////////////////////////////////////////////////////////
// 
// Cleanup

function cleanup()
{
	super.cleanup();

	if (CurrentMoveToActorGoal != None)
	{
		CurrentMoveToActorGoal.Release();
		CurrentMoveToActorGoal = None;
	}

	if (CurrentRotateTowardRotationGoal != None)
	{
		CurrentRotateTowardRotationGoal.Release();
		CurrentRotateTowardRotationGoal = None;
	}

    // Guarentee collision avoidance is back on
    m_Pawn.EnableCollisionAvoidance();
    
/////Exception to the Difficulty and threat system
/////This is to prevent high threat suspects from being wrongly subjected to unauthorized use of force -Probe

//////Easy 
	if(m_Pawn.IsA('SwatEasyClassic') || m_Pawn.IsA('SwatEasyLowThreat') || m_Pawn.IsA('SwatEasyMiddleThreat') || m_Pawn.IsA('SwatEasyGangsterA') || m_Pawn.IsA('SwatEasyGangsterB') || m_Pawn.IsA('SwatEasyMafia'))
	{
	ISwatEnemy(m_Pawn).UnBecomeAThreat(true, 3.0f);
	}
	
//////Normal
	if(m_Pawn.IsA('SwatNormalClassic') || m_Pawn.IsA('SwatNormalLowThreat') || m_Pawn.IsA('SwatNormalMiddleThreat') || m_Pawn.IsA('SwatNormalGangsterA') || m_Pawn.IsA('SwatNormalGangsterB') || m_Pawn.IsA('SwatNormalMafia'))
	{
	ISwatEnemy(m_Pawn).UnBecomeAThreat(true, 3.0f);
	}
	
//////Hard
	if(m_Pawn.IsA('SwatHardClassic') || m_Pawn.IsA('SwatHardLowThreat') || m_Pawn.IsA('SwatHardMiddleThreat') || m_Pawn.IsA('SwatHardGangsterA') || m_Pawn.IsA('SwatHardGangsterB') || m_Pawn.IsA('SwatHardMafia'))
	{
	ISwatEnemy(m_Pawn).UnBecomeAThreat(true, 3.0f);
	}

//////Other ACtorClass
	if(m_Pawn.IsA('SwatClassic') || m_Pawn.IsA('SwatLowThreat') || m_Pawn.IsA('SwatMiddleThreat') || m_Pawn.IsA('SwatGangsterA') || m_Pawn.IsA('SwatGangsterB') || m_Pawn.IsA('SwatMafia'))
	{
	ISwatEnemy(m_Pawn).UnBecomeAThreat(true, 3.0f);
	}
}

//function IEvidence GetEvidenceTarget()
//{
//    return EvidenceTarget;
//}

///////////////////////////////////////////////////////////////////////////////
//
// Tyrion callbacks

function goalNotAchievedCB( AI_Goal goal, AI_Action child, ACT_ErrorCodes errorCode )
{
	super.goalNotAchievedCB(goal, child, errorCode);

	// if our movement goal fails, we succeed so we don't get reposted!
	if (goal == CurrentMoveToActorGoal)
	{
		instantFail(errorCode);
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

latent function MoveIntoPosition()
{
    assert(WeaponModel != None);
	assert(!ISwatAI(m_pawn).isarrested() && !ISwatPawn(m_pawn).IsBeingArrestedNow()); //dont even bother
	
	CurrentMoveToActorGoal = new class'MoveToActorGoal'(movementResource(), achievingGoal.priority, WeaponModel);
	assert(CurrentMoveToActorGoal != None);
	CurrentMoveToActorGoal.AddRef();

	CurrentMoveToActorGoal.SetAcceptNearbyPath(true);
	CurrentMoveToActorGoal.SetRotateTowardsPointsDuringMovement(true);
	CurrentMoveToActorGoal.SetMoveToThreshold(40.0);

	// post the goal and wait for it to complete
	CurrentMoveToActorGoal.postGoal(self);
	WaitForGoal(CurrentMoveToActorGoal);
	CurrentMoveToActorGoal.unPostGoal(self);

	CurrentMoveToActorGoal.Release();
	CurrentMoveToActorGoal = None;
}

latent function RotateTowardsTarget()
{
    assert(WeaponModel != None);
	assert(!ISwatAI(m_pawn).isarrested() && !ISwatPawn(m_pawn).IsBeingArrestedNow()); //dont even bother
	
	CurrentRotateTowardRotationGoal = new class'RotateTowardRotationGoal'(movementResource(), achievingGoal.priority, rotator(WeaponModel.Location - m_Pawn.Location));
	assert(CurrentRotateTowardRotationGoal != None);
	CurrentRotateTowardRotationGoal.AddRef();

	CurrentRotateTowardRotationGoal.postGoal(self);
	WaitForGoal(CurrentRotateTowardRotationGoal);
	CurrentRotateTowardRotationGoal.unPostGoal(self);

	CurrentRotateTowardRotationGoal.Release();
	CurrentRotateTowardRotationGoal = None;
}

latent function PickUpWeapon()
{
    local float ZDiff;
    local int AnimSpecialChannel;

	m_Pawn.DisableCollisionAvoidance();

    assert(WeaponModel != None);
	assert(!ISwatAI(m_pawn).isarrested() && !ISwatPawn(m_pawn).IsBeingArrestedNow()); //dont even bother

	// if the weapon hasn't already been secured
	if (WeaponModel.CanBeUsedNow())
	{
		// todo: secureWeapon animations are just placeholder (?)
		ZDiff = m_Pawn.Location.Z - WeaponModel.Location.Z;
		if (ZDiff > kSecureOnFloorThreshold)
			AnimSpecialChannel = m_Pawn.AnimPlaySpecial('secureWeaponFloor', 0.1);
		else
			AnimSpecialChannel = m_Pawn.AnimPlaySpecial('secureWeaponTable', 0.1);
			
		// Reaching for a gun? He's a threat!
		if ((m_Pawn.IsA('SwatEnemy')) && ((!m_Pawn.IsA('SwatUndercover')) || (!m_Pawn.IsA('SwatGuard'))) && !ISwatEnemy(m_Pawn).IsAThreat())
		{
			ISwatEnemy(m_Pawn).BecomeAThreat();
		}
		
		//a threat before the animation
		//if ((m_Pawn.IsA('SwatEnemy')) && ((!m_Pawn.IsA('SwatUndercover')) || (!m_Pawn.IsA('SwatGuard'))) && !ISwatEnemy(m_Pawn).IsAThreat())
		//{
		//	ISwatEnemy(m_Pawn).BecomeAThreat();
		//	yield();
		//}	
		
		m_Pawn.FinishAnim(AnimSpecialChannel);

		m_Pawn.EnableCollisionAvoidance();

		ISwatEnemy(m_Pawn).PickUpWeaponModel(WeaponModel);
	}
}

state Running
{
Begin:
	if (m_Pawn.logTyrion)
		log(Name @ "started");

	useResources(class'AI_Resource'.const.RU_ARMS);

	MoveIntoPosition();

	RotateTowardsTarget();

	useResources(class'AI_Resource'.const.RU_LEGS);
	PickUpWeapon();

	succeed();
}
///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    satisfiesGoal = class'PickUpWeaponGoal'
}
