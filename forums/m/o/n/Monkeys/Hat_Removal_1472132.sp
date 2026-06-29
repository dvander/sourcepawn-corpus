#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#pragma semicolon 1

#define VERSION "1.1a"

static currMode;
static bool:bHatsOff[MAXPLAYERS+1] = { false, ... };
static bool:bRecentPrint[MAXPLAYERS+1] = { false, ... };

public Plugin:myinfo =
{
	name = "Hat Removal",
	author = "Jaro 'Monkeys' Vanderheijden",
	description = "Gives players the choice to toggle hat visibility",
	version = VERSION,
	url = "http://www.sourcemod.net/"
};
 
public OnPluginStart()
{
	CreateConVar("sm_hatremoval_version", VERSION, "Version of Hat Removal", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	new Handle:hMode = CreateConVar("sm_hatremoval_mode", "2", "Mode Hat Removal is running in. 0: hats on | 1: hats off | 2: players can toggle");
	currMode = GetConVarInt(hMode);
	HookConVarChange(hMode, cbCvarChange);
	
	RegConsoleCmd("sm_togglehat", cbToggleHat, "Toggles hat visibility");
	
	HookEvent("player_spawn", EventSpawn);
}

public OnClientDisconnect(Client)
{
	bHatsOff[Client] = false;
	bRecentPrint[Client] = false;
}

public OnEntityCreated(entity, const String:Classname[])
{
	//The delay is present so m_ModelName is set
	if(StrEqual(Classname, "tf_wearable"))
			CreateTimer( 0.1, timerHookDelay, entity);
}

public Action:timerHookDelay(Handle:Timer, any:entity)
{
	if(IsValidEdict(entity))
	{
		//Hook transmit
		//Unless it's a The Razorback, Darwin's Danger Shield or Gunboats
		new String:sModel[256];
		GetEntPropString(entity, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
		if(!( StrContains(sModel, "croc_shield") != -1 
		|| StrContains(sModel, "c_rocketboots_soldier") != -1
		|| StrContains(sModel, "knife_shield") != -1 ) )
			SDKHook(entity, SDKHook_SetTransmit, cbTransmit);
	}
}

public EventSpawn(Handle:Event, const String:Name[], bool:dontBroadcast) 
{
	new Client = GetClientOfUserId(GetEventInt( Event, "userid" ));
	
	if( !bRecentPrint[Client] )
	{
		if(currMode == 2)
			PrintToChat(Client, "This server is running Hat Removal, type !togglehat or /togglehat in chat to toggle hat visibility.");
		else
			if(currMode == 1)
				PrintToChat(Client, "This server is running Hat Removal, all hats have been removed.");
				
		//This is to have less spam when switching classes/round start.
		bRecentPrint[Client] = true;
		CreateTimer( 20.0, timerResetRecentPrint, Client);
	}
}

public Action:timerResetRecentPrint(Handle:Timer, any:Client)
{
	bRecentPrint[Client] = false;
	return Plugin_Handled;
}

public Action:cbToggleHat(Client, Args)
{
	//Plugin isn't on
	if(currMode == 0)
	{
		PrintToChat(Client, "This server is running Hat Removal, but it's turned off right now.");
		return Plugin_Handled;
	}
	//Plugin is on forced mode
	if(currMode == 1)
	{
		PrintToChat(Client, "This server is running Hat Removal, all hats have been removed and can't be toggled.");
		return Plugin_Handled;
	}
	//Toggle, but if the client gives a 0/other as argument, turn it off/on.
	if(Args > 0)
	{
		decl String:arg[5];
		GetCmdArg(1, arg, sizeof(arg));
		bHatsOff[Client] = StrEqual(arg, "0");
	} else
		bHatsOff[Client] = !bHatsOff[Client];
	return Plugin_Handled;
}

public cbCvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	currMode = StringToInt(newValue);
	if(currMode < 0 || currMode > 2)
		currMode = 0;
	switch(currMode)
	{
		case 0:
			PrintToChatAll("Hat Removal disabled.");
		case 1:
			PrintToChatAll("All hats removed. Toggling hats is now disabled.");
		case 2:
			PrintToChatAll("Toggling hats is now enabled.");
	}
}

public Action:cbTransmit(Entity, Client)
{
	//Transmit when plugin's off OR if the player didn't turn it on
	if(currMode == 0 || (currMode == 2 && !bHatsOff[Client]) )
		return Plugin_Continue;
	else
		return Plugin_Handled;
}
