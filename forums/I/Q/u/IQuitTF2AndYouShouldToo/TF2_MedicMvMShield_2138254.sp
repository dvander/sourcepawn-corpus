#include <sdktools>
#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#undef REQUIRE_PLUGIN
#tryinclude <updater>

#pragma semicolon 1

#define PLUGIN_VERSION "1.1"
#define UPDATE_URL	"http://abrandnewday.homenet.org/medicshield/raw/default/Updater.txt"

new Handle:g_hEnableUpdater = INVALID_HANDLE;

new g_delay[MAXPLAYERS+1];
new g_mdlBigShield;

public Plugin:myinfo = 
{
	name 			= "Medic's Anti-Projectile Shield",
	author 			= "abrandnewday",
	description 	= "Allows the Medic to use the new shield from MvM",
	version 		= PLUGIN_VERSION,
	url 			= "https://forums.alliedmods.net/member.php?u=165383"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	new String:Game[32];
	GetGameFolderName(Game, sizeof(Game));
	if(!StrEqual(Game, "tf") && !StrEqual(Game, "tf_beta"))
	{
		Format(error, err_max, "This plugin only works for TF2 or TF2 Beta.");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public OnPluginStart()
{
	g_hEnableUpdater = CreateConVar("sm_medicshield_auto_update", "1", "Enables automatic plugin updating (has no effect if Updater is not installed)");
	
	RegConsoleCmd("sm_shield", Command_Shield, "Turns on the Medic's shield effect from MvM. Usage: sm_shield");
	RegConsoleCmd("sm_shield2", Command_Shield2, "Turns on the Medic's advanced shield effect from MvM. Usage: sm_shield2");
}

// Updater stuff (Credit to Dr. McKay, as I took this setup from his plugins)
public OnAllPluginsLoaded()
{
	new Handle:convar;
	if(LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
		new String:newVersion[10];
		Format(newVersion, sizeof(newVersion), "%sA", PLUGIN_VERSION);
		convar = CreateConVar("sm_medicshield_version", newVersion, "Medic's Anti-Projectile Shield Version", FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_CHEAT);
	}
	else
	{
		convar = CreateConVar("sm_medicshield_version", PLUGIN_VERSION, "Medic's Anti-Projectile Shield Version", FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_CHEAT);	
	}
	HookConVarChange(convar, Callback_VersionConVarChanged);
}

public Callback_VersionConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	ResetConVar(convar);
}

public Action:Updater_OnPluginDownloading()
{
	if(!GetConVarBool(g_hEnableUpdater))
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public OnLibraryAdded(const String:name[])
{
	if(StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public Updater_OnPluginUpdated()
{
	ReloadPlugin();
}

public OnMapStart()
{
	g_mdlBigShield = PrecacheModel("models/props_mvm/mvm_player_shield2.mdl");
}

public Action:Command_Shield(client, args)
{
	if (g_delay[client] > 0)
	{
		PrintToChat(client, "[SM] Your shield is recharging and will be ready in %i seconds.", g_delay[client]);
		return Plugin_Handled;
	}

	if (IsValidClient(client) && IsPlayerAlive(client) && TF2_GetPlayerClass(client) == TFClass_Medic)
	{
		new shield = CreateEntityByName("entity_medigun_shield");
		if(shield != -1)
		{
			DispatchSpawn(shield);
			SetEntPropEnt(shield, Prop_Send, "m_hOwnerEntity", client);  
			SetEntProp(shield, Prop_Send, "m_iTeamNum", GetClientTeam(client));
			if (GetClientTeam(client) == _:TFTeam_Red) DispatchKeyValue(shield, "skin", "0");
			else if (GetClientTeam(client) == _:TFTeam_Blue) DispatchKeyValue(shield, "skin", "1");
			Delay(client);
			return Plugin_Handled;
		}
	}
	return Plugin_Handled;
}

public Action:Command_Shield2(client, args)
{
	if (g_delay[client] > 0)
	{
		PrintToChat(client, "[SM] Your shield is recharging and will be ready in %i seconds.", g_delay[client]);
		return Plugin_Handled;
	}

	if (IsValidClient(client) && IsPlayerAlive(client) && TF2_GetPlayerClass(client) == TFClass_Medic)
	{
		new shield = CreateEntityByName("entity_medigun_shield");
		if(shield != -1)
		{
			DispatchSpawn(shield);
			SetEntProp(shield, Prop_Send, "m_nModelIndex", g_mdlBigShield);
			SetEntPropEnt(shield, Prop_Send, "m_hOwnerEntity", client);
			SetEntProp(shield, Prop_Send, "m_iTeamNum", GetClientTeam(client));
			if (GetClientTeam(client) == _:TFTeam_Red) DispatchKeyValue(shield, "skin", "0");
			else if (GetClientTeam(client) == _:TFTeam_Blue) DispatchKeyValue(shield, "skin", "1");
			Delay(client);
			return Plugin_Handled;
		}
	}
	return Plugin_Handled;
} 

public Delay(client)
{
	g_delay[client] = 60;
	CreateTimer(1.0, Timer_Delay, client, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_Delay(Handle:timer, any:client)
{
	g_delay[client]--;
	if (g_delay[client])
	{
		CreateTimer(1.0, Timer_Delay, client, TIMER_FLAG_NO_MAPCHANGE);
	}

	return Plugin_Handled;
}

stock bool:IsValidClient(client, bool:replay = true)
{
	if(client <= 0 || client > MaxClients || !IsClientInGame(client)) return false;
	if(replay && (IsClientSourceTV(client) || IsClientReplay(client))) return false;
	return true;
}