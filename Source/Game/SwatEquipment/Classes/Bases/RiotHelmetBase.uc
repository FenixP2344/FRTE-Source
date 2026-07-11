class RiotHelmetBase extends Engine.Headgear
	implements SwatGame.IProtectFromPepperSpray;
	
var(Mesh) bool HasStrobeLight;
var(Mesh) int StrobeTextureIndex;

var(StrobeLight) StrobeLight AttachedStrobeLight;
var(StrobeLight) vector StrobePositionOffset; 
var bool CanSeeIRLaser;

simulated function bool GetCanSeeIRLaser()
{
	return CanSeeIRLaser;
}

simulated function SetCanSeeIRLaser(bool Set)
{
	CanSeeIRLaser = Set;
	
	if ( CanSeeIRLaser && SwatPlayer(Level.GetLocalPlayerController().Pawn).GetNightvisionState() )
	{

		SetStrobeLight();
		
		if(!AttachedStrobeLight.GetStrobeIsActive())
		{
			AttachedStrobeLight.SetIsActive(true);
			AttachedStrobeLight.StartPulsing();
		}
	}
	else
	{
		CanSeeIRLaser=false;
		AttachedStrobeLight.SetIsActive(false);
		AttachedStrobeLight.Stop();
	}
}

simulated function SetStrobeLight()
{
	if (AttachedStrobeLight == None )
	{
		AttachedStrobeLight = Spawn(class'StrobeLight');	
		StrobePositionOffset.X=0;
		StrobePositionOffset.Y=0;
		StrobePositionOffset.Z=20;
	}
}

simulated function UpdateStrobeLightPosition()
{
	if (AttachedStrobeLight != None )
	{
		AttachedStrobeLight.SetLocation(Pawn(Owner).GetBoneCoords(AttachmentBone).Origin + StrobePositionOffset );
		AttachedStrobeLight.SetRotation(Pawn(Owner).GetBoneRotation(AttachmentBone));
				
		//update textures
		if ( AttachedStrobeLight.GetStrobeLightOn())
			SetStrobeTextureON();
		else
			SetStrobeTextureOFF();
	}
}

simulated function SetStrobeTextureON()
{
	if( HasStrobeLight)
	{
		Skins[StrobeTextureIndex]=Material(DynamicLoadObject( "SWATgearTex.FlashlightLensOnShader", class'Material'));
	}
}

simulated function SetStrobeTextureOFF()
{
	if( HasStrobeLight)
	{
		Skins[StrobeTextureIndex]=None;
		//Skins[StrobeTextureIndex]=ActivatedMesh.Skins[StrobeTextureIndex];
	}
}


defaultproperties
{
	HasStrobeLight=true
	StrobeTextureIndex=1
}
