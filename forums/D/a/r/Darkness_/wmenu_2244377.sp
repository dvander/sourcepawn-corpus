#include <sourcemod>

public OnPluginStart()
{
	HookEvent("player_spawn", Event_PlayerSpawn);
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontbroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (GetClientTeam(client) == 3)
	{
		ShowMenu(client);
	}
}

ShowMenu(client)
{
	if (!IsClientInGame(client))
		return;
		
	new Handle:MenuHandle = CreateMenu(WardenMenu);
	SetMenuTitle(MenuHandle, "Do you want to be Warden? \n");
	AddMenuItem(MenuHandle, "Yes", "Yes");
	AddMenuItem(MenuHandle, "No", "No");
	
	DisplayMenu(MenuHandle, client, 15);
}

public WardenMenu(Handle:menu, MenuAction:action, client, option)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			new String:info[64];
			GetMenuItem(menu, option, info, sizeof(info));
			if (StrEqual(info, "Yes"))
			{
				FakeClientCommand(client, "sm_warden");
			}
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}