///////////////////////////////////////////////////////////////////////////////
// BlueTeamBackMarker.uc - blue light strip worn on the back (Team A / 0).
//
// Mesh only: the head marker already supplies the dynamic light, so the back
// strip stays cheap even with a full 16 player server.
///////////////////////////////////////////////////////////////////////////////

class BlueTeamBackMarker extends TeamMarker
    config(SwatEquipment);

defaultproperties
{
    AttachmentBone=Spine2
    StaticMesh=StaticMesh'gear_sef.lightstickblue_thrown'
    DrawScale=1.4
    RelativeLocation=(X=-3.0,Y=0.0,Z=0.0)
    RelativeRotation=(Pitch=0,Yaw=0,Roll=16384)

    bWantsLight=false
}
