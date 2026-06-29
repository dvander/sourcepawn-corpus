 //
// DoDs Santa Skin
// -----------------------------
// For DoD:Source
// This plugin change team skin and kick no SkinDownload client
// -----------------------------

#include <sourcemod>
#include <sdktools>

#define SPEC 1
#define ALLIES 2
#define AXIS 3

#define PLUGIN_VERSION "1.0"

new Handle:cvar_kicknodl = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "DoD Santa Skin", 
	author = "Micmacx based on <eVa>Dog and vintage scripts ", 
	description = "skin all player with santa skin", 
	version = PLUGIN_VERSION, 
	url = ""
}

public OnPluginStart()
{
	CheckGame()
	
	CreateConVar("dod_santa_skin", PLUGIN_VERSION, "DoD Santa Skin", FCVAR_DONTRECORD | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY)
	cvar_kicknodl = CreateConVar("dod_santa_skin_kicknodl", "1", "Enabled/Disabled kicking players with DL-filter, 0 = off/1 = on", _, true, 0.0, true, 1.0)
	AutoExecConfig(true, "dod_santa_skin", "dod_santa_skin")
	HookEvent("player_spawn", SpawnEvent);
	
}

public OnMapStart()
{
	AddFileToDownloadsTable("models/player/santa_us/santaclaus.dx80.vtx")
	AddFileToDownloadsTable("models/player/santa_us/santaclaus.dx90.vtx")
	AddFileToDownloadsTable("models/player/santa_us/santaclaus.mdl")
	AddFileToDownloadsTable("models/player/santa_us/santaclaus.phy")
	AddFileToDownloadsTable("models/player/santa_us/santaclaus.sw.vtx")
	AddFileToDownloadsTable("models/player/santa_us/santaclaus.vvd")
	AddFileToDownloadsTable("materials/models/player/santa_us/basic_hand.vmt")
	AddFileToDownloadsTable("materials/models/player/santa_us/basic_hand.vtf")
	AddFileToDownloadsTable("materials/models/player/santa_us/face.vmt")
	AddFileToDownloadsTable("materials/models/player/santa_us/face.vtf")
	AddFileToDownloadsTable("materials/models/player/santa_us/hat.vmt")
	AddFileToDownloadsTable("materials/models/player/santa_us/hat.vtf")
	AddFileToDownloadsTable("materials/models/player/santa_us/head.vmt")
	AddFileToDownloadsTable("materials/models/player/santa_us/head.vtf")
	AddFileToDownloadsTable("materials/models/player/santa_us/klaus_legs.vmt")
	AddFileToDownloadsTable("materials/models/player/santa_us/klaus_legs.vtf")
	AddFileToDownloadsTable("materials/models/player/santa_us/klaus_torso.vmt")
	AddFileToDownloadsTable("materials/models/player/santa_us/klaus_torso.vtf")
	AddFileToDownloadsTable("materials/models/player/santa_us/mouth_eyes.vmt")
	AddFileToDownloadsTable("materials/models/player/santa_us/mouth_eyes.vtf")
	AddFileToDownloadsTable("models/player/santa_axis/santaclaus.dx80.vtx")
	AddFileToDownloadsTable("models/player/santa_axis/santaclaus.dx90.vtx")
	AddFileToDownloadsTable("models/player/santa_axis/santaclaus.mdl")
	AddFileToDownloadsTable("models/player/santa_axis/santaclaus.phy")
	AddFileToDownloadsTable("models/player/santa_axis/santaclaus.sw.vtx")
	AddFileToDownloadsTable("models/player/santa_axis/santaclaus.vvd")
	AddFileToDownloadsTable("materials/models/player/santa_axis/basic_hand.vmt")
	AddFileToDownloadsTable("materials/models/player/santa_axis/basic_hand.vtf")
	AddFileToDownloadsTable("materials/models/player/santa_axis/face.vmt")
	AddFileToDownloadsTable("materials/models/player/santa_axis/face.vtf")
	AddFileToDownloadsTable("materials/models/player/santa_axis/hat.vmt")
	AddFileToDownloadsTable("materials/models/player/santa_axis/hat.vtf")
	AddFileToDownloadsTable("materials/models/player/santa_axis/head.vmt")
	AddFileToDownloadsTable("materials/models/player/santa_axis/head.vtf")
	AddFileToDownloadsTable("materials/models/player/santa_axis/klaus_legs.vmt")
	AddFileToDownloadsTable("materials/models/player/santa_axis/klaus_legs.vtf")
	AddFileToDownloadsTable("materials/models/player/santa_axis/klaus_torso.vmt")
	AddFileToDownloadsTable("materials/models/player/santa_axis/klaus_torso.vtf")
	AddFileToDownloadsTable("materials/models/player/santa_axis/mouth_eyes.vmt")
	AddFileToDownloadsTable("materials/models/player/santa_axis/mouth_eyes.vtf")
	PrecacheModel("models/player/santa_us/santaclaus.mdl")
	PrecacheModel("models/player/santa_axis/santaclaus.mdl")
}

public OnClientAuthorized(client, const String:auth[])
{
	if (GetConVarInt(cvar_kicknodl) == 1)
	{
		QueryClientConVar(client, "cl_downloadfilter", ConVarQueryFinished:dlfilter);
	}
}

public dlfilter(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName1[], const String:cvarValue1[])
{
	if (IsClientConnected(client))
	{
		if (strcmp(cvarValue1, "none", true) == 0)
		{
			KickClient(client, "Please enable SkinDownload and reconnect!");
		}
	}
}

public SpawnEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		if (GetClientTeam(client) == 2)
		{
			SetEntityModel(client, "models/player/santa_us/santaclaus.mdl")
		}
		if (GetClientTeam(client) == 3)
		{
			SetEntityModel(client, "models/player/santa_axis/santaclaus.mdl")
		}
	}
}

CheckGame()
{
	new String:strGame[10]
	GetGameFolderName(strGame, sizeof(strGame))
	
	if (StrEqual(strGame, "dod"))
	{
		PrintToServer("[dod_santa_skin] Version %s dod_santa_skin loaded.", PLUGIN_VERSION)
	}
	else
	{
		SetFailState("[dod_santa_skin] This plugin is made for DOD:S! Disabled.")
	}
}

