#include <sourcemod>

#define NETID_TO_COMPARE "STEAM_"
#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = 
{
	name = "RageQuitter Banner",
	author = "ispirto",
	description = "Opens a menu to admins to ban ragequitting user",
	version = PLUGIN_VERSION,
	url = "http://ispirto.us"
}

public OnPluginStart()
{
	HookEvent("player_disconnect", ragequitBanner);
}

public Action:ragequitBanner(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(event != INVALID_HANDLE)
	{
		decl String:pNetid[32], String:pReason[64], String:pName[33];
		GetEventString(event, "networkid", pNetid, sizeof(pNetid));
		GetEventString(event, "reason", pReason, sizeof(pReason));
		GetEventString(event, "name", pName, sizeof(pName));
		
		//check if user disconnected himself
		if(StrEqual(pReason, "Disconnect by user."))
		{
			if(StrEqual(pName, "") || StrEqual(pNetid, ""))
			{
				return Plugin_Continue;
			}
			else if(strncmp(pNetid, NETID_TO_COMPARE, 6) != 0)
			{
				return Plugin_Continue;
			}
			else
			{
				new maxclients = GetMaxClients();
				
				for(new client = 1; client <= maxclients; client++)
				{
					new flags = GetUserFlagBits(client);
					
					//show ban menu to admins
					if(flags & ADMFLAG_BAN)
					{
						BanMenuOverview(client, pName, pNetid)
					}
				}
			}
		}
	}

	return Plugin_Handled;
}

public BanMenuOverview(client, String:pName[], String:pNetid[])
{
	new Handle:Menu = CreateMenu(BanMenu);
	SetMenuExitBackButton(Menu, false);
	SetMenuTitle(Menu, "Ban %s <%s>?\n ", pName, pNetid);

	AddMenuItem(Menu,pNetid,"Yes");
	AddMenuItem(Menu,"no","No");

	DisplayMenu(Menu,client,0);
	
	return Plugin_Handled;
}

public BanMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		if(param2 == 0)
		{
			//ban the user
			new String:info[32];
			new bool:found = GetMenuItem(menu, param2, info, sizeof(info));

			FakeClientCommand(param1, "sm_addban 0 %s ragequit", info);
		}
	}

	return;
}