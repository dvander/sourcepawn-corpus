#include <sourcemod>
#include <tf2_stocks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.00"

bool g_bTouched[MAXPLAYERS+1] = false;
ConVar g_hCVTimer;
ConVar g_hCVEnabled;
Handle g_hWearableEquip;
Handle g_hGameConfig;

public Plugin myinfo = 
{
	name = "Give Bots Cosmetics",
	author = "luki1412",
	description = "Gives all TF2 bots cosmetics",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/member.php?u=43109"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
	char Game[32];
	GetGameFolderName(Game, sizeof(Game));
	
	if (!StrEqual(Game, "tf") && !StrEqual(Game, "tf_beta")) 
	{
		Format(error, err_max, "This plugin only works for TF2 or TF2 Beta.");
		return APLRes_Failure;
	}
	
	return APLRes_Success;
}

public void OnPluginStart() 
{
	ConVar versioncvar = CreateConVar("sm_gbc_version", PLUGIN_VERSION, "Give Bots Gibus version cvar", FCVAR_NOTIFY|FCVAR_DONTRECORD); 
	g_hCVEnabled = CreateConVar("sm_gbc_enabled", "1", "Enables/Disables this plugin", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hCVTimer = CreateConVar("sm_gbc_delay", "2.0", "Delay for giving cosmetics to bots", FCVAR_NONE, true, 0.1, true, 30.0);

	HookEvent("post_inventory_application", player_inv);
	
	SetConVarString(versioncvar, PLUGIN_VERSION);
	AutoExecConfig(true, "Give_Bots_Cosmetics");
	
	g_hGameConfig = LoadGameConfigFile("give.bots.cosmetics");
	
	if (!g_hGameConfig)
	{
		SetFailState("Failed to find give.bots.cosmetics.txt gamedata! Can't continue.");
	}	
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(g_hGameConfig, SDKConf_Virtual, "EquipWearable");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hWearableEquip = EndPrepSDKCall();
	
	if (!g_hWearableEquip)
	{
		SetFailState("Failed to prepare the SDKCall for giving cosmetics. Try updating gamedata or restarting your server.");
	}
}

public void player_inv(Handle event, const char[] name, bool dontBroadcast) 
{
	if (!GetConVarInt(g_hCVEnabled))
	{
		return;
	}

	int userd = GetEventInt(event, "userid");
	int client = GetClientOfUserId(userd);
	
	if (!g_bTouched[client] && IsPlayerHere(client))
	{
		g_bTouched[client] = true;
		CreateTimer(GetConVarFloat(g_hCVTimer), Timer_GiveHat, userd, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Timer_GiveHat(Handle timer, any data)
{
	int client = GetClientOfUserId(data);
	g_bTouched[client] = false;
	
	if (!GetConVarInt(g_hCVEnabled))
	{
		return;
	}
	
	if (IsPlayerHere(client))
	{
		int rnd = GetRandomInt(0,6);
		
		switch (rnd)
		{
			case 1:
			{
				CreateHat(client, 341, 10, 6);    //快樂樹A Rather Festive Tree 
			}
			case 2:
			{
				CreateHat(client, 668, 10, 6);     //343 賞金帽 Bounty Hat
			}
			case 3:
			{
				CreateHat(client, 774, 10, 6);
			}
			case 4:
			{
				CreateHat(client, 941, 10, 6);			
			}
			case 5:
			{
				CreateHat(client, 537, 10, 6);			 //287 Spine-Chilling Skull 毛骨悚然的骷髏	
			}
			case 6:
			{
				CreateHat(client, 302, 10, 6);   //Frontline Field Recorder 
			}			
		}
		//135 Towering Pillar of Hats 帽子塔
		//634 Point and Shoot 法師帽
		//278 Horseless Headless Horsemann's Head 無頭騎士帽子
		//30313 The Kiss King  聖誕帽子
		int rnd2 = GetRandomInt(0,2);
		switch (rnd2)
		{
			case 1:
			{
				CreateHat(client, 343, 10, 6);
			}
			case 2:
			{
				CreateHat(client, 744, 10, 6);
			}			
		}		
		
		int rnd3 = GetRandomInt(0,3);
		switch (rnd3)
		{
			case 1:
			{
				CreateHat(client, 166, 10, 6);  //幽靈大禮帽 Ghastly Gibus 
			}
			case 2:
			{
				CreateHat(client, 583, 10, 6);  //Bombnomicon 
			}
			case 3:
			{
				CreateHat(client, 655, 10, 4);  //奉獻之心 Spirit Of Giving
			}
		}
	}	
}

bool CreateHat(int client, int itemindex, int level, int quality)
{
	int hat = CreateEntityByName("tf_wearable");
	
	if(!IsValidEntity(hat))
	{
		return false;
	}
	
	char entclass[64];
	GetEntityNetClass(hat, entclass, sizeof(entclass));
	SetEntData(hat, FindSendPropInfo(entclass, "m_iItemDefinitionIndex"), itemindex);	
	SetEntData(hat, FindSendPropInfo(entclass, "m_iEntityLevel"), level);
	SetEntData(hat, FindSendPropInfo(entclass, "m_iEntityQuality"), quality);
	SetEntData(hat, FindSendPropInfo(entclass, "m_bInitialized"), 1); 
	
	DispatchSpawn(hat);
	SDKCall(g_hWearableEquip, client, hat);
	return true;
} 

bool IsPlayerHere(int client)
{
	return (IsClientConnected(client) && IsClientInGame(client) && IsFakeClient(client));
}
