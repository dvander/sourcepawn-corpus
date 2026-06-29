#include <sourcemod>

#pragma semicolon 1
#define PLUGIN_VERSION "3.0.0"

#define PREFIX "\x04[SM]\x01 "

new bool:adminallowed[MAXPLAYERS+1] = {true,...};
new Handle:gH_Enabled = INVALID_HANDLE;
new Handle:gH_Menu = INVALID_HANDLE;
new Handle:gH_Undercover = INVALID_HANDLE;
new Handle:gH_Logging = INVALID_HANDLE;
new bool:Enabled;
new bool:Menu;
new bool:Undercovers;
new bool:Logging;

public Plugin:myinfo =
{
	name = "Admin List",
	author = "TimeBomb",
	description = "Another admin list plugin, but BETTER.",
	version = PLUGIN_VERSION
};

public OnPluginStart()
{
	RegConsoleCmd("sm_admins", admins);
	
	CreateConVar("sm_admins_version", PLUGIN_VERSION, "\"Admin List\" plugin version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	gH_Enabled = CreateConVar("sm_admins_enabled", "1", "\"Admin List\" plugin is enabled?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	gH_Menu = CreateConVar("sm_admins_menu", "1", "Admin printing will be on menu or chat? [0 - Chat] [1 - Menu]", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	gH_Undercover = CreateConVar("sm_admins_undercover", "1", "\"Undercover\" Admins allowed?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	gH_Logging = CreateConVar("sm_admins_log", "1", "The plugin will log to a file everytme someone check for admins/changes visibility?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	Enabled = true;
	Menu = true;
	Undercovers = true;
	Logging = true;
	
	HookConVarChange(gH_Enabled, ConVarChanged);
	HookConVarChange(gH_Menu, ConVarChanged);
	HookConVarChange(gH_Undercover, ConVarChanged);
	HookConVarChange(gH_Logging, ConVarChanged);
	
	AutoExecConfig();
}

public ConVarChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if(cvar == gH_Enabled)
	{
		Enabled = GetConVarBool(gH_Enabled);
	}
	if(cvar == gH_Menu)
	{
		Menu = GetConVarBool(gH_Menu);
	}
	if(cvar == gH_Undercover)
	{
		Undercovers = GetConVarBool(gH_Undercover);
	}
	if(cvar == gH_Logging)
	{
		Logging = GetConVarBool(gH_Logging);
	}
}
public OnClientPutInServer(client)
{
	adminallowed[client] = true;
}
public OnClientDisconnect(client)
{
	adminallowed[client] = true;
}
public Action:admins(client, args)
{
	if(!Enabled)
	{
		return Plugin_Handled;
	}
	
	new players = 0;
	decl String:arg1[64];
	decl String:string[128];
	decl String:SteamID[64];
	decl String:IP[64];
	
	GetClientIP(client, IP, 64);
	GetClientAuthString(client, SteamID, 64);
	
	GetCmdArg(1, arg1, sizeof(arg1));
	
	new arg = StringToInt(arg1); 
	
	if(Undercovers && args == 1 && (GetUserFlagBits(client)))
	{
		if(arg == 1)
		{
			adminallowed[client] = true;
			PrintToChat_Custom(client, "You are now \x03SEEN\x01 from the admins list.");
			if(Logging) LogMessage("%N changed his visibility to seen. [IP: %s] [SteamID: %s]", client, IP, SteamID);
			return Plugin_Handled;
		}
		
		else if(arg == 0)
		{
			adminallowed[client] = false;
			PrintToChat_Custom(client, "You are now \x03HIDDEN\x01 from the admins list.");
			if(Logging) LogMessage("%N changed his visibility to hidden. [IP: %s] [SteamID: %s]", client, IP, SteamID);
			return Plugin_Handled;
		}
		
		else
		{
			ReplyToCommand(client, "%s Usage: sm_admins 0/1", PREFIX);
			if(Logging) LogMessage("%N failed to change his visibility. [IP: %s] [SteamID: %s]", client, IP, SteamID);
		}
	}
	else if(!Undercovers && args == 1)
	{
		PrintToChat_Custom(client, "%s Undercover admins are currently disabled.");
		if(Logging)
		{
			LogMessage("%N tried to use undercover admins while they are disabled. [IP: %s] [SteamID: %s]", client, IP, SteamID);
		}
		return Plugin_Handled;
	}
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetUserFlagBits(client) && adminallowed[i])
		{
			players++;
		}
	}
	switch(Menu)
	{
		case 0:
		{
			PrintToChat_Custom(client, "Admins online:");
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i) && GetUserFlagBits(client) && adminallowed[i])
				{
					PrintToChat_Custom(client, "\x03Admin:\x01 %N.", i);
				}
			}
			if(Logging)
			{
				LogMessage("%N typed !admins to see admins online. [Online admins: %d] [Method was chat] [IP: %s] [SteamID: %s]", client, players, IP, SteamID);
			}
			return Plugin_Handled;
		}
		
		case 1:
		{
			new Handle:menu = CreateMenu(MenuHandler_menu);
			SetMenuTitle(menu, "Admins online:");
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(i) && GetUserFlagBits(client) && adminallowed[i])
				{
					Format(string, sizeof(string), "%N", i);
					AddMenuItem(menu, "", string);
				}
			}
			if(players == 0)
			{
				AddMenuItem(menu, "", "There are no online admins.");
				if(Logging)
				{
					LogMessage("%N tried to use !admins while there are no online admins.", client);
				}
			}
			else
			{
				if(Logging)
				{
					LogMessage("%N typed !admins to see the admins online. [Online admins: %d] [Method was menu] [IP: %s] [SteamID: %s]", client, players, IP, SteamID);
				}
			}
			DisplayMenu(menu, client, 20);
			return Plugin_Handled;
		}
	}
	return Plugin_Handled;
}
public MenuHandler_menu(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}


public PrintToChat_Custom(client, const String:format[], any:...)
{
	decl String:buffer[250], String:buffer2[250];
	SetGlobalTransTarget(client);
	Format(buffer, sizeof(buffer), "%s%s", PREFIX, format);
	VFormat(buffer2, sizeof(buffer2), buffer, 3);
	PrintToChat(client, buffer2);
}