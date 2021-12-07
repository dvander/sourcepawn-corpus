/*
	SM Super Commands by pRED*
	
	Large range of admin fun commands..
	Requires The admin flags Custom 4 for most commands (letter 'r')
	You can change the below line #define ADMIN_LEVEl *** to something else if you wish
	
	All powers are reset each round.

	Features and Commands:

	Armour 						- sm_armour <player/@ALL/@CT/@T> <armour>
	HP 							- sm_hp <player/@ALL/@CT/@T> <hp>			
	Bury						- sm_bury <player/@ALL/@CT/@T>, sm_unbury <player>
	Give item (weapons etc)		- sm_weapon <player/@ALL/@CT/@T> <itemname> (eg weapon_ak47)
	Teamswap					- sm_teamswap / sm_swapteam - <player1> <player2> etc etc. Or no args to swap entire team
	Move player team			- sm_team <player/@ALL/@CT/@T> <teamid>  (CSS 1-spec, 2-t, 3-ct)
	Defuser						- sm_defuser <player/@ALL/@CT/@T> <1|0>
	NV							- sm_nv <player/@ALL/@CT/@T> <1|0>
	Helmet						- sm_helmet <player/@ALL/@CT/@T> <1|0>
	God Mode					- sm_god <player/@ALL/@CT/@T> <1|0>
	Gravity						- sm_gravity <player/@ALL/@CT/@T> <Float gravity multiplier>  (eg 1.0 (normal), 0.5 (half))
	Extend						- sm_extend <minutes>
	Speed						- sm_speed <player/@ALL/@CT/@T> <Float speed 
	Name						- sm_name <player> <newname>multiplier> (eg 1.0 (normal), 2.0 (double))
	Damage Done (shows damage done to other players in a hint text message)
								- Cvar: sm_showdamage <1|0>
	Respawn						- sm_respawn <player/@ALL/@CT/@T>
	Disarm						- sm_disarm <player/@ALL/@CT/@T>
	Shutdown					- sm_shutdown (forces players to retry as well, usefull if server auto restarts)
	Connect Announce			- Cvar: sm_connectannounce <1|0>
	Admin See All				- Cvar: sm_adminseeall <1|0>
	Teleport					- sm_teleport <player/@ALL/@CT/@T> <x/#saveloc> <y> <z>
	Client Execute				- sm_exec <player/@ALL/@CT/@T> <command string>
	Get Player Location			- sm_getloc <player> - leave blank for your location
	Save Player Location		- sm_saveloc - Saves your current location and gives you a saveloc number to use with teleport
								
	Things To Do:
	
	- INS Support
	- Swap team at round end
	- Alive checks
	- HL2DM 'armour' support. Respawn?
	
	Changelog:
	
	0.1 	- Initial Release.
	0.11 	- Fixed GodMode
	0.2 	- Added Slay
			- Added Respawn
			- Disarm
			- Fixed team/teamswap
			- New teamswap command (sm_swapteam)
			- Hp/Armour tweaks
	0.3		- Added @ALL/@CT/@T for most commands
			- Added list of defined Admin Levels
	0.31	- Fixed teamswaping again (hopefully....?)
			- Changed method of slaying. See how this works..
	0.4		- Admin See All
			- Connect Anounce
			- Server Shutdown
			- Removed Slay and Burn (basefuncommands stole them.. >: )
	0.5		- Fixed team change in DoD:S, should work in most mods now (The-Killer)
			- Added team name support for other mods, currently CSS, DODS, HL2DM, looking into INS, PVK, Hidden, Sourceforts, Dystopia (The-Killer)
			- Added teamswap for single players (The-Killer)
			- Added Check for cstrike on cstrike specific commands(armor helmet nv defuse) (The-Killer)
			- Reorganised entire plugin to be smaller
			- Renamed Gamedata to "supercmds.gamedata.txt" - to avoid confusion with translation files
			- Fixed a dumb mistake in the gamedata file.
			- Changed to use native hint text
			- Added sm_exec, sm_teleport and sm_getloc
	0.51	- Added Connected checks to the say/say_team handlers
			- Added sm_saveloc
	0.52	- Added sm_freeze <player> <1/0>  1=freeze 0=un-freeze - TechKnow (I think..)
			- Added sm_name - majority of code thanks to bl4nk
			- Updated to use new ProcessTargetString and FindTarget natives
			- Cleaned up adminseeall code
			- Added autoexec config
	0.6		- Added some crazy output config. I don't know why, someone wanted it..
			- Armour should work for hl2dm
			- OTHER STUFF THAT IVE SINCE FORGOTTEN
			
	Credits:
	
			teame06 - help with signature stuff and getting the team switching to work <3
			
	Admin Levels to be used with the below Section
	
		ADMFLAG_RESERVATION
		ADMFLAG_GENERIC
		ADMFLAG_KICK
		ADMFLAG_BAN
		ADMFLAG_UNBAN
		ADMFLAG_SLAY
		ADMFLAG_CHANGEMAP
		ADMFLAG_CONVARS
		ADMFLAG_CONFIG
		ADMFLAG_CHAT
		ADMFLAG_VOTE
		ADMFLAG_PASSWORD
		ADMFLAG_RCON
		ADMFLAG_CHEATS
		ADMFLAG_ROOT
		ADMFLAG_CUSTOM1
		ADMFLAG_CUSTOM2
		ADMFLAG_CUSTOM3
		ADMFLAG_CUSTOM4
		ADMFLAG_CUSTOM5
		ADMFLAG_CUSTOM6
		
*/

#include <sourcemod>
#include <sdktools>
#include <geoip>
#undef REQUIRE_EXTENSIONS
#include <cstrike>

#define PLUGIN_VERSION "0.60"

//Global admin level needed for most commands
//Change ADMFLAG_CUSTOM4 to something from the above list if you wish
#define ADMIN_LEVEL ADMFLAG_CUSTOM4
// Use overrides to quickly edit command access levels.

new Handle:g_hMpTimelimit
new Handle:g_hShowDmg
new Handle:g_hConnectAnnounce
new Handle:g_hAdminSeeAll

new Handle:hGameConf
new Handle:hRoundRespawn
new Handle:hRemoveItems

new Handle:coords

new Handle:thisplugin

new maxplayers

new String:modname[30]

#define NUMMODS 5
#define CSTRIKE 0
#define DOD 1
#define HL2MP 2
#define INS 3
#define TF 4

new bool:cstrike;

new Handle:g_configParser = INVALID_HANDLE;
new Handle:g_functionsTrie = INVALID_HANDLE;

new Handle:hShowActivity;

#define NUMCOMMANDS 22

enum Commands
{
	CommandType_Bury,
	CommandType_UnBury,
	CommandType_Respawn,
	CommandType_Disarm,
	CommandType_Armour,
	CommandType_Weapon,
	CommandType_God,
	CommandType_Speed,
	CommandType_NV,
	CommandType_Defuser,
	CommandType_Helmet,
	CommandType_TeamSwap,
	CommandType_Team,
	CommandType_Spec,
	CommandType_Extend,
	CommandType_Shutdown,
	CommandType_Exec,
	CommandType_Teleport,
	CommandType_Location,
	CommandType_SaveLocation,
	CommandType_Name,
	CommandType_HP	
};

new g_commandOverrides[Commands];
new g_defaultCommandOverride;

#define OVERRIDE_TRIGGER				(1<<0)
#define OVERRIDE_TARGET					(1<<1)
#define OVERRIDE_LOG					(1<<2)
#define OVERRIDE_SERVER					(1<<3)
#define OVERRIDE_ALL					(1<<4)

new mod
static String:teamname[NUMMODS][3][] =  
{
	{"All","Terrorist","Counter-Terrorist" },
	{"All","Allies","Axis" },
	{"All","Combine","Rebels" },
	{"All","US Marines","Insurgents"}, //This might be the other way around
	{"All", "Red", "Blue"}
};

public Plugin:myinfo = 
{
	name = "SM Super Commands",
	author = "pRED*",
	description = "Assorted Fun Commands",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	LoadTranslations("plugin.supercmds");
	
	CreateConVar("sm_supercmds_version", PLUGIN_VERSION, "Super Commands Version", FCVAR_NONE|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	GetGameFolderName(modname, sizeof(modname));
	
	//Get mod name stuff
	if (StrEqual(modname,"cstrike",false)) mod = CSTRIKE;
	else if (StrEqual(modname,"dod",false)) mod = DOD;
	else if (StrEqual(modname,"hl2mp",false)) mod = HL2MP;
	else if (StrEqual(modname,"Insurgency",false)) mod = INS;
	else if (StrEqual(modname,"tf",false)) mod = TF;
	
	cstrike = LibraryExists("cstrike");
	
	RegAdminCmd("sm_bury", Command_Bury, ADMFLAG_CUSTOM4);
	RegAdminCmd("sm_unbury", Command_UnBury, ADMFLAG_CUSTOM4);
	RegAdminCmd("sm_respawn", Command_Respawn, ADMFLAG_CUSTOM4);
	RegAdminCmd("sm_disarm", Command_Disarm, ADMFLAG_CUSTOM4);
	RegAdminCmd("sm_armour", Command_Armour, ADMFLAG_CUSTOM4);
	RegAdminCmd("sm_weapon", Command_Weapon, ADMFLAG_CUSTOM4);
	RegAdminCmd("sm_god", Command_God, ADMFLAG_CUSTOM4);
	RegAdminCmd("sm_speed", Command_Speed, ADMFLAG_CUSTOM4);
	RegAdminCmd("sm_nv", Command_NV, ADMFLAG_CUSTOM4);
	RegAdminCmd("sm_defuser", Command_Defuser, ADMFLAG_CUSTOM4);
	RegAdminCmd("sm_helmet", Command_Helmet, ADMFLAG_CUSTOM4);
	RegAdminCmd("sm_teamswap", Command_TeamSwap, ADMFLAG_CUSTOM4);
	RegAdminCmd("sm_swapteam", Command_TeamSwap, ADMFLAG_CUSTOM4);
	RegAdminCmd("sm_team", Command_Team, ADMFLAG_CUSTOM4);
	RegAdminCmd("sm_spec", Command_Spec, ADMFLAG_CUSTOM4);
	RegAdminCmd("sm_extend", Command_Extend, ADMFLAG_CUSTOM4);
	RegAdminCmd("sm_shutdown", Command_Shutdown, ADMFLAG_CUSTOM4);
	RegAdminCmd("sm_exec", Command_Exec, ADMFLAG_CUSTOM4);
	RegAdminCmd("sm_teleport", Command_Teleport, ADMFLAG_CUSTOM4);
	RegAdminCmd("sm_getloc", Command_Location, ADMFLAG_CUSTOM4);
	RegAdminCmd("sm_saveloc", Command_SaveLocation, ADMFLAG_CUSTOM4);
	RegAdminCmd("sm_name", Command_Name, ADMFLAG_CUSTOM4);
	RegAdminCmd("sm_hp", Command_HP, ADMFLAG_CUSTOM4);

	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_SayTeam);
	
	g_hMpTimelimit = FindConVar("mp_timelimit");
	g_hShowDmg = CreateConVar("sm_showdamage","1","Show Damage Done");
	g_hConnectAnnounce = CreateConVar("sm_connectannounce","1","Announce connections");
	g_hAdminSeeAll = CreateConVar("sm_adminseeall","1","Show admins all chat");
	
	hGameConf = LoadGameConfigFile("supercmds.gamedata");
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "RoundRespawn");
	hRoundRespawn = EndPrepSDKCall();
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "RemoveAllItems");
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	hRemoveItems = EndPrepSDKCall();
	
	HookEvent("player_hurt", Event_PlayerHurt);
	
	thisplugin = GetMyHandle();
	
	coords = CreateArray(3);
	
	AutoExecConfig(true, "super_cmds");
	
	hShowActivity = FindConVar("sm_show_activity");
}

public OnConfigsExecuted()
{
	g_functionsTrie = CreateTrie();

	SetTrieValue(g_functionsTrie, "sm_bury", CommandType_Bury);
	SetTrieValue(g_functionsTrie, "sm_unbury", CommandType_UnBury);
	SetTrieValue(g_functionsTrie, "sm_respawn", CommandType_Respawn);
	SetTrieValue(g_functionsTrie, "sm_disarm", CommandType_Disarm);
	SetTrieValue(g_functionsTrie, "sm_armour", CommandType_Armour);
	SetTrieValue(g_functionsTrie, "sm_weapon", CommandType_Weapon);
	SetTrieValue(g_functionsTrie, "sm_god", CommandType_God);
	SetTrieValue(g_functionsTrie, "sm_speed", CommandType_Speed);
	SetTrieValue(g_functionsTrie, "sm_nv", CommandType_NV);
	SetTrieValue(g_functionsTrie, "sm_defuser", CommandType_Defuser);
	SetTrieValue(g_functionsTrie, "sm_helmet", CommandType_Helmet);
	SetTrieValue(g_functionsTrie, "sm_teamswap", CommandType_TeamSwap);
	SetTrieValue(g_functionsTrie, "sm_swapteam", CommandType_TeamSwap);
	SetTrieValue(g_functionsTrie, "sm_team", CommandType_Team);
	SetTrieValue(g_functionsTrie, "sm_spec", CommandType_Spec);
	SetTrieValue(g_functionsTrie, "sm_extend", CommandType_Extend);
	SetTrieValue(g_functionsTrie, "sm_shutdown", CommandType_Shutdown);
	SetTrieValue(g_functionsTrie, "sm_exec", CommandType_Exec);
	SetTrieValue(g_functionsTrie, "sm_teleport", CommandType_Teleport);
	SetTrieValue(g_functionsTrie, "sm_getloc", CommandType_Location);
	SetTrieValue(g_functionsTrie, "sm_saveloc", CommandType_SaveLocation);
	SetTrieValue(g_functionsTrie, "sm_name", CommandType_Name);
	SetTrieValue(g_functionsTrie, "sm_hp", CommandType_HP);
	
	ParseConfigs();
	
	CloseHandle(g_functionsTrie);	
}

ParseConfigs()
{
	if (g_configParser == INVALID_HANDLE)
	{
		g_configParser = SMC_CreateParser();
	}
	
	SMC_SetReaders(g_configParser, NewSection, KeyValue, EndSection);
	
	decl String:configPath[256];
	BuildPath(Path_SM, configPath, sizeof(configPath), "configs/super_command_overrides.cfg");
	
	if (!FileExists(configPath))
	{
		LogError("Unable to locate overrides file.");
			
		return;		
	}
	
	/* Reset array */
	for (new i=0; i<NUMCOMMANDS; i++)
	{
		g_commandOverrides[i] = -1;

	}
	
	g_defaultCommandOverride = 8;
	
	new line;
	new SMCError:err = SMC_ParseFile(g_configParser, configPath, line);
	if (err != SMCError_Okay)
	{
		decl String:error[256];
		SMC_GetErrorString(err, error, sizeof(error));
		LogError("Could not parse file (line %d, file \"%s\"):", line, configPath);
		LogError("Parser encountered error: %s", error);
	}
	
	return;
}

public SMCResult:NewSection(Handle:smc, const String:name[], bool:opt_quotes)
{

}

public SMCResult:KeyValue(Handle:smc, const String:key[], const String:value[], bool:key_quotes, bool:value_quotes)
{
	new flags = StringToInt(value);
	
	if (StrEqual(key, "default"))
	{
		g_defaultCommandOverride = flags;
	}
	else
	{
		new Command:location;
		if (GetTrieValue(g_functionsTrie, key, location))
		{
			g_commandOverrides[location] = flags;
		}
	}

}

public SMCResult:EndSection(Handle:smc)
{
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "cstrike"))
	{
		cstrike = false;
	}
}
 
public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "cstrike"))
	{
		cstrike = true;
	}
}

public OnMapStart()
{
	maxplayers = GetMaxClients()
	
	ClearArray(coords)
}

Action:FindPlayer(client, String:target[], Function:func, other, flags=0)
{
	new num=trim_quotes(target)
	
	new targets[MAXPLAYERS];
	
	new String:buffername[2];
	new bool:bufferbool;
	
	new count = ProcessTargetString(target[num],
						   client, 
						   targets,
						   MAXPLAYERS,
						   flags,
						   buffername,
						   1,
						   bufferbool);
	
	if (count < 1)
	{
		ReplyToTargetError(client, count);
		return Plugin_Handled;
	}
	
	for (new i = 0; i < count; i++)
	{
		Call_StartFunction(thisplugin, func);
		Call_PushCell(client);
		Call_PushCell(targets[i]);
		Call_PushCell(other);
		Call_Finish();
	}
	
	return Plugin_Handled;
}

NotifyPrint(client, target, Commands:command, String:format[], any:...)
{
	new flags = g_commandOverrides[command];
	
	if (flags == -1)
	{
		flags = g_defaultCommandOverride;	
	}
	
	if (flags == -1)
	{
		return;	
	}
	
	decl String:buffer[256];
	VFormat(buffer, sizeof(buffer), format, 5);
	
	decl String:targetName[32]
	GetClientName(target, targetName, sizeof(targetName));
	
	if (flags & OVERRIDE_ALL)
	{
		ShowActivity2(client, "[SM] ", "%T", "Client", LANG_SERVER, targetName, buffer);
	}
	else
	{		
		if (flags & OVERRIDE_TRIGGER)
		{
			PrintToChat(client, "%t", "Client", targetName, buffer);		
		}
		
		if (flags & OVERRIDE_TARGET)
		{
			/* Don't print to target if it has already been printed to them */
			if (!((flags & OVERRIDE_TRIGGER) && (client == target)))
			{
				if (ShowName(client, target))
				{
					PrintToChat(target, "%N: %t", client, "You", buffer);
				}
				else
				{
					PrintToChat(target, "ADMIN: %t", "You", buffer);	
				}
			}
		}
	}
	
	if (flags & OVERRIDE_LOG)
	{
		LogAction(client, -1, "%T by %L", "Client", LANG_SERVER, targetName, buffer, client);
	}
	
	if (flags & OVERRIDE_SERVER)
	{
		PrintToServer("%T by %L", "Client", LANG_SERVER, targetName, buffer, client);	
	}
}


bool:ShowName(client, target)
{
	new value = GetConVarInt(hShowActivity);
	new flags = GetUserFlagBits(target);
	
	if (!flags)
	{
		/* Treat this as a normal user */
		if ((value & 2) || (target == client))
		{
			return true;
		}

		return false;
	}
	else
	{
		/* Treat this as an admin user */
		new bool:is_root = bool:(flags & ADMFLAG_ROOT);

		if ((value & 8) || ((value & 16) && is_root) || (target == client))
		{
			return true;
		}
	
		return false;
	}
}

public ExecHP(client, target, any:health)
{
	SetEntProp(target, Prop_Send, "m_iHealth", health, 1)
	SetEntProp(target, Prop_Data, "m_iHealth", health, 1)
	NotifyPrint(client, target, CommandType_HP, "\x01\x04%T", "Health", LANG_SERVER, health)
}

public Action:Command_HP(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_hp <name or #userid> <hp>");
		return Plugin_Handled;	
	}	
	
	new String:Target[64],String:hp[10]
	GetCmdArg(1, Target, sizeof(Target))
	GetCmdArg(2, hp, sizeof(hp))
	
	new health = StringToInt(hp)
	
	return FindPlayer(client, Target, ExecHP, any:health, COMMAND_FILTER_ALIVE)
}

public ExecSpeed(client, target, any:speed)
{
    if (speed == 0)
    {
		SetEntPropFloat(target, Prop_Data, "m_flLaggedMovementValue", Float:speed)
		NotifyPrint(client, target, CommandType_Speed, "\x01\x04%T", "Frozen", LANG_SERVER)
    }
    else if (speed == 1.0)
    {
		SetEntPropFloat(target, Prop_Data, "m_flLaggedMovementValue", Float:speed)
		NotifyPrint(client, target, CommandType_Speed, "\x01\x04%T", "Normal Movement", LANG_SERVER)
    }
    else
    {
		SetEntPropFloat(target, Prop_Data, "m_flLaggedMovementValue", Float:speed)
		NotifyPrint(client, target, CommandType_Speed, "\x01\x04%T", "Custom Movement", LANG_SERVER, speed)
	}
}

public Action:Command_Speed(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_speed <name or #userid> <Float speed mult>");
		return Plugin_Handled;	
	}	
	
	new String:Target[64],String:hp[10]
	GetCmdArg(1, Target, sizeof(Target))
	GetCmdArg(2, hp, sizeof(hp))

	new Float:speed = StringToFloat(hp)
	
	return FindPlayer(client, Target, ExecSpeed, any:speed, COMMAND_FILTER_ALIVE)
}

public ExecLocation(client, target, Float:origin[3])
{
	new String:name[30]
	GetClientName(target, name, sizeof(name))
	PrintToChat(client, "\x01\x04%t", "Location", name, origin[0], origin[1], origin[2])
}

public Action:Command_Location(client,args)
{
	new Float:origin[3]

	if (args == 0)
	{
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", origin)
		ExecLocation(client,client,origin)
	}
	else if (args == 1)
	{	
		new String:Target[64]
		
		GetCmdArg(1, Target, sizeof(Target))

		new num=trim_quotes(Target)
		
		new targets[MAXPLAYERS];
	
		new String:buffername[2];
		new bool:bufferbool;
		
		new count = ProcessTargetString(Target[num],
							   client, 
							   targets,
							   MAXPLAYERS,
							   0,
							   buffername,
							   1,
							   bufferbool);
		
		if (count < 1)
		{
			ReplyToTargetError(client, count);
			return Plugin_Handled;
		}
		
		for (new i = 0; i < count; i++)
		{
			GetEntPropVector(targets[i], Prop_Send, "m_vecOrigin", origin);
			ExecLocation(client ,targets[i], origin);
		}
	}
	else
	{
		ReplyToCommand(client, "[SM] Usage: sm_getloc <name or #userid>");		
	}
	
	return Plugin_Handled;
}

public Action:Command_SaveLocation(client,args)
{
	new Float:origin[3]

	GetEntPropVector(client, Prop_Send, "m_vecOrigin", origin)
	
	PushArrayArray(coords, _:origin)
	PrintToChat(client,"\x01\x04%t", "Save Location", GetArraySize(coords))
	
	return Plugin_Handled;
}

public ExecTeleport(client, target, Float:origin[3])
{
	TeleportEntity(target, origin, NULL_VECTOR, NULL_VECTOR)
	NotifyPrint(client, target, CommandType_Teleport, "\x01\x04%T", "Teleport", LANG_SERVER, origin[0], origin[1], origin[2])
}

public Action:Command_Teleport(client,args)
{
	if (args != 4 && args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_teleport <name or #userid> <x> <y> <z> or sm_teleport <name or #userid> <#location>");
		return Plugin_Handled;	
	}	
	
	new String:Target[64],String:x[10],String:y[10], String:z[10]
	
	GetCmdArg(1, Target, sizeof(Target))
	GetCmdArg(2, x, sizeof(x))
	
	new Float:origin[3]
	
	if (args == 4)
	{
		GetCmdArg(3, y, sizeof(y))
		GetCmdArg(4, z, sizeof(z))
	}

	if (x[0] == '#')
	{
		new index = StringToInt(x[1])-1
		
		if (index > -1 && index < GetArraySize(coords))
			GetArrayArray(coords, index, _:origin);
		else
		{
			ReplyToCommand(client, "[SM] Invalid Teleport Save Location");
			return Plugin_Handled;
		}
	}
	else
	{
		origin[0] = StringToFloat(x)
		origin[1] = StringToFloat(y)
		origin[2] = StringToFloat(z)
	}
	new num=trim_quotes(Target)
	
	new targets[MAXPLAYERS];
	
	new String:buffername[2];
	new bool:bufferbool;
	
	new count = ProcessTargetString(Target[num],
			client, 
			targets,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			buffername,
			1,
			bufferbool);
	
	if (count < 1)
	{
		ReplyToTargetError(client, count);
		return Plugin_Handled;
	}
	
	for (new i = 0; i < count; i++)
	{
		ExecTeleport(client, targets[i], origin)
	}
	
	return Plugin_Handled;	
}

public ExecClient(client, target, String:Command[])
{
	ClientCommand(target, Command)
	NotifyPrint(client, target, CommandType_Exec, "\x01\x04%T", "Exec", LANG_SERVER)
}

public Action:Command_Exec(client,args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_exec <name or #userid> <command>");
		return Plugin_Handled;	
	}	
	
	new String:Target[64],String:buffer[256]
	
	GetCmdArgString(buffer, sizeof(buffer));
	new start = BreakString(buffer, Target, sizeof(Target));

	new num=trim_quotes(Target)
	
	new targets[MAXPLAYERS];
	
	new String:buffername[2];
	new bool:bufferbool;
	
	new count = ProcessTargetString(Target[num],
			client, 
			targets,
			MAXPLAYERS,
			0,
			buffername,
			1,
			bufferbool);
	
	if (count < 1)
	{
		ReplyToTargetError(client, count);
		return Plugin_Handled;
	}
	
	for (new i = 0; i < count; i++)
	{
		ExecClient(client, targets[i] ,buffer[start]);
	}
	
	return Plugin_Handled;	
}

public ExecGod(client, target, any:status)
{
	if (status)
	{
		SetEntProp(target, Prop_Data, "m_takedamage", 0, 1)
		NotifyPrint(client, target, CommandType_God, "\x01\x04%T", "God", LANG_SERVER)
	}
	else
	{
		SetEntProp(target, Prop_Data, "m_takedamage", 2, 1)
		NotifyPrint(client, target, CommandType_God, "\x01\x04%T", "NoGod", LANG_SERVER)
	}
}

public Action:Command_God(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_god <name or #userid> <1|0>");
		return Plugin_Handled;	
	}	
	
	new String:Target[64],String:on[10]
	GetCmdArg(1, Target, sizeof(Target))
	GetCmdArg(2, on, sizeof(on))

	new status = StringToInt(on)
	
	return FindPlayer(client, Target, ExecGod, any:status, COMMAND_FILTER_ALIVE)
}

public ExecNV(client, target, any:status)
{
	if (status)
	{
		SetEntProp(target, Prop_Send, "m_bHasNightVision", 1, 1)
		NotifyPrint(client, target, CommandType_NV, "\x01\x04%T", "NV Give", LANG_SERVER)
	}
	else
	{
		SetEntProp(target, Prop_Send, "m_bHasNightVision", 0, 1)
		NotifyPrint(client, target, CommandType_NV, "\x01\x04%T", "NV Remove", LANG_SERVER)
	}
}

public Action:Command_NV(client, args)
{
	if (mod != CSTRIKE)
	{
		ReplyToCommand(client, "[SM] That Command is not supported on this mod (Cstrike only)");
		return Plugin_Handled;	
	}
	
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_nv <name or #userid> <1|0>");
		return Plugin_Handled;	
	}	
	
	new String:Target[64],String:on[10]
	GetCmdArg(1, Target, sizeof(Target))
	GetCmdArg(2, on, sizeof(on))
	
	new status = StringToInt(on)
	
	return FindPlayer(client, Target, ExecNV, any:status, COMMAND_FILTER_ALIVE)
}

public ExecDefuser(client, target, any:status)
{
	if (status)
	{
		SetEntProp(target, Prop_Send, "m_bHasDefuser", 1, 1)
		NotifyPrint(client, target, CommandType_Defuser, "\x01\x04%T", "Defuse Give", LANG_SERVER)
	}
	else
	{
		SetEntProp(target, Prop_Send, "m_bHasDefuser", 0, 1)
		NotifyPrint(client, target, CommandType_Defuser, "\x01\x04%T", "Defuse Remove", LANG_SERVER)
	}
}

public Action:Command_Defuser(client, args)
{
	if (mod != CSTRIKE)
	{
		ReplyToCommand(client, "[SM] That Command is not supported on this mod (Cstrike only)");
		return Plugin_Handled;	
	}
	
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_defuser <name or #userid> <1|0>");
		return Plugin_Handled;	
	}	
	
	new String:Target[64],String:on[10]
	GetCmdArg(1, Target, sizeof(Target))
	GetCmdArg(2, on, sizeof(on))

	new status = StringToInt(on)
	
	return FindPlayer(client, Target, ExecDefuser, any:status, COMMAND_FILTER_ALIVE)
}

public ExecHelmet(client, target, any:status)
{
	if (status)
	{
		SetEntProp(target, Prop_Send, "m_bHasHelmet", 1, 1)
		NotifyPrint(client, target, CommandType_Helmet, "\x01\x04%T", "Helmet Give", LANG_SERVER)
	}
	else
	{
		SetEntProp(target, Prop_Send, "m_bHasHelmet", 0, 1)
		NotifyPrint(client, target, CommandType_Helmet, "\x01\x04%T", "Helmet Remove", LANG_SERVER)
	}	
}

public Action:Command_Helmet(client, args)
{
	if (mod != CSTRIKE)
	{
		ReplyToCommand(client, "[SM] That Command is not supported on this mod (Cstrike only)");
		return Plugin_Handled;	
	}
	
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_helmet <name or #userid> <1|0>");
		return Plugin_Handled;	
	}	
	
	new String:Target[64],String:on[10]
	GetCmdArg(1, Target, sizeof(Target))
	GetCmdArg(2, on, sizeof(on))
	
	new status = StringToInt(on)
	
	return FindPlayer(client, Target, ExecHelmet, any:status, COMMAND_FILTER_ALIVE)
}

public ExecTeam(client, target, any:teamid)
{
	if (mod == CSTRIKE && cstrike && (teamid == 2 || teamid == 3))
	{
		CS_SwitchTeam(target, teamid);
	}
	else
	{
		ChangeClientTeam(target, teamid)
	}
		
	PrintToChat(target, "\x01\x04%t", "Team", teamname[mod][teamid-1])
}

public Action:Command_Team(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_team <name or #userid> <teamindex>");
		return Plugin_Handled;	
	}
	
	new String:Target[64],String:team[5]
	GetCmdArg(1, Target, sizeof(Target))
	GetCmdArg(2, team, sizeof(team))

	new teamid = StringToInt(team)
	
	if (!(teamid<4 && teamid>0))
		return Plugin_Handled;
		
	return FindPlayer(client, Target, ExecTeam, any:teamid)
}

public Action:Command_Spec(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_spec <name or #userid>");
		return Plugin_Handled;	
	}
	
	new String:Target[64]
	GetCmdArg(1, Target, sizeof(Target))

	return FindPlayer(client, Target, ExecTeam, any:1)
}

public Action:Command_Extend(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_extend <minutes>");
		return Plugin_Handled;	
	}
	
	new String:time[7]
	GetCmdArg(1, time, sizeof(time))
	
	new inttime = StringToInt(time)
	
	new timelimit = GetConVarInt(g_hMpTimelimit)
	timelimit += inttime
	SetConVarInt(g_hMpTimelimit, timelimit)
	
	PrintToChatAll("\x01\x04%T", "Extend", LANG_SERVER, inttime)
	
	return Plugin_Handled;	
}

public Action:Command_TeamSwap(client, args)
{
	new team, i;
	
	if ( args == 0 )
	{
		for(i = 1; i <= maxplayers; i++)
		{
			if (IsClientInGame(i))
			{
				team = GetClientTeam(i);
				if (team==2)
				{
					if (mod == CSTRIKE && cstrike)
					{
						CS_SwitchTeam(i, 3);
					}
					else
					{
						ChangeClientTeam(i, 3);
					}
				}
				else if (team==3)
				{
					if (mod == CSTRIKE && cstrike)
					{
						CS_SwitchTeam(i, 2);
					}
					else
					{
						ChangeClientTeam(i, 2);
					}
				}
				
				NotifyPrint(client, i, CommandType_TeamSwap, "\x01\x04%T", "Swapped", LANG_SERVER)
			}
		}
	}
	else if ( args >= 1)
	{

		new String:Target[64]
		for (i =1 ; i<=args; i++) 
		{
			GetCmdArg(i, Target, sizeof(Target))
			
			new iClient = FindTarget(client, Target);
			
			if (iClient == -1)
				continue
		
			if (IsClientInGame(iClient))
			{
				team = GetClientTeam(iClient)
				if (team==2)
				{
					if (mod == CSTRIKE && cstrike)
					{
						CS_SwitchTeam(iClient, 3);
					}
					else
					{
						ChangeClientTeam(iClient, 3)
					}
				}
				else if (team==3)
				{
					if (mod == CSTRIKE && cstrike)
					{
						CS_SwitchTeam(iClient, 2);
					}
					else
					{
						ChangeClientTeam(iClient, 2)
					}
				}
				
				NotifyPrint(client, iClient, CommandType_TeamSwap, "\x01\x04%T", "Swapped", LANG_SERVER)
			}
		}
	}
	
	return Plugin_Handled;	
}

public Action:Command_Shutdown(client, args)
{
	PrintToChatAll("\x01\x04%T", "Shutdown", LANG_SERVER)
	CreateTimer(5.0, Shutdown)
}
	
public Action:Shutdown(Handle:timer)
{
	for(new i = 1; i <= maxplayers; i++)
	{
		if (IsClientInGame(i))
		{
			ClientCommand(i, "retry")
		}
	}
	
	InsertServerCommand("quit")
	ServerExecute()
}

public Action:Command_Weapon(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_weapon <name or #userid> <weapon name>");
		return Plugin_Handled;	
	}	
	
	new String:Target[64],String:weapon[30]
	GetCmdArg(1, Target, sizeof(Target))
	GetCmdArg(2, weapon, sizeof(weapon))

	new num = trim_quotes(Target)
	
	new targets[MAXPLAYERS];
	
	new String:buffername[2];
	new bool:bufferbool;
	
	new count = ProcessTargetString(Target[num],
						   client, 
						   targets,
						   MAXPLAYERS,
						   COMMAND_FILTER_ALIVE,
						   buffername,
						   1,
						   bufferbool);
	
	if (count < 1)
	{
		ReplyToTargetError(client, count);
		return Plugin_Handled;
	}
	
	for (new i = 0; i < count; i++)
	{
		new ent = GivePlayerItem(targets[i], weapon)

		if (ent == -1)
			ReplyToCommand(client, "[SM] Invalid Item")
		else
			NotifyPrint(client, targets[i], CommandType_Weapon, "\x01\x04%T", "Weapon", LANG_SERVER, weapon)
	}
	
	return Plugin_Handled;	
}

public ExecArmour(client, target, any:armour)
{
	if (mod == CSTRIKE)
	{
		SetEntProp(target, Prop_Send, "m_ArmorValue", armour, 1)
	}
	else if (mod == HL2MP)
	{
		SetEntProp(client, Prop_Data, "m_ArmorValue", armour, 1);
	}
	NotifyPrint(client, target, CommandType_Armour, "\x01\x04%T", "Armour", LANG_SERVER, armour)
}

public Action:Command_Armour(client, args)
{
	if (mod != CSTRIKE && mod != HL2MP)
	{
		ReplyToCommand(client, "[SM] That Command is not supported on this mod (Cstrike & HL2MP only)");
		return Plugin_Handled;	
	}
	
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_armour <name or #userid> <armour>");
		return Plugin_Handled;	
	}	
	
	new String:Target[64],String:armr[10]
	GetCmdArg(1, Target, sizeof(Target))
	GetCmdArg(2, armr, sizeof(armr))

	new armour = StringToInt(armr)
	
	return FindPlayer(client, Target, ExecArmour, any:armour, COMMAND_FILTER_ALIVE)
}

public ExecBury(client, target, any:bury)
{
	new Float:vec[3]
	
	if (!bury)
	{
		GetEntPropVector(target, Prop_Send, "m_vecOrigin", vec)

		vec[2]=vec[2]+30.0
		SetEntPropVector(target, Prop_Send, "m_vecOrigin", vec)

		NotifyPrint(client, target, CommandType_Bury, "\x01\x04%T", "UnBury", LANG_SERVER)
	}
	else
	{
		GetEntPropVector(target, Prop_Send, "m_vecOrigin", vec)
		vec[2]=vec[2]-30.0
		SetEntPropVector(target, Prop_Send, "m_vecOrigin", vec)
		
		NotifyPrint(client, target, CommandType_Bury, "\x01\x04%T", "Bury", LANG_SERVER)	
	}
}

public Action:Command_Bury(client, args)
{
	if (args != 1 && args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_bury <name or #userid> <1|0>");
		return Plugin_Handled;	
	}	
	
	new String:Target[64]
	GetCmdArg(1, Target, sizeof(Target))
	
	new type = 1;
	
	if (args == 2)
	{
		new String:typeString[10];
		GetCmdArg(2, typeString, sizeof(typeString));
		
		if (StringToInt(typeString))
		{
			type = 1;	
		}
		else
		{
			type = 0;	
		}
	}
	
	return FindPlayer(client, Target, ExecBury, type, COMMAND_FILTER_ALIVE)
}

public Action:Command_UnBury(client, args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_unbury <name or #userid>");
		return Plugin_Handled;	
	}	
	
	new String:Target[64]
	GetCmdArg(1, Target, sizeof(Target))
	
	return FindPlayer(client, Target, ExecBury, 0)
}

public ExecRespawn(client, target, any:blank)
{
	SDKCall(hRoundRespawn, target)
	NotifyPrint(client, target, CommandType_Respawn, "\x01\x04%T", "Respawn", LANG_SERVER)
}

public Action:Command_Respawn(client, args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_respawn <name or #userid>");
		return Plugin_Handled;	
	}	
	
	new String:Target[64]
	GetCmdArg(1, Target, sizeof(Target))
	
	return FindPlayer(client, Target, ExecRespawn, 0)
}

public ExecDisarm(client, target, any:blank)
{
	SDKCall(hRemoveItems, target, false)
	NotifyPrint(client, target, CommandType_Disarm, "\x01\x04%T", "Disarm", LANG_SERVER)	
}

public Action:Command_Disarm(client, args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_disarm <name or #userid>");
		return Plugin_Handled;	
	}	
	
	new String:Target[64]
	GetCmdArg(1, Target, sizeof(Target))
	
	return FindPlayer(client, Target, ExecDisarm, 0, COMMAND_FILTER_ALIVE)
}

public Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarInt(g_hShowDmg))
		return

	new attackerId = GetEventInt(event, "attacker")
	new damage = GetEventInt(event, "dmg_health")
 
	new attacker = GetClientOfUserId(attackerId)
	
	if (attacker<=0)
		return
 
	PrintHintText(attacker,"Damage : %i",damage)
}

public trim_quotes(String:text[])
{
	new startidx = 0
	if (text[0] == '"')
	{
		startidx = 1
		/* Strip the ending quote, if there is one */
		new len = strlen(text);
		if (text[len-1] == '"')
		{
			text[len-1] = '\0'
		}
	}
	
	return startidx
}

public Action:Command_Say(client, args)
{
	if (!GetConVarInt(g_hAdminSeeAll) || !client)
		return Plugin_Continue
	
	new String:text[192]
	GetCmdArgString(text, sizeof(text))
 
	new startidx = trim_quotes(text)
	
	//need to send message to admin if sender is dead
	if (!IsPlayerAlive(client))
	{
		new String:name[32]
		GetClientName(client,name,31)
	
		//dead
		for (new i=1; i<=maxplayers; i++)
		{
			if (IsClientInGame(i))
			{
				if ((GetUserFlagBits(i) & ADMFLAG_CHAT) && IsPlayerAlive(i))
					PrintToChat(i,"[ADMINSEEALL]%s: %s",name,text[startidx])
			}
		}	
	}
	
	/* Let say continue normally */
	return Plugin_Continue
}

public Action:Command_SayTeam(client, args)
{
	if (!GetConVarInt(g_hAdminSeeAll) || !client)
		return Plugin_Continue
		
	new String:text[192]
	GetCmdArgString(text, sizeof(text))
 
	new startidx = trim_quotes(text)
		
	new String:name[32]
	GetClientName(client,name,31)
	
	new senderteam = GetClientTeam(client)
	new team

	if (IsPlayerAlive(client))
	{
		//alive
		for (new i=1; i<=maxplayers; i++)
		{
			if (IsClientInGame(i))
			{
				team = GetClientTeam(i)
				if ((GetUserFlagBits(i) & ADMFLAG_CHAT) && (senderteam != team))
					PrintToChat(i,"[ADMINSEEALL]%s: %s",name,text[startidx])
			}
		}	
	}
	else
	{
		//dead	
		for (new i=1; i<=maxplayers; i++)
		{
			if (IsClientInGame(i))
			{
				team = GetClientTeam(i)
				if ((GetUserFlagBits(i) & ADMFLAG_CHAT) && (IsPlayerAlive(i) || (senderteam != team)))
					PrintToChat(i,"[ADMINSEEALL]%s: %s",name,text[startidx])
			}
		}	
		
	}
	
	/* Let say continue normally */
	return Plugin_Continue
}

public OnClientPutInServer(client)
{
	if (!GetConVarInt(g_hConnectAnnounce))
		return
	
	new String:ip[32]
	new String:country[46]
	new String:name[32]
	new String:authid[35]
	GetClientAuthId(client, AuthId_Steam2, authid, 34)
	GetClientIP(client, ip, 19)
	GetClientName(client, name,31)
	GeoipCountry(ip, country, sizeof(country))
	
	PrintToChatAll("\x01\x04%s (\x01%s\x04) connected from %s", name, authid, country)
}

/* sm_name function - originally by bl4nk. Updated to use 'ProcessTargetString' and support multiple targets */
public Action:Command_Name(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_name <user> <name>");
		return Plugin_Handled;
	}

	new String:target[64];
	GetCmdArg(1, target, sizeof(target));

	new String:name[64];
	GetCmdArg(2, name, sizeof(name));

	new targets[MAXPLAYERS];
	
	new String:buffername[2];
	new bool:bufferbool;
	
	new count = ProcessTargetString(target,
						   client, 
						   targets,
						   MAXPLAYERS,
						   0,
						   buffername,
						   1,
						   bufferbool);
	
	if (count < 1)
	{
		ReplyToTargetError(client, count);
		return Plugin_Handled;
	}
	
	for (new i = 0; i < count; i++)
	{
		NotifyPrint(client, targets[i], CommandType_Name, "\x01\x04%T", "Name", LANG_SERVER, name)
		ClientCommand(targets[i], "name \"%s\"", name)		
	}

	return Plugin_Handled
}