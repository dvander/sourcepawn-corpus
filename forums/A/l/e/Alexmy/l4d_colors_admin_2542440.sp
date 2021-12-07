#pragma semicolon 1
#include <sourcemod>
#pragma newdecls required


public void OnPluginStart()
{
	HookEvent("player_spawn", EventAdminSpawn, EventHookMode_Post);
}

public void EventAdminSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int adminid = GetClientOfUserId(event.GetInt("userid"));
	if(adminid)
	{
		int flags = GetUserFlagBits(adminid);
		if(flags & ADMFLAG_ROOT) SetEntityRenderColor(adminid, 255, 0, 0, 255); //red
		else if(flags & ADMFLAG_GENERIC) SetEntityRenderColor(adminid, 0, 0, 255, 255); //blue
		else if(flags & ADMFLAG_CUSTOM1) SetEntityRenderColor(adminid, 0, 255, 0, 255); //green
	}
}