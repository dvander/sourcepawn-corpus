
/********************************************************************************************
* Plugin	: HappyTankWitch
* Version	: 0.1
* Game	: Left4Dead 
* Author	: Cia Hang
* Testers	: Myself

* Version 0.1
* 		- Initial release
*********************************************************************************************/ 
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "0.1"
 
new bool:bWitchSpawned;

public Plugin:myinfo = 
{
	name = "Happy Tank Witch",
	author = "Cia Hang",  
	description = "For every Tank that spawns, so shall a Witch",
	version = PLUGIN_VERSION, 
	url = "http://www.sourcemod.net/" 		
};

public OnPluginStart()
{		
	bWitchSpawned = false;
		
	HookEvent("tank_spawn", Event_TankSpawned, EventHookMode_PostNoCopy);	
	HookEvent("witch_killed", Event_WitchKilled, EventHookMode_PostNoCopy);	
	HookEvent("round_start", Event_RoundStart);
}

public GetAnyClient()
{
	new i;
	for (i=1;i<=GetMaxClients();i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && (!IsFakeClient(i)))
		{
			return i;
		}
	}
	return 0;
}

public SpawnAWitch()
{
	if (bWitchSpawned == true)
	{
		return;
	}
	
	bWitchSpawned = true;

	new anyclient = GetAnyClient();
	if (anyclient == 0)
	{		
		anyclient = CreateFakeClient("Bot");
		if (anyclient == 0)
		{		
			return;	
		}	
	}
    
	new String:command[] = "z_spawn";
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
			
	FakeClientCommand(anyclient, "z_spawn witch auto");

	SetCommandFlags(command, flags);
}

public Event_TankSpawned(Handle:event, const String:name[], bool:dontBroadcast) 
{	
	SpawnAWitch();
	return;
}

public Event_WitchKilled(Handle:event, const String:name[], bool:dontBroadcast) 
{	
	if (bWitchSpawned == true)
	{
		bWitchSpawned = false;
	}
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{	
	bWitchSpawned = false;		
}