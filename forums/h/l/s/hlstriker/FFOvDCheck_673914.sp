/*	=============================================
*	- NAME:
*	  + FF OvD Enforce
*
*	- DESCRIPTION:
*	  + This plugin will enforce Offense VS Defense game play if there
*	  + are a certain amount of players in the server.
*	  + 
*	  + When OvD is activated players will be assigned to certain teams
*	  + so the teams are even.
*	  + 
*	  + If there is an odd amount of players on the server then defense
*	  + will gain the remainder.
*	  + 
*	  + Defense can only use: Sniper, Soldier, Demoman, HWGuy, Engineer.
*	  + 
*	  + Offense can only use: Scout, Soldier, Medic, Pyro, Spy.
*
* 	
*	-------------
*	Server cvars:
*	-------------
*	- sv_ovdenabled <1/0>
*	 + Enables/Disables OvD Enforcement.
*	
*	- sv_ovdmaxplayernum <amount>
*	 + Max number of players in server for OvD to be active.
*	
*	- sv_ovdminplayernum <amount>
*	 + Min number of players in server for OvD to be active.
*	
* 	
*	----------
*	Changelog:
*	----------
*	Version 1.0 ( 08-22-2008 )
*	-- Initial release.
*	
*	Version 1.1 ( 08-22-2008 )
*	-- Added auto-detection if plugin should be enabled or disabled for map type.
*	-- Added blacklist file for maps that admin wants to manually disable plugin for.
*	-- Added Demoman as an Offensive and Defensive class.
*/


#include <sourcemod>
#include <sdktools_functions>

#define VERSION "1.1"
public Plugin:myinfo = 
{
	name = "FF OvD Enforce",
	author = "hlstriker",
	description = "Enforces Offense VS Defense",
	version = VERSION,
	url = "None"
}

enum
{
	TEAM_NONE = 0,
	TEAM_SPEC,
	TEAM_BLUE,
	TEAM_RED,
	TEAM_YELLOW,
	TEAM_GREEN
}

enum
{
	CLASS_CIVILIAN = 0,
	CLASS_SCOUT,
	CLASS_SNIPER,
	CLASS_SOLDIER,
	CLASS_DEMOMAN,
	CLASS_MEDIC,
	CLASS_HWGUY,
	CLASS_PYRO,
	CLASS_SPY,
	CLASS_ENGINEER
}

new String:g_szClassNames[][] =
{
	"civilian",
	"scout",
	"sniper",
	"soldier",
	"demoman",
	"medic",
	"hwguy",
	"pyro",
	"spy",
	"engineer"
}

#define MAX_PLAYERS 22
new g_iBluePlayers[MAX_PLAYERS];
new g_iRedPlayers[MAX_PLAYERS];
new g_iTotalBlue;
new g_iTotalRed;

new g_iSavedClass[MAX_PLAYERS+1];
new g_iTeam[MAX_PLAYERS+1];
new bool:g_mCanChangeClass[MAX_PLAYERS+1];
new bool:g_mIsOVD;
new g_iMaxPlayers;

new Float:g_flBlueFlagOrigin[3];
new g_iBlueFlag;

new bool:g_mEnabled;
new Handle:g_hEnabledCVar;
new Handle:g_hMaxCvar;
new Handle:g_hMinCvar;

public OnPluginStart()
{
	CreateConVar("sv_ffovdcheckver", VERSION, "The version of FF OvD Enforce.", FCVAR_NOTIFY);
	g_hEnabledCVar = CreateConVar("sv_ovdenabled", "1", "Enables/Disables OvD Enforcement.", 0, true, 0.0, true, 1.0);
	g_hMaxCvar = CreateConVar("sv_ovdmaxplayernum", "12", "Max number of players in server for OvD to be active", 0, true, 8.0, true, 14.0);
	g_hMinCvar = CreateConVar("sv_ovdminplayernum", "3", "Min number of players in server for OvD to be active", 0, true, 1.0, true, 4.0);
	
	HookEvent("player_team", event_team, EventHookMode_Post);
	HookEvent("player_changeclass", event_changeclass, EventHookMode_Post);
	
	RegConsoleCmd("team", hook_Team);
	RegConsoleCmd("class", hook_Class);
}

public OnClientAuthorized(iClient)
{
	g_mCanChangeClass[iClient] = true;
	g_iTeam[iClient] = 0;
}

public Action:hook_Team(iClient, iArgs)
{
	decl String:szArg1[32];
	GetCmdArg(1, szArg1, sizeof(szArg1)-1);
	
	if(StrEqual(szArg1, "spec", false))
		return Plugin_Continue;
	else if(g_mIsOVD)
	{
		if(g_iTeam[iClient] == TEAM_BLUE && !StrEqual(szArg1, "blue", false))
		{
			PrintToChat(iClient, "[ALERT] Offense VS Defense is active. You can't switch teams right now.");
			g_mCanChangeClass[iClient] = false;
			return Plugin_Handled;
		}
		else if(g_iTeam[iClient] == TEAM_RED && !StrEqual(szArg1, "red", false))
		{
			PrintToChat(iClient, "[ALERT] Offense VS Defense is active. You can't switch teams right now.");
			g_mCanChangeClass[iClient] = false;
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

public Action:hook_Class(iClient, iArgs)
{
	if(g_mIsOVD && !g_mCanChangeClass[iClient])
	{
		g_mCanChangeClass[iClient] = true;
		return Plugin_Handled;
	}
	else if(g_mIsOVD)
	{
		decl String:szArg1[32];
		GetCmdArg(1, szArg1, sizeof(szArg1)-1);
		
		if(g_iTeam[iClient] == TEAM_BLUE)
		{
			// Don't let them choose D classes (solly/demo is O and D)
			if(StrEqual(szArg1, g_szClassNames[CLASS_ENGINEER], false)
			|| StrEqual(szArg1, g_szClassNames[CLASS_HWGUY], false)
			|| StrEqual(szArg1, g_szClassNames[CLASS_SNIPER], false))
			{
				PrintToChat(iClient, "[ALERT] You are on Offense. Please choose an Offensive class.");
				ClientCommand(iClient, "changeclass");
				return Plugin_Handled;
			}
		}
		else if(g_iTeam[iClient] == TEAM_RED)
		{
			// Don't let them choose O classes (solly/demo is O and D)
			if(StrEqual(szArg1, g_szClassNames[CLASS_MEDIC], false)
			|| StrEqual(szArg1, g_szClassNames[CLASS_PYRO], false)
			|| StrEqual(szArg1, g_szClassNames[CLASS_SCOUT], false)
			|| StrEqual(szArg1, g_szClassNames[CLASS_SPY], false))
			{
				PrintToChat(iClient, "[ALERT] You are on Defense. Please choose a Defensive class.");
				ClientCommand(iClient, "changeclass");
				return Plugin_Handled;
			}
		}
	}
	
	return Plugin_Continue;
}

public OnMapStart()
{
	g_mIsOVD = false;
	g_iTotalBlue = 0;
	g_iTotalRed = 0;
	
	if(GetConVarInt(g_hEnabledCVar))
	{
		g_mEnabled = true;
		GetFlagData();
	}
	else
		g_mEnabled = false;
}

public OnConfigsExecuted()
{
	new String:szBuffer[128], String:szMapName[32], Handle:hFile = INVALID_HANDLE;
	GetCurrentMap(szMapName, sizeof(szMapName)-1);
	BuildPath(Path_SM, szBuffer, sizeof(szBuffer)-1, "configs/ovdmapblacklist.ini");
	hFile = OpenFile(szBuffer, "r");
	while(!IsEndOfFile(hFile))
	{
		if(ReadFileLine(hFile, szBuffer, sizeof(szBuffer)))
		{
			if(szBuffer[0] == ';' || strlen(szBuffer) < 2)
				continue;
			
			TrimString(szBuffer);
			if(StrEqual(szBuffer, szMapName, false))
			{
				g_mEnabled = false;
				break;
			}
		}
	}
}

public Action:event_changeclass(Handle:hEvent, const String:szEventName[], bool:mDontBroadcast)
{
	if(!g_mEnabled)
		return Plugin_Continue;
	
	g_iSavedClass[GetClientOfUserId(GetEventInt(hEvent, "userid"))] = GetEventInt(hEvent, "newclass");
	
	return Plugin_Continue;
}

public Action:event_team(Handle:hEvent, const String:szEventName[], bool:mDontBroadcast)
{
	if(!g_mEnabled)
		return Plugin_Continue;
	
	static iClient, iNewTeam, iOldTeam;
	iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	iNewTeam = GetEventInt(hEvent, "team");
	iOldTeam = GetEventInt(hEvent, "oldteam");
	g_iTeam[iClient] = iNewTeam;
	
	if(iNewTeam == TEAM_BLUE)
		g_iTotalBlue++;
	else if(iNewTeam == TEAM_RED)
		g_iTotalRed++;
	
	if(iOldTeam == TEAM_BLUE)
		g_iTotalBlue--;
	else if(iOldTeam == TEAM_RED)
		g_iTotalRed--;
	
	AddPlayerToTeam(iClient, iNewTeam);
	RemovePlayerFromTeam(iClient, iOldTeam);
	CreateTimer(0.1, CheckForOvD);
	
	return Plugin_Continue;
}

public Action:TimerNotifyPos(Handle:hTimer)
{
	if(g_mIsOVD)
	{
		for(new i=1; i<=g_iMaxPlayers; i++)
		{
			if(!IsClientConnected(i))
				continue;
			
			if(g_iTeam[i] == TEAM_BLUE)
				PrintToChat(i, "[ALERT] You are on Offense. Go get the enemy flag!");
			else if(g_iTeam[i] == TEAM_RED)
				PrintToChat(i, "[ALERT] You are on Defense. Guard your teams flag!");
		}
	}
}

public Action:CheckForOvD(Handle:hTimer)
{
	// Check to see if it should be OvD
	static iTotal, i;
	iTotal = g_iTotalBlue + g_iTotalRed;
	if(iTotal <= GetConVarInt(g_hMaxCvar) && iTotal >= GetConVarInt(g_hMinCvar))
	{
		// There are 12 or less players, make OvD
		if(!g_mIsOVD)
		{
			// Notify the server is going into OvD mode
			g_mIsOVD = true;
			CreateTimer(2.0, TimerNotifyPos);
			
			static String:szText[32];
			Format(szText, sizeof(szText)-1, "-=[ OvD is now activated ]=-");
			GameMessage(szText, 0);
			
			for(i=1; i<=g_iMaxPlayers; i++)
			{
				if(!IsClientConnected(i))
					continue;
				
				CheckPlayerClass(i);
				ClientCommand(i, "speak \"vox/robot/o v d is now activated\"");
			}
			
			// Make the blue flag untouchable
			static Float:flOrigin[3];
			GetEntPropVector(g_iBlueFlag, Prop_Data, "m_vecOrigin", flOrigin);
			flOrigin[2] -= 999999;
			TeleportEntity(g_iBlueFlag, flOrigin, NULL_VECTOR, NULL_VECTOR);
		}
		
		static iUnevenBy, iClient, iSlot;
		if(iTotal % 2 == 0)
		{
			// Teams CAN be even, make sure they are
			if(g_iTotalBlue > g_iTotalRed)
			{
				// More blue than red, move the extra players to red
				iSlot = g_iTotalBlue;
				iUnevenBy = (g_iTotalBlue - g_iTotalRed) / 2; // Divide by 2 so you only move half, or other team would then have more
				for(i=0; i<iUnevenBy; i++)
				{
					iSlot--;
					iClient = g_iBluePlayers[iSlot];
					FF_ChangeTeam(iClient, TEAM_RED);
					
					AddPlayerToTeam(iClient, TEAM_RED);
					RemovePlayerFromTeam(iClient, TEAM_BLUE);
					
					g_iTotalRed++;
					g_iTotalBlue--;
				}
			}
			else if(g_iTotalRed > g_iTotalBlue)
			{
				// More red than blue, move the extra players to blue
				iSlot = g_iTotalRed;
				iUnevenBy = (g_iTotalRed - g_iTotalBlue) / 2; // Divide by 2 so you only move half, or other team would then have more
				for(i=0; i<iUnevenBy; i++)
				{
					iSlot--;
					iClient = g_iRedPlayers[iSlot];
					FF_ChangeTeam(iClient, TEAM_BLUE);
					
					AddPlayerToTeam(iClient, TEAM_BLUE);
					RemovePlayerFromTeam(iClient, TEAM_RED);
					
					g_iTotalRed--;
					g_iTotalBlue++;
				}
			}
		}
		else
		{
			// Team can't be even (ex: 5vs6), make red have 1 more than blue
			if(g_iTotalBlue > g_iTotalRed)
			{
				iSlot = g_iTotalBlue;
				iUnevenBy = RoundToCeil((float(g_iTotalBlue) - float(g_iTotalRed)) / 2);
				if(iUnevenBy > 1)
				{
					for(i=0; i<iUnevenBy; i++)
					{
						iSlot--;
						iClient = g_iBluePlayers[iSlot];
						FF_ChangeTeam(iClient, TEAM_RED);
						
						AddPlayerToTeam(iClient, TEAM_RED);
						RemovePlayerFromTeam(iClient, TEAM_BLUE);
						
						g_iTotalRed++;
						g_iTotalBlue--;
					}
				}
			}
			else if(g_iTotalRed > g_iTotalBlue)
			{
				iSlot = g_iTotalRed;
				iUnevenBy = RoundToFloor((float(g_iTotalRed) - float(g_iTotalBlue)) / 2);
				for(i=0; i<iUnevenBy; i++)
				{
					iSlot--;
					iClient = g_iRedPlayers[iSlot];
					FF_ChangeTeam(iClient, TEAM_BLUE);
					
					AddPlayerToTeam(iClient, TEAM_BLUE);
					RemovePlayerFromTeam(iClient, TEAM_RED);
					
					g_iTotalRed--;
					g_iTotalBlue++;
				}
			}
		}
	}
	else
	{
		if(g_mIsOVD)
		{
			// Notify the server is no longer OvD
			g_mIsOVD = false;
			
			static String:szText[32];
			Format(szText, sizeof(szText)-1, "-=[ OvD is deactivated ]=-");
			GameMessage(szText, 0);
			
			for(i=1; i<=g_iMaxPlayers; i++)
			{
				if(!IsClientConnected(i))
					continue;
				
				ClientCommand(i, "speak \"vox/robot/o v d is deactivated\"");
			}
			
			// Make the blue flag touchable
			TeleportEntity(g_iBlueFlag, g_flBlueFlagOrigin, NULL_VECTOR, NULL_VECTOR);
		}
	}
}

RemovePlayerFromTeam(iClient, iTeam)
{
	new iTempArray[g_iMaxPlayers], iSlot, i;
	
	if(iTeam == TEAM_BLUE)
	{
		// Save list of current team array, don't include selected player
		for(i=0; i<g_iMaxPlayers; i++)
		{
			if(!g_iBluePlayers[i])
				break;
			
			if(g_iBluePlayers[i] == iClient)
				continue;
			
			iTempArray[iSlot] = g_iBluePlayers[i];
			iSlot++;
		}
		
		// Now update the real player array
		for(i=0; i<g_iMaxPlayers; i++)
		{
			if(!iTempArray[i])
				break;
			
			g_iBluePlayers[i] = iTempArray[i];
		}
	}
	else if(iTeam == TEAM_RED)
	{
		// Save list of current team array, don't include selected player
		for(i=0; i<g_iMaxPlayers; i++)
		{
			if(!g_iRedPlayers[i])
				break;
			
			if(g_iRedPlayers[i] == iClient)
				continue;
			
			iTempArray[iSlot] = g_iRedPlayers[i];
			iSlot++;
		}
		
		// Now update the real player array
		for(i=0; i<g_iMaxPlayers; i++)
		{
			if(!iTempArray[i])
				break;
			
			g_iRedPlayers[i] = iTempArray[i];
		}
	}
}

AddPlayerToTeam(iClient, iTeam)
{
	new iEmptyCell;
	
	if(iTeam == TEAM_BLUE)
	{
		// Make sure player isn't already in team array
		for(new i=0; i<g_iMaxPlayers; i++)
		{
			if(!g_iBluePlayers[i])
			{
				iEmptyCell = i;
				break;
			}
			
			// If player is on team array, dont add them again
			if(g_iBluePlayers[i] == iClient)
				return 0;
		}
		
		// Add player to team array
		g_iBluePlayers[iEmptyCell] = iClient;
	}
	else if(iTeam == TEAM_RED)
	{
		// Make sure player isn't already in team array
		for(new i=0; i<g_iMaxPlayers; i++)
		{
			if(!g_iRedPlayers[i])
			{
				iEmptyCell = i;
				break;
			}
			
			// If player is on team array, dont add them again
			if(g_iRedPlayers[i] == iClient)
				return 0;
		}
		
		// Add player to team array
		g_iRedPlayers[iEmptyCell] = iClient;
	}
	
	return 0;
}

GetFlagData()
{
	new String:szClassName[32], String:szModel[128], bool:iRedFlag;
	for(new iEnt=0; iEnt<=GetMaxEntities(); iEnt++)
	{
		if(!IsValidEntity(iEnt))
			continue;
		
		GetEdictClassname(iEnt, szClassName, sizeof(szClassName)-1);
		if(StrEqual(szClassName, "info_ff_script"))
		{
			GetEntPropString(iEnt, Prop_Data, "m_ModelName", szModel, sizeof(szModel)-1);
			if(StrEqual(szModel, "models/flag/flag.mdl"))
			{
				switch(GetEntProp(iEnt, Prop_Data, "m_nSkin"))
				{
					case 0:
					{
						g_iBlueFlag = iEnt;
						GetEntPropVector(iEnt, Prop_Data, "m_vecOrigin", g_flBlueFlagOrigin);
					}
					case 1: iRedFlag = true;
					default: g_mEnabled = false;
				}
			}
		}
	}
	
	if(!g_iBlueFlag || !iRedFlag)
		g_mEnabled = false;
	
	if(g_mEnabled)
		g_iMaxPlayers = GetMaxClients();
}

FF_ChangeTeam(iClient, iTeam)
{
	g_iTeam[iClient] = iTeam;
	SetEntProp(iClient, Prop_Data, "m_iTeamNum", iTeam);
	DispatchSpawn(iClient);
}

CheckPlayerClass(iClient)
{
	static iTeam, iClass;
	iTeam = GetEntProp(iClient, Prop_Data, "m_iTeamNum");
	iClass = g_iSavedClass[iClient];
	if(iTeam == TEAM_BLUE)
	{
		if(iClass != CLASS_DEMOMAN && iClass != CLASS_MEDIC && iClass != CLASS_PYRO && iClass != CLASS_SCOUT && iClass != CLASS_SPY && iClass != CLASS_SOLDIER)
			FF_ChangeClass(iClient, CLASS_MEDIC);
	}
	else if(iTeam == TEAM_RED)
	{
		if(iClass != CLASS_DEMOMAN && iClass != CLASS_ENGINEER && iClass != CLASS_HWGUY && iClass != CLASS_SNIPER && iClass != CLASS_SOLDIER)
			FF_ChangeClass(iClient, CLASS_SOLDIER);
	}
}

FF_ChangeClass(iClient, iClass)
{
	g_iSavedClass[iClient] = iClass;
	FakeClientCommandEx(iClient, "class %s", g_szClassNames[iClass]);
	CreateTimer(0.3, TimerSwitchClass, iClient);
}

public Action:TimerSwitchClass(Handle:hTimer, any:iClient)
	DispatchSpawn(iClient);

stock GameMessage(const String:szText[], const iClient)
{
	new String:szFormat[1024];
	FormatEx(szFormat, sizeof(szFormat)-1, "\x01%s\x0D\x0A", szText);
	
	new Handle:hBf;
	if(iClient == 0)
		hBf = StartMessageAll("GameMessage");
	else
		hBf = StartMessageOne("GameMessage", iClient);
	BfWriteString(hBf, szFormat);
	EndMessage();
}