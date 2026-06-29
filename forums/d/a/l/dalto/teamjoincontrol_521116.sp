/*
teamjoincontrol.sp

Description:
	This plugin forces you to autojoin instead of selecting a team when initially joining.
	
Credits:
	Thanks to everyone in the scripting forum.  You guys have been super supportive of all my questions.

Versions:
	1.0
		* Initial Release
		
	1.1
		* Fixed a bug with convars
		* Added admin immunity
		* Added an option to lock the teams
		* Added the ability to force the teams
		
	1.2
		* Added an enable cvar
		* Changed the default value for admin immunity to 1
		* Removed unused function
		* Add sm_team_join_control_stop_spec
		* Added an optional sound
		* Moved the default location of the cfg file
*/


#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define PLUGIN_VERSION "1.2"

#define CSS 0
#define DODS 1

// Plugin definitions
public Plugin:myinfo = 
{
	name = "Auto Join Control",
	author = "dalto",
	description = "This plugin forces you to autojoin instead of selecting a team when initially joining.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

// Global Variables
new g_gameType;
new Handle:g_CvarAdminImmunity = INVALID_HANDLE;
new Handle:g_CvarLockTeams = INVALID_HANDLE;
new Handle:g_CvarForceJoin = INVALID_HANDLE;
new Handle:g_CvarLockTime = INVALID_HANDLE;
new Handle:g_CvarEnable = INVALID_HANDLE;
new Handle:g_CvarStopSpec = INVALID_HANDLE;
new Handle:g_CvarSoundName = INVALID_HANDLE;
new String:g_soundName[PLATFORM_MAX_PATH];
new g_teamList[MAXPLAYERS + 1];
new Handle:g_kv = INVALID_HANDLE;

public OnPluginStart()
{
	CreateConVar("sm_team_join_control_version", PLUGIN_VERSION, "Auto Join Control Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_CvarEnable = CreateConVar("sm_team_join_control_enable", "1", "Set to 1 if you want you admins to be immune");
	g_CvarAdminImmunity = CreateConVar("sm_team_join_control_admin_immunity", "1", "Set to 1 if you want you admins to be immune");
	g_CvarLockTeams = CreateConVar("sm_team_join_control_lock_teams", "0", "Set to 1 if you want to force each player to stay in the teams assigned");
	g_CvarLockTime = CreateConVar("sm_team_join_control_lock_time", "15", "The number of minutes after disconnect before the team lock expires after disconnect");
	g_CvarForceJoin = CreateConVar("sm_team_join_control_force_join", "0", "Set to 1 if you want the player to be autojoined regardless of what they select");
	g_CvarStopSpec = CreateConVar("sm_team_join_control_stop_spec", "0", "Set to 1 if you don't want players who have already joined a team to be able to switch to spectator");
	g_CvarSoundName = CreateConVar("sm_team_join_control_sound_name", "buttons/button11.wav", "The name of the sound to play when an action is denied");
	
	// Determine the mod we are in
	decl String:gameName[20];
	GetGameFolderName(gameName, sizeof(gameName));
	if(StrEqual(gameName, "cstrike"))
	{
		g_gameType = CSS;
	} else if(StrEqual(gameName, "dod")) {
		g_gameType = DODS;
	} else {
		SetFailState("This plugin only works with Counter-Strike:Source or Day of Defeat:Source");
	}
	
	RegConsoleCmd("jointeam", CommandJoinTeam);
	HookEvent("player_team", EventTeamChange, EventHookMode_Post);
	
	g_kv=CreateKeyValues("LockExpiration");
}

public OnClientPutInServer(client)
{
	PrepareClient(client);
}

public OnMapStart()
{
	Prune();
	decl String:buffer[PLATFORM_MAX_PATH];
	GetConVarString(g_CvarSoundName, g_soundName, sizeof(g_soundName));
	if(strcmp(g_soundName, ""))
	{
		PrecacheSound(g_soundName, true);
		Format(buffer, sizeof(buffer), "sound/%s", g_soundName);
		AddFileToDownloadsTable(buffer);
	}
}

public Action:CommandJoinTeam(client, args)
{
	// Check to see if the plugin is enabled
	if(!GetConVarBool(g_CvarEnable))
	{
		return Plugin_Continue;
	}
	
	// Check to see if the client is valid
	if(!client || !IsClientInGame(client) || IsFakeClient(client))
	{
		return Plugin_Continue;
	}
	
	// check admin immunity
	if(GetUserAdmin(client) != INVALID_ADMIN_ID && GetConVarBool(g_CvarAdminImmunity))
	{
		return Plugin_Continue;
	}
	
	// Get the target team
	decl String:teamString[3];
	GetCmdArg(1, teamString, sizeof(teamString));
	new team = StringToInt(teamString);

	// Get the players current team
	new curTeam = GetClientTeam(client);
	
	// Check for join spectator not allowed
	if(curTeam > 1 && team == 1 && GetConVarBool(g_CvarStopSpec))
	{
		Deny(client, "Only players who have not joined a team may spectate");
		return Plugin_Handled;
	}
	
	// Check for team locking concerns
	if(curTeam != 0 && GetConVarBool(g_CvarLockTeams) && team != 1 && g_teamList[client])
	{
		// if autojoin force them back onto their team
		if(team == 0)
		{
			ChangeClientTeam(client, g_teamList[client]);
			return Plugin_Handled;
		}
		
		// check to see if the team they are switching to is the same as their assigned team
		if(team != g_teamList[client])
		{
			Deny(client, "You cannot join that team");
			return Plugin_Handled;
		}
		
		// if we get to here it is safe
		return Plugin_Continue;
	}
	
	// check for force join
	if(team != 1 && GetConVarBool(g_CvarForceJoin))
	{
		// Count the team sizes
		new teamCount[2];
		for(new i = 1; i <= GetMaxClients(); i++) {
			if(IsClientInGame(i) && (GetClientTeam(i) == 2 || GetClientTeam(i) == 3)) {
				teamCount[GetTeamIndex(GetClientTeam(i))]++;
			}
		}
		// Team 2 is bigger
		if(teamCount[GetTeamIndex(2)] > teamCount[GetTeamIndex(3)])
		{
			if(team == 3)
			{
				return Plugin_Continue;
			}
			PrintCenterText(client, "You are being automatically assigned to a team by the server");
			ChangeClientTeam(client, 3);
			return Plugin_Handled;
		}
		// team 3 is bigger
		if(teamCount[GetTeamIndex(2)] < teamCount[GetTeamIndex(3)]) {
			if(team == 2)
			{
				return Plugin_Continue;
			}
			PrintCenterText(client, "You are being automatically assigned to a team by the server");
			ChangeClientTeam(client, 2);
			return Plugin_Handled;
		}
		// the teams are even in size
		PrintCenterText(client, "You are being automatically assigned to a team by the server");
		ChangeClientTeam(client, GetRandomInt(2, 3));
		return Plugin_Handled;
	}		
	// The default case
	if((team == 2 || team == 3) && (curTeam == 1 || curTeam == 0))
	{
		Deny(client, "You must auto join");
		if(g_gameType == CSS)
		{
			ClientCommand(client, "chooseteam");
		}
		else
		{
			ClientCommand(client, "changeteam");
		}
		return Plugin_Handled;
	}
	
	// If we get to here than all is for the good
	return Plugin_Continue;
}

public Action:EventTeamChange(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new team = GetEventInt(event, "team");
	
	if(client && IsClientInGame(client) && !IsFakeClient(client) && (team == 2 || team == 3))
	{
		g_teamList[client] = team;
	}
}

public GetOtherTeam(team)
{
	if(team == 2)
	{
		return 3;
	} else if(team == 3) {
		return 2;
	} else {
		ThrowError("Invalid team sent to GetOtherTeam(), team %i", team);
		return 0;
	}
}

// Given a team id returns the matching index
public GetTeamIndex(team)
{
	return team - 2;
}

// When a user disconnects we need to update their timestamp in kvC4
public OnClientDisconnect(client)
{
	new String:steamId[20];
	if(client && !IsFakeClient(client)) {
		GetClientAuthString(client, steamId, 20);
		KvRewind(g_kv);
		if(KvJumpToKey(g_kv, steamId, true))
		{
			KvSetNum(g_kv, "team", g_teamList[client]);
			KvSetNum(g_kv, "timestamp", GetTime());
		}
	}
}

public PrepareClient(client)
{
	new String:steamId[20];
	if(client)
	{
		if(!IsFakeClient(client))
		{
			// Get the users saved setting or create them if they don't exist
			GetClientAuthString(client, steamId, 20);
			KvRewind(g_kv);
			if(KvJumpToKey(g_kv, steamId))
			{
				if(GetTime() < KvGetNum(g_kv, "timestamp") + GetConVarInt(g_CvarLockTime))
				{
					g_teamList[client] = KvGetNum(g_kv, "team", 0);
					return;
				}
			}
			g_teamList[client] = 0;
		}
	}
}

public Prune()
{
	KvRewind(g_kv);
	if (!KvGotoFirstSubKey(g_kv))
	{
		return;
	}

	for(;;)
	{
		if(GetTime() > KvGetNum(g_kv, "timestamp") + GetConVarInt(g_CvarLockTime))
		{
			if (KvDeleteThis(g_kv) < 1)
			{
				break;
			}
		} else if (!KvGotoNextKey(g_kv)) {
			break;
		}	
	}
}

Deny(client, const String:message[])
{
	if(!client || !IsClientInGame(client) || IsFakeClient(client))
	{
		return;
	}
	
	if(strcmp(g_soundName, ""))
	{
		decl String:buffer[PLATFORM_MAX_PATH + 5];
		Format(buffer, sizeof(buffer), "play %s", g_soundName);
		ClientCommand(client, buffer);
	}
	PrintCenterText(client, message);
}