///////////////////////////////////////////////////////////////////////////////
// StunnedAction.uc - StunnedAction class
// The Action that causes an AI to react to being stunned

class StunnedAction extends SwatCharacterAction
	abstract
    dependson(ISwatAI)
    dependson(UpperBodyAnimBehaviorClients);

///////////////////////////////////////////////////////////////////////////////

import enum EUpperBodyAnimBehavior from ISwatAI;
import enum EUpperBodyAnimBehaviorClientId from UpperBodyAnimBehaviorClients;

///////////////////////////////////////////////////////////////////////////////
//
// Variables

var config private float				MinRequiredFleeDistanceFromOfficer;	// the minimum distance between us and the closest officer to be able to flee
var config private float ThreatCooldown;

// behaviors we use
var private MoveToActorGoal CurrentMoveToActorGoal;

// keeping track of morale taken
var private float		MoralePenalty;

// keeping track of time
var private float		StartTime;
var protected float		EndTime;
var private bool		bRecovering;

var private bool		bPlayedAnimation;

// copied from our goal
var(parameters) vector	StunningDeviceLocation;
var(parameters) float	StunnedDuration;
var(parameters) bool    bShouldRunFromStunningDevice;
var(parameters) bool	bPlayedReaction;
var(parameters) bool    bComplexFlee;

const kRunFromStunningDeviceMinDistSq =   40000.0; //  200.0^2
const kRunFromStunningDeviceMaxDistSq =  640000.0; //  800.0^2

const kRunFromStunningDevicePriority  = 90;

var private FleePoint					FleeDestination;

///////////////////////////////////////////////////////////////////////////////
//
// Initialization / Cleanup

function initAction(AI_Resource r, AI_Goal goal)
{
    super.initAction(r, goal);

    if(StunnedDuration <= 0.0)
    {
     instantFail(ACT_GENERAL_FAILURE);
    }

	// disable our senses
	DisableSenses();

	// keep track of time
	StartTime = Level.TimeSeconds;
	EndTime   = StartTime + StunnedDuration;

	// affect morale
	AffectMorale();

	if(bComplexFlee)
	{
		ISwatAI(m_Pawn).EnableFavorLowThreatPath();
		ISwatAICharacter(m_Pawn).ForceUpdateAwareness();

		if (!ISwatAI(m_Pawn).HasUsableWeapon())
		{
			ISwatEnemy(m_Pawn).GetEnemyCommanderAction().SetHasFledWithoutUsableWeapon();
		}
	}
	
	// if we're running on an enemy, let the hive know
	if (m_Pawn.IsA('SwatEnemy'))
	{
		SwatAIRepository(m_Pawn.Level.AIRepo).GetHive().NotifyEnemyStunned(m_Pawn);
	}
//	if (m_Pawn.IsA('SwatEnemy') && ISwatEnemy(m_Pawn).IsAThreat())
//	{
//		ISwatEnemy(m_Pawn).UnbecomeAThreat(true, ThreatCooldown);
//	}
	// if we're running on an hostage, let the hive know -J21C
	if (m_Pawn.IsA('SwatHostage'))
	{
		SwatAIRepository(m_Pawn.Level.AIRepo).GetHive().NotifyHostageStunned(m_Pawn);
	}
}

// subclasses should override
protected function float GetMoraleModificationAmount()
{
	assert(false);
	return 0.0;
}

protected function float GetEmpathyModifierForCharacter(ISwatAICharacter target)
{
	return 0.0;
}

// Drives the empathy morale modifiers --eez
private function DistributeEmpathyMoraleModifications(float MoraleModification)
{
	local Pawn A;
	local ISwatAICharacter Character;

	// This is stupidly slow but is probably okay because it gets run pretty rarely
	foreach m_Pawn.Level.DynamicActors(class 'Pawn', A)
	{
		Character = ISwatAICharacter(A);
		if(Character == None)
		{	// not an AI character
			continue;
		}

		if(!Character.IsA('SwatEnemy') && !Character.IsA('SwatHostage'))
		{	// not a suspect or civilian, just keep moving along
			continue;
		}

		if(A == m_Pawn)
		{	// cannot apply it to ourselves
			continue;
		}

		if(!m_Pawn.LineOfSightTo(A))
		{	// we don't have line of sight on the target
			continue;
		}

		if(Character.HasEmpathy())
		{
			ISwatAI(A).GetCommanderAction().ChangeMorale(MoraleModification * GetEmpathyModifierForCharacter(Character),
				"Empathy from "$self$" on "$m_Pawn,
				false);
		}
	}
}

protected function AffectMorale()
{
	local float MoraleModification;

	MoraleModification = GetMoraleModificationAmount();

	MoralePenalty += MoraleModification;
	MoraleModification *= -1;
	ISwatAI(m_Pawn).GetCommanderAction().ChangeMorale(MoraleModification, achievingGoal.GoalName);

	// do empathy modifiers
	DistributeEmpathyMoraleModifications(MoraleModification);
}

private function ReturnMorale()
{
	// only return morale if we're still alive
	if (class'Pawn'.static.checkConscious(m_Pawn))
	{
		ISwatAI(m_Pawn).GetCommanderAction().ChangeMorale(MoralePenalty, achievingGoal.GoalName $ " Ended");
	}
}

function cleanup()
{
	super.cleanup();

	// unlock our aim when we're done
	ISwatAI(m_Pawn).UnlockAim();

	ISwatAI(m_Pawn).UnsetUpperBodyAnimBehavior(kUBABCI_StunnedAction);

    // return any morale we've taken
	ReturnMorale();

	// when we're all done, re-enable our senses
	EnableSenses();

	if (CurrentMoveToActorGoal != None)
	{
		CurrentMoveToActorGoal.Release();
		CurrentMoveToActorGoal = None;
	}

	UnTriggerStunnedSpeech();

    // Guarentee collision avoidance is back on
	if (!ISwatAI(m_Pawn).IsArrestedOnFloor())
		m_Pawn.EnableCollisionAvoidance();
	else
		m_Pawn.DisableCollisionAvoidance();

	// stop any animations on the special channel if we have played an animation
	if (bPlayedAnimation && !ISwatAI(m_Pawn).IsArrested())
		ISwatAI(m_Pawn).AnimStopSpecial();

	// Make sure we go back to the idle!
	if(ISwatAI(m_Pawn).IsArrested() && !ISwatAI(m_Pawn).IsArrestedOnFloor())
	{
		ISwatAI(m_Pawn).SetIdleCategory('Restrained');
		ISwatAI(m_Pawn).SwapInRestrainedAnimSet();
	}
	else if(ISwatAI(m_Pawn).IsArrested() && ISwatAI(m_Pawn).IsArrestedOnFloor())
	{
		ISwatAI(m_Pawn).SetIdleCategory('RestrainedFloor');
		ISwatAI(m_Pawn).SwapInRestrainedFloorAnimSet();
	}
}

// subclasses must override
function bool ShouldAffectMoraleAgain()
{
	assert(false);
	return false;
}

// subclasses must override
protected function AddAdditionalStunnedTime(float AdditionalStunnedTime)
{
	assert(false);
}

function ExtendBeingStunned(float AdditionalStunnedTime)
{
	// affect morale again, if we should
	if (ShouldAffectMoraleAgain())
	{
		AffectMorale();
	}

	// extend the time we are affected
	AddAdditionalStunnedTime(AdditionalStunnedTime);

	if (m_Pawn.logAI)
		log("AdditionalStunnedTime is: " $ AdditionalStunnedTime $ " EndTime is now: " $ EndTime $ " Level.TimeSeconds: " $ Level.TimeSeconds $ " bRecovering: " $ bRecovering);

	if (ShouldReTriggerStunnedSpeech())
		TriggerStunnedSpeech();

	// reset the behavior if we are about to recover
	if (bRecovering)
	{
		bRecovering = false;
		if( !ISwatAI(m_Pawn).IsArrestedOnFloor())
			gotostate('Running', 'Begin');
	}
}

private function bool CanGetOutOfRoomSafely()
{
	local SwatAIRepository SwatAIRepo;
	local NavigationPointList DoorsInRoom;
	local Door DoorInRoom;
	local int i;
	local Hive HiveMind;

	if(m_Pawn.GetRoomNameSafe() == 'Unknown')
    {
        // This can cause errors!
        return false;
    }
     

	HiveMind = SwatAIRepository(m_Pawn.Level.AIRepo).GetHive();

	SwatAIRepo = SwatAIRepository(m_Pawn.Level.AIRepo);
	DoorsInRoom = SwatAIRepo.GetRoomNavigationPointsOfType(m_Pawn.GetRoomName(), 'SwatDoor');

	for(i=0; i<DoorsInRoom.GetSize(); ++i)
	{
		DoorInRoom = Door(DoorsInRoom.GetEntryAt(i));

	    if(ISwatPawn(m_Pawn).DoesBelieveDoorWedged(DoorInRoom)) {
	      continue; // We can't use this door if we know it's wedged
	    }
	    if(ISwatPawn(m_Pawn).DoesBelieveDoorLocked(DoorInRoom)) {
	      continue; // We can't use this door if we know it's locked
	    }

		// if there is one door that we can use to get out of here, that isn't close too any player or officer, then we can get out safely
		if (! HiveMind.IsActorWithinDistanceOfOfficers(DoorInRoom, MinRequiredFleeDistanceFromOfficer))
		{
//			log("there is no officer near " $ DoorInRoom $ ", so " $ m_Pawn.Name $ " can get away");
			return true;
		}
	}

//	log("there is no way " $ m_Pawn.Name $ " can get out of " $ m_Pawn.GetRoomName());
	return false;
}

///////////////////////////////////////////////////////////////////////////////
//
// Sub-Behavior Messages

function goalNotAchievedCB( AI_Goal goal, AI_Action child, ACT_ErrorCodes errorCode )
{
	// calling down the chain should do nothing
	super.goalNotAchievedCB(goal, child, errorCode);

	if (m_Pawn.logTyrion)
		log(goal.name $ " was not achieved.  waiting to achieve.");

	// stop trying to move
	if (CurrentMoveToActorGoal != None)
	{
		CurrentMoveToActorGoal.unPostGoal(self);
		CurrentMoveToActorGoal.Release();
		CurrentMoveToActorGoal = None;
	}
	
	// Make sure we go back to the idle!
	if(ISwatAI(m_Pawn).IsArrested() && !ISwatAI(m_Pawn).IsArrestedOnFloor())
	{
		ISwatAI(m_Pawn).SetIdleCategory('Restrained');
		ISwatAI(m_Pawn).SwapInRestrainedAnimSet();
	}
	else if(ISwatAI(m_Pawn).IsArrested() && ISwatAI(m_Pawn).IsArrestedOnFloor())
	{
		ISwatAI(m_Pawn).SetIdleCategory('RestrainedFloor');
		ISwatAI(m_Pawn).SwapInRestrainedFloorAnimSet();
	}
	

	// we shouldn't run from the stunning device now.
	bShouldRunFromStunningDevice                            = false;
	StunnedGoal(achievingGoal).bShouldRunFromStunningDevice = false;

	gotostate('Running', 'WaitToAchieve');
}

///////////////////////////////////////////////////////////////////////////////
//
// State Code

// subclasses should override
function TriggerStunnedSpeech();
protected function UnTriggerStunnedSpeech();

// Run from stunning device code

function NavigationPoint FindRunToPoint()
{
    // Find the point that has the highest confidence and lowest threat to move to.
    local int i;
    local array<AwarenessProxy.AwarenessKnowledge> PotentiallyVisibleSet;
    local AwarenessProxy.AwarenessKnowledge Knowledge;
    local NavigationPoint NavigationPoint;
    local vector DirectionToStunningDevice;
    local vector DirectionToNavigationPoint;
    local float DistSq;
    local float Weight;

    local NavigationPoint BestRunToPoint;
    local float BestRunToPointWeight;

    DirectionToStunningDevice = StunningDeviceLocation - m_Pawn.Location;

    PotentiallyVisibleSet = ISwatAI(m_Pawn).GetAwareness().GetPotentiallyVisibleKnowledge(m_Pawn);

    for (i = 0; i < PotentiallyVisibleSet.Length; ++i)
    {
        Knowledge = PotentiallyVisibleSet[i];
        NavigationPoint = Knowledge.aboutAwarenessPoint.GetClosestNavigationPoint();
        if ((NavigationPoint != None) && !NavigationPoint.IsA('Door'))
        {
            DistSq = VDistSquared(m_Pawn.Location, NavigationPoint.Location);
            // If within our desired distance..
            if (DistSq >= kRunFromStunningDeviceMinDistSq &&
                DistSq <= kRunFromStunningDeviceMaxDistSq)
            {
                // If the dot product of the direction to the point, and the
                // direction to the stunning device is < 0 (this prevents the
                // pawn from running toward the device)..
                DirectionToNavigationPoint = NavigationPoint.Location - m_Pawn.Location;
                if ((DirectionToNavigationPoint dot DirectionToStunningDevice) < 0.0)
                {
                    // Calculate the weight, based on confidence, threat and distance.
                    // We favor high confidence, low threat points.
                    Weight = Knowledge.confidence - (Knowledge.threat * 2.0);
                    if (Weight > 0.0 && (BestRunToPoint == None || Weight > BestRunToPointWeight))
                    {
                        BestRunToPoint = NavigationPoint;
                        BestRunToPointWeight = Weight;
                    }
                }
            }
        }
    }

    return BestRunToPoint;
}

latent function RunFromStunningDevice()
{
    local NavigationPoint RunToPoint;

    if (bShouldRunFromStunningDevice && !ISwatAI(m_Pawn).IsCompliant() && !ISwatAI(m_Pawn).IsArrested() && !m_pawn.HasActiveShield() )
    {
        RunToPoint = FindRunToPoint();
        if (RunToPoint != None)
        {
			clearDummyMovementGoal();

			// unlock our aim while we move
			ISwatAI(m_Pawn).UnlockAim();

            CurrentMoveToActorGoal = new class'MoveToActorGoal'(movementResource(), kRunFromStunningDevicePriority, FindRunToPoint());
            assert(CurrentMoveToActorGoal != None);
            CurrentMoveToActorGoal.AddRef();

            CurrentMoveToActorGoal.SetAcceptNearbyPath(true);
			CurrentMoveToActorGoal.SetRotateTowardsFirstPoint(true);
            CurrentMoveToActorGoal.SetRotateTowardsPointsDuringMovement(true);
            CurrentMoveToActorGoal.SetMoveToThreshold(8.0);
			CurrentMoveToActorGoal.SetWalkThreshold(0.0);

            // post the goal and wait for it to complete
            CurrentMoveToActorGoal.postGoal(self);
            WaitForGoal(CurrentMoveToActorGoal);

			// the behavior may have been stopped already
			if (CurrentMoveToActorGoal != None)
			{
	            CurrentMoveToActorGoal.unPostGoal(self);

				CurrentMoveToActorGoal.Release();
				CurrentMoveToActorGoal = None;
			}

			// lock our aim again
			ISwatAI(m_Pawn).AimToRotation(m_Pawn.Rotation);
			ISwatAI(m_Pawn).LockAim();

			useResources(class'AI_Resource'.const.RU_LEGS);
        }
    }
}

private function FleePoint FindFleePointDestination()
{
    local SwatAIRepository SwatAIRepo;
    local FleePoint Destination, Iter;
    local NavigationPointList AllFleePoints, ExcludesFleePoints;
    local int i;
	local Pawn CurrentEnemy, IterFleePointUser;

	local array<FleePoint> PossibleDestinations;

    SwatAIRepo = SwatAIRepository(m_Pawn.Level.AIRepo);

    log("Flee point room name: " $ m_Pawn.GetRoomNameSafe() $ " ");

    // we exclude the flee points that are in the room we're in
    ExcludesFleePoints = SwatAIRepo.GetRoomNavigationPointsOfType(m_Pawn.GetRoomNameSafe(), 'FleePoint');
    AllFleePoints = SwatAIRepo.FindAllOfNavigationPointClass(class'FleePoint', ExcludesFleePoints);

	CurrentEnemy = ISwatEnemy(m_Pawn).GetEnemyCommanderAction().GetCurrentEnemy();

    // go through each point and find the closest
    for(i=0; i<AllFleePoints.GetSize(); ++i)
    {
        Iter = FleePoint(AllFleePoints.GetEntryAt(i));

//		log("Distance to ITer from Enemy is: " $ VSize2D(Iter.Location - CurrentEnemy.Location) $ " Required Distance is: " $ MinRequiredFleeDistanceFromOfficer);

        if ((CurrentEnemy == None) || !CurrentEnemy.IsInRoom(Iter.GetRoomName(CurrentEnemy)))
        {
			IterFleePointUser = Iter.GetFleePointUser();

			if ((IterFleePointUser == None) || (IterFleePointUser == m_Pawn))
			{
				PossibleDestinations[PossibleDestinations.Length] = Iter;
			}
        }
    }

	// all done with the excludes list
	SwatAIRepo.ReleaseNavigationPointList(ExcludesFleePoints);
	SwatAIRepo.ReleaseNavigationPointList(AllFleePoints);

	if (PossibleDestinations.Length > 0)
		Destination = PossibleDestinations[Rand(PossibleDestinations.Length)];

    return Destination;
}

latent function Flee()
{
	local Pawn CurrentEnemy;
	CurrentEnemy = ISwatEnemy(m_Pawn).GetEnemyCommanderAction().GetCurrentEnemy();

	// trigger the speech
	ISwatEnemy(m_Pawn).GetEnemySpeechManagerAction().TriggerFleeSpeech();

	if (CurrentEnemy != None)
	{
		// let the hive know so officers can "notice" it if they see us
		SwatAIRepository(Level.AIRepo).GetHive().NotifyEnemyFleeing(m_Pawn);
	}

	clearDummyMovementGoal();

	// unlock our aim while we move
	ISwatAI(m_Pawn).UnlockAim();

	assert(FleeDestination != None);

    CurrentMoveToActorGoal = new class'MoveToActorGoal'(movementResource(), achievingGoal.Priority, FleeDestination);
    assert(CurrentMoveToActorGoal != None);
	CurrentMoveToActorGoal.AddRef();

	CurrentMoveToActorGoal.SetRotateTowardsPointsDuringMovement(true);

	// open doors frantically
	CurrentMoveToActorGoal.SetOpenDoorsFrantically(true);

	// don't close doors behind us, we're stunned remember?
	CurrentMoveToActorGoal.SetShouldCloseOpenedDoors(false);

	// we want to use cover while moving
	CurrentMoveToActorGoal.SetUseCoveredPaths();

	// don't use the walk threshold (keep running)
	CurrentMoveToActorGoal.SetWalkThreshold(0.0);

    // post the move to goal and wait for it to complete
    CurrentMoveToActorGoal.postGoal(self);

	// trigger the speech
	ISwatEnemy(m_Pawn).GetEnemySpeechManagerAction().TriggerCallForHelpSpeech();

    WaitForGoal(CurrentMoveToActorGoal);

    // remove the move to goal
    CurrentMoveToActorGoal.unPostGoal(self);
	CurrentMoveToActorGoal.Release();
	CurrentMoveToActorGoal = None;
}

// returns true if we find a flee destination
private function bool FindFleeDestination()
{
	FleeDestination = FindFleePointDestination();

	return (FleeDestination != None);
}

// These two have to set an idle rather than using the special animation channel,
//  otherwise we get a hitch in the animation

// subclasses must override
function name GetReactionAnimation()
{
	assert(false);
	return '';
}

latent function PlayReactionAnimation()
{
	local int AnimSpecialChannel;

	bPlayedAnimation = true;

	AnimSpecialChannel = m_Pawn.AnimPlaySpecial(GetReactionAnimation(), 0.1);
	m_Pawn.FinishAnim(AnimSpecialChannel);

	bPlayedAnimation = false;
}

// subclasses must override
function name GetAffectedAnimation()
{
	assert(false);
	return '';
}

latent function PlayAffectedAnimation()
{
	local int AnimSpecialChannel;
	local bool onfloor;

	bPlayedAnimation = true;
	
	onfloor =  ISwatAI(m_Pawn).IsArrestedOnFloor();

	AnimSpecialChannel = m_Pawn.AnimLoopSpecial(GetAffectedAnimation(), 0.1);

	// wait until we're supposed to be done
	while (Level.TimeSeconds < EndTime && 
	        ( ( !OnFloor && !ISwatAI(m_Pawn).IsArrestedOnFloor()) || ( onfloor ) ) //we are not interrupted by onfloor state
		  )
	{
		yield();
	}
	
	if ( !OnFloor && ISwatAI(m_Pawn).IsArrestedOnFloor()) 
		ISwatAI(m_Pawn).AnimStopSpecial();
	else if ( !ISwatAI(m_Pawn).IsArrestedOnFloor() )
		m_Pawn.FinishAnim(AnimSpecialChannel);

	bPlayedAnimation = false;
}

// subclasses must override
function name GetRecoveryAnimation()
{
	assert(false);
	return '';
}

latent function PlayRecoveryAnimation()
{
	local int AnimSpecialChannel;
	
	assert(!ISwatAI(m_Pawn).IsArrestedOnFloor());
	
	bPlayedAnimation = true;
	bRecovering      = true;

	AnimSpecialChannel = m_Pawn.AnimPlaySpecial(GetRecoveryAnimation(), 0.1);
	m_Pawn.FinishAnim(AnimSpecialChannel);

	bPlayedAnimation = false;
}

// changes the variable on both the goal and the action
private function SetPlayedReaction(bool inPlayedReaction)
{
	StunnedGoal(achievingGoal).bPlayedReaction = inPlayedReaction;
	bPlayedReaction                            = inPlayedReaction;
}

protected function bool ShouldDelayReaction()
{
	return ! bPlayedReaction;
}

protected function bool ShouldTriggerStunnedSpeech()
{
	return true;
}

// in case it happens twice
protected function bool ShouldReTriggerStunnedSpeech()
{
	return true;
}

// allow subclasses to extend functionality
protected latent function NotifyFinishedAffectedAnimation();

state Running
{
Begin:
	if (! resource.requiredResourcesAvailable(achievingGoal.priority, achievingGoal.priority))
	{
//		log(Name $ " Begin - Level.TimeSeconds: " $ Level.TimeSeconds $ " EndTime: " $ EndTime $ " achievingGoal.priority: " $ achievingGoal.priority);
		goto('WaitToAchieve');
	}

	// unlock any existing aim, and aim to our current rotation
	ISwatAI(m_Pawn).UnlockAim();
	ISwatAI(m_Pawn).AimToRotation(m_Pawn.Rotation);
	ISwatAI(m_Pawn).LockAim();

	useResources(class'AI_Resource'.const.RU_ARMS | class'AI_Resource'.const.RU_LEGS);

	if (ShouldDelayReaction())
	{
		SleepInitialDelayTime(false);
	}

    ISwatAI(m_Pawn).SetUpperBodyAnimBehavior(kUBAB_FullBody, kUBABCI_StunnedAction);

	if (ShouldTriggerStunnedSpeech())
		TriggerStunnedSpeech();

    // This will swap in an effect-specific animation set
	if ( !ISwatAI(m_Pawn).IsArrestedOnFloor() )
		m_Pawn.ChangeAnimation();

	if (! bPlayedReaction)
	{
		SetPlayedReaction(true);

		m_Pawn.DisableCollisionAvoidance();
		PlayReactionAnimation();
		
		if ( !ISwatAI(m_Pawn).IsArrestedOnFloor() )
			m_Pawn.EnableCollisionAvoidance();
		else
			m_Pawn.DisableCollisionAvoidance();
			
		//forced arrest after the first issued comply
		if (ISwatAICharacter(m_Pawn) != None  && !ISwatAICharacter(m_Pawn).isa('SwatOfficer') )
		{
			ISwatAICharacter(m_Pawn).SetCanBeArrested(true);
		}
		
		if(FindFleeDestination() && CanGetOutOfRoomSafely() && bComplexFlee && ISwatOfficer(m_Pawn) == None)
		{
			Flee();
		}
		else
		{
			RunFromStunningDevice();
		}
	}

	ISwatAICharacter(m_Pawn).BecomeAware();
	m_Pawn.DisableCollisionAvoidance();
	PlayAffectedAnimation();

	NotifyFinishedAffectedAnimation();

	PlayRecoveryAnimation();
	if ( !ISwatAI(m_Pawn).IsArrestedOnFloor() )
	{
		m_Pawn.EnableCollisionAvoidance();	

		// This will swap in an effectless animation set, since the effect
		// duration has ended
		m_Pawn.ChangeAnimation();
	}
	else
		m_Pawn.DisableCollisionAvoidance();
	
			//forced arrest after the first issued comply
	if (ISwatAICharacter(m_Pawn) != None  && !ISwatAICharacter(m_Pawn).isa('SwatOfficer') )
	{
		ISwatAICharacter(m_Pawn).SetCanBeArrested(false);
	}

succeed();

 WaitToAchieve:

	// stop any animations on the special channel if we have played an animation
	if (bPlayedAnimation)
		ISwatAI(m_Pawn).AnimStopSpecial();

	// clear out any dummy goal
	ClearDummyGoals();

	// wait until the required resources are available before trying to start again, or if time runs out
	while ((Level.TimeSeconds < EndTime) &&
		  !resource.requiredResourcesAvailable(achievingGoal.priority, achievingGoal.priority))
	{
//		log(Name $ " WaitToAchieve - Level.TimeSeconds: " $ Level.TimeSeconds $ " EndTime: " $ EndTime $ " achievingGoal.priority: " $ achievingGoal.priority);
		yield();
	}

	// if time runs out, we're done,
	// otherwise we start over
	if (Level.TimeSeconds >= EndTime)
	{
		succeed();
	}
	else
	{
		yield();
		goto('Begin');
	}
}

///////////////////////////////////////////////////////////////////////////////
defaultproperties
{
    satisfiesGoal = class'StunnedGoal'
    MinRequiredFleeDistanceFromOfficer = 200.0
	ThreatCooldown = 0.0
}
