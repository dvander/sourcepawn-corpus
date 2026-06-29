#include <sourcemod>
#include <tf2_stocks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.05"
#define TELEPORTER_ENTRANCE 1
#define TELEPORTER_EXIT 2

#define BOTH_TEAMS 1
#define RED_TEAM 2
#define BLU_TEAM 3

bool g_bMVM;
bool g_bCVEnabled;
bool g_bCVMVMSupported;
bool g_bCVConsumeMetal;
int g_iTeleportId[MAXPLAYERS+1];
int g_iOffsetForMatchingTeleporters;
int g_iCVTeam;
float g_fCVDelay;
Handle g_hTeleportBuilt[MAXPLAYERS+1];
Handle g_hBuildingStartUpgrading;

public Plugin myinfo =
{
	name = "Give Bots Teleporter Upgrades",
	author = "luki1412",
	description = "Gives TF2 bots teleporter upgrades",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/member.php?u=43109"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_TF2)
	{
		FormatEx(error, err_max, "This plugin only works for Team Fortress 2.");
		return APLRes_Failure;
	}

	return APLRes_Success;
}

public void OnPluginStart()
{
	ConVar hCVVersion = CreateConVar("sm_gbtu_version", PLUGIN_VERSION, "Give Bots Teleporter Upgrades version cvar", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	ConVar hCVEnabled = CreateConVar("sm_gbtu_enabled", "1", "Enables/disables this plugin", FCVAR_NONE, true, 0.0, true, 1.0);
	ConVar hCVDelay = CreateConVar("sm_gbtu_delay", "10.0", "Delay between upgrade attempts, starting when a bot teleporter is created", FCVAR_NONE, true, 1.0, true, 300.0);
	ConVar hCVTeam = CreateConVar("sm_gbtu_team", "1", "Team to give teleport upgrades to: 1-both, 2-red, 3-blu", FCVAR_NONE, true, 1.0, true, 3.0);
	ConVar hCVMVMSupported = CreateConVar("sm_gbtu_mvm", "0", "Enables/disables giving teleport upgrades when MVM mode is enabled", FCVAR_NONE, true, 0.0, true, 1.0);
	ConVar hCVConsumeMetal = CreateConVar("sm_gbtu_consumemetal", "1", "Enables/disables consuming full metal amount, needed for a level upgrade, at the teleporter upgrade time. The teleporter is not upgraded until the bot has enough metal.", FCVAR_NONE, true, 0.0, true, 1.0);

	OnEnabledChanged(hCVEnabled, "", "");
	HookConVarChange(hCVEnabled, OnEnabledChanged);
	OnMVMSupportedChanged(hCVMVMSupported, "", "");
	HookConVarChange(hCVMVMSupported, OnMVMSupportedChanged);
	OnDelayChanged(hCVDelay, "", "");
	HookConVarChange(hCVDelay, OnDelayChanged);
	OnTeamChanged(hCVTeam, "", "");
	HookConVarChange(hCVTeam, OnTeamChanged);
	OnTeamChanged(hCVConsumeMetal, "", "");
	HookConVarChange(hCVConsumeMetal, OnConsumeMetalChanged);
	SetConVarString(hCVVersion, PLUGIN_VERSION);
	AutoExecConfig(true, "Give_Bots_Teleport_Upgrades");
	GameData hGameConfig = LoadGameConfigFile("give.bots.stuff");

	if (!hGameConfig)
	{
		SetFailState("Failed to find give.bots.stuff.txt gamedata! Can't continue.");
	}

	g_iOffsetForMatchingTeleporters = GameConfGetOffset(hGameConfig, "MatchingTeleporter");
	StartPrepSDKCall(SDKCall_Entity);

	if (!PrepSDKCall_SetFromConf(hGameConfig, SDKConf_Virtual, "BuildingStartUpgrading"))
	{
		SetFailState("Failed to prepare the SDKCall for upgrading teleporters. Try updating gamedata or restarting your server.");
	}

	g_hBuildingStartUpgrading = EndPrepSDKCall();

	if (!g_hBuildingStartUpgrading)
	{
		SetFailState("Failed to prepare the SDKCall for upgrading teleporters. Try updating gamedata or restarting your server.");
	}

	delete hGameConfig;
	delete hCVVersion;
	delete hCVEnabled;
	delete hCVDelay;
	delete hCVTeam;
	delete hCVMVMSupported;
	delete hCVConsumeMetal;
}

public void OnEnabledChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (GetConVarBool(convar))
	{
		g_bCVEnabled = true;
		HookEvent("player_builtobject", player_builtobject);
		HookEvent("object_removed", object_removed);
	}
	else
	{
		g_bCVEnabled = false;
		UnhookEvent("player_builtobject", player_builtobject);
		UnhookEvent("object_removed", object_removed);

		for (int i = 0; i < (MAXPLAYERS+1); i++)
		{
			delete g_hTeleportBuilt[i];
			g_iTeleportId[i] = 0;
		}
	}
}

public void OnConsumeMetalChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bCVConsumeMetal = GetConVarBool(convar);
}

public void OnMVMSupportedChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bCVMVMSupported = GetConVarBool(convar);
}

public void OnDelayChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_fCVDelay = GetConVarFloat(convar);
}

public void OnTeamChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iCVTeam = GetConVarInt(convar);
}

public void OnMapStart()
{
	g_bMVM = GameRules_GetProp("m_bPlayingMannVsMachine") ? true : false;

	for (int i = 0; i < (MAXPLAYERS+1); i++)
	{
		delete g_hTeleportBuilt[i];
		g_iTeleportId[i] = 0;
	}
}

public void OnClientDisconnect(int client)
{
	delete g_hTeleportBuilt[client];
	g_iTeleportId[client] = 0;
}

public void player_builtobject(Handle event, const char[] name, bool dontBroadcast)
{
	if (!g_bCVEnabled || (g_bMVM && !g_bCVMVMSupported))
	{
		return;
	}

	int objectId = GetEventInt(event,"index");
	int objectType = GetEntProp(objectId, Prop_Send, "m_iObjectType");

	if (objectType != view_as<int>(TFObject_Teleporter))
	{
		return;
	}

	int teleType = GetEntProp(objectId, Prop_Data, "m_iTeleportType");

	if (teleType != TELEPORTER_ENTRANCE)
	{
		return;
	}

	int userId = GetEventInt(event,"userid");
	int client = GetClientOfUserId(userId);

	if (!IsPlayerHere(client) || !IsPlayerAllowed(client))
	{
		return;
	}

	g_hTeleportBuilt[client] = CreateTimer(g_fCVDelay, Timer_UpgradeTeleporter, userId, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
	g_iTeleportId[client] = EntIndexToEntRef(objectId);
}

public Action Timer_UpgradeTeleporter(Handle timer, any data)
{
	int client = GetClientOfUserId(data);

	if (!g_bCVEnabled || (g_bMVM && !g_bCVMVMSupported) || !IsPlayerHere(client))
	{
		g_hTeleportBuilt[client] = null;
		g_iTeleportId[client] = 0;
		return Plugin_Stop;
	}

	int objectId = EntRefToEntIndex(g_iTeleportId[client]);

	if (!IsValidEntity(objectId) || (objectId < 1))
	{
		g_hTeleportBuilt[client] = null;
		g_iTeleportId[client] = 0;
		return Plugin_Stop;
	}

	if ((GetEntProp(objectId, Prop_Send, "m_bBuilding") == 1) || (GetEntProp(objectId, Prop_Send, "m_bHasSapper") == 1) || (GetEntProp(objectId, Prop_Send, "m_bCarried") == 1) || (GetEntProp(objectId, Prop_Send, "m_bPlacing") == 1))
	{
		return Plugin_Continue;
	}

	int objectLevel = GetEntProp(objectId, Prop_Send, "m_iUpgradeLevel");
	int matchingTele = GetMatchingTeleporter(objectId);

	if (objectLevel < 3)
	{
		if (g_bCVConsumeMetal)
		{
			int clientMetal = GetEntProp(client, Prop_Data, "m_iAmmo", 4, 3);
			int metalSpent = GetEntProp(objectId, Prop_Send, "m_iUpgradeMetal");
			int metalTotalRequired = GetEntProp(objectId, Prop_Send, "m_iUpgradeMetalRequired");
			int metalCurrentlyRequired = metalTotalRequired - metalSpent;

			if (clientMetal >= metalCurrentlyRequired)
			{
				SetEntProp(client, Prop_Data, "m_iAmmo", (clientMetal-metalCurrentlyRequired), 4, 3);
				SetEntProp(objectId, Prop_Send, "m_iUpgradeMetal", 0);
				SDKCall(g_hBuildingStartUpgrading, objectId);
			}
		}
		else
		{
			SDKCall(g_hBuildingStartUpgrading, objectId);
		}
	}

	if (matchingTele > 0)
	{
		objectLevel = GetEntProp(objectId, Prop_Send, "m_iUpgradeLevel");
		int matchedTeleLevel = GetEntProp(matchingTele, Prop_Send, "m_iUpgradeLevel");

		if ((matchedTeleLevel != objectLevel) && (matchedTeleLevel < 3) && (GetEntProp(matchingTele, Prop_Send, "m_bHasSapper") != 1) && (GetEntProp(matchingTele, Prop_Send, "m_bCarried") != 1) && (GetEntProp(matchingTele, Prop_Send, "m_bPlacing") != 1))
		{
			SetEntProp(matchingTele, Prop_Send, "m_iUpgradeMetal", 0);

			if (GetEntProp(matchingTele, Prop_Send, "m_bBuilding") == 1)
			{
				SetEntProp(matchingTele, Prop_Send, "m_iUpgradeLevel",objectLevel);
				SetEntProp(matchingTele, Prop_Send, "m_iHighestUpgradeLevel",objectLevel);
			}
			else
			{
				SDKCall(g_hBuildingStartUpgrading, matchingTele);
			}
		}
	}

	return Plugin_Continue;
}

public void object_removed(Handle event, const char[] name, bool dontBroadcast)
{
	if (!g_bCVEnabled || (g_bMVM && !g_bCVMVMSupported))
	{
		return;
	}

	int objectId = GetEventInt(event, "index");
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int storedObjectId = EntRefToEntIndex(g_iTeleportId[client]);

	if (storedObjectId == objectId)
	{
		delete g_hTeleportBuilt[client];
		g_iTeleportId[client] = 0;
	}
}

int GetMatchingTeleporter(int ent)
{
	int matchingTeleporter = -1;

	if (IsValidEntity(ent) && HasEntProp(ent, Prop_Send, "m_bMatchBuilding"))
	{
		int offset = FindSendPropInfo("CObjectTeleporter", "m_bMatchBuilding") + g_iOffsetForMatchingTeleporters;
		matchingTeleporter = GetEntDataEnt2(ent, offset);
	}

	return matchingTeleporter;
}

bool IsPlayerHere(int client)
{
	return (client && IsClientInGame(client) && IsFakeClient(client) && !IsClientReplay(client) && !IsClientSourceTV(client));
}

bool IsPlayerAllowed(int client)
{
	return ((g_iCVTeam == BOTH_TEAMS) || (GetClientTeam(client) == g_iCVTeam) ? true : false);
}