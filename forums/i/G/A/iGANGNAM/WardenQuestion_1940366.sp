#include <sourcemod>
#include <cstrike>
#include <warden>

new bool:AnyWarden;
new Handle:MenuTimer[MAXPLAYERS + 1] = INVALID_HANDLE;

#define IsValidAlive(%1) ( 1 <= %1 <= MaxClients && IsClientInGame(%1) && IsPlayerAlive(%1) )

public OnPluginStart()
{
	HookEvent("round_freeze_end", Event_RoundFreezeEnd);
}

public Event_RoundFreezeEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new i=0;i<=MAXPLAYERS;i++)
	{
		if (IsValidAlive(i) && GetClientTeam(i) == CS_TEAM_CT && !AnyWarden ) {
			if (warden_iswarden(i)) {
				AnyWarden = true;
			}
		}
	}
	for(new i=0;i<=MAXPLAYERS;i++)
	{
		if (!AnyWarden && IsValidAlive(i) && GetClientTeam(i) == CS_TEAM_CT) {
			MenuTimer[i] = CreateTimer( 0.1, ChooseWarden, i, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}
public Action:ChooseWarden(Handle:timer, any:client)
{
	MenuTimer[client] = INVALID_HANDLE; 
	KillTimer(timer);

	if ( !IsValidAlive(client) || GetClientTeam(client) != CS_TEAM_CT )
	return Plugin_Continue;
	
	ChooseWarden2(client);

	return Plugin_Continue;
}

public ChooseWarden2(client)
{
	new Handle:menu = CreateMenu(ChooseWarden3);

	SetMenuTitle(menu, "Do you want to be warden?");

	AddMenuItem(menu, "class_id", "Yes")
	AddMenuItem(menu, "class_id", "No")

	SetMenuExitButton(menu, true);
	
	DisplayMenu(menu, client, 30 );
}

public ChooseWarden3(Handle:menu, MenuAction:action, client, item)
{
	if( action == MenuAction_Select )
	{	
		switch (item)
		{
		case 0: // show pistols
			{
				Yes(client);
			}
		case 1: // last weapons
			{
				No(client);
			}
		}
	} 
	else if (action == MenuAction_End)	
	{
		CloseHandle(menu);
	}
}

public Action:Yes(client)
{
	for(new i=0;i<=MAXPLAYERS;i++)
	{
		if (IsValidAlive(i) && GetClientTeam(i) == CS_TEAM_CT && !AnyWarden ) {
			if (warden_iswarden(client)) {
				AnyWarden = true;
			}
		}
	}
	
	if (!AnyWarden && GetClientTeam(client) == CS_TEAM_CT) {
		ClientCommand(client, "sm_warden");
	}
}

public Action:No(client)
{
	PrintToChat(client, "Aw.. Be warden next time, ok? ;)");
}