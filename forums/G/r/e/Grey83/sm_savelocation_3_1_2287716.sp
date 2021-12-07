#include <sourcemod>
#include <sdktools>
#define MAX_PLAYERS 64
#define PLUGIN_VERSION 	"3.1"
#define sName 	 "\x01[\x0700FF00Location Saver\x01]"
#define sCom 	 "\x0700FF00!t\x01"
#define sGCom 	 "\x0700FF00!gt\x01"

new Float:playercords[64+1][3];
new Handle:hCvarEnable, bool:bCvarEnable,
	Handle:hCvarSilent, bool:bCvarSilent;
new userused[64+1];
new Float:globalcords[3];
new savedteam[64+1];
new setglobal;

public Plugin:myinfo = 
{
	name = "Location Saver",
	author = "Aviram1994/Aviram Hassan/AviramR0X (Modified by Grey83)",
	description = "Saves the location of the user and lets him teleport back if he falls or get killed",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=745419"
}

public OnClientPutInServer(client)
{
	userused[client] = 0;
}

public Action:NotEnabled(client)
{
	PrintToChat(client,"%s %t", sName, "Disabled");
	return Plugin_Handled;
}
public OnPluginStart()
{
	LoadTranslations("savelocation.phrases");
	CreateConVar("sm_savelocation_version", PLUGIN_VERSION, "Location Saver version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	hCvarEnable = CreateConVar("sm_savelocation_enable", "1", "Enable/Disable the Location Saver", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hCvarSilent = CreateConVar("sm_savelocation_silent", "1", "Turning off the notification players about set a global location", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	RegConsoleCmd("sm_s", Command_SaveClientLocation, "Saves your current location");
	RegConsoleCmd("sm_t", Command_TeleClient, "Teleports you to the location you saved");
	RegConsoleCmd("sm_gt",Command_GlobalTeleClient, "Teleports you to the global location that was set by an admin");
	RegAdminCmd("sm_gs",Command_globalsave,ADMFLAG_KICK,"Save a global location for all ppl");
	RegAdminCmd("sm_gr",Command_globalremove,ADMFLAG_KICK,"Removes the global location");

	bCvarEnable = GetConVarBool(hCvarEnable);
	bCvarSilent = GetConVarBool(hCvarSilent);

	HookConVarChange(hCvarEnable, OnConVarChange);
	HookConVarChange(hCvarSilent, OnConVarChange);
	setglobal = 0;
}

public OnConVarChange(Handle:hCvar, const String:oldValue[], const String:newValue[])
{
	if (hCvar == hCvarEnable)
	{
		bCvarEnable = bool:StringToInt(newValue);
	}
	else if (hCvar == hCvarSilent)
	{
		bCvarSilent = bool:StringToInt(newValue);
	}
}

public Action:Command_globalsave(client, args)
{
	GetClientAbsOrigin(client,globalcords);
	setglobal = 1;
	if (bCvarSilent) PrintToChat(client, "%s %t", sName, "Saved global", sGCom);
	else PrintToChatAll("%s %t", sName, "Saved global", sGCom);
	return Plugin_Handled;
}

public Action:Command_globalremove(client,args)
{
	setglobal = 0;
	if (bCvarSilent) PrintToChat(client, "%s %t", sName, "Removed global");
	else PrintToChatAll("%s %t", sName, "Removed global");
	return Plugin_Handled
}

public Action:Command_GlobalTeleClient(client,args)
{
	if (!bCvarEnable) return NotEnabled(client);
	if (setglobal)
	{
		TeleportEntity(client,globalcords,NULL_VECTOR,NULL_VECTOR);
		PrintToChat(client,"%s %t", sName, "Teleported to global");
	}
	else PrintToChat(client,"%s %t", sName, "No global");
	return Plugin_Handled;
}

public Action:Command_SaveClientLocation(client,args)
{
	if (!bCvarEnable) return NotEnabled(client);
	if (IsPlayerAlive(client))
	{
		userused[client] = 1;
		GetClientAbsOrigin(client,playercords[client]);
		savedteam[client] = GetClientTeam(client);
		PrintToChat(client,"%s %t", sName, "Saved private", sCom);
	}
	else PrintToChat(client,"%s %t", sName, "Not alive");
	return Plugin_Handled;
}

public Action:Command_TeleClient(client,args)
{
	if (userused[client] == 0)
	{
		PrintToChat(client,"%s %t", sName, "No private");
		return Plugin_Handled;
	}
	if (!bCvarEnable) return NotEnabled(client);
	if (GetClientTeam(client) != savedteam[client])
	{
		PrintToChat(client,"%s %t", sName, "Another team");
		return Plugin_Handled;
	}
	TeleportEntity(client, playercords[client],NULL_VECTOR,NULL_VECTOR);
	return Plugin_Handled;
}