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
	No Clip						- sm_noclip <player/@ALL/@CT/@T> <1|0>
	Speed						- sm_speed <player/@ALL/@CT/@T> <Float speed multiplier> (eg 1.0 (normal), 2.0 (double))
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
	
	- Multilingual
	- INS Support
	- Cache ent offsets on plugin load (efficiency)
	- Swap team at round end
	
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
			- Removed Slay and Burn (basefuncommands stole them.. :( )
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

#define PLUGIN_VERSION "0.51"


//Global admin level needed for most commands
//Change ADMFLAG_CUSTOM4 to something from the above list if you wish
#define ADMIN_LEVEL ADMFLAG_CUSTOM4

//Individual Admin levels for commands
//Change the ADMIN_LEVEL to one of the above list if you want
//ADMIN_LEVEL makes it the default admin level (defined above)
#define ADMIN_BURY		ADMIN_LEVEL
#define ADMIN_RESPAWN	ADMIN_LEVEL
#define ADMIN_DISARM	ADMIN_LEVEL
#define ADMIN_HP		ADMIN_LEVEL
#define ADMIN_ARMOUR	ADMIN_LEVEL
#define ADMIN_WEAPON	ADMIN_LEVEL
#define ADMIN_GOD		ADMIN_LEVEL
#define ADMIN_GRAVITY	ADMIN_LEVEL
#define ADMIN_SPEED		ADMIN_LEVEL
#define ADMIN_NOCLIP	ADMIN_LEVEL
#define ADMIN_NV		ADMIN_LEVEL
#define ADMIN_DEFUSER	ADMIN_LEVEL
#define ADMIN_HELMET	ADMIN_LEVEL
#define ADMIN_TEAM		ADMFLAG_SLAY
#define ADMIN_EXTEND	ADMFLAG_CHANGEMAP
#define ADMIN_SHUTDOWN	ADMFLAG_RCON
#define ADMIN_SEEALL	ADMFLAG_CHAT
#define ADMIN_EXEC		ADMIN_LEVEL
#define ADMIN_TELEPORT	ADMIN_LEVEL

new Handle:g_hMpTimelimit
new Handle:g_hShowDmg
new Handle:g_hConnectAnnounce
new Handle:g_hAdminSeeAll

new Handle:hGameConf
new Handle:hRoundRespawn
new Handle:hRemoveItems
new Handle:hSwitchTeam
new Handle:hSetModel
new Handle:hChangeTeam

new Handle:coords

new Handle:thisplugin

new LifeStateOff

new maxplayers

new String:modname[30]

#define NUMMODS 4
#define CSTRIKE 0
#define DOD 1
#define HL2MP 2
#define INS 3
 
new mod
static String:teamname[NUMMODS][3][] =  
{
	{"Spectator","Terrorist","Counter-Terrorist" },
	{"Spectator","Allies","Axis" },
	{"Spectator","Combine","Rebels" },
	{"Spectator","US Marines","Insurgents"} //This might be the other way around
}

public Plugin:myinfo = 
{
	name = "SM Super Commands NO TELEPORT",
	author = "pRED*",
	description = "Assorted Fun Commands",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{	
	LoadTranslations("common.phrases")
	
	CreateConVar("sm_supercmds_version", PLUGIN_VERSION, "Super Commands Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	
	GetGameFolderName(modname, sizeof(modname));
	
	//Get mod name stuff
	if (StrEqual(modname,"cstrike",false)) mod = CSTRIKE
	else if (StrEqual(modname,"dod",false)) mod = DOD
	else if (StrEqual(modname,"hl2mp",false)) mod = HL2MP
	else if (StrEqual(modname,"Insurgency",false)) mod = INS
	
	RegAdminCmd("sm_bury", Command_Bury,ADMIN_BURY)
	RegAdminCmd("sm_unbury", Command_UnBury,ADMIN_BURY)
	RegAdminCmd("sm_respawn", Command_Respawn,ADMIN_RESPAWN)
	RegAdminCmd("sm_disarm", Command_Disarm,ADMIN_DISARM)
	RegAdminCmd("sm_hp", Command_HP,ADMIN_HP)
	RegAdminCmd("sm_armour", Command_Armour,ADMIN_ARMOUR)
	RegAdminCmd("sm_weapon", Command_Weapon,ADMIN_WEAPON)
	RegAdminCmd("sm_god", Command_God,ADMIN_GOD)
	RegAdminCmd("sm_gravity", Command_Gravity,ADMIN_GRAVITY)
	RegAdminCmd("sm_speed", Command_Speed,ADMIN_SPEED)
	RegAdminCmd("sm_noclip", Command_NoClip,ADMIN_NOCLIP)
	RegAdminCmd("sm_nv", Command_NV,ADMIN_NV)
	RegAdminCmd("sm_defuser", Command_Defuser,ADMIN_DEFUSER)
	RegAdminCmd("sm_helmet", Command_Helmet,ADMIN_HELMET)
	
	RegAdminCmd("sm_teamswap",Command_TeamSwap,ADMIN_TEAM)
	RegAdminCmd("sm_swapteam",Command_TeamSwap,ADMIN_TEAM)
	RegAdminCmd("sm_team",Command_Team,ADMIN_TEAM)
	RegAdminCmd("sm_extend",Command_Extend,ADMIN_EXTEND)
	
	RegAdminCmd("sm_shutdown",Command_Shutdown,ADMIN_SHUTDOWN)
	
	RegAdminCmd("sm_exec",Command_Exec,ADMIN_EXEC)
	//RegAdminCmd("sm_teleport",Command_Teleport,ADMIN_TELEPORT)
	//RegAdminCmd("sm_getloc",Command_Location,ADMIN_TELEPORT)
	//RegAdminCmd("sm_saveloc",Command_SaveLocation,ADMIN_TELEPORT)
	
	RegConsoleCmd("say", Command_Say)
	RegConsoleCmd("say_team", Command_SayTeam)
	LifeStateOff = FindSendPropOffs("CBasePlayer","m_lifeState")
	
	g_hMpTimelimit = FindConVar("mp_timelimit")
	g_hShowDmg = CreateConVar("sm_showdamage","1","Show Damage Done")
	g_hConnectAnnounce = CreateConVar("sm_connectannounce","1","Announce connections")
	g_hAdminSeeAll = CreateConVar("sm_adminseeall","1","Show admins all chat")
	
	hGameConf = LoadGameConfigFile("supercmds.gamedata")
	
	StartPrepSDKCall(SDKCall_Player)
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "RoundRespawn")
	hRoundRespawn = EndPrepSDKCall()
	
	StartPrepSDKCall(SDKCall_Player)
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "SwitchTeam")
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain)
	hSwitchTeam = EndPrepSDKCall()
	
	StartPrepSDKCall(SDKCall_Player)
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "SetModel")
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer)
	hSetModel = EndPrepSDKCall()
	
	StartPrepSDKCall(SDKCall_Player)
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "RemoveAllItems")
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain)
	hRemoveItems = EndPrepSDKCall()
	
	StartPrepSDKCall(SDKCall_Player)
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "ChangeTeam")
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain)
	hChangeTeam = EndPrepSDKCall()
	
	HookEvent("player_hurt", Event_PlayerHurt)
	
	thisplugin = GetMyHandle()
	
	coords = CreateArray(3)
}

public OnMapStart()
{
	maxplayers = GetMaxClients()
	
	ClearArray(coords)
}

public Action:FindPlayer(client, String:Target[], Function:func, other)
{
	new num=trim_quotes(Target)
	new letter = Target[num+1]
	
	if (Target[num]=='@')
	{
		//assume it is either @ALL, @CT or @T
		for (new i=1; i<=maxplayers; i++)
		{
			if (!IsClientInGame(i))
				continue
				
			if (letter=='C') //assume @CT
			{
				if (GetClientTeam(i)==3)
				{
					Call_StartFunction(thisplugin, func)
					Call_PushCell(i)
					Call_PushCell(other)
					Call_Finish()
				}
			}
			else if (letter=='T') //assume @T
			{
				if (GetClientTeam(i)==2)
				{
					Call_StartFunction(thisplugin, func)
					Call_PushCell(i)
					Call_PushCell(other)
					Call_Finish()
				}
					
			}
			else //assume @ALL
			{
				Call_StartFunction(thisplugin, func)
				Call_PushCell(i)
				Call_PushCell(other)
				Call_Finish()
			}
		}
		
		return Plugin_Handled
	}
	
	new targetclient = FindClient(client,Target)

	if (targetclient == -1)
		return Plugin_Handled
	
	Call_StartFunction(thisplugin, func)
	Call_PushCell(targetclient)
	Call_PushCell(other)
	Call_Finish()
	
	return Plugin_Handled
}

public FindClient(client,String:Target[])
{
	new iClients[2];
	new iNumClients = SearchForClients(Target, iClients, 2);
	
	if (iNumClients == 0)
	{
		ReplyToCommand(client, "[SM] %t", "No matching client");
		return -1
	}
	else if (iNumClients > 1)
	{
		ReplyToCommand(client, "[SM] %t", "More than one client matches", Target);
		return -1
	}
	else if (!CanUserTarget(client, iClients[0]))
	{
		ReplyToCommand(client, "[SM] %t", "Unable to target");
		return -1
	}
	
	return iClients[0]
}

public ExecSpeed(client, any:speed)
{
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", Float:speed)
	PrintToChat(client,"\x01\x04You have been given %2.1ftimes normal speed", speed)
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
	
	return FindPlayer(client, Target, ExecSpeed, any:speed)
}

public ExecLocation(client,target,Float:origin[3])
{
	new String:name[30]
	GetClientName(target,name,sizeof(name))
	PrintToChat(client,"\x01\x04The location of %s is %2.1f,%2.1f,%2.1f", name, origin[0], origin[1], origin[2])
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
				
		new targetclient = FindClient(client,Target[num])
		
		if (targetclient == -1)
			return Plugin_Handled;
			
		GetEntPropVector(targetclient, Prop_Send, "m_vecOrigin", origin)
		
		ExecLocation(client,targetclient,origin)	
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
	PrintToChat(client,"\x01\x04Your Location has been saved as number %i. Use sm_teleport <name/#userid> <#%i> to use it", GetArraySize(coords), GetArraySize(coords))
	
	return Plugin_Handled;
}

public ExecTeleport(client,Float:origin[3])
{
	TeleportEntity(client, origin, NULL_VECTOR, NULL_VECTOR)
	PrintToChat(client,"\x01\x04You have been teleported to %f,%f,%f", origin[0],origin[1],origin[2])
}

public Action:Command_Teleport(client,args)
{
	if (args != 4 && args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_teleport <name or #userid> <x> <y> <z>");
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
	new letter = Target[num+1]
	
	if (Target[num]=='@')
	{
		//assume it is either @ALL, @CT or @T
		for (new i=1; i<=maxplayers; i++)
		{
			if (!IsClientInGame(i))
				continue
				
			if (letter=='C') //assume @CT
			{
				if (GetClientTeam(i)==3)
				{
					ExecTeleport(i,origin)
				}
			}
			else if (letter=='T') //assume @T
			{
				if (GetClientTeam(i)==2)
				{
					ExecTeleport(i,origin)
				}
					
			}
			else //assume @ALL
			{
				ExecTeleport(i,origin)
			}
		}
		
		return Plugin_Handled
	}
			
	new targetclient = FindClient(client,Target[num])
	
	if (targetclient == -1)
		return Plugin_Handled;
	
	ExecTeleport(targetclient,origin)
	
	return Plugin_Handled;	
}

public ExecClient(client,String:Command[])
{
	ClientCommand(client,Command)
	PrintToChat(client,"\x01\x04You have had a command executed upon you")
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
	new letter = Target[num+1]
	
	if (Target[num]=='@')
	{
		//assume it is either @ALL, @CT or @T
		for (new i=1; i<=maxplayers; i++)
		{
			if (!IsClientInGame(i))
				continue
				
			if (letter=='C') //assume @CT
			{
				if (GetClientTeam(i)==3)
				{
					ExecClient(i,buffer[start])
				}
			}
			else if (letter=='T') //assume @T
			{
				if (GetClientTeam(i)==2)
				{
					ExecClient(i,buffer[start])
				}
					
			}
			else //assume @ALL
			{
				ExecClient(i,buffer[start])
			}
		}
		
		return Plugin_Handled
	}
			
	new targetclient = FindClient(client,Target)
	
	if (targetclient == -1)
		return Plugin_Handled;
	
	ExecClient(targetclient,buffer[start])
	
	return Plugin_Handled;	
}

public ExecGravity(client, any:gravity)
{
	SetEntPropFloat(client, Prop_Data, "m_flGravity", gravity)
	PrintToChat(client,"\x01\x04You have been given %2.1ftimes normal gravity", gravity)
}

public Action:Command_Gravity(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_gravity <name or #userid> <Float grav mult>");
		return Plugin_Handled;	
	}	
	
	new String:Target[64],String:hp[10]
	GetCmdArg(1, Target, sizeof(Target))
	GetCmdArg(2, hp, sizeof(hp))

	new Float:gravity = StringToFloat(hp)
	
	return FindPlayer(client, Target, ExecGravity, any:gravity)
}

public ExecGod(client, any:status)
{
	if (status)
	{
		SetEntProp(client, Prop_Data, "m_takedamage", 0, 1)
		PrintToChat(client,"\x01\x04You have been given god mode")
	}
	else
	{
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1)
		PrintToChat(client,"\x01\x04You have had god mode removed")
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
	
	return FindPlayer(client, Target, ExecGod, any:status)
}

public ExecNoClip(client, any:status)
{
	if (status)
	{
		SetEntProp(client, Prop_Send, "movetype", 8, 1)
		PrintToChat(client,"\x01\x04You have been given noclip")
	}
	else
	{
		SetEntProp(client, Prop_Send, "movetype", 2, 1)
		PrintToChat(client,"\x01\x04You have had noclip removed")
	}
}

public Action:Command_NoClip(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_noclip <name or #userid> <1|0>");
		return Plugin_Handled;	
	}	
	
	new String:Target[64],String:on[10]
	GetCmdArg(1, Target, sizeof(Target))
	GetCmdArg(2, on, sizeof(on))

	new status = StringToInt(on)
	
	return FindPlayer(client, Target, ExecNoClip, any:status)
}

public ExecNV(client, any:status)
{
	if (status)
	{
		SetEntProp(client, Prop_Send, "m_bHasNightVision", 1, 1)
		PrintToChat(client,"\x01\x04You have been given nightvision goggles")
	}
	else
	{
		SetEntProp(client, Prop_Send, "m_bHasNightVision", 0, 1)
		PrintToChat(client,"\x01\x04You have had your nightvision goggles removed")
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
	
	return FindPlayer(client, Target, ExecNV, any:status)
}

public ExecDefuser(client, any:status)
{
	if (status)
	{
		SetEntProp(client, Prop_Send, "m_bHasDefuser", 1, 1)
		PrintToChat(client,"\x01\x04You have been given a defuse kit")
	}
	else
	{
		SetEntProp(client, Prop_Send, "m_bHasDefuser", 0, 1)
		PrintToChat(client,"\x01\x04You have had your defuse kit removed")
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
	
	return FindPlayer(client, Target, ExecDefuser, any:status)
}

public ExecHelmet(client, any:status)
{
	if (status)
	{
		SetEntProp(client, Prop_Send, "m_bHasHelmet", 1, 1)
		PrintToChat(client,"\x01\x04You have been given a helmet")
	}
	else
	{
		SetEntProp(client, Prop_Send, "m_bHasHelmet", 0, 1)
		PrintToChat(client,"\x01\x04You have had your helmet removed")
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
	
	return FindPlayer(client, Target, ExecHelmet, any:status)
}

public ExecTeam(client, any:teamid)
{
	if (mod == CSTRIKE)
	{
		if (teamid == 1)
		{
			ForcePlayerSuicide(client)
			SDKCall(hChangeTeam,client,teamid)
		}
		else
		{
			SDKCall(hSwitchTeam,client,teamid)
			set_random_model(client,teamid)
		}
	}
	else
		ChangeClientTeam(client, teamid)
		
	PrintToChat(client,"\x01\x04You have been moved to the %s team", teamname[mod][teamid-1])
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
	
	PrintToChatAll("\x01\x04The Map has Been extended for %i minutes",inttime)
	
	return Plugin_Handled;	
}

public Action:Command_TeamSwap(client, args)
{
	new team
	new i
	
	if ( args == 0 )
	{
		for(i = 1; i <= maxplayers; i++)
		{
			if (IsClientInGame(i))
			{
				team = GetClientTeam(i)
				if (team==2)
				{
					if (mod == CSTRIKE)
					{
						SDKCall(hSwitchTeam,i,3)
						set_random_model(i,3)
					}
					else
						ChangeClientTeam(i, 3)
				}
				else if (team==3)
				{
					if (mod == CSTRIKE)
					{
						SDKCall(hSwitchTeam,i,2)
						set_random_model(i,2)
					}
					else
						ChangeClientTeam(i, 2)
				}
			}
		}
		PrintToChatAll("\x01\x04The teams have been swapped")
	}
	else if ( args >= 1)
	{

		new String:Target[64]
		for (i =1 ; i<=args; i++) 
		{
			GetCmdArg(i, Target, sizeof(Target))
			
			new iClient = FindClient(client,Target)
			
			if (iClient == -1)
				continue
		
			if (IsClientInGame(iClient))
			{
				team = GetClientTeam(iClient)
				if (team==2)
				{
					if (mod == CSTRIKE)
					{
						SDKCall(hSwitchTeam,iClient,3)
						set_random_model(iClient,3)
					}
					else
					ChangeClientTeam(iClient, 3)
				}
				else if (team==3)
				{
					if (mod == CSTRIKE)
					{
						SDKCall(hSwitchTeam,iClient,2)
						set_random_model(iClient,2)
					}
					else
						ChangeClientTeam(iClient, 2)
				}
			}
		}
	}
	
	return Plugin_Handled;	
}

public Action:Command_Shutdown(client, args)
{
	PrintToChatAll("\x01\x04The Server is now shutting down")
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

	new num=trim_quotes(Target)
	new letter = Target[num+1]
	
	if (Target[num]=='@')
	{
		//assume it is either @ALL, @CT or @T
		for (new i=1; i<=maxplayers; i++)
		{
			if (!IsClientInGame(i))
				continue
				
			if (letter=='C') //assume @CT
			{
				if (GetClientTeam(i)==3)
				{
					new ent = GivePlayerItem(i, weapon)
	
					if (ent == -1)
						ReplyToCommand(client, "[SM] Invalid Item")
					else
						PrintToChat(i,"\x01\x04You have been given %s",weapon)
				}
			}
			else if (letter=='T') //assume @T
			{
				if (GetClientTeam(i)==2)
				{
					new ent = GivePlayerItem(i, weapon)
	
					if (ent == -1)
						ReplyToCommand(client, "[SM] Invalid Item")
					else
						PrintToChat(i,"\x01\x04You have been given %s",weapon)
				}
					
			}
			else //assume @ALL
			{
				new ent = GivePlayerItem(i, weapon)

				if (ent == -1)
					ReplyToCommand(client, "[SM] Invalid Item")
				else
					PrintToChat(i,"\x01\x04You have been given %s",weapon)
			}
		}
		
		return Plugin_Handled
	}
			
	new targetclient = FindClient(client,Target)
	
	if (targetclient == -1)
		return Plugin_Handled;
	
	new ent = GivePlayerItem(targetclient, weapon)
	
	if (ent == -1)
		ReplyToCommand(client, "[SM] Invalid Item")
	else
		PrintToChat(targetclient,"\x01\x04You have been given %s",weapon)
	
	return Plugin_Handled;	
}

public ExecHP(client, any:health)
{
	SetEntProp(client, Prop_Send, "m_iHealth", health, 1)
	SetEntProp(client, Prop_Data, "m_iHealth", health, 1)
	PrintToChat(client,"\x01\x04You have had your health set to: %i",health)
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
	
	return FindPlayer(client, Target, ExecHP, any:health)
}

public ExecArmour(client, any:armour)
{
	SetEntProp(client, Prop_Send, "m_ArmorValue", armour, 1)
	PrintToChat(client,"\x01\x04You have had your armour set to: %i",armour)
}

public Action:Command_Armour(client, args)
{
	if (mod != CSTRIKE)
	{
		ReplyToCommand(client, "[SM] That Command is not supported on this mod (Cstrike only)");
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
	
	return FindPlayer(client, Target, ExecArmour, any:armour)
}

public ExecBury(client, any:bury)
{
	new Float:vec[3]
	
	if (!bury)
	{
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", vec)

		vec[2]=vec[2]+30.0
		SetEntPropVector(client, Prop_Send, "m_vecOrigin", vec)

		PrintToChat(client,"\x01\x04You have been unburied")	
	}
	else
	{
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", vec)
		vec[2]=vec[2]-30.0
		SetEntPropVector(client, Prop_Send, "m_vecOrigin", vec)
		PrintToChat(client,"\x01\x04You have been buried")		
	}
}

public Action:Command_Bury(client, args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_bury <name or #userid>");
		return Plugin_Handled;	
	}	
	
	new String:Target[64]
	GetCmdArg(1, Target, sizeof(Target))
	
	return FindPlayer(client, Target, ExecBury, 1)
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

public ExecRespawn(client, any:blank)
{
	SDKCall(hRoundRespawn, client)
	PrintToChat(client,"\x01\x04You have been respawned")	
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

public ExecDisarm(client, any:blank)
{
	SDKCall(hRemoveItems, client,false)
	PrintToChat(client,"\x01\x04You have been disarmed")		
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
	
	return FindPlayer(client, Target, ExecDisarm, 0)
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

static const String:ctmodels[4][] = {"models/player/ct_urban.mdl","models/player/ct_gsg9.mdl","models/player/ct_sas.mdl","models/player/ct_gign.mdl"}
static const String:tmodels[4][] = {"models/player/t_phoenix.mdl","models/player/t_leet.mdl","models/player/t_arctic.mdl","models/player/t_guerilla.mdl"}

stock set_random_model(client,team)
{
	new random=GetRandomInt(0, 3)
	
	if (team==2) //t!
	{
		SDKCall(hSetModel,client,tmodels[random])
	}
	else if (team==3) //ct	
	{
		SDKCall(hSetModel,client,ctmodels[random])
	}
	
}

public Action:Command_Say(client, args)
{
	if (!GetConVarInt(g_hAdminSeeAll))
		return Plugin_Continue
	
	new String:text[192]
	GetCmdArgString(text, sizeof(text))
 
	new startidx = trim_quotes(text)
	
	new AdminFlag:flag
	BitToFlag(ADMIN_SEEALL, flag)
	new AdminId:aid
		
	new String:name[32]
	GetClientName(client,name,31)

	//need to send message to admin if sender is dead
	if (GetEntData(client, LifeStateOff, 1) != 0)
	{
		//dead
		for (new i=1; i<=maxplayers; i++)
		{
			if (IsClientInGame(i))
			{
				aid = GetUserAdmin(i)
				if (GetAdminFlag(aid, flag, Access_Effective) && (GetEntData(client, LifeStateOff, 1) == 0))
					PrintToChat(i,"[ADMINSEEALL]%s: %s",name,text[startidx])
			}
		}	
	}
	
	/* Let say continue normally */
	return Plugin_Continue
}

public Action:Command_SayTeam(client, args)
{
	if (!GetConVarInt(g_hAdminSeeAll))
		return Plugin_Continue
		
	new String:text[192]
	GetCmdArgString(text, sizeof(text))
 
	new startidx = trim_quotes(text)
	
	new AdminFlag:flag
	BitToFlag(ADMIN_SEEALL, flag)
	new AdminId:aid
		
	new String:name[32]
	GetClientName(client,name,31)
	
	new senderteam = GetClientTeam(client)
	new team

	if (GetEntData(client, LifeStateOff, 1) == 0)
	{
		//alive
		for (new i=1; i<=maxplayers; i++)
		{
			if (IsClientInGame(i))
			{
				aid = GetUserAdmin(i)
				team = GetClientTeam(i)
				if (GetAdminFlag(aid, flag, Access_Effective) && (senderteam != team))
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
				aid = GetUserAdmin(i)
				team = GetClientTeam(i)
				if (GetAdminFlag(aid, flag, Access_Effective) && ((GetEntData(client, LifeStateOff, 1) == 0) || (senderteam != team)))
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
	GetClientAuthString(client,authid,34)
	GetClientIP(client, ip, 19)
	GetClientName(client, name,31)
	GeoipCountry(ip, country, sizeof(country))
	
	PrintToChatAll("\x01\x04%s (\x01%s\x04) connected from %s",name,authid,country)
}