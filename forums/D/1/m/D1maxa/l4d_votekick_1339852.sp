#pragma semicolon 1
#include <sourcemod>
#include <geoip>
#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = 
{
	name = "L4D_Votekick",
	author = "D1maxa",
	description = "Votekick menu for L4D",
	version = PLUGIN_VERSION,
	url = "http://hl2.msk.su/"
};

public OnPluginStart()
{
	LoadTranslations("l4d_votekick.phrases");	
	CreateConVar("l4d_votekick_version", PLUGIN_VERSION, " Version of L4D Votekick on this server ", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	RegConsoleCmd("votekick", Command_Votekick);
	RegConsoleCmd("sm_votekick", Command_Votekick);
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);
}

public OnClientPostAdminCheck(client)
{
	if(!IsFakeClient(client))
	{			
		ClientCommand(client, "bind 6 slot6");
		ClientCommand(client, "bind 7 slot7");
		ClientCommand(client, "bind 8 slot8");
		ClientCommand(client, "bind 9 slot9");
		ClientCommand(client, "bind 0 slot10");
	}
}

public Action:Command_Votekick(client, args)
{
	if(client!=0) CreateVotekickMenu(client);		
	return Plugin_Handled;
}

CreateVotekickMenu(client)
{	
	new Handle:menu = CreateMenu(Menu_Votekick);		
	new team=GetClientTeam(client);
	new String:name[MAX_NAME_LENGTH];
	new String:uid[12];
	new String:menuItem[64];
	new String:ip[16];
	new String:code[4];
	for(new i=1;i<=MaxClients;i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && i!=client && GetClientTeam(i)==team)
		{			
			Format(uid,sizeof(uid),"%i",GetClientUserId(i));
			if(GetClientName(i,name,sizeof(name)))
			{
				if(GetClientIP(i, ip, sizeof(ip)))
				{
					if(!GeoipCode3(ip, code))
						strcopy(code,sizeof(code),"LAN");
					Format(menuItem,sizeof(menuItem),"%s (%s)",name,code);
					AddMenuItem(menu, uid, menuItem);
				}
				else AddMenuItem(menu, uid, name);				
			}
		}		
	}
	
	SetMenuTitle(menu, "%T","Player To Kick",client);
	if (menu == INVALID_HANDLE)
	{
		LogMessage("Could not create menu for votekick");
	}
	else
	{
		DisplayMenu(menu, client, MENU_TIME_FOREVER);	
	}
}

public Menu_Votekick(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[12]; 
		
		if(GetMenuItem(menu, param2, info, sizeof(info)))
		{
			FakeClientCommand(param1,"callvote Kick %s",info);
		}		
	}
	else if (action == MenuAction_End)
	{		
		CloseHandle(menu);
	}
}

public Action:Command_Say(client, args)
{
	decl String:text[192], String:command[64];
	new startidx = 0;
	if (GetCmdArgString(text, sizeof(text)) < 1)
	{
		return Plugin_Continue;
	}
	
	if (text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}

	if (strcmp(command, "say2", false) == 0)
		startidx += 4;

	if (strcmp(text[startidx], "votekick", false) == 0)
	{
		if(client!=0) CreateVotekickMenu(client);		
	}
	return Plugin_Continue;
}

