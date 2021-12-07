#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR	"TheDarkSid3r"
#define PLUGIN_VERSION	"1.16-Beta"

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>
#include <steamtools>

#pragma newdecls required

Handle g_hEnabled;
Handle g_hAlienTeam;
Handle g_hMeleeOnly;
Handle g_hMedieval;

//bool g_bMeleeOnly;
bool g_bEnabled;

public Plugin myinfo =
{
	name = "Aliens Vs Predators",
	author = PLUGIN_AUTHOR,
	description = "Aliens Vs Predators",
	version = PLUGIN_VERSION,
	url = ""
};

public APLRes AskPluginLoad2(Handle myself,bool late,char[] error,int err_max)
{
	if (GetEngineVersion() != Engine_TF2)
	{
		Format(error, err_max, "This plugin only currently works in Team Fortress 2!");
		return APLRes_Failure;
	}

	return APLRes_Success;
}

public void OnPluginStart()
{
	LogMessage("---Initializing Aliens Vs Predators(v%s)---", PLUGIN_VERSION);
	
	LogMessage("---Initializing ConVars(Aliens Vs Predators)---");
	
	CreateConVar("avp_enabled", "1", "1 - Enable Aliens Vs Predators while 0 disables!", FCVAR_NONE, true, 0.0, true, 1.0);
	CreateConVar("avp_alien_team", "1", "Team for Aliens,1 is Red and 0 is Blue", FCVAR_NONE, true, 0.0, true, 1.0);
	CreateConVar("avp_meleeonly", "1", "Melee Only.1 is true and 0 is false", FCVAR_NONE, true, 0.0, true, 1.0);
	
	g_hEnabled = FindConVar("avp_enabled");
	g_hAlienTeam = FindConVar("avp_alien_team");
	g_hMeleeOnly = FindConVar("avp_meleeonly");
	g_hMedieval = FindConVar("tf_medieval");
	
	HookConVarChange(g_hEnabled, ConVarAVP_Enable);
	
	LogMessage("---Initializing Other Stuffs(Aliens Vs Predators)---");
	
	InitPrecache();
	
	LogMessage("---Initializing Events(Aliens Vs Predators)---");
	
	HookEvent("teamplay_round_start", RoundStart);
	HookEvent("player_spawn", RoundStart);
	
	LogMessage("---Initialization Complete(Aliens Vs Predators)---");
	
	Steam_SetGameDescription("Aliens Vs Predators");
}

public void InitPrecache()
{
	//Precaching Models
	PrecacheModel("models/aliensvspredators/aliens/aliens.mdl");
	PrecacheModel("models/aliensvspredators/predators/predator1.mdl");
	
	//Models
	//Aliens Models
	AddFileToDownloadsTable("models/aliensvspredators/aliens/aliens.dx80.vtx");
	AddFileToDownloadsTable("models/aliensvspredators/aliens/aliens.dx90.vtx");
	AddFileToDownloadsTable("models/aliensvspredators/aliens/aliens.mdl");
	AddFileToDownloadsTable("models/aliensvspredators/aliens/aliens.sw.vtx");
	AddFileToDownloadsTable("models/aliensvspredators/aliens/aliens.vvd");
	AddFileToDownloadsTable("models/aliensvspredators/aliens/alien3.dx80.vtx");
	//Predators Models
	AddFileToDownloadsTable("models/aliensvspredators/predators/predator1.dx80.vtx");
	AddFileToDownloadsTable("models/aliensvspredators/predators/predator1.dx90.vtx");
	AddFileToDownloadsTable("models/aliensvspredators/predators/predator1.mdl");
	AddFileToDownloadsTable("models/aliensvspredators/predators/predator1.phy");
	AddFileToDownloadsTable("models/aliensvspredators/predators/predator1.sw.vtx");
	AddFileToDownloadsTable("models/aliensvspredators/predators/predator1.vvd");
	
	//Materials
	//Aliens Materials
	AddFileToDownloadsTable("materials/aliensvspredators/aliens/head.vmt");
	AddFileToDownloadsTable("materials/aliensvspredators/aliens/head_n.vtf");
	AddFileToDownloadsTable("materials/aliensvspredators/aliens/legs.vmt");
	AddFileToDownloadsTable("materials/aliensvspredators/aliens/legs_n.vtf");
	AddFileToDownloadsTable("materials/aliensvspredators/aliens/torso.vmt");
	AddFileToDownloadsTable("materials/aliensvspredators/aliens/torso.vtf");
	AddFileToDownloadsTable("materials/aliensvspredators/aliens/torso_n.vtf");
	AddFileToDownloadsTable("materials/aliensvspredators/aliens/alien_egg.vmt");
	AddFileToDownloadsTable("materials/aliensvspredators/aliens/alien_egg.vtf");
	AddFileToDownloadsTable("materials/aliensvspredators/aliens/alien_egg_norm.vtf");
	AddFileToDownloadsTable("materials/aliensvspredators/aliens/drone_arms.vmt");
	AddFileToDownloadsTable("materials/aliensvspredators/aliens/drone_arms.vtf");
	AddFileToDownloadsTable("materials/aliensvspredators/aliens/drone_head.vmt");
	AddFileToDownloadsTable("materials/aliensvspredators/aliens/drone_head.vtf");
	AddFileToDownloadsTable("materials/aliensvspredators/aliens/drone_legs.vmt");
	AddFileToDownloadsTable("materials/aliensvspredators/aliens/drone_legs.vtf");
	AddFileToDownloadsTable("materials/aliensvspredators/aliens/drone_torso.vmt");
	AddFileToDownloadsTable("materials/aliensvspredators/aliens/drone_torso.vtf");
	//Predators Materials
	AddFileToDownloadsTable("materials/aliensvspredators/predators/alphatest.vmt");
	AddFileToDownloadsTable("materials/aliensvspredators/predators/pred_body.vmt");
	AddFileToDownloadsTable("materials/aliensvspredators/predators/pred_body.vtf");
	AddFileToDownloadsTable("materials/aliensvspredators/predators/pred_body_n.vtf");
	AddFileToDownloadsTable("materials/aliensvspredators/predators/pred_body_spec.vtf");
	AddFileToDownloadsTable("materials/aliensvspredators/predators/pred_face.vtf");
	AddFileToDownloadsTable("materials/aliensvspredators/predators/pred_face.vmt");
	AddFileToDownloadsTable("materials/aliensvspredators/predators/pred_gear.vmt");
	AddFileToDownloadsTable("materials/aliensvspredators/predators/pred_gear.vtf");
	AddFileToDownloadsTable("materials/aliensvspredators/predators/pred_gear_n.vtf");
	AddFileToDownloadsTable("materials/aliensvspredators/predators/pred_gear_spec.vtf");
	AddFileToDownloadsTable("materials/aliensvspredators/predators/pred_mask.vmt");
	AddFileToDownloadsTable("materials/aliensvspredators/predators/pred_mask.vtf");
	AddFileToDownloadsTable("materials/aliensvspredators/predators/pred_mask_n.vtf");
	AddFileToDownloadsTable("materials/aliensvspredators/predators/pred_mask_spec.vtf");
}

public void SetAlienModel(int client)
{
	SetVariantString("models/aliensvspredators/aliens/aliens.mdl");
	AcceptEntityInput(client, "SetCustomModel");
}

public void SetPredModel(int client)
{
	SetVariantString("models/aliensvspredators/predators/predator1.mdl");
	AcceptEntityInput(client, "SetCustomModel");
}

public Action RoundStart(Event event,const char[] name,bool dontBroadcast)
{
	g_bEnabled = GetConVarBool(g_hEnabled);
	
	int i;
	if (g_bEnabled)
	{
		SetMeleeMode();
		for (i = 1; i <= MAXPLAYERS; i++)
		{
			if (IsClientInGame(i) && IsPlayerAlive(i))
			{
				TFTeam team = TF2_GetClientTeam(i);
		
				if (GetConVarBool(g_hAlienTeam))
				{
					if (team == TFTeam_Red) 
					{
						SetAlienClass(i);
					}
					else
					{
						SetPredatorClass(i);
					}
				}
				else
				{
					if (team == TFTeam_Blue)
					{
						SetAlienClass(i);
					}
					else
					{
						SetPredatorClass(i);
					}
				}
			}
		}
		i = 1;
	}
}

public void SetMeleeMode()
{
	SetConVarInt(g_hMedieval, GetConVarInt(g_hMeleeOnly), false, false);
}

void SetPredatorClass(int client)
{
	TF2_SetPlayerClass(client, TFClass_Spy, false, TF2_GetPlayerClass(client) != TFClass_Spy);
	SetPredModel(client);
}

void SetAlienClass(int client)
{
	TF2_SetPlayerClass(client, TFClass_Scout, false, TF2_GetPlayerClass(client) != TFClass_Scout);
	SetAlienModel(client);
}

public void ConVarAVP_Enable(Handle convar, const char[] oldValue, const char[] newValue)
{
	g_bEnabled = GetConVarBool(g_hEnabled);
	LogMessage("---%s Aliens Vs Predators(v%s)---", g_bEnabled ? "Enabled" : "Disabled", PLUGIN_VERSION);
}