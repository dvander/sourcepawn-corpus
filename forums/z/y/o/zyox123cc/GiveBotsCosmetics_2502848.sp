#include <sourcemod>
#include <tf2_stocks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.04"

bool g_bTouched[MAXPLAYERS+1] = false;
bool g_bMVM = false;
bool g_bLateLoad = false;
ConVar g_hCVTimer;
ConVar g_hCVEnabled;
Handle g_hWearableEquip;
Handle g_hGameConfig;

public Plugin myinfo = 
{
	name = "Give Bots Cosmetics",
	author = "luki1412",
	description = "Gives TF2 bots cosmetics",
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
	
	g_bLateLoad = late;
	return APLRes_Success;
}

public void OnPluginStart() 
{
	ConVar versioncvar = CreateConVar("sm_gbc_version", PLUGIN_VERSION, "Give Bots Cosmetics version cvar", FCVAR_NOTIFY|FCVAR_DONTRECORD); 
	g_hCVEnabled = CreateConVar("sm_gbc_enabled", "1", "Enables/disables this plugin", FCVAR_NONE, true, 0.0, true, 1.0);
	g_hCVTimer = CreateConVar("sm_gbc_delay", "0.1", "Delay for giving cosmetics to bots", FCVAR_NONE, true, 0.1, true, 30.0);

	HookEvent("post_inventory_application", player_inv);
	HookConVarChange(g_hCVEnabled, OnEnabledChanged);
	
	SetConVarString(versioncvar, PLUGIN_VERSION);
	AutoExecConfig(true, "Give_Bots_Cosmetics");

	if (g_bLateLoad)
	{
		OnMapStart();
	}
	
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

public void OnEnabledChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (GetConVarBool(g_hCVEnabled))
	{
		HookEvent("post_inventory_application", player_inv);
	}
	else
	{
		UnhookEvent("post_inventory_application", player_inv);
	}
}

public void OnMapStart()
{
	if (GameRules_GetProp("m_bPlayingMannVsMachine"))
	{
		g_bMVM = true;
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
	
	if (!g_bMVM && !g_bTouched[client] && IsPlayerHere(client))
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
	
	if (!g_bMVM && IsPlayerHere(client))
	{
		bool face = false;
	
		int rnd = GetRandomUInt(0,25);
		switch (rnd)
		{
			case 1:
			{
				CreateHat(client, 940, 10, 6);
			}
			case 2:
			{
				CreateHat(client, 940, 10, 6);
			}
			case 3:
			{
				CreateHat(client, 940, 10, 6);
			}
			case 4:
			{
				CreateHat(client, 940, 10, 6);
			}
			case 5:
			{
				CreateHat(client, 940, 10, 6);
			}
			case 6:
			{
				CreateHat(client, 940, 10, 6);
			}
			case 7:
			{
				CreateHat(client, 940, 10, 6);
			}
			case 8:
			{
				CreateHat(client, 940, 10, 6);
			}
			case 9:
			{
				CreateHat(client, 940, 10, 6);
			}
			case 10:
			{
				CreateHat(client, 940, 10, 6);
			}
			case 11:
			{
				CreateHat(client, 940, 10, 6);
			}
			case 12:
			{
				CreateHat(client, 940, 10, 6);
			}
			case 13:
			{
				CreateHat(client, 940, 10, 6);
			}
			case 14:
			{
				CreateHat(client, 940, 10, 6);
			}
			case 15:
			{
				CreateHat(client, 940, 10, 6);
			}
			case 16:
			{
				CreateHat(client, 940, 10, 6);
			}
			case 17:
			{
				CreateHat(client, 940, 10, 6);
			}
			case 18:
			{
				CreateHat(client, 940, 10, 6);
			}
			case 19:
			{
				CreateHat(client, 940, 10, 6);
			}
			case 20:
			{
				CreateHat(client, 940, 10, 6);
			}
			case 21:
			{
				CreateHat(client, 940, 10, 6);
			}
			case 22:
			{
				CreateHat(client, 940, 10, 6);
			}
			case 23:
			{
				CreateHat(client, 940, 10, 6);
			}
			case 24:
			{
				CreateHat(client, 940, 10, 6);
			}
			case 25:
			{
				CreateHat(client, 940, 10, 6);
			}
		}
		
		if ( !face )
		{
			int rnd2 = GetRandomUInt(0,10);
			switch (rnd2)
			{
				case 1:
				{
					CreateHat(client, 744, 10, 6);
				}	
                case 2:
				{
					CreateHat(client, 744, 10, 6);
				}	
				case 3:
				{
					CreateHat(client, 744, 10, 6);
				}
				case 4:
				{
					CreateHat(client, 744, 10, 6);
				}
				case 5:
				{
					CreateHat(client, 744, 10, 6);
				}
				case 6:
				{
					CreateHat(client, 744, 10, 6);
				}
				case 7:
				{
					CreateHat(client, 744, 10, 6);
				}
				case 8:
				{
					CreateHat(client, 744, 10, 6);
				}
				case 9:
				{
					CreateHat(client, 744, 10, 6);
				}
				case 10:
				{
					CreateHat(client, 744, 10, 6);
				}
			}
		}
		
		int rnd3 = GetRandomUInt(0,16);
		switch (rnd3)
		{
			case 1:
			{
				CreateHat(client, 30706, 10, 6);
			}
			case 2:
			{
				CreateHat(client, 30706, 10, 6);
			}
			case 3:
			{
				CreateHat(client, 30706, 10, 6);
			}
			case 4:
			{
				CreateHat(client, 30706, 10, 6);
			}
			case 5:
			{
				CreateHat(client, 30706, 10, 6);
			}
			case 6:
			{
				CreateHat(client, 30706, 10, 6);
			}
			case 7:
			{
				CreateHat(client, 30706, 10, 6);
			}
			case 8:
			{
				CreateHat(client, 30706, 10, 6);
			}
			case 9:
			{
				CreateHat(client, 30706, 10, 6);
			}
			case 10:
			{
				CreateHat(client, 30706, 10, 6);
			}
			case 11:
			{
				CreateHat(client, 30706, 10, 6);
			}
			case 12:
			{
				CreateHat(client, 30706, 10, 6);
			}
			case 13:
			{
				CreateHat(client, 30706, 10, 6);
			}
			case 14:
			{
				CreateHat(client, 30706, 10, 6);
			}
			case 15:
			{
				CreateHat(client, 30706, 10, 6);
			}
			case 16:
			{
				CreateHat(client, 30706, 10, 6);
			}
		}
	}	
}

bool CreateHat(int client, int itemindex, int level, int quality)
{
	int hat = CreateEntityByName("tf_wearable");
	
	if (!IsValidEntity(hat))
	{
		return false;
	}
	
	char entclass[64];
	GetEntityNetClass(hat, entclass, sizeof(entclass));
	SetEntData(hat, FindSendPropInfo(entclass, "m_iItemDefinitionIndex"), itemindex);
	SetEntData(hat, FindSendPropInfo(entclass, "m_bInitialized"), 1); 	
	SetEntData(hat, FindSendPropInfo(entclass, "m_iEntityLevel"), level);
	SetEntData(hat, FindSendPropInfo(entclass, "m_iEntityQuality"), quality);
	
	DispatchSpawn(hat);
	SDKCall(g_hWearableEquip, client, hat);
	return true;
} 

bool IsPlayerHere(int client)
{
	return (client && IsClientInGame(client) && IsFakeClient(client));
}

int GetRandomUInt(int min, int max)
{
	return RoundToFloor(GetURandomFloat() * (max - min + 1)) + min;
}