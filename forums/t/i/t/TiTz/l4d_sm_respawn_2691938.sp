#include <sourcemod>
#include <sdktools>
#pragma semicolon 1
#pragma newdecls required
#define PLUGIN_VERSION "1.9.5"

public Plugin myinfo =
{
	name = "[L4D & L4D2] SM Respawn",
	author = "AtomicStryker & Ivailosp (Modified by Psyk0tik)",
	description = "Allows players to be respawned at one's crosshair.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=96249"
};

ConVar g_cvLoadout;
float g_flPosition[3];
Handle g_hSDKRespawnPlayer;
Handle g_hSDKGhostPlayer;
Handle g_hSDKStateTransition;
Handle g_hGameData;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion evEngine = GetEngineVersion();
	if (evEngine != Engine_Left4Dead && evEngine != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "SM Respawn only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	RegAdminCmd("sm_respawn", cmdRespawn, ADMFLAG_BAN, "Respawn a player at your crosshair.");
	g_cvLoadout = CreateConVar("l4d_sm_respawn_loadout", "smg,pistol,pain_pills", "Respawn players with this loadout.");
	CreateConVar("l4d_sm_respawn_version", PLUGIN_VERSION, "SM Respawn Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	if (bIsL4D2Game())
	{
		HookEvent("dead_survivor_visible", eDeadSurvivorVisible);
	}
	g_hGameData = LoadGameConfigFile("l4drespawn");
	if (g_hGameData != null)
	{
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(g_hGameData, SDKConf_Signature, "RoundRespawn");
		g_hSDKRespawnPlayer = EndPrepSDKCall();
		if (g_hSDKRespawnPlayer == null)
		{
			SetFailState("L4D_SM_Respawn: RoundRespawn Signature broken");
		}
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(g_hGameData, SDKConf_Signature, "BecomeGhost");
		PrepSDKCall_AddParameter(SDKType_PlainOldData , SDKPass_Plain);
		g_hSDKGhostPlayer = EndPrepSDKCall();
		if (g_hSDKGhostPlayer == null && bIsL4D2Game())
		{
			LogError("L4D_SM_Respawn: BecomeGhost Signature broken");
		}
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(g_hGameData, SDKConf_Signature, "State_Transition");
		PrepSDKCall_AddParameter(SDKType_PlainOldData , SDKPass_Plain);
		g_hSDKStateTransition = EndPrepSDKCall();
		if (g_hSDKStateTransition == null && bIsL4D2Game())
		{
			LogError("L4D_SM_Respawn: State_Transition Signature broken");
		}
	}
	else
	{
		SetFailState("Could not find gamedata file at addons/sourcemod/gamedata/l4drespawn.txt , you FAILED AT INSTALLING");
	}
	AutoExecConfig(true, "l4d_sm_respawn");
}

public Action eDeadSurvivorVisible(Event event, const char[] name, bool dontBroadcast)
{
	int iDeadBody = event.GetInt("subject");
	int iDeadPlayer = GetClientOfUserId(event.GetInt("deadplayer"));
	if (IsFakeClient(iDeadPlayer))
	{
		return Plugin_Continue;
	}
	else if (GetClientTeam(iDeadPlayer) != 2)
	{
		return Plugin_Continue;
	}
	else if (IsPlayerAlive(iDeadPlayer))
	{
		AcceptEntityInput(iDeadBody, "Kill");
	}
	return Plugin_Continue;
}

public Action cmdRespawn(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_respawn <player1> [player2] ... [playerN] - respawn all listed players");
		return Plugin_Handled;
	}
	char arg1[MAX_TARGET_LENGTH];
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS];
	int target_count;
	bool tn_is_ml;
	GetCmdArg(1, arg1, sizeof(arg1));
	if ((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, 0, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	for (int i = 0; i < target_count; i++)
	{
		vRespawnPlayer(client, target_list[i]);
	}
	ShowActivity2(client, "[SM] ", "Respawned target '%s'", target_name);
	return Plugin_Handled;
}

void vRespawnPlayer(int client, int target)
{
	switch (GetClientTeam(target))
	{
		case 2:
		{
			bool bCanTeleport = bSetTeleportEndPoint(client);
			SDKCall(g_hSDKRespawnPlayer, target);
			char sLoadout[512];
			g_cvLoadout.GetString(sLoadout, sizeof(sLoadout));
			char sItems[5][64];
			ExplodeString(sLoadout, ",", sItems, sizeof(sItems), sizeof(sItems[]));
			for (int iItem = 0; iItem < sizeof(sItems); iItem++)
			{
				if (StrContains(sLoadout, sItems[iItem], false) != -1 && sItems[iItem][0] != '\0')
				{
					vCheatCommand(target, "give", sItems[iItem]);
				}
			}
			if (bCanTeleport)
			{
				vPerformTeleport(client, target, g_flPosition);
			}
		}
		case 3:
		{
			if (bIsL4D2Game())
			{
				SDKCall(g_hSDKStateTransition, target, 8);
				SDKCall(g_hSDKGhostPlayer, target, 1);
				SDKCall(g_hSDKStateTransition, target, 6);
				SDKCall(g_hSDKGhostPlayer, target, 1);
			}
		}
	}
}

public bool bTraceEntityFilterPlayer(int entity, int contentsMask)
{
	return (entity > MaxClients || !entity);
}

bool bIsL4D2Game()
{
	return GetEngineVersion() == Engine_Left4Dead2;
}

bool bSetTeleportEndPoint(int client)
{
	float flAngles[3];
	float flOrigin[3];
	GetClientEyePosition(client,flOrigin);
	GetClientEyeAngles(client, flAngles);
	Handle hTrace = TR_TraceRayFilterEx(flOrigin, flAngles, MASK_SHOT, RayType_Infinite, bTraceEntityFilterPlayer);
	if (TR_DidHit(hTrace))
	{
		float flBuffer[3];
		float flStart[3];
		TR_GetEndPosition(flStart, hTrace);
		GetVectorDistance(flOrigin, flStart, false);
		float flDistance = -35.0;
		GetAngleVectors(flAngles, flBuffer, NULL_VECTOR, NULL_VECTOR);
		g_flPosition[0] = flStart[0] + (flBuffer[0] * flDistance);
		g_flPosition[1] = flStart[1] + (flBuffer[1] * flDistance);
		g_flPosition[2] = flStart[2] + (flBuffer[2] * flDistance);
	}
	else
	{
		PrintToChat(client, "[SM] %s", "Could not teleport player after respawn");
		delete hTrace;
		return false;
	}
	delete hTrace;
	return true;
}

void vPerformTeleport(int client, int target, float pos[3])
{
	pos[2] += 10.0;
	TeleportEntity(target, pos, NULL_VECTOR, NULL_VECTOR);
	LogAction(client, target, "\"%L\" teleported \"%L\" after respawning him" , client, target);
}

void vCheatCommand(int client, char[] command, char[] arguments = "")
{
	int iCmdFlags = GetCommandFlags(command);
	SetCommandFlags(command, iCmdFlags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, iCmdFlags);
}