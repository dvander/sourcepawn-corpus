
/********************************************************************************************
* Plugin	: SurviveAWitch
* Version	: 0.2
* Game		: Left4Dead 
* Author	: Alex Darby
* Testers	: Myself

* Version 0.1
* 		- Initial release.
* Version 0.2
* 		- Fixed a bug where the witch would not respawn after a round was over
*
*********************************************************************************************/ 

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "0.2"
 
new bool:bCheckForGameMode;
new bool:bSurvivalGameMode;
new bool:bWitchSpawned;

public Plugin:myinfo = 
{
	name = "SurviveAWitch",
	author = "AlexDarby",  
	description = "WitchesInSurvivalMode",
	version = PLUGIN_VERSION, 
	url = "http://www.sourcemod.net/" 		
};

public OnPluginStart()
{		
	bCheckForGameMode = true;
	bSurvivalGameMode = false;
	bWitchSpawned = false;
		
	HookEvent("tank_spawn", Event_TankSpawned, EventHookMode_PostNoCopy);	
	HookEvent("witch_killed", Event_WitchKilled, EventHookMode_PostNoCopy);	
	HookEvent("round_start", Event_RoundStart)
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
	
	PrintToChatAll("A witch has awakened!");
	
	new anyclient = GetAnyClient()
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
	if (bCheckForGameMode == true)
	{
		new String:sGameModeName[32];
		GetConVarString(FindConVar("mp_gamemode"), sGameModeName, 32);
		if (StrContains(sGameModeName, "survival", false) != -1)    
		{
			bSurvivalGameMode = true;
		}    
	
		bCheckForGameMode = false;
	}

    if (bSurvivalGameMode)
    {
		SpawnAWitch();
	}
	
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
	bCheckForGameMode = true;
	bSurvivalGameMode = false;
	bWitchSpawned = false;		
}