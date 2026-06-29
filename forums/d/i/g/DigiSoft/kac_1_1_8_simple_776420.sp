/************************************************
 *		Kigen's Anti-Cheat		*
 *----------------------------------------------*
 * Author: Kigen @ codingdirect.com 		*
 * Thanks to: SourceMod Team for covering a lot *
 * of the grunt work. :P			*
 ************************************************
 *		Copyright Notice		*
 *----------------------------------------------*
 * Copyright (c) 2008-09 Max Krivanek aka Kigen	*
 ************************************************
 *		Websites to Visit		*
 *----------------------------------------------*
 * http://www.kigenac.com/ - KAC's home.	*
 * http://www.codingdirect.com/	- My website	*
 * http://www.n00bsalad.net/ - Best servers on  *
 * the west coast. Users of KAC private version.*
 ************************************************
 * 		 Version History		*
 * ---------------------------------------------*
 * 1.0 Public - Initial Released Public Version *
 * 1.0.1 Pub - Removed useless dependencies.	*
 * 1.0.2 Pub - Fixed round_freeze_end for 	*
 * servers that don't have it. :P		*
 * 1.1 Pub - Added Cafe banning and using KAC	*
 * global banlist.  Added blocking names with	*
 * multibyte characters.  Fixed possible error	*
 * with format.					*
 * 1.1.1 Pub - Fixed problem with replication. 	*
 * 1.1.2 Pub - Replaced bobcycle cvar check.	*
 * 1.1.3 Pub - Fixed problems relating to mis-	*
 * documented/used functions in SourceMod.	*
 * 1.1.4 Pub - Fixed various bugs.  Reworked 	*
 * some of the code. Added logging to separate 	*
 * file. Now requires Sockets for use.  Added 	*
 * support for MySQL bans.			*
 * 1.1.5 Pub - Some new things, probably more 	*
 * than needed but shouldn't affect KAC's 	*
 * performance.  Added check for mat_dxlevel. 	*
 * 1.1.6 Pub - Fixed an error preventing a ban. *
 * 1.1.7 Pub - Updated various things.  Added	*
 * update checker to check for updates. 	*
 * Optimizations have been done as well.	*
 * 1.1.8 Pub - Added Spam Checking.  More	*
 * optimizations to the code.  Added define to	*
 * exclude Sockets at will.			*
 ************************************************
 * 		     License			*
 *----------------------------------------------*
 * All below code is to be covered under the 	*
 * GPL v3 or a later version.			*
 * http://www.gnu.org/licenses/gpl-3.0.txt	*
 ************************************************
 *		      Notes			*
 *----------------------------------------------*
 * This is a public version of the plugin.  It  *
 * is indeed pretty much KAC as it stands now,  *
 * however, it will not recieve all the future  *
 * features that maybe added to my own private  *
 * version of the plugin.  What made me decide  *
 * to go ahead and release a public version of  *
 * this plugin is the release of other similar  *
 * plugins such as ES Anti-Cheat and VBAC.	*
 * Since they currently use the Query ConVar	*
 * feature present in the Source engine they're *
 * likely to get bypassed or dodged due to the  *
 * releases.  Because of this I decided to go   *
 * ahead and give the community something 	*
 * useful instead of just these little plugins  *
 * that only detect sv_cheats and in the case   *
 * of VBAC mat_wireframe.			*
 * Also note that this was originally built  	*
 * before the releases of both above said ACs.	*
 ************************************************

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

    **** DO NOT MODIFY THE ABOVE NOTICES PLEASE! (Unless just to note additions.) ****

*/

#define SOCKET_ENABLED  // Comment this line out to disable Sockets.

#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION "1.1.8"
#define MAX_HACKCVAR 33 // !!!!!!! If you add mat_dxlevel back make sure you change this!!!!!!!!!!!!!!!!!
#define MAX_WEAPONS 24

// Connection States
#define CS_NOTCONN 	0
#define CS_CONNING 	1
#define CS_AUTHED 	2
#define CS_VALIDATED 	3
#define CS_BOT 		4
#define CS_BANNING	5

// Action Types
#define ACTION_BAN 	0
#define ACTION_KICK	1
#define ACTION_WARN	2

// Compare Types
#define COMP_EQUAL	0
#define COMP_LESS	1
#define COMP_GREATER	2

new const String:g_CompareString[3][] = { "equal to", "less than or equal to", "greater than or equal to" };

// Booleans
new bool:Enabled = true;
new ConnState[MAXPLAYERS+1] = {CS_NOTCONN, ...};
new count[MAXPLAYERS+1] = {0,...};

// CVAR Handles
new Handle:CVar_BlockNameCopy = INVALID_HANDLE;
new Handle:CVar_Cheats = INVALID_HANDLE;
new Handle:CVar_BlockMultiByte = INVALID_HANDLE;
new Handle:CVar_Enable = INVALID_HANDLE;

// Timer handles.
new Handle:PTimer[MAXPLAYERS+1] = {INVALID_HANDLE, ...};

// Reason Strings
new String:g_Reason[MAXPLAYERS+1][512];
new String:g_Reason2[MAXPLAYERS+1][512];

// Arrays
new Handle:CacheAuthArray = INVALID_HANDLE;
new Handle:CacheReasonArray = INVALID_HANDLE;

/* Cvars to protect
 * If you wish to add more CVars then please make sure they are replicated properly on normal clients
 * and that you add at the end of this list and add the proper value for that CVar at the end of 
 * g_HackCVarValues.  You will also need to add one to MAX_HACKCVAR.
 */
new String:g_HackCVars[][] = {
	"cl_clock_correction", 	// 15	0
	"cl_leveloverview",	// 9 	1
	"cl_overdraw_test",	//	2
	"cl_particles_show_bbox", // 11	3
	"cl_phys_timescale",	//	4
	"cl_showevents",	//	5
	"fog_enable",		// 7	6
	"host_timescale",	// 2	7
	"mat_fillrate",		// 8	8
	"mat_proxy",		// 5	9
	"mat_wireframe",	//	10
	"mem_force_flush",	// 10	11
	"snd_show",		// 17	12
	"snd_visualize",	// 18	13
	"sv_cheats",		// 0	14
	"sv_consistency",	// 3	15
	"sv_gravity",		// 1	16
	"r_aspectratio",	// 14	17
	"r_colorstaticprops",	// 19	18
	"r_DispWalkable",	// 20	19
	"r_DrawBeams",		// 21	20
	"r_drawbrushmodels",	// 22	21
	"r_drawclipbrushes",	// 23	22
	"r_drawdecals",		// 24	23
	"r_drawentities",	//	24
	"r_drawopaqueworld",	//	25
	"r_drawothermodels",	// 16	26
	"r_drawparticles",	// 4	27
	"r_drawrenderboxes",	// 12	28
	"r_drawtranslucentworld", //	29
	"r_shadowwireframe",	// 6	30
	"r_skybox",		//	31
	"r_visocclusion",	//	32
	"vcollide_wireframe"	// 13	33
//	"cl_bobcycle"		//	34
//	"mat_dxlevel"		//	35
};
new Float:g_HackCVarValues[] = {
	1.0, // cl_clock_correction	15	0
	0.0, // cl_leveloverview	9	1
	0.0, // cl_overdraw_test		2
	0.0, // cl_particles_show_bbox	11	3
	1.0, // cl_phys_timescale		4
	0.0, // cl_showevents			5
	1.0, // fog_enable		7	6
	1.0, // host_timescale		2	7
	0.0, // mat_fillrate		8	8
	0.0, // mat_proxy		5	9
	0.0, // mat_wireframe			10
	0.0, // mem_force_flush		10	11
	0.0, // snd_show		17	12
	0.0, // snd_visualize		18	13
	0.0, // sv_cheats		0	14
	1.0, // sv_consistency		3	15
	800.0, // sv_gravity		1	16
	0.0, // r_aspectratio		14	17
	0.0, // r_colorstaticprops	19	18
	0.0, // r_DispWalkable		20	19
	1.0, // r_DrawBeams		21	20
	1.0, // r_drawbrushmodels	22	21
	0.0, // r_drawclipbrushes	23	22
	1.0, // r_drawdecals		24	23
	1.0, // r_drawentities			24
	1.0, // r_drawopaqueworld		25
	1.0, // r_drawothermodels	16	26
	1.0, // r_drawparticles		4	27
	0.0, // r_drawrenderboxes	12	28
	1.0, // r_drawtranslucentworld		29
	0.0, // r_shadowwireframe	6	30
	1.0, // r_skybox			31
	0.0, // r_visocclusion			32
	0.0  // vcollide_wireframe	13	33
//	0.8  // cl_bobcycle			34
//	80.0 // mat_dxlevel			35
};
new g_HackCVarsComp[] = {
	COMP_EQUAL, // cl_clock_correction	15	0
	COMP_EQUAL, // cl_leveloverview	9	1
	COMP_EQUAL, // cl_overdraw_test		2
	COMP_EQUAL, // cl_particles_show_bbox	11	3
	COMP_EQUAL, // cl_phys_timescale		4
	COMP_EQUAL, // cl_showevents			5
	COMP_EQUAL, // fog_enable		7	6
	COMP_EQUAL, // host_timescale		2	7
	COMP_EQUAL, // mat_fillrate		8	8
	COMP_EQUAL, // mat_proxy		5	9
	COMP_EQUAL, // mat_wireframe			10
	COMP_EQUAL, // mem_force_flush		10	11
	COMP_EQUAL, // snd_show		17	12
	COMP_EQUAL, // snd_visualize		18	13
	COMP_EQUAL, // sv_cheats		0	14
	COMP_EQUAL, // sv_consistency		3	15
	COMP_EQUAL, // sv_gravity		1	16
	COMP_EQUAL, // r_aspectratio		14	17
	COMP_EQUAL, // r_colorstaticprops	19	18
	COMP_EQUAL, // r_DispWalkable		20	19
	COMP_EQUAL, // r_DrawBeams		21	20
	COMP_EQUAL, // r_drawbrushmodels	22	21
	COMP_EQUAL, // r_drawclipbrushes	23	22
	COMP_EQUAL, // r_drawdecals		24	23
	COMP_EQUAL, // r_drawentities			24
	COMP_EQUAL, // r_drawopaqueworld		25
	COMP_EQUAL, // r_drawothermodels	16	26
	COMP_EQUAL, // r_drawparticles		4	27
	COMP_EQUAL, // r_drawrenderboxes	12	28
	COMP_EQUAL, // r_drawtranslucentworld		29
	COMP_EQUAL, // r_shadowwireframe	6	30
	COMP_EQUAL, // r_skybox			31
	COMP_EQUAL, // r_visocclusion			32
	COMP_EQUAL  // vcollide_wireframe	13	33
//	COMP_EQUAL  // cl_bobcycle			34
//	COMP_GREATER // mat_dxlevel			35
};
new g_HackCVarsAction[] = {
	ACTION_BAN, // cl_clock_correction	15	0
	ACTION_BAN, // cl_leveloverview	9	1
	ACTION_BAN, // cl_overdraw_test		2
	ACTION_BAN, // cl_particles_show_bbox	11	3
	ACTION_BAN, // cl_phys_timescale		4
	ACTION_BAN, // cl_showevents			5
	ACTION_BAN, // fog_enable		7	6
	ACTION_BAN, // host_timescale		2	7
	ACTION_BAN, // mat_fillrate		8	8
	ACTION_BAN, // mat_proxy		5	9
	ACTION_BAN, // mat_wireframe			10
	ACTION_BAN, // mem_force_flush		10	11
	ACTION_BAN, // snd_show		17	12
	ACTION_BAN, // snd_visualize		18	13
	ACTION_BAN, // sv_cheats		0	14
	ACTION_BAN, // sv_consistency		3	15
	ACTION_BAN, // sv_gravity		1	16
	ACTION_KICK, // r_aspectratio		14	17
	ACTION_BAN, // r_colorstaticprops	19	18
	ACTION_BAN, // r_DispWalkable		20	19
	ACTION_BAN, // r_DrawBeams		21	20
	ACTION_BAN, // r_drawbrushmodels	22	21
	ACTION_BAN, // r_drawclipbrushes	23	22
	ACTION_BAN, // r_drawdecals		24	23
	ACTION_BAN, // r_drawentities			24
	ACTION_BAN, // r_drawopaqueworld		25
	ACTION_BAN, // r_drawothermodels	16	26
	ACTION_BAN, // r_drawparticles		4	27
	ACTION_BAN, // r_drawrenderboxes	12	28
	ACTION_BAN, // r_drawtranslucentworld		29
	ACTION_BAN, // r_shadowwireframe	6	30
	ACTION_BAN, // r_skybox			31
	ACTION_BAN, // r_visocclusion			32
	ACTION_BAN  // vcollide_wireframe	13	33
//	ACTION_KICK // cl_bobcycle			34
//	ACTION_KICK // mat_dxlevel			35
};

new Handle:g_HackCVarHandles[MAX_HACKCVAR+1] = {INVALID_HANDLE, ...};
new g_HackCheckOrder[MAX_HACKCVAR*2+2] = {0, ...};
new CVarI[MAXPLAYERS+1];

public Plugin:myinfo =
{
    name = "Kigen's Anti-Cheat", 
    author = "Kigen", 
    description = "The cheats stop here!", 
    version = PLUGIN_VERSION, 
    url = "http://www.kigenac.com/"
};

public OnPluginStart()
{
	decl Handle:cvar, String:name[64], bool:comm, flags, Handle:t_ConVar, String:t_String[256], bool:isRPG;

	isRPG = false;
	CacheAuthArray = CreateArray(64);
	CacheReasonArray = CreateArray(256);

	if ( !HookEventEx("player_changename", EventNameChange) )
		LogError("Unable to hook player_changename");

	CreateConVar("kac_version", PLUGIN_VERSION, "KAC version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	CVar_BlockNameCopy = CreateConVar("kac_block_namecopy", "0", "Blocks name copying and short names (name < 3)");
	CVar_BlockMultiByte = CreateConVar("kac_block_multibyte_names", "0", "Blocks the usage of multibyte characters in a name.");
	CVar_Enable = CreateConVar("kac_enable", "1", "Enables/Disables KAC's cheat detection. (Does not affect other features.)");
	CVar_Cheats = FindConVar("sv_cheats");
	SetConVarInt(CVar_Cheats, 0, true);

	if ( CVar_BlockNameCopy == INVALID_HANDLE || CVar_BlockMultiByte == INVALID_HANDLE || CVar_Cheats == INVALID_HANDLE )
		SetFailState("Unable to create/hook needed convars.");

	// Hook sv_cheats if server is not RPG.
	t_ConVar = FindConVar("cssrpg_enable");
	if ( t_ConVar != INVALID_HANDLE )
	{
		isRPG = true;
		CloseHandle(t_ConVar);
	}
	else
		HookConVarChange(CVar_Cheats, CheatsChange);
	HookConVarChange(CVar_Enable, EnableChange);
	
	// Hook replicated convars and cheat commands.
	cvar = FindFirstConCommand(name, sizeof(name), comm, flags);
	if (cvar == INVALID_HANDLE)
		SetFailState("Failed getting first command/convar.");
	do
	{
		if (!comm && (flags & FCVAR_REPLICATED) && ( !StrEqual(name, "sv_cheats") ) ) // RPG is funky.
		{
			t_ConVar = FindConVar(name);
			if ( t_ConVar == INVALID_HANDLE ) // wtf protection
				continue;
			GetConVarString(t_ConVar, t_String, sizeof(t_String));
			ReplicateConVar(t_ConVar, "", t_String); // Replicate it now for idoit protection.
			HookConVarChange(t_ConVar, ReplicateConVar);
		}
		else if (comm && (flags & FCVAR_CHEAT) && !isRPG)
			RegConsoleCmd(name, BlockCheat);
		
	} while (FindNextConCommand(cvar, name, sizeof(name), comm, flags));

	// Exploit
	RegConsoleCmd("changelevel", BlockExploit);
	RegConsoleCmd("ent_fire", BlockExploit); // Exploit that cheaters can do.

	// Cheat
	RegConsoleCmd("snd_restart", BlockCheat);

	// Crash
	RegConsoleCmd("ai_test_los", BlockCrash);
	RegConsoleCmd("sv_benchmark_force_start", BlockCrash);
	RegConsoleCmd("sv_findsoundname", BlockCrash);
	RegConsoleCmd("sv_soundemitter_filecheck", BlockCrash);
	RegConsoleCmd("sv_soundemitter_flush", BlockCrash);
	RegConsoleCmd("sv_soundscape_printdebuginfo", BlockCrash);

	// Spam Check
	RegConsoleCmd("timeleft", SpamCheck);
	RegConsoleCmd("nextmap", SpamCheck);
	for(new i=0;i<MAX_HACKCVAR;i++)
	{
		t_ConVar = FindConVar(g_HackCVars[i]);
		if ( t_ConVar != INVALID_HANDLE && (GetConVarFlags(t_ConVar) & FCVAR_REPLICATED) )
			g_HackCVarHandles[i] = t_ConVar;
	}

	// Stuff for if we're late.
	for(new i=1;i<MaxClients;i++)
	{
		if ( IsClientInGame(i) &&  !IsFakeClient(i) )
		{
			CVarI[i] = 0;
			PTimer[i] = CreateTimer(GetRandomFloat(10.5, 123.8), PeriodicTimer, i, TIMER_FLAG_NO_MAPCHANGE);
		}
	}

	CreateTimer(1.0, Clear, _, TIMER_REPEAT);
}

// SourceMod likes to crash the server if we don't kill all the timers before unload. - Kigen
public OnPluginEnd()
{
	for(new i=1;i<MaxClients;i++)
		KillTimers(i);
}

// This apparently gets called whenever the plugin is loaded.
public OnMapStart()
{
	CreateNewCheckOrder();
	ClearArray(CacheAuthArray);
	ClearArray(CacheReasonArray);
}

public OnMapEnd()
{
	for(new i=1;i<MaxClients;i++)
	{
		CVarI[i] = 0;
		PTimer[i] = INVALID_HANDLE;
	}
}

public bool:OnClientConnect(client, String:rejectmsg[], maxlen)
{
	if ( IsFakeClient(client) )
	{
		ConnState[client] = CS_BOT;
		return true;
	}

	decl String:name[64], len;
	GetClientName(client, name, 64);
	len = strlen(name);
	if ( len <= 0 )
	{
		Format(rejectmsg, maxlen, "Don't even think about it.");
		return false;
	}

	if ( GetConVarBool(CVar_BlockNameCopy) )
	{
		decl String:PlayerName[64], diff;
		if ( len <= 3 )
		{
			Format(rejectmsg, maxlen, "You need a longer name to play in this server.");
			return false;
		}
		for(new i=1;i<MaxClients;i++)
		{
			if (IsClientConnected(i) && client != i)
			{
				GetClientName(i, PlayerName, 64);
				diff = CmpString(PlayerName, name);
				if ( strlen(PlayerName) > 3 && diff < 2 )
				{
					decl String:authString[64], String:reason[255];
					if ( !GetClientAuthString(i, authString, 64) )
						strcopy(authString, 64, "STEAM_ID_PENDING");
					Format(reason, 255, "%s was blocked from entering the server for having a similar name to %s (%s). KAC ID:1 Diff: %d", name, PlayerName, authString, diff);
					KACLog(reason);
					PrintToAdmins(reason);
					Format(rejectmsg, maxlen, "You were blocked from entering the server for having a name similar to %s", PlayerName);
					// CreateTimer(0.1, KickThem, client);
					return false;
				}
			}
		}
	}
	if ( GetConVarBool(CVar_BlockMultiByte) )
	{
		for(new i=0;i<len;i++)
		{
			if ( IsCharMB(name[i]) )
			{
				decl String:reason[255];
				Format(reason, 255, "%s was blocked from entering the server for having a multibyte character (UTF) in their name.", name);
				KACLog(reason);
				PrintToAdmins(reason);
				Format(rejectmsg, maxlen, "You were blocked from entering this server for having a multibyte character (UTF) in your name");
				return false;
			}
		}
	}

	ConnState[client] = CS_CONNING;
	return true;
}

public Action:KickThem(Handle:timer, any:client)
{
	if ( IsClientConnected(client) && !IsClientInKickQueue(client) && !IsFakeClient(client) )
		KickClient(client, "%s", g_Reason[client]);
	return Plugin_Stop;
}

public OnClientAuthorized(client, const String:auth[])
{
	if ( IsFakeClient(client) )
		return;
	

	ConnState[client] = CS_VALIDATED;

	decl  Handle:t_PTimer;
	t_PTimer = PTimer[client]; 

	CVarI[client] = 0;
	PTimer[client] = CreateTimer(GetRandomFloat(5.5, 17.8), PeriodicTimer, client, TIMER_FLAG_NO_MAPCHANGE);

	if ( t_PTimer != INVALID_HANDLE ) // Kill an already existing PTimer to prevent over-checking.
		CloseHandle(t_PTimer);
}

public OnClientDisconnect_Post(client)
{
	ConnState[client] = CS_NOTCONN;
	strcopy(g_Reason[client], 255, "");
	strcopy(g_Reason2[client], 255, "");
	KillTimers(client);
}

public Action:BlockCheat(client, args)
{
	if ( !client )
		return Plugin_Continue; // Server operation.
	new String:log[256], String:cmd[255], String:name[64], String:authString[64];
	GetCmdArgString(cmd, 255);
	GetClientName(client, name, 64);
	GetClientAuthString(client, authString, 64);
	FormatEx(log, 256, "Player %s (%s) tried to execute cheat command: %s", name, authString, cmd);
	KACLog(log);
	return Plugin_Stop;
}

public Action:BlockCrash(client, args)
{
	if ( !client )
		return Plugin_Stop; // Server operation.  Don't allow server to crash itself.
	if ( ConnState[client] == CS_BANNING )
		return Plugin_Stop;
	new String:log[256], String:cmd[255], String:name[64], String:authString[64];
	GetCmdArg(0, cmd, 255);
	GetClientName(client, name, 64);
	GetClientAuthString(client, authString, 64);
	FormatEx(log, 256, "%s (%s) attempted to crash this server with %s.", name, authString, cmd);
	KACLog(log);
	KACBan(client, 0, "Attempting to crash server", "You fail, goodbye.");
	return Plugin_Stop;
}

public Action:BlockExploit(client, args)
{
	if ( !client )
		return Plugin_Continue; // Server operation.
	if ( ConnState[client] == CS_BANNING )
		return Plugin_Stop;
	new String:log[256], String:cmd[255], String:cmd2[255], String:name[64], String:authString[64];
	GetCmdArg(0, cmd, 255);
	GetCmdArgString(cmd2, 255);
	GetClientName(client, name, 64);
	GetClientAuthString(client, authString, 64);
	FormatEx(log, 256, "%s (%s) attempted to exploit this server with: %s %s.", name, authString, cmd, cmd2);
	KACLog(log);
	KACBan(client, 0, "Attempting to exploit server", "You fail, goodbye.");
	return Plugin_Stop;
}

public Action:SpamCheck(client, args)
{
	if ( !client )
		return Plugin_Continue;
	if ( ConnState[client] == CS_BANNING )
		return Plugin_Stop;
	count[client]++;
	if ( count[client] > 10 )
	{
		new String:log[256], String:cmd[255], String:cmd2[255], String:name[64], String:authString[64];
		GetCmdArg(0, cmd, 255);
		GetCmdArgString(cmd2, 255);
		GetClientName(client, name, 64);
		GetClientAuthString(client, authString, 64);
		FormatEx(log, 256, "%s (%s) attempted to spam crash this server with: %s %s.", name, authString, cmd, cmd2);
		KACLog(log);
		KACBan(client, 0, "Attempting to spam crash server", "You fail, goodbye.");
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action:Clear(Handle:timer, any:arg)
{
	for(new i=1;i<MaxClients;i++)
		count[i] = 0;
	return Plugin_Continue;
}

public Action:PeriodicTimer(Handle:timer, any:client)
{
	if ( PTimer[client] == INVALID_HANDLE )
		return Plugin_Stop;
	PTimer[client] = INVALID_HANDLE;
	if ( !IsClientConnected(client) || IsClientInKickQueue(client) )
		return Plugin_Stop;

	decl String:name[64];
	if ( GetClientName(client, name, 64) && strlen(name) < 1 )
	{
		decl String:authString[64], String:reason[255];
		GetClientAuthString(client, authString, 64);
		FormatEx(reason, 255, "%s (%s) was banned for attempting to name hack. KAC ID:2", name, authString);
		KACLog(reason);
		PrintToAdmins(reason);
		KACBan(client, 0, "Banned for name exploit. KAC ID:2", "You have been banned for name exploiting.");
		return Plugin_Stop;
	}
	if ( CVarI[client] > MAX_HACKCVAR*2 )
		CVarI[client] = 0;
	if ( Enabled )
		QueryClientConVar(client, g_HackCVars[g_HackCheckOrder[CVarI[client]]], ClientCVarCallback, client);
	else
		PTimer[client] = CreateTimer(GetRandomFloat(11.5, 25.8), PeriodicTimer, client, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Stop;
}

public Action:TimedBan(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (!client || !IsClientConnected(client) || IsClientInKickQueue(client))
		return Plugin_Stop;

	decl String:name[64];
	GetClientName(client, name, 64);
	PrintToChatAll("%s was banned by KAC for a cheating infraction.", name);
	PrintToAdmins(g_Reason2[client]);
	KACBan(client, 0, g_Reason[client], "You have been banned for a cheating infraction.");
	CreateTimer(GetRandomFloat(4.5, 30.4), TimedBan2, userid, TIMER_FLAG_NO_MAPCHANGE); // Make sure they're gone.
	return Plugin_Stop;
}

public Action:TimedBan2(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (!client || !IsClientConnected(client) || IsClientInKickQueue(client))
		return Plugin_Stop;

	BanClient(client, 0, BANFLAG_AUTO, g_Reason2[client], "You have been banned for a cheating infraction.");
	CreateTimer(GetRandomFloat(4.5, 30.4), TimedBan2, userid, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Stop;
}

public CheatsChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if ( Enabled && StringToInt(newValue) != 0 )
		SetConVarInt(convar, 0, true, false); // Force sv_cheats off at all times.
}

public EnableChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if ( GetConVarBool(convar) )
	{
		if ( Enabled )
			return;
		Enabled = true;
		PrintToAdmins("KAC has been enabled.");
		SetConVarInt(CVar_Cheats, 0, true);
	}
	else
	{
		if ( !Enabled )
			return;
		Enabled = false;
		PrintToAdmins("KAC has been disabled.");
	}
}

// Base Fun Votes (sm_votegravity) and other things like it don't properly replicated values like they should. -.-
public ReplicateConVar(Handle:convar, String:oldValue[], String:newValue[])
{
	for(new i=1;i<MaxClients;i++)
		if ( IsClientConnected(i) && !IsFakeClient(i) )
			SendConVarValue(i, convar, newValue);
}

// param 2 (client) is always passing the client that returned the cookie, does not pass anything else
public ClientCVarCallback(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[])
{
	if ( !client || !IsClientConnected(client) || IsFakeClient(client) )
		return;
	decl String:name[64], Handle:cvar, cvarid, bool:continuechecks, String:authString[64], ComparisonID, CompTest, Float:clientValue, Float:serverValue;
	ComparisonID = 0;
	continuechecks = true;
	cvarid = g_HackCheckOrder[CVarI[client]];
	GetClientName(client, name, 64);
	if ( strcmp(g_HackCVars[cvarid], cvarName) != 0 ) // Lets go ahead and make use of this call.
	{
		decl String:buff[256];
		GetClientAuthString(client, authString, 64);
		FormatEx(buff, 256, "Cvar out of sync: %s (%s) on %s (%s) is %s", g_HackCVars[cvarid], cvarName, name, authString, cvarValue);
		KACLog(buff);
		for(new i=0;i<MAX_HACKCVAR;i++)
		{
			if ( StrEqual(g_HackCVars[i], cvarName) )
			{
				cvarid = i;
				continuechecks = false;
				break;
			}
		}
		if ( continuechecks ) // CVar not found, weird.
			return;
	}
	cvar = g_HackCVarHandles[cvarid];
	if ( Enabled )
	{
		CompTest = g_HackCVarsComp[cvarid];
		if ( cvar != INVALID_HANDLE )
			serverValue = GetConVarFloat(cvar);
		else
			serverValue = g_HackCVarValues[cvarid];
		clientValue = StringToFloat(cvarValue);
		if ( result == ConVarQuery_Okay )
		{
			// if ( ( CompTest == COMP_EQUAL && clientValue != serverValue )
			//   || ( CompTest == COMP_GREATER &&  clientValue < serverValue )
			//   || ( CompTest == COMP_LESS && clientValue > serverValue ) )
			// 	ComparisonID = 5;
			switch (CompTest) // This is actually more efficent. - Kigen
			{
				case COMP_EQUAL:
				{
					if ( clientValue != serverValue )
						ComparisonID = 5;
					// break;
				}
				case COMP_LESS:
				{
					if ( clientValue > serverValue )
						ComparisonID = 5;
					// break;
				}
				case COMP_GREATER:
				{
					if ( clientValue < serverValue )
						ComparisonID = 5;
					// break;
				}
			}
		}
		else
			ComparisonID = 4;
	}
	if ( ComparisonID )
	{
		if ( ComparisonID == 5 && cvar == INVALID_HANDLE )
			ComparisonID++;
		decl String:reason[255], String:buff[256];
		GetClientAuthString(client, authString, 64);
		if ( ComparisonID == 4 )
			FormatEx(buff, sizeof(buff), "Bad CVar response! Client %s (%s) failed to reply properly to convar query!  %s (%s) set to %s", name, authString, cvarName, g_HackCVars[cvarid], cvarValue);
		else
			FormatEx(buff, sizeof(buff), "Bad CVar response! %s (%s) has %s (%s) set to %s", name, authString, cvarName, g_HackCVars[cvarid], cvarValue);
		KACLog(buff);
		if ( g_HackCVarsAction[cvarid] == ACTION_BAN || ComparisonID == 4 )
		{
			FormatEx(reason, 255, "%s (%s) was banned for cheating. KAC ID:%d.%d", name, authString, ComparisonID, cvarid);
			KACLog(reason);
			FormatEx(g_Reason[client], 512, "Cheating. KAC ID:%d.%d", ComparisonID, cvarid);
			CreateTimer(GetRandomFloat(2.5, 11.4), TimedBan, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		}
		else if ( g_HackCVarsAction[cvarid] == ACTION_KICK )
		{
			decl String:value[64];
			if ( cvar != INVALID_HANDLE )
				GetConVarString(cvar, value, 64);
			else
				FloatToString(g_HackCVarValues[cvarid], value, 64);
			FormatEx(g_Reason[client], 512, "The cvar %s needs to be %s %s.", g_HackCVars[cvarid], g_CompareString[CompTest], value);
			FormatEx(reason, 255, "%s (%s) was kicked for having a bad value on %s (had %s).", name, authString, g_HackCVars[cvarid], cvarValue);
			KACLog(reason);
			CreateTimer(0.1, KickThem, client);
		}
		strcopy(g_Reason2[client], 255, reason);
	}
	if ( continuechecks || PTimer[client] == INVALID_HANDLE )
	{
		if ( continuechecks )
			CVarI[client]++;
		if ( CVarI[client] > MAX_HACKCVAR*2 )
		{
			CVarI[client] = 0;
			PTimer[client] = CreateTimer(GetRandomFloat(43.5, 65.8), PeriodicTimer, client, TIMER_FLAG_NO_MAPCHANGE);
			return;
		}
		PTimer[client] = CreateTimer(GetRandomFloat(2.5, 7.8), PeriodicTimer, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public EventNameChange(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if ( !client || !IsClientConnected(client) || IsClientInKickQueue(client) || IsFakeClient(client) )
		return;

	decl String:oldName[64], String:newName[64], String:PlayerName[64], String:authString[64];
	GetEventString(event, "oldname", oldName, sizeof(oldName));
	GetEventString(event, "newname", newName, sizeof(newName));
	if ( !GetClientAuthString(client, authString, 64) )
		strcopy(authString, 64, "STEAM_ID_PENDING");
	if ( strlen(newName) < 1 )
	{
		decl String:reason[255]; // String:authString[64], 
		// GetClientAuthString(client, authString, 64);
		FormatEx(reason, sizeof(reason), "%s (%s) was banned for attempting to name hack. KAC ID:2", oldName, authString);
		KACLog(reason);
		KACBan(client, 0, "Banned for name exploit. KAC ID:2", "You have been banned for name exploiting.");
		PrintToAdmins(reason);
		return;
	}

	if ( GetConVarBool(CVar_BlockMultiByte) )
	{
		decl len;
		len = strlen(newName);
		for(new i=0;i<len;i++)
		{
			if ( IsCharMB(newName[i]) )
			{
				decl String:reason[255];
				FormatEx(reason, 255, "%s was kicked from the server for having a multibyte character (UTF) in their name.", name);
				KACLog(reason);
				PrintToAdmins(reason);
				strcopy(g_Reason[client], 512, "You were kicked from this server for having a multibyte character (UTF) in your name.");
				CreateTimer(0.1, KickThem, client);
				return;
			}
		}
	}

	if ( !GetConVarBool(CVar_BlockNameCopy) )
		return;

	// Why the kick/ban?  Why not block?  Answer: Cheats mess up the way things are handled, thus not always promising that a return Plugin_Handled will do the job.
	if ( strlen(newName) <= 3 )
	{
		strcopy(g_Reason[client], 512, "Your name is too short, please come back with a longer name");
		CreateTimer(0.1, KickThem, client);
	}
	else
	{
		for(new i=1;i<MaxClients;i++)
		{
			if (IsClientConnected(i) && client != i)
			{
				decl diff;
				GetClientName(i, PlayerName, 64);
				diff = CmpString(PlayerName, newName);
				if ( strlen(PlayerName) > 3 && diff < 2 )
				{
					decl String:authString2[64], String:reason[255];
					if ( !GetClientAuthString(i, authString2, 64) )
						strcopy(authString2, 64, "STEAM_ID_PENDING");
					FormatEx(reason, 255, "%s (%s) was banned for attempting to name copy on %s (%s). KAC ID:1 Diff: %d NewName: %s", oldName, authString, PlayerName, authString2, diff, newName);
					KACLog(reason);
					PrintToAdmins(reason);
					KACBan(client, 5, "Banned for name copying. KAC ID:1", "You have been banned for name copying.");
					return;
				}
			}
		}
	}
}


/* Private KAC functions */

/*
 * CreateNewCheckOrder()
 * Description: Creates a new convar checking order.  Used to prevent guessing when a check on a specific convar is going to happen.
 */
CreateNewCheckOrder()
{
	new temp, bool:done = false, test;
	for(new i=0;i<MAX_HACKCVAR+1;i++)
	{
		done = false;
		while (!done)
		{
			if ( i < 4 ) // 0 1 2 3
				temp = GetRandomInt(13, 16); // Check sv_cheats and sv_consistency first.  They're common to be on the blatant cheaters.
			else
				temp = GetRandomInt(0, MAX_HACKCVAR);
			done = true;
			for(new t=0;t<i;t++)
				if ( g_HackCheckOrder[t] == temp )
					done = false;
		}
		g_HackCheckOrder[i] = temp;
	}
	test = MAX_HACKCVAR*2+1;
	for(new i=MAX_HACKCVAR+1;i<test;i++)
	{
		done = false;
		while (!done)
		{
			temp = GetRandomInt(0, MAX_HACKCVAR);
			done = true;
			for(new t=MAX_HACKCVAR+1;t<i;t++)
				if ( g_HackCheckOrder[t] == temp )
					done = false;
		}
		g_HackCheckOrder[i] = temp;
	}
}

/*
 * KACLog(String:log[])
 * log: String to log.
 * Description: Logs actions to KAC log and SourceMod logs.
 */
KACLog(String:log[])
{
	LogMessage("%s", log);
	decl String:path[256];
	BuildPath(Path_SM, path, 256, "logs/KAC.log");
	LogToFileEx(path, "%s", log); // Use Ex since we should be the only ones logging.
}

KACBan(client, time, String:IReason[], String:EReason[])
{
	if ( ConnState[client] == CS_BANNING || !IsClientConnected(client) || IsFakeClient(client) || IsClientInKickQueue(client) )
		return;
	ConnState[client] = CS_BANNING;
	decl String:authString[64], Handle:t_ConVar, bool:test;
	test = GetClientAuthString(client, authString, 64);
	if ( !test || StrEqual(authString, "STEAM_ID_LAN") )
	{
		BanClient(client, time, BANFLAG_IP, IReason, EReason);
		return;
	}
	else
	{
		t_ConVar = FindConVar("sb_version");
		if ( t_ConVar != INVALID_HANDLE )
		{
			ServerCommand("sm_ban #%d %d \"%s\"", GetClientUserId(client), time, IReason);
			CloseHandle(t_ConVar);
			return;
		}
		t_ConVar = FindConVar("mysql_bans_version");
		if ( t_ConVar != INVALID_HANDLE )
		{
			ServerCommand("mysql_ban #%d %d %s", GetClientUserId(client), time, IReason);
			CloseHandle(t_ConVar);
			return;
		}
		BanClient(client, time, BANFLAG_AUTO, IReason, EReason);
	}
	return;
	
}

/*
 * PrintToAdmins(String:text[])
 * text: String to display to all admins.
 * Description: Prints text to all admins on the server.
 */
PrintToAdmins(String:text[])
{
	for(new i=1;i<MaxClients;i++)
		if ( IsClientInGame(i) && GetUserAdmin(i) != INVALID_ADMIN_ID )
			PrintToChat(i, "KAC: %s", text);
}

/*
 * CmpString(String:str1[], String:str2[])
 * str1: First String to Compare.
 * str2: Second String to Compare.
 * Returns difference.
 * Counts the number of differences between two strings.
 */
CmpString(String:str1[], String:str2[])
{
	decl len, diff;
	diff = 0;
	len = strlen(str1);
	if ( len > strlen(str2) )
		len = strlen(str2);

	for(new i=0;i<len;i++)
	{
		if ( str1[i] != str2[i] )
			diff++;
	}
	return diff;
}

/*
 * KillTimers(client)
 * client: Client Index number.
 * Description: Kills all active KAC timers on client.
 */
KillTimers(client)
{
	decl Handle:t_PTimer;
	t_PTimer = PTimer[client];
	PTimer[client] = INVALID_HANDLE;

	if ( t_PTimer != INVALID_HANDLE )
		CloseHandle(t_PTimer);
}
