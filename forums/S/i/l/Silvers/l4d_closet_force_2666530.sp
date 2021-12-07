#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

public Plugin myinfo =
{
	name = "[L4D & L4D2] Force Rescue Closets",
	author = "SilverShot",
	description = "Forces Rescue Closets to be activated.",
	version = "1.0",
	url = "https://www.sourcemod.net/plugins.php?author=Silvers&search=1&sortby=title&order=0"
}

public void OnPluginStart()
{
	HookEvent("round_start", Round_Start, EventHookMode_PostNoCopy);
}

public void Round_Start(Event event, const char[] name, bool dontBroadcast)
{
	CreateTimer(2.0, tmrStart);
}

public Action tmrStart(Handle timer)
{
	DoVscript();
}

void DoVscript()
{
	int entity = CreateEntityByName("logic_script");
	DispatchSpawn(entity);

	char sTemp[256];
	Format(sTemp, sizeof(sTemp), "DirectorOptions <-\
{\
	cm_AllowSurvivorRescue = 1\
}");
	// cm_NoRescueClosets = 0

	SetVariantString(sTemp);
	AcceptEntityInput(entity, "RunScriptCode");
	AcceptEntityInput(entity, "Kill");
}