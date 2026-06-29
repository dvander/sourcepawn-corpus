/*	=============================================
*	- NAME:
*	  + FF Flag Assist Points
*
*	- DESCRIPTION:
*	  + This plugin gives points to players that helped assist the flag.
*
*	  + The points are given in a percentage depending on how long
*	  + they held the flag compared to other assistants.
*
*	  + The flag captor receives the default capture points, but no assist points.
* 	
* 	
*	-------------
*	Server cvars:
*	-------------
*	- sv_assistpool <Number of points>
*	 + Sets the amount of points in the flag cap assist pool.
*	
*	- sv_defendpoints <Number of points>
*	 + Sets the amount of points a player gets for defending the flag.
*	
* 	
*	----------------
*	Client commands:
*	----------------
*	- flagstatus
*	 + Shows the player the status of their teams flag and the enemy teams flag.
*	
* 	
*	---------------
*	Credits/Thanks:
*	---------------
*	- [Rawh]: Providing a Linux box to test on and testing plugin.
*  	- [psychonic]: Pointing out exploits and ideas.
*	- [Tyrant]: Helped test plugin.
*	- [PartialSchism]: Helped test plugin.
*	- [TonyCip]: Helped test plugin.
*	- [Bully]: Helped test plugin.
* 	
* 	
*	----------
*	Changelog:
*	----------
*	Version 1.0 ( 02-12-2009 )
*	-- Initial release.
* 	
*	Version 1.1 ( 02-13-2009 )
*	-- Added logging of the flag assists for stats programs.
*	-- Added hooks for say_team and say2 to remove exploiting (thanks psychonic).
* 	
*	Version 1.2 ( 02-23-2009 )
*	-- Added flaginfo command for players to view the status of the flags.
*	-- Added points for players that help defend the flag.
*	-- Added logging for defending the flag (logs as flag_defend).
*	-- Added cvar sv_assistpool to set the amount of points in the flag capture pool.
*	-- Added cvar sv_defendpoints to set the amount of points a player gets from defending the flag.
*	-- Fixed some problems plugin was having on Linux machines.
* 	
*	Version 1.3 ( 02-25-2009 )
*	-- Fixed variables that needed reset on map change.
*	-- Added the flags location to the flaginfo command.
*	-- Colorized the flaginfo command.
* 	
*	Version 1.4 ( 02-28-2009 )
*	-- Added check to see if the map is CTF. If not a CTF map the plugin will 'unload'.
*	-- Added flag defend points for killing players within a certain distance of the flag.
*	-- Added a new logging feature for killing the flag carrier: 'flag_defend_carrier'.
*	-- Changed 'flag_defend' logging. This now represents that you killed someone near your flag.
*	-- Changed 'flaginfo' command to 'flagstatus' due to flaginfo already existing in FF.
*	-- Added message to inform connected players about the flagstatus command.
*	-- Fixed bug where player carrying a flag would disconnect; which would cause wrong flag status.
* 	
*	Version 1.5 ( 03-02-2009 )
*	-- Fixed bugs in the location message hook.
*	-- Fixed a bug in the client disconnect hook.
*	-- Fixed bug where plugin tried to give non-player entities Fortress-Points.
*	-- This plugin now works with my LocationMessages plugin.
* 	
*	Version 1.6 ( 03-05-2009 )
*	-- Fixed showing the dead players flagstatus.
*	-- Optimized the SayText function so it no longer needs the extra name checks.
* 	
*/

#include <sourcemod>
#include <sdktools_sound>
#include <sdktools_functions>
#include <regex>

#define VERSION "1.6"
public Plugin:myinfo = 
{
	name = "FF Flag Assist Points",
	author = "hlstriker",
	description = "Gives points to players that helped assist the flag",
	version = VERSION,
	url = "None"
}

#define SOUND_CHAT "common/talk.wav"

#define MAX_PLAYERS 22
new g_iMaxPlayers;
new bool:g_bHasSpawned[MAX_PLAYERS+1];

new g_iFlagCapPoints;
new Handle:g_hAssistPool;
new String:g_szTeamEnemyFlagName[6][32];

// Used for defend points
#define DEFEND_DISTANCE 250
new g_iTeamsFlagIndex[6];
new bool:g_bIsMapCTF;
new g_iDefendPoints;
new Handle:g_hDefendPoints;
new g_iWhoDroppedFlag[6];

// Used for flag status
#define FLAG_BASE 0
#define FLAG_DROPPED -1
#define OUR_LOC_ID 728
new g_iWhoHasFlag[6];
new String:g_szFlagLocation[6][42];
new String:g_szPlayerLocation[MAX_PLAYERS+1][42];
new g_iFlagLocColor[6];
new g_iPlayerLocColor[MAX_PLAYERS+1];

new g_iAssistPickupTime[MAX_PLAYERS+1];
new g_iAssistSeconds[MAX_PLAYERS+1];
new g_iAssistSecondsCombined[6];
new g_iAssistTeam[MAX_PLAYERS+1];

public OnPluginStart()
{
	CreateConVar("sv_flagassistver", VERSION, "Flag Assist Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	g_hDefendPoints = CreateConVar("sv_defendpoints", "50", "Sets the amount of points a player gets for defending the flag", 0, true, 1.0);
	g_hAssistPool = CreateConVar("sv_assistpool", "1000", "Sets the amount of points in the flag cap assist pool", 0, true, 10.0);
	
	HookConVarChange(g_hDefendPoints, cvar_DefendPoints);
	HookConVarChange(g_hAssistPool, cvar_AssistPool);
	
	HookUserMessage(UserMsg:28, MsgHook:msg_SetPlayerLocation, false);
	
	HookEvent("player_death", event_death, EventHookMode_Post);
	HookEvent("player_team", event_team, EventHookMode_Pre);
	HookEvent("player_spawn", event_spawn, EventHookMode_Post);
	
	RegConsoleCmd("flagstatus", hook_FlagStatus);
	
	RegConsoleCmd("say", hook_say);
	RegConsoleCmd("say2", hook_say);
	RegConsoleCmd("say_team", hook_say);
	AddGameLogHook(ParseLog);
}

public OnClientAuthorized(iClient, const String:szAuthID[])
	g_bHasSpawned[iClient] = false;

public OnClientDisconnect(iClient)
{
	if(IsValidEntity(iClient))
	{
		new iTeam = GetEntProp(iClient, Prop_Send, "m_iTeamNum");
		if(g_iWhoHasFlag[iTeam] == iClient)
			g_iWhoHasFlag[iTeam] = FLAG_DROPPED;
	}
}

public OnMapStart()
{
	g_iMaxPlayers = GetMaxClients();
	PrecacheSound(SOUND_CHAT);
	
	// Need to reset some variables
	new i;
	for(i=0; i<sizeof(g_iWhoHasFlag); i++)
		g_iWhoHasFlag[i] = 0;
	for(i=0; i<sizeof(g_iWhoDroppedFlag); i++)
		g_iWhoDroppedFlag[i] = 0;
	for(i=0; i<sizeof(g_szFlagLocation); i++)
		strcopy(g_szFlagLocation[i], sizeof(g_szFlagLocation[])-1, "");
}

public OnConfigsExecuted()
{
	g_iFlagCapPoints = GetConVarInt(g_hAssistPool);
	g_iDefendPoints = GetConVarInt(g_hDefendPoints);
	
	g_bIsMapCTF = true;
	
	new i;
	for(i=0; i<sizeof(g_iTeamsFlagIndex); i++)
		g_iTeamsFlagIndex[i] = 0;
	
	new String:szBuffer[128], iFlagTeams[4], iTeamsFlagIndex[4], iSkin;
	// Get the number of flags
	for(i=0; i<GetEntityCount(); i++)
	{
		if(!IsValidEntity(i))
			continue;
		
		GetEntPropString(i, Prop_Data, "m_ModelName", szBuffer, sizeof(szBuffer)-1);
		if(StrEqual(szBuffer, "models/flag/flag.mdl"))
		{
			GetEntPropString(i, Prop_Data, "m_iClassname", szBuffer, sizeof(szBuffer)-1);
			if(StrEqual(szBuffer, "info_ff_script"))
			{
				GetEntPropString(i, Prop_Data, "m_iName", szBuffer, sizeof(szBuffer)-1);
				if(StrContains(szBuffer, "flag", false) != -1)
				{
					iSkin = GetEntProp(i, Prop_Send, "m_nSkin");
					if(iSkin >= 0 && iSkin < 4)
					{
						iFlagTeams[iSkin]++;
						iTeamsFlagIndex[iSkin] = i;
					}
				}
			}
		}
	}
	
	// See if there are more than 2 teams valid for ctf
	new iNumValidTeams, iValidTeamsFlagIndex[4];
	for(i=0; i<sizeof(iFlagTeams); i++)
	{
		if(iFlagTeams[i] == 1)
		{
			iNumValidTeams++;
			iValidTeamsFlagIndex[i] = iTeamsFlagIndex[i];
		}
	}
	
	// If valid teams are equal to 2, map is ctf
	if(iNumValidTeams == 2)
	{
		for(i=0; i<sizeof(iFlagTeams); i++)
		{
			if(iValidTeamsFlagIndex[i] > 0)
				g_iTeamsFlagIndex[i+2] = iValidTeamsFlagIndex[i];
		}
	}
	else
		g_bIsMapCTF = false;
}

public Action:msg_SetPlayerLocation(UserMsg:msg_id, Handle:hBf, const iPlayers[], iPlayersNum, bool:bReliable, bool:bInit)
{
	if(!g_bIsMapCTF || !iPlayersNum)
		return Plugin_Continue;
	
	static iClient;
	iClient = iPlayers[0];
	if(!IsClientInGame(iClient) || !IsValidEntity(iClient))
		return Plugin_Continue;
	
	static String:szMessage[42], iColor, iOne, iTeam;
	iTeam = GetEntProp(iClient, Prop_Send, "m_iTeamNum");
	BfReadString(hBf, szMessage, sizeof(szMessage)-1);
	iColor = BfReadShort(hBf);
	iOne = BfReadShort(hBf);
	
	if(iOne == OUR_LOC_ID)
		return Plugin_Continue;
	
	if(iColor > 1)
		iColor--;
	else
		iColor = 5;
	
	g_iPlayerLocColor[iClient] = iColor;
	strcopy(g_szPlayerLocation[iClient], sizeof(g_szPlayerLocation[])-1, szMessage);
	
	if(g_iWhoHasFlag[iTeam] == iClient)
	{
		g_iFlagLocColor[iTeam] = iColor;
		strcopy(g_szFlagLocation[iTeam], sizeof(g_szFlagLocation[])-1, szMessage);
	}
	
	return Plugin_Continue;
}

// This is the forward call from LocationMessages.smx
public Action:OnSetPlayerLocation(iClient, const String:szLocation[], iColor)
{
	if(!g_bIsMapCTF)
		return Plugin_Continue;
	
	static iTeam;
	iTeam = GetEntProp(iClient, Prop_Send, "m_iTeamNum");
	
	if(iColor > 1)
		iColor--;
	else
		iColor = 5;
	
	g_iPlayerLocColor[iClient] = iColor;
	strcopy(g_szPlayerLocation[iClient], sizeof(g_szPlayerLocation[])-1, szLocation);
	
	if(g_iWhoHasFlag[iTeam] == iClient)
	{
		g_iFlagLocColor[iTeam] = iColor;
		strcopy(g_szFlagLocation[iTeam], sizeof(g_szFlagLocation[])-1, szLocation);
	}
	
	return Plugin_Continue;
}

public Action:event_spawn(Handle:hEvent, const String:szEventName[], bool:bDontBroadcast)
{
	if(!g_bIsMapCTF)
		return Plugin_Continue;
	
	static iClient;
	iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if(!g_bHasSpawned[iClient])
	{
		SayText("^5[ALERT] ^7Bind a key to ^2'flagstatus' ^7to see the flags status.", 1, iClient);
		g_bHasSpawned[iClient] = true;
	}
	
	return Plugin_Continue;
}

public Action:event_death(Handle:hEvent, const String:szEventName[], bool:bDontBroadcast)
{
	if(!g_bIsMapCTF)
		return Plugin_Continue;
	
	static iVictim, iAttacker, iVictimTeam, iAttackerTeam;
	iVictim = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	iAttacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	
	iVictimTeam = GetEntProp(iVictim, Prop_Send, "m_iTeamNum");
	iAttackerTeam = GetEntProp(iAttacker, Prop_Send, "m_iTeamNum");
	
	if(iAttacker < 1 || iAttacker > 32)
		return Plugin_Continue;
	
	if(iVictimTeam == iAttackerTeam)
		return Plugin_Continue;
	
	// Killed flag carrier
	if(g_iWhoDroppedFlag[iVictimTeam] == iVictim)
		SetDefendPoints(iAttacker, g_iDefendPoints, 1);
	else
	{
		// Killed player that was near flag
		static Float:flVictimOrigin[3], Float:flFlagOrigin[3];
		GetClientAbsOrigin(iVictim, flVictimOrigin);
		GetEntPropVector(g_iTeamsFlagIndex[iAttackerTeam], Prop_Send, "m_vecOrigin", flFlagOrigin);
		
		if(RoundFloat(GetVectorDistance(flFlagOrigin, flVictimOrigin)) < DEFEND_DISTANCE)
			SetDefendPoints(iAttacker, g_iDefendPoints, 0);
	}
	
	g_iWhoDroppedFlag[iVictimTeam] = 0;
	
	return Plugin_Continue;
}

public Action:event_team(Handle:hEvent, const String:szEventName[], bool:bDontBroadcast)
{
	if(!g_bIsMapCTF)
		return Plugin_Continue;
	
	static iClient, iOldTeam;
	iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	iOldTeam = GetEventInt(hEvent, "oldteam");
	
	if(g_iAssistTeam[iClient] == iOldTeam)
	{
		g_iAssistSecondsCombined[iOldTeam] -= g_iAssistSeconds[iClient];
		g_iAssistTeam[iClient] = 0;
		g_iAssistSeconds[iClient] = 0;
	}
	
	return Plugin_Continue;
}

public Action:ParseLog(const String:szMessage[])
{
	if(!g_bIsMapCTF)
		return;
	
	if(StrContains(szMessage, "triggered \"flag_touch\"") != -1)
		FlagTouch(szMessage);
	else if(StrContains(szMessage, "triggered \"flag_thrown\"") != -1)
		FlagThrownDropped(szMessage, 0);
	else if(StrContains(szMessage, "triggered \"flag_dropped\"") != -1)
		FlagThrownDropped(szMessage, 1);
	else if(StrContains(szMessage, "triggered \"flag_capture\"") != -1)
		FlagCapture(szMessage);
	else if(StrContains(szMessage, "triggered \"flag_returned\"") != -1)
		FlagReturned(szMessage);
}

FlagTouch(const String:szMessage[])
{
	new Handle:hRegex = INVALID_HANDLE;
	
	hRegex = CompileRegex("<(.+?)><STEAM_.+?flag_name \"(.+?)\"");
	if(hRegex != INVALID_HANDLE)
	{
		new iClient, String:szUserID[4], String:szFlagName[32];
		
		MatchRegex(hRegex, szMessage);
		GetRegexSubString(hRegex, 1, szUserID, sizeof(szUserID)-1);
		GetRegexSubString(hRegex, 2, szFlagName, sizeof(szFlagName)-1);
		iClient = GetClientOfUserId(StringToInt(szUserID));
		if(!iClient)
			return;
		
		g_iAssistPickupTime[iClient] = GetTime();
		g_iAssistTeam[iClient] = GetEntProp(iClient, Prop_Send, "m_iTeamNum");
		
		g_iWhoHasFlag[g_iAssistTeam[iClient]] = iClient;
		g_iWhoDroppedFlag[g_iAssistTeam[iClient]] = 0;
		
		g_iFlagLocColor[g_iAssistTeam[iClient]] = g_iPlayerLocColor[iClient];
		strcopy(g_szFlagLocation[g_iAssistTeam[iClient]], sizeof(g_szFlagLocation[])-1, g_szPlayerLocation[iClient]);
		
		if(StrEqual(g_szTeamEnemyFlagName[g_iAssistTeam[iClient]], ""))
			strcopy(g_szTeamEnemyFlagName[g_iAssistTeam[iClient]], sizeof(g_szTeamEnemyFlagName[])-1, szFlagName);
	}
	
	return;
}

FlagThrownDropped(const String:szMessage[], const iType)
{
	new Handle:hRegex = INVALID_HANDLE;
	
	hRegex = CompileRegex("<(.+?)><STEAM_");
	if(hRegex != INVALID_HANDLE)
	{
		new iClient, String:szUserID[4];
		
		MatchRegex(hRegex, szMessage);
		GetRegexSubString(hRegex, 1, szUserID, sizeof(szUserID)-1);
		iClient = GetClientOfUserId(StringToInt(szUserID));
		if(!iClient)
			return;
		
		g_iWhoHasFlag[g_iAssistTeam[iClient]] = FLAG_DROPPED;
		
		if(!iType)
			g_iWhoDroppedFlag[g_iAssistTeam[iClient]] = 0;
		else
			g_iWhoDroppedFlag[g_iAssistTeam[iClient]] = iClient;
		
		new iHeldTime = GetTime() - g_iAssistPickupTime[iClient];
		if(!iHeldTime)
			iHeldTime = 1;
		g_iAssistSeconds[iClient] += iHeldTime;
		g_iAssistSecondsCombined[g_iAssistTeam[iClient]] += iHeldTime;
	}
	
	return;
}

FlagCapture(const String:szMessage[])
{
	new Handle:hRegex = INVALID_HANDLE;
	
	hRegex = CompileRegex("<(.+?)><STEAM_");
	if(hRegex != INVALID_HANDLE)
	{
		new iClient, String:szUserID[4];
		
		MatchRegex(hRegex, szMessage);
		GetRegexSubString(hRegex, 1, szUserID, sizeof(szUserID)-1);
		iClient = GetClientOfUserId(StringToInt(szUserID));
		if(!iClient)
			return;
		
		g_iWhoHasFlag[g_iAssistTeam[iClient]] = FLAG_BASE;
		g_iWhoDroppedFlag[g_iAssistTeam[iClient]] = 0;
		
		new iHeldTime = GetTime() - g_iAssistPickupTime[iClient];
		if(!iHeldTime)
			iHeldTime = 1;
		g_iAssistSeconds[iClient] += iHeldTime;
		g_iAssistSecondsCombined[g_iAssistTeam[iClient]] += iHeldTime;
		
		new Float:flPercent, iAssistPoints;
		for(new i=1; i<=g_iMaxPlayers; i++)
		{
			if(i == iClient)
				continue;
			
			if(IsClientInGame(i))
			{
				if(g_iAssistTeam[i] == g_iAssistTeam[iClient])
				{
					flPercent = float(g_iAssistSeconds[i]) / g_iAssistSecondsCombined[g_iAssistTeam[iClient]];
					iAssistPoints = RoundFloat(g_iFlagCapPoints * flPercent);
					SetAssistPoints(i, iAssistPoints);
				}
			}
		}
		
		ResetTeamAssists(g_iAssistTeam[iClient]);
	}
	
	return;
}

FlagReturned(const String:szMessage[])
{
	new Handle:hRegex = INVALID_HANDLE;
	
	hRegex = CompileRegex("flag_name \"(.+?)\"");
	if(hRegex != INVALID_HANDLE)
	{
		new String:szFlagName[32];
		
		MatchRegex(hRegex, szMessage);
		GetRegexSubString(hRegex, 1, szFlagName, sizeof(szFlagName)-1);
		
		if(StrEqual(g_szTeamEnemyFlagName[2], szFlagName))
			ResetTeamAssists(2);
		else if(StrEqual(g_szTeamEnemyFlagName[3], szFlagName))
			ResetTeamAssists(3);
		else if(StrEqual(g_szTeamEnemyFlagName[4], szFlagName))
			ResetTeamAssists(4);
		else if(StrEqual(g_szTeamEnemyFlagName[5], szFlagName))
			ResetTeamAssists(5);
	}
}

ResetTeamAssists(const iTeam)
{
	g_iWhoHasFlag[iTeam] = FLAG_BASE;
	
	g_iAssistSecondsCombined[iTeam] = 0;
	
	for(new i=1; i<=g_iMaxPlayers; i++)
	{
		if(g_iAssistTeam[i] == iTeam)
		{
			g_iAssistTeam[i] = 0;
			g_iAssistSeconds[i] = 0;
		}
	}
}

SetAssistPoints(iClient, iPoints)
{
	if(iPoints < 1)
		return;
	
	new iTotalPoints;
	iTotalPoints = GetEntProp(iClient, Prop_Data, "m_iFortPoints") + iPoints;
	
	SetPlayerLatestFortPoints("Flag Cap Assist", iPoints, iClient);
	SetPlayerTotalFortPoints(iTotalPoints, iClient);
	SetEntProp(iClient, Prop_Data, "m_iFortPoints", iTotalPoints);
	
	decl String:szName[32], String:szSteamID[32], String:szTeamName[32], iUserID;
	iUserID = GetClientUserId(iClient);
	GetClientName(iClient, szName, sizeof(szName)-1);
	GetClientAuthString(iClient, szSteamID, sizeof(szSteamID)-1);
	GetTeamName(g_iAssistTeam[iClient], szTeamName, sizeof(szTeamName)-1);
	
	LogToGame("\"%s<%i><%s><%s>\" triggered \"flag_assist\" (points \"%i\")", szName, iUserID, szSteamID, szTeamName, iPoints);
	
	return;
}

SetDefendPoints(iClient, iPoints, iMode=0)
{
	/*
	* 	iMode = 0: Killed player near flag.
	* 	iMode = 1: Killed flag carrier.
	*/
	
	if(iPoints < 1)
		return;
	
	new iTotalPoints;
	iTotalPoints = GetEntProp(iClient, Prop_Data, "m_iFortPoints") + iPoints;
	
	SetPlayerLatestFortPoints("Enemy Kill + Flag Defend", iPoints + 100, iClient); // Show player kill too
	
	SetPlayerTotalFortPoints(iTotalPoints, iClient);
	SetEntProp(iClient, Prop_Data, "m_iFortPoints", iTotalPoints);
	
	decl String:szName[32], String:szSteamID[32], String:szTeamName[32], iUserID;
	iUserID = GetClientUserId(iClient);
	GetClientName(iClient, szName, sizeof(szName)-1);
	GetClientAuthString(iClient, szSteamID, sizeof(szSteamID)-1);
	GetTeamName(GetEntProp(iClient, Prop_Send, "m_iTeamNum"), szTeamName, sizeof(szTeamName)-1);
	
	if(iMode)
		LogToGame("\"%s<%i><%s><%s>\" triggered \"flag_defend_carrier\" (points \"%i\")", szName, iUserID, szSteamID, szTeamName, iPoints);
	else
		LogToGame("\"%s<%i><%s><%s>\" triggered \"flag_defend\" (points \"%i\")", szName, iUserID, szSteamID, szTeamName, iPoints);
	
	return;
}

public Action:hook_FlagStatus(iClient, iArgs)
{
	if(!IsValidEntity(iClient))
		return Plugin_Handled;
	
	if(!g_bIsMapCTF)
	{
		SayText("^6-^7This is not a CTF map.", 1, iClient);
		return Plugin_Handled;
	}
	
	new iTeam = GetEntProp(iClient, Prop_Send, "m_iTeamNum");
	if(iTeam < 2)
		return Plugin_Handled;
	
	new iEnemyCarrier, iEnemyTeam, bool:bFlagDropped;
	for(new i=2; i<sizeof(g_iWhoHasFlag); i++)
	{
		if(iTeam == i)
			continue;
		
		if(g_iWhoHasFlag[i] > 0)
		{
			iEnemyTeam = i;
			iEnemyCarrier = g_iWhoHasFlag[i];
			break;
		}
		else if(g_iWhoHasFlag[i] == FLAG_DROPPED)
		{
			iEnemyTeam = i;
			bFlagDropped = true;
			break;
		}
	}
	
	// Your flag status
	decl String:szText[128];
	if(iEnemyCarrier)
	{
		decl String:szEnemyName[32];
		GetClientName(iEnemyCarrier, szEnemyName, sizeof(szEnemyName)-1);
		Format(szText, sizeof(szText)-1, "^6-^7Your flag is being carried by ^6[^5%s^6] [^%i%s^6]", szEnemyName, g_iFlagLocColor[iEnemyTeam], g_szFlagLocation[iEnemyTeam]);
		SayText(szText, 1, iClient);
	}
	else if(bFlagDropped)
	{
		Format(szText, sizeof(szText)-1, "^6-^7Your flag is lying around the ^6[^%i%s^6]", g_iFlagLocColor[iEnemyTeam], g_szFlagLocation[iEnemyTeam]);
		SayText(szText, 1, iClient);
	}
	else
		SayText("^6-^7Your flag is in your base.", 1, iClient);
	
	// Enemy flag status
	if(g_iWhoHasFlag[iTeam] == iClient)
	{
		Format(szText, sizeof(szText)-1, "^6-^7The enemy flag is being carried by ^6[^5You^6] [^%i%s^6]", g_iFlagLocColor[iTeam], g_szFlagLocation[iTeam]);
		SayText(szText, 1, iClient);
	}
	else if(g_iWhoHasFlag[iTeam] > 0)
	{
		decl String:szName[32];
		GetClientName(g_iWhoHasFlag[iTeam], szName, sizeof(szName)-1);
		Format(szText, sizeof(szText)-1, "^6-^7The enemy flag is being carried by ^6[^5%s^6] [^%i%s^6]", szName, g_iFlagLocColor[iTeam], g_szFlagLocation[iTeam]);
		SayText(szText, 1, iClient);
	}
	else if(g_iWhoHasFlag[iTeam] == FLAG_DROPPED)
	{
		Format(szText, sizeof(szText)-1, "^6-^7The enemy flag is lying around the ^6[^%i%s^6]", g_iFlagLocColor[iTeam], g_szFlagLocation[iTeam]);
		SayText(szText, 1, iClient);
	}
	else
		SayText("^6-^7The enemy flag is in their base.", 1, iClient);
	
	return Plugin_Handled;
}

public Action:hook_say(iClient, iArgs)
{
	if(!g_bIsMapCTF)
		return Plugin_Continue;
	
	decl String:szString[128];
	GetCmdArgString(szString, sizeof(szString)-1);
	
	if((StrContains(szString, "triggered \"flag_touch\"") != -1)
	|| (StrContains(szString, "triggered \"flag_thrown\"") != -1)
	|| (StrContains(szString, "triggered \"flag_dropped\"") != -1)
	|| (StrContains(szString, "triggered \"flag_capture\"") != -1)
	|| (StrContains(szString, "triggered \"flag_returned\"") != -1))
		return Plugin_Handled;
	
	return Plugin_Continue;
}

public cvar_AssistPool(Handle:hConVar, const String:szOldValue[], const String:szNewValue[])
{
	new iNewValue = StringToInt(szNewValue);
	if(iNewValue >= 10)
		g_iFlagCapPoints = iNewValue;
}

public cvar_DefendPoints(Handle:hConVar, const String:szOldValue[], const String:szNewValue[])
{
	new iNewValue = StringToInt(szNewValue);
	if(iNewValue >= 1)
		g_iDefendPoints = iNewValue;
}

stock SetPlayerLatestFortPoints(const String:szText[], const iPoints, const iClient=0)
{
	new Handle:hBf;
	if(iClient <= 0)
		hBf = StartMessageAll("SetPlayerLatestFortPoints");
	else
		hBf = StartMessageOne("SetPlayerLatestFortPoints", iClient);
	BfWriteString(hBf, szText);
	BfWriteShort(hBf, iPoints);
	EndMessage();
}

stock SetPlayerTotalFortPoints(const iPoints, const iClient=0)
{
	new Handle:hBf;
	if(iClient <= 0)
		hBf = StartMessageAll("SetPlayerTotalFortPoints");
	else
		hBf = StartMessageOne("SetPlayerTotalFortPoints", iClient);
	BfWriteNum(hBf, iPoints);
	EndMessage();
}

stock SayText(const String:szText[], const iColor=1, const iClient=0)
{
	new String:szFormat[1024];
	FormatEx(szFormat, sizeof(szFormat)-1, "\x02%s\x0D\x0A", szText);
	
	new Handle:hBf;
	if(iClient <= 0)
		hBf = StartMessageAll("SayText");
	else
	{
		EmitSoundToClient(iClient, SOUND_CHAT);
		hBf = StartMessageOne("SayText", iClient);
	}
	BfWriteString(hBf, szFormat);
	BfWriteByte(hBf, iColor);
	EndMessage();
}