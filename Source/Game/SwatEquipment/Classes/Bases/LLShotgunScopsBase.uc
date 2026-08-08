class LLShotgunScopsBase extends RoundBasedWeapon
  config(SwatEquipment);

var config float Damage;

var config float PlayerStingDuration;
var config float HeavilyArmoredPlayerStingDuration;
var config float NonArmoredPlayerStingDuration;
var config float AIStingDuration;
var config float OfficerUseRangeMin;
var config float OfficerUseRangeMax;
var config int OfficerUseTargetMinHealth;
var config int OfficerUseMaxShotsWhenStung;

//SCOPE CAMERA
var (Scope) config  bool  HasScope;
var (Scope) private config ScriptedTexture ScopeScreen;          // Scripted texture that we draw into
var (Scope) private config Material        ScopeShader;          // Shader applied to the first person mesh when active
var (Scope) private config Material        BlankScope;        // Material to use when the viewport isn't active
var (Scope) private config const int       SizeX;              // Size of the texture along the X axis
var (Scope) private config const int       SizeY;              // Size of the texture along the Y axis
var (Scope) private config const int       FOV;                // FOV for our viewport
var (Scope) private config const int	   ScopeIndex;         // texture index to apply scope camera 
var (Scope) private config const int       ScopeXAdjustment;   // X adjust for perfect aiming
var (Scope) private vector ScopeLocation;                 
var (Scope) private rotator ScopeRotation;    
var (Scope) private config Material FirstSkin;                 //used to avoid missing FirstPersonModel.Skin[0] texture.... god knows why....


simulated function DealDamage(Actor Victim, int Damage, Pawn Instigator, Vector HitLocation, Vector MomentumVector, class<DamageType> DamageType )
{
    // Don't deal damage for pawns, instead make them effected by the sting grenade
    if ( Victim.IsA( 'Pawn' ) )
    {
      IReactToDazingWeapon(Victim).ReactToLessLeathalShotgun(Pawn(Owner), Damage, MomentumVector, PlayerStingDuration, HeavilyArmoredPlayerStingDuration, NonArmoredPlayerStingDuration, AIStingDuration, DamageType);

      log("Called ReactToLessLeathalShotgun on: "$Victim$", Damage="$Damage$"" );

      // This is now handled in ReactToLessLeathalShotgun
      //Super.DealDamage( Victim, Damage, Instigator, HitLocation, MomentumVector, DamageType );
    }
    // Otherwise deal damage, cept for ExplodingStaticMesh that is....
    else if ( !Victim.IsA('ExplodingStaticMesh') )
    {
        Super.DealDamage( Victim, Damage, Instigator, HitLocation, MomentumVector, DamageType );
    }
}

// Less-lethal should never spawn blood effects
simulated function bool  ShouldSpawnBloodForVictim( Pawn PawnVictim, int Damage )
{
    return false;
}

simulated function bool ShouldOfficerUseAgainst(Pawn OtherActor, int ShotsFired)
{
    local SwatPawn SwatPawn;
    local float Distance;

    SwatPawn = SwatPawn(OtherActor);
    if (SwatPawn == None)
    {
        return false;
    }

    // Don't use them -at all- against hostages
    if (SwatPawn.IsA('SwatHostage'))
    {
        return false;
    }

    // Don't shoot the target if lower than X health
    if (SwatPawn.Health < OfficerUseTargetMinHealth)
    {
        return false;
    }

    if (SwatPawn.IsStung() && ShotsFired >= OfficerUseMaxShotsWhenStung)
    {   
        // Don't shoot more than 3 times if the target is stunned
        return false;
    }

    Distance = VSize(Owner.Location - OtherActor.Location);
    if (Distance < OfficerUseRangeMin || Distance > OfficerUseRangeMax)
    {   
        // Outside of the range
        log (Name$"::ShouldOfficerUseAgainst("$OtherActor.Name$") for "$Owner.Name$": not using the LL now because Distance of "$Distance$" falls outside the range.");
        return false;
    }

    return super.ShouldOfficerUseAgainst(OtherActor, ShotsFired);
}

//*******************************************************
//SCOPE CAMERA 
//*******************************************************
simulated function PostBeginPlay()
{
    Super.PostBeginPlay();
	
	if( HasScope )
		Disable('Tick');
}

simulated function OnGivenToOwner()
{
   Super.OnGivenToOwner();
   
   
     if( HasScope )
	{
   
		if ( Pawn(Owner) != None && Pawn(Owner).Controller == Level.GetLocalPlayerController() )
		{	 
			ScopeScreen.Client = Self;
			ScopeScreen.bNotifyClientBeforeRendering = true;
			ScopeScreen.SetSize(SizeX, SizeY);
			Disable('Tick');
		
			assert( FirstPersonModel != None );  
			
			//missing Skin[0] texture workaround
			FirstPersonModel.Skins[0] = FirstSkin;
		}
	}
}

simulated function EquippedHook()
{
	if( HasScope )
		Enable('Tick');
	
    Super.EquippedHook();
}

simulated function UnequippedHook()
{
	if( HasScope )
		Disable('Tick');

  Super.UnequippedHook();
}

simulated event Destroyed()
{
	if( HasScope )
	{
		if (ScopeScreen != None && ScopeScreen.Client == Self)
		{
			// prevent GC failure due to hanging actor refs
			ScopeScreen.Client = None;
		}
	}

	Super.Destroyed();
}

// Render a portal to the lcdscreen from the desired viewport loc and rot
simulated event RenderTexture(ScriptedTexture inTexture)
{
    //local Color White;

    //White.R = 255; White.G = 0; White.B = 0;

    ViewportCalcView(ScopeLocation, ScopeRotation);
    ScopeScreen.DrawPortal(0, 0, SizeX, SizeY, Level.GetLocalPlayerController(), ScopeLocation, ScopeRotation, FOV);
    //LCDScreen.DrawTile(SizeX/2, SizeY/2,  512, 512, 0, 0, 512, 512, ReticleTexture, White);
}

simulated function Tick(float DeltaTime)
{
	Super.Tick(DeltaTime);

	if( HasScope && Level.GetLocalPlayerController() != None )
	{
	  if(FirstPersonModel != None)
	  {
	    FirstPersonModel.Skins[0] = FirstSkin;
	    FirstPersonModel.Skins[ScopeIndex] = ScopeShader;
	  }
	    ScopeScreen.Revision++;

	  if (!Level.GetLocalPlayerController().WantsZoom) 
	  {
		if(FirstPersonModel != None)
		{
		  FirstPersonModel.Skins[ScopeIndex] = BlankScope;
		}
	  }
	 
	  ViewportCalcView(ScopeLocation, ScopeRotation);
    }
}

simulated function  ViewportCalcView(out Vector CameraLocation, out Rotator CameraRotation)
{
	local vector X,Y,Z;
	
    if(FirstPersonModel != None)
    { 
		GetPerfectFireStart(CameraLocation,CameraRotation);
		GetAxes(  CameraRotation, X, Y, Z );
		CameraLocation = CameraLocation + X * ScopeXAdjustment; //X * XAdjustment means offset forward to avoid clipping the scope model	
    }
}

///////////////////////////////////////////////////////////////////////////////
// Optic weapons always aim down sights: ignore the user's
// "Disable Ironsights" (traditional zoom) setting.
simulated function bool ForceIronsights()
{
	return true;
}


defaultproperties
{
    Slot=Slot_Invalid
	bIsLessLethal=true
	WoodBreachingChance = 0;
	MetalBreachingChance = 0;
	bPenetratesDoors=false
    OfficerUseRangeMin=256
    OfficerUseRangeMax=1024
    OfficerUseMaxShotsWhenStung=3
    OfficerUseTargetMinHealth=80
}
