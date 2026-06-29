#include <sourcemod>
#include <WeaponHandling>

public void WH_OnReloadModifier(int client, int weapon, L4D2WeaponType weapontype, float &speedmodifier)
{
    switch (weapontype)
    {
		case L4D2WeaponType_Pistol: speedmodifier = speedmodifier * 2.00; 
		case L4D2WeaponType_Magnum: speedmodifier = speedmodifier * 2.00; 
		case L4D2WeaponType_Rifle: speedmodifier = speedmodifier * 2.00; 
		case L4D2WeaponType_RifleAk47: speedmodifier = speedmodifier * 2.00; 
		case L4D2WeaponType_RifleDesert: speedmodifier = speedmodifier * 2.00; 
		case L4D2WeaponType_RifleM60: speedmodifier = speedmodifier * 2.00; 
		case L4D2WeaponType_RifleSg552: speedmodifier = speedmodifier * 2.00; 
		case L4D2WeaponType_HuntingRifle: speedmodifier = speedmodifier * 2.00; 
		case L4D2WeaponType_SniperAwp: speedmodifier = speedmodifier * 2.00; 
		case L4D2WeaponType_SniperMilitary: speedmodifier = speedmodifier * 2.00; 
		case L4D2WeaponType_SniperScout: speedmodifier = speedmodifier * 2.00; 
		case L4D2WeaponType_SMG: speedmodifier = speedmodifier * 2.00; 
		case L4D2WeaponType_SMGSilenced: speedmodifier = speedmodifier * 2.00; 
		case L4D2WeaponType_SMGMp5: speedmodifier = speedmodifier * 2.00; 
		case L4D2WeaponType_Autoshotgun: speedmodifier = speedmodifier * 2.00; 
		case L4D2WeaponType_AutoshotgunSpas: speedmodifier = speedmodifier * 2.00; 
		case L4D2WeaponType_Pumpshotgun: speedmodifier = speedmodifier * 2.00; 
		case L4D2WeaponType_PumpshotgunChrome: speedmodifier = speedmodifier * 2.00; 
		case L4D2WeaponType_GrenadeLauncher: speedmodifier = speedmodifier * 2.00; 
    }
}

public void WH_OnGetRateOfFire(int client, int weapon, L4D2WeaponType weapontype, float &speedmodifier)
{
    switch (weapontype)
    {
        case L4D2WeaponType_AutoshotgunSpas: speedmodifier = speedmodifier * 1.25; 
		case L4D2WeaponType_Autoshotgun: speedmodifier = speedmodifier * 1.25; 
		case L4D2WeaponType_Pumpshotgun: speedmodifier = speedmodifier * 1.25; 
		case L4D2WeaponType_PumpshotgunChrome: speedmodifier = speedmodifier * 1.25; 
		case L4D2WeaponType_SniperAwp: speedmodifier = speedmodifier * 1.25; 
		case L4D2WeaponType_SniperScout: speedmodifier = speedmodifier * 1.25; 
		case L4D2WeaponType_Pistol: speedmodifier = speedmodifier * 1.25; 
		case L4D2WeaponType_SniperMilitary: speedmodifier = speedmodifier * 1.25; 
		case L4D2WeaponType_HuntingRifle: speedmodifier = speedmodifier * 1.25; 
		case L4D2WeaponType_RifleM60: speedmodifier = speedmodifier * 1.25;
		case L4D2WeaponType_RifleAk47: speedmodifier = speedmodifier * 1.25; 
    }
} 

public void WH_OnMeleeSwing(int client, int weapon, float &speedmodifier)
{
	speedmodifier = 2.0;
}