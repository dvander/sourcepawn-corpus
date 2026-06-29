//////////////////////////////////////////////////////////////////
/////////////////////INCLUDE LIBRARIES////////////////////////////
//////////////////////////////////////////////////////////////////

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <colors>

//////////////////////////////////////////////////////////////////
//////////////////////////PLUGIN INFO/////////////////////////////
//////////////////////////////////////////////////////////////////

public Plugin myinfo = 
{
	name = "L4D(2) Gascan/Molotov Announce",
	author = "Foxhound",
	description = "Show a Announce when gascan + molotov is destroyed/thrown",
	version = "2020",
	url = "https://forums.alliedmods.net/showpost.php?p=2670127&postcount=13"
};

//////////////////////////////////////////////////////////////////
//////////////////////////PLUGIN START////////////////////////////
//////////////////////////////////////////////////////////////////

public void OnPluginStart()
{
	HookEvent("molotov_thrown", OnMolotovThrown);
}

//////////////////////////////////////////////////////////////////
////////////////////////ENTITY CREATED////////////////////////////
//////////////////////////////////////////////////////////////////

public void OnEntityCreated(int entity, const char[] name)
{
    if (StrEqual(name, "weapon_gascan"))
    {
        SDKHook(entity, SDKHook_OnTakeDamage, GasCanDestroyed);
    }
}

//////////////////////////////////////////////////////////////////
/////////////////////HOOK THE GASCAN DAMAGE///////////////////////
//////////////////////////////////////////////////////////////////

public Action GasCanDestroyed(int gascan, int & attacker, int & inflictor, float & damage, int & damageType, int & weapon, float damageForce[3], float damagePosition[3]) {
	if (!IsGascan(gascan) || !IsSurvivor(attacker) || IsFakeClient(attacker)) return Plugin_Continue;

	if (IsValidBullet(weapon)) {

		for (int i = 1; i <= MaxClients; i++) {
			if (IsSurvivor(i) && !IsFakeClient(i)) {
				CPrintToChat(i, "{orange}[{olive}BA{orange}] {blue}%N {olive}Has Burned A {orange}GasCan.", attacker);
			}
		}

		//PrintToChatAll("DMG TYPE: %i", damageType);

		AcceptEntityInput(gascan, "break");

		return Plugin_Changed;

	}

	return Plugin_Continue;
}

//////////////////////////////////////////////////////////////////
/////////////////////////LITTLE STOCKS////////////////////////////
//////////////////////////////////////////////////////////////////

bool IsSurvivor(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2);
}

//////////////////////////////////////////////////////////////////

bool IsValidBullet(int weapon)
{
	if(weapon != -1){
	char WeaponName[64];
	GetEdictClassname(weapon, WeaponName, sizeof(WeaponName));
	return (StrEqual(WeaponName, "weapon_autoshotgun")
	 || StrEqual(WeaponName, "weapon_grenade_launcher")
	 || StrEqual(WeaponName, "weapon_hunting_rifle")
	 || StrEqual(WeaponName, "weapon_pistol")
	 || StrEqual(WeaponName, "weapon_pistol_magnum")
	 || StrEqual(WeaponName, "weapon_pumpshotgun")
	 || StrEqual(WeaponName, "weapon_rifle")
	 || StrEqual(WeaponName, "weapon_rifle_ak47")
	 || StrEqual(WeaponName, "weapon_rifle_desert")
	 || StrEqual(WeaponName, "weapon_rifle_m60")
	 || StrEqual(WeaponName, "weapon_rifle_sg552")
	 || StrEqual(WeaponName, "weapon_shotgun_chrome")
	 || StrEqual(WeaponName, "weapon_shotgun_spas")
	 || StrEqual(WeaponName, "weapon_smg")
	 || StrEqual(WeaponName, "weapon_smg_mp5")
	 || StrEqual(WeaponName, "weapon_smg_silenced")
	 || StrEqual(WeaponName, "weapon_sniper_military")
	 || StrEqual(WeaponName, "weapon_sniper_scout")
	 || StrEqual(WeaponName, "weapon_molotov")
	 || StrEqual(WeaponName, "weapon_sniper_awp")
	 || StrEqual(WeaponName, "weapon_chainsaw"));
	}

	return false;
}

//////////////////////////////////////////////////////////////////

bool IsGascan(int entity)
{
    if (entity > 0 && IsValidEntity(entity) && IsValidEdict(entity))
    {
        char strClassName[64];
        GetEdictClassname(entity, strClassName, sizeof(strClassName));
        return StrEqual(strClassName, "weapon_gascan");
    }
    return false;
}

//////////////////////////////////////////////////////////////////
///////////////////////////MOLOTOV EVENT//////////////////////////
//////////////////////////////////////////////////////////////////

public Action OnMolotovThrown(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!IsSurvivor(client)) {
		return;
	}

	for (int i = 1; i <= MaxClients; i++) {
		if (IsSurvivor(i) && !IsFakeClient(i)) {
			CPrintToChat(i, "{orange}[{olive}BA{orange}] {blue}%N {olive}Has Thrown A {orange}Molotov.", client);
		}
	}
}

//////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////
//////////////////////////THE END/////////////////////////////////
//////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////