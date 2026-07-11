class RiotShieldHG extends ShieldHandgun;

var private bool DebugTrace;

simulated function EquippedHook()
{
	super.EquippedHook();
	if (Ammo == None)
	{
		Ammo = new class'LessLethalNoAmmo';
		ShotgunAmmo(Ammo).StartingRounds=1;
		ShotgunAmmo(Ammo).CurrentRounds=1;
		Log("LessLethal No Ammo " $ Ammo.name $ " Rounds " $ ShotgunAmmo(Ammo).StartingRounds);
	}
	
}

defaultproperties
{
	IgnoreAmmoOverrides=true
}
