#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR	"TheDarkSid3r edit by RavensBro"
#define PLUGIN_VERSION	"2.0-beta"

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <tf2items>
#include <tf2items_giveweapon>
#include <sdkhooks>
#include <steamtools>

#pragma newdecls required

Handle g_hEnabled;
Handle g_hAlienTeam;
Handle g_hMeleeOnly;
Handle g_hMedieval;

bool g_bMeleeOnly;
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
	CreateConVar("tf_medieval", "1", "1 - Enable Medieval while 0 disables!", FCVAR_NONE, true, 0.0, true, 1.0);
	
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
	PrecacheModel("models/aliensvspredators/alien/alien.mdl");
	PrecacheModel("models/aliensvspredators/predator/predator.mdl");
	
	//Models
	//Aliens Models
	AddFileToDownloadsTable("models/aliensvspredators/alien/alien.dx80.vtx");
	AddFileToDownloadsTable("models/aliensvspredators/alien/alien.dx90.vtx");
	AddFileToDownloadsTable("models/aliensvspredators/alien/alien.mdl");
	AddFileToDownloadsTable("models/aliensvspredators/alien/alien.sw.vtx");
	AddFileToDownloadsTable("models/aliensvspredators/alien/alien.vvd");
	//Predators Models
	AddFileToDownloadsTable("models/aliensvspredators/predator/predator.dx80.vtx");
	AddFileToDownloadsTable("models/aliensvspredators/predator/predator.dx90.vtx");
	AddFileToDownloadsTable("models/aliensvspredators/predator/predator.mdl");
	AddFileToDownloadsTable("models/aliensvspredators/predator/predator.phy");
	AddFileToDownloadsTable("models/aliensvspredators/predator/predator.sw.vtx");
	AddFileToDownloadsTable("models/aliensvspredators/predator/predator.vvd");
	
	//Materials
	//Aliens Materials
	AddFileToDownloadsTable("materials/aliensvspredators/alien/drone_arms.vmt");
	AddFileToDownloadsTable("materials/aliensvspredators/alien/drone_arms.vtf");
	AddFileToDownloadsTable("materials/aliensvspredators/alien/drone_head.vmt");
	AddFileToDownloadsTable("materials/aliensvspredators/alien/drone_head.vtf");
	AddFileToDownloadsTable("materials/aliensvspredators/alien/drone_legs.vmt");
	AddFileToDownloadsTable("materials/aliensvspredators/alien/drone_legs.vtf");
	AddFileToDownloadsTable("materials/aliensvspredators/alien/drone_torso.vmt");
	AddFileToDownloadsTable("materials/aliensvspredators/alien/drone_torso.vtf");
	//Predators Materials
	AddFileToDownloadsTable("materials/aliensvspredators/predator/alphatest.vmt");
	AddFileToDownloadsTable("materials/aliensvspredators/predator/pred_body.vmt");
	AddFileToDownloadsTable("materials/aliensvspredators/predator/pred_body.vtf");
	AddFileToDownloadsTable("materials/aliensvspredators/predator/pred_body_n.vtf");
	AddFileToDownloadsTable("materials/aliensvspredators/predator/pred_body_spec.vtf");
	AddFileToDownloadsTable("materials/aliensvspredators/predator/pred_face.vtf");
	AddFileToDownloadsTable("materials/aliensvspredators/predator/pred_face.vmt");
	AddFileToDownloadsTable("materials/aliensvspredators/predator/pred_gear.vmt");
	AddFileToDownloadsTable("materials/aliensvspredators/predator/pred_gear.vtf");
	AddFileToDownloadsTable("materials/aliensvspredators/predator/pred_gear_n.vtf");
	AddFileToDownloadsTable("materials/aliensvspredators/predator/pred_gear_spec.vtf");
	AddFileToDownloadsTable("materials/aliensvspredators/predator/pred_mask.vmt");
	AddFileToDownloadsTable("materials/aliensvspredators/predator/pred_mask.vtf");
	AddFileToDownloadsTable("materials/aliensvspredators/predator/pred_mask_n.vtf");
	AddFileToDownloadsTable("materials/aliensvspredators/predator/pred_mask_spec.vtf");
}

public void SetAlienModel(int i)
{
	SetVariantString("models/aliensvspredators/alien/alien.mdl");
	AcceptEntityInput(i, "SetCustomModel");
	SetEntProp(i, Prop_Send, "m_bUseClassAnimations",1);
	SetEntProp(i, Prop_Send, "m_nBody", 0);
	
	SetClientClass(i, "scout");
	TF2Items_GiveWeapon(i, 0);	
}

public void SetPredModel(int i)
{
	SetVariantString("models/aliensvspredators/predator/predator.mdl");
	AcceptEntityInput(i, "SetCustomModel");
	SetEntProp(i, Prop_Send, "m_bUseClassAnimations",1);
	SetEntProp(i, Prop_Send, "m_nBody", 0);

	SetClientClass(i, "spy");
	TF2Items_GiveWeapon(i, 4);
	//TF2Items_GiveWeapon(i, 30);	
}

public void RoundStart(Event event,const char[] name,bool dontBroadcast)
{
	g_bEnabled = GetConVarBool(g_hEnabled);
	
	int i;
	if (g_bEnabled)
	{
		SetMeleeMode();
		for (i = 1; i<=MaxClients; i++)
		{
		    if(IsClientInGame(i) && IsPlayerAlive(i))			
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
						SetPredatorClass(i);
					}
					else
					{
						SetAlienClass(i);
					}
				}
			}
		}
	}
}

int SetClientClass(int i, char tfclass[128])
{
	if (IsClientInGame(i) && (IsPlayerAlive(i)))
	{
		TFClassType input = TFClass_Scout;
		if (StrEqual(tfclass,"soldier")) input = TFClass_Soldier;
		if (StrEqual(tfclass,"spy")) input = TFClass_Spy;
		if (StrEqual(tfclass,"demoman")) input = TFClass_DemoMan;
		if (StrEqual(tfclass,"sniper")) input = TFClass_Sniper;
		if (StrEqual(tfclass,"medic")) input = TFClass_Medic;
		if (StrEqual(tfclass,"engineer")) input = TFClass_Engineer;
		if (StrEqual(tfclass,"heavy")) input = TFClass_Heavy;
		if (StrEqual(tfclass,"pyro")) input = TFClass_Pyro;
		if (IsClientInGame(i)){
			if (TF2_GetPlayerClass(i) != input)
			{
				TF2_SetPlayerClass(i, input);
				SetVariantString("");
				AcceptEntityInput(i, "SetCustomModel");
			}
			if(TF2_IsPlayerInCondition(i, TFCond_Taunting))
			{
				TF2_RemoveCondition(i, TFCond_Taunting);
			}
		}
	}
}

public void SetMeleeMode()
{
	GameRules_SetProp("m_bPlayingMedieval", 1);	
	g_bMeleeOnly = GetConVarBool(g_hMeleeOnly);	
	SetConVarBool(g_hMedieval, g_bMeleeOnly, false, false);
}

void SetPredatorClass(int i)
{
	TF2_SetPlayerClass(i, TFClass_Spy, false, TF2_GetPlayerClass(i) != TFClass_Spy);
	SetPredModel(i);
}

void SetAlienClass(int i)
{
	TF2_SetPlayerClass(i, TFClass_Scout, false, TF2_GetPlayerClass(i) != TFClass_Scout);	
	SetAlienModel(i);
}

public void ConVarAVP_Enable(Handle convar, const char[] oldValue, const char[] newValue)
{
	g_bEnabled = GetConVarBool(g_hEnabled);
	LogMessage("---%s Aliens Vs Predators(v%s)---", g_bEnabled ? "Enabled" : "Disabled", PLUGIN_VERSION);
}