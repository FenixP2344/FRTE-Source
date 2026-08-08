///////////////////////////////////////////////////////////////////////////////
class SwatWeaponFR extends Engine.SwatWeapon;
//Extended SwatWeapon class to avoid native restrictions

import enum LeanWalkState from SwatGame.SwatPlayer;
///////////////////////////////////////////////////////////////////////////////

//LASER 
var (Laser) config   bool bHasIRLaser;
var (Laser) config   bool bHasVisibleLaser;
var (Laser) private bool bWantLaser;
var (Laser) IRLaser IRLaserClass;
var (Laser) private bool CanSeeLaser;

//offset
var (Laser) config vector IRLaserPosition_1stPerson;
var (Laser) config rotator IRLaserRotation_1stPerson;
var (Laser) config vector IRLaserPosition_3rdPerson;
var (Laser) config rotator IRLaserRotation_3rdPerson;

//*******************************************************
//PIP SCOPE (independent of the classic ScopeBase camera)
//*******************************************************
// Picture-in-picture optic: the lens renders a live magnified portal that is
// only shown while actually aiming down sights - never while low-ready
// (manual or forced) and never while leaning / craning the neck.
var (PIP) config bool HasPIP;                          // enable the PIP lens on this weapon
var (PIP) private config ScriptedTexture PIPScreen;    // texture the portal renders into
var (PIP) private config Material PIPShader;           // lens shader (portal + reticle) while ADS
var (PIP) private config Material PIPBlank;            // blank lens when the portal is hidden
var (PIP) private config const int PIPSkinIndex;       // first-person model skin slot for the lens
var (PIP) private config const int PIPSizes;           // portal texture size (square)
var (PIP) private config const int PIPFOV;             // portal FOV (small = magnified, large ~= 1x)
var (PIP) private config const int PIPXAdjust;         // push the portal camera forward to avoid clipping
var (PIP) private vector PIPLocation;
var (PIP) private rotator PIPRotation;
var (PIP) private config Material PIPFirstSkin;        // skin[0] restoration workaround

//*******************************************************
//LASER
//*******************************************************
function LaserDraw()
{
	local vector traceEnd, hitNormal;
	local HandheldEquipmentModel WeaponModel;
	local vector PositionOffset;
	local rotator RotationOffset;
    local vector TraceStart;
	local vector HitLocation;
	
	//Dedicated server doesnt care about your laser
	assert(Level.Netmode != NM_DedicatedServer );
	
	if(bWantLaser && ( bHasIRLaser || bHasVisibleLaser) )
	{
	
	if (Pawn(Owner).isA('SwatPlayer') || Pawn(Owner).isA('SwatOfficer'))
	{
	
	if (InFirstPersonView())
    {
		PositionOffset = IRLaserPosition_1stPerson;
		RotationOffset = IRLaserRotation_1stPerson;
		WeaponModel = FirstPersonModel;
		
		IRLaserClass.SetRelativeLocation(PositionOffset);
		IRLaserClass.SetRelativeRotation(RotationOffset);
		WeaponModel.Owner.UpdateAttachmentLocations();
    }
    else 
    {
		PositionOffset = IRLaserPosition_3rdPerson;
		RotationOffset = IRLaserRotation_3rdPerson;
		WeaponModel = ThirdPersonModel;

	    //cant use player's attachment location cause UpdateAttachmentLocations() doesnt work when player's model is outside FOV 
		//and we want laser to start and be visible even when starting outside FOV
		//workaround it's not perfect (some kink rotation when crouched/low ready) but it works!!
		IrLaserClass.SetLocation(WeaponModel.Location + (positionoffset >> WeaponModel.Owner.GetBoneRotation('GripRHand') ));		
		IrLaserClass.SetRotation( Rotator( IrLaserClass.Location - WeaponModel.Owner.GetBoneCoords('GripRHand').Origin ) + RotationOffset );		
    }
	
	//we draw only if local player is on NVGs
	if ( bHasIRLaser )
	{
		//NVG assertion needed 
		if(SwatPlayer(Level.GetLocalPlayerController().Pawn).HasNVGActiveForLaser() && Level.GetLocalPlayerController().Pawn.IsFirstPerson() )
			IrLaserClass.Show();
		else
			IrLaserClass.Hide();
    }
	else
	{
		IrLaserClass.Show();
	}
	
	TraceStart = IrLaserClass.Location;
	TraceEnd = TraceStart + vector(IrLaserClass.Rotation) * 10000;
		
	if ( IrLaserClass.Trace(hitLocation, hitNormal, traceEnd, traceStart, true, , , , True) != None)
		IrLaserClass.LaserLength(VDist(TraceStart , hitLocation));
	else
		IrLaserClass.LaserLength(VDist(TraceStart , TraceEnd));
	
	//DEBUG
	//Level.GetLocalPlayerController().myHUD.AddDebugLine(traceStart, hitLocation,class'Engine.Canvas'.Static.MakeColor(0,255,0), 0.02);
	}
	
	}
	else
		IrLaserClass.Hide();
}

//client/AI laser use
simulated function SetLaser(bool bForce)
{
	//assert(Level.NetMode != NM_DedicatedServer);
	bWantLaser=bForce;
	
	//log("SetLaser() bWantLaser " $ bWantLaser $ " " $ Level.GetLocalPlayerController().Pawn.name );
	
	if (bWantLaser)
		InitLaser();
	else
		DestroyLaser();		
}


simulated function InitLaser()
{
	local HandheldEquipmentModel WeaponModel;	
	local vector PositionOffset;
	local rotator RotationOffset;
	
	//attach IRLaser class
	if (InFirstPersonView())
    {
		//assertWithDescription(FirstPersonModel != None, "[ckline] Can't set up flashlight for "$self$", FirstPersonModel is None");
		WeaponModel = FirstPersonModel;
		PositionOffset = IRLaserPosition_1stPerson;
		RotationOffset = IRLaserRotation_1stPerson;
    }
    else
    {
		//assertWithDescription(ThirdPersonModel != None, "[ckline] Can't set up flashlight for "$self$", ThirdPersonModel is None");
		WeaponModel = ThirdPersonModel;
		PositionOffset = IRLaserPosition_3rdPerson;
		RotationOffset = IRLaserRotation_3rdPerson;
    }
	
	if ( IRLaserClass != None )
		DestroyLaser();
	
	IRLaserClass=Spawn(class'IRLaser',WeaponModel);
	
	WeaponModel.Owner.AttachToBone(IRLaserClass, WeaponModel.EquippedSocket);
	
	IRLaserClass.SetRelativeLocation(PositionOffset);
	IRLaserClass.SetRelativeRotation(RotationOffset);
	WeaponModel.Owner.UpdateAttachmentLocations();
	
	if (bHasIRLaser)
		IRLaserClass.IRLaserColor();
    else if (bHasVisibleLaser)
		IRLaserClass.RedLaserColor();
	

}

simulated function bool IsLaserON()
{
	return bWantLaser;
}

simulated function DestroyLaser()
{
	IRLaserClass.Destroy();
}

simulated function bool HasIrLaser()
{
	return bHasIRLaser;
}

///////////////////////////////////////////////////////////////////////////////
// PIP scope lifecycle - mirrors the classic ScopeBase camera but self-contained.

simulated function PostBeginPlay()
{
	Super.PostBeginPlay();

	if (HasPIP)
		Disable('Tick');
}

simulated function OnGivenToOwner()
{
	Super.OnGivenToOwner();

	if (HasPIP)
	{
		if (Pawn(Owner) != None && Pawn(Owner).Controller == Level.GetLocalPlayerController())
		{
			PIPScreen.Client = Self;
			PIPScreen.bNotifyClientBeforeRendering = true;
			PIPScreen.SetSize(PIPSizes, PIPSizes);
			Disable('Tick');

			assert(FirstPersonModel != None);
			// missing Skin[0] workaround
			FirstPersonModel.Skins[0] = PIPFirstSkin;
		}
	}
}

simulated function EquippedHook()
{
	if (HasPIP)
		Enable('Tick');

	Super.EquippedHook();
}

simulated function UnequippedHook()
{
	if (HasPIP)
		Disable('Tick');

	Super.UnequippedHook();
}

simulated event Destroyed()
{
	if (HasPIP)
	{
		if (PIPScreen != None && PIPScreen.Client == Self)
			PIPScreen.Client = None;
	}

	Super.Destroyed();
}

// Render the portal into the lens texture from the desired view.
simulated event RenderTexture(ScriptedTexture inTexture)
{
	ViewportCalcViewPIP(PIPLocation, PIPRotation);
	PIPScreen.DrawPortal(0, 0, PIPSizes, PIPSizes, Level.GetLocalPlayerController(), PIPLocation, PIPRotation, PIPFOV);
}

simulated function Tick(float DeltaTime)
{
	local SwatGamePlayerController LPC;
	local SwatPawn PlayerPawn;
	local bool bRenderPIP;

	Super.Tick(DeltaTime);

	if (!HasPIP)
		return;

	LPC = SwatGamePlayerController(Level.GetLocalPlayerController());
	if (LPC == None)
		return;

	if (FirstPersonModel != None)
	{
		FirstPersonModel.Skins[0] = PIPFirstSkin;
		FirstPersonModel.Skins[PIPSkinIndex] = PIPShader;
	}

	// The portal only renders while actually aiming down sights, and never
	// while the weapon is low (manual or forced) or while leaning / craning
	// the neck over the shoulder.
	PlayerPawn = SwatPawn(LPC.Pawn);
	bRenderPIP = LPC.WantsZoom
		&& (PlayerPawn == None || !PlayerPawn.IsLowReady())
		&& (LPC.Pawn == None || !LPC.Pawn.bShoulderLook)
		&& (SwatPlayer(LPC.Pawn) == None || SwatPlayer(LPC.Pawn).LWS == Lean_Cent);

	if (bRenderPIP)
	{
		PIPScreen.Revision++;
		ViewportCalcViewPIP(PIPLocation, PIPRotation);
	}
	else if (FirstPersonModel != None)
	{
		FirstPersonModel.Skins[PIPSkinIndex] = PIPBlank;
	}
}

simulated function ViewportCalcViewPIP(out Vector CameraLocation, out Rotator CameraRotation)
{
	local vector X, Y, Z;

	if (FirstPersonModel != None)
	{
		GetPerfectFireStart(CameraLocation, CameraRotation);
		GetAxes(CameraRotation, X, Y, Z);
		CameraLocation = CameraLocation + X * PIPXAdjust;
	}
}
