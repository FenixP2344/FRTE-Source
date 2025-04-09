class SASmaskBase extends Engine.ProtectiveEquipment
    implements IProtectFromCSGas, IProtectFromPepperSpray, IProtectFromFlashbang;

function QualifyProtectedRegion() 
{
    assertWithDescription(ProtectedRegion < REGION_Body_Max,
        "[Carlos] The SASmaskBase class "$class.name
        $" specifies ProtectedRegion="$GetEnum(ESkeletalRegion, ProtectedRegion)
        $".  ProtectiveEquipment may only protect body regions or Region_None.");
}
