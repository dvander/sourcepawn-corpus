#pragma semicolon 1
//------------------------------------------------------------------------------------------------------------------------------------
#include <sourcemod>
#include <sdktools>
#include <geoip>
#undef REQUIRE_EXTENSIONS
#include <cstrike>
#include <tf2_stocks>
#include <tf2>
#include <smlib>
#undef REQUIRE_PLUGIN
#include <adminmenu>
//------------------------------------------------------------------------------------------------------------------------------------
#include <advcommands.inc>
//------------------------------------------------------------------------------------------------------------------------------------
#define PLUGIN_VERSION "0.19"
//------------------------------------------------------------------------------------------------------------------------------------
public Plugin:myinfo = 
{
	name = "Advanced admin commands", 
	author = "3sigma | TnTSCS | Dark-Skript", // aka X@IDER some updates by TnTSCS aKa ClarkKent
	description = "Many useful commands", 
	version = PLUGIN_VERSION, 
	url = "http://www.sourcemod.net/"
};
//------------------------------------------------------------------------------------------------------------------------------------
// Some custom defines
// Uncomment if you..
//------------------------------------------------------------------------------------------------------------------------------------
// don't want menu items
//#define NOMENU

// would preffer SDKCalls instead of natives
//#define FORCESDK

// want lswap/lexch and ATB work on death in CS:S
//#define FORCEDEAD

// want to handle chat motd phrase
//#define CHATMOTD

// want to force using old AV
//#define OLDAV

// want to allow some actions to work on dead players/spectators (can be unsafe!!!)
// WARNING!!! If both enabled any retard with admin rights CAN CRASH YOUR SERVER
//#define ALLOWDEAD
//#define ALLOWSPEC
//------------------------------------------------------------------------------------------------------------------------------------
#define SPEC	1
#define TEAM1	2
#define TEAM2	3
//------------------------------------------------------------------------------------------------------------------------------------
#if defined ALLOWSPEC
#define FILTER_REAL		0
#else
#define FILTER_REAL		COMMAND_FILTER_CONNECTED
#endif
//------------------------------------------------------------------------------------------------------------------------------------
#if defined ALLOWDEAD
#define FILTER_ALIVE	FILTER_REAL
#else
#define FILTER_ALIVE	COMMAND_FILTER_ALIVE
#endif
//------------------------------------------------------------------------------------------------------------------------------------
// Colors
//------------------------------------------------------------------------------------------------------------------------------------
#define YELLOW               "\x01"
#define NAME_TEAMCOLOR       "\x02"
#define TEAMCOLOR            "\x03"
#define GREEN                "\x04"
//------------------------------------------------------------------------------------------------------------------------------------
// Games
//------------------------------------------------------------------------------------------------------------------------------------
#define GAME_UNKNOWN	0
#define GAME_CSTRIKE	1
#define GAME_DOD		2
#define GAME_TF2		4
#define GAME_HL2MP		8
#define GAME_LEFT4DEAD	16
#define GAME_LEFT4DEAD2	32
#define GAME_CSGO		64
//------------------------------------------------------------------------------------------------------------------------------------
// Sizes
//------------------------------------------------------------------------------------------------------------------------------------
#define MAX_CLIENTS		129
#define MAX_ID			32
#define MAX_NAME		96
#define MAX_BUFF_SM		128
#define MAX_BUFF		512
//------------------------------------------------------------------------------------------------------------------------------------
// For blink
#define	CLIENTWIDTH		35.0
#define	CLIENTHEIGHT	90.0
//------------------------------------------------------------------------------------------------------------------------------------
// Variables
//------------------------------------------------------------------------------------------------------------------------------------
new Float:coords[MAX_CLIENTS][3];
new NewTeam[MAX_CLIENTS];
//------------------------------------------------------------------------------------------------------------------------------------
new game = GAME_UNKNOWN;
new bool:g_late = false;
new Handle:hTopMenu = INVALID_HANDLE;
//------------------------------------------------------------------------------------------------------------------------------------
new Handle:hGameConf = INVALID_HANDLE;
//new Handle:hSetModel = INVALID_HANDLE;
new Handle:hDrop = INVALID_HANDLE;
new Handle:hRespawn = INVALID_HANDLE;
new Handle:hDisarm = INVALID_HANDLE;
//------------------------------------------------------------------------------------------------------------------------------------
new Handle:sv_alltalk = INVALID_HANDLE;
new Handle:mp_atb = INVALID_HANDLE;
new Handle:mp_ltm = INVALID_HANDLE;
new Handle:hostname = INVALID_HANDLE;
new Handle:hSilent = INVALID_HANDLE;
new Handle:hNotify = INVALID_HANDLE;
new Handle:hLog = INVALID_HANDLE;
new Handle:hMapcfg = INVALID_HANDLE;
new Handle:hMe = INVALID_HANDLE;
new Handle:hMotd = INVALID_HANDLE;
new Handle:hCAEnable = INVALID_HANDLE;
new Handle:hSProt = INVALID_HANDLE;
new Handle:hREProt = INVALID_HANDLE;
new Handle:hBanlog = INVALID_HANDLE;
new Handle:hAdmList = INVALID_HANDLE;
new Handle:hAdmVision = INVALID_HANDLE;
new Handle:hAdmFlags = INVALID_HANDLE;
new Handle:hAdmImm = INVALID_HANDLE;
//------------------------------------------------------------------------------------------------------------------------------------
// Cvars' values
//------------------------------------------------------------------------------------------------------------------------------------
new bool:g_bSilent = false, bool:g_bMapcfg = false, bool:g_bLog = false;
new bool:g_bMe = false, g_bREProt = false;
new bool:g_bATB = false, g_bAlltalk = false;
new g_iNotify = 0, g_iCAEnable = 0, g_iBanlog = 0, g_iAdmVision = 0, g_iAdmFlags = 0, g_iAdmImm = 0;
new g_iLTM = 0, g_iAdmList = 0;
new Float:g_fSProt = 0.0;
new String:g_sBanlog[PLATFORM_MAX_PATH];
new bool:g_oldAV = false;
//------------------------------------------------------------------------------------------------------------------------------------
// Teams
//------------------------------------------------------------------------------------------------------------------------------------
new String:t_models[4][PLATFORM_MAX_PATH] =
{
	"models/player/t_phoenix.mdl", 
	"models/player/t_leet.mdl", 
	"models/player/t_arctic.mdl", 
	"models/player/t_guerilla.mdl"
};
//------------------------------------------------------------------------------------------------------------------------------------
new String:ct_models[4][PLATFORM_MAX_PATH] =
{
	"models/player/ct_urban.mdl", 
	"models/player/ct_gsg9.mdl", 
	"models/player/ct_sas.mdl", 
	"models/player/ct_gign.mdl"
};
//------------------------------------------------------------------------------------------------------------------------------------
new String:teams[4][16] = 
{
	"N/A", 
	"SPEC", 
	"T", 
	"CT"
};
//------------------------------------------------------------------------------------------------------------------------------------
// Functions
//------------------------------------------------------------------------------------------------------------------------------------
abs(val)
{
	return (val<0)?-val:val;
}
//------------------------------------------------------------------------------------------------------------------------------------
public PrintToChatEx(from, to, const String:format[], any:...)
{
	decl String:message[MAX_BUFF]; message[0] = '\0';
	VFormat(message, sizeof(message), format, 4);
	
	if ((game == GAME_DOD) || !to)
	{
		PrintToChat(to, message);
		return;
	}

	new Handle:hBf = StartMessageOne("SayText2", to);
	if (hBf != INVALID_HANDLE)
	{
		if (GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available && GetUserMessageType() == UM_Protobuf)
		{
			PbSetInt(hBf, "ent_idx", from);
			PbSetBool(hBf, "chat", true);
			PbSetString(hBf, "msg_name", message);
			PbAddString(hBf, "params", "");
			PbAddString(hBf, "params", "");
			PbAddString(hBf, "params", "");
			PbAddString(hBf, "params", "");
		}
		else
		{
			BfWriteByte(hBf, from);
			BfWriteByte(hBf, true);
			BfWriteString(hBf, message);
		}
	
		EndMessage();
	}
}
//------------------------------------------------------------------------------------------------------------------------------------
public PrintToChatAllEx(from, const String:format[], any:...)
{
	decl String:message[MAX_BUFF];
	VFormat(message, sizeof(message), format, 3);
	
	if (game == GAME_DOD)
	{
		PrintToChatAll(message);
		return;
	}

	new Handle:hBf = StartMessageAll("SayText2");
	if (hBf != INVALID_HANDLE)
	{
		if (GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available && GetUserMessageType() == UM_Protobuf)
		{
			PbSetInt(hBf, "ent_idx", from);
			PbSetBool(hBf, "chat", true);
			PbSetString(hBf, "msg_name", message);
			PbAddString(hBf, "params", "");
			PbAddString(hBf, "params", "");
			PbAddString(hBf, "params", "");
			PbAddString(hBf, "params", "");
		}
		else
		{
			BfWriteByte(hBf, from);
			BfWriteByte(hBf, true);
			BfWriteString(hBf, message);
		}
	
		EndMessage();
	}
}
//------------------------------------------------------------------------------------------------------------------------------------
public AdvNotify(Handle:plugin, numParams)
{
	if (g_bSilent) return;

	new admin = GetNativeCell(1);
	new target = GetNativeCell(2);
	decl String:admname[MAX_NAME], String:tagname[MAX_NAME];

	GetClientName(target, tagname, sizeof(tagname));

	for (new i = 1; i <= MaxClients; i++)
	if (IsClientInGame(i) && !IsFakeClient(i) && FormatActivitySource(admin, i, admname, sizeof(admname)))
	{
		Call_StartFunction(INVALID_HANDLE, PrintToChatEx);
		Call_PushCell(admin);
		Call_PushCell(i);
		Call_PushString("%t");
		Call_PushCell(GetNativeCell(3));
		Call_PushString(YELLOW);
		Call_PushString(GREEN);
		Call_PushString(admname);
		Call_PushString(YELLOW);
		Call_PushString(TEAMCOLOR);
		Call_PushString(tagname);
		Call_PushString(YELLOW);
		Call_PushString(GREEN);
		for (new j = 4; j <= numParams; j++) Call_PushCell(GetNativeCell(j));
		Call_PushString(YELLOW);
		Call_Finish();
	}
}
//------------------------------------------------------------------------------------------------------------------------------------
public AdvNotify2(Handle:plugin, numParams)
{
	if (g_bSilent) return;

	new admin = GetNativeCell(1);
	decl String:admname[MAX_NAME], String:tagname[MAX_NAME];
	GetNativeString(2, tagname, sizeof(tagname));

	for (new i = 1; i <= MaxClients; i++)
	if (IsClientInGame(i) && !IsFakeClient(i) && FormatActivitySource(admin, i, admname, sizeof(admname)))
	{
		Call_StartFunction(INVALID_HANDLE, PrintToChatEx);
		Call_PushCell(admin);
		Call_PushCell(i);
		Call_PushString("%t");
		Call_PushCell(GetNativeCell(3));
		Call_PushString(YELLOW);
		Call_PushString(GREEN);
		Call_PushString(admname);
		Call_PushString(YELLOW);
		Call_PushString(TEAMCOLOR);
		Call_PushString(tagname);
		Call_PushString(YELLOW);
		Call_PushString(GREEN);
		for (new j = 4; j <= numParams; j++) Call_PushCell(GetNativeCell(j));
		Call_PushString(YELLOW);
		Call_Finish();
	}
}
//------------------------------------------------------------------------------------------------------------------------------------
God(client, value) 
{
	SetEntProp(client, Prop_Data, "m_takedamage", value, 1);
}
//------------------------------------------------------------------------------------------------------------------------------------
Balance(bool:dead)
{
	new n1 = 0, n2 = 0, nf1 = 0, nf2 = 0, nd1 = 0, nd2 = 0;
	for (new i = 1; i <= MaxClients; i++)
	if (IsClientInGame(i)) switch (GetClientTeam(i))
	{
		case TEAM1 : {
				n1++;
				nf1 += GetClientFrags(i);
				nd1 += GetClientDeaths(i);
			}
		case TEAM2 : {
				n2++;
				nf2 += GetClientFrags(i);
				nd2 += GetClientDeaths(i);
			}
	}
	new st = TEAM2, mt = TEAM1, dn = abs(n1-n2), df = 0, dd = 0;
	if (n1 > n2)
	{
		st = TEAM1;
		mt = TEAM2;
	}
	while (dn-- > g_iLTM)
	{
		df = abs(nf1-nf2)/2;
		dd = abs(nd1-nd2)/2;
		new mi = 0, mf = 2047, md = 2047;
		for (new i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && (GetClientTeam(i) == st) && (!dead || (dead && !IsPlayerAlive(i))))
		{
			new AdminId:admid = GetUserAdmin(i);
			if ((admid != INVALID_ADMIN_ID) && g_iAdmImm && (GetAdminImmunityLevel(admid) > g_iAdmImm)) continue;
			new cdf = abs(GetClientFrags(i)-df);
			new cdd = abs(GetClientDeaths(i)-dd);
			if ((cdf < mf) || ((cdf == mf) && (cdd < md)))
			{
				mi = i;
				mf = cdf;
				md = cdd;
			}
		}
		if (mi && IsClientInGame(mi))
		{
			ChangeClientTeamEx(mi, mt);
			if (g_iNotify & 1)
				 (g_iNotify & 16)?PrintHintText(mi, "%t", "Moved Notify"):PrintToChat(mi, "%t", "Moved Notify");
		}
	}
}
//------------------------------------------------------------------------------------------------------------------------------------
DropWeapon(client, ent)
{
	if (game == GAME_CSTRIKE || game == GAME_CSGO)
	{
		CS_DropWeapon(client, ent, true);
	}
	else
	{
		if (hDrop != INVALID_HANDLE)
		{
			SDKCall(hDrop, client, ent, 0, 0);
		}
		else
		{
			decl String:edict[MAX_NAME]; edict[0] = '\0';		
			GetEdictClassname(ent, edict, sizeof(edict));
			FakeClientCommandEx(client, "use %s;drop", edict);
		}
	}
}
//------------------------------------------------------------------------------------------------------------------------------------
ChangeClientTeamEx(client, team)
{
	if ((game != GAME_CSTRIKE && game != GAME_CSGO) || team < TEAM1)
	{
		//PrintToChatAll("ChangeClientTeamEx Game != CSS or CSGO");
		ChangeClientTeam(client, team);
		return;
	}

	new oldTeam = GetClientTeam(client);
	//PrintToChatAll("ChangeClientTeamEx Game running CS_SwitchTeam");
	CS_SwitchTeam(client, team);
	if (!IsPlayerAlive(client))
	{
		//PrintToChatAll("ChangeClientTeamEx Player is dead?");
		return;
	}
	
	if (game == GAME_CSGO)
	{
		//PrintToChatAll("ChangeClientTeamEx running CS_RespawnPlayer");
		CS_RespawnPlayer(client);
		return;
	}

	decl String:model[PLATFORM_MAX_PATH], String:newmodel[PLATFORM_MAX_PATH];
	GetClientModel(client, model, sizeof(model));
	newmodel = model;

	if (oldTeam == TEAM1)
	{
		new c4 = GetPlayerWeaponSlot(client, CS_SLOT_C4);
		if (c4 != -1) DropWeapon(client, c4);
		
		if (game == GAME_CSTRIKE)
		{
			if (StrContains(model, t_models[0], false)) newmodel = ct_models[0];
			if (StrContains(model, t_models[1], false)) newmodel = ct_models[1];
			if (StrContains(model, t_models[2], false)) newmodel = ct_models[2];
			if (StrContains(model, t_models[3], false)) newmodel = ct_models[3];
		}
	} else
	if (oldTeam == TEAM2)
	{
		SetEntProp(client, Prop_Send, "m_bHasDefuser", 0, 1);
		
		if (game == GAME_CSTRIKE)
		{
			if (StrContains(model, ct_models[0], false)) newmodel = t_models[0];
			if (StrContains(model, ct_models[1], false)) newmodel = t_models[1];
			if (StrContains(model, ct_models[2], false)) newmodel = t_models[2];
			if (StrContains(model, ct_models[3], false)) newmodel = t_models[3];
		}
	}

	//if (hSetModel != INVALID_HANDLE) SDKCall(hSetModel, client, newmodel);
}
//------------------------------------------------------------------------------------------------------------------------------------
SwapPlayer(client, target)
{
	switch (GetClientTeam(target))
	{
		case TEAM1 : ChangeClientTeamEx(target, TEAM2);
		case TEAM2 : ChangeClientTeamEx(target, TEAM1);
		default:
			return;
	}
	Notify(client, target, "Swap Notify", teams[GetClientTeam(target)]);
}
//------------------------------------------------------------------------------------------------------------------------------------
SwapPlayerRound(client, target)
{
	if (NewTeam[target])
	{
		Notify(client, target, "Swap Round Cancel", teams[NewTeam[target]]);
		NewTeam[target] = 0;
		return;
	}
	switch (GetClientTeam(target))
	{
		case TEAM1 : NewTeam[target] = TEAM2;
		case TEAM2 : NewTeam[target] = TEAM1;
		default:
			return;
	}
	Notify(client, target, "Swap Round Notify", teams[NewTeam[target]]);
}
//------------------------------------------------------------------------------------------------------------------------------------
ExchangePlayers(client, cl1, cl2)
{
	new t1 = GetClientTeam(cl1), t2 = GetClientTeam(cl2);
	if (((t1 == TEAM1) && (t2 == TEAM2)) || ((t1 == TEAM2) && (t2 == TEAM1)))
	{
		ChangeClientTeamEx(cl1, t2);
		ChangeClientTeamEx(cl2, t1);
	} else
		ReplyToCommand(client, "%t", "Bad targets");
}
//------------------------------------------------------------------------------------------------------------------------------------
ExchangePlayersRound(client, cl1, cl2)
{
	new t1 = GetClientTeam(cl1), t2 = GetClientTeam(cl2);
	if (((t1 == TEAM1) && (t2 == TEAM2)) || ((t1 == TEAM2) && (t2 == TEAM1)))
	{
		SwapPlayerRound(client, cl1);
		SwapPlayerRound(client, cl2);
	} else
		ReplyToCommand(client, "%t", "Bad targets");
}
//------------------------------------------------------------------------------------------------------------------------------------
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("Notify", AdvNotify);
	CreateNative("Notify2", AdvNotify2);
	MarkNativeAsOptional("TF2_RespawnPlayer");
	MarkNativeAsOptional("TF2_RemoveAllItems");
	MarkNativeAsOptional("GetUserMessageType");
	g_late = late;
	return APLRes_Success;
}
//------------------------------------------------------------------------------------------------------------------------------------
public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("advcommands");

	CreateConVar("sm_adv_version", PLUGIN_VERSION, "Sourcemod Advanced version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);	
	hSilent		= CreateConVar("sm_adv_silent", 			"0", 	"Suppress all notifications", 			FCVAR_PLUGIN, true, 0.0, true, 1.0);	
	hNotify		= CreateConVar("sm_adv_notify", 			"3", 	"Player notiications (1 - move, 2 - spawn protection, 16 - notify in hint)", FCVAR_PLUGIN, true, 0.0, true, 31.0);	
	hLog		= CreateConVar("sm_adv_log", 			"1", 	"Log actions", 							FCVAR_PLUGIN, true, 0.0, true, 1.0);	
	hMapcfg		= CreateConVar("sm_adv_mapcfg", 			"0", 	"Enable mapconfigs", 					FCVAR_PLUGIN, true, 0.0, true, 1.0);	
	hMe			= CreateConVar("sm_adv_me", 				"1", 	"Enable /me trigger", 					FCVAR_PLUGIN, true, 0.0, true, 1.0);	
	hMotd		= CreateConVar("sm_adv_motd", 			"", 	"If empty shows MOTD page, elsewhere opens this url", FCVAR_PLUGIN);
	hCAEnable	= CreateConVar("sm_adv_connect_announce", "1", 	"Enable connect announce (1 - humans, 2 - bots)", FCVAR_PLUGIN, true, 0.0, true, 3.0);	
	hSProt		= CreateConVar("sm_adv_spawn_protection", "5.0", "Spawn protection time (0 to disable)", FCVAR_PLUGIN, true, 0.0);	
	hREProt		= CreateConVar("sm_adv_round_protection", "0", 	"Protect players between rounds", 		FCVAR_PLUGIN, true, 0.0, true, 1.0);	
	hBanlog		= CreateConVar("sm_adv_banlog", 			"7", 	"Enable ban logging (1 - log bans, 2 - log unbans, 4 - log console too)", FCVAR_PLUGIN, true, 0.0, true, 7.0);	
	hAdmList	= CreateConVar("sm_adv_admin_list", 		"1", 	"Enable sm_admins command (1 - generic, 2 - roots)", FCVAR_PLUGIN, true, 0.0, true, 3.0);	
	hAdmVision	= CreateConVar("sm_adv_admin_vision", 	"7", 	"Enable admin vision (for: 1 - admins, 2 - fake clients, 4 - all, when sv_alltalk 1, 8 - all)", FCVAR_PLUGIN, true, 0.0, true, 15.0);
	hAdmFlags	= CreateConVar("sm_adv_admin_flags", 	"j", 	"Set of admin flags, which allows admin vision", 	FCVAR_PLUGIN);
	hAdmImm		= CreateConVar("sm_adv_admin_immunity", 	"90", 	"Minimum admin immunity, which grants protection against balancing", FCVAR_PLUGIN, true, 0.0);	

	HookConVarChange(hSilent, UpdateCvars);
	HookConVarChange(hNotify, UpdateCvars);
	HookConVarChange(hLog, UpdateCvars);
	HookConVarChange(hMapcfg, UpdateCvars);
	HookConVarChange(hMe, UpdateCvars);
	HookConVarChange(hMotd, UpdateCvars);
	HookConVarChange(hCAEnable, UpdateCvars);
	HookConVarChange(hSProt, UpdateCvars);
	HookConVarChange(hREProt, UpdateCvars);
	HookConVarChange(hBanlog, UpdateCvars);
	HookConVarChange(hAdmList, UpdateCvars);
	HookConVarChange(hAdmVision, UpdateCvars);
	HookConVarChange(hAdmFlags, UpdateCvars);
	HookConVarChange(hAdmImm, UpdateCvars);

	decl String:gdir[PLATFORM_MAX_PATH];
	GetGameFolderName(gdir, sizeof(gdir));
	if (StrEqual(gdir, "cstrike", false))		game = GAME_CSTRIKE;	else
	if (StrEqual(gdir, "dod", false))			game = GAME_DOD;		else
	if (StrEqual(gdir, "tf", false))			game = GAME_TF2;		else
	if (StrEqual(gdir, "hl2mp", false))		game = GAME_HL2MP;		else
	if (StrEqual(gdir, "left4dead", false))	game = GAME_LEFT4DEAD;	else
	if (StrEqual(gdir, "left4dead2", false))	game = GAME_LEFT4DEAD2; else
	if (StrEqual(gdir, "csgo", false))		game = GAME_CSGO;

	hGameConf = LoadGameConfigFile("advcommands.gamedata");
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "SetModel");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	//if ((hSetModel = EndPrepSDKCall()) == INVALID_HANDLE)
	//	PrintToServer("[Advanced Commands] Warning: SetModel SDKCall not found, model changing disabled");
	//else
	RegAdminCmd("sm_setmodel", Command_SetModel, ADMFLAG_BAN, "Set target's model (be careful)");
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "Weapon_Drop");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_Pointer);
	if ((hDrop = EndPrepSDKCall()) == INVALID_HANDLE)
		PrintToServer("[Advanced Commands] Warning: Weapon_Drop SDKCall not found, stupid method will be used");
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "Respawn");
	hRespawn = EndPrepSDKCall();
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "RemoveAllItems");
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	if (((hDisarm = EndPrepSDKCall()) == INVALID_HANDLE) && (game != GAME_TF2))
		PrintToServer("[Advanced Commands] Warning: RemoveAllItems SDKCall not found, direct method will be used");


	if (game == GAME_CSTRIKE || game == GAME_CSGO)
	{
		RegAdminCmd("sm_nv", 		Command_NV, 		ADMFLAG_GENERIC, 	"Toggle target's nightvision");
		RegAdminCmd("sm_defuser", 	Command_Defuser, ADMFLAG_GENERIC, 	"Toggle target's defuser");
		RegAdminCmd("sm_cash", 		Command_Cash, 	ADMFLAG_KICK, 		"Change target's cash");
		RegAdminCmd("sm_knives", 	Command_Melee, 	ADMFLAG_KICK, 		"Remove all weapons, except knives");
	}

	if ((game & (GAME_CSTRIKE|GAME_CSGO|GAME_TF2)) || (hRespawn != INVALID_HANDLE))
		RegAdminCmd("sm_respawn", 	Command_Respawn, ADMFLAG_KICK, 		"Respawn target");
	else
		PrintToServer("[Advanced Commands] Warning: Respawn SDKCall not found, sm_respawn disabled");

	RegAdminCmd("sm_disarm", 	Command_Disarm, 		ADMFLAG_GENERIC, 	"Disarm target");
	RegAdminCmd("sm_melee", 		Command_Melee, 		ADMFLAG_BAN, 		"Remove all weapons, except melee weapon");
	RegAdminCmd("sm_equip", 		Command_Equip, 		ADMFLAG_BAN, 		"Remove all weapons, and give this weapon for all");
	RegAdminCmd("sm_bury", 		Command_Bury, 		ADMFLAG_KICK, 		"Bury target");
	RegAdminCmd("sm_unbury", 	Command_Unbury, 		ADMFLAG_KICK, 		"Unbury target");
	RegAdminCmd("sm_hp", 		Command_HP, 			ADMFLAG_KICK, 		"Set target's health points");
	RegAdminCmd("sm_armour", 	Command_Armour, 		ADMFLAG_KICK, 		"Set target's armour");
	RegAdminCmd("sm_give", 		Command_Give, 		ADMFLAG_BAN, 		"Give item to target");
	RegAdminCmd("sm_speed", 		Command_Speed, 		ADMFLAG_BAN, 		"Set target's speed");
	RegAdminCmd("sm_frags", 		Command_Frags, 		ADMFLAG_BAN, 		"Change target's frags");
	RegAdminCmd("sm_deaths", 	Command_Deaths, 		ADMFLAG_BAN, 		"Change target's deaths");
	RegAdminCmd("sm_balance", 	Command_Balance, 	ADMFLAG_GENERIC, 	"Balance teams");
	RegAdminCmd("sm_shuffle", 	Command_Shuffle, 	ADMFLAG_KICK, 		"Shuffle players");
	RegAdminCmd("sm_exec", 		Command_Exec, 		ADMFLAG_BAN, 		"Execute command on target");
	RegAdminCmd("sm_fexec", 		Command_FExec, 		ADMFLAG_BAN, 		"Fake-execute command on target");
	RegAdminCmd("sm_getloc", 	Command_Location, 	ADMFLAG_BAN, 		"Print location");
	RegAdminCmd("sm_saveloc", 	Command_SaveLoc, 	ADMFLAG_BAN, 		"Save location");
	RegAdminCmd("sm_teleport", 	Command_Teleport, 	ADMFLAG_BAN, 		"Teleport target");
	RegAdminCmd("sm_blink", 		Command_Blink, 		ADMFLAG_BAN, 		"Aimed teleport");
	RegAdminCmd("sm_god", 		Command_God, 		ADMFLAG_BAN, 		"Set target's godmode state");
	RegAdminCmd("sm_rr", 		Command_RR, 			ADMFLAG_CHANGEMAP, 	"Restart round");
	RegAdminCmd("sm_extend", 	Command_Extend, 		ADMFLAG_CHANGEMAP, 	"Extend map");
	RegAdminCmd("sm_shutdown", 	Command_Shutdown, 	ADMFLAG_ROOT, 		"Shutdown server");
	RegAdminCmd("sm_showmotd", 	Command_MOTD, 		ADMFLAG_GENERIC, 	"Show MOTD for target");
	RegAdminCmd("sm_url", 		Command_Url, 		ADMFLAG_GENERIC, 	"Open URL for target");
	RegAdminCmd("sm_getmodel", 	Command_GetModel, 	ADMFLAG_BAN, 		"Get target's model name");
	RegAdminCmd("sm_drop", 		Command_Drop, 		ADMFLAG_KICK, 		"Drop target's weapon");
	RegAdminCmd("sm_dropslot", 	Command_DropSlot, 	ADMFLAG_KICK, 		"Drop target's weapon from slot");
	RegAdminCmd("sm_spec", 		Command_Spec, 		ADMFLAG_KICK, 		"Move target to spectator");
	RegAdminCmd("sm_teamswap", 	Command_TeamSwap, 	ADMFLAG_KICK, 		"Swap teams");
	RegAdminCmd("sm_team", 		Command_Team, 		ADMFLAG_KICK, 		"Set target's team");
	RegAdminCmd("sm_swap", 		Command_Swap, 		ADMFLAG_KICK, 		"Swap target's team");
	RegAdminCmd("sm_lswap", 		Command_LSwap, 		ADMFLAG_KICK, 		"Swap target's team later");
	RegAdminCmd("sm_exch", 		Command_Exchange, 	ADMFLAG_KICK, 		"Exchange targets in teams");
	RegAdminCmd("sm_lexch", 		Command_LExchange, 	ADMFLAG_KICK, 		"Exchange targets in teams later");

	RegAdminCmd ("sm_botsay", 	BotSay, 			ADMFLAG_CHAT, 		"Make a bot say something");
	
	RegConsoleCmd("sm_admins", 	Command_Admins, 		"Show online admins");

	sv_alltalk = FindConVar("sv_alltalk");
	mp_atb = FindConVar("mp_autoteambalance");
	mp_ltm = FindConVar("mp_limitteams");
	hostname = FindConVar("hostname");
	
	if (mp_atb == INVALID_HANDLE)
		mp_atb = CreateConVar("sm_adv_autoteambalance", "1", "Enable automatic team balance", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	if (mp_ltm == INVALID_HANDLE)
		mp_ltm = CreateConVar("sm_adv_limitteams", "0", "Max # of players 1 team can have over another (0 disables check)", FCVAR_PLUGIN, true, 0.0);

	HookConVarChange(sv_alltalk, UpdateCvars);
	HookConVarChange(mp_atb, UpdateCvars);
	HookConVarChange(mp_ltm, UpdateCvars);

	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_Say, "say_team");

#if defined OLDAV
	g_oldAV = true;
#else
	new UserMsg:msg_id = GetUserMessageId("SayText2");
	if (msg_id == INVALID_MESSAGE_ID)
		g_oldAV = true; // oh, shi--! It's DoD
	else
		HookUserMessage(msg_id, OnSayText);
#endif
		

	HookEvent("player_spawn", Event_PlayerSpawn);
	if (game == GAME_CSTRIKE || game == GAME_CSGO) 
	{
		HookEvent("round_end", Event_RoundEnd);
	}
#if !defined FORCEDEAD
	else
#endif
	HookEvent("player_death", Event_PlayerDeath);
	

#if !defined NOMENU
	if (g_late) OnAdminMenuReady(GetAdminTopMenu());
#endif

	BuildPath(Path_SM, g_sBanlog, sizeof(g_sBanlog), "/logs/bans.log");
	AutoExecConfig(true, "advcommands");

	SetRandomSeed(GetSysTickCount());
}
//------------------------------------------------------------------------------------------------------------------------------------
#if !defined OLDAV
//------------------------------------------------------------------------------------------------------------------------------------
public Action:OnSayText(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	new bool:bProtobuf = GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available && GetUserMessageType() == UM_Protobuf;
	
	new from;
	if (bProtobuf)
		from = PbReadInt(bf, "ent_idx");
	else
		from = BfReadByte(bf);
		
	if (reliable && g_iAdmVision && (from == players[0]))
	{
		new bool:dead = !IsPlayerAlive(from), bool:at = (g_iAdmVision & 8) || ((g_iAdmVision & 4) && g_bAlltalk);
		new team = GetClientTeam(from);
		decl String:message[MAX_BUFF];

		if(bProtobuf)
		{
			PbReadString(bf, "msg_name", message, sizeof(message));
		}
		else
		{
			BfReadByte(bf);
			BfReadString(bf,message,sizeof(message));
		}
		new bool:tsay = StrContains(message,"_All") < 0;
	
		new ncl = 0;
		decl cl[MAX_CLIENTS];

		for (new i = 1; i <= MaxClients; i++)
		if ((i != from) && IsClientInGame(i) && ((IsPlayerAlive(i) && dead) || (tsay && (GetClientTeam(i) != team))) &&
			(at || ((g_iAdmVision & 2) && IsFakeClient(i)) || ((g_iAdmVision & 1) && ((GetUserFlagBits(i) & g_iAdmFlags) == g_iAdmFlags))))
			cl[ncl++] = i;

		if (ncl)
		{
			new Handle:ma = CreateArray(MAX_BUFF_SM, 3);
			SetArrayCell(ma, 0, from);
			SetArrayCell(ma, 1, ncl);
			SetArrayArray(ma, 2, cl, ncl);

//			if (!at) PushArrayString(ma, "\x04[AV]\x01 %s1");

			if(bProtobuf)
			{
				PushArrayString(ma, message);
				new num = PbGetRepeatedFieldCount(bf, "params");
				for(new i=0;i<num;i++)
				{
					PbReadString(bf, "params", message, sizeof(message), i);
					PushArrayString(ma, message);
				}
			}
			else
			{
				do PushArrayString(ma,message);
				while (BfReadString(bf,message,sizeof(message)) > 0);
			}
		
			CreateTimer(0.1, SendMsg, ma);
		}
	}
	return Plugin_Continue;
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:SendMsg(Handle:timer, Handle:ma)
{
	new from = GetArrayCell(ma, 0), ncl = GetArrayCell(ma, 1);
	decl cl[MAX_CLIENTS];
	GetArrayArray(ma, 2, cl, ncl);

	for (new i = 0; i < ncl; i++)
	if (!IsClientInGame(cl[i]))
	{
		for (new j = i; j < ncl; j++) cl[j] = cl[j+1];
		ncl--;
	}
	new Handle:hBf = StartMessage("SayText2", cl, ncl, USERMSG_BLOCKHOOKS);
	if (hBf != INVALID_HANDLE)
	{
		if (GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available && GetUserMessageType() == UM_Protobuf)
		{
			PbSetInt(hBf, "ent_idx", from);
			PbSetBool(hBf, "chat", true);
			decl String:msg[MAX_BUFF];
			new n = GetArraySize(ma);
			for (new i = 3; i < n; i++)
			{
				GetArrayString(ma,i,msg,sizeof(msg));
				if(i == 3)
					PbSetString(hBf, "msg_name", msg);
				else
					PbAddString(hBf, "params", msg);
			}
			for(new i=n-3;i<4;i++)
				PbAddString(hBf, "params", "");
		}
		else
		{
			BfWriteByte(hBf, from);
			BfWriteByte(hBf, true);
			decl String:msg[MAX_BUFF];
			new n = GetArraySize(ma);
			for (new i = 3; i < n; i++)
			{
				GetArrayString(ma,i,msg,sizeof(msg));
				BfWriteString(hBf, msg);
			}
		}
		
		EndMessage();
	}
	ClearArray(ma);
	CloseHandle(ma);
	return Plugin_Stop;
}
//------------------------------------------------------------------------------------------------------------------------------------
#endif
//------------------------------------------------------------------------------------------------------------------------------------
public Action:Command_Say(client, const String:command[], args)
{
	if (!client || !IsClientInGame(client)) return Plugin_Continue;

	decl String:msg[MAX_BUFF];
	GetCmdArg(1, msg, sizeof(msg));

#if defined CHATMOTD
	if (!strcmp(msg, "rules", false) || !strcmp(msg, "motd", false))
#else
	if (!strcmp(msg, "rules", false))
#endif
	{
		ShowMOTD(client);
		return Plugin_Handled;
	}

	new bool:dead = !IsPlayerAlive(client), bool:tsay = StrEqual(command, "say_team");
	new team = GetClientTeam(client);

	if (!strncmp(msg, "/me ", 4, false) && g_bMe)
	{
		decl String:mesg[MAX_BUFF];
		Format(mesg, sizeof(mesg), "%s*** \x03%N\x04 %s", tsay?YELLOW:GREEN, client, msg[4]);
		for (new i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && !(IsPlayerAlive(i) && dead) && (!tsay || (tsay && (team == GetClientTeam(i)))))
			PrintToChatEx(client, i, mesg);
		return Plugin_Handled;		
	}

	if (!g_oldAV || !g_iAdmVision || IsChatTrigger() || (msg[0] == '@')) return Plugin_Continue;

	decl String:pref[MAX_ID] = "(Dead)(Team)";
	if (tsay)
	{
		if (!dead || (team == SPEC)) pref = "(Team)";

		if ((g_iAdmVision & 8) || ((g_iAdmVision & 4) && g_bAlltalk))
		{
			for (new i = 1; i <= MaxClients; i++)
			if ((i != client) && IsClientInGame(i) &&
				((GetClientTeam(i) != team) || (IsPlayerAlive(i) && dead)))
					PrintToChatEx(client, i, "\x01%s \x03%N\x01 :  %s", pref, i, msg);
		} else
		{
			for (new i = 1; i <= MaxClients; i++)
			if ((i != client) && IsClientInGame(i) && ((GetClientTeam(i) != team) || (IsPlayerAlive(i) && dead)) && 
				(((g_iAdmVision & 1) && ((GetUserFlagBits(i) & g_iAdmFlags) == g_iAdmFlags)) || ((g_iAdmVision & 2) && IsFakeClient(i))))
				PrintToChatEx(client, i, "\x04[AV]\x01 %s \x03%N\x01 :  %s", pref, i, msg);
		}
	} else if (dead)
	{
		if (team == SPEC) pref = "(Team)";
		else pref = "(Dead)";

		if ((g_iAdmVision & 8) || ((g_iAdmVision & 4) && g_bAlltalk))
		{
			for (new i = 1; i <= MaxClients; i++)
			if ((i != client) && IsClientInGame(i) && IsPlayerAlive(i) && dead)
				PrintToChatEx(client, i, "\x01%s \x03%N\x01 :  %s", pref, i, msg);
		} else
		{
			for (new i = 1; i <= MaxClients; i++)
			if ((i != client) && IsClientInGame(i) && IsPlayerAlive(i) && dead && 
				(((g_iAdmVision & 1) && ((GetUserFlagBits(i) & g_iAdmFlags) == g_iAdmFlags)) || ((g_iAdmVision & 2) && IsFakeClient(i))))
				PrintToChatEx(client, i, "\x04[AV]\x01 %s \x03%N\x01 :  %s", pref, i, msg);
		}
	}

	return Plugin_Continue;
}
//------------------------------------------------------------------------------------------------------------------------------------
public OnClientAuthorized(client, const String:auth[])
{
	if (!g_iCAEnable || (!(g_iCAEnable & 2) && IsFakeClient(client))) return;

	decl String:ip[MAX_ID], String:name[MAX_NAME], String:country[MAX_NAME], String:from[MAX_BUFF_SM];
	GetClientName(client, name, sizeof(name));
	if (GetClientIP(client, ip, sizeof(ip)) && GeoipCountry(ip, country, sizeof(country)))
		Format(from, sizeof(from), " from \x03%s", country);
	else from = "";

	PrintToChatAll("\x04%s [\x03%s\x04] connected%s", name, auth, from);
}
//------------------------------------------------------------------------------------------------------------------------------------
public UpdateCvars(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_bSilent = GetConVarBool(hSilent);
	g_iNotify = GetConVarInt(hNotify);
	g_bLog = GetConVarBool(hLog);
	g_bMapcfg = GetConVarBool(hMapcfg);
	g_bMe = GetConVarBool(hMe);
	g_fSProt = GetConVarFloat(hSProt);
	g_bREProt = GetConVarBool(hREProt);
	g_iCAEnable = GetConVarInt(hCAEnable);
	g_iBanlog = GetConVarInt(hBanlog);
	g_iAdmList = GetConVarInt(hAdmList);
	g_iAdmVision = GetConVarInt(hAdmVision);
	g_iAdmImm = GetConVarInt(hAdmImm);

	decl String:flags[MAX_ID];
	GetConVarString(hAdmFlags, flags, sizeof(flags));
	g_iAdmFlags = ReadFlagString(flags);

	g_bATB = GetConVarBool(mp_atb);
	g_iLTM = GetConVarBool(mp_ltm);
	g_bAlltalk = GetConVarBool(sv_alltalk);
}
//------------------------------------------------------------------------------------------------------------------------------------
public OnConfigsExecuted()
{
	if (g_bMapcfg)
	{
		new String:map[64];
		GetCurrentMap(map, sizeof(map));
		InsertServerCommand("exec mapcfg/%s.cfg", map);
		ServerExecute();
	}
	for (new i = 1; i <= MaxClients; i++)
	{
		coords[i][0] = 0.0;
		coords[i][1] = 0.0;
		coords[i][2] = 0.0;
	}
	if (game != GAME_CSTRIKE || game != GAME_CSGO)
	{
		GetTeamName(TEAM1, teams[TEAM1], MAX_ID);
		GetTeamName(TEAM2, teams[TEAM2], MAX_ID);
	}
	UpdateCvars(INVALID_HANDLE, "", "");
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:OnBanClient(client, time, flags, const String:reason[], const String:kick_message[], const String:command[], any:source)
{
	if ((g_iBanlog & 1) && (source || (g_iBanlog & 4)))
	{
		decl String:mins[MAX_ID];
		if (time) Format(mins, sizeof(mins), "%d mins", time);
		else mins = "permanent";
		if (reason[0]) LogToFileEx(g_sBanlog, "%L banned %L (%s) reason: %s", source, client, mins, reason);
		else LogToFileEx(g_sBanlog, "%L banned %L (%s)", source, client, mins);
	}
	return Plugin_Continue;
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:OnBanIdentity(const String:identity[], time, flags, const String:reason[], const String:command[], any:source)
{
	if ((g_iBanlog & 1) && (source || (g_iBanlog & 4)))
	{
		decl String:mins[MAX_ID];
		if (time) Format(mins, sizeof(mins), "%d mins", time);
		else mins = "permanent";
		if (reason[0]) LogToFileEx(g_sBanlog, "%L banned %s (%s) reason: %s", source, identity, mins, reason);
		else LogToFileEx(g_sBanlog, "%L banned %s (%s)", source, identity, mins);

	}
	return Plugin_Continue;
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:OnRemoveBan(const String:identity[], flags, const String:command[], any:source)
{
	if ((g_iBanlog & 2) && (source || (g_iBanlog & 4)))
		LogToFileEx(g_sBanlog, "%L unbanned %s", source, identity);

	return Plugin_Continue;
}
//------------------------------------------------------------------------------------------------------------------------------------
#if !defined NOMENU
//------------------------------------------------------------------------------------------------------------------------------------
public MenuHandler_Extend(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_End : CloseHandle(menu);
		case MenuAction_Cancel :
			if ((param2 == MenuCancel_ExitBack) && (hTopMenu != INVALID_HANDLE))
	            DisplayTopMenu(GetAdminTopMenu(), param1, TopMenuPosition_LastCategory);
		case MenuAction_Select :
			{
				decl String:tm[MAX_ID];
				GetMenuItem(menu, param2, tm, sizeof(tm));
				ExtendMap(param1, StringToInt(tm));
			}
	}
}
//------------------------------------------------------------------------------------------------------------------------------------
public DisplayExtendMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_Extend);
	SetMenuExitBackButton(menu, true);

	SetMenuTitle(menu, "%t", "Menu Extend");

	AddMenuItem(menu, "5", "5 min");
	AddMenuItem(menu, "10", "10 min");
	AddMenuItem(menu, "15", "15 min");
	AddMenuItem(menu, "20", "20 min");
	AddMenuItem(menu, "30", "30 min");
	AddMenuItem(menu, "45", "45 min");

	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}
//------------------------------------------------------------------------------------------------------------------------------------
public FillMenuByPlayers(Handle:menu, skipteam, skipclient)
{
	decl String:name[MAX_NAME], String:title[MAX_BUFF_SM], String:id[MAX_ID];

	for (new i = 1; i <= MaxClients; i++)
	if (IsClientInGame(i) && (i != skipclient))
	{
		new team = GetClientTeam(i);
		if ((team > SPEC) && (team != skipteam))
		{
			GetClientName(i, name, sizeof(name));
			if (NewTeam[i]) Format(title, sizeof(title), "[%s>>%s] %s", teams[team], teams[NewTeam[i]], name);
			else Format(title, sizeof(title), "[%s] %s", teams[team], name);
			IntToString(GetClientUserId(i), id, sizeof(id));
			AddMenuItem(menu, id, title);
		}
	}
}
//------------------------------------------------------------------------------------------------------------------------------------
public MenuHandler_Swap(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_End : CloseHandle(menu);
		case MenuAction_Cancel :
			if ((param2 == MenuCancel_ExitBack) && (hTopMenu != INVALID_HANDLE))
				DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
		case MenuAction_Select :
			{
				decl String:title[MAX_BUFF_SM], String:id[MAX_ID], String:late[MAX_BUFF_SM];
				GetMenuItem(menu, param2, id, sizeof(id));
				new target = GetClientOfUserId(StringToInt(id));
				if (target)
				{
					GetMenuTitle(menu, title, sizeof(title));
					Format(late, sizeof(late), "%t", "Menu Swap Round", param1);
					if (!strcmp(late, title))
					{
						SwapPlayerRound(param1, target);
						DisplayActionMenu(param1, "sm_lswap");
					} else
					{
						SwapPlayer(param1, target);
						DisplayActionMenu(param1, "sm_swap");
					}
				}
			}
	}
}
//------------------------------------------------------------------------------------------------------------------------------------
public MenuHandler_Exchange2(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_End : CloseHandle(menu);
		case MenuAction_Cancel :
			if ((param2 == MenuCancel_ExitBack) && (hTopMenu != INVALID_HANDLE))
				DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
		case MenuAction_Select :
			{
				decl String:id1[MAX_ID], String:id2[MAX_ID], String:late[MAX_BUFF_SM];
				GetMenuItem(menu, 0, id1, sizeof(id1));
				GetMenuItem(menu, param2, id2, sizeof(id2));
		
				new cl1 = GetClientOfUserId(StringToInt(id1));
				new cl2 = GetClientOfUserId(StringToInt(id2));
		
				if (cl1 && cl2)
				{
					decl String:title[MAX_BUFF_SM];
					GetMenuTitle(menu, title, sizeof(title));
					Format(late, sizeof(late), "%t", "Menu Exchange Round", param1);
					if (!strcmp(late, title))
					{
						ExchangePlayersRound(param1, cl1, cl2);
						DisplayActionMenu(param1, "sm_lexch");
					} else
					{
						ExchangePlayers(param1, cl1, cl2);
						DisplayActionMenu(param1, "sm_exch");
					}
				}
			}
	}
}
//------------------------------------------------------------------------------------------------------------------------------------
public MenuHandler_Exchange(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_End : CloseHandle(menu);
		case MenuAction_Cancel :
			if ((param2 == MenuCancel_ExitBack) && (hTopMenu != INVALID_HANDLE))
				DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
		case MenuAction_Select :
			{
				decl String:name[MAX_BUFF_SM], String:title[MAX_BUFF_SM], String:id[MAX_ID];
				GetMenuItem(menu, param2, id, sizeof(id));
				new target = GetClientOfUserId(StringToInt(id));
				if (target)
				{
					new team = GetClientTeam(target);
		
					new Handle:menu2 = CreateMenu(MenuHandler_Exchange2);
					SetMenuExitBackButton(menu2, true);
					GetMenuTitle(menu, title, sizeof(title));
					SetMenuTitle(menu2, title);
			
					GetClientName(target, name, sizeof(name));
					Format(title, sizeof(title), "[%s] %s", teams[team], name);
					AddMenuItem(menu2, id, title, ITEMDRAW_DISABLED);
			
					FillMenuByPlayers(menu2, team, target);
					DisplayMenu(menu2, param1, MENU_TIME_FOREVER);
				}
			}
	}
}
//------------------------------------------------------------------------------------------------------------------------------------
DisplayActionMenu(client, String:cmd[])
{
	new Handle:menu = INVALID_HANDLE;
	decl String:title[MAX_BUFF_SM];
	if (StrEqual(cmd, "sm_swap"))
	{
		menu = CreateMenu(MenuHandler_Swap);
		Format(title, sizeof(title), "%t", "Menu Swap Now", client);
	} else
	if (StrEqual(cmd, "sm_lswap"))
	{
		menu = CreateMenu(MenuHandler_Swap);
		Format(title, sizeof(title), "%t", "Menu Swap Round", client);
	} else
	if (StrEqual(cmd, "sm_exch"))
	{
		menu = CreateMenu(MenuHandler_Exchange);
		Format(title, sizeof(title), "%t", "Menu Exchange Now", client);
	} else
	if (StrEqual(cmd, "sm_lexch"))
	{
		menu = CreateMenu(MenuHandler_Exchange);
		Format(title, sizeof(title), "%t", "Menu Exchange Round", client);
	}

	if (menu != INVALID_HANDLE)
	{
		SetMenuExitBackButton(menu, true);
		SetMenuTitle(menu, title);
		FillMenuByPlayers(menu, 0, 0);
	
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}
//------------------------------------------------------------------------------------------------------------------------------------
public AdminMenu_Handler(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	decl String:name[MAX_NAME];
	GetTopMenuObjName(topmenu, object_id, name, sizeof(name));
	switch (action)
	{
		case TopMenuAction_DisplayOption :
			{
				if (StrEqual(name, "sm_shutdown"))	Format(buffer, maxlength, "%t", "Menu Shutdown", 	param); else
				if (StrEqual(name, "sm_extend"))		Format(buffer, maxlength, "%t", "Menu Extend", 		param); else
				if (StrEqual(name, "sm_balance"))	Format(buffer, maxlength, "%t", "Menu Balance", 		param); else
				if (StrEqual(name, "sm_shuffle"))	Format(buffer, maxlength, "%t", "Menu Shuffle", 		param); else
				if (StrEqual(name, "sm_teamswap"))	Format(buffer, maxlength, "%t", "Menu Teamswap", 	param); else
				if (StrEqual(name, "sm_rr"))			Format(buffer, maxlength, "%t", "Menu RR", 			param); else
				if (StrEqual(name, "sm_swap"))		Format(buffer, maxlength, "%t", "Menu Swap Now", 	param); else
				if (StrEqual(name, "sm_lswap"))		Format(buffer, maxlength, "%t", "Menu Swap Round", 	param); else
				if (StrEqual(name, "sm_exch"))		Format(buffer, maxlength, "%t", "Menu Exchange Now", param); else
				if (StrEqual(name, "sm_lexch"))		Format(buffer, maxlength, "%t", "Menu Exchange Round", param);
			}
		case TopMenuAction_SelectOption :
			{
				if (StrEqual(name, "sm_shutdown"))	Command_Shutdown(param, 0);	else
				if (StrEqual(name, "sm_extend"))		DisplayExtendMenu(param);	else
				if (StrEqual(name, "sm_balance"))	Balance(false);				else
				if (StrEqual(name, "sm_shuffle"))	Command_Shuffle(param, 0);	else
				if (StrEqual(name, "sm_teamswap"))	Command_TeamSwap(param, 0);	else
				if (StrEqual(name, "sm_rr"))			ServerCommand("mp_restartgame 1");
				else
					DisplayActionMenu(param, name);
				
			}
	}
}
//------------------------------------------------------------------------------------------------------------------------------------
public OnAdminMenuReady(Handle:topmenu)
{
	new TopMenuObject:server_commands = FindTopMenuCategory(topmenu, ADMINMENU_SERVERCOMMANDS);
	new TopMenuObject:player_commands = FindTopMenuCategory(topmenu, ADMINMENU_PLAYERCOMMANDS);

	AddToTopMenu(topmenu, "sm_shutdown", 	TopMenuObject_Item, AdminMenu_Handler, server_commands, "sm_shutdown", 	ADMFLAG_ROOT);
	AddToTopMenu(topmenu, "sm_extend", 	TopMenuObject_Item, AdminMenu_Handler, server_commands, "sm_extend", 	ADMFLAG_CHANGEMAP);
	AddToTopMenu(topmenu, "sm_balance", 	TopMenuObject_Item, AdminMenu_Handler, server_commands, "sm_balance", 	ADMFLAG_GENERIC);
	AddToTopMenu(topmenu, "sm_shuffle", 	TopMenuObject_Item, AdminMenu_Handler, server_commands, "sm_shuffle", 	ADMFLAG_KICK);
	AddToTopMenu(topmenu, "sm_teamswap", 	TopMenuObject_Item, AdminMenu_Handler, server_commands, "sm_teamswap", 	ADMFLAG_KICK);
	AddToTopMenu(topmenu, "sm_rr", 		TopMenuObject_Item, AdminMenu_Handler, server_commands, "sm_rr", 		ADMFLAG_CHANGEMAP);

	AddToTopMenu(topmenu, "sm_swap", 		TopMenuObject_Item, AdminMenu_Handler, player_commands, "sm_swap", 		ADMFLAG_KICK);
	AddToTopMenu(topmenu, "sm_lswap", 	TopMenuObject_Item, AdminMenu_Handler, player_commands, "sm_lswap", 	ADMFLAG_KICK);
	AddToTopMenu(topmenu, "sm_exch", 		TopMenuObject_Item, AdminMenu_Handler, player_commands, "sm_exch", 		ADMFLAG_KICK);
	AddToTopMenu(topmenu, "sm_lexch", 	TopMenuObject_Item, AdminMenu_Handler, player_commands, "sm_lexch", 	ADMFLAG_KICK);

	hTopMenu = topmenu;
}
//------------------------------------------------------------------------------------------------------------------------------------
#endif
//------------------------------------------------------------------------------------------------------------------------------------
public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_bATB && g_iLTM) Balance(true);
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (NewTeam[client])
	{
		ChangeClientTeamEx(client, NewTeam[client]);
		NewTeam[client] = 0;
	}
	return Plugin_Continue;
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_bATB && g_iLTM) Balance(false);
	for (new i = 1; i <= MaxClients; i++)
	if (IsClientInGame(i))
	{
		if (NewTeam[i])
		{
			ChangeClientTeamEx(i, NewTeam[i]);
			NewTeam[i] = 0;
		}
		if (g_bREProt && IsPlayerAlive(i))
			God(i, 0);
	}

	return Plugin_Continue;
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new user = GetClientOfUserId(GetEventInt(event, "userid"));
	if (g_fSProt)
	{
		CreateTimer(g_fSProt, Unprotect, user);
		God(user, 0);
		switch (GetClientTeam(user))
		{
			case TEAM1	: SetEntityRenderColor(user, 255, 0, 0, 128);
			case TEAM2	: SetEntityRenderColor(user, 0, 0, 255, 128);
			default		: SetEntityRenderColor(user, 0, 255, 0, 128);
		}
	}
	NewTeam[user] = 0;
	return Plugin_Continue;
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:Unprotect(Handle:timer, any:client)
{
	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		God(client, 2);
		SetEntityRenderColor(client, 255, 255, 255, 255);
		if (g_iNotify & 2)
			(g_iNotify & 16)?PrintHintText(client, "%t", "SP End Notify"):PrintToChat(client, "%t", "SP End Notify");
	}
	return Plugin_Stop;
}
//------------------------------------------------------------------------------------------------------------------------------------
public ShowMOTD(client)
{
	decl String:host[MAX_BUFF_SM], String:motd[MAX_BUFF_SM];
	GetConVarString(hostname, host, sizeof(host));
	GetConVarString(hMotd, motd, sizeof(motd));
	if (strlen(motd))
		ShowMOTDPanel(client, host, motd, MOTDPANEL_TYPE_URL);
	else ShowMOTDPanel(client, host, "motd", MOTDPANEL_TYPE_INDEX);
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:Command_MOTD(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_showmotd <target>");
		return Plugin_Handled;
	}
	decl String:pattern[MAX_NAME], String:buffer[MAX_NAME];
	GetCmdArg(1, pattern, sizeof(pattern));
	new targets[MAX_CLIENTS], bool:ml = false;

	new count = ProcessTargetString(pattern, client, targets, sizeof(targets), FILTER_REAL, buffer, sizeof(buffer), ml);

	if (count <= 0) ReplyToCommand(client, "%t", (count < 0)?"Bad target":"No target", YELLOW, TEAMCOLOR, pattern, YELLOW);
	else for (new i = 0; i < count; i++)
	{
		ShowMOTD(targets[i]);
		if (g_bLog) LogAction(client, targets[i], "\"%L\" showed MOTD for \"%L\"", client, targets[i]);
	}

	return Plugin_Handled;
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:Command_Url(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_url <target> <url>");
		return Plugin_Handled;
	}
	decl String:pattern[MAX_NAME], String:buffer[MAX_NAME], String:url[MAX_BUFF];
	GetCmdArg(1, pattern, sizeof(pattern));
	GetCmdArg(2, url, sizeof(url));
	new targets[MAX_CLIENTS], bool:ml = false;

	new count = ProcessTargetString(pattern, client, targets, sizeof(targets), 0, buffer, sizeof(buffer), ml);

	decl String:host[MAX_BUFF_SM];
	GetConVarString(hostname, host, sizeof(host));
	if (count <= 0) ReplyToCommand(client, "%t", (count < 0)?"Bad target":"No target", YELLOW, TEAMCOLOR, pattern, YELLOW);
	else for (new i = 0; i < count; i++)
	{
		ShowMOTDPanel(targets[i], host, url, MOTDPANEL_TYPE_URL);
		if (g_bLog) LogAction(client, targets[i], "\"%L\" opened \"%s\" for \"%L\"", client, url, targets[i]);
	}
	return Plugin_Handled;
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:Command_Admins(client, args)
{
	if (!g_iAdmList) return Plugin_Stop;
	new Adms[MAX_CLIENTS], count = 0;
	for (new i = 1; i <= MaxClients; i++)
	if (IsClientInGame(i) && (GetUserFlagBits(i) & ADMFLAG_GENERIC)) Adms[count++] = i;

	if (count)
	{
		PrintToChatEx(client, client, "---------------------------------------------------");
		for (new i = 0; i < count; i++)
		{
			if ((GetUserFlagBits(Adms[i]) & ADMFLAG_ROOT) && (g_iAdmList & 2)) PrintToChatEx(Adms[i], client, "\x04[ROOT]\x01 \x03%N\x01", Adms[i]);
			else if ((GetUserFlagBits(Adms[i]) & ADMFLAG_GENERIC) && (g_iAdmList & 1)) PrintToChatEx(Adms[i], client, "\x04[ADMIN]\x01 \x03%N\x01", Adms[i]);
		}
		PrintToChatEx(client, client, "---------------------------------------------------");
	}
	return Plugin_Handled;
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:Command_Swap(client, args)
{
	if (!args)
	{
		ReplyToCommand(client, "[SM] Usage: sm_swap <target>");
		return Plugin_Handled;
	}
	decl String:pattern[MAX_NAME];
	GetCmdArg(1, pattern, sizeof(pattern));

	new cl = FindTarget(client, pattern);

	if (cl != -1)
	{
		SwapPlayer(client, cl);
		if(IsPlayerAlive(cl))
			CS_RespawnPlayer(cl);
	}
	else
	{
		ReplyToCommand(client, "%t", "No target", YELLOW, TEAMCOLOR, pattern, YELLOW);
	}

	return Plugin_Handled;
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:Command_LSwap(client, args)
{
	if (!args)
	{
		ReplyToCommand(client, "[SM] Usage: sm_lswap <target>");
		return Plugin_Handled;
	}
	decl String:pattern[MAX_NAME];
	GetCmdArg(1, pattern, sizeof(pattern));

	new cl = FindTarget(client, pattern);

	if (cl != -1)
		SwapPlayerRound(client, cl);
	else
		ReplyToCommand(client, "%t", "No target", YELLOW, TEAMCOLOR, pattern, YELLOW);

	return Plugin_Handled;	
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:Command_Exchange(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_exch <target1> <target2>");
		return Plugin_Handled;
	}

	new String:p1[MAX_NAME], String:p2[MAX_NAME];
	GetCmdArg(1, p1, sizeof(p1));
	GetCmdArg(2, p2, sizeof(p2));

	new cl1 = FindTarget(client, p1);
	new cl2 = FindTarget(client, p2);

	if (cl1 == -1) ReplyToCommand(client, "%t", "No target", YELLOW, TEAMCOLOR, p1, YELLOW);
	if (cl2 == -1) ReplyToCommand(client, "%t", "No target", YELLOW, TEAMCOLOR, p2, YELLOW);

	if ((cl1 > 0) && (cl2 > 0)) ExchangePlayers(client, cl1, cl2);

	return Plugin_Handled;	
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:Command_LExchange(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_lexch <target1> <target2>");
		return Plugin_Handled;
	}

	new String:p1[MAX_NAME], String:p2[MAX_NAME];
	GetCmdArg(1, p1, sizeof(p1));
	GetCmdArg(2, p2, sizeof(p2));

	new cl1 = FindTarget(client, p1);
	new cl2 = FindTarget(client, p2);

	if (cl1 == -1) ReplyToCommand(client, "%t", "No target", YELLOW, TEAMCOLOR, p1, YELLOW);
	if (cl2 == -1) ReplyToCommand(client, "%t", "No target", YELLOW, TEAMCOLOR, p2, YELLOW);

	if ((cl1 > 0) && (cl2 > 0)) ExchangePlayersRound(client, cl1, cl2);

	return Plugin_Handled;	
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:Command_GetModel(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_getmodel <target>");
		return Plugin_Handled;
	}
	decl String:pattern[MAX_NAME], String:buffer[PLATFORM_MAX_PATH];
	GetCmdArg(1, pattern, sizeof(pattern));
	new targets[MAX_CLIENTS], bool:ml = false;

	new count = ProcessTargetString(pattern, client, targets, sizeof(targets), FILTER_REAL, buffer, sizeof(buffer), ml);

	if (count <= 0) ReplyToCommand(client, "%t", (count < 0)?"Bad target":"No target", YELLOW, TEAMCOLOR, pattern, YELLOW);
	else for (new i = 0; i < count; i++)
	{
		new t = targets[i];
		GetClientModel(t, buffer, sizeof(buffer));
		GetClientName(t, pattern, sizeof(pattern));
		PrintToChatEx(t, client, "%t", "Get Model Notify", YELLOW, TEAMCOLOR, pattern, YELLOW, GREEN, buffer, YELLOW);
	}

	return Plugin_Handled;
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:Command_SetModel(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_setmodel <target> <model>");
		return Plugin_Handled;
	}
	decl String:pattern[MAX_NAME], String:buffer[MAX_NAME], String:model[PLATFORM_MAX_PATH];
	GetCmdArg(1, pattern, sizeof(pattern));
	GetCmdArg(2, model, sizeof(model));
	if (!FileExists(model))
	{
		ReplyToCommand(client, "[SM] %s not found", model);
		return Plugin_Handled;
	}
	new targets[MAX_CLIENTS], bool:ml = false;

	new count = ProcessTargetString(pattern, client, targets, sizeof(targets), FILTER_ALIVE, buffer, sizeof(buffer), ml);

	if (count <= 0) ReplyToCommand(client, "%t", (count < 0)?"Bad target":"No target", YELLOW, TEAMCOLOR, pattern, YELLOW);
	else for (new i = 0; i < count; i++)
	{
		new t = targets[i];
		//SDKCall(hSetModel, t, model);
		SetEntityModel(t, model);
		if (!ml) Notify(client, t, "Set Model Notify", model);
	}
	if (ml) Notify2(client, buffer, "Set Model Notify", model);

	return Plugin_Handled;
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:Command_DropSlot(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_dropslot <target> <slot>");
		return Plugin_Handled;
	}
	decl String:pattern[MAX_NAME], String:buffer[MAX_NAME], String:s_slot[MAX_ID];
	GetCmdArg(1, pattern, sizeof(pattern));
	GetCmdArg(2, s_slot, sizeof(s_slot));
	new slot = StringToInt(s_slot);
	new targets[MAX_CLIENTS], bool:ml = false;

	new count = ProcessTargetString(pattern, client, targets, sizeof(targets), FILTER_ALIVE, buffer, sizeof(buffer), ml);

	if (count <= 0) ReplyToCommand(client, "%t", (count < 0)?"Bad target":"No target", YELLOW, TEAMCOLOR, pattern, YELLOW);
	else for (new i = 0; i < count; i++)
	{
		new t = targets[i];
		new ent = GetPlayerWeaponSlot(t, slot);
		if (ent != -1)
		{
			DropWeapon(t, ent);
			if (g_bLog) LogAction(client, t, "\"%L\" dropped weapon from slot %d of player \"%L\"", client, slot, t);
			if (!ml) Notify(client, t, "Drop Slot Notify", slot);
		}
	}
	if (ml) Notify2(client, buffer, "Drop Slot Notify", slot);

	return Plugin_Handled;
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:Command_Drop(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_drop <target> <weapon>");
		return Plugin_Handled;
	}
	decl String:pattern[MAX_NAME], String:buffer[MAX_NAME], String:weapon[MAX_ID], String:edict[MAX_ID];
	GetCmdArg(1, pattern, sizeof(pattern));
	GetCmdArg(2, weapon, sizeof(weapon));
	if (StrContains(weapon, "weapon_") == -1)
	{
		decl String:tmp[MAX_ID];
		Format(tmp, sizeof(tmp), "weapon_%s", weapon);
		strcopy(weapon, sizeof(weapon), tmp);
	}
	new targets[MAX_CLIENTS], bool:ml = false;

	new count = ProcessTargetString(pattern, client, targets, sizeof(targets), FILTER_ALIVE, buffer, sizeof(buffer), ml);

	if (count <= 0) ReplyToCommand(client, "%t", (count < 0)?"Bad target":"No target", YELLOW, TEAMCOLOR, pattern, YELLOW);
	else for (new i = 0; i < count; i++)
	{
		new t = targets[i];
		for (new j = 0; j < 5; j++)
		{
			new ent = GetPlayerWeaponSlot(t, j);
			if ((ent != -1) && GetEdictClassname(ent, edict, sizeof(edict)) && StrEqual(weapon, edict))
			{
				DropWeapon(t, ent);
				
				if (g_bLog) LogAction(client, t, "\"%L\" dropped weapon %s from player \"%L\"", client, weapon, t);
				if (!ml) Notify(client, t, "Drop Weapon Notify", weapon);
			}
		}
	} 
	if (ml) Notify2(client, buffer, "Drop Weapon Notify", weapon);

	return Plugin_Handled;
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:Command_Bury(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_bury <target>");
		return Plugin_Handled;
	}
	decl String:pattern[MAX_NAME], String:buffer[MAX_NAME];
	GetCmdArg(1, pattern, sizeof(pattern));
	new targets[MAX_CLIENTS], bool:ml = false;

	new count = ProcessTargetString(pattern, client, targets, sizeof(targets), FILTER_ALIVE, buffer, sizeof(buffer), ml);

	new Float:vec[3];
	if (count <= 0) ReplyToCommand(client, "%t", (count < 0)?"Bad target":"No target", YELLOW, TEAMCOLOR, pattern, YELLOW);
	else for (new i = 0; i < count; i++)
	{
		new t = targets[i];
		GetEntPropVector(t, Prop_Send, "m_vecOrigin", vec);

		vec[2] -= 30.0;
		SetEntPropVector(t, Prop_Send, "m_vecOrigin", vec);

		if (g_bLog) LogAction(client, t, "\"%L\" buried player \"%L\"", client, t);
		if (!ml) Notify(client, t, "Bury Notify");
	}
	if (ml) Notify2(client, buffer, "Bury Notify");

	return Plugin_Handled;
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:Command_Unbury(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_unbury <target>");
		return Plugin_Handled;
	}
	decl String:pattern[MAX_NAME], String:buffer[MAX_NAME];
	GetCmdArg(1, pattern, sizeof(pattern));
	new targets[MAX_CLIENTS], bool:ml = false;

	new count = ProcessTargetString(pattern, client, targets, sizeof(targets), FILTER_ALIVE, buffer, sizeof(buffer), ml);

	new Float:vec[3];
	if (count <= 0) ReplyToCommand(client, "%t", (count < 0)?"Bad target":"No target", YELLOW, TEAMCOLOR, pattern, YELLOW);
	else for (new i = 0; i < count; i++)
	{
		new t = targets[i];
		GetEntPropVector(t, Prop_Send, "m_vecOrigin", vec);

		vec[2] += 30.0;
		SetEntPropVector(t, Prop_Send, "m_vecOrigin", vec);

		if (g_bLog) LogAction(client, t, "\"%L\" unburied player \"%L\"", client, t);
		if (!ml) Notify(client, t, "Unbury Notify");
	}
	if (ml) Notify2(client, buffer, "Unbury Notify");

	return Plugin_Handled;
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:Command_Respawn(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_respawn <target>");
		return Plugin_Handled;
	}
	decl String:pattern[MAX_NAME], String:buffer[MAX_NAME];
	GetCmdArg(1, pattern, sizeof(pattern));
	new targets[MAX_CLIENTS], bool:ml = false;

	new count = ProcessTargetString(pattern, client, targets, sizeof(targets), FILTER_REAL, buffer, sizeof(buffer), ml);

	if (count <= 0) ReplyToCommand(client, "%t", (count < 0)?"Bad target":"No target", YELLOW, TEAMCOLOR, pattern, YELLOW);
	else for (new i = 0; i < count; i++)
	{
		new t = targets[i];
		switch (game)
		{
#if !defined FORCESDK
			case GAME_CSTRIKE :	CS_RespawnPlayer(t);
			case GAME_CSGO : 	CS_RespawnPlayer(t);
			case GAME_TF2 :		TF2_RespawnPlayer(t);
#endif
			default :
				SDKCall(hRespawn, t);
		}
		if (g_bLog) LogAction(client, t, "\"%L\" respawned player \"%L\"", client, t);
		if (!ml) Notify(client, t, "Respawn Notify");
	}
	if (ml) Notify2(client, buffer, "Respawn Notify");

	return Plugin_Handled;
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:Command_Disarm(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_disarm <target>");
		return Plugin_Handled;
	}
	decl String:pattern[MAX_NAME], String:buffer[MAX_NAME];
	GetCmdArg(1, pattern, sizeof(pattern));
	new targets[MAX_CLIENTS], bool:ml = false;

	new count = ProcessTargetString(pattern, client, targets, sizeof(targets), COMMAND_FILTER_ALIVE, buffer, sizeof(buffer), ml);

	if (count <= 0) ReplyToCommand(client, "%t", (count < 0)?"Bad target":"No target", YELLOW, TEAMCOLOR, pattern, YELLOW);
	else for (new i = 0; i < count; i++)
	{
		new t = targets[i];
#if !defined FORCESDK
		if (game == GAME_TF2) TF2_RemoveAllWeapons(t); else
		if (game & GAME_CSGO|GAME_CSTRIKE) Client_RemoveAllWeapons(t); else
#endif
		if (hDisarm != INVALID_HANDLE) SDKCall(hDisarm, t, false);
		else
		for (new j = 0; j < 5; j++)
		{
			new w = -1;
			while ((w = GetPlayerWeaponSlot(t, j)) != -1)
				if (IsValidEntity(w)) RemovePlayerItem(t, w);
		}
		if (g_bLog) LogAction(client, t, "\"%L\" disarmed player \"%L\"", client, t);
		if (!ml) Notify(client, t, "Disarm Notify");
	}
	if (ml) Notify2(client, buffer, "Disarm Notify");

	return Plugin_Handled;
}
//------------------------------------------------------------------------------------------------------------------------------------
Melee(bool:s)
{
	// Weapon slot mask to remove weapons from
	// Use like 1+2+3 => (1<<0)|(1<<1)|(1<<2) = 7

	new wslots = 11; // 0, 1, 3 (1h, 2h, 8h)
	new mslot = 2;
	switch (game)
	{
		case GAME_HL2MP : {
				wslots = 30; // 1, 2, 3, 4 (2h, 4h, 8h, 10h)
				mslot = 0;
			}
		case GAME_LEFT4DEAD : {
				wslots = 5; // 0, 2 (1h, 4h)
				mslot = 1;
			}
		case GAME_LEFT4DEAD2 : {
				wslots = 5; // 0, 2 (1h, 4h)
				mslot = 1;
			}
	}

	for (new i = 1; i <= MaxClients; i++)
	if (IsClientInGame(i) && IsPlayerAlive(i))
	{
		for (new j = 0; j < 5; j++)
		if (wslots & (1<<j))
		{
			new w = -1;
			while ((w = GetPlayerWeaponSlot(i, j)) != -1)
				if (IsValidEntity(w)) RemovePlayerItem(i, w);
		}
		if (s)
		{
			new m = GetPlayerWeaponSlot(i, mslot);
			if (IsValidEntity(m)) EquipPlayerWeapon(i, m);
		}
	}
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:Command_Melee(client, args)
{
	Melee(true);
	Notify(client, client, "Melee Notify");
	if (g_bLog) LogAction(client, -1, "\"%L\" set all players to melee", client);
	return Plugin_Handled;
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:Command_Equip(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_equip <weapon>");
		return Plugin_Handled;
	}
	Melee(false);
	decl String:ent[MAX_BUFF_SM];
	GetCmdArg(1, ent, sizeof(ent));
	decl String:weapon[MAX_NAME];
	GetCmdArg(1, weapon, sizeof(weapon));
	for (new i = 1; i <= MaxClients; i++)
	if (IsClientInGame(i) && IsPlayerAlive(i))
	{
		if ((GivePlayerItem(i, weapon) == -1) && StrEqual(ent, weapon))
		{
			Format(weapon, sizeof(weapon), "weapon_%s", ent);
			i--;
		}
	}
	Notify(client, client, "Equip Notify", ent);
	if (g_bLog) LogAction(client, -1, "\"%L\" equipped all players with %s", client, ent);
	return Plugin_Handled;
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:Command_Give(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_give <target> <entity>");
		return Plugin_Handled;	
	}	
	decl String:pattern[MAX_NAME], String:buffer[MAX_NAME], String:ent[MAX_NAME];
	GetCmdArg(1, pattern, sizeof(pattern));
	GetCmdArg(2, ent, sizeof(ent));
	new targets[MAX_CLIENTS], bool:ml = false;
	decl String:weapon[MAX_NAME];
	GetCmdArg(2, weapon, sizeof(weapon));

	new count = ProcessTargetString(pattern, client, targets, sizeof(targets), FILTER_ALIVE, buffer, sizeof(buffer), ml);

	if (count <= 0) ReplyToCommand(client, "%t", (count < 0)?"Bad target":"No target", YELLOW, TEAMCOLOR, pattern, YELLOW);
	else for (new i = 0; i < count; i++)
	{
		new t = targets[i];
		if ((GivePlayerItem(t, weapon) == -1) && StrEqual(ent, weapon))
		{
			Format(weapon, sizeof(weapon), "weapon_%s", ent);
			i--;
			continue;
		} else
		{
			if (!ml) Notify(client, t, "Give Notify", ent);
			if (g_bLog) LogAction(client, t, "\"%L\" gave item %s to player \"%L\"", client, ent, t);
		}
	}
	if (ml) Notify2(client, buffer, "Give Notify", ent);

	return Plugin_Handled;
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:Command_Speed(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_speed <target> <multiplier>");
		return Plugin_Handled;	
	}	
	decl String:pattern[MAX_NAME], String:buffer[MAX_NAME], String:mul[MAX_ID];
	GetCmdArg(1, pattern, sizeof(pattern));
	GetCmdArg(2, mul, sizeof(mul));
	new Float:mult = StringToFloat(mul);
	new targets[MAX_CLIENTS], bool:ml = false;

	new count = ProcessTargetString(pattern, client, targets, sizeof(targets), FILTER_ALIVE, buffer, sizeof(buffer), ml);

	if (count <= 0) ReplyToCommand(client, "%t", (count < 0)?"Bad target":"No target", YELLOW, TEAMCOLOR, pattern, YELLOW);
	else for (new i = 0; i < count; i++)
	{
		new t = targets[i];
		SetEntPropFloat(t, Prop_Data, "m_flLaggedMovementValue", mult);
		if (!ml) Notify(client, t, "Speed Notify", mult);
		if (g_bLog) LogAction(client, t, "\"%L\" set speed of player \"%L\" to %.1f", client, t, mult);
	}
	if (ml) Notify2(client, buffer, "Speed Notify", mult);


	return Plugin_Handled;
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:Command_Armour(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_armour <target> <[+/-]armour>");
		return Plugin_Handled;	
	}	
	decl String:pattern[MAX_NAME], String:buffer[MAX_NAME], String:arm[MAX_ID];
	GetCmdArg(1, pattern, sizeof(pattern));
	GetCmdArg(2, arm, sizeof(arm));
	new armour = StringToInt(arm);
	new targets[MAX_CLIENTS], bool:ml = false;

	new count = ProcessTargetString(pattern, client, targets, sizeof(targets), FILTER_ALIVE, buffer, sizeof(buffer), ml);

	if (count <= 0) ReplyToCommand(client, "%t", (count < 0)?"Bad target":"No target", YELLOW, TEAMCOLOR, pattern, YELLOW);
	else for (new i = 0; i < count; i++)
	{
		new t = targets[i];
		new val = GetEntProp(t, Prop_Send, "m_ArmorValue");
		if ((arm[0] == '+') || (arm[0] == '-'))
		{
			val += armour;
			if (val < 0) val = 0;
			if (!ml) Notify(client, t, "Armour Change Notify", val, arm);
			if (g_bLog) LogAction(client, t, "\"%L\" set armour of player \"%L\" to %d [%s]", client, t, val, arm);
		} else
		{
			val = armour;
			if (!ml) Notify(client, t, "Armour Set Notify", arm);
			if (g_bLog) LogAction(client, t, "\"%L\" set armour of player \"%L\" to %d", client, t, armour);
		}
		SetEntProp(targets[i], Prop_Send, "m_ArmorValue", val);

		if (game == GAME_CSTRIKE || game == GAME_CSGO) SetEntProp(t, Prop_Send, "m_bHasHelmet", val?1:0);
	}
	if (ml) Notify2(client, buffer, "Armour Set Notify", arm);

	return Plugin_Handled;
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:Command_HP(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_hp <target> <[+/-]hp>");
		return Plugin_Handled;	
	}	
	decl String:pattern[MAX_NAME], String:buffer[MAX_NAME], String:health[MAX_ID];
	GetCmdArg(1, pattern, sizeof(pattern));
	GetCmdArg(2, health, sizeof(health));
	new hp = StringToInt(health);
	new targets[MAX_CLIENTS], bool:ml = false;

	new count = ProcessTargetString(pattern, client, targets, sizeof(targets), FILTER_ALIVE, buffer, sizeof(buffer), ml);

	if (count <= 0) ReplyToCommand(client, "%t", (count < 0)?"Bad target":"No target", YELLOW, TEAMCOLOR, pattern, YELLOW);
	else for (new i = 0; i < count; i++)
	{
		new t = targets[i];
		new val = GetEntProp(t, Prop_Send, "m_iHealth");
		if ((health[0] == '+') || (health[0] == '-'))
		{
			val += hp;
			if (val < 0) val = 0;
			if (!ml) Notify(client, t, "Health Change Notify", val, health);
			if (g_bLog) LogAction(client, t, "\"%L\" set health of player \"%L\" to %d [%s]", client, t, val, health);
		} else
		{
			val = hp;
			if (!ml) Notify(client, t, "Health Set Notify", health);
			if (g_bLog) LogAction(client, t, "\"%L\" set health of player \"%L\" to %d", client, t, hp);
		}

		SetEntProp(t, Prop_Send, "m_iHealth", hp);
	}
	if (ml) Notify2(client, buffer, "Health Set Notify", health);

	return Plugin_Handled;
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:Command_Cash(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_cash <target> <[+/-]amount>");
		return Plugin_Handled;	
	}	
	decl String:pattern[MAX_NAME], String:buffer[MAX_NAME], String:cash[MAX_ID];
	GetCmdArg(1, pattern, sizeof(pattern));
	GetCmdArg(2, cash, sizeof(cash));
	new csh = StringToInt(cash);
	new targets[MAX_CLIENTS], bool:ml = false;

	new count = ProcessTargetString(pattern, client, targets, sizeof(targets), FILTER_REAL, buffer, sizeof(buffer), ml);

	if (count <= 0) ReplyToCommand(client, "%t", (count < 0)?"Bad target":"No target", YELLOW, TEAMCOLOR, pattern, YELLOW);
	else for (new i = 0; i < count; i++)
	{
		new t = targets[i];
		if(!IsClientInGame(t) || !IsValidEntity(t))
		{
			return Plugin_Continue;
		}
			
		new val = GetEntProp(t, Prop_Send, "m_iAccount");
		if ((cash[0] == '+') || (cash[0] == '-'))
		{
			val += csh;
			if (val < 0) val = 0;
			if (!ml) Notify(client, t, "Cash Change Notify", val, cash);
			if (g_bLog) LogAction(client, t, "\"%L\" changed cash of player \"%L\" to %d [%s]", client, t, val, cash);
		} else
		{
			val = csh;
			if (!ml) Notify(client, t, "Cash Set Notify", cash);
			if (g_bLog) LogAction(client, t, "\"%L\" changed cash of player \"%L\" to %d", client, t, csh);
		}
		SetEntProp(t, Prop_Send, "m_iAccount", val);
	}
	if (ml) Notify2(client, buffer, "Cash Set Notify", cash);
	return Plugin_Handled;
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:Command_Frags(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_frags <target> <[+/-]amount>");
		return Plugin_Handled;	
	}	
	decl String:pattern[MAX_NAME], String:buffer[MAX_NAME], String:frags[MAX_ID];
	GetCmdArg(1, pattern, sizeof(pattern));
	GetCmdArg(2, frags, sizeof(frags));
	new frag = StringToInt(frags);
	new targets[MAX_CLIENTS], bool:ml = false;

	new count = ProcessTargetString(pattern, client, targets, sizeof(targets), FILTER_REAL, buffer, sizeof(buffer), ml);

	if (count <= 0) ReplyToCommand(client, "%t", (count < 0)?"Bad target":"No target", YELLOW, TEAMCOLOR, pattern, YELLOW);
	else for (new i = 0; i < count; i++)
	{
		new t = targets[i];
		new val = GetClientFrags(t);
		if ((frags[0] == '+') || (frags[0] == '-'))
		{
			val += frag;
			if (val < 0) val = 0;
			if (!ml) Notify(client, t, "Frags Change Notify", val, frags);
			if (g_bLog) LogAction(client, t, "\"%L\" changed frags of player \"%L\" to %d [%s]", client, t, val, frags);
		} else
		{
			val = frag;
			if (!ml) Notify(client, t, "Frags Set Notify", frags);
			if (g_bLog) LogAction(client, t, "\"%L\" changed frags of player \"%L\" to %d", client, t, frag);
		}
		SetEntProp(t, Prop_Data, "m_iFrags", val);
	}
	if (ml) Notify2(client, buffer, "Frags Set Notify", frags);
	return Plugin_Handled;
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:Command_Deaths(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_deaths <target> <[+/-]amount>");
		return Plugin_Handled;	
	}	
	decl String:pattern[MAX_NAME], String:buffer[MAX_NAME], String:deaths[MAX_ID];
	GetCmdArg(1, pattern, sizeof(pattern));
	GetCmdArg(2, deaths, sizeof(deaths));
	new death = StringToInt(deaths);
	new targets[MAX_CLIENTS], bool:ml = false;

	new count = ProcessTargetString(pattern, client, targets, sizeof(targets), FILTER_REAL, buffer, sizeof(buffer), ml);

	if (count <= 0) ReplyToCommand(client, "%t", (count < 0)?"Bad target":"No target", YELLOW, TEAMCOLOR, pattern, YELLOW);
	else for (new i = 0; i < count; i++)
	{
		new t = targets[i];
		new val = GetClientDeaths(t);
		if ((deaths[0] == '+') || (deaths[0] == '-'))
		{
			val += death;
			if (val < 0) val = 0;
			if (!ml) Notify(client, t, "Deaths Change Notify", val, deaths);
			if (g_bLog) LogAction(client, t, "\"%L\" changed deaths of player \"%L\" to %d [%s]", client, t, val, deaths);
		} else
		{
			val = death;
			if (!ml) Notify(client, t, "Deaths Set Notify", death);
			if (g_bLog) LogAction(client, t, "\"%L\" changed deaths of player \"%L\" to %d", client, t, death);
		}
		SetEntProp(t, Prop_Data, "m_iDeaths", val);
	}
	if (ml) Notify2(client, buffer, "Deaths Set Notify", deaths);
	return Plugin_Handled;
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:Command_Balance(client, args)
{
	Balance(false);
	if (g_bLog) LogAction(client, -1, "\"%L\" balanced teams", client);
	return Plugin_Handled;
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:Command_Shuffle(client, args)
{
	Balance(false);
	new m = 0, c1 = 0, c2 = 0;
	new pl1[MAX_CLIENTS], pl2[MAX_CLIENTS];
	for (new i = 1; i <= MaxClients; i++)
	if (IsClientInGame(i)) switch (GetClientTeam(i))
	{
		case TEAM1 : pl1[c1++] = i;
		case TEAM2 : pl2[c2++] = i;
	}
	m = c1-- +c2--;
	if (m < 2) return Plugin_Handled;

	if (m%4) m += 3;
	m /= 4;

	while (m)
	{
		new mi1 = GetRandomInt(0, c1);
		new mi2 = GetRandomInt(0, c2);

		if ((pl1[mi1] != -1) && (pl2[mi2] != -1))
		{
			ChangeClientTeamEx(pl1[mi1], TEAM2);
			ChangeClientTeamEx(pl2[mi2], TEAM1);

			pl1[mi1] = pl2[mi2] = -1;
			m--;
		}
	}
	if (g_bLog) LogAction(client, -1, "\"%L\" shuffled teams", client);
	return Plugin_Handled;
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:Command_TeamSwap(client, args)
{
	for (new i = 1; i <= MaxClients; i++)
	if (IsClientInGame(i)) switch (GetClientTeam(i))
	{
		case TEAM1 : ChangeClientTeamEx(i, TEAM2);
		case TEAM2 : ChangeClientTeamEx(i, TEAM1);
	}
	new ts = GetTeamScore(TEAM1);
	SetTeamScore(TEAM1, GetTeamScore(TEAM2));
	SetTeamScore(TEAM2, ts);

	if (g_bLog) LogAction(client, -1, "\"%L\" swapped teams", client);
	return Plugin_Handled;
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:Command_Team(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_team <target> <team>");
		return Plugin_Handled;	
	}	
	decl String:pattern[MAX_NAME], String:buffer[MAX_NAME], String:team[MAX_ID];
	GetCmdArg(1, pattern, sizeof(pattern));
	GetCmdArg(2, team, sizeof(team));
	new tm = StringToInt(team);
	new targets[MAX_CLIENTS], bool:ml = false;

	new count = ProcessTargetString(pattern, client, targets, sizeof(targets), FILTER_REAL, buffer, sizeof(buffer), ml);

	if (count <= 0) ReplyToCommand(client, "%t", (count < 0)?"Bad target":"No target", YELLOW, TEAMCOLOR, pattern, YELLOW);
	else for (new i = 0; i < count; i++)
	{
		ChangeClientTeamEx(targets[i], tm);
		if (g_bLog) LogAction(client, targets[i], "\"%L\" set team of player \"%L\" to %d", client, targets[i], tm);
	}
	return Plugin_Handled;
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:Command_Spec(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_spec <target>");
		return Plugin_Handled;	
	}	
	decl String:pattern[MAX_NAME], String:buffer[MAX_NAME];
	GetCmdArg(1, pattern, sizeof(pattern));
	new targets[MAX_CLIENTS], bool:ml;

	new count = ProcessTargetString(pattern, client, targets, sizeof(targets), FILTER_REAL, buffer, sizeof(buffer), ml);

	if (count <= 0) ReplyToCommand(client, "%t", (count < 0)?"Bad target":"No target", YELLOW, TEAMCOLOR, pattern, YELLOW);
	else for (new i = 0; i < count; i++)
	{
		new t = targets[i];
		if (IsPlayerAlive(t)) ForcePlayerSuicide(t);

		ChangeClientTeam(t, SPEC);
		if (g_bLog) LogAction(client, t, "\"%L\" moved player \"%L\" to spectators", client, t);
	}
	return Plugin_Handled;
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:Command_Exec(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_exec <target> <cmd>");
		return Plugin_Handled;	
	}	
	decl String:pattern[MAX_NAME], String:buffer[MAX_NAME], String:cmd[128];
	GetCmdArg(1, pattern, sizeof(pattern));
	GetCmdArg(2, cmd, sizeof(cmd));
	new targets[MAX_CLIENTS], bool:ml;

	new count = ProcessTargetString(pattern, client, targets, sizeof(targets), FILTER_REAL|COMMAND_FILTER_NO_BOTS, buffer, sizeof(buffer), ml);

	if (count <= 0) ReplyToCommand(client, "%t", (count < 0)?"Bad target":"No target", YELLOW, TEAMCOLOR, pattern, YELLOW);
	else for (new i = 0; i < count; i++)
	{
		ClientCommand(targets[i], cmd);
		if (g_bLog) LogAction(client, targets[i], "\"%L\" executed command \"%s\" on \"%L\"", client, cmd, targets[i]);
	}
	return Plugin_Handled;
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:BotSay( client, args )
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_botsay <target> \"Message to have bot say\"");
		return Plugin_Handled;
	}
	
	decl String:who[MAX_NAME_LENGTH], String:msg[192];
	GetCmdArg(1, who, sizeof(who));
	GetCmdArg(2, msg, sizeof(msg));
	
	decl String:target_name[MAX_NAME_LENGTH];
	decl target_list[MAXPLAYERS];
	decl target_count;
	decl bool:tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			who, 
			client, 
			target_list, 
			MAXPLAYERS, 
			COMMAND_FILTER_NO_IMMUNITY, 
			target_name, 
			sizeof(target_name), 
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	Format(msg, sizeof(msg), "say %s", msg);
	
	for (new i = 0; i < target_count; i++)
	{
		if(IsFakeClient(target_list[i]))
			FakeClientCommandEx(target_list[i], msg);
	}	
	return Plugin_Handled;
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:Command_FExec(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_fexec <target> <cmd>");
		return Plugin_Handled;	
	}	
	decl String:pattern[MAX_NAME], String:buffer[MAX_NAME], String:cmd[MAX_BUFF_SM];
	GetCmdArg(1, pattern, sizeof(pattern));
	GetCmdArg(2, cmd, sizeof(cmd));
	new targets[MAX_CLIENTS], bool:ml;

	new count = ProcessTargetString(pattern, client, targets, sizeof(targets), FILTER_REAL|COMMAND_FILTER_NO_BOTS, buffer, sizeof(buffer), ml);

	if (count <= 0) ReplyToCommand(client, "%t", (count < 0)?"Bad target":"No target", YELLOW, TEAMCOLOR, pattern, YELLOW);
	else for (new i = 0; i < count; i++)
	{
		FakeClientCommandEx(targets[i], cmd);
		if (g_bLog) LogAction(client, targets[i], "\"%L\" fake-executed command \"%s\" on \"%L\"", client, cmd, targets[i]);
	}
	return Plugin_Handled;
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:Command_Location(client, args)
{
	decl String:name[64];
	new Float:origin[3];
	if (args)
	{
		decl String:pattern[MAX_NAME], String:buffer[MAX_NAME];
		GetCmdArg(1, pattern, sizeof(pattern));
		new targets[MAX_CLIENTS], bool:ml;

		new count = ProcessTargetString(pattern, client, targets, sizeof(targets), FILTER_REAL, buffer, sizeof(buffer), ml);

		for (new i = 0; i < count; i++)
		{
			new t = targets[i];
			GetEntPropVector(t, Prop_Send, "m_vecOrigin", origin);
			GetClientName(t, name, sizeof(name));
			PrintToChatEx(t, client, "%t", "Get Location Notify", YELLOW, TEAMCOLOR, name, YELLOW, GREEN, origin[0], origin[1], origin[2], YELLOW);
		}
	} else if (client)
	{
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", origin);
		GetClientName(client, name, sizeof(name));
		PrintToChatEx(client, client, "%t", "Get Location Notify", YELLOW, TEAMCOLOR, name, YELLOW, GREEN, origin[0], origin[1], origin[2], YELLOW);
	}
	return Plugin_Handled;
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:Command_SaveLoc(client, args)
{
	if (args > 2)
	{
		decl String:ax[16];
		GetCmdArg(1, ax, sizeof(ax));
		coords[client][0] = StringToFloat(ax);
		GetCmdArg(2, ax, sizeof(ax));
		coords[client][1] = StringToFloat(ax);
		GetCmdArg(3, ax, sizeof(ax));
		coords[client][2] = StringToFloat(ax);	
	} else if (client)
	{
		new Float:origin[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", origin);
		coords[client][0] = origin[0];
		coords[client][1] = origin[1];
		coords[client][2] = origin[2];
	}
	PrintToChatEx(client, client, "%t", "Save Location Notify", YELLOW, GREEN, coords[client][0], coords[client][1], coords[client][2], YELLOW);
	
	return Plugin_Handled;
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:Command_Teleport(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_teleport <target> [x|client] [y] [z]");
		return Plugin_Handled;	
	}

	new Float:origin[3];
	if (args > 3)
	{
		decl String:ax[MAX_ID];
		GetCmdArg(2, ax, sizeof(ax));
		origin[0] = StringToFloat(ax);
		GetCmdArg(3, ax, sizeof(ax));
		origin[1] = StringToFloat(ax);
		GetCmdArg(4, ax, sizeof(ax));
		origin[2] = StringToFloat(ax);	
	} else
	if (args > 1)
	{
		decl String:cl[MAX_NAME];
		GetCmdArg(2, cl, sizeof(cl));
		new tgt = FindTarget(client, cl);
		if ((tgt != -1) && IsValidEntity(tgt)) GetEntPropVector(tgt, Prop_Send, "m_vecOrigin", origin);
		else
		{
			ReplyToCommand(client, "%t", "Bad target", YELLOW, TEAMCOLOR, cl, YELLOW);
			return Plugin_Handled;
		}
	} else
	{
		origin[0] = coords[client][0];
		origin[1] = coords[client][1];
		origin[2] = coords[client][2];
	}
	decl String:pattern[MAX_NAME], String:buffer[MAX_NAME];
	GetCmdArg(1, pattern, sizeof(pattern));
	new targets[MAX_CLIENTS], bool:ml = false;

	new count = ProcessTargetString(pattern, client, targets, sizeof(targets), FILTER_ALIVE, buffer, sizeof(buffer), ml);

	if (count <= 0) ReplyToCommand(client, "%t", (count < 0)?"Bad target":"No target", YELLOW, TEAMCOLOR, pattern, YELLOW);
	else for (new i = 0; i < count; i++)
	{
		new t = targets[i];
		TeleportEntity(t, origin, NULL_VECTOR, NULL_VECTOR);
		if (!ml) Notify(client, t, "Teleport Notify", origin[0], origin[1], origin[2]);
		if (g_bLog) LogAction(client, t, "\"%L\" teleported player \"%L\" to %.1f %.1f %.1f", client, t, origin[0], origin[1], origin[2]);
	}
	if (ml) Notify2(client, buffer, "Teleport Notify", origin[0], origin[1], origin[2]);
	
	return Plugin_Handled;
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:Command_Blink(client, args)
{
	new target = client;
	if (args > 0)
	{
		decl String:name[MAX_NAME];
		GetCmdArg(1, name, sizeof(name));
		if ((target = FindTarget(client, name)) == -1)
		{
			ReplyToCommand(client, "%t", "No target", YELLOW, TEAMCOLOR, name, YELLOW);
			return Plugin_Handled;
		}
	}

	decl Float:from[3], Float:angles[3];
	GetClientEyeAngles(target, angles);
	GetClientEyePosition(target, from);

	new Handle:tray = TR_TraceRayEx(from, angles, MASK_SHOT, RayType_Infinite);
	if (TR_DidHit(tray))
	{
		decl Float:pos[3], Float:end[3], Float:cpos[3];

		TR_GetEndPosition(end, tray);

		new Float:dist = GetVectorDistance(from, end) - CLIENTWIDTH;
		pos[2] = end[2];
		pos[1] = (from[1] + (dist * Sine(DegToRad(angles[1]))));
		pos[0] = (from[0] + (dist * Cosine(DegToRad(angles[1]))));

		cpos = pos;
		cpos[2] = (cpos[2] - CLIENTHEIGHT);

		if (!TR_GetPointContents(cpos)) pos[2] = (pos[2] - CLIENTHEIGHT);

		if (!TR_GetPointContents(pos))
		{
			TeleportEntity(target, pos, NULL_VECTOR, NULL_VECTOR);	

			Notify(client, target, "Blink Notify", pos[0], pos[1], pos[2]);
			if (g_bLog) LogAction(client, target, "\"%L\" blinked player \"%L\" to %.1f %.1f %.1f", client, target, pos[0], pos[1], pos[2]);
		}
	}
	CloseHandle(tray);
	return Plugin_Handled;
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:Command_God(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_god <target> <0|1>");
		return Plugin_Handled;	
	}	
	decl String:pattern[MAX_NAME], String:buffer[MAX_NAME], String:god[MAX_ID];
	GetCmdArg(1, pattern, sizeof(pattern));
	GetCmdArg(2, god, sizeof(god));
	new gd = StringToInt(god);
	new targets[MAX_CLIENTS], bool:ml = false;

	new count = ProcessTargetString(pattern, client, targets, sizeof(targets), FILTER_ALIVE, buffer, sizeof(buffer), ml);

	if (count <= 0) ReplyToCommand(client, "%t", (count < 0)?"Bad target":"No target", YELLOW, TEAMCOLOR, pattern, YELLOW);
	else for (new i = 0; i < count; i++)
	{
		SetEntProp(targets[i], Prop_Data, "m_takedamage", gd?0:2, 1);
		if (!ml) Notify(client, targets[i], gd?"God Notify":"NoGod Notify");
		if (g_bLog) LogAction(client, targets[i], "\"%L\" set godmode of player \"%L\" to %d", client, targets[i], gd);
	}
	if (ml) Notify2(client, buffer, gd?"God Notify":"NoGod Notify");
	return Plugin_Handled;
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:Command_NV(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_nv <target> <0|1>");
		return Plugin_Handled;	
	}	
	decl String:pattern[MAX_NAME], String:buffer[MAX_NAME], String:nvs[MAX_ID];
	GetCmdArg(1, pattern, sizeof(pattern));
	GetCmdArg(2, nvs, sizeof(nvs));
	new nv = StringToInt(nvs);
	new targets[MAX_CLIENTS], bool:ml = false;

	new count = ProcessTargetString(pattern, client, targets, sizeof(targets), FILTER_ALIVE, buffer, sizeof(buffer), ml);

	if (count <= 0) ReplyToCommand(client, "%t", (count < 0)?"Bad target":"No target", YELLOW, TEAMCOLOR, pattern, YELLOW);
	else for (new i = 0; i < count; i++)
	{
		new t = targets[i];
		SetEntProp(t, Prop_Send, "m_bHasNightVision", nv?1:0, 1);
		if (!ml) Notify(client, t, nv?"NV Notify":"NoNV Notify");
		if (g_bLog) LogAction(client, t, "\"%L\" set nightvision of player \"%L\" to %d", client, t, nv);
	}
	if (ml) Notify2(client, buffer, nv?"NV Notify":"NoNV Notify");
	return Plugin_Handled;
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:Command_Defuser(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_defuser <target> <0|1>");
		return Plugin_Handled;	
	}	
	decl String:pattern[MAX_NAME], String:buffer[MAX_NAME], String:def[MAX_ID];
	GetCmdArg(1, pattern, sizeof(pattern));
	GetCmdArg(2, def, sizeof(def));
	new df = StringToInt(def);
	new targets[MAX_CLIENTS], bool:ml = false;

	new count = ProcessTargetString(pattern, client, targets, sizeof(targets), FILTER_ALIVE, buffer, sizeof(buffer), ml);

	if (!count) ReplyToCommand(client, "%t", "No target", YELLOW, TEAMCOLOR, pattern, YELLOW);
	else for (new i = 0; i < count; i++)
	{
		new t = targets[i];
		if (GetClientTeam(t) == CS_TEAM_CT)
		{
			SetEntProp(t, Prop_Send, "m_bHasDefuser", df?1:0, 1);
			if (!ml) Notify(client, t, df?"Defuser Notify":"NoDefuser Notify");
			if (g_bLog) LogAction(client, t, "\"%L\" set defuser of player \"%L\" to %d", client, t, df);
		}
	}
	if (ml) Notify2(client, buffer, df?"Defuser Notify":"NoDefuser Notify");
	return Plugin_Handled;
}
//------------------------------------------------------------------------------------------------------------------------------------
ExtendMap(client, mins)
{
	ExtendMapTimeLimit(mins*60);

	Notify(client, client, "Extend Notify", mins);
	if (g_bLog) LogAction(client, -1, "\"%L\" extended map for %d minutes", client, mins);
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:Command_RR(client, args)
{
	new t = 1;
	if (args)
	{
		decl String:ax[MAX_ID];
		GetCmdArg(1, ax, sizeof(ax));
		t = StringToInt(ax);
	}	
	ServerCommand("mp_restartgame %d", t);

	Notify(client, client, "RR Notify", t);
	if (g_bLog) LogAction(client, -1, "\"%L\" restarted game in %d sec", client, t);
	return Plugin_Handled;	
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:Command_Extend(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_extend <minutes>");
		return Plugin_Handled;	
	}	
	decl String:m[MAX_ID];
	GetCmdArg(1, m, sizeof(m));
	ExtendMap(client, StringToInt(m));

	return Plugin_Handled;	
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:Command_Shutdown(client, args)
{
	new Float:to = 5.0;
	if (args)
	{
		decl String:ax[MAX_ID];
		GetCmdArg(1, ax, sizeof(ax));
		to = StringToFloat(ax);
	}
	PrintToChatAllEx(client, "%t", "Shutdown Notify", YELLOW, GREEN, to, YELLOW);
	if (g_bLog) LogAction(client, -1, "\"%L\" shuts down the server in %.1f seconds", client, to);
	CreateTimer(to, Shutdown);
	return Plugin_Handled;
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:Shutdown(Handle:timer)
{
	for (new i = 1; i <= MaxClients; i++)
	if (IsClientInGame(i) && !IsFakeClient(i)) ClientCommand(i, "retry");
	
	InsertServerCommand("quit");
	ServerExecute();
	return Plugin_Handled;
}
//------------------------------------------------------------------------------------------------------------------------------------
