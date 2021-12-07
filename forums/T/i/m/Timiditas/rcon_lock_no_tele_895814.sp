#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define VERSION "0.2.8"

public Plugin:myinfo =
{
	name = "RCON Lock",
	author = "devicenull",
	description = "Locks RCON and patches various exploitable commands",
	version = VERSION,
	url = "http://www.sourcemod.net/"
};

// Entities that are not allowed to be created with ent_create or give
new String:forbidden_ents[][] = { "point_servercommand", "point_clientcommand", "logic_timer" };

/* These are strings that are not allowed to be present in ent_fire commands
*	quit, restart - obvious
*	sm, admin, ma_ - prevent access to sourcemod commands, including unloading plugins
*	rcon - prevent changing rcon password
*/
new String:forbidden_cmds[][] = { "quit", "restart", "sm", "admin", "ma_", "rcon", "sv_", "mp_", "meta" };
new String:cheat_flag[][] = { "dumpcountedstrings", "dbghist_dump", "dumpeventqueue", "dump_globals", "physics_select"
	, "physics_debug_entity", "dump_entity_sizes", "dumpentityfactories", "dump_terrain", "mp_dump_timers", "dumpcountedstrings"
	, "mem_dump", "soundscape_flush" };
new String:block_mani[][] = { "timeleft", "nextmap", "ma_timeleft", "ma_nextmap", "listmaps" };
	
new String:forbidden_cvars[][] = { "sourcemod_version", "metamod_version", "mani_admin_plugin_version", "eventscripts_ver", "est_version", "bat_version", "beetlesmod_version" };

new cvar_pos[MAXPLAYERS];

new Handle:rcon_pw;
new bool:rcon_set=false;
new String:correct_rcon_pw[256];

new Handle:mintries;
new Handle:maxtries;

public OnPluginStart()
{
	CreateConVar("sm_rconlock", VERSION, "Plugin version", FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	RegConsoleCmd("ent_create",Cmd_EntCreate);
	RegConsoleCmd("ent_fire",Cmd_EntFire);
	
	// Grab the rcon password to prevent changes
	rcon_pw = FindConVar("rcon_password");
	HookConVarChange(rcon_pw,rcon_changed);

	// Flag any of the exploitable commands as cheats
	new Handle:curcmd;
	for (new i=0;i<sizeof(cheat_flag);i++)
	{
		curcmd = FindConVar(cheat_flag[i]);
		if (curcmd != INVALID_HANDLE)
		{
			SetConVarFlags(curcmd,GetConVarFlags(curcmd)|FCVAR_CHEAT);
		}
	}
	
	// Figure out if Mani is loaded
	if (FindConVar("mani_admin_plugin_version") != INVALID_HANDLE)
	{
		for (new i=0;i<sizeof(block_mani);i++)
		{
			curcmd = FindConVar(block_mani[i]);
			if (curcmd != INVALID_HANDLE)
			{
				SetConVarFlags(curcmd,GetConVarFlags(curcmd)|FCVAR_CHEAT);
			}
		}
	}
	
	// Remove convar bounds so the actual rcon crash can be prevented
	mintries = FindConVar("sv_rcon_minfailures");
	maxtries = FindConVar("sv_rcon_maxfailures");
	SetConVarBounds(mintries,ConVarBound_Upper,false);
	SetConVarBounds(maxtries,ConVarBound_Upper,false);
	
	decl String:curCmd[128], bool:isCmd;
	new Handle:cmdIt = FindFirstConCommand(curCmd,sizeof(curCmd),isCmd);
	do
	{
		if (!isCmd) continue;
		RegConsoleCmd(curCmd,HalfConnected);				
	} while (FindNextConCommand(cmdIt,curCmd,sizeof(curCmd),isCmd));
}

/*
************************** TELEPORT EXPLOIT ********************************
*/

/*
*****DISABLED******
public OnGameFrame()
{
	decl Float:origin[3];
	for (new i=1;i<=MaxClients;i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && IsPlayerAlive(i))
		{
			GetClientAbsOrigin(i,origin);
			if (origin[0] == 0.0 && origin[1] == 0.0)
			{
				ForcePlayerSuicide(i);
				PrintToChat(i,"Likely teleport hack detected, you have been slayed");
			}
		}	
	}
}
***********DISABLED***********
*/

/*
************************** CLIENT PLUGINS ********************************
*/
public OnClientPutInServer(client)
{
	cvar_pos[client] = 0;
	CreateTimer(5.0, CheckPlayer, client, TIMER_REPEAT);
	OnClientSettingsChanged(client);
}

public Action:CheckPlayer(Handle:timer,any:value)
{
	if (!IsClientInGame(value)) return Plugin_Stop;
	if (value >= sizeof(cvar_pos)) return Plugin_Stop;
	if (cvar_pos[value] >= sizeof(forbidden_cvars)) return Plugin_Stop;
	
	QueryClientConVar(value, forbidden_cvars[cvar_pos[value]], ConVarDone);
	cvar_pos[value]++;
	if (cvar_pos[value] >= sizeof(forbidden_cvars))
	{
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public ConVarDone(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[], any:value)
{
	if (result != ConVarQuery_Okay && result != ConVarQuery_Protected) return;
	LogMessage("Removing client '%N' as %s=%s",client, cvarName, cvarValue);
	KickClient(client,"Please remove any plugins you are running");
}

/*
************************** RCON LOCK ********************************
*/
public OnConfigsExecuted()
{
	rcon_set = true;
	GetConVarString(rcon_pw,correct_rcon_pw,sizeof(correct_rcon_pw));
	if (GetConVarInt(mintries) == 5)
	{
		SetConVarInt(mintries,10000);
	}
	if (GetConVarInt(maxtries) == 10)
	{
		SetConVarInt(maxtries,10000);
	}
}

public rcon_changed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (rcon_set && !StrEqual(newValue,correct_rcon_pw))
	{
		LogMessage("Rcon password changed to %s, reverting",newValue);
		SetConVarString(rcon_pw,correct_rcon_pw);
	}
}

/*
************************** ENT_CREATE/ ENT_FIRE ********************************
*/
public Action:Cmd_EntCreate(client, args)
{
	new String:entname[128];
	GetCmdArg(1,entname,sizeof(entname));

	for (new i=0;i<sizeof(forbidden_ents);i++)
	{
		if (StrEqual(entname,forbidden_ents[i],false))
		{
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public Action:Cmd_EntFire(client, args)
{
	new String:argstring[1024];
	GetCmdArgString(argstring,1024);

	for (new i=0;i<sizeof(forbidden_cmds);i++)
	{
		if (StrContains(argstring,forbidden_cmds[i],false) != -1)
		{
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}
/*
********************************** UNNAMMED ***************************************
*/

public OnClientSettingsChanged(client)
{
	new String:newname[128];
	GetClientName(client,newname,sizeof(newname));
	if (strlen(newname) == 0)
	{
		KickClient(client,"Please set a name, then rejoin");
	}
}

/*
********************************** EARLY CMD ***************************************
*/

public Action:HalfConnected(client, args)
{
	if (client == 0) return Plugin_Continue;
	if (!IsClientInGame(client)) return Plugin_Stop;
	return Plugin_Continue;
}