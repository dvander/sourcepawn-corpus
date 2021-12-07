#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

// Silly gibberish
#define FOLDER "particles/"
#define EXTENSION ".pcf"

// Cvar bullshit
new Handle:g_Cvar_CustomFireIgnite = INVALID_HANDLE;
new Handle:g_Cvar_CustomFireInferno = INVALID_HANDLE;

new bool:lateLoad = true;
new bool:igniteLoad = false;
new bool:infernoLoad = false;

public Plugin:myinfo ={
	name = "Custom fire particle system evildoer",
	author = "Chester the Cheetah",
	description = "Precachescustom fire particles to make the server look fancy.",
	version = "1.2.1",
	url = "http://veryboringwords.com/"
};

public OnPluginStart(){ 
	HookEvent("round_start", OnRoundStart);

	g_Cvar_CustomFireIgnite = CreateConVar("sm_fire_ignite_name", "burning_fx_sblue", "Defines the particle system file to be used for the ignite particles. ");
	g_Cvar_CustomFireInferno = CreateConVar("sm_fire_inferno_name", "inferno_fx_fps", "Defines the particle system file to be used for the inferno particles. ");

	// Hook cvar changes. The particles must be precached before they're active, so the safest bet is at round start
	HookConVarChange(g_Cvar_CustomFireIgnite, OnIgniteChanged);
	HookConVarChange(g_Cvar_CustomFireInferno, OnInfernoChanged);

	if(lateLoad)
	{
		lateLoad = false;
		OnMapStart();
	}
}

public OnIgniteChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	PrintToChatAll("\x01 %cIgnite particle system changed from '%c%s%c' to '%c%s%c'. Changes will be applied next round. ", 9, 8, 9, 8, oldVal, 9, newVal);
	igniteLoad = true;
}

public OnInfernoChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	PrintToChatAll("\x01 %cInferno particle system changed from '%c%s%c' to '%c%s%c'. Changes will be applied next round. ", 9, 8, 9, 8, oldVal, 9, newVal);
	infernoLoad = true;
}

public OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(igniteLoad)
	{
		loadIgnite();
	}

	if(infernoLoad)
	{
		loadInferno();
	}
}

public OnMapStart()
{
	// Load both when the map starts
	loadIgnite();
	loadInferno();
}

public loadIgnite()
{
	decl String:igniteSystem[128];
	decl String:igniteName[128];

	GetConVarString(g_Cvar_CustomFireIgnite, igniteName, sizeof(igniteName));
	FormatEx(igniteSystem, sizeof(igniteSystem), "%s%s%s", FOLDER, igniteName, EXTENSION);

	if(FileExists(igniteSystem))
	{
		PrecacheGeneric(igniteSystem, true);
	}	
}

public loadInferno()
{
	decl String:infernoSystem[128];
	decl String:infernoName[128];

	GetConVarString(g_Cvar_CustomFireInferno, infernoName, sizeof(infernoName));
	FormatEx(infernoSystem, sizeof(infernoSystem), "%s%s%s", FOLDER, infernoName, EXTENSION);

	if(FileExists(infernoSystem))
	{
		PrecacheGeneric(infernoSystem, true);
	}	
}