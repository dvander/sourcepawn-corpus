#include <sourcemod>
#include <sdkhooks>

enum WpnID {
	wpn_none,
	ConVar:wpn_ak47,
	ConVar:wpn_aug,
	ConVar:wpn_awp,
	ConVar:wpn_bizon,
	ConVar:wpn_deagle,
	ConVar:wpn_elite,
	ConVar:wpn_famas,
	ConVar:wpn_fiveseven,
	ConVar:wpn_g3sg1,
	ConVar:wpn_galilar,
	ConVar:wpn_glock,
	ConVar:wpn_hkp2000,
	ConVar:wpn_knife,
	ConVar:wpn_m249,
	ConVar:wpn_m4a1,
	ConVar:wpn_mac10,
	ConVar:wpn_mag7,
	ConVar:wpn_mp7,
	ConVar:wpn_mp9,
	ConVar:wpn_negev,
	ConVar:wpn_nova,
	ConVar:wpn_p250,
	ConVar:wpn_p90,
	ConVar:wpn_sawedoff,
	ConVar:wpn_scar20,
	ConVar:wpn_sg556,
	ConVar:wpn_ssg08,
	ConVar:wpn_tec9,
	ConVar:wpn_ump45,
	ConVar:wpn_xm1014
};

ConVar wpn_damage[WpnID];
float wpn_damage_value[WpnID];

char WeaponClassname[WpnID][] = {
	"", "weapon_ak47", "weapon_aug", "weapon_awp", "weapon_bizon", "weapon_deagle", "weapon_elite", "weapon_famas", "weapon_fiveseven", "weapon_g3sg1", "weapon_galilar", "weapon_glock", "weapon_hkp2000", "weapon_knife", "weapon_m249", "weapon_m4a1", "weapon_mac10", "weapon_mag7", "weapon_mp7", "weapon_mp9", "weapon_negev", "weapon_nova", "weapon_p250", "weapon_p90", "weapon_sawedoff", "weapon_scar20", "weapon_sg556", "weapon_ssg08", "weapon_tec9", "weapon_ump45", "weapon_xm1014"
};

Handle hWeaponClassTrie = INVALID_HANDLE;

stock void InitWeaponClassTrie()
{
    hWeaponClassTrie = CreateTrie();
    for(int i = 0; i < view_as<int>(WpnID); i++)
    {
        SetTrieValue(hWeaponClassTrie, WeaponClassname[view_as<WpnID>(i)], i);
    }
}

stock WpnID WeaponClassToId(const char[] weaponClass)
{
    WpnID id;
    if(hWeaponClassTrie == INVALID_HANDLE)
    {
        InitWeaponClassTrie();
    }
    if(GetTrieValue(hWeaponClassTrie, weaponClass, id))
    {
        return view_as<WpnID>(id);
    }
    return wpn_none;
}

public Plugin myinfo =
{
	name = "CS:GO Weapons Damage Mod",
	author = "Accelerator",
	description = "",
	version = "2.0",
	url = "http://core-ss.org"
};

public void OnPluginStart()
{
	wpn_damage[wpn_ak47] = CreateConVar("damage_ak47", "1.0");
	wpn_damage[wpn_aug] = CreateConVar("damage_aug", "1.0");
	wpn_damage[wpn_awp] = CreateConVar("damage_awp", "1.0");
	wpn_damage[wpn_bizon] = CreateConVar("damage_bizon", "1.0");
	wpn_damage[wpn_deagle] = CreateConVar("damage_deagle", "1.0", "Deagle and Revolver");
	wpn_damage[wpn_elite] = CreateConVar("damage_elite", "1.0");
	wpn_damage[wpn_famas] = CreateConVar("damage_famas", "1.0");
	wpn_damage[wpn_fiveseven] = CreateConVar("damage_fiveseven", "1.0");
	wpn_damage[wpn_g3sg1] = CreateConVar("damage_g3sg1", "1.0");
	wpn_damage[wpn_galilar] = CreateConVar("damage_galilar", "1.0");
	wpn_damage[wpn_glock] = CreateConVar("damage_glock", "1.0");
	wpn_damage[wpn_hkp2000] = CreateConVar("damage_hkp2000", "1.0", "HKP2000 and USP Silencer");
	wpn_damage[wpn_knife] = CreateConVar("damage_knife", "1.0");
	wpn_damage[wpn_m249] = CreateConVar("damage_m249", "1.0");
	wpn_damage[wpn_m4a1] = CreateConVar("damage_m4a1", "1.0", "M4A1 and M4A1 Silencer");
	wpn_damage[wpn_mac10] = CreateConVar("damage_mac10", "1.0");
	wpn_damage[wpn_mag7] = CreateConVar("damage_mag7", "1.0");
	wpn_damage[wpn_mp7] = CreateConVar("damage_mp7", "1.0");
	wpn_damage[wpn_mp9] = CreateConVar("damage_mp9", "1.0");
	wpn_damage[wpn_negev] = CreateConVar("damage_negev", "1.0");
	wpn_damage[wpn_nova] = CreateConVar("damage_nova", "1.0");
	wpn_damage[wpn_p250] = CreateConVar("damage_p250", "1.0", "P250 and CZ75A");
	wpn_damage[wpn_p90] = CreateConVar("damage_p90", "1.0");
	wpn_damage[wpn_sawedoff] = CreateConVar("damage_sawedoff", "1.0");
	wpn_damage[wpn_scar20] = CreateConVar("damage_scar20", "1.0");
	wpn_damage[wpn_sg556] = CreateConVar("damage_sg556", "1.0");
	wpn_damage[wpn_ssg08] = CreateConVar("damage_ssg08", "1.0");
	wpn_damage[wpn_tec9] = CreateConVar("damage_tec9", "1.0");
	wpn_damage[wpn_ump45] = CreateConVar("damage_ump45", "1.0");
	wpn_damage[wpn_xm1014] = CreateConVar("damage_xm1014", "1.0");
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
			OnClientPutInServer(i);
	}
	for(int i = 1; i < view_as<int>(WpnID); i++)
    {
		wpn_damage_value[i] = wpn_damage[i].FloatValue;
		HookConVarChange(wpn_damage[i], OnConVarDamageChange);
	}
	AutoExecConfig(true, "damagemod");
}

public void OnConVarDamageChange(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	if (StringToFloat(newVal) == StringToFloat(oldVal))
		return;
	
	for(int i = 1; i < view_as<int>(WpnID); i++)
	{
		if (cvar == wpn_damage[i])
		{
			wpn_damage_value[i] = wpn_damage[i].FloatValue;
		}
	}
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if (damage <= 0.0 || victim < 1 || victim > MaxClients || attacker < 1 || attacker > MaxClients)
		return Plugin_Continue;
	
	if (!IsValidEdict(weapon))
		return Plugin_Continue;
	
	char clsname[32];
	GetEdictClassname(weapon, clsname, sizeof(clsname));
	
	WpnID WeaponId;
	if ((WeaponId = WeaponClassToId(clsname)) != wpn_none)
	{
		damage *= wpn_damage_value[WeaponId];
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}