class RiotShieldHG extends Handgun;

///////////////////////////////////////////////////////////////////////////////////
var() float MomentumToPenetrate;
var() float BlockedDamageFactor;
var() float PenetratedDamageFactor; 
var() float RiotShieldHealth;

///////////////////////////////////////////////////////////////////////////////////
	
//which slot should be equipped after this item becomes unavailable
simulated function EquipmentSlot GetSlotForReequip()
{
    return Slot_PrimaryWeapon;
}

//simulated function EquipmentSlot GetSlotForUnable()
//{
//    return Slot_Detonator;
//}
///////////////////////////////////////////////////////////////////////////////////
// HERE I WANT TO RETURN TO PRIMARY WEAPON IF IM IN DANGER!!! - TO BE FIX
///////////////////////////////////////////////////////////////////////////////////
simulated function ShieldHealth()
{
	if (MomentumToPenetrate < 400.000000);
		GetSlotForReequip();
}

///////////////////////////////////////////////////////////////////////////////////














///////////////////////////////////////////////////////////////////////////////////

// Decompiled with UE Explorer.







// Decompiled with UE Explorer.






// Decompiled with UE Explorer.
defaultproperties
{
	AttachmentBone=Torso
	ProtectedRegion=REGION_Torso
    BlockedDamageFactor=0.0
    bProjTarget=true
	ArmorProtection=Level_3
    MomentumToPenetrate=400
    bCollideActors=true
    bBlockHavok=true
}