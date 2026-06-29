#include <sourcemod>
#include <sdktools>
#include <warden>

#pragma semicolon 1

new iEnt;
new const String:EntityList[][] = { "func_door", "func_movinglinear" };

public OnPluginStart()
{
    RegConsoleCmd("sm_open", OnOpenCommand);
    RegConsoleCmd("sm_close", OnCloseCommand);
}

public Action:OnOpenCommand(client, args)
{
	if(warden_iswarden(client))
	{
		for(new i = 0; i < sizeof(EntityList); i++)
			while((iEnt = FindEntityByClassname(iEnt, EntityList[i])) != -1)
				AcceptEntityInput(iEnt, "Open");
	}
	else
	{	
		PrintToChat(client, "You're not the warden");
	}
}

public Action:OnCloseCommand(client, args)
{
	if(warden_iswarden(client))
	{
		for(new i = 0; i < sizeof(EntityList); i++)
			while((iEnt = FindEntityByClassname(iEnt, EntityList[i])) != -1)
				AcceptEntityInput(iEnt, "Close");
	}
	else
	{	
		PrintToChat(client, "You're not the warden");
	}
}