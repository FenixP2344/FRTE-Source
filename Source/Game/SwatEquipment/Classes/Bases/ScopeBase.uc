///////////////////////////////////////////////////////////////////////////////
class ScopeBase extends ClipBasedWeapon;
///////////////////////////////////////////////////////////////////////////////

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
	if( HasScope )
	{
	  FirstPersonModel.Skins[0] =  FirstSkin; 
	  if(FirstPersonModel != None)
	  {
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