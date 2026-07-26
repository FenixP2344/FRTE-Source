///////////////////////////////////////////////////////////////////////////////
// RedTeamHeadMarker.uc - red glowstick worn on the head (Team B / 1).
///////////////////////////////////////////////////////////////////////////////

class RedTeamHeadMarker extends TeamMarker
    config(SwatEquipment);

defaultproperties
{
    AttachmentBone=Head
    StaticMesh=StaticMesh'gear_sef.lightstickred_thrown'
    DrawScale=1.15
    RelativeLocation=(X=0.0,Y=0.0,Z=6.0)
    RelativeRotation=(Pitch=16384,Yaw=0,Roll=0)

    bWantsLight=true
    GlowHue=0
    GlowSaturation=0
    GlowBrightness=200
    GlowRadius=7
    LightOffset=(X=0.0,Y=0.0,Z=6.0)
}
