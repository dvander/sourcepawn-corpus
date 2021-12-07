#pragma semicolon 1

#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <morecolors>

#define PLUG_VER	"1.2.0"

public Plugin myinfo =
{
	name = "[TF2] No Taunting After Killing",
	author = "aIM",
	description = "Manages players that taunt after killing somebody.",
	version = PLUG_VER,
	url = ""
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	new String:Game[32];
	GetGameFolderName(Game, sizeof(Game));
	if(!StrEqual(Game, "tf"))
	{
		Format(error, err_max, "[TAK] This plugin only works for Team Fortress 2.");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

///////////// CONVARS /////////////
new Handle:cvarTimeCheck;
new Handle:cvarAdminCheck;
new Handle:cvarEnabled;
new Handle:cvarAdvert;
new Handle:cvarMethod;
new Handle:cvarTauntAdvert;
new Handle:cvarTauntMenuSupport;

//////////// TIMER //////////////
new Handle:unblockTimer[MAXPLAYERS + 1];
new bool:IsMarked[MAXPLAYERS + 1] = false;

new Handle:advertTimer[MAXPLAYERS + 1];

public void OnPluginStart()
{
	CreateConVar("tak_version", PLUG_VER, "Plugin version. Don't touch!", FCVAR_NOTIFY);
	
	cvarEnabled = CreateConVar("tak_enabled", "1", "Enables No Taunting After Killing.", _, true, 0.0, true, 1.0);
	cvarAdminCheck = CreateConVar("tak_admins", "0", "If set to 1, admins are immune to penalties. If set to 0, ignores admins.", _, true, 0.0, true, 1.0);
	cvarTimeCheck = CreateConVar("tak_time", "2.5", "Seconds to block taunting if using method 1 or 2.", _, true, 0.1, true, 7.0);
	cvarAdvert = CreateConVar("tak_advert", "1", "Enables the advert players see when they get on the server.", _, true, 0.0, true, 1.0);
	cvarMethod = CreateConVar("tak_method", "1", "Sets how the plugin manages taunting players (0- Nothing. 1- Block taunt. 2- Slay)", _, true, 0.0, true, 2.0);
	cvarTauntMenuSupport = CreateConVar("tak_tauntmenu_support", "0", "Enables support for blocking taunts through an external taunt menu.", _, true, 0.0, true, 1.0);
	cvarTauntAdvert = CreateConVar("tak_taunt_advert", "1", "Shows players a chat message when they can taunt again.", _, true, 0.0, true, 1.0);
	
	AddCommandListener(OnClientTaunt, "taunt");
	AddCommandListener(OnClientTaunt, "+taunt");
	AddCommandListener(OnClientTaunt_EF, "eureka_teleport");
	
	AddCommandListener(OnClientTauntMenu, "sm_taunt");
	AddCommandListener(OnClientTauntMenu, "sm_taunts");
	AddCommandListener(OnClientTauntMenu, "sm_tauntmenu");
	
	HookEvent("player_death", OnPlayerDeath);
}

public void OnClientPutInServer(client)
{
	if (GetConVarBool(cvarAdvert) && IsValidClient(client))
		advertTimer[client] = CreateTimer(30.0, DoAdvert, client);
}

public Action DoAdvert (Handle timer, any data)
{
	int client = data;

	CPrintToChat(client, "{limegreen}[TAK] {default}Welcome, %N. This server is running {palegreen}No Taunt After Kill v%s by {red}aIM{default}.", client, PLUG_VER);
}

public Action OnPlayerDeath (Handle event, const char[] name, bool dontBroadcast)
{
	new killer = GetClientOfUserId(GetEventInt(event, "attacker"));
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (killer == client) return;
	
	new Method = GetConVarInt(cvarMethod);
	
	if (!GetConVarBool(cvarEnabled))
	{
		return;
	}
	
	if (GetConVarBool(cvarAdminCheck))
	{
		if (CheckCommandAccess(killer, "tak_immune", ADMFLAG_GENERIC))
		{
			return;
		}
	}
	
	if (Method == 0)
	{
		return;
	}
	
	if (CheckCommandAccess(killer, "tak_immune", ADMFLAG_GENERIC, false))
	{
		return;
	}
	
	IsMarked[killer] = true;
	unblockTimer[client] = CreateTimer(GetConVarFloat(cvarTimeCheck), UnblockTaunting, killer, TIMER_REPEAT);
}

public Action OnClientTaunt (int client, const char[] command, int argc)
{
	new Method = GetConVarInt(cvarMethod);
	
	if (IsMarked[client] && IsPlayerAlive(client))
	{
		if (Method == 1 && CheckValidTaunt(client))
		{
			PrintCenterText(client, "You can't taunt after killing somebody!");
			return Plugin_Stop;
		}
		else if (Method == 2 && CheckValidTaunt(client))
		{
			ForcePlayerSuicide(client);
			PrintCenterText(client, "You can't taunt after killing somebody!");
		}
	}
	return Plugin_Continue;
}

public Action OnClientTauntMenu (int client, const char[] command, int argc)
{
	if (GetConVarBool(cvarTauntMenuSupport))
	{
		if (IsMarked[client] && IsPlayerAlive(client))
		{
			CReplyToCommand(client, "{limegreen}[TAK] {default}You can't use the taunt menu now.");
			return Plugin_Stop;
		}
		return Plugin_Continue;
	}
	return Plugin_Continue;
}

public Action OnClientTaunt_EF (int client, const char[] command, int argc)
{
	if (IsMarked[client] && IsPlayerAlive(client))
	{
		return Plugin_Continue;
	}
	return Plugin_Continue;
}

public Action UnblockTaunting (Handle timer, any data)
{
	int client = data;
	
	if (GetConVarBool(cvarTauntAdvert))
		CPrintToChat(client, "{limegreen}[TAK] {default}You can taunt again now, %N.", client);
	
	IsMarked[client] = false;
	return Plugin_Stop;
}

bool:IsValidClient(client) 
{
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) 
        return false; 
     
    return true; 
}

bool CheckValidTaunt(int client)
{
	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	int index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
	
	switch (index)
	{
		case 163, 46, 1145, 594, 42, 159, 433, 863, 1002, 311:
			return false;
		default:
			return true;
	}
	return false;
}