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
	Igniting Players			- sm_burn <player/@ALL/@CT/@T> <seconds>
	Give item (weapons etc)		- sm_weapon <player/@ALL/@CT/@T> <itemname> (eg weapon_ak47)
	Teamswap					- sm_teamswap / sm_swapteam
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
	Slay						- sm_slay <player/@ALL/@CT/@T>
	Shutdown					- sm_shutdown (forces players to retry as well, usefull if server auto restarts)
	Connect Announce			- Cvar: sm_connectannounce <1|0>
	Admin See All				- Cvar: sm_adminseeall <1|0>
								
	Things To Do:
	
	- Multilinugal
	- More Commands!
	
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

#define PLUGIN_VERSION "0.31"


//Global admin level needed for most commands
//Change ADMFLAG_CUSTOM4 to something from the above list if you wish
#define ADMIN_LEVEL ADMFLAG_CUSTOM4

//Individual Admin levels for commands
//Change the ADMIN_LEVEL to one of the above list if you want
//ADMIN_LEVEL makes it the default admin level (defined above)
#define ADMIN_BURY		ADMIN_LEVEL
#define ADMIN_SLAY		ADMIN_LEVEL
#define ADMIN_RESPAWN	ADMIN_LEVEL
#define ADMIN_DISARM	ADMIN_LEVEL
#define ADMIN_BURN		ADMIN_LEVEL
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

new Handle:g_hMpTimelimit
new Handle:g_hShowDmg
new Handle:g_hConnectAnnounce
new Handle:g_hAdminSeeAll

new Handle:hGameConf
new Handle:hRoundRespawn
new Handle:hRemoveItems
new Handle:hSwitchTeam
new Handle:hSetModel
new Handle:hCommitSuicide

new LifeStateOff

new maxplayers

static String:teamname[3][] = { "Spectator","Terrorist","Counter-Terrorist"}

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
	LoadTranslations("common.phrases")
	
	CreateConVar("sm_supercmds_version", PLUGIN_VERSION, "Super Commands Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	
	RegAdminCmd("sm_bury", Command_Bury,ADMIN_BURY)
	RegAdminCmd("sm_unbury", Command_UnBury,ADMIN_BURY)
	RegAdminCmd("sm_burn", Command_Burn,ADMIN_BURN)
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
	
	RegAdminCmd("sm_extend",Command_Extend,ADMIN_EXTEND)
	
	RegAdminCmd("sm_shutdown",Command_Shutdown,ADMIN_SHUTDOWN)
	
	RegConsoleCmd("say", Command_Say)
	RegConsoleCmd("say_team", Command_SayTeam)
	LifeStateOff = FindSendPropOffs("CBasePlayer","m_lifeState")
	
	g_hMpTimelimit = FindConVar("mp_timelimit")
	g_hShowDmg = CreateConVar("sm_showdamage","1","Show Damage Done")
	g_hConnectAnnounce = CreateConVar("sm_connectannounce","1","Announce connections")
	g_hAdminSeeAll = CreateConVar("sm_adminseeall","1","Show admins all chat")
	
	

	maxplayers = GetMaxClients()

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
					SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", speed)
					PrintToChat(i,"\x01\x04You have been given %2.1ftimes normal speed", speed)
				}
			}
			else if (letter=='T') //assume @T
			{
				if (GetClientTeam(i)==2)
				{
					SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", speed)
					PrintToChat(i,"\x01\x04You have been given %2.1ftimes normal speed", speed)
				}
					
			}
			else //assume @ALL
			{
				SetEntPropFloat(i, Prop_Data, "m_flLaggedMovementValue", speed)
				PrintToChat(i,"\x01\x04You have been given %2.1ftimes normal speed", speed)
			}
		}
		
		return Plugin_Handled
	}
	
	
	new iClients[2];
	new iNumClients = SearchForClients(Target, iClients, 2);
	
	if (iNumClients == 0)
	{
		ReplyToCommand(client, "[SM] %t", "No matching client");
		return Plugin_Handled;
	}
	else if (iNumClients > 1)
	{
		ReplyToCommand(client, "[SM] %t", "More than one client matches", Target);
		return Plugin_Handled;
	}
	else if (!CanUserTarget(client, iClients[0]))
	{
		ReplyToCommand(client, "[SM] %t", "Unable to target");
		return Plugin_Handled;
	}
	
	SetEntPropFloat(iClients[0], Prop_Data, "m_flLaggedMovementValue", speed)
	
	PrintToChat(iClients[0],"\x01\x04You have been given %2.1ftimes normal speed", speed)
	
	return Plugin_Handled;	
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
					SetEntPropFloat(i, Prop_Data, "m_flGravity", gravity)
					PrintToChat(i,"\x01\x04You have been given %2.1ftimes normal gravity", gravity)
				}
			}
			else if (letter=='T') //assume @T
			{
				if (GetClientTeam(i)==2)
				{
					SetEntPropFloat(i, Prop_Data, "m_flGravity", gravity)
					PrintToChat(i,"\x01\x04You have been given %2.1ftimes normal gravity", gravity)
				}
					
			}
			else //assume @ALL
			{
				SetEntPropFloat(i, Prop_Data, "m_flGravity", gravity)
				PrintToChat(i,"\x01\x04You have been given %2.1ftimes normal gravity", gravity)
			}
		}
		
		return Plugin_Handled
	}
	
	new iClients[2];
	new iNumClients = SearchForClients(Target, iClients, 2);
	
	if (iNumClients == 0)
	{
		ReplyToCommand(client, "[SM] %t", "No matching client");
		return Plugin_Handled;
	}
	else if (iNumClients > 1)
	{
		ReplyToCommand(client, "[SM] %t", "More than one client matches", Target);
		return Plugin_Handled;
	}
	else if (!CanUserTarget(client, iClients[0]))
	{
		ReplyToCommand(client, "[SM] %t", "Unable to target");
		return Plugin_Handled;
	}
	
	SetEntPropFloat(iClients[0], Prop_Data, "m_flGravity", gravity)
	PrintToChat(iClients[0],"\x01\x04You have been given %2.1ftimes normal gravity", gravity)
	
	return Plugin_Handled;	
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
					if (status)
					{
						SetEntProp(i, Prop_Data, "m_takedamage", 0, 1)
						PrintToChat(i,"\x01\x04You have been given god mode")
					}
					else
					{
						SetEntProp(i, Prop_Data, "m_takedamage", 2, 1)
						PrintToChat(i,"\x01\x04You have had god mode removed")
					}
				}
			}
			else if (letter=='T') //assume @T
			{
				if (GetClientTeam(i)==2)
				{
					if (status)
					{
						SetEntProp(i, Prop_Data, "m_takedamage", 0, 1)
						PrintToChat(i,"\x01\x04You have been given god mode")
					}
					else
					{
						SetEntProp(i, Prop_Data, "m_takedamage", 2, 1)
						PrintToChat(i,"\x01\x04You have had god mode removed")
					}
				}
					
			}
			else //assume @ALL
			{
				if (status)
				{
					SetEntProp(i, Prop_Data, "m_takedamage", 0, 1)
					PrintToChat(i,"\x01\x04You have been given god mode")
				}
				else
				{
					SetEntProp(i, Prop_Data, "m_takedamage", 2, 1)
					PrintToChat(i,"\x01\x04You have had god mode removed")
				}
			}
		}
		
		return Plugin_Handled
	}
	
		
	new iClients[2];
	new iNumClients = SearchForClients(Target, iClients, 2);
	
	if (iNumClients == 0)
	{
		ReplyToCommand(client, "[SM] %t", "No matching client");
		return Plugin_Handled;
	}
	else if (iNumClients > 1)
	{
		ReplyToCommand(client, "[SM] %t", "More than one client matches", Target);
		return Plugin_Handled;
	}
	else if (!CanUserTarget(client, iClients[0]))
	{
		ReplyToCommand(client, "[SM] %t", "Unable to target");
		return Plugin_Handled;
	}
	
	if (status)
	{
		SetEntProp(iClients[0], Prop_Data, "m_takedamage", 0, 1)
		PrintToChat(iClients[0],"\x01\x04You have been given god mode")
	}
	else
	{
		SetEntProp(iClients[0], Prop_Data, "m_takedamage", 2, 1)
		PrintToChat(iClients[0],"\x01\x04You have had god mode removed")
	}
	

	return Plugin_Handled;	
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
					if (status)
					{
						SetEntProp(i, Prop_Send, "movetype", 8, 1)
						PrintToChat(i,"\x01\x04You have been given noclip")
					}
					else
					{
						SetEntProp(i, Prop_Send, "movetype", 1, 1)
						PrintToChat(i,"\x01\x04You have had noclip removed")
					}
				}
			}
			else if (letter=='T') //assume @T
			{
				if (GetClientTeam(i)==2)
				{
					if (status)
					{
						SetEntProp(i, Prop_Send, "movetype", 8, 1)
						PrintToChat(i,"\x01\x04You have been given noclip")
					}
					else
					{
						SetEntProp(i, Prop_Send, "movetype", 1, 1)
						PrintToChat(i,"\x01\x04You have had noclip removed")
					}
				}
					
			}
			else //assume @ALL
			{
				if (status)
				{
					SetEntProp(i, Prop_Send, "movetype", 8, 1)
					PrintToChat(i,"\x01\x04You have been given noclip")
				}
				else
				{
					SetEntProp(i, Prop_Send, "movetype", 1, 1)
					PrintToChat(i,"\x01\x04You have had noclip removed")
				}
			}
		}
		
		return Plugin_Handled
	}
	
	new iClients[2];
	new iNumClients = SearchForClients(Target, iClients, 2);
	
	if (iNumClients == 0)
	{
		ReplyToCommand(client, "[SM] %t", "No matching client");
		return Plugin_Handled;
	}
	else if (iNumClients > 1)
	{
		ReplyToCommand(client, "[SM] %t", "More than one client matches", Target);
		return Plugin_Handled;
	}
	else if (!CanUserTarget(client, iClients[0]))
	{
		ReplyToCommand(client, "[SM] %t", "Unable to target");
		return Plugin_Handled;
	}
	
	if (status)
	{
		SetEntProp(iClients[0], Prop_Send, "movetype", 8, 1)
		PrintToChat(iClients[0],"\x01\x04You have been given noclip")
	}
	else
	{
		SetEntProp(iClients[0], Prop_Send, "movetype", 1, 1)
		PrintToChat(iClients[0],"\x01\x04You have had noclip removed")
	}
	

	return Plugin_Handled;	
}

public Action:Command_NV(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_nv <name or #userid> <1|0>");
		return Plugin_Handled;	
	}	
	
	new String:Target[64],String:on[10]
	GetCmdArg(1, Target, sizeof(Target))
	GetCmdArg(2, on, sizeof(on))
	
	new status = StringToInt(on)
	
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
					if (status)
					{
						SetEntProp(i, Prop_Send, "m_bHasNightVision", 1, 1)
						PrintToChat(i,"\x01\x04You have been given nightvision goggles")
					}
					else
					{
						SetEntProp(i, Prop_Send, "m_bHasNightVision", 0, 1)
						PrintToChat(i,"\x01\x04You have had your nightvision goggles removed")
					}
				}
			}
			else if (letter=='T') //assume @T
			{
				if (GetClientTeam(i)==2)
				{
					if (status)
					{
						SetEntProp(i, Prop_Send, "m_bHasNightVision", 1, 1)
						PrintToChat(i,"\x01\x04You have been given nightvision goggles")
					}
					else
					{
						SetEntProp(i, Prop_Send, "m_bHasNightVision", 0, 1)
						PrintToChat(i,"\x01\x04You have had your nightvision goggles removed")
					}
				}
					
			}
			else //assume @ALL
			{
				if (status)
				{
					SetEntProp(i, Prop_Send, "m_bHasNightVision", 1, 1)
					PrintToChat(i,"\x01\x04You have been given nightvision goggles")
				}
				else
				{
					SetEntProp(i, Prop_Send, "m_bHasNightVision", 0, 1)
					PrintToChat(i,"\x01\x04You have had your nightvision goggles removed")
				}
			}
		}
		
		return Plugin_Handled
	}
		
	new iClients[2];
	new iNumClients = SearchForClients(Target, iClients, 2);
	
	if (iNumClients == 0)
	{
		ReplyToCommand(client, "[SM] %t", "No matching client");
		return Plugin_Handled;
	}
	else if (iNumClients > 1)
	{
		ReplyToCommand(client, "[SM] %t", "More than one client matches", Target);
		return Plugin_Handled;
	}
	else if (!CanUserTarget(client, iClients[0]))
	{
		ReplyToCommand(client, "[SM] %t", "Unable to target");
		return Plugin_Handled;
	}
	
	if (status)
	{
		SetEntProp(iClients[0], Prop_Send, "m_bHasNightVision", 1, 1)
		PrintToChat(iClients[0],"\x01\x04You have been given nightvision goggles")
	}
	else
	{
		SetEntProp(iClients[0], Prop_Send, "m_bHasNightVision", 0, 1)
		PrintToChat(iClients[0],"\x01\x04You have had your nightvision goggles removed")
	}
	

	return Plugin_Handled;	
}

public Action:Command_Defuser(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_defuser <name or #userid> <1|0>");
		return Plugin_Handled;	
	}	
	
	new String:Target[64],String:on[10]
	GetCmdArg(1, Target, sizeof(Target))
	GetCmdArg(2, on, sizeof(on))

	new status = StringToInt(on)
	
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
					if (status)
					{
						SetEntProp(i, Prop_Send, "m_bHasDefuser", 1, 1)
						PrintToChat(i,"\x01\x04You have been given a defuse kit")
					}
					else
					{
						SetEntProp(i, Prop_Send, "m_bHasDefuser", 0, 1)
						PrintToChat(i,"\x01\x04You have had your defuse kit removed")
					}
				}
			}
			else if (letter=='T') //assume @T
			{
				if (GetClientTeam(i)==2)
				{
					if (status)
					{
						SetEntProp(i, Prop_Send, "m_bHasDefuser", 1, 1)
						PrintToChat(i,"\x01\x04You have been given a defuse kit")
					}
					else
					{
						SetEntProp(i, Prop_Send, "m_bHasDefuser", 0, 1)
						PrintToChat(i,"\x01\x04You have had your defuse kit removed")
					}
				}
					
			}
			else //assume @ALL
			{
				if (status)
				{
					SetEntProp(i, Prop_Send, "m_bHasDefuser", 1, 1)
					PrintToChat(i,"\x01\x04You have been given a defuse kit")
				}
				else
				{
					SetEntProp(i, Prop_Send, "m_bHasDefuser", 0, 1)
					PrintToChat(i,"\x01\x04You have had your defuse kit removed")
				}
			}
		}
		
		return Plugin_Handled
	}
		
	new iClients[2];
	new iNumClients = SearchForClients(Target, iClients, 2);
	
	if (iNumClients == 0)
	{
		ReplyToCommand(client, "[SM] %t", "No matching client");
		return Plugin_Handled;
	}
	else if (iNumClients > 1)
	{
		ReplyToCommand(client, "[SM] %t", "More than one client matches", Target);
		return Plugin_Handled;
	}
	else if (!CanUserTarget(client, iClients[0]))
	{
		ReplyToCommand(client, "[SM] %t", "Unable to target");
		return Plugin_Handled;
	}
	
	if (status)
	{
		SetEntProp(iClients[0], Prop_Send, "m_bHasDefuser", 1, 1)
		PrintToChat(iClients[0],"\x01\x04You have been given a defuse kit")
	}
	else
	{
		SetEntProp(iClients[0], Prop_Send, "m_bHasDefuser", 0, 1)
		PrintToChat(iClients[0],"\x01\x04You have had your defuse kit removed")
	}

	return Plugin_Handled;	
}

public Action:Command_Helmet(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_helmet <name or #userid> <1|0>");
		return Plugin_Handled;	
	}	
	
	new String:Target[64],String:on[10]
	GetCmdArg(1, Target, sizeof(Target))
	GetCmdArg(2, on, sizeof(on))
	
	new status = StringToInt(on)
	
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
					if (status)
					{
						SetEntProp(i, Prop_Send, "m_bHasHelmet", 1, 1)
						PrintToChat(i,"\x01\x04You have been given a helmet")
					}
					else
					{
						SetEntProp(i, Prop_Send, "m_bHasHelmet", 0, 1)
						PrintToChat(i,"\x01\x04You have had your helmet removed")
					}
				}
			}
			else if (letter=='T') //assume @T
			{
				if (GetClientTeam(i)==2)
				{
					if (status)
					{
						SetEntProp(i, Prop_Send, "m_bHasHelmet", 1, 1)
						PrintToChat(i,"\x01\x04You have been given a helmet")
					}
					else
					{
						SetEntProp(i, Prop_Send, "m_bHasHelmet", 0, 1)
						PrintToChat(i,"\x01\x04You have had your helmet removed")
					}
				}
					
			}
			else //assume @ALL
			{
				if (status)
				{
					SetEntProp(i, Prop_Send, "m_bHasHelmet", 1, 1)
					PrintToChat(i,"\x01\x04You have been given a helmet")
				}
				else
				{
					SetEntProp(i, Prop_Send, "m_bHasHelmet", 0, 1)
					PrintToChat(i,"\x01\x04You have had your helmet removed")
				}
			}
		}
		
		return Plugin_Handled
	}
		
	new iClients[2];
	new iNumClients = SearchForClients(Target, iClients, 2);
	
	if (iNumClients == 0)
	{
		ReplyToCommand(client, "[SM] %t", "No matching client");
		return Plugin_Handled;
	}
	else if (iNumClients > 1)
	{
		ReplyToCommand(client, "[SM] %t", "More than one client matches", Target);
		return Plugin_Handled;
	}
	else if (!CanUserTarget(client, iClients[0]))
	{
		ReplyToCommand(client, "[SM] %t", "Unable to target");
		return Plugin_Handled;
	}
	
	if (status)
	{
		SetEntProp(iClients[0], Prop_Send, "m_bHasHelmet", 1, 1)
		PrintToChat(iClients[0],"\x01\x04You have been given a helmet")
	}
	else
	{
		SetEntProp(iClients[0], Prop_Send, "m_bHasHelmet", 0, 1)
		PrintToChat(iClients[0],"\x01\x04You have had your helmet removed")
	}
	
	return Plugin_Handled;	
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
					SDKCall(hSwitchTeam,i,teamid)
					set_random_model(i,teamid)
					PrintToChat(i,"\x01\x04You have been moved to the %s team", teamname[teamid-1])
				}
			}
			else if (letter=='T') //assume @T
			{
				if (GetClientTeam(i)==2)
				{
					SDKCall(hSwitchTeam,i,teamid)
					set_random_model(i,teamid)
					PrintToChat(i,"\x01\x04You have been moved to the %s team", teamname[teamid-1])
				}
					
			}
			else //assume @ALL
			{
				SDKCall(hSwitchTeam,i,teamid)
				set_random_model(i,teamid)
				PrintToChat(i,"\x01\x04You have been moved to the %s team", teamname[teamid-1])
			}
		}
		
		return Plugin_Handled
	}
		
	new iClients[2];
	new iNumClients = SearchForClients(Target, iClients, 2);
	
	if (iNumClients == 0)
	{
		ReplyToCommand(client, "[SM] %t", "No matching client");
		return Plugin_Handled;
	}
	else if (iNumClients > 1)
	{
		ReplyToCommand(client, "[SM] %t", "More than one client matches", Target);
		return Plugin_Handled;
	}
	else if (!CanUserTarget(client, iClients[0]))
	{
		ReplyToCommand(client, "[SM] %t", "Unable to target");
		return Plugin_Handled;
	}

	SDKCall(hSwitchTeam,iClients[0],teamid)
	set_random_model(iClients[0],teamid)

	PrintToChat(iClients[0],"\x01\x04You have been moved to the %s team", teamname[teamid-1])

	
	return Plugin_Handled;	
}

public Action:Command_Extend(client, args)
{
	if (args < 2)
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
	new num = GetMaxClients()
	new team
	
	for(new i = 1; i <= num; i++)
	{
		if (IsClientInGame(i))
		{
			team = GetClientTeam(i)
			if (team==2)
			{
				SDKCall(hSwitchTeam,i,3)
				set_random_model(i,3)
			}
			else if (team==3)
			{
				SDKCall(hSwitchTeam,i,2)
				set_random_model(i,2)
			}
		}
	}
	
	PrintToChatAll("\x01\x04The teams have been swapped")
	
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
		ReplyToCommand(client, "[SM] Usage: sm_weapon <name or #userid> <weapon #>");
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
			
	new iClients[2];
	new iNumClients = SearchForClients(Target, iClients, 2);
	
	if (iNumClients == 0)
	{
		ReplyToCommand(client, "[SM] %t", "No matching client");
		return Plugin_Handled;
	}
	else if (iNumClients > 1)
	{
		ReplyToCommand(client, "[SM] %t", "More than one client matches", Target);
		return Plugin_Handled;
	}
	else if (!CanUserTarget(client, iClients[0]))
	{
		ReplyToCommand(client, "[SM] %t", "Unable to target");
		return Plugin_Handled;
	}
	
	new ent = GivePlayerItem(iClients[0], weapon)
	
	if (ent == -1)
		ReplyToCommand(client, "[SM] Invalid Item")
	else
		PrintToChat(iClients[0],"\x01\x04You have been given %s",weapon)
	
	return Plugin_Handled;	
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
					SetEntProp(i, Prop_Send, "m_iHealth", health, 1)
					SetEntProp(i, Prop_Data, "m_iHealth", health, 1)
					PrintToChat(i,"\x01\x04You have had your health set to: %i",health)
				}
			}
			else if (letter=='T') //assume @T
			{
				if (GetClientTeam(i)==2)
				{
					SetEntProp(i, Prop_Send, "m_iHealth", health, 1)
					SetEntProp(i, Prop_Data, "m_iHealth", health, 1)
					PrintToChat(i,"\x01\x04You have had your health set to: %i",health)
				}
					
			}
			else //assume @ALL
			{
				SetEntProp(i, Prop_Send, "m_iHealth", health, 1)
				SetEntProp(i, Prop_Data, "m_iHealth", health, 1)
				PrintToChat(i,"\x01\x04You have had your health set to: %i",health)
			}
		}
		
		return Plugin_Handled
	}
	
	new iClients[2];
	new iNumClients = SearchForClients(Target, iClients, 2);
	
	if (iNumClients == 0)
	{
		ReplyToCommand(client, "[SM] %t", "No matching client");
		return Plugin_Handled;
	}
	else if (iNumClients > 1)
	{
		ReplyToCommand(client, "[SM] %t", "More than one client matches", Target);
		return Plugin_Handled;
	}
	else if (!CanUserTarget(client, iClients[0]))
	{
		ReplyToCommand(client, "[SM] %t", "Unable to target");
		return Plugin_Handled;
	}
	
	SetEntProp(iClients[0], Prop_Send, "m_iHealth", health, 1)
	SetEntProp(iClients[0], Prop_Data, "m_iHealth", health, 1)
	PrintToChat(iClients[0],"\x01\x04You have had your health set to: %i",health)
	
	return Plugin_Handled;	
}

public Action:Command_Armour(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_armour <name or #userid> <armour>");
		return Plugin_Handled;	
	}	
	
	new String:Target[64],String:armr[10]
	GetCmdArg(1, Target, sizeof(Target))
	GetCmdArg(2, armr, sizeof(armr))

	new armour = StringToInt(armr)
	
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
					SetEntProp(i, Prop_Send, "m_ArmorValue", armour, 1)
					PrintToChat(i,"\x01\x04You have had your armour set to: %i",armour)
				}
			}
			else if (letter=='T') //assume @T
			{
				if (GetClientTeam(i)==2)
				{
					SetEntProp(i, Prop_Send, "m_ArmorValue", armour, 1)
					PrintToChat(i,"\x01\x04You have had your armour set to: %i",armour)
				}
					
			}
			else //assume @ALL
			{
				SetEntProp(i, Prop_Send, "m_ArmorValue", armour, 1)
				PrintToChat(i,"\x01\x04You have had your armour set to: %i",armour)
			}
		}
		
		return Plugin_Handled
	}
		
	new iClients[2];
	new iNumClients = SearchForClients(Target, iClients, 2);
	
	if (iNumClients == 0)
	{
		ReplyToCommand(client, "[SM] %t", "No matching client");
		return Plugin_Handled;
	}
	else if (iNumClients > 1)
	{
		ReplyToCommand(client, "[SM] %t", "More than one client matches", Target);
		return Plugin_Handled;
	}
	else if (!CanUserTarget(client, iClients[0]))
	{
		ReplyToCommand(client, "[SM] %t", "Unable to target");
		return Plugin_Handled;
	}
	
	SetEntProp(iClients[0], Prop_Send, "m_ArmorValue", armour, 1)
	PrintToChat(iClients[0],"\x01\x04You have had your armour set to: %i",armour)
	
	return Plugin_Handled;	
}

public Action:Command_Burn(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_burn <name or #userid> <time in seconds>");
		return Plugin_Handled;	
	}	
	
	new String:Target[64],String:time[10]
	GetCmdArg(1, Target, sizeof(Target))
	GetCmdArg(2, time, sizeof(time))

	new Float:burntime = StringToFloat(time)
	
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
					IgniteEntity(i, burntime)
					PrintToChat(i,"\x01\x04You have been set on fire for %2.1f seconds",burntime)
				}
			}
			else if (letter=='T') //assume @T
			{
				if (GetClientTeam(i)==2)
				{
					IgniteEntity(i, burntime)
					PrintToChat(i,"\x01\x04You have been set on fire for %2.1f seconds",burntime)
				}
					
			}
			else //assume @ALL
			{
				IgniteEntity(i, burntime)
				PrintToChat(i,"\x01\x04You have been set on fire for %2.1f seconds",burntime)
			}
		}
		
		return Plugin_Handled
	}
		
	new iClients[2];
	new iNumClients = SearchForClients(Target, iClients, 2);
	
	if (iNumClients == 0)
	{
		ReplyToCommand(client, "[SM] %t", "No matching client");
		return Plugin_Handled;
	}
	else if (iNumClients > 1)
	{
		ReplyToCommand(client, "[SM] %t", "More than one client matches", Target);
		return Plugin_Handled;
	}
	else if (!CanUserTarget(client, iClients[0]))
	{
		ReplyToCommand(client, "[SM] %t", "Unable to target");
		return Plugin_Handled;
	}
	
	IgniteEntity(iClients[0], burntime)
	PrintToChat(iClients[0],"\x01\x04You have been set on fire for %2.1f seconds",burntime)
	
	return Plugin_Handled;
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
	
	new Float:vec[3]
	
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
					GetEntPropVector(i, Prop_Send, "m_vecOrigin", vec)
	
					vec[2]=vec[2]+30.0
					SetEntPropVector(i, Prop_Send, "m_vecOrigin", vec)
	
					PrintToChat(i,"\x01\x04You have been unburied")
				}
			}
			else if (letter=='T') //assume @T
			{
				if (GetClientTeam(i)==2)
				{
					GetEntPropVector(i, Prop_Send, "m_vecOrigin", vec)
	
					vec[2]=vec[2]+30.0
					SetEntPropVector(i, Prop_Send, "m_vecOrigin", vec)
	
					PrintToChat(i,"\x01\x04You have been unburied")
				}
					
			}
			else //assume @ALL
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", vec)

				vec[2]=vec[2]+30.0
				SetEntPropVector(i, Prop_Send, "m_vecOrigin", vec)

				PrintToChat(i,"\x01\x04You have been unburied")
			}
		}
		
		return Plugin_Handled
	}
	
	new iClients[2];
	new iNumClients = SearchForClients(Target, iClients, 2);
	
	if (iNumClients == 0)
	{
		ReplyToCommand(client, "[SM] %t", "No matching client");
		return Plugin_Handled;
	}
	else if (iNumClients > 1)
	{
		ReplyToCommand(client, "[SM] %t", "More than one client matches", Target);
		return Plugin_Handled;
	}
	else if (!CanUserTarget(client, iClients[0]))
	{
		ReplyToCommand(client, "[SM] %t", "Unable to target");
		return Plugin_Handled;
	}	
	
	GetEntPropVector(iClients[0], Prop_Send, "m_vecOrigin", vec)
	
	vec[2]=vec[2]+30.0
	SetEntPropVector(iClients[0], Prop_Send, "m_vecOrigin", vec)
	
	PrintToChat(iClients[0],"\x01\x04You have been unburied")
	
	return Plugin_Handled;	
}

public Action:Command_Slay(client, args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_slay <name or #userid>");
		return Plugin_Handled;	
	}	
	
	new String:Target[64]
	GetCmdArg(1, Target, sizeof(Target))

	new num=trim_quotes(Target)
	new letter = Target[num+1]
	
	if (Target[num]=='@')
	{
		//assume it is either @ALL, @CT or @T
		for (new i=1; i<=maxplayers; i++)
		{
			if (!IsClientInGame(i))
				continue
			
			if ((letter=='C' && GetClientTeam(i)==3) || (letter=='T' && GetClientTeam(i)==2) || letter=='A')
			{
				SDKCall(hCommitSuicide, client)
				PrintToChat(i,"\x01\x04You have been slain")
			}	
		}
		
		return Plugin_Handled
	}
		
	new iClients[2];
	new iNumClients = SearchForClients(Target, iClients, 2);
	
	if (iNumClients == 0)
	{
		ReplyToCommand(client, "[SM] %t", "No matching client");
		return Plugin_Handled;
	}
	else if (iNumClients > 1)
	{
		ReplyToCommand(client, "[SM] %t", "More than one client matches", Target);
		return Plugin_Handled;
	}
	else if (!CanUserTarget(client, iClients[0]))
	{
		ReplyToCommand(client, "[SM] %t", "Unable to target");
		return Plugin_Handled;
	}
	
	SDKCall(hCommitSuicide, client)
	
	PrintToChat(iClients[0],"\x01\x04You have been slain")
	
	return Plugin_Handled;	
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

	new num=trim_quotes(Target)
	new letter = Target[num+1]
	
	if (Target[num]=='@')
	{
		//assume it is either @ALL, @CT or @T
		for (new i=1; i<=maxplayers; i++)
		{
			if (!IsClientInGame(i))
				continue
			
			if ((letter=='C' && GetClientTeam(i)==3) || (letter=='T' && GetClientTeam(i)==2) || letter=='A')
			{
				SDKCall(hRoundRespawn, i)
				PrintToChat(i,"\x01\x04You have been respawned")
			}	
		}
		
		return Plugin_Handled
	}
		
	new iClients[2];
	new iNumClients = SearchForClients(Target, iClients, 2);
	
	if (iNumClients == 0)
	{
		ReplyToCommand(client, "[SM] %t", "No matching client");
		return Plugin_Handled;
	}
	else if (iNumClients > 1)
	{
		ReplyToCommand(client, "[SM] %t", "More than one client matches", Target);
		return Plugin_Handled;
	}
	else if (!CanUserTarget(client, iClients[0]))
	{
		ReplyToCommand(client, "[SM] %t", "Unable to target");
		return Plugin_Handled;
	}
	
	SDKCall(hRoundRespawn, iClients[0])
	
	PrintToChat(iClients[0],"\x01\x04You have been respawned")
	
	return Plugin_Handled;	
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

	new num=trim_quotes(Target)
	new letter = Target[num+1]
	
	if (Target[num]=='@')
	{
		//assume it is either @ALL, @CT or @T
		for (new i=1; i<=maxplayers; i++)
		{
			if (!IsClientInGame(i))
				continue
			
			if ((letter=='C' && GetClientTeam(i)==3) || (letter=='T' && GetClientTeam(i)==2) || letter=='A')
			{
				SDKCall(hRemoveItems, i,false)
				PrintToChat(i,"\x01\x04You have been disarmed")
			}	
		}
		
		return Plugin_Handled
	}
		
	new iClients[2];
	new iNumClients = SearchForClients(Target, iClients, 2);
	
	if (iNumClients == 0)
	{
		ReplyToCommand(client, "[SM] %t", "No matching client");
		return Plugin_Handled;
	}
	else if (iNumClients > 1)
	{
		ReplyToCommand(client, "[SM] %t", "More than one client matches", Target);
		return Plugin_Handled;
	}
	else if (!CanUserTarget(client, iClients[0]))
	{
		ReplyToCommand(client, "[SM] %t", "Unable to target");
		return Plugin_Handled;
	}
	
	SDKCall(hRemoveItems, iClients[0],false)
	
	PrintToChat(iClients[0],"\x01\x04You have been disarmed")
	
	return Plugin_Handled;	
}

public Action:Command_Bury(client, args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_bury <name or #userid>");
		return Plugin_Handled;	
	}	
	new Float:vec[3]
	
	new String:Target[64]
	GetCmdArg(1, Target, sizeof(Target))

	new num=trim_quotes(Target)
	new letter = Target[num+1]
	
	if (Target[num]=='@')
	{
		//assume it is either @ALL, @CT or @T
		for (new i=1; i<=maxplayers; i++)
		{
			if (!IsClientInGame(i))
				continue
			
			if ((letter=='C' && GetClientTeam(i)==3) || (letter=='T' && GetClientTeam(i)==2) || letter=='A')
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", vec)
				vec[2]=vec[2]-30.0
				SetEntPropVector(i, Prop_Send, "m_vecOrigin", vec)
				PrintToChat(i,"\x01\x04You have been buried")
			}	
		}
		
		return Plugin_Handled
	}
		
	new iClients[2];
	new iNumClients = SearchForClients(Target, iClients, 2);
	
	if (iNumClients == 0)
	{
		ReplyToCommand(client, "[SM] %t", "No matching client");
		return Plugin_Handled;
	}
	else if (iNumClients > 1)
	{
		ReplyToCommand(client, "[SM] %t", "More than one client matches", Target);
		return Plugin_Handled;
	}
	else if (!CanUserTarget(client, iClients[0]))
	{
		ReplyToCommand(client, "[SM] %t", "Unable to target");
		return Plugin_Handled;
	}
	
	GetEntPropVector(iClients[0], Prop_Send, "m_vecOrigin", vec)
	
	vec[2]=vec[2]-30.0
	SetEntPropVector(iClients[0], Prop_Send, "m_vecOrigin", vec)
	
	PrintToChat(iClients[0],"\x01\x04You have been buried")
	
	return Plugin_Handled;	
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
 
	SendHintText(attacker,"Damage : %i",damage)
}

stock SendHintText(client,String:text[], any:...)
{
	new String:message[192];
	VFormat(message,191,text, 3);

	new len = strlen(message);
	
	if(len > 30)
	{
		new LastAdded=0;

		for(new i=0;i<len;i++)
		{
			if((message[i]==' ' && LastAdded > 30 && (len-i) > 10) || ((GetNextSpaceCount(text,i+1) + LastAdded)  > 34))
			{
				message[i] = '\n';
				LastAdded = 0;
			}
			else
				LastAdded++;
		}
	}

	new clients[2]
	clients[0]=client
	
	new Handle:HintMessage = StartMessage("HintText", clients, 1)
	BfWriteByte(HintMessage,-1);
	BfWriteString(HintMessage,message);
	EndMessage();
}

stock GetNextSpaceCount(String:text[],CurIndex)
{
	new Count=0;
	new len = strlen(text);
	for(new i=CurIndex;i<len;i++)
	{
		if(text[i] == ' ')
			return Count;
		else
			Count++;
	}

	return Count;
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
			aid = GetUserAdmin(i)
			if (GetAdminFlag(aid, flag, Access_Effective) && (GetEntData(client, LifeStateOff, 1) == 0))
				PrintToChat(i,"[ADMINSEEALL]%s: %s",name,text[startidx])
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
			aid = GetUserAdmin(i)
			team = GetClientTeam(i)
			if (GetAdminFlag(aid, flag, Access_Effective) && (senderteam != team))
				PrintToChat(i,"[ADMINSEEALL]%s: %s",name,text[startidx])
		}	
	}
	else
	{
		//dead	
		for (new i=1; i<=maxplayers; i++)
		{
			aid = GetUserAdmin(i)
			team = GetClientTeam(i)
			if (GetAdminFlag(aid, flag, Access_Effective) && ((GetEntData(client, LifeStateOff, 1) == 0) || (senderteam != team)))
				PrintToChat(i,"[ADMINSEEALL]%s: %s",name,text[startidx])
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
	GeoipCountry(ip, country)
	
	PrintToChatAll("\x01\x04%s (\x01%s\x04) connected from %s",name,authid,country)
}