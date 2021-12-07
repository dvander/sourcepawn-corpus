#pragma semicolon 1
#include <sourcemod>

#define CVAR_FLAGS FCVAR_NOTIFY
#define PLUGIN_VERSION "1.0"

#define STEAMID_SIZE 32
#define L4D_TEAM_SPECTATE 1

static const ARRAY_STEAMID = 0;
static const ARRAY_LERP = 1;
static const ARRAY_CHANGES = 2;
static const ARRAY_COUNT = 3;

static Handle:arrayLerps;
static Handle:cVarAllowedLerpChanges;
static Handle:cVarLerpChangeSpec;
static Handle:cVarMinLerp;
static Handle:cVarMaxLerp;

static Handle:cVarMinUpdateRate;
static Handle:cVarMaxUpdateRate;
static Handle:cVarMinInterpRatio;
static Handle:cVarMaxInterpRatio;

static bool:isFirstHalf = true;
static bool:isMatchLife = true;

public Plugin:myinfo =
{
	name = "Lerp Monitor",
	author = "ProdigySim, Die Teetasse, vintik",
	description = "Monitors And Tracks Every Player's Lerp.",
	version = PLUGIN_VERSION,
	url = "https://bitbucket.org/vintik/various-plugins"
};

public OnPluginStart()
{
	cVarMinUpdateRate = FindConVar("sv_minupdaterate");
	cVarMaxUpdateRate = FindConVar("sv_maxupdaterate");
	cVarMinInterpRatio = FindConVar("sv_client_min_interp_ratio");
	cVarMaxInterpRatio = FindConVar("sv_client_max_interp_ratio");
	
	cVarAllowedLerpChanges = CreateConVar("lerp_monitor_maxchanges", "1", "Maximum Changes To Lerp", CVAR_FLAGS);
	cVarLerpChangeSpec = CreateConVar("lerp_monitor_move2spec", "1", "Enable/Disable Team Redirection", CVAR_FLAGS);
	cVarMinLerp = CreateConVar("lerp_monitor_min", "0.000", "Minimum Value Of Lerp", CVAR_FLAGS);
	cVarMaxLerp = CreateConVar("lerp_monitor_max", "0.100", "Maximum Value Of Lerp", CVAR_FLAGS);
	
	RegConsoleCmd("sm_lmlist", Lerps_Cmd, "List All Players' Lerps", CVAR_FLAGS);
	
	HookEvent("round_start", OnRoundStart);
	HookEvent("player_left_start_area", OnRoundBegin);
	HookEvent("player_left_checkpoint", OnRoundBegin);
	HookEvent("round_end", OnRoundEnd);
	HookEvent("player_team", OnPlayerTeam);
	
	arrayLerps = CreateArray(ByteCountToCells(STEAMID_SIZE));
	
	for (new client = 1; client <= MaxClients; client++)
	{	
		if (!IsClientInGame(client) || IsFakeClient(client))
		{
			continue;	
		}
		
		ProcessPlayerLerp(client);
	}
}

public OnMapEnd()
{
	isFirstHalf = true;
	ClearArray(arrayLerps);
}

public OnClientSettingsChanged(client)
{
	if (IsValidEntity(client) && !IsFakeClient(client))
	{
		ProcessPlayerLerp(client);
	}
}

public Action:OnPlayerTeam(Handle:event, String:name[], bool:dontBroadcast)
{
    if (GetEventInt(event, "team") != L4D_TEAM_SPECTATE)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if (client > 0 && IsClientInGame(client) && !IsFakeClient(client))
		{
			CreateTimer(0.1, OnTeamChangeDelay, client, TIMER_FLAG_NO_MAPCHANGE);
		}
    }
}

public Action:OnTeamChangeDelay(Handle:timer, any:client)
{
	if (!IsClientConnected(client))
	{
		return Plugin_Stop;
	}
	
	ProcessPlayerLerp(client);
	return Plugin_Stop;
}

public Action:OnRoundBegin(Handle:event, const String:name[], bool:dontBroadcast)
{
	isMatchLife = true;
}
 
public Action:OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(0.5, Timer_RoundEndDelay);
}

public Action:Timer_RoundEndDelay(Handle:timer)
{
	isFirstHalf = false;
	isMatchLife = false;
	return Plugin_Stop;
}

stock bool:IsFirstHalf()
{
	return isFirstHalf;
}

stock bool:IsMatchLife()
{
	return isMatchLife;
}

stock GetClientBySteamID(const String:steamID[])
{
	decl String:tempSteamID[STEAMID_SIZE];
	
	for (new client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
		{
			continue;
		}
		
		GetClientAuthString(client, tempSteamID, STEAMID_SIZE);
		if (StrEqual(steamID, tempSteamID))
		{
			return client;
		}
	}
	
	return -1;
}

public Action:Lerps_Cmd(client, args)
{
	new clientID, index;
	
	decl Float:lerp;
	decl String:steamID[STEAMID_SIZE];
	
	for (new i = 0; i < (GetArraySize(arrayLerps) / ARRAY_COUNT); i++)
	{
		index = (i * ARRAY_COUNT);
		
		GetArrayString(arrayLerps, index + ARRAY_STEAMID, steamID, STEAMID_SIZE);
		clientID = GetClientBySteamID(steamID);
		lerp = GetArrayCell(arrayLerps, index + ARRAY_LERP);
		
		if (clientID != -1 && GetClientTeam(clientID) != L4D_TEAM_SPECTATE)
		{
			ReplyToCommand(client, "%N [%s]: %.01f", clientID, steamID, lerp * 1000);
		}
	}
	
	return Plugin_Handled;
}

public Action:OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!IsFirstHalf())
	{
		for (new i = 0; i < (GetArraySize(arrayLerps) / ARRAY_COUNT); i++)
		{
			SetArrayCell(arrayLerps, (i * ARRAY_COUNT) + ARRAY_CHANGES, 0);
		}
	}
}

ProcessPlayerLerp(client)
{
	if (IsClientConnected(client))
	{
		new Float:newLerpTime = GetLerpTime(client);
		SetEntPropFloat(client, Prop_Data, "m_fLerpTime", newLerpTime);
		
		if (GetClientTeam(client) == L4D_TEAM_SPECTATE)
		{
			return;
		}
		
		if ((FloatCompare(newLerpTime, GetConVarFloat(cVarMinLerp)) == -1) || (FloatCompare(newLerpTime, GetConVarFloat(cVarMaxLerp)) == 1))
		{
			ChangeClientTeam(client, L4D_TEAM_SPECTATE);
			PrintToChat(client, "\x04[\x05LM\x04]\x01 Illegal Lerp Value (Min: %.01f, Max: %.01f)", GetConVarFloat(cVarMinLerp) * 1000, GetConVarFloat(cVarMaxLerp) * 1000);
			return;
		}
		
		decl String:steamID[STEAMID_SIZE];
		GetClientAuthString(client, steamID, STEAMID_SIZE);
		
		new index = FindStringInArray(arrayLerps, steamID);
		if (index != -1)
		{
			new Float:currentLerpTime = GetArrayCell(arrayLerps, index + ARRAY_LERP);
			if (currentLerpTime == newLerpTime)
			{
				return;
			}
			
			if (IsMatchLife())
			{
				new count = GetArrayCell(arrayLerps, index + ARRAY_CHANGES)+1;
				new max = GetConVarInt(cVarAllowedLerpChanges);
				
				PrintToChatAll("\x01%N's lerp changed from %.01f to %.01f [%s%d\x01/%d changes]", client, currentLerpTime*1000, newLerpTime*1000, ((count > max)?"\x04":""), count, max);
			
				if (GetConVarBool(cVarLerpChangeSpec) && (count > max))
				{
					ChangeClientTeam(client, L4D_TEAM_SPECTATE);
					PrintToChat(client, "\x04[\x05LM\x04]\x01 Illegal Lerp Change: %.01f", currentLerpTime * 1000);
					return;
				}
				
				SetArrayCell(arrayLerps, index + ARRAY_CHANGES, count);
			}
			else
			{
				PrintToChatAll("\x04[\x05LM\x04] \x03%N's\x01 Lerp Changed\nFrom: %.01f\nTo: %.01f", client, currentLerpTime * 1000, newLerpTime * 1000);
			}
			
			SetArrayCell(arrayLerps, index + ARRAY_LERP, newLerpTime);
		}
		else
		{
			PrintToChatAll("\x04[\x05LM\x04] \x03%N's\x01 Lerp Set: %.01f", client, newLerpTime * 1000);
			
			PushArrayString(arrayLerps, steamID);
			PushArrayCell(arrayLerps, newLerpTime);
			PushArrayCell(arrayLerps, 0);
		}
	}
}

Float:GetLerpTime(client)
{
	if (IsClientConnected(client))
	{
		decl String:buffer[64];
		
		if (!GetClientInfo(client, "cl_updaterate", buffer, sizeof(buffer)))
		{
			buffer = "";
		}
		
		new updateRate = StringToInt(buffer);
		updateRate = RoundFloat(clamp(float(updateRate), GetConVarFloat(cVarMinUpdateRate), GetConVarFloat(cVarMaxUpdateRate)));
		
		if (!GetClientInfo(client, "cl_interp_ratio", buffer, sizeof(buffer)))
		{
			buffer = "";
		}
		
		new Float:flLerpRatio = StringToFloat(buffer);
		
		if (!GetClientInfo(client, "cl_interp", buffer, sizeof(buffer)))
		{
			buffer = "";
		}
		
		new Float:flLerpAmount = StringToFloat(buffer);	
		
		if (cVarMinInterpRatio != INVALID_HANDLE && cVarMaxInterpRatio != INVALID_HANDLE && GetConVarFloat(cVarMinInterpRatio) != -1.0)
		{
			flLerpRatio = clamp(flLerpRatio, GetConVarFloat(cVarMinInterpRatio), GetConVarFloat(cVarMaxInterpRatio));
		}
		
		return maximum(flLerpAmount, flLerpRatio / updateRate);
	}
}

Float:clamp(Float:chosen, Float:low, Float:high)
{
	return chosen > high ? high : (chosen < low ? low : chosen);
}

Float:maximum(Float:a, Float:b)
{
	return a > b ? a : b;
}

