#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION		"1.2"

bool isl4d2, g_bPluginOn, g_bPEnable;

ConVar	g_hPEnable, g_hWeaponAmt, g_hMedAmt, g_hPillAmt, g_hPipeAmt, g_hMoloAmt, g_hJarAmt, g_hAdrAmt, 
		g_hDefAmt, g_hMeleeAmt, g_hPisAmt, g_hMagnumAmt, g_hM60Amt, g_hGLAmt, g_hIncenAmt, g_hExploAmt;


static char weaponList[14][] = {
	"weapon_spawn",
	"weapon_shotgun_chrome_spawn",
	"weapon_pumpshotgun_spawn",
	"weapon_smg_spawn",
	"weapon_smg_silenced_spawn",
	"weapon_smg_mp5_spawn",
	"weapon_rifle_spawn",
	"weapon_rifle_ak47_spawn",
	"weapon_rifle_desert_spawn",
	"weapon_rifle_sg552_spawn",
	"weapon_hunting_rifle_spawn",
	"weapon_sniper_military_spawn",
	"weapon_sniper_scout_spawn",
	"weapon_sniper_awp_spawn"};

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
	url = "https://forums.alliedmods.net/showthread.php?p=2679662",
};

public void OnPluginStart()
{
	CreateConVar("l4d_wam_version", PLUGIN_VERSION, "[L4D1+2] Weapon Amount Modifier Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hPEnable = CreateConVar("l4d_wam_enabled", "1", "1 = Plugin on, 0 = Plugin off", FCVAR_NOTIFY,true, 0.0, true, 1.0);
	g_hWeaponAmt = CreateConVar("l4d_wam_weapon_amount", "9", "Amount of primary weapons per spot", FCVAR_NOTIFY,true, 0.0);
	g_hPisAmt = CreateConVar("l4d_wam_pistol_amount", "9", "Amount of pistols per spot", FCVAR_NOTIFY,true, 0.0);
	g_hMedAmt = CreateConVar("l4d_wam_medkit_amount", "2", "Amount of first aid kits per spot", FCVAR_NOTIFY,true, 0.0);
	g_hPillAmt = CreateConVar("l4d_wam_pain_pills_amount", "2", "Amount of pain pills per spot", FCVAR_NOTIFY,true, 0.0);
	g_hPipeAmt = CreateConVar("l4d_wam_pipe_bomb_amount", "1", "Amount of pipe bombs per spot", FCVAR_NOTIFY,true, 0.0);
	g_hMoloAmt = CreateConVar("l4d_wam_molotov_amount", "1", "Amount of molotovs per spot", FCVAR_NOTIFY,true, 0.0);
	if (isl4d2)
	{
		g_hMagnumAmt = CreateConVar("l4d_wam_pistol_magnum_amount", "9", "Amount of magnum pistols per spot", FCVAR_NOTIFY,true, 0.0);
		g_hJarAmt = CreateConVar("l4d_wam_vomitjar_amount", "1", "Amount of vomitjars per spot", FCVAR_NOTIFY,true, 0.0);
		g_hAdrAmt = CreateConVar("l4d_wam_adrenaline_amount", "2", "Amount of adrenaline shots per spot", FCVAR_NOTIFY,true, 0.0);
		g_hDefAmt = CreateConVar("l4d_wam_defibrillator_amount", "1", "Amount of defibrillators per spot", FCVAR_NOTIFY,true, 0.0);
		g_hMeleeAmt = CreateConVar("l4d_wam_melee_amount", "1", "Amount of melee weapons per spot", FCVAR_NOTIFY,true, 0.0);
		g_hM60Amt = CreateConVar("l4d_wam_m60_amount", "1", "Amount of m60 rifles per spot", FCVAR_NOTIFY,true, 0.0);
		g_hGLAmt = CreateConVar("l4d_wam_grenade_launcher_amount", "1", "Amount of grenade launchers per spot", FCVAR_NOTIFY,true, 0.0);
		g_hIncenAmt = CreateConVar("l4d_wam_incendiary_ammo_amount", "1", "Amount of incendiary ammo packs per spot", FCVAR_NOTIFY,true, 0.0);
		g_hExploAmt = CreateConVar("l4d_wam_explosive_ammo_amount", "1", "Amount of explosive ammo packs per spot", FCVAR_NOTIFY,true, 0.0);
	}
	
	g_hPEnable.AddChangeHook(CVarChange_Enable);
	AutoExecConfig (true, "l4d_weapon_amount_modifier");
}
public void OnConfigsExecuted()
{
	PluginSwitch();
}

public void CVarChange_Enable(Handle convar, const char[] oldValue, const char[] newValue)
{
	PluginSwitch();
}

public Action Event_Round_Start(Event event, const char[] name, bool dontBroadcast)
{
	CreateTimer(0.2, SetItemCount);	// Add a delay after round start to ensure all weapons have been spawned
}

void PluginSwitch()
{
	g_bPEnable = g_hPEnable.BoolValue;
	if (!g_bPluginOn && g_bPEnable)
	{
		g_bPluginOn = true;
		HookEvent("round_start", Event_Round_Start, EventHookMode_PostNoCopy);
		PrintToServer("Hooking Round Start.");
	}
		
	if (g_bPluginOn && !g_bPEnable)
	{
		g_bPluginOn = false;
		UnhookEvent("round_start", Event_Round_Start);
		PrintToServer("Unhooking Round Start.");
	}
}

public Action SetItemCount(Handle timer)
{
	for (int i = 0; i < sizeof(weaponList); i++)
	{
		ModifyItemCount(weaponList[i], GetConVarInt(g_hWeaponAmt));
	}
	ModifyItemCount("weapon_first_aid_kit_spawn", g_hMedAmt.IntValue);
	ModifyItemCount("weapon_pain_pills_spawn", g_hPillAmt.IntValue);
	ModifyItemCount("weapon_molotov_spawn", g_hMoloAmt.IntValue);
	ModifyItemCount("weapon_pipe_bomb_spawn", g_hPipeAmt.IntValue);
	ModifyItemCount("weapon_pistol_spawn", g_hPisAmt.IntValue);
	if (isl4d2)
	{
		ModifyItemCount("weapon_vomitjar_spawn", g_hJarAmt.IntValue);
		ModifyItemCount("weapon_adrenaline_spawn", g_hAdrAmt.IntValue);
		ModifyItemCount("weapon_defibrillator_spawn", g_hDefAmt.IntValue);
		ModifyItemCount("weapon_melee_spawn", g_hMeleeAmt.IntValue);
		ModifyItemCount("weapon_pistol_magnum_spawn", g_hMagnumAmt.IntValue);
		ModifyItemCount("weapon_upgradepack_explosive_spawn", g_hExploAmt.IntValue);
		ModifyItemCount("weapon_upgradepack_incendiary_spawn", g_hIncenAmt.IntValue);
		ModifyItemCount("weapon_grenade_launcher_spawn", g_hGLAmt.IntValue);
		ModifyItemCount("weapon_rifle_m60_spawn", g_hM60Amt.IntValue);
	}
}

void ModifyItemCount(const char[] itemName, int countValue)
{
	int i = -1;
	while ((i = FindEntityByClassname(i, itemName)) != -1) 
	{
		if (countValue == 0)
			AcceptEntityInput(i, "Kill");
			
		else
			SetEntProp(i, Prop_Data, "m_itemCount", countValue);
	}  
}