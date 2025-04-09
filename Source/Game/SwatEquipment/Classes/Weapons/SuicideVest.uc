class SuicideVest extends RoundBasedWeapon;

//GEZ - Added

function BallisticFire(vector StartTrace, vector EndTrace)
{
    local vector ShotVector;
    local SwatProjectile Grenade;
    local vector GrenadeStart;
    local rotator GrenadeRotation;

	// Don't spawn projectiles on a client
	if (Level.NetMode == NM_Client)
		return;

    ShotVector = Normal(EndTrace - StartTrace);

    GrenadeStart = StartTrace + ShotVector * 20.0;     //push grenade away from the camera a bit

	assertWithDescription(Ammo.ProjectileClass != None,
        "[ryan] The RPGLauncher's Ammo.ProjectileClass was None for Ammo class " $ Ammo.class $ ".");

    Grenade = Spawn(
        Ammo.ProjectileClass,	//SpawnClass
        Owner,					//SpawnOwner
        ,						//SpawnTag
        GrenadeStart,			//SpawnLocation
        ,						//SpawnRotation
        true);					//bNoCollisionFail

    assert(Grenade != None);

	if (Grenade.IsA('SwatGrenadeProjectile'))
		SwatGrenadeProjectile(Grenade).bWasFired = true;

    Grenade.Velocity = ShotVector * MuzzleVelocity;

	GrenadeRotation = Rotator(Grenade.Velocity);
	GrenadeRotation.Yaw -= 16384;

	Grenade.SetRotation( GrenadeRotation );
}





// Decompiled with UE Explorer.
defaultproperties
{
    MagazineSize=1
    zoomedSensitivity=1
    PlayerAmmoOption=/* Array type was not detected. */
    EnemyUsesAmmo=/* Array type was not detected. */
    MaxAimError=40
    SmallAimErrorRecoveryRate=3
    LargeAimErrorRecoveryRate=14
    AimErrorBreakingPoint=5.5
    LookAimErrorPenaltyFactor=0.000125
    MaxLookAimErrorPenalty=13
    InjuredAimErrorPenalty=1.5
    MaxInjuredAimErrorPenalty=6
    EquippedAimErrorPenalty=9
    FiredAimErrorPenalty=0.7
    WalkToRunAimErrorPenalty=5.5
    StandToWalkAimErrorPenalty=2.5
    StandingAimError=2.75
    WalkingAimError=3.5
    RunningAimError=11
    CrouchingAimError=2.25
    RecoilBackDuration=0.05
    RecoilForeDuration=0.45
    RecoilMagnitude=1200
    FlashlightPosition_1stPerson=(X=14,Y=-4,Z=7)
    FlashlightPosition_3rdPerson=(X=0,Y=-34.6,Z=2.7)
    FlashlightRotation_3rdPerson=(Pitch=0,Yaw=-16384,Roll=0)
    OverrideArmDamageModifier=1
    OfficerWontEquipAsPrimary=true
    Range=250
    Description="A vest made of improvised explosives used for terrorist attacks.  This vest will kill its wearer upon detonation."
    FriendlyName="Suicide Vest"
    GUIImage=Texture'CF_WeaponTex.SuicideVest_gui'
    ZoomedFOV=90
    LightstickThrowAnimPostfix=M4
    UseAnimationRate=1.5
}