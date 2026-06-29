#pragma semicolon 1
#include <PTaH>

public void OnPluginStart() 
{
	PTaH(PTaH_WeaponCanUse, Hook, WeaponCanUse);
}
	
//Allowing Counter-terrorist pick up C4
public bool WeaponCanUse(int iClient, int iEnt, bool CanUse)
{
	static char sClassname[64];
	GetEdictClassname(iEnt, sClassname, sizeof(sClassname));
	if(StrEqual(sClassname, "weapon_c4")) return true;
	return CanUse;
}

