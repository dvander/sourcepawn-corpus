#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define STEAMID_SIZE 32

new Handle:hCvarAllowedRateChanges;
new Handle:hCvarMinRate;
new Handle:hCvarMinCmd;
new Handle:hCvarProhibitFakePing;
new Handle:hCvarProhibitedAction;
new Handle:hClientSettingsArray;

new iAllowedRateChanges;
new iMinRate;
new iMinCmd;
new iActionUponExceed;

new bool:bProhibitFakePing;
new bool:bIsMatchLive = false;

enum NetsettingsStruct
{
    String:Client_SteamId[STEAMID_SIZE],
    Client_Rate,
    Client_Cmdrate,
    Client_Updaterate,
    Client_Changes
};

public Plugin:myinfo =
{
	name = "Rate Monitor",
	author = "Visor",
	description = "Monitors And Tracks Every Player's Rates.",
	version = "2.2",
	url = "https://github.com/Attano/smplugins"
};

public OnPluginStart()
{
	hCvarAllowedRateChanges = CreateConVar("rate_monitor_maxchanges", "-1", "Max Changes Allowed To Rates", FCVAR_NOTIFY);
	hCvarMinRate = CreateConVar("rate_monitor_minrate", "66000", "Minimum Value Of sv_minrate Command", FCVAR_NOTIFY);
	hCvarMinCmd = CreateConVar("rate_monitor_mincmd", "66", "Minimum Value Of cl_cmdrate Command", FCVAR_NOTIFY);
	hCvarProhibitFakePing = CreateConVar("rate_monitor_nofp", "1", "Enable/Disable Fake Ping Prohibition", FCVAR_NOTIFY);
	hCvarProhibitedAction = CreateConVar("rate_monitor_punish", "3", "Punishment: 1=Notifications, 2=Move To Spec, 3=Kick", FCVAR_NOTIFY, true, 1.0, true, 3.0);
	
	iAllowedRateChanges = GetConVarInt(hCvarAllowedRateChanges);
	iMinRate = GetConVarInt(hCvarMinRate);
	iMinCmd = GetConVarInt(hCvarMinCmd);
	bProhibitFakePing = GetConVarBool(hCvarProhibitFakePing);
	iActionUponExceed = GetConVarInt(hCvarProhibitedAction);
	
	HookConVarChange(hCvarAllowedRateChanges, cvarChanged_AllowedRateChanges);
	HookConVarChange(hCvarMinRate, cvarChanged_MinRate);
	HookConVarChange(hCvarMinCmd, cvarChanged_MinCmd);
	HookConVarChange(hCvarProhibitFakePing, cvarChanged_ProhibitFakePing);
	HookConVarChange(hCvarProhibitedAction, cvarChanged_ExceedAction);
	
	RegConsoleCmd("sm_rmlist", ListRates, "List All Players' Net Settings");
	
	HookEvent("round_start", EventHook:OnRoundStart);
	HookEvent("player_left_start_area", OnRoundBegin);
	HookEvent("player_left_checkpoint", OnRoundBegin);
	HookEvent("player_team", OnPlayerTeam);
	HookEvent("round_end", EventHook:OnRoundEnd);
	
	hClientSettingsArray = CreateArray(_:NetsettingsStruct);
}

public OnRoundStart() 
{
	decl player[NetsettingsStruct];
	for (new i = 0; i < GetArraySize(hClientSettingsArray); i++) 
	{
		GetArrayArray(hClientSettingsArray, i, player[0]);
		player[Client_Changes] = _:0;
		SetArrayArray(hClientSettingsArray, i, player[0]);
	}
}

public Action:OnRoundBegin(Handle:event, const String:name[], bool:dontBroadcast) 
{
	bIsMatchLive = true;
}

public OnRoundEnd()
{
	bIsMatchLive = false;
}

public OnMapEnd()
{
	ClearArray(hClientSettingsArray);
}

public Action:OnPlayerTeam(Handle:event, String:name[], bool:dontBroadcast)
{
	if (GetEventInt(event, "team") != 1)
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
	RegisterSettings(client);
	return Plugin_Stop;
}

public OnClientSettingsChanged(client) 
{
	RegisterSettings(client);
}

public Action:ListRates(client, args) 
{
	decl player[NetsettingsStruct];
	new iClient;
	
	ReplyToCommand(client, "\x03[\x04RM\x03]\x01 List Of Players' Net Settings (\x03cmd\x01/\x04upd\x01/\x05rate\x01):");
	
	for (new i = 0; i < GetArraySize(hClientSettingsArray); i++) 
	{
		GetArrayArray(hClientSettingsArray, i, player[0]);
		
		iClient = GetClientBySteamId(player[Client_SteamId]);
		if (iClient < 0)
		{
			continue;
		}
		
		if (IsClientConnected(iClient) && GetClientTeam(iClient) != 1) 
		{
			ReplyToCommand(client, "\x03%N\x01 : %d/%d/%d", iClient, player[Client_Cmdrate], player[Client_Updaterate], player[Client_Rate]);
		}
	}
	
	return Plugin_Handled;
}

RegisterSettings(client) 
{	
    if (!IsClientInGame(client) || GetClientTeam(client) == 1 || IsFakeClient(client)) 
    {
		return;
	}
	
	decl player[NetsettingsStruct];
	decl String:sCmdRate[32], String:sUpdateRate[32], String:sRate[32];
	decl String:sSteamId[STEAMID_SIZE];
	decl String:sCounter[32] = "";
	
	new iCmdRate, iUpdateRate, iRate;
    
	GetClientAuthString(client, sSteamId, STEAMID_SIZE);
	new iIndex = FindStringInArray(hClientSettingsArray, sSteamId);
	
	iRate = GetClientDataRate(client);
	
	GetClientInfo(client, "cl_cmdrate", sCmdRate, sizeof(sCmdRate));
	iCmdRate = StringToInt(sCmdRate);
	
	GetClientInfo(client, "cl_updaterate", sUpdateRate, sizeof(sUpdateRate));
	iUpdateRate = StringToInt(sUpdateRate);
   
	if (bProhibitFakePing)
	{
		new bool:bIsCmdRateClean, bIsUpdateRateClean;
		
		bIsCmdRateClean = IsNatural(sCmdRate);
		bIsUpdateRateClean = IsNatural(sUpdateRate);
		
		if (!bIsCmdRateClean || !bIsUpdateRateClean) 
		{
			sCounter = " [\x03Bad cmd/upd\x01]";
			
			Format(sCmdRate, sizeof(sCmdRate), "%s%s%s", !bIsCmdRateClean ? "\x03(\x04" : "\x04", sCmdRate, !bIsCmdRateClean ? "\x03)\x01" : "\x01");
			Format(sUpdateRate, sizeof(sUpdateRate), "%s%s%s", !bIsUpdateRateClean ? "\x03(\x04" : "\x04", sUpdateRate, !bIsUpdateRateClean ? "\x03)\x01" : "\x01");
			Format(sRate, sizeof(sRate), "\x05%d\x01", iRate);
			
			PunishPlayer(client, sCmdRate, sUpdateRate, sRate, sCounter, iIndex);
			return;
		}
	}
	
	if ((iCmdRate < iMinCmd && iMinCmd > -1) || (iRate < iMinRate && iRate > -1))
	{
		sCounter = " [\x03Low cmd/rate\x01]";
		
		Format(sCmdRate, sizeof(sCmdRate), "%s%d%s", iCmdRate < iMinCmd ? "\x05>\x04" : "\x04", iCmdRate, iCmdRate < iMinCmd ? "\x05<\x01" : "\x01");
		Format(sUpdateRate, sizeof(sUpdateRate), "\x04%d\x01", iUpdateRate);
		Format(sRate, sizeof(sRate), "%s%d%s", iRate < iMinRate ? "\x04>\x05" : "\x05", iRate, iRate < iMinRate ? "\x04<\x01" : "\x01");
		
		PunishPlayer(client, sCmdRate, sUpdateRate, sRate, sCounter, iIndex);
		return;
	}
	
	if (iIndex > -1) 
	{
		GetArrayArray(hClientSettingsArray, iIndex, player[0]);
		
		if (iRate == player[Client_Rate] && iCmdRate == player[Client_Cmdrate] && iUpdateRate == player[Client_Updaterate])
		{
			return;
		}
		
		if (bIsMatchLive && iAllowedRateChanges > -1)
		{
			player[Client_Changes] += 1;
			Format(sCounter, sizeof(sCounter), " [%s%d\x01/%d]", (player[Client_Changes] > iAllowedRateChanges ? "\x04" : "\x01"), player[Client_Changes], iAllowedRateChanges);
			
			if (player[Client_Changes] > iAllowedRateChanges)
			{
				Format(sCmdRate, sizeof(sCmdRate), "%s%d\x01", iCmdRate != player[Client_Cmdrate] ? "\x05*\x04" : "\x04", iCmdRate);
				Format(sUpdateRate, sizeof(sUpdateRate), "%s%d\x01", iUpdateRate != player[Client_Updaterate] ? "\x05*\x04" : "\x04", iUpdateRate);
				Format(sRate, sizeof(sRate), "%s%d\x01", iRate != player[Client_Rate] ? "\x04*\x05" : "\x05", iRate);
				
				PunishPlayer(client, sCmdRate, sUpdateRate, sRate, sCounter, iIndex);
				return;
			}
		}
        
		PrintToChatAll("\x03[\x04RM\x03] \x05%N's\x01 Net Settings Changed\nFrom: \x04%d\x01/\x04%d\x01/\x05%d\x01\nTo: \x04%d\x01/\x04%d\x01/\x05%d\x01%s", client, player[Client_Cmdrate], player[Client_Updaterate], player[Client_Rate], iCmdRate, iUpdateRate, iRate, sCounter);
		
		player[Client_Cmdrate] = _:iCmdRate;
		player[Client_Updaterate] = _:iUpdateRate;
		player[Client_Rate] = _:iRate;
		
		SetArrayArray(hClientSettingsArray, iIndex, player[0]);
    }
	else
	{
		strcopy(player[Client_SteamId], STEAMID_SIZE, sSteamId);
		
		player[Client_Cmdrate] = _:iCmdRate;
		player[Client_Updaterate] = _:iUpdateRate;
		player[Client_Rate] = _:iRate;
		player[Client_Changes] = _:0;
		
		PushArrayArray(hClientSettingsArray, player[0]);
		
		PrintToChatAll("\x03[\x04RM\x03] \x05%N's\x01 Net Settings Set: \x04%d\x01/\x04%d\x01/\x05%d\x01", client, player[Client_Cmdrate], player[Client_Updaterate], player[Client_Rate]);
	}
}

PunishPlayer(client, const String:sCmdRate[], const String:sUpdateRate[], const String:sRate[], const String:sCounter[], iIndex)
{
	new bool:bInitialRegister = iIndex > -1 ? false : true;
	
	switch (iActionUponExceed)
	{
		case 1:
		{
			if (bInitialRegister)
			{
				PrintToChatAll("\x03[\x04RM\x03] \x05%N\x01 Has Illegal Net Settings: %s/%s/%s%s", client, sCmdRate, sUpdateRate, sRate, sCounter);
			}
			else
			{
				PrintToChatAll("\x03[\x04RM\x03] \x05%N\x01 Illegally Changed Net Settings: %s/%s/%s%s", client, sCmdRate, sUpdateRate, sRate, sCounter);
			}
        }
		case 2:
		{
			ChangeClientTeam(client, 1);
			
			if (bInitialRegister)
			{
				PrintToChat(client, "\x03[\x04RM\x03]\x01 Rates Must Be Higher Than: \x04%d\x01/\x05%d\x01%s", iMinCmd, iMinRate, bProhibitFakePing ? " and remove any \x03non-digital characters" : "");
			}
			else
			{
				decl player[NetsettingsStruct];
				GetArrayArray(hClientSettingsArray, iIndex, player[0]);
				
				PrintToChat(client, "\x03[\x04RM\x03]\x01 Net Settings Must Be: \x04%d\x01/\x04%d\x01/\x05%d", player[Client_Cmdrate], player[Client_Updaterate], player[Client_Rate]);
			}
		}
		case 3:
		{
			if (bInitialRegister)
			{
				KickClient(client, "Rates Must Be Higher Than %d/%d%s", iMinCmd, iMinRate, bProhibitFakePing ? " And Fake Pings Prohibited!" : "");
				PrintToChatAll("\x03[\x04RM\x03]\x01 Kicked \x05%N\x01 For Illegal Net Settings: %s/%s/%s%s", client, sCmdRate, sUpdateRate, sRate, sCounter);
			}
			else
			{
				decl player[NetsettingsStruct];
				GetArrayArray(hClientSettingsArray, iIndex, player[0]);
				
				KickClient(client, "Fake Pings Prohibited And Rates %d/%d/%d Exceed!", player[Client_Cmdrate], player[Client_Updaterate], player[Client_Rate]);
				PrintToChatAll("\x03[\x04RM\x03]\x01 Kicked \x05%N\x01 For Illegal Net Settings Change: %s/%s/%s%s", client, sCmdRate, sUpdateRate, sRate, sCounter);
			}
			
			if ((GetUserFlagBits(client) & ADMFLAG_GENERIC) || (GetUserFlagBits(client) & ADMFLAG_KICK) || (GetUserFlagBits(client) & ADMFLAG_ROOT))
			{
				PrintToChatAll("\x05[-]\x01 Admin \x04%N \x03[\x04Illegal Net Settings!\x03]", client);
			}
			else if ((GetUserFlagBits(client) & ADMFLAG_CUSTOM1) || (GetUserFlagBits(client) & ADMFLAG_CUSTOM2) || (GetUserFlagBits(client) & ADMFLAG_CUSTOM3) || (GetUserFlagBits(client) & ADMFLAG_CUSTOM4) || (GetUserFlagBits(client) & ADMFLAG_CUSTOM5) || (GetUserFlagBits(client) & ADMFLAG_CUSTOM6))
			{
				PrintToChatAll("\x05[-]\x01 VIP \x04%N \x03[\x04Illegal Net Settings!\x03]", client);
			}
			else
			{
				PrintToChatAll("\x05[-]\x01 Player \x04%N \x03[\x04Illegal Net Settings!\x03]", client);
			}
		}
	}
	return;
}

stock GetClientBySteamId(const String:steamID[]) 
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

stock bool:IsNatural(const String:str[])
{	
	new x = 0;
	
	while (str[x] != '\0') 
	{
		if (!IsCharNumeric(str[x]))
		{
			return false;
		}
		
		x++;
	}
	
	return true;
}

public cvarChanged_AllowedRateChanges(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	iAllowedRateChanges = GetConVarInt(hCvarAllowedRateChanges);
}

public cvarChanged_MinRate(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	iMinRate = GetConVarInt(hCvarMinRate);
}

public cvarChanged_MinCmd(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	iMinCmd = GetConVarInt(hCvarMinCmd);
}

public cvarChanged_ProhibitFakePing(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	bProhibitFakePing = GetConVarBool(hCvarProhibitFakePing);
}

public cvarChanged_ExceedAction(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	iActionUponExceed = GetConVarInt(hCvarProhibitedAction);
}

