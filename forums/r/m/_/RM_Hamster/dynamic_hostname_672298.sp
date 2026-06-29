/*
   Versions:

	2.1.1 - 12/31/2008
		* Fixed small bug with dh_update when using RCON/console (really fixed now!)

	2.1 - 8/27/2008
		* Added CVar dh_empty to control behavior of the plugin when server is empty
		* Fixed small bug with dh_update when using RCON/console
		* Semi-support for bug with Insurgency and OnConfigsExecuted (will have full support next major version)

	2.0 - 8/19/2008
		* Renamed to "Dynamic Hostname"
		* Rewrote most of the existing code
		* Renamed original CVar to dh_frequency
		* Added CVars dh_default and dh_update
		* Added support for %t and %n
		* Added changing of frequency "on the fly"
		* Optimized to only update when needed

	*** ORIGINAL PLUGIN ***

	1.4
		* Added code to reset hostname when server empties
	1.3
		* Fixed frequency cvar not doing anything if set
	1.2
		* Fixed errors in the console
	1.1
		* Added missing map end timer kill
	1.0
		* First Public Release!

   CVars:

	dh_default <string> - Default hostname for when no clients are active on the server. Default is "" (empty string).

	dh_empty <bool> - Specifies whether the hostname will include timeleft when the server is empty. Default is 1 (true).

	dh_frequency <float> - How often, in seconds, to update the hostname. Default is one second (1.0).
	   * Note: timeleft (%t) does not work if the server is empty.

	dh_update <opt:string> - Manually update the hostname with an option to specify a new hostname.

   Thanks To:

	Hell Phoenix - original SourceMod plugin
	Chanz - for the concept and the SourceForts code
	Caught off Guard - for helping with the Insurgency/OnConfigsExecuted() bug
	MaKTaiL - for the ideas to make this plugin better and for testing

	Cheap Suit - original AMXX plugin
	Ferret - for pointing out some things to fix =D
*/

#include <sourcemod>
#include <sdktools>

#define DH_VERSION "2.0"

#pragma semicolon 1

new Handle:DHhandle = INVALID_HANDLE;
new Handle:DHfreq = INVALID_HANDLE;
new Handle:DHdef = INVALID_HANDLE;
new Handle:DHhostname = INVALID_HANDLE;
new Handle:DHnextmap = INVALID_HANDLE;
new Handle:DHempty = INVALID_HANDLE;

new String:defHN[64];
new String:oldHN[64];
new String:newHN[64];

new timeleft;
new String:f_timeleft[8];
new String:nextmap[32];

new activeClients;

new i;

new subTimeleft[2];

public Plugin:myinfo = 
{
	name = "Dynamic Hostname",
	author = "RM_Hamster",
	description = "Allows for usage of variables within the hostname, such as %t for timeleft and %n for nextmap.",
	version = DH_VERSION,
	url = "http://version2.clanservers.com"
}

public OnPluginStart()
{
	CreateConVar("dynamic_hostname_version", DH_VERSION, "Dynamic Hostname Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	DHfreq = CreateConVar("dh_frequency", "1.0", "How often, in seconds, to update the hostname.", FCVAR_PLUGIN);
	DHdef = CreateConVar("dh_default", "", "Default hostname for when no clients are active on the server.", FCVAR_PLUGIN);
	DHempty = CreateConVar("dh_empty", "1", "Specifies whether the hostname will include timeleft when the server is empty.", FCVAR_PLUGIN);
	RegAdminCmd("dh_update", Cmd_Update, ADMFLAG_CONVARS, "Manually update the hostname with an option to specify a new hostname.");

	DHhostname = FindConVar("hostname");
	if(DHhostname == INVALID_HANDLE)
		SetFailState("[DH] Unable to retrieve hostname.");

	HookConVarChange(DHfreq, CVarChanged);
	HookConVarChange(DHdef, CVarChanged);

	HookEvent("player_team", Event_ChangeTeam);

	GetConVarString(DHhostname, oldHN, sizeof(oldHN));
	GetConVarString(DHdef, defHN, sizeof(defHN));

	Update_Hostname();
}

public OnConfigsExecuted()
{
	DHnextmap = FindConVar("sm_nextmap");
	HookConVarChange(DHnextmap, CVarChanged);
	GetConVarString(DHnextmap, nextmap, sizeof(nextmap));

	Update_Hostname();
}

public CVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar == DHnextmap)
	{
		GetConVarString(DHnextmap, nextmap, sizeof(nextmap));
		Update_Hostname();
	}

	if(convar == DHfreq)
	{
		CloseDHhandle();
		Update_Hostname();
	}

	if(convar == DHdef)
	{
		GetConVarString(DHdef, defHN, sizeof(defHN));
		Update_Hostname();
	}
}

public Event_ChangeTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(PlayerCount() <= 1)
		CreateTimer(0.1, Delay_ChangeTeam);
}

public Action:Delay_ChangeTeam(Handle:timer)
{
	Update_Hostname();
}

public OnClientDisconnect_Post()
{
	if(PlayerCount() == 0)
		Update_Hostname();
}

public Action:Cmd_Update(client, args)
{
	if(args > 0)
		GetCmdArgString(oldHN, sizeof(oldHN));

	Update_Hostname();

	if(client != 0)
		PrintToChat(client, "[DH] Server hostname updated.");
	else
		PrintToServer("[DH] Server hostname updated.");

	return Plugin_Handled;
}

public Action:Update_Hostname()
{
	GetNewHN();

	if((DHhandle != INVALID_HANDLE) && (PlayerCount() == 0) && !GetConVarBool(DHempty))
		CloseDHhandle();

	if(StrContains(newHN, "%t") > -1)
	{
		if((DHhandle == INVALID_HANDLE) && (PlayerCount() > 0))
		{
			DHhandle = CreateTimer(GetConVarFloat(DHfreq), Update_Timeleft, INVALID_HANDLE, TIMER_REPEAT);
			return Plugin_Stop;
		}
		else
			ReplaceTimeleft();
	}

	if(StrContains(newHN, "%n") > -1)
		ReplaceString(newHN, sizeof(newHN), "%n", nextmap);

	SetConVarString(DHhostname, newHN);

	return Plugin_Continue;
}

public Action:Update_Timeleft(Handle:timer)
{
	GetNewHN();
	GetMapTimeLeft(timeleft);

	if(StrContains(newHN, "%n") > -1)
		ReplaceString(newHN, sizeof(newHN), "%n", nextmap);
	ReplaceTimeleft();

	SetConVarString(DHhostname, newHN);
}

public GetNewHN()
{
	if(!StrEqual(defHN, "") && (PlayerCount() == 0))
		strcopy(newHN, sizeof(newHN), defHN);
	else
		strcopy(newHN, sizeof(newHN), oldHN);
}

public ReplaceTimeleft()
{
	if(DHhandle != INVALID_HANDLE)
	{
		Format(f_timeleft, sizeof(f_timeleft), "%d:%02d", (timeleft / 60), (timeleft % 60));
		ReplaceString(newHN, sizeof(newHN), "%t", f_timeleft);
	}
	else
	{
		i = StrContains(newHN, "%t") - 1;

		subTimeleft[0] = newHN[i];
		subTimeleft[1] = newHN[i + 3];

		if(subTimeleft[0] == ' ')
			ReplaceString(newHN, sizeof(newHN), " %t", "");

		else if(subTimeleft[1] == ' ')
			ReplaceString(newHN, sizeof(newHN), "%t ", "");

		else
			ReplaceString(newHN, sizeof(newHN), "%t", "");
	}
}

public PlayerCount()
{
	activeClients = GetTeamClientCount(2) + GetTeamClientCount(3);

	return activeClients;
}

public CloseDHhandle()
{
	if(DHhandle != INVALID_HANDLE)
		CloseHandle(DHhandle);
	DHhandle = INVALID_HANDLE;
}

public OnMapEnd()
{
	CloseDHhandle();
	SetConVarString(DHhostname, oldHN);
}

public OnPluginEnd()
{
	SetConVarString(DHhostname, oldHN);
}
