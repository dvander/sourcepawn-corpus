#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION		"1.1"

bool g_weaponChanged		=false;
bool isl4d2					=false;

// ConVar Handles
ConVar h_pluginEnable;
ConVar h_weaponAmount;
ConVar h_medkitAmount;
ConVar h_pillsAmount;
ConVar h_pipebombAmount;
ConVar h_molotovAmount;
ConVar h_vomitjarAmount;
ConVar h_adrenAmount;
ConVar h_defibAmount;
ConVar h_meleeAmount;
ConVar h_pistolAmount;
ConVar h_magnumAmount;
ConVar h_m60Amount;
ConVar h_grenadeLauncherAmount;
ConVar h_iAmmoAmount;
ConVar h_eAmmoAmount;

char weaponList[10][] = {"weapon_spawn",
	"weapon_shotgun_chrome_spawn",
	"weapon_pumpshotgun_spawn",
	"weapon_smg_spawn",
	"weapon_smg_silenced_spawn",
	"weapon_rifle_spawn",
	"weapon_rifle_ak47_spawn",
	"weapon_rifle_desert_spawn",
	"weapon_hunting_rifle_spawn",
	"weapon_sniper_military_spawn"};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if(GetEngineVersion() == Engine_Left4Dead2)
	{
		isl4d2 = true;
		return APLRes_Success;
	}
	else if(GetEngineVersion() == Engine_Left4Dead)
	{
		isl4d2 = false;
		return APLRes_Success;
	}
	strcopy(error, err_max, "Plugin only supports Left 4 Dead and Left 4 Dead 2.");
	return APLRes_SilentFailure;
}

public Plugin myinfo =
{
	name = "[L4D 1+2] Weapon Amount Modifier",
	author = "Eärendil",
	description = "Modify the number of times weapons and heal items can be picked before removing, or deletes them.",
	version = PLUGIN_VERSION,
	url = "",
};

public void OnPluginStart()
{
	CreateConVar("l4d_wam_version", PLUGIN_VERSION, "[L4D1+2] Weapon Amount Modifier Version", FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	h_pluginEnable = CreateConVar("l4d_wam_enabled", "1", "Enable/disable plugin functionality", _, true, 0.0, true, 1.0);
	h_weaponAmount = CreateConVar("l4d_wam_weapon_amount", "9", "Amount of primary weapons per spot", _, true, 0.0, true, 32.0);
	h_pistolAmount = CreateConVar("l4d_wam_pistol_amount", "9", "Amount of pistols per spot", _, true, 0.0, true, 32.0);
	h_medkitAmount = CreateConVar("l4d_wam_medkit_amount", "2", "Amount of first aid kits per spot", _, true, 0.0, true, 20.0);
	h_pillsAmount = CreateConVar("l4d_wam_pain_pills_amount", "2", "Amount of pain pills per spot", _, true, 0.0, true, 20.0);
	h_pipebombAmount = CreateConVar("l4d_wam_pipe_bomb_amount", "1", "Amount of pipe bombs per spot", _, true, 0.0, true, 20.0);
	h_molotovAmount = CreateConVar("l4d_wam_molotov_amount", "1", "Amount of molotovs per spot", _, true, 0.0, true, 20.0);
	if (isl4d2)
	{
		h_magnumAmount = CreateConVar("l4d_wam_pistol_magnum_amount", "9", "Amount of magnum pistols per spot", _, true, 0.0, true, 32.0);
		h_vomitjarAmount = CreateConVar("l4d_wam_vomitjar_amount", "1", "Amount of vomitjars per spot", _, true, 0.0, true, 20.0);
		h_adrenAmount = CreateConVar("l4d_wam_adrenaline_amount", "2", "Amount of adrenaline shots per spot", _, true, 0.0, true, 20.0);
		h_defibAmount = CreateConVar("l4d_wam_defibrillator_amount", "1", "Amount of defibrillators per spot", _, true, 0.0, true, 20.0);
		h_meleeAmount = CreateConVar("l4d_wam_melee_amount", "1", "Amount of melee weapons per spot", _, true, 0.0, true, 20.0);
		h_m60Amount = CreateConVar("l4d_wam_m60_amount", "1", "Amount of m60 rifles per spot", _, true, 0.0, true, 20.0);
		h_grenadeLauncherAmount = CreateConVar("l4d_wam_grenade_launcher_amount", "1", "Amount of grenade launchers per spot", _, true, 0.0, true, 20.0);
		h_iAmmoAmount = CreateConVar("l4d_wam_incendiary_ammo_amount", "1", "Amount of incendiary ammo packs per spot", _, true, 0.0, true, 20.0);
		h_eAmmoAmount = CreateConVar("l4d_wam_explosive_ammo_amount", "1", "Amount of explosive ammo packs per spot", _, true, 0.0, true, 20.0);
	}
	HookEvent("round_end", Event_Round_End, EventHookMode_PostNoCopy);
	HookEvent("player_spawn", Event_Player_Spawn, EventHookMode_PostNoCopy);
	AutoExecConfig (true, "l4d_weapon_amount_modifier");
}

public void OnMapStart()
{
	g_weaponChanged = false;
}

void Event_Round_End(Handle event, const char[] name, bool dontBroadcast)
{
	g_weaponChanged = false;
}

void Event_Player_Spawn(Handle event, const char[] name, bool dontBroadcast)
{
	if (GetConVarBool(h_pluginEnable) && !g_weaponChanged)
	{
		g_weaponChanged = true;
		// I need to create a delay because code is executed before the director spawns the saferoom medkits and weapons
		CreateTimer(0.2, SetItemCount);
	}
}

Action SetItemCount(Handle timer)
{
	for (int i = 0; i < sizeof(weaponList); i++)
	{
		ModifyItemCount(weaponList[i], GetConVarInt(h_weaponAmount));
	}
	ModifyItemCount("weapon_first_aid_kit_spawn", GetConVarInt(h_medkitAmount));
	ModifyItemCount("weapon_pain_pills_spawn", GetConVarInt(h_pillsAmount));
	ModifyItemCount("weapon_molotov_spawn", GetConVarInt(h_molotovAmount));
	ModifyItemCount("weapon_pipe_bomb_spawn", GetConVarInt(h_pipebombAmount));
	ModifyItemCount("weapon_pistol_spawn", GetConVarInt(h_pistolAmount));
	if (isl4d2)
	{
		ModifyItemCount("weapon_vomitjar_spawn", GetConVarInt(h_vomitjarAmount));
		ModifyItemCount("weapon_adrenaline_spawn", GetConVarInt(h_adrenAmount));
		ModifyItemCount("weapon_defibrillator_spawn", GetConVarInt(h_defibAmount));
		ModifyItemCount("weapon_melee_spawn", GetConVarInt(h_meleeAmount));
		ModifyItemCount("weapon_pistol_magnum_spawn", GetConVarInt(h_magnumAmount));
		ModifyItemCount("weapon_upgradepack_explosive_spawn", GetConVarInt(h_eAmmoAmount));
		ModifyItemCount("weapon_upgradepack_incendiary_spawn", GetConVarInt(h_iAmmoAmount));
		ModifyItemCount("weapon_grenade_launcher_spawn", GetConVarInt(h_grenadeLauncherAmount));
		ModifyItemCount("weapon_rifle_m60_spawn", GetConVarInt(h_m60Amount));
	}
}

void ModifyItemCount(const char[] itemName, int countValue)
{
	int i = -1;
	while ((i = FindEntityByClassname(i, itemName)) != -1) 
	{
		if (countValue == 0) AcceptEntityInput(i, "Kill");
		else SetEntProp(i, Prop_Data, "m_itemCount", countValue);
	}  
}