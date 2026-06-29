/**
* L4D Scavenge 4 Ever
* 1.0 - initial release
*/

#pragma semicolon 1
#include <sourcemod>
#define Version "1.0"

#define ADVERT "\x03This server runs \x04[\x03Scavenge 4 Ever\x04]\x03\nThere is a scavenge mapcycle!"

new Handle:Defaultmap;
new Handle:Delay;
new Handle:Announce;
new Handle:Force;

new Handle:CurrentGameMode = INVALID_HANDLE;
new String:GameMode;

new String:currentmap[64];

public Plugin:myinfo = 
{
	name = "L4D2 Scavenge4Ever",
	author = "kwski43 aka Jacklul",
	description = "Force change to next map when current ends in scavenge.",
	version = Version,
	url = ""
}

public OnPluginStart()
{
	decl String:ModName[50];
	GetGameFolderName(ModName, sizeof(ModName));

	if(!StrEqual(ModName, "left4dead2", false))
		SetFailState("Use this Left 4 Dead 2 only.");
	
	CreateConVar("l4d2_s4e_version", Version, "Scavenge 4 Ever version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	Defaultmap = CreateConVar("l4d2_s4e_defaultmap", "c1m4_atrium", "Map for change by default.",FCVAR_PLUGIN|FCVAR_NOTIFY);
	Delay = CreateConVar("l4d2_s4e_delay", "15.0", "Delay before map change.",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 30.0);
	Announce = CreateConVar("l4d2_s4e_announce", "20.0", "Announce delay from round start. 0-disables announcements",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 60.0);
	Force = CreateConVar("l4d2_s4e_forcescav", "0", "Force scavenge gamemode and maps on the server. 0-disables, 1-enable",FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);

	AutoExecConfig(true, "l4d2_scavenge4ever");	

	HookEvent("scavenge_match_finished", Event_ScavengeEnd, EventHookMode_Post);
	
	CurrentGameMode = FindConVar("mp_gamemode");

	HookConVarChange(CurrentGameMode, GameModeChanged);
}

public OnMapStart()
{
	GetCurrentMap(currentmap, 64);
	GameMode = Gamemode();
	if(GameMode == 6 || GameMode == 7)
	{
		CreateTimer(GetConVarFloat(Announce), Advert); 
	}
}

public Event_ScavengeEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GameMode == 6 || GameMode == 7)
	{
		PrintToChatAll("\x03The map is changing in \x04%s \x03seconds\x04!", Delay);
		CreateTimer(GetConVarFloat(Delay), ChangeMap);
	}
}

public Action:Advert(Handle:timer)
{

	PrintToChatAll(ADVERT);
}

public Action:ChangeMap(Handle:timer)
{
	if(GameMode == 6 || GameMode == 7)
	{
	//c5m2_park>c1m4_atrium>c6m1_riverbank>c6m2_bedlam>c6m3_port>c2m1_highway>c3m1_plankcountry>c4m1_milltown_a>c5m2_park
	if(StrEqual(currentmap, "c5m2_park") == true)
	{
		ServerCommand("changelevel c1m4_atrium");
	}
	else if(StrEqual(currentmap, "c1m4_atrium") == true)
	{
		ServerCommand("changelevel c6m1_riverbank");
	}
	else if(StrEqual(currentmap, "c6m1_riverbank") == true)
	{
		ServerCommand("changelevel c6m2_bedlam");
	}
	else if(StrEqual(currentmap, "c6m2_bedlam") == true)
	{
		ServerCommand("changelevel c6m3_port");
	}
	else if(StrEqual(currentmap, "c6m3_port") == true)
	{
		ServerCommand("changelevel c2m1_highway");
	}
	else if(StrEqual(currentmap, "c2m1_highway") == true)
	{
		ServerCommand("changelevel c3m1_plankcountry");
	}
	else if(StrEqual(currentmap, "c3m1_plankcountry") == true)
	{
		ServerCommand("changelevel c4m1_milltown_a");
	}
	else if(StrEqual(currentmap, "c4m1_milltown_a") == true)
	{
		ServerCommand("changelevel c5m2_park");
	}
	else if(StrEqual(currentmap, "c5m2_park") == true)
	{
		ServerCommand("changelevel c1m4_atrium");
	}
	else
	{
		LogMessage("Not a scavenge map (%s) detected! Forcing to the default map!", currentmap);
		ServerCommand("changelevel %s", Defaultmap);
	}
	}
}

Gamemode()
{
	new String:gmode[32];
	GetConVarString(FindConVar("mp_gamemode"), gmode, sizeof(gmode));

	if (strcmp(gmode, "coop") == 0)
	{
		return 1;
	}
	else if (strcmp(gmode, "realism", false) == 0)
	{
		return 2;
	}
	else if (strcmp(gmode, "survival", false) == 0)
	{
		return 3;
	}
	else if (strcmp(gmode, "versus", false) == 0)
	{
		return 4;
	}
	else if (strcmp(gmode, "teamversus", false) == 0)
	{
		return 5;
	}
	else if (strcmp(gmode, "scavenge", false) == 0)
	{
		return 6;
	}
	else if (strcmp(gmode, "teamscavenge", false) == 0)
	{
		return 7;
	}
	else
	{
		return false;
	}
}

public GameModeChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(GetConVarInt(Force) == 1)
	{
		LogMessage("Detected %s gamemode! Forcing to the scavenge and to the default map!", oldValue);
		ServerCommand("sm_cvar mp_gamemode scavenge");
		ServerCommand("changelevel %s", Defaultmap);
	}
}