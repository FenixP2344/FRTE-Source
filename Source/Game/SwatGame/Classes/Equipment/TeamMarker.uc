///////////////////////////////////////////////////////////////////////////////
// TeamMarker.uc
//
// PVP team identification marker. Attaches a coloured glowstick mesh to
// a pawn bone so opposing teams can be told apart at a glance.
//
// Extends plain Actor, NOT SimpleEquipment — markers are spawned and
// bone-attached directly; they are never added to inventory, so extending
// Equipment would pull them into the inventory render chain and cause a
// phantom "shield on back" bug in MP spectator mode.
///////////////////////////////////////////////////////////////////////////////

class TeamMarker extends Engine.Actor
    config(SwatEquipment);

// Light tuning. Hue 0 = red, 153 = blue.
var config byte  GlowHue;
var config byte  GlowSaturation;
var config float GlowBrightness;
var config float GlowRadius;

// Only head markers spawn a dynamic light.
var config bool  bWantsLight;

// Local offset applied to the spawned light.
var config vector LightOffset;

var private DynamicLightEffect Light;

simulated function PostBeginPlay()
{
    Super.PostBeginPlay();

    if (bWantsLight && Level.NetMode != NM_DedicatedServer)
    {
        Light = Spawn(class'DynamicLightEffect', self);

        if (Light != None)
        {
            Light.LightBrightness = GlowBrightness;
            Light.LightHue        = GlowHue;
            Light.LightSaturation = GlowSaturation;
            Light.LightRadius     = GlowRadius;
            Light.SetLocation(Location + LightOffset);

            Enable('Tick');
        }
    }
    else
    {
        Disable('Tick');
    }
}

simulated function Tick(float DeltaTime)
{
    Super.Tick(DeltaTime);

    if (Light == None || Light.bDeleteMe)
    {
        Light = None;
        Disable('Tick');
        return;
    }

    Light.SetLocation(Location + LightOffset);
}

simulated event Destroyed()
{
    if (Light != None)
    {
        Light.Destroy();
        Light = None;
    }

    Super.Destroyed();
}

defaultproperties
{
    AttachmentBone=Head

    DrawType=DT_StaticMesh
    StaticMesh=StaticMesh'gear_sef.lightstick_depleted'
    DrawScale=1.0

    bStatic=false
    bNoDelete=false
    bCollideActors=false
    bBlockActors=false
    bBlockPlayers=false
    bCollideWorld=false
    bProjTarget=false

    // Visible to everyone so both teams can identify each other.
    bOnlyOwnerSee=false
    bOwnerNoSee=false

    RemoteRole=ROLE_SimulatedProxy
    bNetTemporary=true

    bWantsLight=false
    GlowHue=0
    GlowSaturation=0
    GlowBrightness=180
    GlowRadius=6
    LightOffset=(X=0.0,Y=0.0,Z=4.0)
}
