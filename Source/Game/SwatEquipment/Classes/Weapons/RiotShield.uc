class RiotShield extends SwatGame.EquipmentUsedOnOther
    implements ITacticalAid;

///////////////////////////////////////////////////////////////////////////////////
var() float MomentumToPenetrate;
var() float BlockedDamageFactor;
var() float PenetratedDamageFactor; 
var() float RiotShieldHealth;

///////////////////////////////////////////////////////////////////////////////////
//simulated function UnabletoUseRiotShield()
//{
//    if (FirstPersonModel != None)
//}
///////////////////////////////////////////////////////////////////////////////////
simulated function PostBeginPlay()
{
    Super.PostBeginPlay();

    bWorldGeometry = true;
}
///////////////////////////////////////////////////////////////////////////////////

simulated function UsedHook()
{
    local SwatDoor TargetDoor;

    if (FirstPersonModel != None)
        FirstPersonModel.Hide();
    if (ThirdPersonModel != None)
        ThirdPersonModel.Hide();

    TargetDoor = SwatDoor(Other);
    if (TargetDoor.ActorIsToMyLeft(Pawn(Owner)))
    {
        if (TargetDoor.GetDeployedC2ChargeLeft() != None)
            return; //someone else beat us to it... don't confuse the issue
    }
    else    //Owner is on the Door's Right
        if (TargetDoor.GetDeployedC2ChargeRight() != None)
            return; //someone else beat us to it... don't confuse the issue

    IAmUsedByC2Charge(Other).OnUsedByC2Charge(ICanUseC2Charge(Owner));
}

// IAmAQualifiedUseEquipment implementation

simulated function float GetQualifyDuration()
{
    return IAmUsedByC2Charge(Other).GetQualifyTimeForC2Charge();
}

// IAmUsedOnOther implementation

simulated protected function AssertOtherIsValid()
{
    assertWithDescription(Other.IsA('IAmUsedByC2Charge'),
        "[tcohen] A RiotShield was called to AssertOtherIsValid(), but Other is a "$Other.class.name
        $", which is not an IAmUsedByC2Charge.");
}

///////////////////////////////////////////////////////////////////////////////////
	
//which slot should be equipped after this item becomes unavailable
simulated function EquipmentSlot GetSlotForReequip()
{
    return Slot_PrimaryWeapon;
}

simulated function EquipmentSlot GetSlotForUnable()
{
    return Slot_Detonator;
}
///////////////////////////////////////////////////////////////////////////////////
// HERE I WANT TO RETURN TO PRIMARY WEAPON IF IM IN DANGER!!! - TO BE FIX
///////////////////////////////////////////////////////////////////////////////////
simulated function ShieldHealth()
{
	if (MomentumToPenetrate < 50.000000);
		GetSlotForReequip();
}

///////////////////////////////////////////////////////////////////////////////////














///////////////////////////////////////////////////////////////////////////////////

// Decompiled with UE Explorer.







// Decompiled with UE Explorer.






// Decompiled with UE Explorer.
defaultproperties
{
    MomentumToPenetrate=10000
    bCollideActors=true
    bBlockHavok=true
}