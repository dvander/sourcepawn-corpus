#include <sourcemod>
#include <morecolors>

#pragma semicolon 1

new Handle:g_h_CVAR_Enable = INVALID_HANDLE;
new Handle:g_h_CVAR_Usage = INVALID_HANDLE;
new Handle:g_h_CVAR_Tag = INVALID_HANDLE;

new Handle:g_h_CVAR_CTag = INVALID_HANDLE;
new Handle:g_h_CVAR_CName = INVALID_HANDLE;
new Handle:g_h_CVAR_CText = INVALID_HANDLE;

new String:IDs[][]=
{
	"STEAM_x:x:xxxxxxxx",	"STEAM_x:x:xxxxxxxx",	"STEAM_x:x:xxxxxxxx",
	"STEAM_x:x:xxxxxxxx"
};


public Plugin:myinfo = 
{
	name = "Admin Chat",
	author = "eXceeder",
	description = "Admin Chat for all or for few admins",
	version = "1.0",
	url = "www.sourcemod.net"
}


public OnPluginStart()
{
	g_h_CVAR_Enable = CreateConVar("sm_enable", "1", "Turn On/Off the plugin. (0 = Off | 1 = On)");
	g_h_CVAR_Usage = CreateConVar("sm_usage", "1", "Use Admin Chat for all Admins = 1, or 2 = for Admins they are available in the list");
	g_h_CVAR_Tag = CreateConVar("sm_tag", "[ADMIN]", "Tag for the Admin Chat");
	g_h_CVAR_CTag = CreateConVar("sm_color_tag", "lime", "Color for the Admin Tag");
	g_h_CVAR_CName = CreateConVar("sm_color_name", "fullred", "Color for the Name of the Admin");
	g_h_CVAR_CText = CreateConVar("sm_color_text", "deepskyblue", "Color for the Text which the Admin has written");
	
	AutoExecConfig(true, "plugin.AdminChat");
	
	RegConsoleCmd("say", Say_Hook);
}


public Action:Say_Hook(client, args)
{
	new Enable = GetConVarInt(g_h_CVAR_Enable);
	if(Enable != 1)
	{
		return Plugin_Continue;
	}
	
	decl String:sText[192];
	GetCmdArgString(sText, sizeof(sText));
	StripQuotes(sText);
	
	new Usage = GetConVarInt(g_h_CVAR_Usage);
	switch(Usage)
	{
		case 1:
		{
			new AdminId:ID = GetUserAdmin(client);
			
			/* Check if the client is an admin */
			if(ID != INVALID_ADMIN_ID)
			{
				/* Check if the client is valid */
				if(IsClientValid(client))
				{
					AdminChat(client, sText);
				}
			}
			
			else
			{
				return Plugin_Continue;
			}
		}
		
		case 2:
		{
			new bool:is_admin = false;
			
			for(new i; i < sizeof(IDs); i++)
			{
				decl String:SteamID[32];
				GetClientAuthString(client, SteamID, sizeof(SteamID));
				
				/* Check if SteamID is in the list */
				if(StrEqual(SteamID, IDs[i], true))
				{
					/* Check if the client is valid */
					if(IsClientValid(client))
					{
						is_admin = true;
						AdminChat(client, sText);
					}
				}
			}
			
			if(!is_admin)
				return Plugin_Continue;
		}
	}
	
	return Plugin_Handled;
}


AdminChat(client, String:sText[192])
{
	new String:sTag[20];
	GetConVarString(g_h_CVAR_Tag, sTag, sizeof(sTag));
	
	new String:Color_Tag[20];
	GetConVarString(g_h_CVAR_CTag, Color_Tag, sizeof(Color_Tag));
	
	new String:Color_Name[20];
	GetConVarString(g_h_CVAR_CName, Color_Name, sizeof(Color_Name));
	
	new String:Color_Text[20];
	GetConVarString(g_h_CVAR_CText, Color_Text, sizeof(Color_Text));
	
	CPrintToChatAll("{%s}%s{%s}%N: {%s}%s", Color_Tag, sTag, Color_Name, client, Color_Text, sText);
}


// --------------------------------- STOCKS --------------------------------- //


stock bool:IsClientValid(i)
{
	if(i > 0 && i <= MaxClients && IsClientInGame(i))
	{
		return true;
	}
	
	return false;
}