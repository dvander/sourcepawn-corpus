#define PLUGIN_AUTHOR "skyler"
#define PLUGIN_VERSION "1.45"
#define PREFIX "  \x0C[\x0FSkylerJailAddons\x0C] \x09"
#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <smlib>
#include <sdkhooks>
#include <skyler>
#include <morecolors>
#include <hl_gangs>
bool isbox = false;
bool nospam[MAXPLAYERS + 1] = false;
ConVar g_SetTimeMute;
ConVar g_SetTimeCooldown;
public Plugin myinfo = 
{
	name = "skyler", 
	author = PLUGIN_AUTHOR, 
	description = "nice and usefull function's for your jailbreak server", 
	version = PLUGIN_VERSION, 
	url = "https://forums.alliedmods.net/member.php?u=283190"
};

public OnPluginStart()
{
	g_SetTimeMute = CreateConVar("sm_setmutetime", "30.0", "Set the mute timer on round start");
	g_SetTimeCooldown = CreateConVar("sm_setmedic7time", "5.0", "Set Cooldown for the /medic command");
	AutoExecConfig(true, "SkylerJailAddons", "sourcemod");
	
	RegConsoleCmd("sm_givelr", cmd_givelr, "");
	RegConsoleCmd("sm_box", cmd_box, "");
	RegConsoleCmd("sm_pvp", cmd_box, "");
	RegConsoleCmd("sm_medic", cmd_medic, "");
	RegConsoleCmd("sm_deagle", cmd_deagle, "");
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("round_start", Event_RoundStart);
}
public Action cmd_medic(int client, args)
{
	int hp;
	char name[512];
	hp = GetClientHealth(client);
	GetClientName(client, name, sizeof(name));
	if (IsPlayerAlive(client) && GetClientTeam(client) == CS_TEAM_T)
	{
		if (hp == 100)
		{
			PrintToChat(client, "%s you cant call a medic because you have \x02100 HP!", PREFIX);
			return Plugin_Handled;
		}
		if (nospam[client])
		{
			PrintToChat(client, "%s you cant call a medic because you still have \x02%d \x09cooldown!", PREFIX, g_SetTimeCooldown.IntValue);
			return Plugin_Handled;
		}
		if (!nospam[client] && hp < 100 && IsValidClient(client))
		{
			nospam[client] = true;
			PrintToChatAll("%s \x03%s\x04 have \x02%d HP\x04 and he need a \x04medic!", PREFIX, name, hp);
			CreateTimer(g_SetTimeCooldown.FloatValue, medicHandler, client);
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}
public Action medicHandler(Handle timer, any client)
{
	if (nospam[client])
	{
		nospam[client] = false;
		KillTimer(timer); //pervent memory leak
	}
}
public Action cmd_deagle(int client, args)
{
	if (IsClientInGame(client) && GetClientTeam(client) == CS_TEAM_T && !CheckCommandAccess(client, "sm_admin", ADMFLAG_GENERIC))
	{
		PrintToChat(client, "%s You are not in the guards team you cant active this command!", PREFIX);
		return Plugin_Handled;
	}
	if (IsClientInGame(client) && GetClientTeam(client) == CS_TEAM_CT && !IsPlayerAlive(client) && !CheckCommandAccess(client, "sm_admin", ADMFLAG_GENERIC))
	{
		PrintToChat(client, "%s You are need to be alive to active this command!", PREFIX);
		return Plugin_Handled;
	}
	if (IsClientInGame(client) && GetClientTeam(client) == CS_TEAM_CT || IsClientInGame(client) && GetClientTeam(client) == CS_TEAM_T && CheckCommandAccess(client, "sm_admin", ADMFLAG_GENERIC))
	{
		PrintToChatAll("%s All terrorist alive got a empty deagle! Have Fun", PREFIX);
		for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && GetClientTeam(i) == CS_TEAM_T && IsPlayerAlive(i))
		{
			RemoveAllWeapons(i);
			Client_GiveWeaponAndAmmo(i, "weapon_deagle", _, 0, _, 0);
			GivePlayerItem(i, "weapon_knife");
		}
	}
	return Plugin_Continue;
}
public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	ServerCommand("mp_forcecamera 1");
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == CS_TEAM_T && !CheckCommandAccess(i, "sm_admin", ADMFLAG_GENERIC))
		{
			SetClientListeningFlags(i, VOICE_MUTED);
			
			CreateTimer(g_SetTimeMute.FloatValue, MuteHandler);
		}
	}
	for (int i = 1; i <= 1; i++)
	{
		char timeinchar[4096];
		FloatToString(g_SetTimeMute.FloatValue, timeinchar, sizeof(timeinchar));
		PrintToChatAll("%s The terrorists cant speak until passes %s seconds", PREFIX, timeinchar);
	}
}
public Action MuteHandler(Handle timer, any client)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			CPrintToChat(i, "%s The terrorists can speak now quietly", PREFIX);
		}
		if (IsClientInGame(i) && GetClientTeam(i) == CS_TEAM_T && !CheckCommandAccess(i, "sm_admin", ADMFLAG_GENERIC))
		{
			SetClientListeningFlags(i, VOICE_NORMAL);
		}
	}
}
public Action Event_PlayerDeath(Event event, char[] name, bool dontBroadcast)
{
	//int client = GetClientOfUserId(event.GetInt("userid"));
	//int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int talive;
	talive = GetAlivePlayerAmountTeamT();
	if (talive == 1) //lastrequest time
	{
		ServerCommand("mp_teammates_are_enemies 0");
		for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i))
			PrintToChat(i, "%s the friendly fire turned off automatically!", PREFIX);
		
	}
}
public Action cmd_box(int client, args)
{
	if (GetClientTeam(client) == CS_TEAM_CT || CheckCommandAccess(client, "sm_admin", ADMFLAG_GENERIC))
	{
		Menu box = CreateMenu(BoxMenuHandler);
		box.SetTitle("[Box] menu");
		if (!isbox)
			box.AddItem("box", "Enable Friendly Fire");
		else
			box.AddItem("box", "Enable Friendly Fire", ITEMDRAW_DISABLED);
		if (isbox)
			box.AddItem("box", "Disable Friendly Fire");
		else
			box.AddItem("box", "Disable Friendly Fire", ITEMDRAW_DISABLED);
		box.Display(client, MENU_TIME_FOREVER);
	}
}
public int BoxMenuHandler(Menu menu, MenuAction action, int client, int item)
{
	if (action == MenuAction_Select)
	{
		char info[64];
		GetMenuItem(menu, item, info, sizeof(info));
		if (StrEqual(info, "box"))
		{
			if (!isbox)
			{
				ServerCommand("mp_teammates_are_enemies 1");
				PrintToChatAll("%s friendly fire turned on!", PREFIX);
			}
			if (isbox)
			{
				ServerCommand("mp_teammates_are_enemies 0");
				PrintToChatAll("%s friendly fire turned off!", PREFIX);
			}
			
		}
	}
	if (action == MenuAction_End)
	{
		isbox = !isbox;
	}
}
public Action cmd_givelr(int client, args)
{
	if (args != 1)
	{
		PrintToChat(client, "%s Usage: /givelr <playername>", PREFIX);
		return Plugin_Handled;
	}
	if (!IsPlayerAlive(client))
	{
		PrintToChat(client, "%s You are dead you cant give some one lastrequest", PREFIX);
		return Plugin_Handled;
	}
	if (GetTeamAliveCount() != 1)
	{
		PrintToChat(client, "%s you are not the last terrorist!", PREFIX);
		return Plugin_Handled;
	}
	if (GetClientTeam(client) == CS_TEAM_T && IsPlayerAlive(client) && GetTeamAliveCount() == 1)
	{
		if (args == 1)
		{
			char arg1[32];
			GetCmdArg(1, arg1, sizeof(arg1));
			int target = FindTarget(client, arg1, false, false);
			if (!target)
			{
				PrintToChat(client, "%s Invalid Target.", PREFIX);
				return Plugin_Handled;
			}
			float Origin[3];
			char clientname[4096];
			char targetname[4096];
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", Origin);
			CS_RespawnPlayer(target);
			TeleportEntity(target, Origin, NULL_VECTOR, NULL_VECTOR);
			SlapPlayer(client, 100, false);
			GetClientName(client, clientname, sizeof(clientname));
			GetClientName(target, targetname, sizeof(targetname));
			PrintToChatAll("%s %s gave to %s the lastrequest", PREFIX, clientname, targetname);
		}
	}
	return Plugin_Continue;
}
stock GetTeamAliveCount()
{
	new iCount;
	for (new iClient = 1; iClient <= MaxClients; iClient++)
	if (IsClientInGame(iClient) && GetClientTeam(iClient) == CS_TEAM_T && IsPlayerAlive(iClient))
		iCount++;
	return iCount;
} 