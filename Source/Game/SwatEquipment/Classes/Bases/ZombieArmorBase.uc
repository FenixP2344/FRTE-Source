class ZombieArmorBase extends BodyArmorBase
    implements SwatGame.IProtectFromSting, SwatGame.IProtectFromTaser;

function QualifyProtectedRegion()
{
    assertWithDescription(ProtectedRegion < REGION_Body_Max,
        "[Carlos] The CeramicArmorBase class "$class.name
        $" specifies ProtectedRegion="$GetEnum(ESkeletalRegion, ProtectedRegion)
        $".  ProtectiveEquipment may only protect body regions or Region_None.");
}