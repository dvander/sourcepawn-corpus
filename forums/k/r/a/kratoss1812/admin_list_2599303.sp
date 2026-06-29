#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "kRatoss"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>
#include <colors>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "New Admin List",
	author = PLUGIN_AUTHOR,
	description = "Reply to sm_admins command the name of online admin & his curent group",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_admins", Command_ShowAdminsOnline);
}

public Action Command_ShowAdminsOnline(int client, int args)
{
	int Admins = 0;
	
	for (int index = 1; index < MaxClients; index++)
	{
		if(IsClientInGame(index))
		{
			AdminId ClientAccess = GetUserAdmin(index);
			
			if(ClientAccess)
			{
				int AdminGroupsCount = GetAdminGroupCount(ClientAccess);
				
				for (int x = 0; x < AdminGroupsCount; x++)
				{
					char GroupName[32];
					
					if(GetAdminGroup(ClientAccess, x, GroupName, sizeof(GroupName)) != INVALID_GROUP_ID)
					{
						Admins++;
						
						char AdminNameAndGroup[64];
						Format(AdminNameAndGroup, sizeof(AdminNameAndGroup), "%N @ %s; ", index, GroupName);
						
						PrintToChatAll("\x04 \x05 Admins Online : \x03 %s", AdminNameAndGroup);						
					}
				}
			}
		}
	}
}