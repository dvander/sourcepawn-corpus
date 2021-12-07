#define PLUGIN_VERSION 		"1.4.1"

/*=======================================================================================
	Plugin Info:

*	Name	:	[ANY] Dev Cmds
*	Author	:	SilverShot
*	Descrp	:	Provides a heap of commands for admins/developers to use.
*	Link	:	http://forums.alliedmods.net/showthread.php?t=187566
*	Plugins	:	http://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.4.1 (28-Jun-2019)
	- Changed PrecacheParticle method.

1.4 (01-Jun-2019)
	- Added "sm_anim" to show your players animation sequence number (for 6 * 0.5 seconds).
	- Changed "sm_tel" to also accept angles when teleporting.
	- Changed "sm_ente" to work from the server console.

1.3 (05-May-2018)
	- Converted plugin source to the latest syntax utilizing methodmaps. Requires SourceMod 1.8 or newer.

1.2 (09-Aug-2013)
	- Reverted the change to "sm_alloff".
	- Changed "sm_fcmd" to allow command arguments, Usage: sm_fcmd <#userid|name> <command> [args].

1.1 (22-Jun-2012)
	- Added "sm_findname" to list entities by matching a partial targetname.
	- Changed "sm_modlist" to save the file as "models_mapname.txt".
	- Changed "sm_input", "sm_inputent" and "sm_inputme" to accept parameters.
	- Changed "sm_alloff" to not toggle the director or sb_hold_position.
	- Fixed "sm_find" throwing errors for non-networked entities.

1.0 (15-Jun-2012)
	- Initial release.

========================================================================================

	This plugin was made using source code from the following plugins.
	If I have used your code and not credited you, please let me know.

*	Thanks to "Don't Fear The Reaper" - For the sm_slaycommon and sm_slaywitches code.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define	MAX_OUTPUTS	32

bool g_bDirector = true, g_bCheats, g_bAll, g_bHalt, g_bHold, g_bNB;
int g_iGAMETYPE, g_iEntsSpit[MAXPLAYERS], g_iLedge[MAXPLAYERS];
float g_vAng[MAXPLAYERS+1][3], g_vPos[MAXPLAYERS+1][3];

ConVar mp_gamemode, z_background_limit, z_boomer_limit, z_charger_limit, z_common_limit, z_hunter_limit, z_jockey_limit, z_minion_limit, z_smoker_limit, z_spitter_limit;
int g_iHaloMaterial, g_iLaserMaterial, g_iOutputs[MAX_OUTPUTS][2];
char g_sOutputs[MAX_OUTPUTS][64];

enum ()
{
	GAME_ANY = 1,
	GAME_L4D,
	GAME_L4D2,
	GAME_CSS
}



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[ANY] Dev Cmds",
	author = "SilverShot",
	description = "Provides a heap of commands for admins/developers to use.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=187566"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	switch( test )
	{
		case (Engine_CSS):			g_iGAMETYPE = GAME_CSS;
		case (Engine_CSGO):			g_iGAMETYPE = GAME_CSS;
		case (Engine_Left4Dead):	g_iGAMETYPE = GAME_L4D;
		case (Engine_Left4Dead2):	g_iGAMETYPE = GAME_L4D2;
		default:					g_iGAMETYPE = GAME_ANY;
	}

	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("sm_dev_cmds",		PLUGIN_VERSION,			"Dev Cmds plugin version.",	FCVAR_NOTIFY|FCVAR_DONTRECORD);

	// Commands
	RegAdminCmd("sm_refresh",		CmdRefresh,		ADMFLAG_ROOT);
	RegAdminCmd("sm_renew",			CmdRenew,		ADMFLAG_ROOT);
	RegAdminCmd("sm_unload",		CmdUnload,		ADMFLAG_ROOT);

	RegAdminCmd("sm_round",			CmdRound,		ADMFLAG_ROOT);
	RegAdminCmd("sm_cheats",		CmdCheats,		ADMFLAG_ROOT);
	RegAdminCmd("sm_logit",			CmdLogIt,		ADMFLAG_ROOT);
	RegAdminCmd("sm_gametime",		CmdGameTime,	ADMFLAG_ROOT);
	RegAdminCmd("sm_createent",		CmdCreateEnt,	ADMFLAG_ROOT);

	RegAdminCmd("sm_e",				CmdECheat,		ADMFLAG_ROOT);
	RegAdminCmd("e",				CmdECheat,		ADMFLAG_ROOT);
	RegAdminCmd("sm_cv",			CmdCV,			ADMFLAG_ROOT);
	RegAdminCmd("cv",				CmdCV,			ADMFLAG_ROOT);
	RegAdminCmd("sm_fcmd",			CmdFCmd,		ADMFLAG_ROOT);
	RegAdminCmd("sm_ccmd",			CmdCCmd,		ADMFLAG_ROOT);

	RegAdminCmd("sm_views",			CmdViewS,		ADMFLAG_ROOT);
	RegAdminCmd("sm_viewr",			CmdViewR,		ADMFLAG_ROOT);
	RegAdminCmd("sm_pos",			CmdPosition,	ADMFLAG_ROOT);
	RegAdminCmd("sm_tel",			CmdTeleport,	ADMFLAG_ROOT);
	RegAdminCmd("sm_anim",			CmdAnim,		ADMFLAG_ROOT);

	RegAdminCmd("sm_del",			CmdDel,			ADMFLAG_ROOT);
	RegAdminCmd("sm_ent",			CmdEnt,			ADMFLAG_ROOT);
	RegAdminCmd("sm_ente",			CmdEntE,		ADMFLAG_ROOT);
	RegAdminCmd("sm_box",			CmdBox,			ADMFLAG_ROOT);
	RegAdminCmd("sm_find",			CmdFind,		ADMFLAG_ROOT);
	RegAdminCmd("sm_findname",		CmdFindName,	ADMFLAG_ROOT);
	RegAdminCmd("sm_count",			CmdCount,		ADMFLAG_ROOT);
	RegAdminCmd("sm_modlist",		CmdModList,		ADMFLAG_ROOT);

	RegAdminCmd("sm_prop",			CmdProp,		ADMFLAG_ROOT);
	RegAdminCmd("sm_propent",		CmdPropEnt,		ADMFLAG_ROOT);
	RegAdminCmd("sm_propi",			CmdPropMe,		ADMFLAG_ROOT);
	RegAdminCmd("sm_propself",		CmdPropMe,		ADMFLAG_ROOT);

	RegAdminCmd("sm_input",			CmdInput,		ADMFLAG_ROOT);
	RegAdminCmd("sm_inputent",		CmdInputEnt,	ADMFLAG_ROOT);
	RegAdminCmd("sm_inputme",		CmdInputMe,		ADMFLAG_ROOT);
	RegAdminCmd("sm_output",		CmdOutput,		ADMFLAG_ROOT);
	RegAdminCmd("sm_outputent",		CmdOutputEnt,	ADMFLAG_ROOT);
	RegAdminCmd("sm_outputme",		CmdOutputMe,	ADMFLAG_ROOT);
	RegAdminCmd("sm_outputstop",	CmdOutputStop,	ADMFLAG_ROOT);

	RegAdminCmd("sm_part",			CmdPart,		ADMFLAG_ROOT);
	RegAdminCmd("sm_parti",			CmdPart2,		ADMFLAG_ROOT);

	if( g_iGAMETYPE == GAME_L4D || g_iGAMETYPE == GAME_L4D2 )
	{
		RegAdminCmd("sm_lobby",			CmdLobby,		0,	"Starts a vote return to lobby.");
		RegAdminCmd("sm_ledge",			CmdLedge,		ADMFLAG_ROOT);
		RegAdminCmd("sm_spit",			CmdSpit,		ADMFLAG_ROOT);

		RegAdminCmd("sm_alloff",		CmdAll,			ADMFLAG_ROOT);
		RegAdminCmd("sm_director",		CmdDirector,	ADMFLAG_ROOT);
		RegAdminCmd("sm_hold",			CmdHold,		ADMFLAG_ROOT);
		RegAdminCmd("sm_halt",			CmdHalt,		ADMFLAG_ROOT);
		RegAdminCmd("sm_nb",			CmdNB,			ADMFLAG_ROOT);

		RegAdminCmd("sm_slaycommon",	CmdSlayCommon,	ADMFLAG_ROOT);
		RegAdminCmd("sm_slaywitches",	CmdSlayWitches,	ADMFLAG_ROOT);

		RegAdminCmd("sm_c",				CmdCoop,		ADMFLAG_ROOT);
		RegAdminCmd("sm_r",				CmdRealism,		ADMFLAG_ROOT);
		RegAdminCmd("sm_s",				CmdSurvival,	ADMFLAG_ROOT);
		RegAdminCmd("sm_v",				CmdVersus,		ADMFLAG_ROOT);

		mp_gamemode = FindConVar("mp_gamemode");
		z_background_limit = FindConVar("z_background_limit");
		z_common_limit = FindConVar("z_common_limit");
		z_minion_limit = FindConVar("z_minion_limit");
	}

	if( g_iGAMETYPE == GAME_L4D2 )
	{
		z_boomer_limit = FindConVar("z_boomer_limit");
		z_charger_limit = FindConVar("z_charger_limit");
		z_hunter_limit = FindConVar("z_hunter_limit");
		z_jockey_limit = FindConVar("z_jockey_limit");
		z_smoker_limit = FindConVar("z_smoker_limit");
		z_spitter_limit = FindConVar("z_spitter_limit");
	}

	if( g_iGAMETYPE == GAME_CSS || g_iGAMETYPE == GAME_L4D || g_iGAMETYPE == GAME_L4D2 )
	{
		RegAdminCmd("sm_nv",		CmdNV,			ADMFLAG_ROOT);
	}

	if( g_iGAMETYPE == GAME_CSS )
	{
		RegAdminCmd("sm_bots",		CmdBots,		ADMFLAG_ROOT);
		RegAdminCmd("sm_money",		CmdMoney,		ADMFLAG_ROOT);
	}

	// Translations
	LoadTranslations("common.phrases");
}

public void OnPluginEnd()
{
	if( g_iGAMETYPE == GAME_L4D2 )
	{
		for( int i = 0; i <= MaxClients; i++ )
		{
			if( IsValidEntRef(g_iEntsSpit[i]) )
			{
				AcceptEntityInput(g_iEntsSpit[i], "ClearParent");
				AcceptEntityInput(g_iEntsSpit[i], "Kill");
			}
		}
	}
}

public void OnMapStart()
{
	if( g_iGAMETYPE == GAME_L4D || g_iGAMETYPE == GAME_L4D2 )
	{
		g_bDirector = true;
		g_bCheats = false;
		g_bHold = false;
		g_bHalt = false;
		g_bAll = false;

		if( g_iGAMETYPE == GAME_L4D2 )
			PrecacheParticle("spitter_slime_trail");
	}

	g_iLaserMaterial = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_iHaloMaterial = PrecacheModel("materials/sprites/halo01.vmt");
}



// ====================================================================================================
//					COMMANDS - PLUGINS - sm_refresh, sm_reload, sm_unload
// ====================================================================================================
public Action CmdRefresh(int client, int args)
{
	ServerCommand("sm plugins refresh");
	if( client ) PrintToChat(client, "\x04[Plugins Refreshed]");
	else ReplyToCommand(client, "[Plugins Refreshed]");
	return Plugin_Handled;
}

public Action CmdRenew(int client, int args)
{
	ServerCommand("sm plugins unload_all; sm plugins refresh");
	if( client ) PrintToChat(client, "\x04[Plugins Reloaded]");
	else ReplyToCommand(client, "[Plugins Reloaded]");
	return Plugin_Handled;
}

public Action CmdUnload(int client, int args)
{
	ServerCommand("sm plugins unload_all");
	if( client ) PrintToChat(client, "\x04[Plugins Unloaded]");
	else ReplyToCommand(client, "[Plugins Unloaded]");
	return Plugin_Handled;
}



// ====================================================================================================
//					COMMANDS - ALL GAMES - sm_round, sm_cheats, sm_logit, sm_createent
// ====================================================================================================
public Action CmdRound(int client, int args)
{
	if( g_iGAMETYPE == GAME_CSS )
		ServerCommand("mp_restartgame 1");
	else
		ServerCommand("sm_cvar mp_restartgame 1");
	if( client ) PrintToChat(client, "\x04[Restarting game]");
	else ReplyToCommand(client, "\x04[Restarting game]");
	return Plugin_Handled;
}

public Action CmdCheats(int client, int args)
{
	if( g_bCheats )
	{
		ServerCommand("sv_cheats 0");
		g_bCheats = false;
		if( client ) PrintToChat(client, "\x04[sv_cheats]\x01 disabled!");
		else ReplyToCommand(client, "[sv_cheats] disabled!");
	}
	else
	{
		ServerCommand("sv_cheats 1");
		g_bCheats = true;
		if( client ) PrintToChat(client, "\x04[sv_cheats]\x01 enabled!");
		else ReplyToCommand(client, "[sv_cheats] enabled!");
	}
	return Plugin_Handled;
}

public Action CmdLogIt(int client, int args)
{
	char sTemp[256];
	GetCmdArgString(sTemp, sizeof(sTemp));
	LogCustom("%N: %s", client, sTemp);
	return Plugin_Handled;
}

public Action CmdGameTime(int client, int args)
{
	ReplyToCommand(client, "[GameTime] %f", GetGameTime());
	return Plugin_Handled;
}

public Action CmdCreateEnt(int client, int args)
{
	char sBuff[32];
	GetCmdArg(1, sBuff, sizeof(sBuff));

	int entity = CreateEntityByName(sBuff);
	if( entity != -1 )
	{
		ReplyToCommand(client, "Created entity: %s", sBuff);
		AcceptEntityInput(entity, "Kill");
	}
	else
	{
		ReplyToCommand(client, "Failed entity: %s", sBuff);
	}
	return Plugin_Handled;
}




// ====================================================================================================
//					COMMANDS - ALL GAMES - sm_e, sm_cv, sm_fcmd
// ====================================================================================================
public Action CmdECheat(int client, int args)
{
	if( !client ) return Plugin_Handled;
	if( args != 0 )
	{
		char sArg1[64], sArg2[64];
		GetCmdArg(1, sArg1, sizeof(sArg1));

		if( args != 1 )
		{
			GetCmdArgString(sArg2, sizeof(sArg2));
			strcopy(sArg2, sizeof(sArg2), sArg2[FindCharInString(sArg2, ' ')]);
		}

		int bits = GetUserFlagBits(client);
		int flags = GetCommandFlags(sArg1);

		SetUserFlagBits(client, ADMFLAG_ROOT);
		SetCommandFlags(sArg1, flags & ~FCVAR_CHEAT);

		if( args != 1 )
			FakeClientCommand(client, "%s %s", sArg1, sArg2);
		else
			FakeClientCommand(client, "%s", sArg1);

		SetUserFlagBits(client, bits);
		SetCommandFlags(sArg1, flags);
	}
	return Plugin_Handled;
}

public Action CmdCV(int client, int args)
{
	if( args == 0 )
	{
		ReplyToCommand(client, "[SM] Usage: sm_cv <cvar> [value]");
		return Plugin_Handled;
	}

	char sCvar[64], sTemp[256];
	GetCmdArg(1, sCvar, sizeof(sCvar));

	ConVar hCvar = FindConVar(sCvar);
	if( hCvar == null )
	{
		ReplyToCommand(client, "[SM] %t", "Unable to find cvar", sCvar);
		return Plugin_Handled;
	}

	if( args == 1 )
	{
		hCvar.GetString(sTemp, sizeof(sTemp));
		ReplyToCommand(client, "[SM] %t", "Value of cvar", sCvar, sTemp);
		return Plugin_Handled;
	}

	int flags = hCvar.Flags;
	hCvar.Flags = flags & ~FCVAR_NOTIFY;
	GetCmdArg(2, sTemp, sizeof(sTemp));
	hCvar.SetString(sTemp);
	hCvar.Flags = flags;

	ReplyToCommand(client, "[SM] %t", "Cvar changed", sCvar, sTemp);

	return Plugin_Handled;
}

public Action CmdFCmd(int client, int args)
{
	if( args < 2 )
	{
		ReplyToCommand(client, "[FakeCmd] Usage: <#userid|name> <command> [args]");
	}

	char arg1[32]; char arg2[32]; char arg3[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	if( args == 3 ) GetCmdArg(3, arg3, sizeof(arg3));

	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if( (target_count = ProcessTargetString(
		arg1,
		client,
		target_list,
		MAXPLAYERS,
		COMMAND_FILTER_ALIVE,
		target_name,
		sizeof(target_name),
		tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	int target;
	for( int i = 0; i < target_count; i++ )
	{
		target = target_list[i];

		if( args == 3 )
			FakeClientCommand(target, "%s %s", arg2, arg3);
		else
			FakeClientCommand(target, arg2);

		if( client ) PrintToChat(client, "[FakeCmd] Performed on %N", target);
		else ReplyToCommand(client, "[FakeCmd] Performed on %N", target);
	}

	return Plugin_Handled;
}

public Action CmdCCmd(int client, int args)
{
	if( args < 2 )
	{
		ReplyToCommand(client, "[ClientCmd] Usage: <#userid|name> <command> [args]");
	}

	char arg1[32], arg2[32], arg3[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	if( args == 3 ) GetCmdArg(3, arg3, sizeof(arg3));

	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;

	if( (target_count = ProcessTargetString(
		arg1,
		client,
		target_list,
		MAXPLAYERS,
		COMMAND_FILTER_ALIVE,
		target_name,
		sizeof(target_name),
		tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	int target;
	for( int i = 0; i < target_count; i++ )
	{
		target = target_list[i];

		if( args == 3 )
			ClientCommand(target, "%s %s", arg2, arg3);
		else
			ClientCommand(target, arg2);
		PrintToChat(client, "[ClientCmd] Performed on %N", target);
	}

	return Plugin_Handled;
}



// ====================================================================================================
//					COMMANDS - POS - sm_views, sm_viewr, sm_pos, sm_tel
// ====================================================================================================
public Action CmdViewS(int client, int args)
{
	if( !client ) return Plugin_Handled;
	GetClientAbsOrigin(client, g_vPos[client]);
	GetClientEyeAngles(client, g_vAng[client]);
	return Plugin_Handled;
}

public Action CmdViewR(int client, int args)
{
	if( !client ) return Plugin_Handled;
	if( g_vAng[client][0] == 0.0 && g_vAng[client][1] == 0.0 && g_vAng[client][2] == 0.0 )
	{
		PrintToChat(client, "[ViewR] No saved position.");
		return Plugin_Handled;
	}
	TeleportEntity(client, g_vPos[client], g_vAng[client], NULL_VECTOR);
	return Plugin_Handled;
}

public Action CmdPosition(int client, int args)
{
	if( !client ) return Plugin_Handled;
	float vPos[3], vAng[3];
	GetClientAbsOrigin(client, vPos);
	GetClientEyeAngles(client, vAng);
	PrintToChat(client, "%f %f %f     %f %f %f", vPos[0], vPos[1], vPos[2], vAng[0], vAng[1], vAng[2]);
	return Plugin_Handled;
}

public Action CmdTeleport(int client, int args)
{
	if( !client ) return Plugin_Handled;
	float vPos[3];
	char arg[16];
	if( args == 6 )
	{
		GetCmdArg(1, arg, 16);
		vPos[0] = StringToFloat(arg);
		GetCmdArg(2, arg, 16);
		vPos[1] = StringToFloat(arg);
		GetCmdArg(3, arg, 16);
		vPos[2] = StringToFloat(arg);

		float vAng[3];
		GetCmdArg(4, arg, 16);
		vAng[0] = StringToFloat(arg);
		GetCmdArg(5, arg, 16);
		vAng[1] = StringToFloat(arg);
		GetCmdArg(6, arg, 16);
		vAng[2] = StringToFloat(arg);
		TeleportEntity(client, vPos, vAng, NULL_VECTOR);
		return Plugin_Handled;
	}
	else if( args == 3 )
	{
		GetCmdArg(1, arg, 16);
		vPos[0] = StringToFloat(arg);
		GetCmdArg(2, arg, 16);
		vPos[1] = StringToFloat(arg);
		GetCmdArg(3, arg, 16);
		vPos[2] = StringToFloat(arg);
	}
	else if( args == 1 )
	{
		GetCmdArg(1, arg, 16);
		int entity = StringToInt(arg);
		if( IsValidEntity(entity) )
		{
			GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPos);
			vPos[2] += 20.0;
			TeleportEntity(client, vPos, NULL_VECTOR, NULL_VECTOR);
		}
	}
	else
	{
		SetTeleportEndPoint(client, vPos);
	}
	TeleportEntity(client, vPos, NULL_VECTOR, NULL_VECTOR);
	return Plugin_Handled;
}

public Action CmdAnim(int client, int args)
{
	CreateTimer(0.5, tmrAnim, GetClientUserId(client), TIMER_REPEAT);
	return Plugin_Handled;
}

public Action tmrAnim(Handle timer, any client)
{
	static int animCount;
	animCount++;
	if( animCount <= 6 && (client = GetClientOfUserId(client)) && IsClientInGame(client) )
	{
		int seq = GetEntProp(client, Prop_Send, "m_nSequence");
		PrintToChat(client, "[SM] Anim %d", seq);
		return Plugin_Continue;
	}
	animCount = 0;
	return Plugin_Stop;
}



// ====================================================================================================
//					COMMANDS - ENTITIES - sm_del, sm_ent, sm_box, sm_find, sm_count, sm_modlist
// ====================================================================================================
public Action CmdDel(int client, int args)
{
	if( !client ) return Plugin_Handled;
	int entity = GetClientAimTarget(client, false);
	if( entity != -1 )
		AcceptEntityInput(entity, "kill");
	return Plugin_Handled;
}

public Action CmdEnt(int client, int args)
{
	if( !client ) return Plugin_Handled;
	int entity = GetClientAimTarget(client, false);
	if( entity != -1 )
	{
		char sName[64], sClass[64];
		GetEdictClassname(entity, sClass, 64);
		GetEntPropString(entity, Prop_Data, "m_iName", sName, 64);
		
		char sModel[64];
		GetEntPropString(entity, Prop_Data, "m_ModelName", sModel, 64);
		
		int iHammerID;
		iHammerID = GetEntProp(entity, Prop_Data, "m_iHammerID");
		
		float vPos[3];
		// float vAng[3];
		GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vPos);
		// GetEntPropVector(entity, Prop_Data, "m_angRotation", vAng);
		
		PrintToChat(client, "\x05%d \x01Class: \x05%s \x01Targetname: \x05%s \x01Model: \x05%s \x01HammerID: \x05%d \x01Position: \x05%d %d %d", entity, sClass, sName, sModel, iHammerID, RoundFloat(vPos[0]), RoundFloat(vPos[1]), RoundFloat(vPos[2]));
	}
	return Plugin_Handled;
}

public Action CmdEntE(int client, int args)
{
	char sTemp[32];
	int entity;

	if( args == 1 )
	{
		GetCmdArg(1, sTemp, sizeof(sTemp));
		entity = StringToInt(sTemp);

		if( (entity < -1 && EntRefToEntIndex(entity) == INVALID_ENT_REFERENCE) || (entity >= MaxClients && IsValidEntity(entity) == false) )
		{
			ReplyToCommand(client, "[SM] Invalid Entity %d", entity);
			return Plugin_Handled;
		}
	}

	if( client && args == 0 )
	{
		entity = GetClientAimTarget(client, false);
		if( entity == -1 )
			return Plugin_Handled;
	}

	if( IsValidEntity(entity) )
	{
		char sName[64], sClass[64];
		GetEdictClassname(entity, sClass, 64);
		GetEntPropString(entity, Prop_Data, "m_iName", sName, 64);

		char sModel[64];
		GetEntPropString(entity, Prop_Data, "m_ModelName", sModel, 64);
		if( client )
			PrintToChat(client, "\x05%d \x01Class: \x05%s \x01Targetname: \x05%s \x01Model: \x05%s", entity, sClass, sName, sModel);
		else
			ReplyToCommand(client, "%d Class: %s Targetname: %s Model: %s", entity, sClass, sName, sModel);
	} else {
		ReplyToCommand(client, "[SM] Invalid Entity %d", entity);
	}
	return Plugin_Handled;
}

public Action CmdBox(int client, int args)
{
	char sTemp[32];
	int entity;

	if( args == 1 )
	{
		GetCmdArg(1, sTemp, sizeof(sTemp));
		entity = StringToInt(sTemp);

		if( entity == 0 || (entity < -1 && EntRefToEntIndex(entity) == INVALID_ENT_REFERENCE) || (entity >= 0 && IsValidEntity(entity) == false) )
			return Plugin_Handled;
	}
	else
	{
		entity = GetClientAimTarget(client, false);
		if( entity == -1 )
			return Plugin_Handled;
	}

	float vPos[3]; float vMins[3]; float vMaxs[3];

	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vPos);
	GetEntPropVector(entity, Prop_Send, "m_vecMaxs", vMaxs);
	GetEntPropVector(entity, Prop_Send, "m_vecMins", vMins);

	if( vMins[0] == vMaxs[0] && vMins[1] == vMaxs[1] && vMins[2] == vMaxs[2] )
	{
		vMins = view_as<float>({ -15.0, -15.0, -15.0 });
		vMaxs = view_as<float>({ 15.0, 15.0, 15.0 });
	}
	else
	{
		AddVectors(vPos, vMaxs, vMaxs);
		AddVectors(vPos, vMins, vMins);
	}

	float vPos1[3], vPos2[3], vPos3[3], vPos4[3], vPos5[3], vPos6[3];
	vPos1 = vMaxs;
	vPos1[0] = vMins[0];
	vPos2 = vMaxs;
	vPos2[1] = vMins[1];
	vPos3 = vMaxs;
	vPos3[2] = vMins[2];
	vPos4 = vMins;
	vPos4[0] = vMaxs[0];
	vPos5 = vMins;
	vPos5[1] = vMaxs[1];
	vPos6 = vMins;
	vPos6[2] = vMaxs[2];

	TE_SendBeam(vMaxs, vPos1);
	TE_SendBeam(vMaxs, vPos2);
	TE_SendBeam(vMaxs, vPos3);
	TE_SendBeam(vPos6, vPos1);
	TE_SendBeam(vPos6, vPos2);
	TE_SendBeam(vPos6, vMins);
	TE_SendBeam(vPos4, vMins);
	TE_SendBeam(vPos5, vMins);
	TE_SendBeam(vPos5, vPos1);
	TE_SendBeam(vPos5, vPos3);
	TE_SendBeam(vPos4, vPos3);
	TE_SendBeam(vPos4, vPos2);

	ReplyToCommand(client, "[Box] Displaying beams for 5 seconds on %d", entity);
	return Plugin_Handled;
}

void TE_SendBeam(const float vMins[3], const float vMaxs[3])
{
	TE_SetupBeamPoints(vMins, vMaxs, g_iLaserMaterial, g_iHaloMaterial, 0, 0, 5.0, 1.0, 1.0, 1, 0.0, { 255, 0, 0, 255 }, 0);
	TE_SendToAll();
}

public Action CmdFind(int client, int args)
{
	if( args > 0 )
	{
		char class[64], sName[64];
		float vPos[3];
		int offset, count, entity = -1;
		GetCmdArg(1, class, 64);

		while( count < 50 && (entity = FindEntityByClassname(entity, class)) != -1 )
		{
			GetEntPropString(entity, Prop_Data, "m_iName", sName, 64);

			offset = FindDataMapInfo(entity, "m_vecOrigin");

			if( offset != -1 )
			{
				GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vPos);

				if( client ) PrintToChat(client, "%d [%s] - %f %f %f", entity, sName, vPos[0], vPos[1], vPos[2]);
				else ReplyToCommand(client, "%d [%s] - %f %f %f", entity, sName, vPos[0], vPos[1], vPos[2]);
			}
			else
			{
				if( client ) PrintToChat(client, "%d (%d) [%s]", entity, EntRefToEntIndex(entity), sName);
				else ReplyToCommand(client, "%d (%d) [%s]", entity, EntRefToEntIndex(entity), sName);
			}
			count++;
		}
	}
	return Plugin_Handled;
}

public Action CmdFindName(int client, int args)
{
	if( args > 0 )
	{
		char sFind[64], sTemp[64], sName[64];
		GetCmdArg(1, sFind, 64);

		for( int i = 0; i < 4096; i++ )
		{
			if( IsValidEntity(i) )
			{
				if( i < 2048 || EntIndexToEntRef(i) != -1 )
				{
					GetEntPropString(i, Prop_Data, "m_iName", sName, 64);
					if( StrContains(sName, sFind, false) != -1 )
					{
						GetEntityClassname(i, sTemp, sizeof(sTemp));

						if( client ) PrintToChat(client, "%d [%s] %s", i, sTemp, sName);
						else ReplyToCommand(client, "%d [%s] %s", i, sTemp, sName);
					}
				}
			}
		}
	}
	return Plugin_Handled;
}

public Action CmdCount(int client, int args)
{
	int count;
	int tt;

	char sTemp[64];
	char sClass[512][32];
	int value[512];

	for( int i = 0; i < 4096; i++ )
	{
		if( IsValidEntity(i) && IsValidEdict(i) )
		{
			tt++;
			GetEdictClassname(i, sTemp, sizeof(sTemp));

			for( int x = 0; x < 256; x++ )
			{
				if( strcmp(sTemp, sClass[x]) == 0 )
				{
					value[x]++;
					break;
				}
				else if( x == count )
				{
					strcopy(sClass[count], 128, sTemp);
					value[count]++;
					count++;
					break;
				}
			}
		}
	}

	int add;

	char sPad[16];

	for( int x = 0; x < count; x++ )
	{
		IntToString(value[x], sPad, sizeof(sPad));
		Pad(sPad, sPad, sizeof(sPad));
		ReplyToCommand(client, "%s %s", sPad, sClass[x]);
		add += value[x];
	}

	ReplyToCommand(client, "Total: %d %d %d", count, tt, add);
	return Plugin_Handled;
}

void Pad(const char[] sTemp, char[] sTemp2, int size)
{
	int len = strlen(sTemp);
	strcopy(sTemp2, size, sTemp);

	for( int i = len; i < 3; i++ )
	{
		StrCat(sTemp2, size, " ");
	}
	StrCat(sTemp2, size, " ");
}

public Action CmdModList(int client, int args)
{
	int offset, count;
	char sTemp[64];
	char sClas[64];

	for( int i = 1; i < 4096; i++ )
	{
		if( IsValidEntity(i) && IsValidEdict(i) )
		{
			GetEdictClassname(i, sClas, sizeof(sClas));
			offset = FindDataMapInfo(i, "m_ModelName");
			if( offset != -1 )
			{
				GetEntPropString(i, Prop_Data, "m_ModelName", sTemp, 64);
				if( strcmp(sTemp, "") )
				{
					LogModels("%s - %s", sTemp, sClas);
					count++;
				}
			}
		}
	}

	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));
	ReplyToCommand(client, "[Models] Saved %d to \"/sourcemod/logs/models_%s.txt\"", count, sMap);
	return Plugin_Handled;
}



// ====================================================================================================
//					COMMANDS - ENTITY PROPERTIES - sm_prop, sm_propent, sm_propi
// ====================================================================================================
public Action CmdProp(int client, int args)
{
	if( client == 0 )
	{
		return Plugin_Handled;
	}
	else if( args < 1 || args > 2 )
	{
		PrintToChat(client, "[SM] Usage: sm_prop <property name> [value].");
	}
	else
	{
		int entity = GetClientAimTarget(client, false);
		if( entity == -1 )
			return Plugin_Handled;

		char sProp[64], sValue[64];
		GetCmdArg(1, sProp, sizeof(sProp));
		if( args == 2 )
			GetCmdArg(2, sValue, sizeof(sValue));

		PropertyValue(client, entity, args, sProp, sValue);
	}
	return Plugin_Handled;
}

public Action CmdPropEnt(int client, int args)
{
	if( client == 0 )
	{
		return Plugin_Handled;
	}
	else if( args < 2 || args > 3 )
	{
		PrintToChat(client, "[SM] Usage: sm_propent <entity index> <property name> [value].");
	}
	else
	{
		char sTemp[64], sProp[64], sValue[64];
		GetCmdArg(1, sTemp, sizeof(sTemp));
		GetCmdArg(2, sProp, sizeof(sProp));
		if( args == 3 )
			GetCmdArg(3, sValue, sizeof(sValue));

		int entity = StringToInt(sTemp);
		if( IsValidEntity(entity) )
		{
			PropertyValue(client, entity, args-1, sProp, sValue);
		}
	}
	return Plugin_Handled;
}

public Action CmdPropMe(int client, int args)
{
	if( client == 0 )
	{
		return Plugin_Handled;
	}
	else if( args < 1 || args > 2 )
		PrintToChat(client, "[SM] Usage: sm_propi <property name> [value].");
	else
	{
		char sProp[64], sValue[64];
		GetCmdArg(1, sProp, sizeof(sProp));
		if( args == 2 )
			GetCmdArg(2, sValue, sizeof(sValue));

		PropertyValue(client, client, args, sProp, sValue);
	}
	return Plugin_Handled;
}

void PropertyValue(int client, int entity, int args, const char sProp[64], const char sValue[64])
{
	char sClass[64], sValueTemp[64], sTemp[3][16];
	float vVec[3];
	PropFieldType proptype;
	GetEntityNetClass(entity, sClass, sizeof(sClass));



	// READ
	if( args == 1 )
	{
		// PROP SEND
		int offset = FindSendPropInfo(sClass, sProp, proptype);
		if( offset > 0 )
		{
			if( proptype == PropField_Integer )
			{
				PrintToChat(client, "\x05%d\x01) \x03Prop_Send\x01 integer \"%s\" \"%s\" is \x05%d", entity, sClass, sProp, GetEntProp(entity, Prop_Send, sProp));
			}
			else if( proptype == PropField_Entity )
			{
				PrintToChat(client, "\x05%d\x01) \x03Prop_Send\x01 entity \"%s\" \"%s\" is \x05%d", entity, sClass, sProp, GetEntPropEnt(entity, Prop_Send, sProp));
			}
			else if( proptype == PropField_Float )
			{
				PrintToChat(client, "\x05%d\x01) \x03Prop_Send\x01 float \"%s\" \"%s\" is \x05%f", entity, sClass, sProp, GetEntPropFloat(entity, Prop_Send, sProp));
			}
			else if( proptype == PropField_String || proptype == PropField_String_T )
			{
				GetEntPropString(entity, Prop_Send, sProp, sValueTemp, sizeof(sValueTemp));
				PrintToChat(client, "\x05%d\x01) \x03Prop_Send\x01 string \"%s\" \"%s\" is \x05%s", entity, sClass, sProp, sValueTemp);
			}
			else if( proptype == PropField_Vector )
			{
				GetEntPropVector(entity, Prop_Send, sProp, vVec);
				PrintToChat(client, "\x05%d\x01) \x03Prop_Send\x01 vector \"%s\" \"%s\" is \x05%f %f %f", entity, sClass, sProp, vVec[0], vVec[1], vVec[2]);
			}
			else
			{
				if( proptype == PropField_Unsupported )
					PrintToChat(client, "\x05%d\x01) \x03Prop_Send\x01 \"%s\" \"%s\" Error: PropField_Unsupported.", entity, sClass, sProp);
				else
					PrintToChat(client, "\x05%d\x01) \x03Prop_Send\x01 \"%s\" \"%s\" Unknown Error.", entity, sClass, sProp);
			}
		}


		// PROP DATA
		offset = FindDataMapInfo(entity, sProp, proptype);
		if( offset != -1 )
		{
			if( proptype == PropField_Integer )
			{
				PrintToChat(client, "\x05%d\x01) \x05Prop_Data\x01 integer \"%s\" \"%s\" is \x05%d", entity, sClass, sProp, GetEntProp(entity, Prop_Data, sProp));
			}
			else if( proptype == PropField_Entity )
			{
				PrintToChat(client, "\x05%d\x01) \x05Prop_Data\x01 entity \"%s\" \"%s\" is \x05%d", entity, sClass, sProp, GetEntPropEnt(entity, Prop_Data, sProp));
			}
			else if( proptype == PropField_Float )
			{
				PrintToChat(client, "\x05%d\x01) \x05Prop_Data\x01 float \"%s\" \"%s\" is \x05%f", entity, sClass, sProp, GetEntPropFloat(entity, Prop_Data, sProp));
			}
			else if( proptype == PropField_String || proptype == PropField_String_T )
			{
				GetEntPropString(entity, Prop_Data, sProp, sValueTemp, sizeof(sValueTemp));
				PrintToChat(client, "\x05%d\x01) \x05Prop_Data\x01 string \"%s\" \"%s\" is \x05%s", entity, sClass, sProp, sValueTemp);
			}
			else if( proptype == PropField_Vector )
			{
				GetEntPropVector(entity, Prop_Data, sProp, vVec);
				PrintToChat(client, "\x05%d\x01) \x05Prop_Data\x01 vector \"%s\" \"%s\" is \x05%f %f %f", entity, sClass, sProp, vVec[0], vVec[1], vVec[2]);
			}
			else
			{
				if( proptype == PropField_Unsupported )
					PrintToChat(client, "\x05%d\x01) \x05Prop_Data\x01 \"%s\" \"%s\" Error: PropField_Unsupported.", entity, sClass, sProp);
				else
					PrintToChat(client, "\x05%d\x01) \x05Prop_Data\x01 \"%s\" \"%s\" Unknown Error.", entity, sClass, sProp);
			}
		}
	}


	// WRITE
	else
	{
		// PROP SEND
		int offset = FindSendPropInfo(sClass, sProp, proptype);
		if( offset > 0 )
		{
			if( proptype == PropField_Integer )
			{
				int value = StringToInt(sValue);
				SetEntProp(entity, Prop_Send, sProp, value);
				PrintToChat(client, "\x05%d\x01) Set \x03Prop_Send\x01 integer \"%s\" \"%s\" to \x05%d", entity, sClass, sProp, value);
			}
			else if( proptype == PropField_Entity )
			{
				int value = StringToInt(sValue);
				SetEntPropEnt(entity, Prop_Send, sProp, value);
				PrintToChat(client, "\x05%d\x01) Set \x03Prop_Send\x01 entity \"%s\" \"%s\" to \x05%d", entity, sClass, sProp, value);
			}
			else if( proptype == PropField_Float )
			{
				float value = StringToFloat(sValue);
				SetEntPropFloat(entity, Prop_Send, sProp, value);
				PrintToChat(client, "\x05%d\x01) Set \x03Prop_Send\x01 float \"%s\" \"%s\" to \x05%f", entity, sClass, sProp, value);
			}
			else if( proptype == PropField_String || proptype == PropField_String_T )
			{
				SetEntPropString(entity, Prop_Send, sProp, sValue);
				PrintToChat(client, "\x05%d\x01) Set \x03Prop_Send\x01 string \"%s\" \"%s\" to \x05%s", entity, sClass, sProp, sValue);
			}
			else if( proptype == PropField_Vector )
			{
				ExplodeString(sValue, " ", sTemp, 3, 16);
				vVec[0] = StringToFloat(sTemp[0]);
				vVec[1] = StringToFloat(sTemp[1]);
				vVec[2] = StringToFloat(sTemp[2]);

				SetEntPropVector(entity, Prop_Send, sProp, vVec);
				PrintToChat(client, "\x05%d\x01) Set \x03Prop_Send\x01 vector \"%s\" \"%s\" to \x05%f %f %f", entity, sClass, sProp, vVec[0], vVec[1], vVec[2]);
			}
			else
			{
				if( proptype == PropField_Unsupported )
					PrintToChat(client, "\x05%d\x01) \x03Prop_Send\x01 \"%s\" \"%s\" Error: PropField_Unsupported.", entity, sClass, sProp);
				else
					PrintToChat(client, "\x05%d\x01) \x03Prop_Send\x01 \"%s\" \"%s\" Unknown Error.", entity, sClass, sProp);
			}
		}


		// PROP DATA
		offset = FindDataMapInfo(entity, sProp, proptype);
		if( offset != -1 )
		{
			if( proptype == PropField_Integer )
			{
				int value = StringToInt(sValue);
				SetEntProp(entity, Prop_Data, sProp, value);
				PrintToChat(client, "\x05%d\x01) Set \x05Prop_Data\x01 integer \"%s\" \"%s\" to \x05%d", entity, sClass, sProp, value);
			}
			else if( proptype == PropField_Entity )
			{
				int value = StringToInt(sValue);
				SetEntPropEnt(entity, Prop_Data, sProp, value);
				PrintToChat(client, "\x05%d\x01) Set \x05Prop_Data\x01 entity \"%s\" \"%s\" to \x05%d", entity, sClass, sProp, value);
			}
			else if( proptype == PropField_Float )
			{
				float value = StringToFloat(sValue);
				SetEntPropFloat(entity, Prop_Data, sProp, value);
				PrintToChat(client, "\x05%d\x01) Set \x05Prop_Data\x01 float \"%s\" \"%s\" to \x05%f", entity, sClass, sProp, value);
			}
			else if( proptype == PropField_String || proptype == PropField_String_T )
			{
				SetEntPropString(entity, Prop_Data, sProp, sValue);
				PrintToChat(client, "\x05%d\x01) Set \x05Prop_Data\x01 string \"%s\" \"%s\" to \x05%s", entity, sClass, sProp, sValue);
			}
			else if( proptype == PropField_Vector )
			{
				ExplodeString(sValue, " ", sTemp, 3, 16);
				vVec[0] = StringToFloat(sTemp[0]);
				vVec[1] = StringToFloat(sTemp[1]);
				vVec[2] = StringToFloat(sTemp[2]);

				SetEntPropVector(entity, Prop_Data, sProp, vVec);
				PrintToChat(client, "\x05%d\x01) Set \x05Prop_Data\x01 vector \"%s\" \"%s\" to \x05%f %f %f", entity, sClass, sProp, vVec[0], vVec[1], vVec[2]);
			}
			else
			{
				if( proptype == PropField_Unsupported )
					PrintToChat(client, "\x05%d\x01) \x05Prop_Data\x01 \"%s\" \"%s\" Error: PropField_Unsupported.", entity, sClass, sProp);
				else
					PrintToChat(client, "\x05%d\x01) \x05Prop_Data\x01 \"%s\" \"%s\" Unknown Error.", entity, sClass, sProp);
			}
		}
	}
}



// ====================================================================================================
//					COMMANDS - sm_input, sm_inputent
// ====================================================================================================
public Action CmdInput(int client, int args)
{
	if( !client ) return Plugin_Handled;
	if( args == 0  )
	{
		ReplyToCommand(client, "[Input] Usage: sm_input <input> [params]");
		return Plugin_Handled;
	}

	int entity = GetClientAimTarget(client, false);
	if( entity != -1 )
	{
		char sTemp[64];
		GetCmdArg(1, sTemp, sizeof(sTemp));

		if( args == 2 )
		{
			char sTemp2[64];
			GetCmdArg(2, sTemp2, sizeof(sTemp2));
			SetVariantString(sTemp2);
		}

		if( AcceptEntityInput(entity, sTemp) )
			ReplyToCommand(client, "[Input] Success!");
		else
			ReplyToCommand(client, "[Input] Failed!");
	}

	return Plugin_Handled;
}

public Action CmdInputEnt(int client, int args)
{
	if( !client ) return Plugin_Handled;
	if( args < 2 )
	{
		ReplyToCommand(client, "[InputEnt] Usage: sm_input <entity index|target name> <input> [params]");
		return Plugin_Handled;
	}

	char sTemp[64];
	GetCmdArg(1, sTemp, sizeof(sTemp));

	// new entity = StringToInt(sTemp);
	int entity;
	if( StringToIntEx(sTemp, entity) == 0 )
	{
		entity = FindByTargetName(sTemp);
		if( entity == -1 )
		{
			ReplyToCommand(client, "[InputEnt] Cannot find the specified targetname.");
			return Plugin_Handled;
		}
	}

	if( IsValidEntity(entity) )
	{
		GetCmdArg(2, sTemp, sizeof(sTemp));

		if( args == 3 )
		{
			char sTemp2[64];
			GetCmdArg(3, sTemp2, sizeof(sTemp2));
			SetVariantString(sTemp2);
		}

		if( AcceptEntityInput(entity, sTemp) )
			ReplyToCommand(client, "[InputEnt] Success!");
		else
			ReplyToCommand(client, "[InputEnt] Failed!");
	}

	return Plugin_Handled;
}

public Action CmdInputMe(int client, int args)
{
	if( !client ) return Plugin_Handled;
	if( args == 0 )
	{
		ReplyToCommand(client, "[InputMe] Usage: sm_inputme <input> [params]");
		return Plugin_Handled;
	}

	char sTemp[64];
	GetCmdArg(1, sTemp, sizeof(sTemp));

	if( args == 2 )
	{
		char sTemp2[64];
		GetCmdArg(2, sTemp2, sizeof(sTemp2));
		SetVariantString(sTemp2);
	}

	if( AcceptEntityInput(client, sTemp) )
		ReplyToCommand(client, "[InputMe] Success!");
	else
		ReplyToCommand(client, "[InputMe] Failed!");

	return Plugin_Handled;
}

int FindByTargetName(const char[] sTarget)
{
	char sName[64];
	for( int i = MaxClients + 1; i < 4096; i++ )
	{
		if( IsValidEntity(i) )
		{
			GetEntPropString(i, Prop_Data, "m_iName", sName, 64);
			if( strcmp(sTarget, sName) == 0 ) return i;
		}
	}
	return -1;
}



// ====================================================================================================
//					COMMANDS - sm_output, sm_outputent
// ====================================================================================================
public Action CmdOutput(int client, int args)
{
	if( !client ) return Plugin_Handled;
	if( args != 1 )
	{
		ReplyToCommand(client, "[Output] Usage: sm_output <input>");
		return Plugin_Handled;
	}

	int entity = GetClientAimTarget(client, false);
	if( entity != -1 )
	{
		char sTemp[64];
		GetCmdArg(1, sTemp, sizeof(sTemp));

		HookSingleEntityOutput(entity, sTemp, OutputCallback);
		ReplyToCommand(client, "[Output] Successfully hooked '%s'!", sTemp);

		for( int i = 0; i < MAX_OUTPUTS; i++ )
		{
			if( IsValidEntRef(g_iOutputs[i][0]) == false )
			{
				g_iOutputs[i][0] = EntIndexToEntRef(entity);
				g_iOutputs[i][1] = client;
				strcopy(g_sOutputs[i], 64, sTemp);
				break;
			}
		}
	}

	return Plugin_Handled;
}

public Action CmdOutputEnt(int client, int args)
{
	if( !client ) return Plugin_Handled;
	if( args != 2 )
	{
		ReplyToCommand(client, "[OutputEnt] Usage: sm_output <entity index> <input>");
		return Plugin_Handled;
	}

	char sTemp[64];
	GetCmdArg(1, sTemp, sizeof(sTemp));
	int entity = StringToInt(sTemp);

	if( IsValidEntity(entity) )
	{
		GetCmdArg(2, sTemp, sizeof(sTemp));

		HookSingleEntityOutput(entity, sTemp, OutputCallback);
		ReplyToCommand(client, "[OutputEnt] Successfully hooked '%s'!", sTemp);

		for( int i = 0; i < MAX_OUTPUTS; i++ )
		{
			if( IsValidEntRef(g_iOutputs[i][0]) == false )
			{
				g_iOutputs[i][0] = EntIndexToEntRef(entity);
				g_iOutputs[i][1] = client;
				strcopy(g_sOutputs[i], 64, sTemp);
				break;
			}
		}
	}

	return Plugin_Handled;
}

public Action CmdOutputMe(int client, int args)
{
	if( !client ) return Plugin_Handled;
	if( args != 1 )
	{
		ReplyToCommand(client, "[OutputMe] Usage: sm_outputme <input>");
		return Plugin_Handled;
	}

	char sTemp[64];
	GetCmdArg(1, sTemp, sizeof(sTemp));

	HookSingleEntityOutput(client, sTemp, OutputCallback);
	ReplyToCommand(client, "[OutputMe] Successfully hooked '%s'!", sTemp);

	for( int i = 0; i < MAX_OUTPUTS; i++ )
	{
		if( IsValidEntRef(g_iOutputs[i][0]) == false )
		{
			g_iOutputs[i][0] = client;
			g_iOutputs[i][1] = client;
			strcopy(g_sOutputs[i], 64, sTemp);
			break;
		}
	}
	return Plugin_Handled;
}

public void OutputCallback(const char[] output, int caller, int activator, float delay)
{
	PrintToChatAll("\x01[Output] \x05%s \x01Caller= \x05%d \x01Activator= \x05%d", output, caller, activator);
}

public Action CmdOutputStop(int client, int args)
{
	for( int i = 0; i < MAX_OUTPUTS; i++ )
	{
		if( (g_iOutputs[i][0] != 0 && g_iOutputs[i][0] <= MaxClients) || IsValidEntRef(g_iOutputs[i][0]) == true )
		{
			UnhookSingleEntityOutput(g_iOutputs[i][0], g_sOutputs[i], OutputCallback);
			g_iOutputs[i][0] = 0;
			g_iOutputs[i][1] = 0;
			strcopy(g_sOutputs[i], 64, "");
		}
	}
	return Plugin_Handled;
}



// ====================================================================================================
//					COMMANDS - CREATE - sm_part, sm_parti
// ====================================================================================================
public Action CmdPart(int client, int args)
{
	if( !client ) return Plugin_Handled;
	char sBuff[32];
	GetCmdArg(1, sBuff, sizeof(sBuff));

	char sAttachment[12];
	int entity;
	FormatEx(sAttachment, sizeof(sAttachment), "forward");
	entity = DisplayParticle(sBuff, view_as<float>({ 0.0, 0.0, 0.0 }), view_as<float>({ 0.0, 0.0, 0.0 }), client, sAttachment);

	SetVariantString("OnUser1 !self:Kill::5.0:1");
	AcceptEntityInput(entity, "AddOutput");
	AcceptEntityInput(entity, "FireUser1");

	return Plugin_Handled;
}

public Action CmdPart2(int client, int args)
{
	if( !client ) return Plugin_Handled;
	char sBuff[32];
	float vPos[3];
	GetCmdArg(1, sBuff, sizeof(sBuff));

	SetTeleportEndPoint(client, vPos);
	int entity = DisplayParticle(sBuff, vPos, NULL_VECTOR);

	SetVariantString("OnUser1 !self:Kill::5.0:1");
	AcceptEntityInput(entity, "AddOutput");
	AcceptEntityInput(entity, "FireUser1");

	return Plugin_Handled;
}



// ====================================================================================================
//					COMMANDS - L4D2 - sm_lobby, sm_ledge, sm_spit, sm_alloff, sm_director, sm_hold, sm_halt, sm_c, sm_r, sm_s, sm_v
// ====================================================================================================
public Action CmdLobby(int client, int args)
{
	if( !client ) return Plugin_Handled;
	FakeClientCommand(client, "callvote ReturnToLobby");
	return Plugin_Handled;
}

public Action CmdLedge(int client, int args)
{
	if( !client ) return Plugin_Handled;

	if( args == 0 )
	{
		g_iLedge[client] = !g_iLedge[client];

		if( g_iLedge[client] )
			AcceptEntityInput(client, "DisableLedgeHang");
		else
			AcceptEntityInput(client, "EnableLedgeHang");

		PrintToChat(client, "[LedgeGrab] %s", g_iLedge[client] ? "Disabled" : "Enabled");
	}
	else
	{
		char arg1[32];
		GetCmdArg(1, arg1, sizeof(arg1));

		char target_name[MAX_TARGET_LENGTH];
		int target_list[MAXPLAYERS], target_count;
		bool tn_is_ml;

		if( (target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}

		int target;
		for( int i = 0; i < target_count; i++ )
		{
			target = target_list[target_count];

			g_iLedge[target] = !g_iLedge[target];

			if( g_iLedge[target] )
				AcceptEntityInput(target, "DisableLedgeHang");
			else
				AcceptEntityInput(target, "EnableLedgeHang");

			PrintToChat(client, "[LedgeGrab] %s for %N", g_iLedge[target] ? "Disabled" : "Enabled", target);
		}
	}

	return Plugin_Handled;
}

public Action CmdSpit(int client, int args)
{
	if( !client ) return Plugin_Handled;


	if( args == 0 )
	{
		int entity = g_iEntsSpit[client];
		if( entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
		{
			AcceptEntityInput(entity, "Kill");
		}
		else
		{
			char sAttachment[12];
			FormatEx(sAttachment, sizeof(sAttachment), "forward");
			g_iEntsSpit[client] = DisplayParticle("spitter_slime_trail", view_as<float>({ 0.0, 0.0, 0.0 }), view_as<float>({ 0.0, 0.0, 0.0 }), client, sAttachment);
			g_iEntsSpit[client] = EntIndexToEntRef(g_iEntsSpit[client]);
		}
	}
	else
	{
		char arg1[32];
		GetCmdArg(1, arg1, sizeof(arg1));

		char target_name[MAX_TARGET_LENGTH];
		int target_list[MAXPLAYERS], target_count;
		bool tn_is_ml;

		if( (target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}

		char sAttachment[12];
		int entity; int target;
		for( int i = 0; i < target_count; i++ )
		{
			target = target_list[target_count];

			entity = g_iEntsSpit[target];
			if( entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
			{
				AcceptEntityInput(entity, "Kill");
			}
			else
			{
				FormatEx(sAttachment, sizeof(sAttachment), "forward");
				g_iEntsSpit[target] = DisplayParticle("spitter_slime_trail", view_as<float>({ 0.0, 0.0, 0.0 }), view_as<float>({ 0.0, 0.0, 0.0 }), target, sAttachment);
				g_iEntsSpit[target] = EntIndexToEntRef(g_iEntsSpit[target]);

				PrintToChat(client, "[Spit] %s for %N", g_iLedge[target] ? "Removed" : "Added", target);
			}
		}
	}

	return Plugin_Handled;
}

public Action CmdAll(int client, int args)
{
	if( g_bAll )
	{
		g_bAll = false;
		g_bHold = false;
		g_bDirector = true;

		ExecuteCheatCommand("director_start");
		ExecuteCheatCommand("sb_hold_position", "0");
		z_background_limit.RestoreDefault();
		z_common_limit.RestoreDefault();
		z_minion_limit.RestoreDefault();

		if( g_iGAMETYPE == GAME_L4D2 )
		{
			z_boomer_limit.RestoreDefault();
			z_charger_limit.RestoreDefault();
			z_hunter_limit.RestoreDefault();
			z_jockey_limit.RestoreDefault();
			z_smoker_limit.RestoreDefault();
			z_spitter_limit.RestoreDefault();
		}
		if( client ) PrintToChat(client, "\x04[All]\x01 Enabled!");
		else ReplyToCommand(client, "[All] Enabled!");
	}
	else
	{
		g_bAll = true;
		g_bHold = true;
		g_bDirector = false;

		ExecuteCheatCommand("director_stop");
		ExecuteCheatCommand("sb_hold_position", "1");
		z_background_limit.IntValue = 0;
		z_common_limit.IntValue = 0;
		z_minion_limit.IntValue = 0;
		if( g_iGAMETYPE == GAME_L4D2 )
		{
			z_boomer_limit.IntValue = 0;
			z_charger_limit.IntValue = 0;
			z_hunter_limit.IntValue = 0;
			z_jockey_limit.IntValue = 0;
			z_smoker_limit.IntValue = 0;
			z_spitter_limit.IntValue = 0;
		}
		if( client ) PrintToChat(client, "\x04[All]\x01 Disabled!");
		else ReplyToCommand(client, "[All] Disabled!");
	}

	return Plugin_Handled;
}

public Action CmdDirector(int client, int args)
{
	if( g_bDirector )
	{
		ExecuteCheatCommand("director_stop");
		if( client ) PrintToChat(client, "\x04[AI Director]\x01 disabled!");
		else ReplyToCommand(client, "[AI Director] disabled!");
	}
	else
	{
		ExecuteCheatCommand("director_start");
		if( client ) PrintToChat(client, "\x04[AI Director]\x01 enabled!");
		else ReplyToCommand(client, "[AI Director] enabled!");
	}
	g_bDirector = !g_bDirector;
	return Plugin_Handled;
}

public Action CmdHold(int client, int args)
{
	if( g_bHold )
	{
		ExecuteCheatCommand("sb_hold_position", "0");
		g_bHold = false;
		if( client ) PrintToChat(client, "\x04[sb_hold_position]\x01 0");
		else ReplyToCommand(client, "[sb_hold_position] 0");
	}
	else
	{
		ExecuteCheatCommand("sb_hold_position", "1");
		g_bHold = true;
		if( client ) PrintToChat(client, "\x04[sb_hold_position]\x01 1");
		else ReplyToCommand(client, "[sb_hold_position] 1");
	}
	return Plugin_Handled;
}

public Action CmdHalt(int client, int args)
{
	if( g_bHalt )
	{
		ExecuteCheatCommand("sb_stop", "0");
		if( client ) PrintToChat(client, "\x04[sb_stop]\x01 0");
		else ReplyToCommand(client, "[sb_stop] 0");
	}
	else
	{
		ExecuteCheatCommand("sb_stop", "1");
		if( client ) PrintToChat(client, "\x04[sb_stop]\x01 1");
		else ReplyToCommand(client, "[sb_stop] 1");
	}
	g_bHalt = !g_bHalt;
	return Plugin_Handled;
}

public Action CmdNB(int client, int args)
{
	if( g_bNB )
	{
		ExecuteCheatCommand("nb_stop", "0");
		if( client ) PrintToChat(client, "\x04[nb_stop]\x01 0");
		else ReplyToCommand(client, "[nb_stop] 0");
	}
	else
	{
		ExecuteCheatCommand("nb_stop", "1");
		if( client ) PrintToChat(client, "\x04[nb_stop]\x01 1");
		else ReplyToCommand(client, "[nb_stop] 1");
	}
	g_bNB = !g_bNB;
	return Plugin_Handled;
}

// Code thanks to: "Don't Fear The Reaper"
public Action CmdSlayCommon(int client, int args)
{
	int count, i_EdictIndex = -1;
	while( (i_EdictIndex = FindEntityByClassname(i_EdictIndex, "infected")) != INVALID_ENT_REFERENCE )
	{
		AcceptEntityInput(i_EdictIndex, "Kill");
		count++;
	}

	PrintToChat(client, "[SM] Slayed %d common infected.", count);
	return Plugin_Handled;
}

// Code thanks to: "Don't Fear The Reaper"
public Action CmdSlayWitches(int client, int args)
{
	int count, i_EdictIndex = -1;
	while( (i_EdictIndex = FindEntityByClassname(i_EdictIndex, "witch")) != INVALID_ENT_REFERENCE )
	{
		AcceptEntityInput(i_EdictIndex, "Kill");
		count++;
	}

	if( count == 1 )
		PrintToChat(client, "[SM] Slayed 1 witch.");
	else
		PrintToChat(client, "[SM] Slayed %d witches", count);
	return Plugin_Handled;
}

public Action CmdCoop(int client, int args)
{
	mp_gamemode.SetString("coop");

	if( client ) PrintToChat(client, "\x04[GameMode]\x01 Gamemode set to coop!");
	else ReplyToCommand(client, "[GameMode] Gamemode set to coop!");
	return Plugin_Handled;
}

public Action CmdRealism(int client, int args)
{
	mp_gamemode.SetString("realism");

	if( client ) PrintToChat(client, "\x04[GameMode]\x01 Gamemode set to realism!");
	else ReplyToCommand(client, "[GameMode] Gamemode set to realism!");
	return Plugin_Handled;
}

public Action CmdSurvival(int client, int args)
{
	mp_gamemode.SetString("survival");

	if( client ) PrintToChat(client, "\x04[GameMode]\x01 Gamemode set to survival!");
	else ReplyToCommand(client, "[GameMode] Gamemode set to survival!");
	return Plugin_Handled;
}

public Action CmdVersus(int client, int args)
{
	if( g_iGAMETYPE == GAME_L4D2 )
		ExecuteCheatCommand("sb_all_bot_game", "1");
	else
		ExecuteCheatCommand("sb_all_bot_team", "1");
	mp_gamemode.SetString("versus");

	if( client ) PrintToChat(client, "\x04[GameMode]\x01 Gamemode set to versus!");
	else ReplyToCommand(client, "[GameMode] Gamemode set to versus!");
	return Plugin_Handled;
}



// ====================================================================================================
//					COMMANDS - L4D2 & CSS - sm_nv
// ====================================================================================================
public Action CmdNV(int client, int args)
{
	if( !client ) return Plugin_Handled;

	if( args == 0 )
	{
		SetEntProp(client, Prop_Send, "m_bNightVisionOn", !GetEntProp(client, Prop_Send, "m_bNightVisionOn"));
	}
	else
	{
		char arg1[32];
		GetCmdArg(1, arg1, sizeof(arg1));

		char target_name[MAX_TARGET_LENGTH];
		int target_list[MAXPLAYERS], target_count;
		bool tn_is_ml;

		if( (target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE|COMMAND_FILTER_NO_BOTS,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}

		int target, nv;
		for( int i = 0; i < target_count; i++ )
		{
			target = target_list[target_count];
			nv = !GetEntProp(target, Prop_Send, "m_bNightVisionOn");
			SetEntProp(target, Prop_Send, "m_bNightVisionOn", nv);
			ReplyToCommand(client, "Turned %s Nightvision for %N", nv ? "On" : "Off", target);
		}
	}
	return Plugin_Handled;
}



// ====================================================================================================
//					COMMANDS - CSS - sm_bots, sm_money
// ====================================================================================================
public Action CmdBots(int client, int args)
{
	ShowBotMenu(client);
	return Plugin_Handled;
}

void ShowBotMenu(int client)
{
	if( IsClientInGame(client) )
	{
		Menu menu = new Menu(BotMenuHandler);
		menu.AddItem("1", "10 CT");
		menu.AddItem("2", "10 T");
		menu.AddItem("3", "Add CT");
		menu.AddItem("4", "Add T");
		menu.AddItem("5", "Kick CT");
		menu.AddItem("6", "Kick T");
		menu.AddItem("7", "Kick all");
		menu.SetTitle("Bots Control:");
		menu.ExitBackButton = true;
		menu.Display(client, MENU_TIME_FOREVER);
	}
}

public int BotMenuHandler(Menu menu, MenuAction action, int client, int index)
{
	if( action == MenuAction_End )
		delete menu;
	else if( action == MenuAction_Select )
	{
		if( index == 0 )
			ServerCommand("bot_kick; bot_join_team ct; bot_quota 10"); // bot_prefix CT;
		else if( index == 1 )
			ServerCommand("bot_kick; bot_join_team t; bot_quota 10"); // bot_prefix T;
		else if( index == 2 )
			ServerCommand("bot_add ct");
		else if( index == 3 )
			ServerCommand("bot_add t");
		else if( index == 4 )
			ServerCommand("bot_kick ct");
		else if( index == 5 )
			ServerCommand("bot_kick t");
		else if( index == 6 )
			ServerCommand("bot_kick");
		ShowBotMenu(client);
	}
	else if( action == MenuAction_Cancel && index == MenuCancel_ExitBack )
		ShowBotMenu(client);
}

public Action CmdMoney(int client, int args)
{
	if( !client ) return Plugin_Handled;

	ShowPlayerList(client);
	return Plugin_Handled;
}

void ShowPlayerList(int client)
{
	if( client && IsClientInGame(client) )
	{
		char sTempA[16], sTempB[MAX_NAME_LENGTH];
		Menu menu = new Menu(PlayerListMenur);

		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsValidClient(i) )
			{
				IntToString(GetClientUserId(i), sTempA, sizeof(sTempA));
				GetClientName(i, sTempB, sizeof(sTempB));
				menu.AddItem(sTempA, sTempB);
			}
		}

		menu.SetTitle("Give money to:");
		menu.ExitBackButton = true;
		menu.Display(client, MENU_TIME_FOREVER);
	}
}

public int PlayerListMenur(Menu menu, MenuAction action, int client, int index)
{
	if( action == MenuAction_End )
		delete menu;
	else if( action == MenuAction_Select )
	{
		char sTemp[32];
		menu.GetItem(index, sTemp, sizeof(sTemp));
		int target = StringToInt(sTemp);
		target = GetClientOfUserId(target);

		if( IsValidClient(target) )
		{
			SetEntProp(target, Prop_Send, "m_iAccount", 16000);
		}

		ShowPlayerList(client);
	}
	else if( action == MenuAction_Cancel && index == MenuCancel_ExitBack )
		ShowPlayerList(client);
}



// ====================================================================================================
//					STUFF
// ====================================================================================================
void ExecuteCheatCommand(const char[] command, const char[] value = "")
{
	int flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT); // Remove cheat flag
	ServerCommand("%s %s", command, value);
	ServerExecute();
	SetCommandFlags(command, flags);
}

void PrecacheParticle(const char[] sEffectName)
{
	static int table = INVALID_STRING_TABLE;

	if( table == INVALID_STRING_TABLE )
	{
		table = FindStringTable("ParticleEffectNames");
	}

	if( FindStringIndex(table, sEffectName) == INVALID_STRING_INDEX )
	{
		bool save = LockStringTables(false);
		AddToStringTable(table, sEffectName);
		LockStringTables(save);
	}
}

int DisplayParticle(char[] sParticle, float vPos[3], float fAng[3], int client = 0, const char[] sAttachment = "")
{
	int entity = CreateEntityByName("info_particle_system");

	if( entity != -1 && IsValidEdict(entity) )
	{
		DispatchKeyValue(entity, "effect_name", sParticle);
		DispatchSpawn(entity);
		ActivateEntity(entity);
		AcceptEntityInput(entity, "start");

		if( client )
		{
			SetVariantString("!activator");
			AcceptEntityInput(entity, "SetParent", client);

			if( strlen(sAttachment) != 0 )
			{
				SetVariantString(sAttachment);
				AcceptEntityInput(entity, "SetParentAttachment");
			}
		}

		TeleportEntity(entity, vPos, fAng, NULL_VECTOR);

		return entity;
	}

	return 0;
}

bool IsValidClient(int client)
{
	if( !client || !IsClientInGame(client) || !IsPlayerAlive(client) )
		return false;
	return true;
}

bool SetTeleportEndPoint(int client, float vPos[3])
{
	float vBuffer[3], vAng[3];
	GetClientEyePosition(client, vPos);
	GetClientEyeAngles(client, vAng);

	Handle trace = TR_TraceRayFilterEx(vPos, vAng, MASK_SHOT, RayType_Infinite, _TraceFilter);

	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(vPos, trace);
		GetAngleVectors(vAng, vBuffer, NULL_VECTOR, NULL_VECTOR);
		vPos[0] += vBuffer[0] * -10;
		vPos[1] += vBuffer[1] * -10;
		vPos[2] += vBuffer[2] * -10;
	}
	else
	{
		delete trace;
		return false;
	}
	delete trace;
	return true;
}

public bool _TraceFilter(int entity, int contentsMask)
{
	return entity > MaxClients || !entity;
}

bool IsValidEntRef(int iEnt)
{
	if( iEnt && EntRefToEntIndex(iEnt) != INVALID_ENT_REFERENCE )
		return true;
	return false;
}

void LogModels(const char[] format, any ...)
{
	char buffer[512];
	VFormat(buffer, sizeof(buffer), format, 2);

	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));

	char FileName[PLATFORM_MAX_PATH];
	GetCurrentMap(sMap, sizeof(sMap));
	BuildPath(Path_SM, FileName, sizeof(FileName), "logs/models_%s.txt", sMap);
	File file = OpenFile(FileName, "a+");
	file.WriteLine("%s", buffer);
	FlushFile(file);
	delete file;
}

void LogCustom(const char[] format, any ...)
{
	char buffer[512];
	VFormat(buffer, sizeof(buffer), format, 2);

	File file;
	char FileName[256], sTime[256];
	FormatTime(sTime, sizeof(sTime), "%Y%m%d");
	BuildPath(Path_SM, FileName, sizeof(FileName), "logs/sm_logit.txt");
	file = OpenFile(FileName, "a+");
	FormatTime(sTime, sizeof(sTime), "%d-%b-%Y %H:%M:%S");
	file.WriteLine("%s  %s", sTime, buffer);
	FlushFile(file);
	delete file;
}