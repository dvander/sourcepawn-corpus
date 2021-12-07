#include <multicolors>
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

#define PLUGIN_AUTHOR 	"Arkarr"
#define PLUGIN_VERSION 	"1.00"
#define PLUGIN_TAG		"{green}[Shot Administration]{default}"
//Plugin config
#define NBR_MODES		7

char modes[NBR_MODES + 1][45] =  { "Normal", "Shooter", "Bullet Reflector", "Victim", "Bad Aim", "No Damage", "Suicider", "Uber Suicider" };

enum modesIndex
{
	NORMAL = 0, 
	SHOOTER, 
	BULLET_REFLECTOR, 
	VICTIM, 
	BAD_AIM, 
	NO_DMG, 
	SUICIDER, 
	U_SUICIDER
};
//Plugin global variables
int PlayerMode[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "[CSS/CSGO] Shot Administration", 
	author = PLUGIN_AUTHOR, 
	description = "Remake of https://forums.alliedmods.net/showthread.php?p=577578", 
	version = PLUGIN_VERSION, 
	url = "http://www.sourcemod.net"
};

public void OnPluginStart()
{
	EngineVersion g_Game = GetEngineVersion();
	if (g_Game != Engine_CSGO && g_Game != Engine_CSS)
		SetFailState("This plugin is for CSGO/CSS only.");
	
	RegAdminCmd("sm_sadministration", CMD_AdminsitrateShot, ADMFLAG_CHEATS, "Set the shot administration mode on a player.");
	RegAdminCmd("sm_sa", CMD_AdminsitrateShot, ADMFLAG_CHEATS, "Set the shot administration mode on a player.");
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (PlayerMode[attacker] == _:NORMAL && PlayerMode[victim] == _:NORMAL)
		return Plugin_Continue;
	
	if (PlayerMode[attacker] == _:NO_DMG)
		damage = 0.0;
	
	if (PlayerMode[attacker] == _:SHOOTER)
		damagetype = CS_DMG_HEADSHOT;
	
	if (PlayerMode[victim] == _:VICTIM)
		damagetype = CS_DMG_HEADSHOT;
	
	if (PlayerMode[attacker] == _:BAD_AIM)
		damagetype = DMG_BULLET;
	
	if (PlayerMode[victim] == _:BULLET_REFLECTOR && IsValidClient(attacker))
		SlapPlayer(attacker, RoundToFloor(damage), false);
	
	if (PlayerMode[attacker] == _:SUICIDER)
		SlapPlayer(attacker, RoundToFloor(damage), false);
	
	if (PlayerMode[attacker] == _:U_SUICIDER)
		SlapPlayer(attacker, RoundToFloor(damage * 2.0), false);
	
	return Plugin_Changed;
}

public Action CMD_AdminsitrateShot(int client, int args)
{
	if (args == 0)
	{
		DisplayPlayerMenu(client);
		
		return Plugin_Handled;
	}
	else if (args == 1)
	{
		CPrintToChat(client, "%s Usage : sm_sadministration", PLUGIN_TAG);
		CPrintToChat(client, "%s OR", PLUGIN_TAG);
		CPrintToChat(client, "%s Usage : sm_sadministration [PLAYER] [MODE]", PLUGIN_TAG);
		
		return Plugin_Handled;
	}
	
	char arg1[45];
	char arg2[45];
	
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	if ((target_count = ProcessTargetString(
				arg1, 
				client, 
				target_list, 
				MAXPLAYERS, 
				COMMAND_FILTER_CONNECTED, 
				target_name, 
				sizeof(target_name), 
				tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
	}
	
	for (new i = 0; i < target_count; i++)
	SetMode(target_list[i], StringToInt(arg2));
	
	CPrintToChat(client, "%s Sucessfully set mode %s on %i players !", PLUGIN_TAG, arg2, target_count);
	
	return Plugin_Handled;
}

public void DisplayPlayerMenu(int client)
{
	char playerName[MAX_NAME_LENGTH];
	char menuItem[MAX_NAME_LENGTH + 30];
	Handle menu = CreateMenu(MenuHandler_ChangePlayerMode);
	for (int z = 0; z < MaxClients; z++)
	{
		if (!IsValidClient(z))
			continue;
		
		GetClientName(z, playerName, sizeof(playerName));
		Format(menuItem, sizeof(menuItem), "%s - %s", playerName, modes[PlayerMode[z]]);
		IntToString(GetClientUserId(z), playerName, sizeof(playerName));
		AddMenuItem(menu, playerName, menuItem);
	}
	DisplayMenu(menu, client, 30);
}

public MenuHandler_ChangePlayerMode(Handle menu, MenuAction menuAction, int client, int itemIndex)
{
	if (menuAction == MenuAction_Select)
	{
		char infoBuf[25];
		GetMenuItem(menu, itemIndex, infoBuf, sizeof(infoBuf));
		
		int target = GetClientOfUserId(StringToInt(infoBuf));
		if (IsValidClient(target))
		{
			PlayerMode[target]++;
			if (PlayerMode[target] > NBR_MODES)
				PlayerMode[target] = 0;
		}
		else
		{
			CPrintToChat(client, "%s ERROR: This player is disconnected.", PLUGIN_TAG);
		}
		
		DisplayPlayerMenu(client);
	}
}

public void SetMode(int client, int modeID)
{
	PlayerMode[client] = modeID;
}

stock bool IsValidClient(iClient, bool bReplay = true)
{
	if (iClient <= 0 || iClient > MaxClients)
		return false;
	if (!IsClientInGame(iClient))
		return false;
	if (bReplay && (IsClientSourceTV(iClient) || IsClientReplay(iClient)))
		return false;
	
	return true;
} 