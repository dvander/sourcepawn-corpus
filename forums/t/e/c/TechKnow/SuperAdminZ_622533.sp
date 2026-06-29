/*
	SM Super Admin bY TechKnow & Pred
	
	You can change the below line #define ADMIN_LEVEl *** to something else if you wish
	
	Most powers are reset each round.

	Features and Commands:

	Armour 		    - sm_armour <player/@ALL/@CT/@T> <armour>
	HP 		    - sm_hp <player/@ALL/@CT/@T> <hp>			
	Bury		    - sm_bury <player/@ALL/@CT/@T>, sm_unbury <player>
	Give weapon	    - sm_weapon <player/@ALL/@CT/@T> <itemname> (eg weapon_ak47)
	Teamswap	    - sm_teamswap / sm_swapteam - <player1> <player2> etc etc. Or no args to swap entire team
	Move player team    - sm_team <player/@ALL/@CT/@T> <teamid>  (CSS 1-spec, 2-t, 3-ct)
	Defuser		    - sm_defuser <player/@ALL/@CT/@T> <1|0>
	NV		    - sm_nv <player/@ALL/@CT/@T> <1|0>
	Helmet		    - sm_helmet <player/@ALL/@CT/@T> <1|0>
	God Mode	    - sm_god <player/@ALL/@CT/@T> <1|0>
	Extend		    - sm_extend <minutes>
	Speed		    - sm_speed <player/@ALL/@CT/@T> <Float speed>
        Cash		    - sm_cash <player/@ALL/@CT/@T> <amount>
        Name		    - sm_name <player> <newname>
	Respawn		    - sm_respawn <player/@ALL/@CT/@T>
	Disarm		    - sm_disarm <player/@ALL/@CT/@T>
        Saves Tele loc      - sm_saveloc <Wherever you are is the saved teleport location>
        Teleport Player     - sm_tele <player/@ALL/@CT/@T>
        Infinite Ammo       - sm_aia <1|0>
	Connect Announce    - Cvar: sm_connectannounce <1|0>
	Admin See All	    - Cvar: sm_adminseeall <1|0>
        show damage         - Cvar: sm_showdamage <1|0>

	

			
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

#define PLUGIN_VERSION "0.60"


//Global admin level needed for most commands
//Change ADMFLAG_CUSTOM4 to something from the above list if you wish
//#define ADMIN_LEVEL ADMFLAG_BAN

//Individual Admin levels for commands
//Change the ADMIN_LEVEL to one of the above list if you want
//ADMIN_LEVEL makes it the default admin level (defined above)
#define ADMIN_BURY	ADMFLAG_ROOT
#define ADMIN_UNBURY	ADMFLAG_ROOT
#define ADMIN_RESPAWN	ADMFLAG_ROOT
#define ADMIN_DISARM	ADMFLAG_ROOT
#define ADMIN_HP	ADMFLAG_ROOT
#define ADMIN_ARMOUR	ADMFLAG_ROOT
#define ADMIN_WEAPON	ADMFLAG_ROOT
#define ADMIN_GOD	ADMFLAG_ROOT
#define ADMIN_SPEED	ADMFLAG_ROOT
#define ADMIN_NV	ADMFLAG_ROOT
#define ADMIN_DEFUSER	ADMFLAG_ROOT
#define ADMIN_HELMET	ADMFLAG_ROOT
#define ADMIN_TEAM	ADMFLAG_ROOT
#define ADMIN_EXTEND	ADMFLAG_ROOT
#define ADMIN_SEEALL	ADMFLAG_ROOT
#define ADMIN_NAME	ADMFLAG_ROOT
#define ADMIN_CASH	ADMFLAG_ROOT

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
new g_iAccount = -1
new Float:g_uLoc[3]
new Handle:thisplugin
new LifeStateOff
new maxplayers
new String:modname[30]
new activeoffset = 1896
new clipoffset = 1204
new bool:iammo = false;
new aswitch;

#define NUMMODS 4
#define CSTRIKE 0
#define DOD 1
#define HL2MP 2
#define INS 3
 
new mod
static String:teamname[NUMMODS][3][] =  
{
	{"All","Terrorist","Counter-Terrorist" },
	{"All","Allies","Axis" },
	{"All","Combine","Rebels" },
	{"All","US Marines","Insurgents"} //This might be the other way around
}

public Plugin:myinfo = 
{
	name = "SM Super Admin",
	author = "TechKnow & Pred",
	description = "Assorted Fun Commands",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	CreateConVar("sm_superadmin_version", PLUGIN_VERSION, "Super Admin Version",         FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	
	GetGameFolderName(modname, sizeof(modname));
	
	//Get mod name stuff
	if (StrEqual(modname,"cstrike",false)) mod = CSTRIKE
	else if (StrEqual(modname,"dod",false)) mod = DOD
	else if (StrEqual(modname,"hl2mp",false)) mod = HL2MP
	else if (StrEqual(modname,"Insurgency",false)) mod = INS

        LoadTranslations("common.phrases");
	RegAdminCmd("sm_saveloc", Save_Loc, ADMFLAG_ROOT, "saves location");
	RegAdminCmd("sm_teleport", Teleport_User, ADMFLAG_ROOT, "sm_teleport <#userid|name>");
        RegAdminCmd("sm_aia", Command_Setiammo, ADMFLAG_ROOT);       
	RegAdminCmd("sm_bury", Command_Bury,ADMIN_BURY)
	RegAdminCmd("sm_unbury", Command_UnBury,ADMIN_BURY)
	RegAdminCmd("sm_respawn", Command_Respawn,ADMIN_RESPAWN)
	RegAdminCmd("sm_disarm", Command_Disarm,ADMIN_DISARM)
	RegAdminCmd("sm_hp", Command_HP,ADMIN_HP)
	RegAdminCmd("sm_armour", Command_Armour,ADMIN_ARMOUR)
	RegAdminCmd("sm_weapon", Command_Weapon,ADMIN_WEAPON)
	RegAdminCmd("sm_god", Command_God,ADMIN_GOD)
	RegAdminCmd("sm_speed", Command_Speed,ADMIN_SPEED)
	RegAdminCmd("sm_nv", Command_NV,ADMIN_NV)
	RegAdminCmd("sm_defuser", Command_Defuser,ADMIN_DEFUSER)
	RegAdminCmd("sm_helmet", Command_Helmet,ADMIN_HELMET)
	RegAdminCmd("sm_teamswap",Command_TeamSwap,ADMIN_TEAM)
	RegAdminCmd("sm_swapteam",Command_TeamSwap,ADMIN_TEAM)
	RegAdminCmd("sm_team",Command_Team,ADMIN_TEAM)
	RegAdminCmd("sm_extend",Command_Extend,ADMIN_EXTEND)
        RegAdminCmd("sm_name", Command_Name,ADMIN_NAME) 
	RegAdminCmd("sm_cash", Command_SmCash, ADMIN_CASH)
	
	RegConsoleCmd("say", Command_Say)
	RegConsoleCmd("say_team", Command_SayTeam)
	
	g_hMpTimelimit = FindConVar("mp_timelimit")
	g_hShowDmg = CreateConVar("sm_showdamage","1","Show Damage Done")
	g_hConnectAnnounce = CreateConVar("sm_connectannounce","1","Announce connections")
	g_hAdminSeeAll = CreateConVar("sm_adminseeall","1","Show admins all chat")
	
	hGameConf = LoadGameConfigFile("superadmin.gamedata")
	LoadTranslations("common.phrases")
	
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

	if (g_iAccount == -1)
	{
		PrintToServer("[smcash] - Unable to start, cannot find necessary send prop offsets.");
		return;
	}	
	
        new off = FindSendPropOffs("CAI_BaseNPC", "m_hActiveWeapon");
        if(off != -1)
        {
            activeoffset = off;
        }
        off = -1;
        off = FindSendPropOffs("CBaseCombatWeapon", "m_iClip1");
        if(off != -1)
        {
            clipoffset = off;
        }

	LifeStateOff = FindSendPropOffs("CBasePlayer","m_lifeState")
        g_iAccount = FindSendPropOffs("CCSPlayer", "m_iAccount");
	thisplugin = GetMyHandle()

	HookEvent("player_hurt", Event_PlayerHurt)
}

public OnMapStart()
{
	maxplayers = GetMaxClients()
}

public OnMapEnd()
{
        iammo = false;
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
		ReplyToCommand(client, "\x01\x04[SM] %t", "No matching client");
		return -1
	}
	else if (iNumClients > 1)
	{
		ReplyToCommand(client, "\x01\x04[SM] %t", "More than one client matches", Target);
		return -1
	}
	else if (!CanUserTarget(client, iClients[0]))
	{
		ReplyToCommand(client, "\x01\x04[SM] %t", "Unable to target");
		return -1
	}
	
	return iClients[0]
}

public ExecSpeed(client, any:speed)
{
        if (!client || !IsClientInGame(client) || !IsPlayerAlive(client))
        {
               return;
        }
        if (speed == 0)
        {
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", Float:speed)
	PrintToChat(client,"\x01\x04You have been FROZEN by an admin", speed)
        }
        else if (speed == 1.0)
        {
	SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", Float:speed)
	PrintToChat(client,"\x01\x04Your movement has been returnd to normal", speed)
        }
        else
        {
        SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", Float:speed)
	PrintToChat(client,"\x01\x04You have been given %2.1ftimes normal speed", speed)
        }
}

public Action:Command_Speed(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "\x01\x04[SM] Usage: sm_speed <name or #userid> <Float speed mult>");
		return Plugin_Handled;	
	}	
	
	new String:Target[64],String:hp[10]
	GetCmdArg(1, Target, sizeof(Target))
	GetCmdArg(2, hp, sizeof(hp))

	new Float:speed = StringToFloat(hp)
	
	return FindPlayer(client, Target, ExecSpeed, any:speed)
}

public ExecGod(client, any:status)
{
        if (!client || !IsClientInGame(client) || !IsPlayerAlive(client))
        {
               return;
        }
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
		ReplyToCommand(client, "\x01\x04[SM] Usage: sm_god <name or #userid> <1|0>");
		return Plugin_Handled;	
	}	
	
	new String:Target[64],String:on[10]
	GetCmdArg(1, Target, sizeof(Target))
	GetCmdArg(2, on, sizeof(on))

	new status = StringToInt(on)
	
	return FindPlayer(client, Target, ExecGod, any:status)
}

public ExecNV(client, any:status)
{
        if (!client || !IsClientInGame(client) || !IsPlayerAlive(client))
        {
               return;
        }
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
		ReplyToCommand(client, "\x01\x04[SM] That Command is not supported on this mod (Cstrike only)");
		return Plugin_Handled;	
	}
	
	if (args < 2)
	{
		ReplyToCommand(client, "\x01\x04[SM] Usage: sm_nv <name or #userid> <1|0>");
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
        if (!client || !IsClientInGame(client) || !IsPlayerAlive(client))
        {
               return;
        }
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
		ReplyToCommand(client, "\x01\x04[SM] That Command is not supported on this mod (Cstrike only)");
		return Plugin_Handled;	
	}
	
	if (args < 2)
	{
		ReplyToCommand(client, "\x01\x04[SM] Usage: sm_defuser <name or #userid> <1|0>");
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
        if (!client || !IsClientInGame(client) || !IsPlayerAlive(client))
        {
               return;
        }
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
		ReplyToCommand(client, "\x01\x04[SM] That Command is not supported on this mod (Cstrike only)");
		return Plugin_Handled;	
	}
	
	if (args < 2)
	{
		ReplyToCommand(client, "\x01\x04[SM] Usage: sm_helmet <name or #userid> <1|0>");
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
		ReplyToCommand(client, "\x01\x04[SM] Usage: sm_team <name or #userid> <teamindex>");
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
		ReplyToCommand(client, "\x01\x04[SM] Usage: sm_extend <minutes>");
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

public Action:Command_Weapon(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "\x01\x04[SM] Usage: sm_weapon <name or #userid> <weapon name>");
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
			if (!IsClientInGame(i) || !IsPlayerAlive(i))
				continue;
				
			if (letter=='C') //assume @CT
			{
				if (GetClientTeam(i)==3)
				{
					new ent = GivePlayerItem(i, weapon)
	
					if (ent == -1)
						ReplyToCommand(client, "\x01\x04[SM] Invalid Item")
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
						ReplyToCommand(client, "\x01\x04[SM] Invalid Item")
					else
						PrintToChat(i,"\x01\x04You have been given %s",weapon)
				}
					
			}
			else //assume @ALL
			{
				new ent = GivePlayerItem(i, weapon)

				if (ent == -1)
					ReplyToCommand(client, "\x01\x04[SM] Invalid Item")
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
		ReplyToCommand(client, "\x01\x04[SM] Invalid Item")
	else
		PrintToChat(targetclient,"\x01\x04You have been given %s",weapon)
	
	return Plugin_Handled;	
}

public ExecHP(client, any:health)
{
        if (!client || !IsClientInGame(client) || !IsPlayerAlive(client))
        {
               return;
        }
	SetEntProp(client, Prop_Send, "m_iHealth", health, 1)
	SetEntProp(client, Prop_Data, "m_iHealth", health, 1)
	PrintToChat(client,"\x01\x04You have had your health set to: %i",health)
}

public Action:Command_HP(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "\x01\x04[SM] Usage: sm_hp <name or #userid> <hp>");
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
        if (!client || !IsClientInGame(client) || !IsPlayerAlive(client))
        {
               return;
        }
	SetEntProp(client, Prop_Send, "m_ArmorValue", armour, 1)
	PrintToChat(client,"\x01\x04You have had your armour set to: %i",armour)
}

public Action:Command_Armour(client, args)
{
	if (mod != CSTRIKE)
	{
		ReplyToCommand(client, "\x01\x04[SM] That Command is not supported on this mod (Cstrike only)");
		return Plugin_Handled;	
	}
	
	if (args < 2)
	{
		ReplyToCommand(client, "\x01\x04[SM] Usage: sm_armour <name or #userid> <armour>");
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
        if (!client || !IsClientInGame(client) || !IsPlayerAlive(client))
        {
               return;
        }
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
		ReplyToCommand(client, "\x01\x04[SM] Usage: sm_bury <name or #userid>");
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
		ReplyToCommand(client, "\x01\x04[SM] Usage: sm_unbury <name or #userid>");
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
		ReplyToCommand(client, "\x01\x04[SM] Usage: sm_respawn <name or #userid>");
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
		ReplyToCommand(client, "\x01\x04[SM] Usage: sm_disarm <name or #userid>");
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
					PrintToChat(i,"\x01\x04[ADMINSEEALL]%s: %s",name,text[startidx])
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
					PrintToChat(i,"\x01\x04[ADMINSEEALL]%s: %s",name,text[startidx])
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
					PrintToChat(i,"\x01\x04[ADMINSEEALL]%s: %s",name,text[startidx])
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

public Action:Command_Name(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "\x01\x04[SM] Usage: sm_name <user> <name>");
		return Plugin_Handled;
	}

	new String:target[64]
	GetCmdArg(1, target, sizeof(target))

	new String:name[64]
	GetCmdArg(2, name, sizeof(name))

	new clients[2]
	SearchForClients(target, clients, 2)
	
	if (!FindTarget(client, target))
	{
		return Plugin_Handled
	}

	new player = clients[0]

	PrintToChat(player, "\x01\x04[SM] An Admin has changed your name to %s", name)
	ClientCommand(player, "name \"%s\"", name)

	return Plugin_Handled
}

public Action:Command_SmCash(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "\x01\x04[SM] Usage: sm_cash <name or #userid or all/t/ct> <amount>");
		return Plugin_Handled;	
	}
	
	new String:szArg[65]
	GetCmdArg(1, szArg, sizeof(szArg))

	new iAmount
	decl String:szAmount[64]
	GetCmdArg(2, szAmount, 64)
	iAmount = StringToInt(szAmount)
	
	if(iAmount == 0 && szAmount[0] != '0')
	{
		ReplyToCommand(client, "\x01\x04[SM] You have enterd an Invalid Amount")
		return Plugin_Handled;
	}
	
	if(strcmp(szArg, "@all", false) == 0)
	{
		new iMaxClients = GetMaxClients()
		
		for (new i = 1; i <= iMaxClients; i++)
		{
				if (IsClientInGame(i))
					SetMoney(i, iAmount)
		}
		
		ShowActivity(client, "\x01\x04Admin has set everyones cash");		
	}
	else if(strcmp(szArg, "@t", false) == 0 || strcmp(szArg, "@ct", false) == 0)
	{
		new iMaxClients = GetMaxClients()
		
		for (new i = 1; i <= iMaxClients; i++)
		{
				if (IsClientInGame(i))
				{
					if(GetClientTeam(i) == (strcmp(szArg, "@t", false) == 0 ? 2 : 3))
						SetMoney(i, iAmount)
				}
		}
		
		ShowActivity(client, "\x01\x04Admin has set A Teams cash");			
	}
	else
	{
		new iClients[2];
		new iNumClients = SearchForClients(szArg, iClients, 2)
	
		if (iNumClients == 0)
		{
			ReplyToCommand(client, "\x01\x04[SM] %t", "No matching client")
			return Plugin_Handled;
		}
		else if (iNumClients > 1)
		{
			ReplyToCommand(client, "\x01\x04[SM] %t", "More than one client matches", szArg)
			return Plugin_Handled;
		}
		else if (!CanUserTarget(client, iClients[0]))
		{
			ReplyToCommand(client, "\x01\x04[SM] %t", "Unable to target")
			return Plugin_Handled;
		}
		
		decl String:szName[64];
		GetClientName(iClients[0], szName, 64)
		
		SetMoney(iClients[0], iAmount)
		
		ShowActivity(client, "\x01\x04Admin has set a players cash");
	}
		
	return Plugin_Handled
}

public SetMoney(client, amount)
{
	if (g_iAccount != -1)
		SetEntData(client, g_iAccount, amount)
}

public GetMoney(client)
{
	if (g_iAccount != -1)
		return GetEntData(client, g_iAccount)

	return 0
}

public Action:Save_Loc(client, args)
{
	GetClientAbsOrigin(client, g_uLoc);
	return Plugin_Handled;
}

public Action:Teleport_User(client, args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "\x01\x04[SM] Usage: sm_tele <name or #userid>");
		return Plugin_Handled;	
	}	
	
	new String:Target[64]
	GetCmdArg(1, Target, sizeof(Target))
	
	return FindPlayer(client, Target, Teleport, 1)
}

public Teleport(client, any:tele)
{
	ShowActivity(client, "\x01\x04An Admin has Teleported a player");
	TeleportEntity(client, g_uLoc, NULL_VECTOR, NULL_VECTOR);
}

public Action:Command_Setiammo(client, args)
{
	if (args < 1)
        {
		ReplyToCommand(client, "\x01\x04[SM] Usage: sm_aia <1/0>");
		return Plugin_Handled;
	}
       
	new String:sa[10];
	GetCmdArg(1, sa, sizeof(sa));
        aswitch = StringToInt(sa);
        if(aswitch == 1)
        {
                iammo = true;
                PrintToChatAll("\x01\x04 Infinite Ammo Has Been Enabled")
	}
        if(aswitch == 0)
        {
                iammo = false;
                PrintToChatAll("\x01\x04 Infinite Ammo Has Been Disabled")
        }
        return Plugin_Handled;
}


public OnGameFrame()
{
    if (iammo == false)
	{
		return;
	}
    new zomg;
    for (new i=1; i <= GetMaxClients(); i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i) && IsPlayerAlive(i))
        {
            zomg = GetEntDataEnt(i, activeoffset);
            SetEntData(zomg, clipoffset, 5, 4, true);
        }
    }
} 