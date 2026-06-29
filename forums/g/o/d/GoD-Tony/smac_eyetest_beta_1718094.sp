#pragma semicolon 1

/* SM Includes */
#include <sourcemod>
#include <sdktools>
#include <smac>

/* Plugin Info */
public Plugin:myinfo =
{
	name = "SMAC Eye Angle Test",
	author = "GoD-Tony, psychonic",
	description = "Detects eye angle violations used in cheats",
	version = "beta",
	url = SMAC_URL
};

/* Globals */
new Handle:g_hCvarBan = INVALID_HANDLE;
new Float:g_fDetectedTime[MAXPLAYERS+1];
new g_iSDKVersion;

/* Plugin Functions */
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	MarkNativeAsOptional("GameRules_GetPropEnt");
	return APLRes_Success;
}

public OnPluginStart()
{
	LoadTranslations("smac.phrases");
	
	// Convars.
	g_hCvarBan = SMAC_CreateConVar("smac_eyetest_ban", "0", "Automatically ban players on eye test detections.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	// Cache engine version.
	if ((g_iSDKVersion = GuessSDKVersion()) == SOURCE_SDK_UNKNOWN)
	{
		decl String:sGame[64];
		GetGameFolderName(sGame, sizeof(sGame));
		SetFailState("SDK Version could not be determined for game: %s", sGame);
	}
}

public OnClientDisconnect_Post(client)
{
	g_fDetectedTime[client] = 0.0;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	// Check for valid eye angles.
	if (g_iSDKVersion >= SOURCE_SDK_LEFT4DEAD)
	{
		// In L4D+ engines the client can alternate between ±180 and 0-360.
		if (angles[0] > -135.0 && angles[0] < 135.0 && angles[1] > -270.0 && angles[1] < 420.0)
			return Plugin_Continue;
	}
	else if (g_iSDKVersion >= SOURCE_SDK_EPISODE2)
	{
		// ± normal limit * 1.5 as a buffer zone.
		if (angles[0] > -135.0 && angles[0] < 135.0 && angles[1] > -270.0 && angles[1] < 270.0)
			return Plugin_Continue;
	}
	else
	{
		// Older engine support.
		decl Float:vTemp[3];
		vTemp = angles;
		
		if (vTemp[0] > 180.0)
			vTemp[0] -= 360.0;
		
		if (vTemp[2] > 180.0)
			vTemp[2] -= 360.0;
		
		if (vTemp[0] >= -90.0 && vTemp[0] <= 90.0 && vTemp[2] >= -90.0 && vTemp[2] <= 90.0)
			return Plugin_Continue;
	}
	
	// Ignore bots and dead clients.
	if (IsFakeClient(client) || !IsPlayerAlive(client))
		return Plugin_Continue;
	
	// Game specific checks.
	switch (SMAC_GetGameType())
	{
		case Game_DODS:
		{
			// Ignore prone players.
			if (DODS_IsPlayerProne(client))
				return Plugin_Continue;
		}
		
		case Game_L4D:
		{
			// Only check survivors in first-person view.
			if (GetClientTeam(client) != 2 || L4D_IsSurvivorBusy(client))
				return Plugin_Continue;
		}
		
		case Game_L4D2:
		{
			// Only check survivors in first-person view.
			if (GetClientTeam(client) != 2 || L4D2_IsSurvivorBusy(client))
				return Plugin_Continue;
		}
		
		case Game_ND:
		{
			if (ND_IsPlayerCommander(client))
				return Plugin_Continue;
		}
	}
	
	// Ignore clients that are interacting with the map.
	new flags = GetEntityFlags(client);
	
	if (flags & FL_FROZEN || flags & FL_ATCONTROLS)
		return Plugin_Continue;
	
	// The client failed all checks.
	Eyetest_Detected(client, angles);
	return Plugin_Continue;
}

Eyetest_Detected(client, const Float:angles[3])
{
	// Allow the same player to be processed once every 30 seconds.
	if (GetGameTime() > g_fDetectedTime[client])
	{
		g_fDetectedTime[client] = GetGameTime() + 30.0;
		
		// Strict bot checking - https://bugs.alliedmods.net/show_bug.cgi?id=5294
		decl String:sAuthID[32];
		if (GetClientAuthString(client, sAuthID, sizeof(sAuthID)) && !StrEqual(sAuthID, "BOT") && SMAC_CheatDetected(client) == Plugin_Continue)
		{
			decl String:sName[MAX_NAME_LENGTH];
			GetClientName(client, sName, sizeof(sName));
			
			SMAC_PrintAdminNotice("%t", "SMAC_EyetestDetected", sName);
			
			if (GetConVarBool(g_hCvarBan))
			{
				SMAC_LogAction(client, "was banned for cheating with their eye angles. Eye Angles: %.0f %.0f %.0f", angles[0], angles[1], angles[2]);
				SMAC_Ban(client, "Eye Angles Violation");
			}
			else
			{
				SMAC_LogAction(client, "is suspected of cheating with their eye angles. Eye Angles: %.0f %.0f %.0f", angles[0], angles[1], angles[2]);
			}
		}
	}
}
