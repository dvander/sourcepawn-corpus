#include <sourcemod>
#include <sdktools>

#define DEFAULT_FLAGS FCVAR_PLUGIN|FCVAR_NOTIFY
#define PLUGIN_VERSION "1"

static Handle:AssaultAmmoCVAR = INVALID_HANDLE;
static Handle:SMGAmmoCVAR = INVALID_HANDLE;
static Handle:ShotgunAmmoCVAR = INVALID_HANDLE;
static Handle:AutoShotgunAmmoCVAR = INVALID_HANDLE;
static Handle:HRAmmoCVAR = INVALID_HANDLE;
static Handle:SniperRifleAmmoCVAR = INVALID_HANDLE;
static Handle:GrenadeLauncherAmmoCVAR = INVALID_HANDLE;
static Handle:M60AmmoCVAR = INVALID_HANDLE;

static bool:buttondelay[MAXPLAYERS+1];
public Plugin:myinfo ={
	name = "Unlimit Reload",
	author = "Lumiere/亮晶晶",
	description = "Dont ever need to reload again!",
	version = "1.0.0.0",
	url = "http://www.sourcemod.net/"
}
 
public OnPluginStart(){
	CreateConVar("l4d2_unlimitreload_version", PLUGIN_VERSION, " Version of L4D2 Unlimit Reload on this server ", DEFAULT_FLAGS|FCVAR_SPONLY|FCVAR_DONTRECORD);
	
	AssaultAmmoCVAR = CreateConVar("l4d2_unlimitreload_assaultreload", "30", "Reload amont for Assault Rifles ", DEFAULT_FLAGS);
	SMGAmmoCVAR = CreateConVar("l4d2_unlimitreload_smgreload", "50", "Reload amount for SMG gun types ", DEFAULT_FLAGS);
	ShotgunAmmoCVAR = CreateConVar("l4d2_unlimitreload_shotgunreload", "8", "Reload amount for Shotgun and Chrome Shotgun ", DEFAULT_FLAGS);
	AutoShotgunAmmoCVAR = CreateConVar("l4d2_unlimitreload_autoshotgunreload", "10", "Reload amount for Autoshottie and SPAS ", DEFAULT_FLAGS);
	HRAmmoCVAR = CreateConVar("l4d2_unlimitreload_huntingrifleareload", "30", "Reload amount for the Hunting Rifle ", DEFAULT_FLAGS);
	SniperRifleAmmoCVAR = CreateConVar("l4d2_unlimitreload_sniperrifleareload", "30", "Reload amount for the Military Sniper Rifle, AWP, and Scout ", DEFAULT_FLAGS);	
	GrenadeLauncherAmmoCVAR = CreateConVar("l4d2_unlimitreload_grenadelauncherreload", "1", "Reload amount for the Grenade Launcher ", DEFAULT_FLAGS);
	AutoExecConfig(true, "l4d2_unlimitreload");
	HookEvent("weapon_fire", Event_Weapon_fire);
}
public Action:Event_Weapon_fire(Handle:event, const String:name[], bool:dontBroadcast){
	new client = GetClientOfUserId(GetEventInt(event, "userid"));	
	decl String:weaponName[20];
	GetEventString(event, "weapon", weaponName, sizeof(weaponName));
    if (!IsValidEntity(client)) return 1000;
    new weapon = GetPlayerWeaponSlot(client, 0); 
    if (IsValidEntity(weapon)){
		new iOffset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 0)*4;
		new iAmmoTable = FindSendPropInfo("CTerrorPlayer", "m_iAmmo");
		new clipammo=GetEntProp(weapon, Prop_Send, "m_iClip1");
		new allAmmo=GetEntData(client, iAmmoTable+iOffset);
		PrintToServer("GetAmmo  %d,%d %s %",clipammo,allAmmo,weaponName);
		if(clipammo<=1){
			if (StrEqual(weaponName, "pumpshotgun")||StrEqual(weaponName, "shotgun_chrome")){
				if(allAmmo>=GetConVarInt(ShotgunAmmoCVAR)){
					SetEntProp(weapon, Prop_Send, "m_iClip1",GetConVarInt(ShotgunAmmoCVAR));
					SetEntData(client, iAmmoTable+iOffset, allAmmo-GetConVarInt(ShotgunAmmoCVAR), 4, true);
				}
			}
			if (StrEqual(weaponName, "autoshotgun")||StrEqual(weaponName, "shotgun_spas")){
				if(allAmmo>=GetConVarInt(AutoShotgunAmmoCVAR)){
					SetEntProp(weapon, Prop_Send, "m_iClip1",GetConVarInt(AutoShotgunAmmoCVAR));
					SetEntData(client, iAmmoTable+iOffset, allAmmo-GetConVarInt(AutoShotgunAmmoCVAR), 4, true);
				}
			}
			if (StrEqual(weaponName, "smg")||StrEqual(weaponName, "smg_silenced")||StrEqual(weaponName, "smg_mp5")){
				if(allAmmo>=GetConVarInt(SMGAmmoCVAR)){
					SetEntProp(weapon, Prop_Send, "m_iClip1",GetConVarInt(SMGAmmoCVAR));
					SetEntData(client, iAmmoTable+iOffset, allAmmo-GetConVarInt(SMGAmmoCVAR), 4, true);
				}
			}
			if (StrEqual(weaponName, "rifle")||StrEqual(weaponName, "rifle_ak47")||StrEqual(weaponName, "rifle_ak47")||StrEqual(weaponName, "rifle_sg552")||StrEqual(weaponName, "rifle_desert")){
				if(allAmmo>=GetConVarInt(AssaultAmmoCVAR)){
					SetEntProp(weapon, Prop_Send, "m_iClip1",GetConVarInt(AssaultAmmoCVAR));
					SetEntData(client, iAmmoTable+iOffset, allAmmo-GetConVarInt(AssaultAmmoCVAR), 4, true);
				}
			}
			if (StrEqual(weaponName, "hunting_rifle")){
				if(allAmmo>=GetConVarInt(HRAmmoCVAR)){
					SetEntProp(weapon, Prop_Send, "m_iClip1",GetConVarInt(HRAmmoCVAR));
					SetEntData(client, iAmmoTable+iOffset, allAmmo-GetConVarInt(HRAmmoCVAR), 4, true);
				}
			}
			if (StrEqual(weaponName, "sniper_military")||StrEqual(weaponName, "sniper_awp")||StrEqual(weaponName, "sniper_scout")){
				if(allAmmo>=GetConVarInt(SniperRifleAmmoCVAR)){
					SetEntProp(weapon, Prop_Send, "m_iClip1",GetConVarInt(SniperRifleAmmoCVAR));
					SetEntData(client, iAmmoTable+iOffset, allAmmo-GetConVarInt(SniperRifleAmmoCVAR), 4, true);
				}
			}
			if (StrEqual(weaponName, "grenade_launcher")){
				if(allAmmo>=GetConVarInt(GrenadeLauncherAmmoCVAR)){
					SetEntProp(weapon, Prop_Send, "m_iClip1",GetConVarInt(GrenadeLauncherAmmoCVAR));
					SetEntData(client, iAmmoTable+iOffset, allAmmo-GetConVarInt(GrenadeLauncherAmmoCVAR), 4, true);
				}
			}
		}
	}
}
public GetPriAmmo(entity)
{
    if(IsValidEntity(entity))
        return GetEntProp(entity, Prop_Send, "m_iClip1");
    return 200;
}

stock SetAmmo(client, slot, ammo)
{
    new weapon = GetPlayerWeaponSlot(client, slot);
    if (IsValidEntity(weapon))
    {
        new iOffset = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType", 0)*4;
        new iAmmoTable = FindSendPropInfo("CTerrorPlayer", "m_iAmmo");
        SetEntData(client, iAmmoTable+iOffset, ammo, 4, true);
    }
}