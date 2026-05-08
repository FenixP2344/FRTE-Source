class ActionMoveDoor extends Scripting.Action;

enum EDoorTarget
{
    DT_OpenRight,
    DT_OpenLeft,
    DT_Closed
};

var() editcombotype(enumScriptLabels) name DoorLabel;
var() EDoorTarget Target;     // <-- shows as a dropdown in the editor
var() bool ForceOpen;         // false = respect gameplay rules; true = force via DesiredPosition

// Map editor choice to the engine's DoorPosition
final function Door.DoorPosition ToDoorPosition()
{
    switch (Target)
    {
        case DT_OpenRight: return DoorPosition_OpenRight;
        case DT_OpenLeft:  return DoorPosition_OpenLeft;
        case DT_Closed:    return DoorPosition_Closed;
    }
    // Fallback
    return DoorPosition_Closed;
}

latent function Variable execute()
{
    local SwatDoor     D;
    local Door.DoorPosition P;

    super.execute();

    D = SwatDoor(parentScript.findByLabel(class'SwatDoor', DoorLabel));
    assertWithDescription(D != None, "ActionMoveDoor: No SwatDoor found with label '" $ DoorLabel $ "'");

    P = ToDoorPosition();

    if (!ForceOpen)
    {
        // Player-like route: respects locks/wedges/blockers/etc.
        if (parentScript.Level.NetMode != NM_Client)
        {
            
			D.SetPositionForMove(P, MR_Interacted);
            D.Moved(false, false);     // IMPORTANT: actually perform the move
        }
    }
    else
    {
        // Force route: property path (server updates Desired; SwatDoor drives the move)
        if (parentScript.Level.NetMode != NM_Client)
        {
            D.DesiredPosition = P;
            D.DesiredPositionChanged();  // sets PendingPosition and calls Moved(false,true)
        }
    }

    return None;
}

// Limit the picker to door labels
event function enumScriptLabels(Engine.LevelInfo level, out Array<Name> s)
{
    local SwatDoor d;
    ForEach level.AllActors(class'SwatDoor', d)
        if (d.label != d.name && d.label != '')
            s[s.Length] = d.label;
}











// Decompiled with UE Explorer.
defaultproperties
{
    actionDisplayName="Door: Set Position"
    actionHelp="Moves the specified SwatDoor to Open Left, Open Right, or Closed."
    category="Door"
}