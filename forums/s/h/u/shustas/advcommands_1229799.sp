#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <geoip>
#undef REQUIRE_EXTENSIONS
#include <cstrike>
#include <tf2_stocks>
#undef REQUIRE_PLUGIN
#include <adminmenu>

#include "include\advcommands.inc"

#define PLUGIN_VERSION "0.13"

public Plugin:myinfo = 
{
	name = "Advanced admin commands",
	author = "X@IDER",
	description = "Many useful commands",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

#define YELLOW               "\x01"
#define NAME_TEAMCOLOR       "\x02"
#define TEAMCOLOR            "\x03"
#define GREEN                "\x04"

new Float:coords[64][3];
new NewTeam[64];

new game = 0;
new bool:g_late = false;
new Handle:hTopMenu = INVALID_HANDLE;

new Handle:hGameConf = INVALID_HANDLE;
new Handle:hRemoveItems = INVALID_HANDLE;
new Handle:hSetModel = INVALID_HANDLE;
new Handle:hDrop = INVALID_HANDLE;

new Handle:sv_alltalk = INVALID_HANDLE;
new Handle:mp_atb = INVALID_HANDLE;
new Handle:mp_ltm = INVALID_HANDLE;
new Handle:hostname = INVALID_HANDLE;
new Handle:hAVEnable = INVALID_HANDLE;
new Handle:hAVAdmins = INVALID_HANDLE;
new Handle:hAVFlags = INVALID_HANDLE;
new Handle:hSilent = INVALID_HANDLE;
new Handle:hNotify = INVALID_HANDLE;
new Handle:hLog = INVALID_HANDLE;
new Handle:hMapcfg = INVALID_HANDLE;
new Handle:hMe = INVALID_HANDLE;
new Handle:hAdmList = INVALID_HANDLE;
new Handle:hMotd = INVALID_HANDLE;
new Handle:hCAEnable = INVALID_HANDLE;
new Handle:hSProt = INVALID_HANDLE;
new Handle:hMVAdmins = INVALID_HANDLE;
new Handle:hREProt = INVALID_HANDLE;
new Handle:hBLEnable = INVALID_HANDLE;
new Handle:hBLConsole = INVALID_HANDLE;

// Teams
new TEAM1,TEAM2;

new String:t_models[4][PLATFORM_MAX_PATH] =
{
	"models/player/t_phoenix.mdl",
	"models/player/t_leet.mdl",
	"models/player/t_arctic.mdl",
	"models/player/t_guerilla.mdl"
};

new String:ct_models[4][PLATFORM_MAX_PATH] =
{
	"models/player/ct_urban.mdl",
	"models/player/ct_gsg9.mdl",
	"models/player/ct_sas.mdl",
	"models/player/ct_gign.mdl"
};

// Team names
new String:teams[4][16] = 
{
	"N/A",
	"SPEC",
	"T",
	"CT"
};

abs(val)
{
	if (val < 0) return -val;
	return val;
}

public PrintToChatEx(from,to,const String:format[],any:...)
{
	decl String:message[512];
	VFormat(message,sizeof(message),format,4);
	
	if ((game == 2) || !to)
	{
		PrintToChat(to,message);
		return;
	}

	new Handle:hBf = StartMessageOne("SayText2",to);
	if (hBf != INVALID_HANDLE)
	{
		BfWriteByte(hBf, from);
		BfWriteByte(hBf, true);
		BfWriteString(hBf, message);
	
		EndMessage();
	}
}

public PrintToChatAllEx(from,const String:format[], any:...)
{
	decl String:message[256];
	VFormat(message,sizeof(message),format,3);
	
	if (game == 2)
	{
		PrintToChatAll(message);
		return;
	}

	new Handle:hBf = StartMessageAll("SayText2");
	if (hBf != INVALID_HANDLE)
	{
		BfWriteByte(hBf, from);
		BfWriteByte(hBf, true);
		BfWriteString(hBf, message);
	
		EndMessage();
	}
}

public AdvNotify(Handle:plugin,numParams)
{
	new admin = GetNativeCell(1);
	new target = GetNativeCell(2);
	decl String:admname[64],String:tagname[64];

	GetClientName(target,tagname,sizeof(tagname));
	GetClientName(admin,admname,sizeof(admname));

	if (GetConVarBool(hSilent)) return;

	for (new i = 1; i <= MaxClients; i++)
	if (IsClientInGame(i) && !IsFakeClient(i))
	{
		if (FormatActivitySource(admin,i,admname,sizeof(admname)))
		{
			Call_StartFunction(INVALID_HANDLE,PrintToChatEx);
			Call_PushCell(target);
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
}

Balance(bool:dead)
{
	new n1 = 0, n2 = 0, nf1 = 0, nf2 = 0, nd1 = 0, nd2 = 0;
	for (new i = 1; i <= MaxClients; i++)
	if (IsClientInGame(i))
	{
		if (GetClientTeam(i) == 2)
		{
			n1++;
			nf1 += GetClientFrags(i);
			nd1 += GetClientDeaths(i);
		}
		if (GetClientTeam(i) == 3)
		{
			n2++;
			nf2 += GetClientFrags(i);
			nd2 += GetClientDeaths(i);
		}
	}
	new st = 2, mt = 3;
	new dn = n1-n2, df = 0,dd = 0;
	if (dn < 0)
	{
		st = 3;
		mt = 2;
		dn = -dn;
	}
	while (dn-- > GetConVarInt(mp_ltm))
	{
		new mvadm = GetConVarInt(hMVAdmins);
		df = abs(nf1-nf2)/2;
		dd = abs(nd1-nd2)/2;
		new mi = 0, mf = 2047, md = 2047;
		for (new i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && (GetClientTeam(i) == st) && (!dead || (dead && !IsPlayerAlive(i))))
		{
			new AdminId:admid = GetUserAdmin(i);
			if ((admid != INVALID_ADMIN_ID) && mvadm && (GetAdminImmunityLevel(admid) > mvadm)) continue;
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
			ChangeClientTeamEx(mi,mt);
			if (GetConVarInt(hNotify) & 1)
				 (GetConVarInt(hNotify) & 15)?PrintHintText(mi,"%t","Moved Notify"):PrintToChat(mi,"%t","Moved Notify");
		}
	}
}

DropWeapon(client,ent)
{
	if (!game && (hDrop != INVALID_HANDLE))
		SDKCall(hDrop,client,ent,false,false);
	else
	{
		decl String:edict[64];
		GetEdictClassname(ent,edict,sizeof(edict));
		FakeClientCommandEx(client,"use %s;drop",edict);
	}
}

ChangeClientTeamEx(client,team)
{
	if (game)
	{
		ChangeClientTeam(client,team);
		return;
	}

	new oldTeam = GetClientTeam(client);
	CS_SwitchTeam(client,team);
	if (!IsPlayerAlive(client)) return;

	decl String:model[PLATFORM_MAX_PATH],String:newmodel[PLATFORM_MAX_PATH];
	GetClientModel(client,model,sizeof(model));
	newmodel = model;

	if (oldTeam == TEAM1)
	{
		new c4 = GetPlayerWeaponSlot(client,CS_SLOT_C4);
		if (c4 != -1) DropWeapon(client,c4);

		if (StrContains(model,t_models[0],false)) newmodel = ct_models[0];
		if (StrContains(model,t_models[1],false)) newmodel = ct_models[1];
		if (StrContains(model,t_models[2],false)) newmodel = ct_models[2];
		if (StrContains(model,t_models[3],false)) newmodel = ct_models[3];		
	} else
	if (oldTeam == TEAM2)
	{
		SetEntProp(client, Prop_Send, "m_bHasDefuser", 0, 1);

		if (StrContains(model,ct_models[0],false)) newmodel = t_models[0];
		if (StrContains(model,ct_models[1],false)) newmodel = t_models[1];
		if (StrContains(model,ct_models[2],false)) newmodel = t_models[2];
		if (StrContains(model,ct_models[3],false)) newmodel = t_models[3];		
	}

	SDKCall(hSetModel, client, newmodel);
}

SwapPlayer(client,target)
{
	if (GetClientTeam(target) == TEAM1) ChangeClientTeamEx(target,TEAM2); else
	if (GetClientTeam(target) == TEAM2) ChangeClientTeamEx(target,TEAM1); else
	return;
	Notify(client,target,"Swap Notify",teams[GetClientTeam(target)]);
}

SwapPlayerRound(client,target)
{
	if (NewTeam[target])
	{
		Notify(client,target,"Swap Round Cancel",teams[NewTeam[target]]);
		NewTeam[target] = 0;
		return;
	}
	if (GetClientTeam(target) == TEAM1) NewTeam[target] = TEAM2; else
	if (GetClientTeam(target) == TEAM2) NewTeam[target] = TEAM1; else
	return;

	Notify(client,target,"Swap Round Notify",teams[NewTeam[target]]);
}

ExchangePlayers(client,cl1,cl2)
{
	if ((GetClientTeam(cl1) == TEAM1) && (GetClientTeam(cl2) == TEAM2))
	{
		ChangeClientTeamEx(cl1,TEAM2);
		ChangeClientTeamEx(cl2,TEAM1);
	} else
	if ((GetClientTeam(cl1) == TEAM2) && (GetClientTeam(cl2) == TEAM1))
	{
		ChangeClientTeamEx(cl1,TEAM1);
		ChangeClientTeamEx(cl2,TEAM2);
	} else
		ReplyToCommand(client,"%t","Bad targets");
}

ExchangePlayersRound(client,cl1,cl2)
{
	if (((GetClientTeam(cl1) == TEAM1) && (GetClientTeam(cl2) == TEAM2)) || 
		((GetClientTeam(cl1) == TEAM2) && (GetClientTeam(cl2) == TEAM1)))
	{
		SwapPlayerRound(client,cl1);
		SwapPlayerRound(client,cl2);
	} else
		ReplyToCommand(client,"%t","Bad targets");
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("Notify", AdvNotify);
	MarkNativeAsOptional("TF2_RespawnPlayer");
	MarkNativeAsOptional("TF2_RemoveWeaponSlot");
	MarkNativeAsOptional("TF2_RemoveAllItems");
	g_late = late;
	return APLRes_Success;
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("advcommands");

	CreateConVar("sm_adv_version", PLUGIN_VERSION, "Sourcemod Advanced version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);	
	hSilent = CreateConVar("sm_adv_silent", "1", "Suppress all notifications", FCVAR_PLUGIN, true, 0.0, true, 1.0);	
	hNotify = CreateConVar("sm_adv_notify", "1", "Player notiications (1 - move,2 - spawn protection,15 - notify in hint)", FCVAR_PLUGIN, true, 0.0, true, 31.0);	
	hLog = CreateConVar("sm_adv_log", "1", "Log actions", FCVAR_PLUGIN, true, 0.0, true, 1.0);	
	hMapcfg = CreateConVar("sm_adv_mapcfg", "0", "Enable mapconfigs", FCVAR_PLUGIN, true, 0.0, true, 1.0);	
	hAdmList = CreateConVar("sm_adv_admlist", "0", "Enable sm_admins", FCVAR_PLUGIN, true, 0.0, true, 1.0);	
	hMe = CreateConVar("sm_adv_me", "0", "Enable /me trigger", FCVAR_PLUGIN, true, 0.0, true, 1.0);	
	hAVEnable = CreateConVar("sm_av_enable", "1", "Enable admin vision (all chat)", FCVAR_PLUGIN, true, 0.0, true, 1.0);	
	hAVAdmins = CreateConVar("sm_av_admins", "1", "1 - visible for admins, 0 - visible only for fake admins (SourceTV)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	hAVFlags = CreateConVar("sm_av_flags", "j", "Set of admin flags, which allows AV", FCVAR_PLUGIN);
	hMotd = CreateConVar("sm_adv_motd", "http://www.arising-evil.com/clanrulez.html", "If empty shows MOTD page, elsewhere opens this url", FCVAR_PLUGIN);
	hCAEnable = CreateConVar("sm_adv_connect_announce", "0", "Enable connect announce", FCVAR_PLUGIN, true, 0.0, true, 1.0);	
	hSProt = CreateConVar("sm_adv_spawn_protection", "3.0", "Spawn protection time (0 to disable)", FCVAR_PLUGIN, true, 0.0);	
	hMVAdmins = CreateConVar("sm_adv_move_admins", "10", "Maximum immunity to move admin, when balancing (0 to disable)", FCVAR_PLUGIN, true, 0.0);	
	hREProt = CreateConVar("sm_adv_round_protection", "0", "Protect players between rounds", FCVAR_PLUGIN, true, 0.0, true, 1.0);	
	hBLEnable = CreateConVar("sm_bl_enable", "0", "Enable ban logging (1 - log bans, 2 - log unbans, 3 - both)", FCVAR_PLUGIN, true, 0.0, true, 3.0);	
	hBLConsole = CreateConVar("sm_bl_console", "0", "Log console bans or not", FCVAR_PLUGIN, true, 0.0, true, 1.0);	

	decl String:gdir[PLATFORM_MAX_PATH];
	GetGameFolderName(gdir, sizeof(gdir));
	if (StrEqual(gdir,"cstrike",false)) game = 0;
	else if (StrEqual(gdir,"hl2mp",false)) game = 1;
	else if (StrEqual(gdir,"dod",false)) game = 2;
	else if (StrEqual(gdir,"tf",false)) game = 3;
	else game = 4;

	TEAM1 = 2;
	TEAM2 = 3;

	hGameConf = LoadGameConfigFile("advcommands.gamedata");
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "RemoveAllItems");
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	hRemoveItems = EndPrepSDKCall();

	if (game == 0)
	{
		RegAdminCmd("sm_nv", Command_NV, ADMFLAG_GENERIC);
		RegAdminCmd("sm_defuser", Command_Defuser, ADMFLAG_GENERIC);
		RegAdminCmd("sm_cash", Command_Cash, ADMFLAG_KICK);
		RegAdminCmd("sm_knives", Command_Melee, ADMFLAG_KICK);

		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "DropWeapon");
		PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		hDrop = EndPrepSDKCall();

		if (hDrop == INVALID_HANDLE)
			PrintToServer("[Advanced Commands] Warning: DropWeapon SDKCall not found, stupid method will be used");
	}

	if (game < 2)
		RegAdminCmd("sm_armour", Command_Armour, ADMFLAG_GENERIC);

	if (game < 3)
	{
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "SetModel");
		PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
		hSetModel = EndPrepSDKCall();

		if (hSetModel == INVALID_HANDLE)
			PrintToServer("[Advanced Commands] Warning: SetModel SDKCall not found, model changing disabled");
		else
			RegAdminCmd("sm_setmodel", Command_SetModel, ADMFLAG_BAN);
	}

	if ((game < 3) && (hRemoveItems == INVALID_HANDLE))
		PrintToServer("[Advanced Commands] Warning: RemoveAllItems SDKCall not found, direct method will be used");


	if ((game == 0) || (game == 3))
		RegAdminCmd("sm_respawn", Command_Respawn, ADMFLAG_KICK);

	RegAdminCmd("sm_disarm", Command_Disarm, ADMFLAG_GENERIC);
	RegAdminCmd("sm_melee", Command_Melee, ADMFLAG_BAN);
	RegAdminCmd("sm_equip", Command_Equip, ADMFLAG_BAN);
	RegAdminCmd("sm_bury", Command_Bury, ADMFLAG_KICK);
	RegAdminCmd("sm_unbury", Command_Unbury, ADMFLAG_KICK);
	RegAdminCmd("sm_hp", Command_HP, ADMFLAG_KICK);
	RegAdminCmd("sm_give", Command_Give, ADMFLAG_BAN);
	RegAdminCmd("sm_speed", Command_Speed, ADMFLAG_BAN);
	RegAdminCmd("sm_frags", Command_Frags, ADMFLAG_BAN);
	RegAdminCmd("sm_deaths", Command_Deaths, ADMFLAG_BAN);
	RegAdminCmd("sm_balance", Command_Balance, ADMFLAG_GENERIC);
	RegAdminCmd("sm_shuffle", Command_Shuffle, ADMFLAG_KICK);
	RegAdminCmd("sm_exec", Command_Exec, ADMFLAG_BAN);
	RegAdminCmd("sm_fexec", Command_FExec, ADMFLAG_BAN);
	RegAdminCmd("sm_getloc", Command_Location, ADMFLAG_BAN);
	RegAdminCmd("sm_saveloc", Command_SaveLocation, ADMFLAG_BAN);
	RegAdminCmd("sm_teleport", Command_Teleport, ADMFLAG_BAN);
	RegAdminCmd("sm_god", Command_God, ADMFLAG_BAN);
	RegAdminCmd("sm_rr", Command_RR, ADMFLAG_CHANGEMAP);
	RegAdminCmd("sm_extend", Command_Extend, ADMFLAG_CHANGEMAP);
	RegAdminCmd("sm_shutdown", Command_Shutdown, ADMFLAG_ROOT);
	RegAdminCmd("sm_showmotd", Command_MOTD, ADMFLAG_GENERIC);
	RegAdminCmd("sm_url", Command_Url, ADMFLAG_GENERIC);
	RegAdminCmd("sm_getmodel", Command_GetModel, ADMFLAG_BAN);
	RegAdminCmd("sm_drop", Command_Drop, ADMFLAG_KICK);
	RegAdminCmd("sm_dropslot", Command_DropSlot, ADMFLAG_KICK);

	RegAdminCmd("sm_spec", Command_Spec, ADMFLAG_KICK);
	RegAdminCmd("sm_teamswap", Command_TeamSwap, ADMFLAG_KICK);
	RegAdminCmd("sm_team", Command_Team, ADMFLAG_KICK);
	RegAdminCmd("sm_swap", Command_Swap, ADMFLAG_KICK);
	RegAdminCmd("sm_lswap", Command_SwapRound, ADMFLAG_KICK);
	RegAdminCmd("sm_exch", Command_Exchange, ADMFLAG_KICK);
	RegAdminCmd("sm_lexch", Command_ExchangeRound, ADMFLAG_KICK);

	RegConsoleCmd("sm_admins",Command_Admins);

	sv_alltalk = FindConVar("sv_alltalk");
	mp_atb = FindConVar("mp_autoteambalance");
	mp_ltm = FindConVar("mp_limitteams");
	hostname = FindConVar("hostname");
	
	if (mp_atb == INVALID_HANDLE)
		mp_atb = CreateConVar("sm_adv_autoteambalance", "1", "Enable automatic team balance", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	if (mp_ltm == INVALID_HANDLE)
		mp_ltm = CreateConVar("sm_adv_limitteams", "0", "Max # of players 1 team can have over another (0 disables check)", FCVAR_PLUGIN, true, 0.0);

	AddCommandListener(Command_Say,"say");
	AddCommandListener(Command_Say,"say_team");
	HookEvent("player_spawn",Event_PlayerSpawn);
	
	if (game) HookEvent("player_death",Event_PlayerDeath);
	HookEvent("round_end",Event_RoundEnd);
	HookEvent("round_start",Event_RoundStart);

	if (g_late) OnAdminMenuReady(GetAdminTopMenu());

	AutoExecConfig(true,"advcommands");
}

public OnClientAuthorized(client,const String:auth[])
{
	if (!GetConVarBool(hCAEnable)) return;

	decl String:ip[32],String:name[64],String:country[64],String:from[90];
	GetClientName(client,name,sizeof(name));
	if (GetClientIP(client,ip,sizeof(ip)) && GeoipCountry(ip,country,sizeof(country)))
		Format(from,sizeof(from)," from \x03%s",country);
	else from = "";

	PrintToChatAll("\x04%s [\x03%s\x04] connected%s",name,auth,from);
}

public OnConfigsExecuted()
{
	if (GetConVarBool(hMapcfg))
	{
		new String:map[64];
		GetCurrentMap(map,sizeof(map));
		InsertServerCommand("exec mapcfg/%s.cfg",map);
		ServerExecute();
		LogToGame("exec mapcfg/%s.cfg",map);
	}
	for (new i = 1; i <= MaxClients; i++)
	{
		coords[i][0] = 0.0;
		coords[i][1] = 0.0;
		coords[i][2] = 0.0;
	}
	if (game)
	{
		GetTeamName(TEAM1,teams[TEAM1],16);
		GetTeamName(TEAM2,teams[TEAM2],16);
	}
}

public Action:OnBanClient(client,time,flags,const String:reason[],const String:kick_message[],const String:command[],any:source)
{
	if ((GetConVarInt(hBLEnable) & 1) && (source || GetConVarBool(hBLConsole)))
	{
		decl String:Path[PLATFORM_MAX_PATH],String:mins[32];
		BuildPath(Path_SM,Path,sizeof(Path),"/logs/bans.log");
		if (time) Format(mins,sizeof(mins),"%d mins",time);
		else mins = "permanent";
		if (reason[0]) LogToFileEx(Path,"%L banned %L (%s) reason: %s",source,client,mins,reason);
		else LogToFileEx(Path,"%L banned %L (%s)",source,client,mins);
	}
	return Plugin_Continue;
}

public Action:OnBanIdentity(const String:identity[],time,flags,const String:reason[],const String:command[],any:source)
{
	if ((GetConVarInt(hBLEnable) & 1) && (source || GetConVarBool(hBLConsole)))
	{
		decl String:Path[PLATFORM_MAX_PATH],String:mins[32];
		BuildPath(Path_SM,Path,sizeof(Path),"/logs/bans.log");
		if (time) Format(mins,sizeof(mins),"%d mins",time);
		else mins = "permanent";
		if (reason[0]) LogToFileEx(Path,"%L banned %s (%s) reason: %s",source,identity,mins,reason);
		else LogToFileEx(Path,"%L banned %s (%s)",source,identity,mins);

	}
	return Plugin_Continue;
}

public Action:OnRemoveBan(const String:identity[],flags,const String:command[],any:source)
{
	if ((GetConVarInt(hBLEnable) & 2) && (source || GetConVarBool(hBLConsole)))
	{
		decl String:Path[PLATFORM_MAX_PATH],String:mins[32];
		BuildPath(Path_SM,Path,sizeof(Path),"/logs/bans.log");
		LogToFileEx(Path,"%L unbanned %s",source,identity,mins);

	}
	return Plugin_Continue;
}

public MenuHandler_Extend(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End) CloseHandle(menu);
	if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack)
            DisplayTopMenu(GetAdminTopMenu(), param1, TopMenuPosition_LastCategory);
    }
	if (action == MenuAction_Select)
	{
		decl String:tm[16];
		GetMenuItem(menu,param2,tm,sizeof(tm));
		ExtendMap(param1,StringToInt(tm));
	}
}

public DisplayExtendMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler_Extend);
	SetMenuExitBackButton(menu,true);

	decl String:title[100];
	Format(title, sizeof(title), "%t", "Menu Extend", client);
	SetMenuTitle(menu, title);

	AddMenuItem(menu,"5","5 min");
	AddMenuItem(menu,"10","10 min");
	AddMenuItem(menu,"15","15 min");
	AddMenuItem(menu,"20","20 min");
	AddMenuItem(menu,"30","30 min");
	AddMenuItem(menu,"45","45 min");

	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public FillMenuByPlayers(Handle:menu,skipteam,skipclient)
{
	decl String:name[64],String:title[100],String:id[16];

	for (new i = 1; i <= MaxClients; i++)
	if (IsClientInGame(i) && (i != skipclient))
	{
		new team = GetClientTeam(i);
		if ((team > CS_TEAM_SPECTATOR) && (team != skipteam))
		{
			GetClientName(i,name,sizeof(name));
			if (NewTeam[i]) Format(title, sizeof(title), "[%s>>%s] %s",teams[team],teams[NewTeam[i]],name);
			else Format(title, sizeof(title), "[%s] %s",teams[team],name);
			IntToString(GetClientUserId(i),id,sizeof(id));
			AddMenuItem(menu,id,title);
		}
	}
}

public MenuHandler_Swap(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End) CloseHandle(menu);
	if (action == MenuAction_Cancel)
	{
		if ((param2 == MenuCancel_ExitBack) && (hTopMenu != INVALID_HANDLE))
			DisplayTopMenu(hTopMenu,param1,TopMenuPosition_LastCategory);
	}
	if (action == MenuAction_Select)
	{
		decl String:title[100],String:id[16],String:late[100];
		GetMenuItem(menu,param2,id,sizeof(id));
		new target = GetClientOfUserId(StringToInt(id));
		if (target)
		{
			GetMenuTitle(menu, title, sizeof(title));
			Format(late, sizeof(late), "%t", "Menu Swap Round", param1);
			if (!strcmp(late,title))
			{
				SwapPlayerRound(param1,target);
				DisplayActionMenu(param1,"sm_lswap");
			} else
			{
				SwapPlayer(param1,target);
				DisplayActionMenu(param1,"sm_swap");
			}
		}
	}
}

public MenuHandler_Exchange2(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End) CloseHandle(menu);
	if (action == MenuAction_Cancel)
	{
		if ((param2 == MenuCancel_ExitBack) && (hTopMenu != INVALID_HANDLE))
			DisplayTopMenu(hTopMenu,param1,TopMenuPosition_LastCategory);
	}
	if (action == MenuAction_Select)
	{
		decl String:id1[16],String:id2[16],String:late[100];
		GetMenuItem(menu,0,id1,sizeof(id1));
		GetMenuItem(menu,param2,id2,sizeof(id2));

		new cl1 = GetClientOfUserId(StringToInt(id1));
		new cl2 = GetClientOfUserId(StringToInt(id2));

		if (cl1 && cl2)
		{
			decl String:title[100];
			GetMenuTitle(menu, title, sizeof(title));
			Format(late, sizeof(late), "%t", "Menu Exchange Round", param1);
			if (!strcmp(late,title))
			{
				ExchangePlayersRound(param1,cl1,cl2);
				DisplayActionMenu(param1,"sm_lexch");
			} else
			{
				ExchangePlayers(param1,cl1,cl2);
				DisplayActionMenu(param1,"sm_exch");
			}
		}
	}
}

public MenuHandler_Exchange(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End) CloseHandle(menu);
	if (action == MenuAction_Cancel)
	{
		if ((param2 == MenuCancel_ExitBack) && (hTopMenu != INVALID_HANDLE))
			DisplayTopMenu(hTopMenu,param1,TopMenuPosition_LastCategory);
	}
	if (action == MenuAction_Select)
	{
		decl String:name[100],String:title[100],String:id[16];
		GetMenuItem(menu, param2, id, sizeof(id));
		new target = GetClientOfUserId(StringToInt(id));
		if (target)
		{
			new team = GetClientTeam(target);

			new Handle:menu2 = CreateMenu(MenuHandler_Exchange2);
			SetMenuExitBackButton(menu2,true);
			GetMenuTitle(menu, title, sizeof(title));
			SetMenuTitle(menu2, title);
	
			GetClientName(target,name,sizeof(name));
			Format(title, sizeof(title), "[%s] %s",teams[team],name);
			AddMenuItem(menu2,id,title,ITEMDRAW_DISABLED);
	
			FillMenuByPlayers(menu2,team,target);
			DisplayMenu(menu2, param1, MENU_TIME_FOREVER);
		}
	}
}

DisplayActionMenu(client,String:cmd[])
{
	new Handle:menu = INVALID_HANDLE;
	decl String:title[100];
	if (StrEqual(cmd,"sm_swap"))
	{
		menu = CreateMenu(MenuHandler_Swap);
		Format(title, sizeof(title), "%t", "Menu Swap Now", client);
	} else
	if (StrEqual(cmd,"sm_lswap"))
	{
		menu = CreateMenu(MenuHandler_Swap);
		Format(title, sizeof(title), "%t", "Menu Swap Round", client);
	} else
	if (StrEqual(cmd,"sm_exch"))
	{
		menu = CreateMenu(MenuHandler_Exchange);
		Format(title, sizeof(title), "%t", "Menu Exchange Now", client);
	} else
	if (StrEqual(cmd,"sm_lexch"))
	{
		menu = CreateMenu(MenuHandler_Exchange);
		Format(title, sizeof(title), "%t", "Menu Exchange Round", client);
	}

	if (menu != INVALID_HANDLE)
	{
		SetMenuExitBackButton(menu,true);
		SetMenuTitle(menu, title);
		FillMenuByPlayers(menu,0,0);
	
		DisplayMenu(menu, client, MENU_TIME_FOREVER);
	}
}

public AdminMenu_Handler(Handle:topmenu,TopMenuAction:action,TopMenuObject:object_id,param,String:buffer[],maxlength)
{
	decl String:name[64];
	GetTopMenuObjName(topmenu,object_id,name,sizeof(name));
	if (action == TopMenuAction_DisplayOption)
	{
		if (StrEqual(name,"sm_shutdown"))	Format(buffer, maxlength, "%t", "Menu Shutdown",	param);
		if (StrEqual(name,"sm_extend"))		Format(buffer, maxlength, "%t", "Menu Extend",		param);
		if (StrEqual(name,"sm_balance"))	Format(buffer, maxlength, "%t", "Menu Balance",		param);
		if (StrEqual(name,"sm_shuffle"))	Format(buffer, maxlength, "%t", "Menu Shuffle",		param);
		if (StrEqual(name,"sm_teamswap"))	Format(buffer, maxlength, "%t", "Menu Teamswap",	param);
		if (StrEqual(name,"sm_rr"))			Format(buffer, maxlength, "%t", "Menu RR",			param);
		if (StrEqual(name,"sm_swap"))		Format(buffer, maxlength, "%t", "Menu Swap Now",	param);
		if (StrEqual(name,"sm_lswap"))		Format(buffer, maxlength, "%t", "Menu Swap Round",	param);
		if (StrEqual(name,"sm_exch"))		Format(buffer, maxlength, "%t", "Menu Exchange Now",param);
		if (StrEqual(name,"sm_lexch"))		Format(buffer, maxlength, "%t", "Menu Exchange Round",param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		if (StrEqual(name,"sm_shutdown"))	Command_Shutdown(param,0);	else
		if (StrEqual(name,"sm_extend"))		DisplayExtendMenu(param);	else
		if (StrEqual(name,"sm_balance"))	Balance(false);				else
		if (StrEqual(name,"sm_shuffle"))	Command_Shuffle(param,0);	else
		if (StrEqual(name,"sm_teamswap"))	Command_TeamSwap(param,0);	else
		if (StrEqual(name,"sm_rr"))			ServerCommand("mp_restartgame 1");
		else
			DisplayActionMenu(param,name);
		
	}
}

public OnAdminMenuReady(Handle:topmenu)
{
	new TopMenuObject:server_commands = FindTopMenuCategory(topmenu, ADMINMENU_SERVERCOMMANDS);
	new TopMenuObject:player_commands = FindTopMenuCategory(topmenu, ADMINMENU_PLAYERCOMMANDS);

	AddToTopMenu(topmenu,"sm_shutdown",	TopMenuObject_Item,AdminMenu_Handler,server_commands,"sm_shutdown",	ADMFLAG_ROOT);
	AddToTopMenu(topmenu,"sm_extend",	TopMenuObject_Item,AdminMenu_Handler,server_commands,"sm_extend",	ADMFLAG_CHANGEMAP);
	AddToTopMenu(topmenu,"sm_balance",	TopMenuObject_Item,AdminMenu_Handler,server_commands,"sm_balance",	ADMFLAG_GENERIC);
	AddToTopMenu(topmenu,"sm_shuffle",	TopMenuObject_Item,AdminMenu_Handler,server_commands,"sm_shuffle",	ADMFLAG_GENERIC);
	AddToTopMenu(topmenu,"sm_teamswap",	TopMenuObject_Item,AdminMenu_Handler,server_commands,"sm_teamswap",	ADMFLAG_GENERIC);
	AddToTopMenu(topmenu,"sm_rr",		TopMenuObject_Item,AdminMenu_Handler,server_commands,"sm_rr",		ADMFLAG_CHANGEMAP);

	AddToTopMenu(topmenu,"sm_swap",		TopMenuObject_Item,AdminMenu_Handler,player_commands,"sm_swap",		ADMFLAG_KICK);
	AddToTopMenu(topmenu,"sm_lswap",	TopMenuObject_Item,AdminMenu_Handler,player_commands,"sm_lswap",	ADMFLAG_KICK);
	AddToTopMenu(topmenu,"sm_exch",		TopMenuObject_Item,AdminMenu_Handler,player_commands,"sm_exch",		ADMFLAG_KICK);
	AddToTopMenu(topmenu,"sm_lexch",	TopMenuObject_Item,AdminMenu_Handler,player_commands,"sm_lexch",	ADMFLAG_KICK);

	hTopMenu = topmenu;
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarBool(mp_atb)) Balance(true);
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	if (NewTeam[client])
	{
		ChangeClientTeamEx(client,NewTeam[client]);
		NewTeam[client] = 0;
	}
	return Plugin_Continue;
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
/*	if (GetConVarBool(hREProt))
	for (new i = 1; i <= MaxClients; i++)
	if (IsClientInGame(i) && (GetClientTeam(i) > 1))
		SetEntProp(i, Prop_Data, "m_takedamage", 2, 1);*/
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarBool(mp_atb)) Balance(false);
	for (new i = 1; i < sizeof(NewTeam); i++)
	if (NewTeam[i] && IsClientInGame(i))
	{
		ChangeClientTeamEx(i,NewTeam[i]);
		NewTeam[i] = 0;
	}
	if (GetConVarBool(hREProt))
	for (new i = 1; i <= MaxClients; i++)
	if (IsClientInGame(i) && (GetClientTeam(i) > 1))
		SetEntProp(i, Prop_Data, "m_takedamage", 0, 1);
	return Plugin_Continue;
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new user = GetClientOfUserId(GetEventInt(event,"userid"));
	new Float:ptime = GetConVarFloat(hSProt);
	if (ptime)
	{
		CreateTimer(ptime,Unprotect,user);
		SetEntProp(user, Prop_Data, "m_takedamage", 0, 1);
		if (GetClientTeam(user) == 2) SetEntityRenderColor(user,255,0,0,128); else
		if (GetClientTeam(user) == 3) SetEntityRenderColor(user,0,0,255,128); else
		SetEntityRenderColor(user,0,255,0,128);
	}
	NewTeam[user] = 0;
	return Plugin_Continue;
}

public Action:Unprotect(Handle:timer,any:client)
{
	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
		SetEntityRenderColor(client,255,255,255,255);
		if (GetConVarInt(hNotify) & 2)
			(GetConVarInt(hNotify) & 15)?PrintHintText(client,"%t","SP End Notify"):PrintToChat(client,"%t","SP End Notify");
	}
	return Plugin_Stop;
}

public ShowMOTD(client)
{
	decl String:host[128],String:motd[128];
	GetConVarString(hostname,host,sizeof(host));
	GetConVarString(hMotd,motd,sizeof(motd));
	if (strlen(motd))
		ShowMOTDPanel(client,host,motd,MOTDPANEL_TYPE_URL);
	else ShowMOTDPanel(client,host,"motd",MOTDPANEL_TYPE_INDEX);
}

public Action:Command_Say(client, const String:command[], args)
{
	if (!client || !IsClientInGame(client)) return Plugin_Continue;

	decl String:msg[512],String:name[64];
	GetCmdArg(1,msg,sizeof(msg));
	GetClientName(client,name,sizeof(name)-1);

	if (!strcmp(msg,"rules",false))
	{
		ShowMOTD(client);
		return Plugin_Handled;
	}

	if (!strncmp(msg,"/me ",4,false) && GetConVarBool(hMe))
	{
		decl String:mesg[512];
		if (StrEqual(command,"say")) Format(mesg,sizeof(mesg),"\x04*** \x03%s\x04 %s",name,msg[4]);
		if (StrEqual(command,"say_team")) Format(mesg,sizeof(mesg),"\x01*** \x03%s\x04 %s",name,msg[4]);
		for (new i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && (!IsPlayerAlive(i) || IsPlayerAlive(client)))
		{
			if (StrEqual(command,"say_team") && (GetClientTeam(client) != GetClientTeam(i))) continue;
			PrintToChatEx(client,i,mesg);
		}
		return Plugin_Handled;		
	}

	if (!GetConVarBool(hAVEnable) || IsChatTrigger() || (msg[0] == '@')) return Plugin_Continue;

	new bool:admins = GetConVarBool(hAVAdmins);
	new bool:alltalk = GetConVarBool(sv_alltalk);

	decl String:flags[32],String:team[32],String:pref[64];
	GetConVarString(hAVFlags,flags,sizeof(flags));
	new flag = ReadFlagString(flags);
	
	if (StrEqual(command,"say_team"))
	{
		GetTeamName(GetClientTeam(client),team,sizeof(team));
		if (game == 0)
		{
			if (GetClientTeam(client) == 1) team = "Spectator\0";
			if (GetClientTeam(client) == 2) team = "Terrorist\0";
			if (GetClientTeam(client) == 3) team = "Counter-Terrorist\0";
		}

		if (IsPlayerAlive(client) || (GetClientTeam(client) == 1)) Format(pref,sizeof(pref),"(%s)",team);
		else Format(pref,sizeof(pref),"*DEAD*(%s)",team);

		for (new i = 1; i <= MaxClients; i++)
		if ((i != client) && IsClientInGame(i) &&
			((GetClientTeam(i) != GetClientTeam(client)) || (IsPlayerAlive(i) && !IsPlayerAlive(client))) && 
			((admins && ((GetUserFlagBits(i) & flag) == flag)) || (!admins && IsFakeClient(i))))
			PrintToChatEx(client,i,"\x04[AV]\x01 %s \x03%s\x01 :  %s",pref,name,msg);
	}

	if (StrEqual(command,"say"))
	{
		if (GetClientTeam(client) == 1) pref = "*SPEC*\0";
		else pref = "*DEAD*\0";

		for (new i = 1; i <= MaxClients; i++)
		if ((i != client) && IsClientInGame(i) && IsPlayerAlive(i) && !IsPlayerAlive(client) && 
			((admins && ((GetUserFlagBits(i) & flag) == flag)) || (!admins && IsFakeClient(i))))
			PrintToChatEx(client,i,"\x04[AV]\x01 %s \x03%s\x01 :  %s",pref,name,msg);
	}

	return Plugin_Continue;
}

public Action:Command_Swap(client,args)
{
	if (!args)
	{
		ReplyToCommand(client,"\x04sm_swap <target>");
		return Plugin_Handled;
	}
	decl String:pattern[64],String:buffer[64];
	GetCmdArg(1,pattern,sizeof(pattern));

	new targets[64],bool:mb;

	new count = ProcessTargetString(pattern,client,targets,sizeof(targets),0,buffer,sizeof(buffer),mb);

	if (!count) ReplyToCommand(client,"%t","No target",YELLOW,TEAMCOLOR,pattern,YELLOW);
	else
		for (new i = 0; i < count; i++) SwapPlayer(client,targets[i]);

	return Plugin_Handled;
}

public Action:Command_SwapRound(client,args)
{
	if (!args)
	{
		ReplyToCommand(client,"\x04sm_lswap <target>");
		return Plugin_Handled;
	}
	new String:pattern[64],String:buffer[64];
	GetCmdArg(1,pattern,sizeof(pattern));

	new targets[64],bool:mb;

	new count = ProcessTargetString(pattern,client,targets,sizeof(targets),0,buffer,sizeof(buffer),mb);

	if (!count) ReplyToCommand(client,"%t","No target",YELLOW,TEAMCOLOR,pattern,YELLOW);
	else
		for (new i = 0; i < count; i++) SwapPlayerRound(client,targets[i]);

	return Plugin_Handled;	
}

public Action:Command_Exchange(client,args)
{
	if (args < 2)
	{
		ReplyToCommand(client,"\x04sm_exch <target1> <target2>");
		return Plugin_Handled;
	}

	new String:p1[64],String:p2[64];
	GetCmdArg(1,p1,sizeof(p1));
	GetCmdArg(2,p2,sizeof(p2));

	new cl1 = FindTarget(client,p1);
	new cl2 = FindTarget(client,p2);

	if (cl1 == -1) ReplyToCommand(client,"%t","No target",YELLOW,TEAMCOLOR,p1,YELLOW);
	if (cl2 == -1) ReplyToCommand(client,"%t","No target",YELLOW,TEAMCOLOR,p2,YELLOW);

	if ((cl1 > 0) && (cl2 > 0)) ExchangePlayers(client,cl1,cl2);

	return Plugin_Handled;	
}

public Action:Command_ExchangeRound(client,args)
{
	if (args < 2)
	{
		ReplyToCommand(client,"\x04sm_lexch <target1> <target2>");
		return Plugin_Handled;
	}

	new String:p1[64],String:p2[64];
	GetCmdArg(1,p1,sizeof(p1));
	GetCmdArg(2,p2,sizeof(p2));

	new cl1 = FindTarget(client,p1);
	new cl2 = FindTarget(client,p2);

	if (cl1 == -1) ReplyToCommand(client,"%t","No target",YELLOW,TEAMCOLOR,p1,YELLOW);
	if (cl2 == -1) ReplyToCommand(client,"%t","No target",YELLOW,TEAMCOLOR,p2,YELLOW);

	if ((cl1 > 0) && (cl2 > 0)) ExchangePlayersRound(client,cl1,cl2);

	return Plugin_Handled;	
}

public Action:Command_GetModel(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client,"[SM] Usage: sm_getmodel <target>");
		return Plugin_Handled;
	}
	decl String:pattern[64],String:buffer[64],String:name[64],String:model[PLATFORM_MAX_PATH];
	GetCmdArg(1,pattern,sizeof(pattern));
	new targets[64],bool:mb;
	new count = ProcessTargetString(pattern,client,targets,sizeof(targets),0,buffer,sizeof(buffer),mb);
	if (!count) ReplyToCommand(client,"%t","No target",YELLOW,TEAMCOLOR,pattern,YELLOW);
	else for (new i = 0; i < count; i++)
	if (IsClientInGame(targets[i]) && IsPlayerAlive(targets[i]))
	{
		GetClientModel(targets[i],model,sizeof(model));
		GetClientName(targets[i],name,sizeof(name));
		PrintToChatEx(targets[i],client,"%t","Get Model Notify",YELLOW,TEAMCOLOR,name,YELLOW,GREEN,model,YELLOW);
	}

	return Plugin_Handled;
}

public Action:Command_SetModel(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client,"[SM] Usage: sm_setmodel <target> <model>");
		return Plugin_Handled;
	}
	decl String:pattern[64],String:buffer[64],String:model[PLATFORM_MAX_PATH];
	GetCmdArg(1,pattern,sizeof(pattern));
	GetCmdArg(2,model,sizeof(model));
	if (!FileExists(model))
	{
		ReplyToCommand(client,"[SM] %s not found",model);
		return Plugin_Handled;
	}
	new targets[64],bool:mb;
	new count = ProcessTargetString(pattern,client,targets,sizeof(targets),0,buffer,sizeof(buffer),mb);
	if (!count) ReplyToCommand(client,"%t","No target",YELLOW,TEAMCOLOR,pattern,YELLOW);
	else for (new i = 0; i < count; i++)
	if (IsClientInGame(targets[i]) && IsPlayerAlive(targets[i]))
	{
		SDKCall(hSetModel, targets[i], model);
		Notify(client,targets[i],"Set Model Notify",model);
	}

	return Plugin_Handled;
}

public Action:Command_DropSlot(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client,"[SM] Usage: sm_dropslot <target> <slot>");
		return Plugin_Handled;
	}
	decl String:pattern[64],String:buffer[64],String:s_slot[8];
	GetCmdArg(1,pattern,sizeof(pattern));
	GetCmdArg(2,s_slot,sizeof(s_slot));
	new slot = StringToInt(s_slot);
	new targets[64],bool:mb;
	new count = ProcessTargetString(pattern,client,targets,sizeof(targets),0,buffer,sizeof(buffer),mb);
	if (!count) ReplyToCommand(client,"%t","No target",YELLOW,TEAMCOLOR,pattern,YELLOW);
	else for (new i = 0; i < count; i++)
	if (IsClientInGame(targets[i]) && IsPlayerAlive(targets[i]))
	{
		new ent = GetPlayerWeaponSlot(targets[i],slot);
		if (ent != -1)
		{
			DropWeapon(targets[i],ent);
			Notify(client,targets[i],"Drop Slot Notify",slot);
		}
	}

	return Plugin_Handled;
}

public Action:Command_Drop(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client,"[SM] Usage: sm_drop <target> <weapon>");
		return Plugin_Handled;
	}
	decl String:pattern[64],String:buffer[64],String:weapon[32],String:edict[32];
	GetCmdArg(1,pattern,sizeof(pattern));
	GetCmdArg(2,weapon,sizeof(weapon));
	if (StrContains(weapon,"weapon_") == -1)
	{
		decl String:tmp[32];
		Format(tmp,sizeof(tmp),"weapon_%s",weapon);
		strcopy(weapon,sizeof(weapon),tmp);
	}
	new targets[64],bool:mb;
	new count = ProcessTargetString(pattern,client,targets,sizeof(targets),0,buffer,sizeof(buffer),mb);
	if (!count) ReplyToCommand(client,"%t","No target",YELLOW,TEAMCOLOR,pattern,YELLOW);
	else for (new i = 0; i < count; i++)
	if (IsClientInGame(targets[i]) && IsPlayerAlive(targets[i]))
	{
		for (new j = 0; j < 5; j++)
		{
			new ent = GetPlayerWeaponSlot(targets[i],j);
			if ((ent != -1) && GetEdictClassname(ent,edict,sizeof(edict)) && StrEqual(weapon,edict))
			{
				DropWeapon(targets[i],ent);
				Notify(client,targets[i],"Drop Weapon Notify",weapon);
			}
		}
	}

	return Plugin_Handled;
}
public Action:Command_Bury(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client,"[SM] Usage: sm_bury <target>");
		return Plugin_Handled;
	}
	decl String:pattern[64],String:buffer[64];
	GetCmdArg(1,pattern,sizeof(pattern));
	new targets[64],bool:mb;
	new count = ProcessTargetString(pattern,client,targets,sizeof(targets),0,buffer,sizeof(buffer),mb);
	new Float:vec[3];
	if (!count) ReplyToCommand(client,"%t","No target",YELLOW,TEAMCOLOR,pattern,YELLOW);
	else for (new i = 0; i < count; i++)
	if (IsClientInGame(targets[i]))
	{
		GetEntPropVector(targets[i], Prop_Send, "m_vecOrigin", vec);

		vec[2]=vec[2]-30.0;
		SetEntPropVector(targets[i], Prop_Send, "m_vecOrigin", vec);

		Notify(client,targets[i],"Bury Notify");
		if (GetConVarBool(hLog)) LogAction(client,targets[i],"\"%L\" buried player \"%L\"",client,targets[i]);
	}

	return Plugin_Handled;
}

public Action:Command_Unbury(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client,"[SM] Usage: sm_unbury <target>");
		return Plugin_Handled;
	}
	decl String:pattern[64],String:buffer[64];
	GetCmdArg(1,pattern,sizeof(pattern));
	new targets[64],bool:mb;
	new count = ProcessTargetString(pattern,client,targets,sizeof(targets),0,buffer,sizeof(buffer),mb);
	new Float:vec[3];
	if (!count) ReplyToCommand(client,"%t","No target",YELLOW,TEAMCOLOR,pattern,YELLOW);
	else for (new i = 0; i < count; i++)
	if (IsClientInGame(targets[i]))
	{
		GetEntPropVector(targets[i], Prop_Send, "m_vecOrigin", vec);

		vec[2]=vec[2]+30.0;
		SetEntPropVector(targets[i], Prop_Send, "m_vecOrigin", vec);

		Notify(client,targets[i],"Unbury Notify");
		if (GetConVarBool(hLog)) LogAction(client,targets[i],"\"%L\" unburied player \"%L\"",client,targets[i]);
	}

	return Plugin_Handled;
}

public Action:Command_MOTD(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client,"[SM] Usage: sm_showmotd <target>");
		return Plugin_Handled;
	}
	decl String:pattern[64],String:buffer[64];
	GetCmdArg(1,pattern,sizeof(pattern));
	new targets[64],bool:mb;
	new count = ProcessTargetString(pattern,client,targets,sizeof(targets),0,buffer,sizeof(buffer),mb);
	if (!count) ReplyToCommand(client,"%t","No target",YELLOW,TEAMCOLOR,pattern,YELLOW);
	else for (new i = 0; i < count; i++)
	if (IsClientInGame(targets[i]))
	{
		ShowMOTD(targets[i]);
		if (GetConVarBool(hLog)) LogAction(client,targets[i],"\"%L\" showed MOTD for \"%L\"",client,targets[i]);
	}

	return Plugin_Handled;
}

public Action:Command_Url(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client,"[SM] Usage: sm_url <target> <url>");
		return Plugin_Handled;
	}
	decl String:pattern[64],String:buffer[64],String:url[256];
	GetCmdArg(1,pattern,sizeof(pattern));
	GetCmdArg(2,url,sizeof(url));
	new targets[64],bool:mb;
	new count = ProcessTargetString(pattern,client,targets,sizeof(targets),0,buffer,sizeof(buffer),mb);
	decl String:host[128];
	GetConVarString(hostname,host,sizeof(host));
	if (!count) ReplyToCommand(client,"%t","No target",YELLOW,TEAMCOLOR,pattern,YELLOW);
	else for (new i = 0; i < count; i++)
	if (IsClientInGame(targets[i]))
	{
		ShowMOTDPanel(targets[i],host,url,MOTDPANEL_TYPE_URL);
		if (GetConVarBool(hLog)) LogAction(client,targets[i],"\"%L\" opened \"%s\" for \"%L\"",client,url,targets[i]);
	}

	return Plugin_Handled;
}

public Action:Command_Admins(client, args)
{
	if (!GetConVarBool(hAdmList)) return Plugin_Handled;
	new Adms[64],count = 0;
	for (new i = 1; i <= MaxClients; i++)
	if (IsClientInGame(i) && (GetUserAdmin(i) != INVALID_ADMIN_ID)) Adms[count++] = i;

	if (count)
	{
		decl String:name[64];
		PrintToChatEx(client,client,"---------------------------------------------------");
		for (new i = 0; i < count; i++)
		{
			GetClientName(Adms[i],name,sizeof(name));
			if (GetUserFlagBits(Adms[i]) & ADMFLAG_ROOT) PrintToChatEx(Adms[i],client,"\x04[ROOT]\x01 \x03%s\x01",name);
			else if (GetUserFlagBits(Adms[i]) & ADMFLAG_GENERIC) PrintToChatEx(Adms[i],client,"\x04[ADMIN]\x01 \x03%s\x01",name);
		}
		PrintToChatEx(client,client,"---------------------------------------------------");
	}
	return Plugin_Handled;
}

public Action:Command_Respawn(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client,"[SM] Usage: sm_respawn <target>");
		return Plugin_Handled;
	}
	decl String:pattern[64],String:buffer[64];
	GetCmdArg(1,pattern,sizeof(pattern));
	new targets[64],bool:mb;
	new count = ProcessTargetString(pattern,client,targets,sizeof(targets),0,buffer,sizeof(buffer),mb);
	if (!count) ReplyToCommand(client,"%t","No target",YELLOW,TEAMCOLOR,pattern,YELLOW);
	else for (new i = 0; i < count; i++)
	if (IsClientInGame(targets[i]) && (GetClientTeam(targets[i]) > 1))
	{
		if (game == 0) CS_RespawnPlayer(targets[i]);
		if (game == 3) TF2_RespawnPlayer(targets[i]);
		Notify(client,targets[i],"Respawn Notify");
		if (GetConVarBool(hLog)) LogAction(client,targets[i],"\"%L\" respawned player \"%L\"",client,targets[i]);
	}

	return Plugin_Handled;
}

public Action:Command_Disarm(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client,"[SM] Usage: sm_disarm <target>");
		return Plugin_Handled;
	}
	decl String:pattern[64],String:buffer[64];
	GetCmdArg(1,pattern,sizeof(pattern));
	new targets[64],bool:mb;
	new count = ProcessTargetString(pattern,client,targets,sizeof(targets),COMMAND_FILTER_ALIVE,buffer,sizeof(buffer),mb);
	if (!count) ReplyToCommand(client,"%t","No target",YELLOW,TEAMCOLOR,pattern,YELLOW);
	else for (new i = 0; i < count; i++)
	if (IsClientInGame(targets[i]))
	{
		if (game == 3) TF2_RemoveAllWeapons(targets[i]);
		else if (hRemoveItems != INVALID_HANDLE) SDKCall(hRemoveItems, targets[i], false);
		else
		for (new j = 0; j < 5; j++)
		{
			new w = -1;
			while ((w = GetPlayerWeaponSlot(targets[i],j)) != -1)
				if (IsValidEntity(w)) RemovePlayerItem(targets[i],w);
		}
		Notify(client,targets[i],"Disarm Notify");
		if (GetConVarBool(hLog)) LogAction(client,targets[i],"\"%L\" disarmed player \"%L\"",client,targets[i]);
	}

	return Plugin_Handled;
}

Melee(bool:s)
{
	// Weapon slot mask to remove weapons from
	// Use like 1+2+3 => (1<<0)|(1<<1)|(1<<2) = 7

	new wslots = 11; // 1,2,4 (1h,2h,8h)
	new mslot = 2;
	if (game == 1)
	{
		wslots = 30; // 2,3,4,5 (2h,4h,8h,10h)
		mslot = 0;
	}
	// I dont know what weapon slot is melee for your game
	// type if condition as above if you need another slot

	for (new i = 1; i <= MaxClients; i++)
	if (IsClientInGame(i) && IsPlayerAlive(i))
	{
		for (new j = 0; j < 5; j++)
		if (wslots & (1<<j))
		{
			new w = -1;
			while ((w = GetPlayerWeaponSlot(i,j)) != -1)
				if (IsValidEntity(w)) RemovePlayerItem(i,w);
		}
		if (s)
		{
			new m = GetPlayerWeaponSlot(i,mslot);
			if (IsValidEntity(m)) EquipPlayerWeapon(i,m);
		}
	}
}

public Action:Command_Melee(client, args)
{
	Melee(true);
	Notify(client,client,"Melee Notify");
	if (GetConVarBool(hLog)) LogAction(client,-1,"\"%L\" set all players to melee",client);
	return Plugin_Handled;
}

public Action:Command_Equip(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client,"[SM] Usage: sm_equip <weapon>");
		return Plugin_Handled;
	}
	Melee(false);
	decl String:ent[128];
	GetCmdArg(1,ent,sizeof(ent));
	for (new i = 1; i <= MaxClients; i++)
	if (IsClientInGame(i) && IsPlayerAlive(i))
	{
		if (GivePlayerItem(i,ent) == -1)
		{
			decl String:weapon[64];
			Format(weapon,sizeof(weapon),"weapon_%s",ent);
			GivePlayerItem(i,weapon);
		}
	}
	Notify(client,client,"Equip Notify",ent);
	if (GetConVarBool(hLog)) LogAction(client,-1,"\"%L\" equipped all players with %s",client,ent);
	return Plugin_Handled;
}

public Action:Command_Armour(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_armour <target> <armour>");
		return Plugin_Handled;	
	}	
	decl String:pattern[64],String:buffer[64],String:arm[16];
	GetCmdArg(1,pattern,sizeof(pattern));
	GetCmdArg(2,arm,sizeof(arm));
	new armour = StringToInt(arm);
	new targets[64],bool:mb;
	new count = ProcessTargetString(pattern,client,targets,sizeof(targets),COMMAND_FILTER_ALIVE,buffer,sizeof(buffer),mb);
	if (!count) ReplyToCommand(client,"%t","No target",YELLOW,TEAMCOLOR,pattern,YELLOW);
	else for (new i = 0; i < count; i++)
	if (IsClientInGame(targets[i]))
	{
		SetEntProp(targets[i], Prop_Send, "m_ArmorValue", armour, 1);
		SetEntProp(targets[i], Prop_Send, "m_bHasHelmet", armour?1:0, 1);
		Notify(client,targets[i],"Armour Notify",armour);
		if (GetConVarBool(hLog)) LogAction(client,targets[i],"\"%L\" set armour of player \"%L\" to %d",client,targets[i],armour);
	}

	return Plugin_Handled;
}

public Action:Command_HP(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_hp <target> <hp>");
		return Plugin_Handled;	
	}	
	decl String:pattern[64],String:buffer[64],String:health[16];
	GetCmdArg(1,pattern,sizeof(pattern));
	GetCmdArg(2,health,sizeof(health));
	new hp = StringToInt(health);
	new targets[64],bool:mb;
	new count = ProcessTargetString(pattern,client,targets,sizeof(targets),COMMAND_FILTER_ALIVE,buffer,sizeof(buffer),mb);
	if (!count) ReplyToCommand(client,"%t","No target",YELLOW,TEAMCOLOR,pattern,YELLOW);
	else for (new i = 0; i < count; i++)
	if (IsClientInGame(targets[i]))
	{
		SetEntProp(targets[i], Prop_Send, "m_iHealth", hp, 1);
		SetEntProp(targets[i], Prop_Data, "m_iHealth", hp, 1);
		Notify(client,targets[i],"Health Notify",hp);
		if (GetConVarBool(hLog)) LogAction(client,targets[i],"\"%L\" set health of player \"%L\" to %d",client,targets[i],hp);
	}

	return Plugin_Handled;
}

public Action:Command_Give(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_give <target> <entity>");
		return Plugin_Handled;	
	}	
	decl String:pattern[64],String:buffer[64],String:ent[64];
	GetCmdArg(1,pattern,sizeof(pattern));
	GetCmdArg(2,ent,sizeof(ent));
	new targets[64],bool:mb;
	new count = ProcessTargetString(pattern,client,targets,sizeof(targets),0,buffer,sizeof(buffer),mb);
	if (!count) ReplyToCommand(client,"%t","No target",YELLOW,TEAMCOLOR,pattern,YELLOW);
	else for (new i = 0; i < count; i++)
	if (IsClientInGame(targets[i]))
	{
		if (GivePlayerItem(targets[i],ent) == -1)
		{
			decl String:weapon[64];
			Format(weapon,sizeof(weapon),"weapon_%s",ent);
			if (GivePlayerItem(targets[i],weapon) != -1)
				Notify(client,targets[i],"Give Notify",weapon);
		} else
			Notify(client,targets[i],"Give Notify",ent);
		if (GetConVarBool(hLog)) LogAction(client,targets[i],"\"%L\" gived item %s to player \"%L\"",client,ent,targets[i]);
	}

	return Plugin_Handled;
}

public Action:Command_Speed(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_speed <target> <multiplier>");
		return Plugin_Handled;	
	}	
	decl String:pattern[64],String:buffer[64],String:mul[16];
	GetCmdArg(1,pattern,sizeof(pattern));
	GetCmdArg(2,mul,sizeof(mul));
	new Float:mult = StringToFloat(mul);
	new targets[64],bool:mb;
	new count = ProcessTargetString(pattern,client,targets,sizeof(targets),COMMAND_FILTER_ALIVE,buffer,sizeof(buffer),mb);
	if (!count) ReplyToCommand(client,"%t","No target",YELLOW,TEAMCOLOR,pattern,YELLOW);
	else for (new i = 0; i < count; i++)
	if (IsClientInGame(targets[i]))
	{
		SetEntPropFloat(targets[i], Prop_Data, "m_flLaggedMovementValue", mult);
		Notify(client,targets[i],"Speed Notify",mult);
		if (GetConVarBool(hLog)) LogAction(client,targets[i],"\"%L\" set speed of player \"%L\" to %.1f",client,targets[i],mult);
	}

	return Plugin_Handled;
}

public Action:Command_Cash(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_cash <target> <[+/-]amount>");
		return Plugin_Handled;	
	}	
	decl String:pattern[64],String:buffer[64],String:cash[16];
	GetCmdArg(1,pattern,sizeof(pattern));
	GetCmdArg(2,cash,sizeof(cash));
	new csh = StringToInt(cash);
	new targets[64],bool:mb;
	new count = ProcessTargetString(pattern,client,targets,sizeof(targets),0,buffer,sizeof(buffer),mb);
	if (!count) ReplyToCommand(client,"%t","No target",YELLOW,TEAMCOLOR,pattern,YELLOW);
	else for (new i = 0; i < count; i++)
	if (IsClientInGame(targets[i]))
	{
		new val = GetEntProp(targets[i], Prop_Send, "m_iAccount");
		if ((cash[0] == '+') || (cash[0] == '-'))
		{
			val += csh;
			if (val < 0) val = 0;
			Notify(client,targets[i],"Cash Change Notify",val,cash);
			if (GetConVarBool(hLog)) LogAction(client,targets[i],"\"%L\" changed cash of player \"%L\" to %d [%s]",client,targets[i],val,cash);
		} else
		{
			val = csh;
			Notify(client,targets[i],"Cash Set Notify",csh);
			if (GetConVarBool(hLog)) LogAction(client,targets[i],"\"%L\" changed cash of player \"%L\" to %d",client,targets[i],csh);
		}
		SetEntProp(targets[i], Prop_Send, "m_iAccount", val);
	}
	return Plugin_Handled;
}

public Action:Command_Frags(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_frags <target> <[+/-]amount>");
		return Plugin_Handled;	
	}	
	decl String:pattern[64],String:buffer[64],String:frags[16];
	GetCmdArg(1,pattern,sizeof(pattern));
	GetCmdArg(2,frags,sizeof(frags));
	new frag = StringToInt(frags);
	new targets[64],bool:mb;
	new count = ProcessTargetString(pattern,client,targets,sizeof(targets),0,buffer,sizeof(buffer),mb);
	if (!count) ReplyToCommand(client,"%t","No target",YELLOW,TEAMCOLOR,pattern,YELLOW);
	else for (new i = 0; i < count; i++)
	if (IsClientInGame(targets[i]))
	{
		new val = GetClientFrags(targets[i]);
		if ((frags[0] == '+') || (frags[0] == '-'))
		{
			val += frag;
			if (val < 0) val = 0;
			Notify(client,targets[i],"Frags Change Notify",val,frags);
			if (GetConVarBool(hLog)) LogAction(client,targets[i],"\"%L\" changed frags of player \"%L\" to %d [%s]",client,targets[i],val,frags);
		} else
		{
			val = frag;
			Notify(client,targets[i],"Frags Set Notify",frag);
			if (GetConVarBool(hLog)) LogAction(client,targets[i],"\"%L\" changed frags of player \"%L\" to %d",client,targets[i],frag);
		}
		SetEntProp(targets[i], Prop_Data, "m_iFrags", val);
	}
	return Plugin_Handled;
}

public Action:Command_Deaths(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_deaths <target> <[+/-]amount>");
		return Plugin_Handled;	
	}	
	decl String:pattern[64],String:buffer[64],String:deaths[16];
	GetCmdArg(1,pattern,sizeof(pattern));
	GetCmdArg(2,deaths,sizeof(deaths));
	new death = StringToInt(deaths);
	new targets[64],bool:mb;
	new count = ProcessTargetString(pattern,client,targets,sizeof(targets),0,buffer,sizeof(buffer),mb);
	if (!count) ReplyToCommand(client,"%t","No target",YELLOW,TEAMCOLOR,pattern,YELLOW);
	else for (new i = 0; i < count; i++)
	if (IsClientInGame(targets[i]))
	{
		new val = GetClientDeaths(targets[i]);
		if ((deaths[0] == '+') || (deaths[0] == '-'))
		{
			val += death;
			if (val < 0) val = 0;
			Notify(client,targets[i],"Deaths Change Notify",val,deaths);
			if (GetConVarBool(hLog)) LogAction(client,targets[i],"\"%L\" changed deaths of player \"%L\" to %d [%s]",client,targets[i],val,deaths);
		} else
		{
			val = death;
			Notify(client,targets[i],"Deaths Set Notify",death);
			if (GetConVarBool(hLog)) LogAction(client,targets[i],"\"%L\" changed deaths of player \"%L\" to %d",client,targets[i],death);
		}
		SetEntProp(targets[i], Prop_Data, "m_iDeaths", val);
	}
	return Plugin_Handled;
}

public Action:Command_Balance(client, args)
{
	Balance(false);
	if (GetConVarBool(hLog)) LogAction(client,-1,"\"%L\" balanced teams",client);
	return Plugin_Handled;
}

public Action:Command_Shuffle(client, args)
{
	Balance(false);
	SetRandomSeed(GetSysTickCount());
	new m = 0;
	new tm[64];
	for (new i = 1; i <= MaxClients; i++)
	if (IsClientInGame(i) && (GetClientTeam(i) > 1))
	{
		tm[i] = GetClientTeam(i);
		m++;
	}
	if (m%4) m += 3;
	m /= 4;
	new fail_max = 1000;
	while (m)
	for (new i = 1; (i <= MaxClients) && m; i++)
	if (IsClientInGame(i) && (GetRandomInt(0,9) > 4) && (GetClientTeam(i) > 1) && (GetClientTeam(i) == tm[i]))
	{
		new t = -1;
		while (t == -1)
		for	(new j = 1; (j <= MaxClients) && (t == -1); j++)
		if ((i != j) && IsClientInGame(j) && (GetClientTeam(j) > 1) 
			&& (GetClientTeam(i) != GetClientTeam(j)) && (GetRandomInt(0,9) > 4)) t = j;
		else if (fail_max-- < 0) return Plugin_Handled;

		tm[i] = GetClientTeam(t);
		tm[t] = GetClientTeam(i);
		m--;
	} else if (fail_max-- < 0) return Plugin_Handled;
	for (new i = 1; i <= MaxClients; i++)
	if (IsClientInGame(i) && (GetClientTeam(i) != tm[i])) ChangeClientTeamEx(i,tm[i]);
	if (GetConVarBool(hLog)) LogAction(client,-1,"\"%L\" shuffled teams",client);
	return Plugin_Handled;
}

public Action:Command_TeamSwap(client, args)
{
	for (new i = 1; i <= MaxClients; i++)
	if (IsClientInGame(i))
	{
		if (GetClientTeam(i) == 2) ChangeClientTeamEx(i,3);
		else if (GetClientTeam(i) == 3) ChangeClientTeamEx(i,2);
	}
	new ts = GetTeamScore(2);
	SetTeamScore(2,GetTeamScore(3));
	SetTeamScore(3,ts);
	if (GetConVarBool(hLog)) LogAction(client,-1,"\"%L\" swapped teams",client);
	return Plugin_Handled;
}

public Action:Command_Team(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_team <target> <team>");
		return Plugin_Handled;	
	}	
	decl String:pattern[64],String:buffer[64],String:team[16];
	GetCmdArg(1,pattern,sizeof(pattern));
	GetCmdArg(2,team,sizeof(team));
	new tm = StringToInt(team);
	new targets[64],bool:mb;
	new count = ProcessTargetString(pattern,client,targets,sizeof(targets),0,buffer,sizeof(buffer),mb);
	if (!count) ReplyToCommand(client,"%t","No target",YELLOW,TEAMCOLOR,pattern,YELLOW);
	else for (new i = 0; i < count; i++)
	if (IsClientInGame(targets[i]))
	{
		if ((game == 0) && ((tm == 2) || (tm == 3))) ChangeClientTeamEx(targets[i],tm);
		else ChangeClientTeam(targets[i],tm);
		if (GetConVarBool(hLog)) LogAction(client,targets[i],"\"%L\" set team of player \"%L\" to %d",client,targets[i],tm);
	}
	return Plugin_Handled;
}

public Action:Command_Spec(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_spec <target>");
		return Plugin_Handled;	
	}	
	decl String:pattern[64],String:buffer[64];
	GetCmdArg(1,pattern,sizeof(pattern));
	new targets[64],bool:mb;
	new count = ProcessTargetString(pattern,client,targets,sizeof(targets),0,buffer,sizeof(buffer),mb);
	if (!count) ReplyToCommand(client,"%t","No target",YELLOW,TEAMCOLOR,pattern,YELLOW);
	else for (new i = 0; i < count; i++)
	if (IsClientInGame(targets[i]))
	{
		if (IsPlayerAlive(targets[i])) ForcePlayerSuicide(targets[i]);
		ChangeClientTeam(targets[i],1);
		if (GetConVarBool(hLog)) LogAction(client,targets[i],"\"%L\" moved player \"%L\" to spectators",client,targets[i]);
	}
	return Plugin_Handled;
}

public Action:Command_Exec(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_exec <target> <cmd>");
		return Plugin_Handled;	
	}	
	decl String:pattern[64],String:buffer[64],String:cmd[128];
	GetCmdArg(1,pattern,sizeof(pattern));
	GetCmdArg(2,cmd,sizeof(cmd));
	new targets[64],bool:mb;
	new count = ProcessTargetString(pattern,client,targets,sizeof(targets),0,buffer,sizeof(buffer),mb);
	if (!count) ReplyToCommand(client,"%t","No target",YELLOW,TEAMCOLOR,pattern,YELLOW);
	else for (new i = 0; i < count; i++)
	if (IsClientInGame(targets[i]) && !IsFakeClient(targets[i]))
	{
		ClientCommand(targets[i], cmd);
		if (GetConVarBool(hLog)) LogAction(client,targets[i],"\"%L\" executed command \"%s\" on \"%L\"",client,cmd,targets[i]);
	}
	return Plugin_Handled;
}

public Action:Command_FExec(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_fexec <target> <cmd>");
		return Plugin_Handled;	
	}	
	decl String:pattern[64],String:buffer[64],String:cmd[128];
	GetCmdArg(1,pattern,sizeof(pattern));
	GetCmdArg(2,cmd,sizeof(cmd));
	new targets[64],bool:mb;
	new count = ProcessTargetString(pattern,client,targets,sizeof(targets),0,buffer,sizeof(buffer),mb);
	if (!count) ReplyToCommand(client,"%t","No target",YELLOW,TEAMCOLOR,pattern,YELLOW);
	else for (new i = 0; i < count; i++)
	if (IsClientInGame(targets[i]) && !IsFakeClient(targets[i]))
	{
		FakeClientCommandEx(targets[i], cmd);
		if (GetConVarBool(hLog)) LogAction(client,targets[i],"\"%L\" fake-executed command \"%s\" on \"%L\"",client,cmd,targets[i]);
	}
	return Plugin_Handled;
}

public Action:Command_Location(client, args)
{
	decl String:Name[64];
	new Float:origin[3];
	if (args)
	{
		decl String:pattern[64],String:buffer[64];
		GetCmdArg(1,pattern,sizeof(pattern));
		new targets[64],bool:mb;
		new count = ProcessTargetString(pattern,client,targets,sizeof(targets),0,buffer,sizeof(buffer),mb);
		for (new i = 0; i < count; i++)
		if (IsClientInGame(targets[i]))
		{
			GetEntPropVector(targets[i], Prop_Send, "m_vecOrigin", origin);
			GetClientName(targets[i],Name,sizeof(Name));
			PrintToChatEx(targets[i],client,"%t","Get Location Notify",YELLOW,TEAMCOLOR,Name,YELLOW,GREEN,origin[0],origin[1],origin[2],YELLOW);
		}
	} else if (client)
	{
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", origin);
		GetClientName(client,Name,sizeof(Name));
		PrintToChatEx(client,client,"%t","Get Location Notify",YELLOW,TEAMCOLOR,Name,YELLOW,GREEN,origin[0],origin[1],origin[2],YELLOW);
	}
	return Plugin_Handled;
}

public Action:Command_SaveLocation(client, args)
{
	if (args > 2)
	{
		decl String:ax[16];
		GetCmdArg(1,ax,sizeof(ax));
		coords[client][0] = StringToFloat(ax);
		GetCmdArg(2,ax,sizeof(ax));
		coords[client][1] = StringToFloat(ax);
		GetCmdArg(3,ax,sizeof(ax));
		coords[client][2] = StringToFloat(ax);	
	} else if (client)
	{
		new Float:origin[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", origin);
		coords[client][0] = origin[0];
		coords[client][1] = origin[1];
		coords[client][2] = origin[2];
	}
	PrintToChatEx(client,client,"%t","Save Location Notify",YELLOW,GREEN,coords[client][0],coords[client][1],coords[client][2],YELLOW);
	
	return Plugin_Handled;
}

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
		decl String:ax[16];
		GetCmdArg(2,ax,sizeof(ax));
		origin[0] = StringToFloat(ax);
		GetCmdArg(3,ax,sizeof(ax));
		origin[1] = StringToFloat(ax);
		GetCmdArg(4,ax,sizeof(ax));
		origin[2] = StringToFloat(ax);	
	} else
	if (args > 1)
	{
		decl String:cl[64];
		GetCmdArg(2,cl,sizeof(cl));
		new tgt = FindTarget(client,cl);
		if ((tgt != -1) && IsValidEntity(tgt)) GetEntPropVector(tgt, Prop_Send, "m_vecOrigin", origin);
		else
			return Plugin_Handled;
	} else
	{
		origin[0] = coords[client][0];
		origin[1] = coords[client][1];
		origin[2] = coords[client][2];
	}
	decl String:pattern[64],String:buffer[64];
	GetCmdArg(1,pattern,sizeof(pattern));
	new targets[64],bool:mb;
	new count = ProcessTargetString(pattern,client,targets,sizeof(targets),0,buffer,sizeof(buffer),mb);
	if (!count) ReplyToCommand(client,"%t","No target",YELLOW,TEAMCOLOR,pattern,YELLOW);
	else for (new i = 0; i < count; i++)
	if (IsClientInGame(targets[i]))
	{
		TeleportEntity(targets[i], origin, NULL_VECTOR, NULL_VECTOR);
		Notify(client,targets[i],"Teleport Notify",origin[0],origin[1],origin[2]);
		if (GetConVarBool(hLog)) LogAction(client,targets[i],"\"%L\" teleported player \"%L\" to %.1f %.1f %.1f",client,targets[i],origin[0],origin[1],origin[2]);
	}
	
	return Plugin_Handled;
}

public Action:Command_God(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_god <target> <0|1>");
		return Plugin_Handled;	
	}	
	decl String:pattern[64],String:buffer[64],String:god[4];
	GetCmdArg(1,pattern,sizeof(pattern));
	GetCmdArg(2,god,sizeof(god));
	new gd = StringToInt(god);
	new targets[64],bool:mb;
	new count = ProcessTargetString(pattern,client,targets,sizeof(targets),COMMAND_FILTER_ALIVE,buffer,sizeof(buffer),mb);
	if (!count) ReplyToCommand(client,"%t","No target",YELLOW,TEAMCOLOR,pattern,YELLOW);
	else for (new i = 0; i < count; i++)
	if (IsClientInGame(targets[i]))
	{
		SetEntProp(targets[i], Prop_Data, "m_takedamage", gd?0:2, 1);
		Notify(client,targets[i],gd?"God Notify":"NoGod Notify");
		if (GetConVarBool(hLog)) LogAction(client,targets[i],"\"%L\" set godmode of player \"%L\" to %d",client,targets[i],gd);
	}
	return Plugin_Handled;
}

public Action:Command_NV(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_nv <target> <0|1>");
		return Plugin_Handled;	
	}	
	decl String:pattern[64],String:buffer[64],String:nvs[4];
	GetCmdArg(1,pattern,sizeof(pattern));
	GetCmdArg(2,nvs,sizeof(nvs));
	new nv = StringToInt(nvs);
	new targets[64],bool:mb;
	new count = ProcessTargetString(pattern,client,targets,sizeof(targets),COMMAND_FILTER_ALIVE,buffer,sizeof(buffer),mb);
	if (!count) ReplyToCommand(client,"%t","No target",YELLOW,TEAMCOLOR,pattern,YELLOW);
	else for (new i = 0; i < count; i++)
	if (IsClientInGame(targets[i]))
	{
		SetEntProp(targets[i], Prop_Send, "m_bHasNightVision", nv?1:0, 1);
		Notify(client,targets[i],nv?"NV Notify":"NoNV Notify");
		if (GetConVarBool(hLog)) LogAction(client,targets[i],"\"%L\" set nightvision of player \"%L\" to %d",client,targets[i],nv);
	}
	return Plugin_Handled;
}

public Action:Command_Defuser(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_defuser <target> <0|1>");
		return Plugin_Handled;	
	}	
	decl String:pattern[64],String:buffer[64],String:def[4];
	GetCmdArg(1,pattern,sizeof(pattern));
	GetCmdArg(2,def,sizeof(def));
	new df = StringToInt(def);
	new targets[64],bool:mb;
	new count = ProcessTargetString(pattern,client,targets,sizeof(targets),COMMAND_FILTER_ALIVE,buffer,sizeof(buffer),mb);
	if (!count) ReplyToCommand(client,"%t","No target",YELLOW,TEAMCOLOR,pattern,YELLOW);
	else for (new i = 0; i < count; i++)
	if (IsClientInGame(targets[i]) && (GetClientTeam(targets[i]) == CS_TEAM_CT))
	{
		SetEntProp(targets[i], Prop_Send, "m_bHasDefuser", df?1:0, 1);
		Notify(client,targets[i],df?"Defuser Notify":"NoDefuser Notify");
		if (GetConVarBool(hLog)) LogAction(client,targets[i],"\"%L\" set defuser of player \"%L\" to %d",client,targets[i],df);
	}
	return Plugin_Handled;
}

ExtendMap(client,mins)
{
	ExtendMapTimeLimit(mins*60);

	Notify(client,client,"Extend Notify",mins);
	if (GetConVarBool(hLog)) LogAction(client,-1,"\"%L\" extended map for %d minutes",client,mins);
}

public Action:Command_RR(client, args)
{
	new t = 1;
	if (args)
	{
		decl String:ax[16];
		GetCmdArg(1,ax,sizeof(ax));
		t = StringToInt(ax);
	}	
	ServerCommand("mp_restartgame %d",t);

	Notify(client,client,"RR Notify",t);
	if (GetConVarBool(hLog)) LogAction(client,-1,"\"%L\" restarted game in %d sec",client,t);
	return Plugin_Handled;	
}

public Action:Command_Extend(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_extend <minutes>");
		return Plugin_Handled;	
	}	
	decl String:m[16];
	GetCmdArg(1,m,sizeof(m));
	ExtendMap(client,StringToInt(m));

	return Plugin_Handled;	
}

public Action:Command_Shutdown(client, args)
{
	new Float:to = 5.0;
	if (args)
	{
		decl String:ax[16];
		GetCmdArg(1,ax,sizeof(ax));
		to = StringToFloat(ax);
	}
	PrintToChatAllEx(client,"%t","Shutdown Notify",YELLOW,GREEN,to,YELLOW);
	if (GetConVarBool(hLog)) LogAction(client,-1,"\"%L\" shuts down the server in %.1f seconds",client,to);
	CreateTimer(to, Shutdown);
	return Plugin_Handled;
}
	
public Action:Shutdown(Handle:timer)
{
	for (new i = 1; i <= MaxClients; i++)
	if (IsClientInGame(i) && !IsFakeClient(i)) ClientCommand(i, "retry");
	
	InsertServerCommand("quit");
	ServerExecute();
	return Plugin_Handled;
}
