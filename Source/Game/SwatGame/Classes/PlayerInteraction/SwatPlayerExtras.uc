///////////////////////////////////////////////////////////////////////////////
// SwatPlayerExtras.uc
//
// Non-native holder for local-player state that cannot live on
// SwatGamePlayerController (a native class with a locked layout - adding vars
// there crashes the game with a "native class size does not match" error).
//
// Because the state below is per-LOCAL-player and there is only one local
// player, we keep it on the class default object and access it from the
// controller as class'SwatPlayerExtras'.default.X.
///////////////////////////////////////////////////////////////////////////////

class SwatPlayerExtras extends Core.Object
    config(PlayerInterface_Use);

// ---- reload-blocks-ADS (gameplay rule, identical for every client) ----
var config bool bBlockZoomWhileReloading;

// ---- multiplayer walk-state replication ----
var bool LastReplicatedWalking;

// ---- "come here" summon delay tracker ----
var SummonDelayTracker LocalSummonDelayTracker;

// ---- recoil: per-shot kick with relative pitch/yaw ceilings ----
var config float MaxRecoilPitch;
var config float HorizontalRecoilMinFraction;
var config float HorizontalRecoilMaxFraction;
var config float MaxRecoilYaw;
var config float MinRecoilRecoveryDuration;
var config float MaxRecoilRecoveryDuration;
var float AppliedRecoilPitch;
var float AppliedRecoilYaw;
var SwatPawn RecoilPawn;
var float RecoilShotBasePitch;
var float RecoilShotBaseYaw;
var float RecoilYawMagnitude;
var int RecoilYawDirection;
var bool bAutomaticRecoilActive;
var bool bRecoilRecovering;
var float RecoilRecoveryStartTime;
var float RecoilRecoveryDuration;
var float RecoilRecoveryPitch;
var float RecoilRecoveryYaw;

// ---- night-vision modes ----
// 0 = native green, 1 = silver/gray thermal luminance, 2 = ENVG-B
// green/yellow/red surface temperature mapping, 3 = AI outlines.
// Keep the old boolean as a config alias for existing PlayerInterface_Use.ini
// files; runtime decisions use NVGMode.
var config byte NVGMode;
var config bool bNVGThermalFusion;
// true while the worn helmet locks its mode (ADVBase -> thermal only, N toggles off)
var bool bNVGModeLocked;
var config byte NVGOverlayAlpha;
var config byte NVGWhiteHotAlpha;
var array<SwatPawn> ThermalPawns;
var array<byte> ThermalSavedUnlit;
var array<byte> ThermalSavedAmbientGlow;
var array<float> ThermalSavedScaleGlow;
var array<byte> ThermalSavedStyle;
var array<Material> ThermalSavedSkins;
var array<int> ThermalSkinCounts;
var bool bThermalMaterialsApplied;
var int ThermalAppliedMode;

///////////////////////////////////////////////////////////////////////////////

defaultproperties
{
    bBlockZoomWhileReloading=true
    // Unreal rotators use 65536 units per revolution: 5461 is about 30 degrees.
    MaxRecoilPitch=2730.5
    HorizontalRecoilMinFraction=0.22
    HorizontalRecoilMaxFraction=0.36
    MaxRecoilYaw=1820.0
    MinRecoilRecoveryDuration=0.16
    MaxRecoilRecoveryDuration=0.42
    RecoilRecoveryDuration=0.24
    NVGMode=0
    bNVGThermalFusion=false
    NVGOverlayAlpha=8
    // Keep the white-hot wash subtle; pawn luminance carries the actual
    // gray-to-white thermal range.
    NVGWhiteHotAlpha=72
    ThermalAppliedMode=-1
}
