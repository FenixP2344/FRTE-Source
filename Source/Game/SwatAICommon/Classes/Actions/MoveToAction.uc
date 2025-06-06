///////////////////////////////////////////////////////////////////////////////
// MoveToAction.uc - MoveToAction class
// The Action that is used by an Officer AI to complete the MoveTo command

class MoveToAction extends SwatCharacterAction;
///////////////////////////////////////////////////////////////////////////////

///////////////////////////////////////////////////////////////////////////////
//
// Variables

// behaviors we use
var private MoveToActorGoal		CurrentMoveToActorGoal;
var private AimAroundGoal		CurrentAimAroundGoal;
var private RotateTowardActorGoal	CurrentRotateTowardActorGoal;

// copied from our goal
var(parameters) Actor			Destination;

// config variables
var config float				DistanceFromDestinationToStartWalking;

var config float				MoveToMinAimHoldTime; // 0.25
var config float				MoveToMaxAimHoldTime; // 1


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

	if (CurrentAimAroundGoal != None)
	{
		CurrentAimAroundGoal.Release();
		CurrentAimAroundGoal = None;
	}
	
	if (CurrentRotateTowardActorGoal != None)
	{
		CurrentRotateTowardActorGoal.Release();
		CurrentRotateTowardActorGoal = None;
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// Tyrion callbacks

function goalNotAchievedCB( AI_Goal goal, AI_Action child, ACT_ErrorCodes errorCode )
{
	super.goalNotAchievedCB(goal, child, errorCode);

	if (goal == CurrentMoveToActorGoal)
	{
		assert(m_Pawn.IsA('SwatOfficer'));
		ISwatOfficer(m_Pawn).GetOfficerSpeechManagerAction().TriggerCouldntCompleteMoveSpeech();

		instantSucceed();
	}
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

function AimAround()
{
	CurrentAimAroundGoal = new class'SwatAICommon.AimAroundGoal'(weaponResource(), MoveToMinAimHoldTime, MoveToMaxAimHoldTime);
	assert(CurrentAimAroundGoal != None);
	CurrentAimAroundGoal.AddRef();

	CurrentAimAroundGoal.SetOnlyAimIfMoving(true);

	CurrentAimAroundGoal.postGoal( self );
}

latent function MoveToDestination()
{	
	CurrentMoveToActorGoal = new class'MoveToActorGoal'(movementResource(), achievingGoal.priority, Destination);
	assert(CurrentMoveToActorGoal != None);
	CurrentMoveToActorGoal.AddRef();

	CurrentMoveToActorGoal.SetRotateTowardsPointsDuringMovement(true);
	CurrentMoveToActorGoal.SetShouldWalkEntireMove(true);
	//CurrentMoveToActorGoal.SetWalkThreshold(DistanceFromDestinationToStartWalking);
	CurrentMoveToActorGoal.SetUseNavigationDistanceOnSensor(true);
	CurrentMoveToActorGoal.SetShouldSucceedWhenDestinationBlocked(true);

	CurrentMoveToActorGoal.postGoal(self);
	WaitForGoal(CurrentMoveToActorGoal);
	CurrentMoveToActorGoal.unPostGoal(self);

	CurrentMoveToActorGoal.Release();
	CurrentMoveToActorGoal = None;
}

latent function RotateToFaceDestination(Actor Dest)
{

	CurrentRotateTowardActorGoal = new class'RotateTowardActorGoal'(movementResource(), achievingGoal.priority, Dest);
	assert(CurrentRotateTowardActorGoal != None);
	CurrentRotateTowardActorGoal.AddRef();

	CurrentRotateTowardActorGoal.postGoal(self);
	
	WaitForGoal(CurrentRotateTowardActorGoal);
}

state Running
{
Begin:
	SleepInitialDelayTime(true);

	AimAround();
	MoveToDestination();
	
	if (IswatOfficer(m_pawn).IsInFormation())
		RotateToFaceDestination(Destination);

	succeed();
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    satisfiesGoal = class'MoveToGoal'
}