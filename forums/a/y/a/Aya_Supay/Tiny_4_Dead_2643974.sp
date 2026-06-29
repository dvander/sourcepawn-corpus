/*##########################
#      Code By Lux         #
##########################*/

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

#define TEAM_INFECTED  3
#define ZOMBIECLASS_SMOKER	1
#define ZOMBIECLASS_BOOMER	2
#define ZOMBIECLASS_HUNTER	3

#define hulkgiant	"models/infected/hulkgiant.mdl"
#define hulktiny	"models/infected/hulktiny.mdl"
#define tinyboomer	"models/infected/tinyboomer.mdl"
#define tinyhunter	"models/infected/tinyhunter.mdl"
#define tinysmoker	"models/infected/tinysmoker.mdl"
#define tinywitch	"models/infected/tinywitch.mdl"

Handle g_hWitchEnable = null;
Handle g_hTankEnable = null;
Handle g_hInfectedEnable = null;
bool g_bRandomWitch = false;
bool g_bRandomTank = false;
bool g_bInfected = false;

public Plugin myinfo =
{
	name = "Tiny 4 Dead",
	author = "Joshe Gatito",
	description = "",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/joshegatito/"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if (test != Engine_Left4Dead)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("Tiny4Dead", PLUGIN_VERSION, "Version of Tiny4Dead", FCVAR_SPONLY|FCVAR_DONTRECORD);
	g_hWitchEnable = CreateConVar("RW_Enable", "1", "Should We Enable Random Witch", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hTankEnable = CreateConVar("RT_Enable", "1", "Should We Enable Random Tank", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hInfectedEnable = CreateConVar("RI_Enable", "1", "Should We Enable Random Infected", FCVAR_NOTIFY, true, 0.0, true, 1.0);	
	HookConVarChange(g_hWitchEnable, eConvarsChanged);
	HookConVarChange(g_hTankEnable, eConvarsChanged);
	HookConVarChange(g_hInfectedEnable, eConvarsChanged);
	CvarsChanged();
	HookEvent("witch_spawn", eWitchSpawn);
	HookEvent("tank_spawn", eTankSpawn);
	HookEvent("player_spawn", ePlayer_Spawn); 	
}

public void OnMapStart()
{
	PrecacheModel("models/infected/witch.mdl", true);
	PrecacheModel(tinywitch, true);
	PrecacheModel("models/infected/hulk.mdl", true);
	PrecacheModel("models/infected/smoker.mdl", true);
	PrecacheModel("models/infected/boomer.mdl", true);
	PrecacheModel("models/infected/hunter.mdl", true);
	PrecacheModel(hulkgiant, true);
	PrecacheModel(hulktiny, true);
	PrecacheModel(tinyboomer, true);
	PrecacheModel(tinyhunter, true);
	PrecacheModel(tinysmoker, true);
	PrecacheModel(tinywitch, true);
	AddFileToDownloadsTable("models/infected/hulkgiant.mdl");
	AddFileToDownloadsTable("models/infected/hulktiny.mdl");
	AddFileToDownloadsTable("models/infected/tinyboomer.mdl");
	AddFileToDownloadsTable("models/infected/tinyhunter.mdl");
	AddFileToDownloadsTable("models/infected/tinysmoker.mdl");
	AddFileToDownloadsTable("models/infected/tinywitch.mdl");	
	AddFileToDownloadsTable("models/infected/hulkgiant.vvd"); 
	AddFileToDownloadsTable("models/infected/hulktiny.vvd"); 
	AddFileToDownloadsTable("models/infected/tinyboomer.vvd"); 
	AddFileToDownloadsTable("models/infected/tinyhunter.vvd"); 
	AddFileToDownloadsTable("models/infected/tinysmoker.vvd"); 
	AddFileToDownloadsTable("models/infected/tinywitch.vvd");
	AddFileToDownloadsTable("models/infected/hulkgiant.dx90.vtx"); 
	AddFileToDownloadsTable("models/infected/hulktiny.dx90.vtx"); 
	AddFileToDownloadsTable("models/infected/tinyboomer.dx90.vtx"); 
	AddFileToDownloadsTable("models/infected/tinyhunter.dx90.vtx"); 
	AddFileToDownloadsTable("models/infected/tinysmoker.dx90.vtx"); 
	AddFileToDownloadsTable("models/infected/tinywitch.dx90.vtx");	
	AddFileToDownloadsTable("models/infected/hulkgiant.vtx"); 
	AddFileToDownloadsTable("models/infected/hulktiny.vtx"); 
	AddFileToDownloadsTable("models/infected/tinyboomer.vtx"); 
	AddFileToDownloadsTable("models/infected/tinyhunter.vtx"); 
	AddFileToDownloadsTable("models/infected/tinysmoker.vtx"); 
	AddFileToDownloadsTable("models/infected/tinywitch.vtx");
	AddFileToDownloadsTable("models/infected/hulkgiant.phy"); 
	AddFileToDownloadsTable("models/infected/hulktiny.phy"); 
	AddFileToDownloadsTable("models/infected/tinyboomer.phy"); 
	AddFileToDownloadsTable("models/infected/tinyhunter.phy"); 
	AddFileToDownloadsTable("models/infected/tinysmoker.phy"); 
	AddFileToDownloadsTable("models/infected/tinywitch.phy");
	CvarsChanged();
}

public void eConvarsChanged(Handle hCvar, const char[] sOldVal, const char[] sNewVal)
{
	CvarsChanged();
}

void CvarsChanged()
{
	g_bRandomWitch = GetConVarInt(g_hWitchEnable) > 0;
	g_bRandomTank = GetConVarInt(g_hTankEnable) > 0;
	g_bInfected = GetConVarInt(g_hInfectedEnable) > 0;
}

public Action eWitchSpawn(Handle hEvent, const char[] sName, bool dontBroadcast)
{
	if(!g_bRandomWitch)
	return;

	switch(GetRandomInt(1, 2))
	{
		case 1:
		{
			int iWitch = GetEventInt(hEvent, "witchid");
			SetEntityModel(iWitch, tinywitch);
		}
	}
}

public Action eTankSpawn(Handle hEvent, const char[] sName, bool dontBroadcast)
{
	if(!g_bRandomTank)
	return;

	switch(GetRandomInt(1, 3))
	{
		case 1:
		{
			int iTank = GetEventInt(hEvent, "tankid");
			SetEntityModel(iTank, hulkgiant);
		}
		case 2:
		{
			int iTank = GetEventInt(hEvent, "tankid");
			SetEntityModel(iTank, hulktiny);
		}
	}
}

public Action ePlayer_Spawn(Handle hEvent, const char[] sName, bool dontBroadcast)
{
	if(!g_bInfected)
	return;

	static int iClient;
	iClient  = GetClientOfUserId(GetEventInt(hEvent, "userid"));

	// if client has invalid index OR is NOT connected OR is NOT in-game OR is NOT alive.
	if (iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient) || !IsPlayerAlive(iClient))
	    return;  
     
	if(GetClientTeam(iClient) == TEAM_INFECTED)
	{
		switch (GetEntProp(iClient, Prop_Send, "m_zombieClass")) 
		{
			case ZOMBIECLASS_HUNTER:
			{
				switch(GetRandomInt(1,2)) 
				{
					case 1:
					{
						SetEntityModel(iClient, tinyhunter);	
					}
					case 2:
					{
						SetEntityModel(iClient, "models/infected/hunter.mdl");	
					}					
				}
			}
			case ZOMBIECLASS_BOOMER:
			{
				switch(GetRandomInt(1,2)) 
				{
					case 1:
					{
						SetEntityModel(iClient, tinyboomer);
					}
					case 2:
					{
						SetEntityModel(iClient, "models/infected/boomer.mdl");
					}
				}
			}
			case ZOMBIECLASS_SMOKER:
			{
				switch(GetRandomInt(1,2)) 
				{
					case 1:
					{
						SetEntityModel(iClient, tinysmoker);
					}
					case 2:
					{
						SetEntityModel(iClient, "models/infected/smoker.mdl");
					}
				}
			}
		}
	}
}
