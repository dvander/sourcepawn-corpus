#include <sourcemod>
#include <sdktools>
#include <duck>
#pragma semicolon 1

public Plugin:myinfo =
{
    name = "Duck",
    author = "Duck",
    description = "Duck",
    version = "Duck",
    url = "Duck"
};

stock DuckOverlay(duck, const String:duckmaterial[] = "")
{
	new duckflags = GetCommandFlags("r_screenoverlay");
	SetCommandFlags("r_screenoverlay", duckflags & ~FCVAR_CHEAT);
	if(!StrEqual(duckmaterial, ""))
	{
		ClientCommand(duck, "r_screenoverlay \"%s\"", duckmaterial);
	}
	else
	{
		ClientCommand(duck, "r_screenoverlay \"\"");
	}
	SetCommandFlags("r_screenoverlay", duckflags);
}

public OnPluginStart()
{
	HookEvent("player_spawn", Event_DuckSpawn);
	AddNormalSoundHook(NormalSHook:DuckSound);
}

public Action:DuckSound(ducks[64], &numDucks, String:ducksample[PLATFORM_MAX_PATH], &duckent, &duckchannel, &Float:duckvolume, &ducklevel, &duckpitch, &duckflags)
{
	if(IsValidEntity(duckent) && duckent < 1 || duckent > MaxClients || duckchannel < 1)
	{
		return Plugin_Continue;
	}
	if(IsValidDuck(duckent))
	{
		Format(ducksample, sizeof(ducksample), "duck/duck.wav");
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public OnMapStart()
{
	AddFileToDownloadsTable("materials/duck/duck.vtf");
	AddFileToDownloadsTable("materials/duck/duck.vmt");
	AddFileToDownloadsTable("sound/duck/duck.wav");
	PrecacheGeneric("materials/duck/duck.vmt", true);
	PrecacheGeneric("materials/duck/duck.vtf", true);
	PrecacheSound("duck/duck.wav", true);
}

public APLRes:AskPluginLoad2(Handle:duck, bool:ducklate, String:duckerror[], duckerr_max)
{
	CreateNative("Duck_DuckOverlay", Native_DuckOverlay);
	CreateNative("Duck_DisableDuckOverlay", Native_DuckOverlay);
	RegPluginLibrary("duck");
	return APLRes_Success;
}

public Native_DisableDuckOverlay(Handle:duckplugin, ducknumParams)
{
	new duck = GetNativeCell(1);
	new duckflags = GetCommandFlags("r_screenoverlay");
	SetCommandFlags("r_screenoverlay", duckflags & ~FCVAR_CHEAT);
	ClientCommand(duck, "r_screenoverlay \"\"");
	SetCommandFlags("r_screenoverlay", duckflags);
}

public Native_DuckOverlay(Handle:duckplugin, ducknumParams)
{
	new duck = GetNativeCell(1);
	new String:overlay[PLATFORM_MAX_PATH];
	GetNativeString(2, overlay, PLATFORM_MAX_PATH);
	new duckflags = GetCommandFlags("r_screenoverlay");
	SetCommandFlags("r_screenoverlay", duckflags & ~FCVAR_CHEAT);
	ClientCommand(duck, "r_screenoverlay \"%s\"", overlay);
	SetCommandFlags("r_screenoverlay", duckflags);
}

public OnClientPutInServer(duck)
{
	DuckOverlay(duck, "materials/duck/duck.vtf");
}

public Action:Event_DuckSpawn(Handle:duckevent, const String:duckname[], bool:dontduckcast)
{
	new duck = GetClientOfUserId(GetEventInt(duckevent, "userid"));
	DuckOverlay(duck, "materials/duck/duck.vtf");
}

public bool:IsValidDuck(duck)
{
	if(duck >= 1 && duck <= MaxClients && IsClientInGame(duck) && IsClientConnected(duck))
	{
		return true;
	}
	return false;
}