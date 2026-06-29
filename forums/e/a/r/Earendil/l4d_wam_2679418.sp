/*============================================================================================
							L4D & L4D2 Weapon Amount Modifier
----------------------------------------------------------------------------------------------
*	Author	:	Eärendil
*	Descrp	:	Modify the number of times weapons and heal items can be picked before removing, or deletes them.
*	Version	:	1.0
*	Link	:	https://forums.alliedmods.net/showthread.php?t=332272
----------------------------------------------------------------------------------------------*/
#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION		"1.4"

bool isl4d2, g_bPluginOn, g_bPEnable, g_bBlockChange;

ConVar	g_hPEnable, g_hWeaponAmt, g_hMedAmt, g_hPillAmt, g_hPipeAmt, g_hMoloAmt, g_hJarAmt, g_hAdrAmt, 
		g_hDefAmt, g_hMeleeAmt, g_hPisAmt, g_hMagnumAmt, g_hM60Amt, g_hGLAmt, g_hIncenAmt, g_hExploAmt, g_hStartOnly;
		
int		g_iArAmount[28];

static char sArWeaponList[28][] = {
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
	"weapon_sniper_awp_spawn",
	"weapon_first_aid_kit_spawn",
	"weapon_pain_pills_spawn",
	"weapon_molotov_spawn",
	"weapon_pipe_bomb_spawn",
	"weapon_pistol_spawn",
	"weapon_vomitjar_spawn",
	"weapon_adrenaline_spawn",
	"weapon_defibrillator_spawn",
	"weapon_melee_spawn",
	"weapon_pistol_magnum_spawn",
	"weapon_upgradepack_explosive_spawn",
	"weapon_upgradepack_incendiary_spawn",
	"weapon_grenade_launcher_spawn",
	"weapon_rifle_m60_spawn"};

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
	name = "[L4D & L4D2] Weapon Amount Modifier",
	author = "Eärendil",
	description = "Modify the number of times weapons and heal items can be picked before removing, or deletes them.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2679662",
};

public void OnPluginStart()
{
	CreateConVar("l4d_wam_version", PLUGIN_VERSION, "[L4D1+2] Weapon Amount Modifier Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hPEnable = CreateConVar("l4d_wam_enabled", "1", "1 = Plugin on, 0 = Plugin off", FCVAR_NOTIFY,true, 0.0, true, 1.0);
	g_hWeaponAmt = CreateConVar("l4d_wam_weapon_amount", "9", "Amount of primary weapons per spot", FCVAR_NOTIFY, true, 0.0);
	g_hPisAmt = CreateConVar("l4d_wam_pistol_amount", "9", "Amount of pistols per spot", FCVAR_NOTIFY, true, 0.0);
	g_hMedAmt = CreateConVar("l4d_wam_medkit_amount", "2", "Amount of first aid kits per spot", FCVAR_NOTIFY, true, 0.0);
	g_hPillAmt = CreateConVar("l4d_wam_pain_pills_amount", "2", "Amount of pain pills per spot", FCVAR_NOTIFY, true, 0.0);
	g_hPipeAmt = CreateConVar("l4d_wam_pipe_bomb_amount", "1", "Amount of pipe bombs per spot", FCVAR_NOTIFY, true, 0.0);
	g_hMoloAmt = CreateConVar("l4d_wam_molotov_amount", "1", "Amount of molotovs per spot", FCVAR_NOTIFY, true, 0.0);
	g_hStartOnly = CreateConVar("l4d_wam_roundstart_only", "1", "Modify only weapon amounts when round starts.\nThis prevents modifying weapon amount created by other plugins in midgame.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	if (isl4d2)
	{
		g_hMagnumAmt = CreateConVar("l4d_wam_pistol_magnum_amount", "9", "Amount of magnum pistols per spot", FCVAR_NOTIFY, true, 0.0);
		g_hJarAmt = CreateConVar("l4d_wam_vomitjar_amount", "1", "Amount of vomitjars per spot", FCVAR_NOTIFY, true, 0.0);
		g_hAdrAmt = CreateConVar("l4d_wam_adrenaline_amount", "2", "Amount of adrenaline shots per spot", FCVAR_NOTIFY, true, 0.0);
		g_hDefAmt = CreateConVar("l4d_wam_defibrillator_amount", "1", "Amount of defibrillators per spot", FCVAR_NOTIFY, true, 0.0);
		g_hMeleeAmt = CreateConVar("l4d_wam_melee_amount", "1", "Amount of melee weapons per spot", FCVAR_NOTIFY, true, 0.0);
		g_hM60Amt = CreateConVar("l4d_wam_m60_amount", "1", "Amount of m60 rifles per spot", FCVAR_NOTIFY, true, 0.0);
		g_hGLAmt = CreateConVar("l4d_wam_grenade_launcher_amount", "1", "Amount of grenade launchers per spot", FCVAR_NOTIFY, true, 0.0);
		g_hIncenAmt = CreateConVar("l4d_wam_incendiary_ammo_amount", "1", "Amount of incendiary ammo packs per spot", FCVAR_NOTIFY, true, 0.0);
		g_hExploAmt = CreateConVar("l4d_wam_explosive_ammo_amount", "1", "Amount of explosive ammo packs per spot", FCVAR_NOTIFY, true, 0.0);
	}
	
	g_hPEnable.AddChangeHook(CVarChange_Enable);
	g_hWeaponAmt.AddChangeHook(CVarChange_Amounts);
	g_hPisAmt.AddChangeHook(CVarChange_Amounts);
	g_hMedAmt.AddChangeHook(CVarChange_Amounts);
	g_hPillAmt.AddChangeHook(CVarChange_Amounts);
	g_hPipeAmt.AddChangeHook(CVarChange_Amounts);
	g_hMoloAmt.AddChangeHook(CVarChange_Amounts);
	if (isl4d2)
	{
		g_hMagnumAmt.AddChangeHook(CVarChange_Amounts);
		g_hJarAmt.AddChangeHook(CVarChange_Amounts);
		g_hAdrAmt.AddChangeHook(CVarChange_Amounts);
		g_hDefAmt.AddChangeHook(CVarChange_Amounts);
		g_hMeleeAmt.AddChangeHook(CVarChange_Amounts);
		g_hM60Amt.AddChangeHook(CVarChange_Amounts);
		g_hGLAmt.AddChangeHook(CVarChange_Amounts);
		g_hIncenAmt.AddChangeHook(CVarChange_Amounts);
		g_hExploAmt.AddChangeHook(CVarChange_Amounts);
	}

	AutoExecConfig (true, "l4d_weapon_amount_modifier");
}

public void OnConfigsExecuted()
{
	PluginSwitch();
	GetAmounts();
}

public void CVarChange_Enable(Handle convar, const char[] oldValue, const char[] newValue)
{
	PluginSwitch();
}

public void CVarChange_Amounts(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetAmounts();
}

void PluginSwitch()
{
	g_bPEnable = g_hPEnable.BoolValue;
	if (!g_bPluginOn && g_bPEnable)
	{
		g_bPluginOn = true;
		HookEvent("round_end", Event_Round_End, EventHookMode_PostNoCopy);
		HookEvent("round_start", Event_Round_Start, EventHookMode_PostNoCopy);
	}
	if (g_bPluginOn && !g_bPEnable)
	{
		g_bPluginOn = false;
		UnhookEvent("round_end", Event_Round_End);
		UnhookEvent("round_start", Event_Round_Start);
	}
}

void GetAmounts()
{
	for (int i = 0; i < 14; i++)
		g_iArAmount[i] = g_hWeaponAmt.IntValue;
	
	g_iArAmount[14] = g_hMedAmt.IntValue;
	g_iArAmount[15] = g_hPillAmt.IntValue;
	g_iArAmount[16] = g_hMoloAmt.IntValue;
	g_iArAmount[17] = g_hPipeAmt.IntValue;
	g_iArAmount[18] = g_hPisAmt.IntValue;
	if (isl4d2)
	{
		g_iArAmount[19] = g_hJarAmt.IntValue;
		g_iArAmount[20] = g_hAdrAmt.IntValue;
		g_iArAmount[21] = g_hDefAmt.IntValue;
		g_iArAmount[22] = g_hMeleeAmt.IntValue;
		g_iArAmount[23] = g_hMagnumAmt.IntValue;
		g_iArAmount[24] = g_hExploAmt.IntValue;
		g_iArAmount[25] = g_hIncenAmt.IntValue;
		g_iArAmount[26] = g_hGLAmt.IntValue;
		g_iArAmount[27] = g_hM60Amt.IntValue;
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (!g_bPluginOn)
		return;
	
	if (g_bBlockChange && g_hStartOnly.BoolValue)
		return;

	if(StrContains(classname, "weapon_", false) == -1|| StrContains(classname, "_spawn", false) == -1)	// Ignore any entity that is not a weapon_****_spawn
		return;

	int i;
	for (i = 0; i < sizeof(sArWeaponList); i++)
	{
		if (StrEqual(classname, sArWeaponList[i], false))
			break;
	}
	if (i < sizeof(sArWeaponList))
		ModifyItemCount(entity, g_iArAmount[i]);
	
}

// Plugin works perfectly except when servers starts from empty state, with this we force server to modify all weapon amounts when a player connects in an empty server
// Check when first player joins server from empty state
public void OnClientConnected()
{
	if (GetClientCount() == 0)
		CreateTimer(5.0, FirstLoad_Timer, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Event_Round_End(Event event, const char[] name, bool dontBroadcast)
{
	g_bBlockChange = false;
}

public Action Event_Round_Start(Event event, const char[] name, bool dontBroadcast)
{
	CreateTimer(1.0, CheckLeft_Timer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public void OnMapEnd()
{
	g_bBlockChange = false;	
}

void ModifyItemCount(int entity, int countValue)
{
	if (countValue == 0)
	{
		SetVariantString("OnUser1 !self:Kill::0.01:0");	// Kill entity with a delay or it will crash the server
		AcceptEntityInput(entity, "AddOutput");
		AcceptEntityInput(entity, "FireUser1");
	}		
	else
	{
		char sBuffer[64];
		Format(sBuffer, sizeof(sBuffer), "OnUser1 !self:AddOutput:count %i:0.01:0", countValue);	// Using entity I/O allows to call outputs with delay of 0.01s and avoid timers :D
		SetVariantString(sBuffer);
		AcceptEntityInput(entity, "Addoutput");
		AcceptEntityInput(entity, "FireUser1");
	}
}

// Loop through all entities and find weapon_spawn to change them (probably there is a better method to do this, but this one works and is done only once)
public Action FirstLoad_Timer(Handle timer)
{
	for (int i = 0; i < 2048; i++)
	{
		if (!IsValidEntity(i))
			continue;

		char sClassName[64];
		GetEntityClassname(i, sClassName, sizeof(sClassName));
		if(StrContains(sClassName, "weapon_", false) == -1|| StrContains(sClassName, "_spawn", false) == -1)
			continue;

		int j;
		for (j = 0; j < sizeof(sArWeaponList); j++)
		{
			if(StrEqual(sClassName, sArWeaponList[j], false))
				break;
		}
		if (j < sizeof(sArWeaponList))
			ModifyItemCount(i, g_iArAmount[j]);
	}
}

// Infected bots, MI5: https://forums.alliedmods.net/showthread.php?p=893938
// Allow weapon modifications until a player leaves start area
public Action CheckLeft_Timer(Handle timer)
{
	if (g_bBlockChange)
		return Plugin_Stop;
		
	int ent = -1, maxents = GetMaxEntities();
	for (int i = MaxClients+1; i <= maxents; i++)
	{
		if (IsValidEntity(i))
		{
			char netclass[64];
			GetEntityNetClass(i, netclass, sizeof(netclass));
			
			if (StrEqual(netclass, "CTerrorPlayerResource"))
			{
				ent = i;
				break;
			}
		}
	}
	if (ent > -1)
	{
		if (GetEntProp(ent, Prop_Send, "m_hasAnySurvivorLeftSafeArea"))
			g_bBlockChange = true;
	}
	return Plugin_Continue;
}

/*============================================================================================
									Changelog
----------------------------------------------------------------------------------------------
* 1.0
	- First release.
   
* 1.0.1
    - Fixed plugin version CVar "l4d_wam_version".

* 1.1
	- Rebuilded code with new syntax, special thanks to Shadowysn for help and tips.
	- Pistols and magnum pistols can have their amount modified separately from all other weapons.
	- Throwables can be managed individually by their respective CVar instead of using a common CVar.
	- Added M60 and grenade launcher CVars to manage their amount.
	- Added explosive and incendiary ammo pack CVar to manage their amount.
	
* 1.2
	- Counter Strike weapons included.
	- Cleaned code.
	- Plugin now only hooks "round_start", event is unhooked when "l4d_wam_enabled" "0".
	
* 1.3
	- Fixed any potential fail modifying weapon amounts.
	- Plugin now can modify any weapon_spawn created anytime in the game (controlled by CVar).
	- New ConVar: l4d_wam_roundstart_only
	- Change of game tags in plugin title. 

* 1.4
	- Fixed plugin failing to modify amount after map transition.
==============================================================================================*/