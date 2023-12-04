#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define VERSION "0.5"

public Plugin:myinfo =
{
	name = "RCON Lock",
	author = "devicenull",
	description = "Locks RCON and patches various exploitable commands",
	version = VERSION,
	url = "http://www.sourcemod.net/"
};

/* Entities that are not allowed to be created with ent_create or give */
new String:forbidden_ents[][] = { "point_servercommand", "point_clientcommand", "logic_timer", "logic_relay"
	,"logic_auto", "logic_autosave", "logic_branch", "logic_case", "logic_collision_pair", "logic_compareto" 
	,"logic_lineto", "logic_measure_movement", "logic_multicompare", "logic_navigation" };

/*Strings that are not allowed to be present in ent_fire commands */
new String:forbidden_cmds[][] = { "quit", "quti", "restart", "sm", "admin", "ma_", "rcon", "sv_", "mp_", "meta", "alias" };

/* Commands that will have the FCVAR_CHEATS flag added, to prevent execution */
new String:cheat_flag[][] = { "dumpcountedstrings", "dbghist_dump", "dumpeventqueue", "dump_globals", "physics_select"
	, "physics_debug_entity", "dump_entity_sizes", "dumpentityfactories", "dump_terrain", "mp_dump_timers"
	, "mem_dump", "soundscape_flush", "groundlist", "soundlist", "report_touchlinks", "report_entities", "physics_report_active"
	, "listmodels" };
	
/* Mani commands that will be disabled */
new String:block_mani[][] = { "timeleft", "nextmap", "ma_timeleft", "ma_nextmap", "listmaps", "ff" };

/* Cvars that clients are not permitted to have */
new String:forbidden_cvars[][] = { "sourcemod_version", "metamod_version", "mani_admin_plugin_version", "eventscripts_ver", "est_version", "bat_version", "beetlesmod_version" };

/* Plugins that will be removed if they exist */
new String:bad_plugins[][] = { "sourceadmin.smx", "s.smx", "boomstick.smx", "hax.smx", "sourcemod.smx" };

new cvar_pos[MAXPLAYERS];

new Handle:rcon_pw;
new bool:rcon_set=false;
new bool:logging=false;
new String:correct_rcon_pw[256];

new Handle:mintries;
new Handle:maxtries;

public OnPluginStart()
{
	CreateConVar("sm_rconlock", VERSION, "Plugin version", FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	RegConsoleCmd("ent_create",Cmd_EntCreate);
	RegConsoleCmd("give",Cmd_EntCreate);
	RegConsoleCmd("ent_fire",Cmd_EntFire);
	RegConsoleCmd("changelevel",Cmd_ChangeLevel);
	RegServerCmd("log",Cmd_Log);

	// Grab the rcon password to prevent changes
	rcon_pw = FindConVar("rcon_password");
	HookConVarChange(rcon_pw,rcon_changed);

	// Flag any of the exploitable commands as cheats
	new Handle:curcmd;
	LogMessage("%i cheat commands",sizeof(cheat_flag));
	for (new i=0;i<sizeof(cheat_flag);i++)
	{
		if (GetCommandFlags(cheat_flag[i]) != INVALID_FCVAR_FLAGS)
		{
			LogMessage("Flagging %s as cheat",cheat_flag[i]);
			SetCommandFlags(cheat_flag[i],GetCommandFlags(cheat_flag[i])|FCVAR_CHEAT);
		}
		else
		{
			LogMessage("Couldn't find %s (this may be normal)",cheat_flag[i]);
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
		// Skip trying to register sm command, which is blocked
		if (StrEqual(curCmd,"sm")) continue;
		// Registering these make the server crash when they are executed
		if (StrEqual(curCmd,"quit")) continue;
		if (StrEqual(curCmd,"killserver")) continue;
		
		RegConsoleCmd(curCmd,HalfConnected);				
	} while (FindNextConCommand(cmdIt,curCmd,sizeof(curCmd),isCmd));
	
	GetGameFolderName(curCmd,sizeof(curCmd));
	if (StrEqual(curCmd,"left4dead",false) || StrEqual(curCmd,"left4dead2",false))
	{	// Workaround for bug #4066
		HookEvent("game_start",game_start);
	}
}

public Action:Cmd_Log(args)
{
	if (args == 0) return Plugin_Continue;
	
	if (logging)
	{
		PrintToServer("Cannot stop logging right now.");
		return Plugin_Stop;
	}
	
	new String:arg1[32];
	GetCmdArg(1,arg1,sizeof(arg1));
	
	if (StrEqual(arg1,"on",false))
	{
		logging = true;
	}
	return Plugin_Continue;
}

/*
************************** CLIENT PLUGINS ********************************
*/
public OnClientPutInServer(client)
{
	cvar_pos[client] = 0;
	CreateTimer(5.0, CheckPlayer, client, TIMER_REPEAT);
	CreateTimer(5.0, StartTeleCheck, client, TIMER_REPEAT);
	OnClientSettingsChanged(client);
}

public Action:CheckPlayer(Handle:timer,any:value)
{
	if (!IsClientInGame(value) || IsFakeClient(value)) return Plugin_Stop;
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
	LogMessage("Removing client '%L' as %s=%s",client, cvarName, cvarValue);
	KickClient(client,"Please remove any plugins you are running");
}

/*
************************** RCON LOCK ********************************
*/

public game_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!rcon_set) OnConfigsExecuted();
}
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
			LogMessage("Blocking ent_create from '%L', for containing %s", client, forbidden_ents[i]);
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
			LogMessage("Blocking ent_fire from '%L': %s",client, argstring);
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

/*
********************************** CHANGELEVEL ***************************************
*/
public Action:Cmd_ChangeLevel(client, args)
{
	if (client != 0)
	{
		new String:argstring[1024];
		GetCmdArgString(argstring,1024);
		LogMessage("Blocking changelevel from '%L': %s",client,argstring);
		return Plugin_Stop;
	}
	return Plugin_Continue;
}
/*
********************************** UNNAMMED ***************************************
*/

public OnClientSettingsChanged(client)
{
	if (IsFakeClient(client)) return;
	new String:newname[128];
	GetClientName(client,newname,sizeof(newname));
	if (strlen(newname) == 0)
	{
		LogMessage("Removing client '%L' for not having a name", client);
		KickClient(client,"Please set a name, then rejoin");
	}
	if (StrContains(newname,"\x07") != -1)
	{
		ReplaceString(newname,sizeof(newname),"\x07","");
		SetClientInfo(client,"name",newname);
		LogMessage("Removing client '%L' for having BELL characters", client);
		KickClient(client,"The bell does not toll here.  Remove bell characters from your name");
	}
	if (StrContains(newname,"%") != -1)
	{
		ReplaceString(newname,sizeof(newname),"%","");
		SetClientInfo(client,"name",newname);
		LogMessage("Removing client '%L' for having % characters", client);
		KickClient(client,"Please remove all % characters from your name");
	}
}

/*
********************************** TELEPORT ***************************************
*/
	
public Action:StartTeleCheck(Handle:timer,any:value)
{
	if (!IsClientConnected(value) || !IsClientInGame(value)) return Plugin_Stop;
	QueryClientConVar(value, "sensitivity", TeleCheckDone);
	return Plugin_Continue;
}

public TeleCheckDone(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[], any:value)
{
	if (result != ConVarQuery_Okay) return;
	new Float:fValue = StringToFloat(cvarValue);
	if (fValue < 1000.0) return;
	
	LogMessage("Removing client '%L' as sensitivity=%f",client, fValue);
	KickClient(client,"Please lower your sensitivity");
}


/*
********************************** EARLY CMD ***************************************
*/

public Action:HalfConnected(client, args)
{
	if (client == 0) return Plugin_Continue;
	if (!IsClientInGame(client) || !IsClientConnected(client))
	{
		new String:argstring[1024], String:ip[64];
		GetCmdArgString(argstring,1024);
		GetClientIP(client,ip,sizeof(ip));
		LogMessage("Got half-connected command from client %s: %s",ip,argstring);
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

/*
********************************** DELETE PLUGINS ***************************************
*/

public OnMapStart()
{
	DeletePlugins();
}

public OnMapEnd()
{
	DeletePlugins();
}

DeletePlugins()
{
	/* 
		This will delete some of the known malicious plugins from the server
		They frequently end up installed through an exploit, and people don't 
		realize they exist 
	*/
	
	new String:temp[1024];
	
	for (new i=0;i<sizeof(bad_plugins);i++)
	{
		BuildPath(Path_SM,temp,sizeof(temp),"plugins/%s",bad_plugins[i]);
		
		if (FileExists(temp))
		{
			LogMessage("Deleted malicious plugin %s",bad_plugins[i]);
			DeleteFile(temp);
		}
	}

	
	
}