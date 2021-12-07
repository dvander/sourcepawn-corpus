#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION		"1.0.1"

bool g_weaponChanged		= false;
bool isl4d2;

//ConVar Handles
ConVar h_pluginEnable;
ConVar h_weaponAmount;
ConVar h_medkitAmount;
ConVar h_pillsAmount;
ConVar h_throwableAmount;
ConVar h_adrenAmount;
ConVar h_defibAmount;
ConVar h_meleeAmount;

/*
//ConVar Variables
static bool g_pluginEnable; // static prevents value from being overridden when defined again.
static int g_weaponAmount; // but i've only ever seen this happen in a function, not outside here.
static int g_medkitAmount; // if plugin reloads for example, the variables will get overridden.
static int g_pillsAmount; // In my experience, giving outside variables 'static' didn't raise a problem.
static int g_throwableAmount; // but still, it's up to your choice whether you want to or not.
static int g_adrenAmount;
static int g_defibAmount;
static int g_meleeAmount;
*/ // < This allows you to comment out multiple lines like this:
/* Why do I not exist
within the realm of the 
compiled plugin? */
// But you can't use it inside lines that have also been /**/'d

char weaponList[12][] = {"weapon_spawn",
	"weapon_pistol_spawn",
	"weapon_pistol_magnum_spawn",
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
	name = "Weapon Amount Modifier",
	author = "Eärendil",
	description = "Modify the number of times weapons and heal items can be picked before removing.",
	version = PLUGIN_VERSION,
	url = "",
}

// public is only needed for functions like OnEntityCreated, OnPluginStart, etc.
// If it's a new function like ThisCustomFunction, it does not need public at all.
public void OnPluginStart()
{
	CreateConVar("l4d_wam_version", PLUGIN_VERSION, "L4D Weapon Amount Modifier Version", FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	h_pluginEnable = CreateConVar("l4d_wam_enabled", "1", "Enable/disable plugin functionality", _, true, 0.0, true, 1.0);
	h_weaponAmount = CreateConVar("l4d_wam_weapon_count", "9", "Number of weapons per spot", _, true, 0.0, true, 32.0);
	h_medkitAmount = CreateConVar("l4d_wam_medkit_count", "2", "Number of medkits per spot", _, true, 0.0, true, 20.0);
	h_pillsAmount = CreateConVar("l4d_wam_pain_pills_count", "2", "Number of pain pills per spot", _, true, 0.0, true, 20.0);
	h_throwableAmount = CreateConVar("l4d_wam_throwable_count", "1", "Number of throwables per spot", _, true, 0.0, true, 20.0);
	if (isl4d2)
	{
		h_adrenAmount = CreateConVar("l4d_wam_adrenaline_count", "2", "Number of adrenaline shots per spot", _, true, 0.0, true, 20.0);
		h_defibAmount = CreateConVar("l4d_wam_defibrillator_count", "1", "Number of defibrillators per spot", _, true, 0.0, true, 20.0);
		h_meleeAmount = CreateConVar("l4d_wam_melee_count", "1", "Number of melee weapons per spot", _, true, 0.0, true, 20.0);
	}
	HookEvent("round_end", Event_Round_End);
	HookEvent("player_spawn", Event_Player_Spawn);
	/*HookConVarChange(h_pluginEnable, OnCvarChange); // I don't think these are needed, we can just directly get the values
	HookConVarChange(h_weaponAmount, OnCvarChange); // when they're needed. Check out the SetItemCount function for more details.
	HookConVarChange(h_medkitAmount, OnCvarChange);
	HookConVarChange(h_pillsAmount, OnCvarChange);
	HookConVarChange(h_throwableAmount, OnCvarChange);
	if (isl4d2)
	{
		HookConVarChange(h_adrenAmount, OnCvarChange);
		HookConVarChange(h_defibAmount, OnCvarChange);
		HookConVarChange(h_meleeAmount, OnCvarChange);
	}*/
	AutoExecConfig (true, "l4d_weapon_amount_modifier");
	//UpdateCVars();
}

/*void OnCvarChange(ConVar conVar, char[] oldValue, char[] newValue)
{
	UpdateCVars();
}

public void OnConfigsExecuted()
{
	UpdateCVars();
}*/

/*void UpdateCVars()
{
	g_pluginEnable = GetConVarBool(h_pluginEnable);
	g_pluginEnable = GetConVarBool(h_pluginEnable);
	g_weaponAmount = GetConVarInt(h_weaponAmount);
	g_medkitAmount = GetConVarInt(h_medkitAmount);
	g_pillsAmount = GetConVarInt(h_pillsAmount);
	g_throwableAmount = GetConVarInt(h_throwableAmount);
	if (isl4d2)
	{
		g_adrenAmount = GetConVarInt(h_adrenAmount);
		g_defibAmount = GetConVarInt(h_defibAmount);
		g_meleeAmount = GetConVarInt(h_meleeAmount);
	}
}*/

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
	ModifyItemCount("weapon_first_aid_kit_spawn", GetConVarInt(h_medkitAmount)); // We can just directly get the value from cvar
	ModifyItemCount("weapon_pain_pills_spawn", GetConVarInt(h_pillsAmount)); // as opposed to using a global variable that has to be updated
	int throwable_amount = GetConVarInt(h_throwableAmount); // every time the cvar changes.
	ModifyItemCount("weapon_molotov_spawn", throwable_amount);
	ModifyItemCount("weapon_pipe_bomb_spawn", throwable_amount);
	if (isl4d2)
	{
		ModifyItemCount("weapon_vomitjar_spawn", throwable_amount);
		ModifyItemCount("weapon_adrenaline_spawn", GetConVarInt(h_adrenAmount));
		ModifyItemCount("weapon_defibrillator_spawn", GetConVarInt(h_defibAmount));
		ModifyItemCount("weapon_melee_spawn", GetConVarInt(h_meleeAmount));
	}
	g_weaponChanged = true;
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