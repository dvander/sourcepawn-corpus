/*
Stamm by Popoklopsi

Changelog:

comming soon: Better Debug, more Happy Hour options, PayPal Option

1.45 Added Stamm Webscript (Thanks to HSFighter!), SQL Changes, 60 Seconds after Map Start no Jpin Sound, Removed Option "stamm_connectiontype", -> you have to change the database config, for more infos see config!!

1.41 Fixed Lag Problems (hopefully), Changed something with logging

1.4 Fixed Language Phrase Errors, Fixed invalid Client Errors, Fixed Timer Error, Filter Option default off, Fixed VIP Chat, Fixed bug when showing current Time, Fixed rounds were not saved, Added more Debug

1.32 Fixed VIP Joinsound, Added Russian, Changed save times, fixed VIP Top Bug

1.31 Model can be changed without changing team, new config and language files !!

1.3 Bugs fixed, Welcome Messages & Joinsound fixed, New options (Tag & Flag), Added Cvarlist ingame (stamm_cvarlist)

1.2 Fixed time bug, Fixed Model bug, Changed "stats" to "points"

1.11 Add Option "'O' flag = VIP", fixed time bug

1.1 Save Points direct to the database

1.0 Release

Copyright by Popoklopsi 2009-2099!

*/

/* Includes */

#include <sourcemod>
#include <sdktools>
#include <colors>  
#include <socket>

/* Use Semi Colon */

#pragma semicolon 1

/* Define Standards */

#define FEATURE_TAG 0
#define FEATURE_MONEY 1
#define FEATURE_JOINSOUND 2
#define FEATURE_WELCOME 3
#define FEATURE_LEAVE 4
#define FEATURE_MODEL 5
#define FEATURE_VIPCHAT 6
#define FEATURE_CHAT 7
#define FEATURE_SLOT 8
#define FEATURE_HOLY 9

#define YELLOW 0x01
#define GREEN 0x04
#define LIGHTGREEN 0x03

/* Global Handles */

new Handle:db;
new Handle:info;
new Handle:credits;
new Handle:cmdlist;
new Handle:adminpanel;
new Handle:resetpanel;
new Handle:ModelMenu;
new Handle:featurelist;
new Handle:MessageTagc;
new Handle:OwnChatTagc;
new Handle:texttowritec;
new Handle:stammdebugc;
new Handle:serveridc;
new Handle:allow_changec;
new Handle:model_changec;
new Handle:model_change_cmdc;
new Handle:vip_typec;
new Handle:stamm_levelc;
new Handle:bot_kill_counterc;
new Handle:lvl_up_soundc;
new Handle:min_playerc;
new Handle:infotimec;
new Handle:points_to_become_vipc;
new Handle:stamm_bronzec;
new Handle:stamm_silverc;
new Handle:stamm_goldc;
new Handle:stamm_platinumc;
new Handle:giveflagadminc;
new Handle:enable_filterc;
new Handle:enable_modelsc;
new Handle:same_modelsc;
new Handle:admin_modelc;
new Handle:admin_menuc;
new Handle:viplistc;
new Handle:viprankc;
new Handle:viplistminc;
new Handle:autochatc;
new Handle:own_chatc;
new Handle:vipcashc;
new Handle:enable_holy_grenadec;
new Handle:hear_holy_grenadec;
new Handle:enable_vip_slotc;
new Handle:vip_slotsc;
new Handle:vip_kick_messagec;
new Handle:let_freec;
new Handle:vip_kick_message2c;
new Handle:stamm_tag_on_offc;
new Handle:stammtagc;
new Handle:stammtagkickc;
new Handle:stammtag_posc;
new Handle:see_textc;
new Handle:join_showc;
new Handle:vip_joinsoundc;
new Handle:vip_chatwelcomec;
new Handle:vip_chatgoodbyec;
new Handle:updateaddonc;
new Handle:level_settings;
new Handle:model_settings;
new Handle:player_stamm;
new Handle:stamm_get;
new Handle:timetimer;
new Handle:inftimer;
new Handle:MapTimer_Timer;

/* Global Ints/float */

new Float:infotime;
new IsTF;
new stammdebug;
new serverid;
new allow_change;
new model_change;
new stamm_level;
new bot_kill_counter;
new min_player;
new points_to_become_vip;
new stamm_bronze;
new stamm_silver;
new stamm_gold;
new stamm_platinum;
new giveflagadmin;
new enable_filter;
new enable_models;
new same_models;
new admin_model;
new autochat;
new own_chat;
new vipcash;
new enable_holy_grenade;
new hear_holy_grenade;
new enable_vip_slot;
new vip_slots;
new let_free;
new stamm_tag_on_off;
new stammtagkick;
new see_text;
new viplistmin;
new join_show;
new vip_chatwelcome;
new vip_chatgoodbye;
new updateaddon;
new points;
new happyhouron;

new levels[10];

new pointsnumber[MAXPLAYERS + 1];
new happynumber[MAXPLAYERS + 1];
new happyfactor[MAXPLAYERS + 1];
new playervip[MAXPLAYERS + 1];
new playerpoints[MAXPLAYERS + 1];
new playertag[MAXPLAYERS + 1];
new playermoney[MAXPLAYERS + 1];
new playerchat[MAXPLAYERS + 1];
new playervipchat[MAXPLAYERS + 1];
new playerjoinsound[MAXPLAYERS + 1];
new playerwelcome[MAXPLAYERS + 1];
new playerdisconnect[MAXPLAYERS + 1];
new playermodel[MAXPLAYERS + 1];
new playerslot[MAXPLAYERS + 1];
new playerholy[MAXPLAYERS + 1];
new playerlevel[MAXPLAYERS + 1];
new PlayerHasModel[MAXPLAYERS + 1];
new LastTeam[MAXPLAYERS + 1];
new WantTag[MAXPLAYERS + 1];
new WantHoly[MAXPLAYERS + 1];
new WantJoin[MAXPLAYERS + 1];
new WantVipChat[MAXPLAYERS + 1];
new WantChat[MAXPLAYERS + 1];

/* Global Strings */

new String:lvl_up_sound[PLATFORM_MAX_PATH + 1];
new String:vip_type[8];
new String:model_change_cmd[32];
new String:texttowrite[32];
new String:admin_menu[32];
new String:viplist[32];
new String:viprank[32];
new String:MessageTag[32];
new String:OwnChatTag[32];
new String:vip_kick_message[128];
new String:vip_kick_message2[128];
new String:stammtag[MAX_NAME_LENGTH + 1];
new String:stammtag_pos[4];
new String:vip_joinsound[PLATFORM_MAX_PATH + 1];
new String:T_1_MODEL[PLATFORM_MAX_PATH + 1];
new String:T_1_NAME[128];
new String:T_2_MODEL[PLATFORM_MAX_PATH + 1];
new String:T_2_NAME[128];
new String:CT_1_MODEL[PLATFORM_MAX_PATH + 1];
new String:CT_1_NAME[128];
new String:CT_2_MODEL[PLATFORM_MAX_PATH + 1];
new String:CT_2_NAME[128];
new String:tablename[32];
new String:Plugin_Version[64] = "1.45";
new String:PlayerModel[MAXPLAYERS + 1][PLATFORM_MAX_PATH + 1];
new String:LogFile[PLATFORM_MAX_PATH + 1];
new String:DebugFile[PLATFORM_MAX_PATH + 1];
new String:SQLError[256];

/* Global Bools */

new bool:ClientReady[MAXPLAYERS + 1];
new bool:MapTimer_Joinsound;

/* SM Blocks */

public Plugin:myinfo =
{
	name = "Stamm",
	author = "Popoklopsi",
	version = Plugin_Version,
	description = "A powerful VIP Addon with lot of features",
	url = "http://pup-board.de"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("GetClientStammPoints", Native_GetClientStammPoints);
	CreateNative("GetStammLevels", Native_GetStammLevels);
	CreateNative("GetStammType", Native_GetStammType);
	CreateNative("SetClientStammPoints", Native_SetClientStammPoints);
	CreateNative("AddClientStammPoints", Native_AddClientStammPoints);
	CreateNative("DelClientStammPoints", Native_DelClientStammPoints);
	CreateNative("IsClientVip", Native_IsClientVip);
	CreateNative("IsStammLevelOn", Native_IsStammLevelOn);
	
	return APLRes_Success;
}

public OnPluginStart()
{
	decl String:CurrentDate[20];
	
	CheckGame();
	
	points = 1;
	happyhouron = 0;
	
	LoadTranslations("stamm.phrases");
	
	CreateConfig();
	
	if (db == INVALID_HANDLE) SQL_TConnect(LoadDB, "stamm_sql");
	
	player_stamm = CreateGlobalForward("OnClientBecomeVip", ET_Event, Param_Cell);
	stamm_get = CreateGlobalForward("OnClientGetStammPoints", ET_Event, Param_Cell, Param_Cell);
	
	RegServerCmd("set_stamm_points", SetPlayerPoints, "Set Points of a Player");
	RegServerCmd("add_stamm_points", AddPlayerPoints, "Add Points of a Player");
	RegServerCmd("del_stamm_points", DelPlayerPoints, "Del Points of a Player");

	RegConsoleCmd("sm_sinfo", InfoPanel);
	RegConsoleCmd("stamm_cvarlist", ShowConVars);
	RegConsoleCmd("sm_schange", ChangePanel);
	RegConsoleCmd("say", CmdSay);
	
	HookEvent("player_say", event_PlayerSay);
	HookEvent("player_death", event_PlayerDeath);
	HookEvent("player_spawn", event_PlayerSpawn);
	HookEvent("player_team", event_PlayerTeam);
	
	if (!IsTF)
	{
		HookEvent("weapon_fire", event_WeaponFire);
		HookEvent("hegrenade_detonate", event_HeDetonate);
	}
	
	for(new i=0; i <= MaxClients; i++) ClientReady[i] = false;
	
	FormatTime(CurrentDate, sizeof(CurrentDate), "%d-%m-%y");
	
	BuildPath(Path_SM, LogFile, sizeof(LogFile), "logs/Stamm_Logs (%s).log", CurrentDate);
	BuildPath(Path_SM, DebugFile, sizeof(DebugFile), "logs/Stamm_SQL_DEBUG (%s).log", CurrentDate);
}

public OnClientPostAdminCheck(client)
{
	if (IsClientConnected(client))
	{
		decl String:name[MAX_NAME_LENGTH + 1];
		
		GetClientName(client, name, sizeof(name));
		
		if (!StrEqual(vip_joinsound, "0") && WantJoin[client])
		{
			if (!stamm_level) 
			{
				if (playervip[client]) EmitSoundToAll(vip_joinsound);
			}
			else
			{
				if (playerjoinsound[client] && MapTimer_Joinsound == true) EmitSoundToAll(vip_joinsound);
			}
		}
				
		if (vip_chatwelcome)
		{
			if (!stamm_level)
			{
				if (playervip[client]) PrintToChatAll("%c[ Stamm ] %T", GREEN, "WelcomeMessage", LANG_SERVER, LIGHTGREEN, GREEN, name, GREEN, LIGHTGREEN, GREEN);
			}
			else
			{
				if (playerwelcome[client]) PrintToChatAll("%c[ Stamm ] %T", GREEN, "WelcomeMessage", LANG_SERVER, LIGHTGREEN, GREEN, name, GREEN, LIGHTGREEN, GREEN);
			}
		}

		if (giveflagadmin) CheckFlagAdmin(client);
		if (join_show) ShowPlayerPoints(client);
	}
}

public OnClientAuthorized(client, const String:auth[]) InsertPlayer(client);

public OnClientDisconnect(client)
{
	decl String:name[MAX_NAME_LENGTH+1];
	
	GetClientName(client, name, sizeof(name));
	
	if (!IsClientBot(client))
	{
		if (vip_chatgoodbye)
		{
			if(!stamm_level)
			{
				if (playervip[client]) PrintToChatAll("%c[ Stamm ] %T", LIGHTGREEN, "LeaveMessage", LANG_SERVER, GREEN, LIGHTGREEN, name, GREEN);
			}
			else
			{
				if (playervip[client]) PrintToChatAll("%c[ Stamm ] %T", LIGHTGREEN, "LeaveMessage", LANG_SERVER, GREEN, LIGHTGREEN, name, GREEN);
			}
			
		}
	}
	
	ClientReady[client] = false;
}


public OnConfigsExecuted()
{
	ReadConfig();
	CreatePanels();
	Format(tablename, sizeof(tablename), "STAMM_DB_%i", serverid);
	
	if (enable_holy_grenade && !IsTF) DownloadHoly();
	if (!StrEqual(lvl_up_sound, "0")) DownloadLevel();
	if (!StrEqual(vip_joinsound, "0")) DownloadJoin();
	if (enable_models) ModelDownloads();
	
	if (!StrEqual(T_1_MODEL, "") && !StrEqual(T_1_MODEL, "0") && !StrEqual(T_1_MODEL, " ")) PrecacheModel(T_1_MODEL, true);
	if (!StrEqual(T_2_MODEL, "") && !StrEqual(T_2_MODEL, "0") && !StrEqual(T_2_MODEL, " ")) PrecacheModel(T_2_MODEL, true);
	if (!StrEqual(CT_1_MODEL, "") && !StrEqual(CT_1_MODEL, "0") && !StrEqual(CT_1_MODEL, " ")) PrecacheModel(CT_1_MODEL, true);
	if (!StrEqual(CT_2_MODEL, "") && !StrEqual(CT_2_MODEL, "0") && !StrEqual(CT_2_MODEL, " ")) PrecacheModel(CT_2_MODEL, true);
	if (enable_holy_grenade && !IsTF) PrecacheModel("models/holy_grenade/holy_grenade.mdl", true);
	if (enable_holy_grenade && !IsTF) PrecacheSound("stamm/throw1.wav", true);
	if (enable_holy_grenade && !IsTF) PrecacheSound("stamm/explode1.wav", true);
	if (!StrEqual(lvl_up_sound, "0")) PrecacheSound(lvl_up_sound, true);
	if (!StrEqual(vip_joinsound, "0")) PrecacheSound(vip_joinsound, true);
	
	inftimer = CreateTimer(infotime, PlayerInfoTimer, _, TIMER_REPEAT);
	
	if (StrEqual(vip_type, "time")) timetimer = CreateTimer(60.0, PlayerTime, _,TIMER_REPEAT);
}

public bool:OnClientConnect(client, String:rejectmsg[], maxlen)
{
	ClientReady[client] = false;
	PlayerHasModel[client] = 0;
	
	if (updateaddon && !IsClientBot(client)) CreateTimer(10.0, CheckUpdate, client);
	
	return true;
}

public OnMapEnd()
{
	if (timetimer != INVALID_HANDLE) ClearTimer(timetimer);
	if (inftimer != INVALID_HANDLE) ClearTimer(inftimer);
}
public OnMapStart()
{
	points = 1;
	MapTimer_Joinsound = false;
	if (MapTimer_Timer != INVALID_HANDLE) ClearTimer(MapTimer_Timer);
	MapTimer_Timer = CreateTimer(60.0, MapTimer_Change);
	happyhouron = 0;
}

public OnPluginEnd()
{
	CloseHandle(credits);
	CloseHandle(info);
	CloseHandle(cmdlist);
	CloseHandle(featurelist);
}
/* Timer Handler*/

public Action:MapTimer_Change(Handle:timer)
{
	MapTimer_Joinsound = true;
}

public Action:EndHappyHour(Handle:timer)
{
	happyhouron = 0;
	points = 1;
}

public Action:CheckUpdate(Handle:timer, any:client)
{
	if (IsClientConnected(client)) CheckForUpdate(client);
}

public Action:PlayerTime(Handle:timer)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsClientBot(i) && (GetClientTeam(i) == 2 || GetClientTeam(i) == 3) && min_player <= GetClientCount())
		{
			GivePlayerPoints(i);
			CheckVip(i);
		}
	}
	
	return Plugin_Continue;
}

public Action:PlayerInfoTimer(Handle:timer)
{
	if (StrEqual(vip_type, "rounds")) PrintToChatAll("%c[ Stamm ] %T", GREEN, "InfoTypRounds", LANG_SERVER, LIGHTGREEN, GREEN, texttowrite, LIGHTGREEN, GREEN );
	if (StrEqual(vip_type, "kills")) PrintToChatAll("%c[ Stamm ] %T", GREEN, "InfoTypKills", LANG_SERVER, LIGHTGREEN, GREEN, texttowrite, LIGHTGREEN, GREEN );
	if (StrEqual(vip_type, "time")) PrintToChatAll("%c[ Stamm ] %T", GREEN, "InfoTypTime", LANG_SERVER, LIGHTGREEN, GREEN, texttowrite, LIGHTGREEN, GREEN );
	
	PrintToChatAll("%c[ Stamm ] %T", GREEN, "InfoTypInfo", LANG_SERVER, LIGHTGREEN, GREEN, LIGHTGREEN);
	
	return Plugin_Continue;
}

public Action:change(Handle:timer, any:client)
{
	new ent = -1;
	
	ent = FindEntityByClassname(ent, "hegrenade_projectile");
	new owner = GetEntPropEnt(ent, Prop_Send, "m_hThrower");
	
	if (IsValidEntity(ent) && owner == client) SetEntityModel(ent, "models/holy_grenade/holy_grenade.mdl");
}


/* Events */

public Action:event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (client)
	{
		if (!IsClientBot(client)) PlayerHasModel[client] = 0;
	}
}

public Action:event_PlayerSay(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	decl String:text[129];
	
	GetEventString(event, "text", text, sizeof(text));
	
	if (StrEqual(text, texttowrite) && !IsClientBot(client)) ShowPlayerPoints(client);
	if (StrEqual(text, viplist) && !IsClientBot(client)) GetVIPTop(client);
	if (StrEqual(text, viprank) && !IsClientBot(client)) GetVIPRank(client);
}

public Action:event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	
	if (StrEqual(vip_type, "rounds") && GetClientCount() >= min_player && !IsClientBot(client)) 
	{
		if (GetClientTeam(client) == 2 || GetClientTeam(client) == 3)
		{
			GivePlayerPoints(client);
		}
	}
	CheckVip(client);
	if (happyhouron) PrintToChat(client, "%c[ Stamm ] %T", GREEN, "HappyActive", LANG_SERVER, LIGHTGREEN, GREEN, LIGHTGREEN, points);
	
	if (!IsClientBot(client))
	{
		if (vipcash && !IsTF)
		{
			new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount");
			new OldMoney = GetEntData(client, MoneyOffset);
			
			if (!stamm_level)
			{			
				if (playervip[client]) SetEntData(client, MoneyOffset, vipcash + OldMoney);
			}
			else
			{
				if (playermoney[client]) SetEntData(client, MoneyOffset, vipcash + OldMoney);
			}
		}
		
		if (enable_models)
		{
			if (GetClientTeam(client) == 2 || GetClientTeam(client) == 3)
			{
				if (LastTeam[client] != GetClientTeam(client)) PlayerHasModel[client] = 0;
				
				LastTeam[client] = GetClientTeam(client);
				
				if (!stamm_level)
				{
					if (playervip[client])
					{
						if (same_models) PrepareSameModels(client);
						else PrepareRandomModels(client);
					}
				}
				if (stamm_level)
				{
					if (playermodel[client])
					{
						if (same_models) PrepareSameModels(client);
						else PrepareRandomModels(client);
					}
				}
			}
		}
		
		if (stamm_tag_on_off) NameCheck(client);
		if (enable_filter) CheckDLFilter(client);
	}
}

public Action:event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetClientOfUserId(GetEventInt(event, "userid"));
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if (StrEqual(vip_type, "kills") && !IsClientBot(client) && GetClientCount() >= min_player && (GetClientTeam(client) == 2 || GetClientTeam(client) == 3) && (!IsClientBot(userid) || (IsClientBot(userid) && bot_kill_counter)) && userid != client && GetClientTeam(userid) != GetClientTeam(client)) 
	{
		GivePlayerPoints(client);
		CheckVip(client);
	}
}


public Action:event_WeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	decl String:weapon[256];
	
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	
	if ( enable_holy_grenade && !IsClientBot(client) && WantHoly[client])
	{
		if (StrEqual(weapon, "hegrenade")) 
		{
			if (!stamm_level)
			{
				if (playervip[client])
				{
					if (!hear_holy_grenade) EmitSoundToClient(client, "stamm/throw1.wav");
					if (hear_holy_grenade) EmitSoundToAll("stamm/throw1.wav");
					
					CreateTimer(0.25, change, client);
				}
			}
			else
			{
				if (playerholy[client])
				{
					if (!hear_holy_grenade) EmitSoundToClient(client, "stamm/throw1.wav");
					if (hear_holy_grenade) EmitSoundToAll("stamm/throw1.wav");
					
					CreateTimer(0.25, change, client);
				}
			}
		}
	}
}

public Action:event_HeDetonate(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	
	if ( enable_holy_grenade && !IsClientBot(client) && WantHoly[client])
	{
		if (!stamm_level)
		{
			if (playervip[client])
			{
				if (!hear_holy_grenade) EmitSoundToClient(client, "stamm/explode1.wav");
				if (hear_holy_grenade) EmitSoundToAll("stamm/explode1.wav");
			}
		}
		else
		{
			if (playerholy[client])
			{
				if (!hear_holy_grenade) EmitSoundToClient(client, "stamm/explode1.wav");
				if (hear_holy_grenade) EmitSoundToAll("stamm/explode1.wav");
			}
		}
	}
}

/* Reg Handler */

public Action:ShowConVars(client, args)
{
	PrintToConsole(client, "A list of all Stamm Cvars you can change ingame:");
	PrintToConsole(client, "--------------------------------------------------");
	PrintToConsole(client, "Last brackets = default value");
	PrintToConsole(client, "--------------------------------------------------");
	PrintToConsole(client, "-stamm_debug      			 // 1 = Log important Stamm steps, 0 = OFF (1)");
	PrintToConsole(client, "-stamm_oflag      			 // not 0 = a Player with the a special Flag become VIP (1='o', 2='p' , 3='q', 4='r', 5='s', 6='t'), 0 = Off (0)");
	PrintToConsole(client, "-stamm_bot_kill_counter	 // 1 = Count BOT Kills, too, 0 = Don't count BOT Kills (1)");
	PrintToConsole(client, "-stamm_lvl_up_sound  		 // 0 = Level Up Sound OFF, otherwise the Path to the sound, beginning after sound/ (stamm/lvl_up.mp3)");
	PrintToConsole(client, "-stamm_min_player      	 // Number of Players, which have to be on the Server, to count rounds/kills/time (0)");
	PrintToConsole(client, "-stamm_enable_filter   	 // 1 = if a Player haven't cl_downloadfilter to 'all', he have to change it, 0 = OFF (0)");
	PrintToConsole(client, "-stamm_enable_models   	 // 1 = Enable VIP Skins, 0 = OFF (1)");
	PrintToConsole(client, "-stamm_model_change	  	 // 0 = Players can only change models, when changing team, 1 = Players can always change it (1)");
	PrintToConsole(client, "-stamm_viplistmin    		 // How much points a Player must have, to come in the VIP Top, Time in Minutes (if you have much VIP's, make this number greater than the number to become VIP) (2000)");
	PrintToConsole(client, "-stamm_autochat    		 // 0 = No VIP Chat Tag 1 = VIP's get a special chat tag, if they start the message with '*' (1)");
	PrintToConsole(client, "-stamm_messagetag     	 	 // Tag when a player writes something as a VIP (VIP Message)");
	PrintToConsole(client, "-stamm_own_chat    		 // 0 = VIP's get no own chat 1 = VIP's get a own chat, if they start the message with '#' (1)");
	PrintToConsole(client, "-stamm_ownchattag     	 	 // Tag when a player writes something in the VIP Chat (VIP Chat)");
	PrintToConsole(client, "-stamm_vipcash	    		 // 0 = No VIP Cash x = Cash, what a VIP gets, when he join (NOT AVAILABLE IN TF2) (2000)");
	PrintToConsole(client, "-stamm_enable_holy_grenade  // Should VIP's get a Holy Grenade? 1 = yes, 0 = no (NOT AVAILABLE IN TF2) (1)");
	PrintToConsole(client, "-stamm_hear_holy_grenade	 // Should all Player hear the Holy Grenade? 1 = yes, 0 = no (NOT AVAILABLE IN TF2) (1)");
	PrintToConsole(client, "-stamm_enable_vip_slot   	 // Should VIP's get a Reserve Slot ? 1 = yes, 0 = no (Own Reserve Slot Function) (0)");
	PrintToConsole(client, "-stamm_vip_kick_message	 // Message, when someone join on a Reserve Slot (You joined on a Reserve Slot)");
	PrintToConsole(client, "-stamm_let_free		     // 1 = Let a Slot always free and kick a random Player  0 = Off (0)");
	PrintToConsole(client, "-stamm_vip_kick_message2	 // Message for the random kicked person (You get kicked, to let a VIP slot free)");
	PrintToConsole(client, "-stamm_stamm_tag_on_off  	 // 1 = VIP's get a VIP Tag, 0 = OFF (1)");
	PrintToConsole(client, "-stamm_stammtagkick		 // 1 = Kicks Player, which use Stamm Tag, but aren't VIPs, 0 = No Kick (1)");
	PrintToConsole(client, "-stamm_see_text		 	 // 1 = All see rounds/kills/time , 0 = only the player, who write it in the chat (1)");
	PrintToConsole(client, "-stamm_join_show			 // 1 = When a Player join, he see his rounds/kills/time, 0 = OFF (1)");
	PrintToConsole(client, "-stamm_vip_joinsound	 	 // 0 = No VIP Join Sound, otherwise the Path to the sound, beginning after sound/ (stamm/vip_join_fix.mp3)");
	PrintToConsole(client, "-stamm_vip_chatwelcome		 // Message when a VIP join the Server 1 = yes, 0 = no (1)");
	PrintToConsole(client, "-stamm_vip_chatgoodbye		 // Message when a VIP leave the Server 1 = yes, 0 = no (1)");
	PrintToConsole(client, "-stamm_updateaddon			 // 1 = Get Update Infomations, 0 = OFF (1)");
}

public Action:ChangePanel(client, args)
{
	if (allow_change)
	{
		new Handle:ChangeMenu = CreateMenu(ChangePanelHandler);
		SetMenuExitButton(ChangeMenu, false);
		
		if (WantTag[client] && stamm_tag_on_off) 
		{
			decl String:dTag[64];
			
			Format(dTag, sizeof(dTag), "%T", "TagOn", LANG_SERVER);
			
			AddMenuItem(ChangeMenu, "dTag", dTag);
		}
		if (!WantTag[client] && stamm_tag_on_off) 
		{
			decl String:eTag[64];
			
			Format(eTag, sizeof(eTag), "%T", "TagOff", LANG_SERVER);
			
			AddMenuItem(ChangeMenu, "eTag", eTag);
		}
		if (WantHoly[client] && enable_holy_grenade) 
		{
			decl String:dHoly[64];
			
			Format(dHoly, sizeof(dHoly), "%T", "HolyOn", LANG_SERVER);
			
			AddMenuItem(ChangeMenu, "dHoly", dHoly);
		}
		if (!WantHoly[client] && enable_holy_grenade) 
		{
			decl String:eHoly[64];
			
			Format(eHoly, sizeof(eHoly), "%T", "HolyOff", LANG_SERVER);
			
			AddMenuItem(ChangeMenu, "eHoly", eHoly);
		}
		if (WantJoin[client] && !StrEqual(vip_joinsound, "0")) 
		{
			decl String:dJoin[64];
			
			Format(dJoin, sizeof(dJoin), "%T", "JoinOn", LANG_SERVER);
			
			AddMenuItem(ChangeMenu, "dJoin", dJoin);
		}
		if (!WantJoin[client] && !StrEqual(vip_joinsound, "0")) 
		{
			decl String:eJoin[64];
			
			Format(eJoin, sizeof(eJoin), "%T", "JoinOff", LANG_SERVER);
			
			AddMenuItem(ChangeMenu, "eJoin", eJoin);
		}
		if (WantVipChat[client] && own_chat) 
		{
			decl String:dVipChat[64];
			
			Format(dVipChat, sizeof(dVipChat), "%T", "VipChatOn", LANG_SERVER);
			
			AddMenuItem(ChangeMenu, "dVipChat", dVipChat);
		}
		if (!WantVipChat[client] && own_chat) 
		{
			decl String:eVipChat[64];
			
			Format(eVipChat, sizeof(eVipChat), "%T", "VipChatOff", LANG_SERVER);
			
			AddMenuItem(ChangeMenu, "eVipChat", eVipChat);
		}
		if (WantChat[client] && autochat) 
		{
			decl String:dChat[64];
			
			Format(dChat, sizeof(dChat), "%T", "ChatOn", LANG_SERVER);
			
			AddMenuItem(ChangeMenu, "dChat", dChat);
		}
		if (!WantChat[client] && autochat) 
		{
			decl String:eChat[64];
			
			Format(eChat, sizeof(eChat), "%T", "ChatOff", LANG_SERVER);
			
			AddMenuItem(ChangeMenu, "eChat", eChat);
		}
		
		decl String:closetext[64];
		
		Format(closetext, sizeof(closetext), "%T", "Close", LANG_SERVER);
		
		AddMenuItem(ChangeMenu, "close", closetext);
		
		DisplayMenu(ChangeMenu, client, 30);

	}
}

public Action:InfoPanel(client, args)
{
	SendPanelToClient(info, client, InfoHandler, 20);
	
	return Plugin_Handled;
}

public Action:SetPlayerPoints(args)
{
	if (GetCmdArgs() == 2)
	{
		decl String:useridString[25];
		decl String:numberString[25];
		
		GetCmdArg(1, useridString, sizeof(useridString));
		GetCmdArg(2, numberString, sizeof(numberString));
		
		new client = GetClientOfUserId(StringToInt(useridString));
		new number = StringToInt(numberString);
		
		if (IsClientInGame(client) && !IsClientBot(client))
		{	
			playerpoints[client] = number;
			
			CheckVip(client);
		}
		
	}
	
	return Plugin_Handled;
}

public Action:AddPlayerPoints(args)
{
	if (GetCmdArgs() == 2)
	{
		decl String:useridString[25];
		decl String:numberString[25];
		
		GetCmdArg(1, useridString, sizeof(useridString));
		GetCmdArg(2, numberString, sizeof(numberString));
		
		new client = GetClientOfUserId(StringToInt(useridString));
		new number = StringToInt(numberString);
		
		if (IsClientInGame(client) && !IsClientBot(client))
		{	
			playerpoints[client] = playerpoints[client] + number;
				
			CheckVip(client);
		}
	}
	
	return Plugin_Handled;
}

public Action:DelPlayerPoints(args)
{
	if (GetCmdArgs() == 2)
	{
		decl String:useridString[25];
		decl String:numberString[25];
		
		GetCmdArg(1, useridString, sizeof(useridString));
		GetCmdArg(2, numberString, sizeof(numberString));
		
		new client = GetClientOfUserId(StringToInt(useridString));
		new number = StringToInt(numberString);
		
		
		if (IsClientInGame(client) && !IsClientBot(client))
		{	
			playerpoints[client] = playerpoints[client] - number;
			if (playerpoints[client] < 0) playerpoints[client] = 0;
			
			CheckVip(client);
		}
	}
	
	return Plugin_Handled;
}

public Action:CmdSay(client, args)
{
	decl String:text[128];
	decl String:name[MAX_NAME_LENGTH+1];
	
	GetClientName(client, name, sizeof(name));
	GetCmdArgString(text, sizeof(text));
	
	ReplaceString(text, sizeof(text), "\"", "");
	
	if (!IsClientBot(client))
	{
		if (happynumber[client] == 1)
		{
			new timetoset = StringToInt(text);
			
			if (timetoset > 1) 
			{
				happynumber[client] = timetoset;
			}
			else
			{
				happynumber[client] = 0;
				PrintToChat(client, "%c[ Stamm ] %c%T", GREEN, LIGHTGREEN, "aborted", LANG_SERVER);
				return Plugin_Handled;
			}
			
			PrintToChat(client, "%c[ Stamm ] %T", GREEN, "WriteHappyFactor", LANG_SERVER, LIGHTGREEN, GREEN);
			PrintToChat(client, "%c[ Stamm ] %T", GREEN, "WriteHappyFactorInfo", LANG_SERVER, LIGHTGREEN, GREEN, LIGHTGREEN);
			
			happyfactor[client] = 1;
				
			return Plugin_Handled;	
		}
		else if (happyfactor[client] == 1)
		{
			new factortoset = StringToInt(text);
			
			if (factortoset > 1) 
			{
				happyfactor[client] = 0;
				points = factortoset;
				happyhouron = 1;
				PrintToChatAll("%c[ Stamm ] %T", GREEN, "HappyActive", LANG_SERVER, LIGHTGREEN, GREEN, LIGHTGREEN, points);
				CreateTimer(float(happynumber[client])*60, EndHappyHour);
				happynumber[client] = 0;
			}
			else
			{
				PrintToChat(client, "%c[ Stamm ] %c%T", GREEN, LIGHTGREEN, "aborted", LANG_SERVER);
				happynumber[client] = 0;
				happyfactor[client] = 0;
			}
				
			return Plugin_Handled;	
		}
		else if (pointsnumber[client] > 0)
		{
			if (StrEqual(text, " ")) 
			{
				pointsnumber[client] = 0;
				PrintToChat(client, "%c[ Stamm ] %c%T", GREEN, LIGHTGREEN, "aborted", LANG_SERVER);
				return Plugin_Handled;
			}
			
			new choose = pointsnumber[client];
			new pointstoset = StringToInt(text);
			
			if (IsClientInGame(choose) && !IsClientBot(choose))
			{
				decl String:names[MAX_NAME_LENGTH+1];
				
				GetClientName(choose, names, sizeof(names));
				
				playerpoints[choose] = pointstoset;
				
				PrintToChat(client, "%c[ Stamm ] %T", GREEN, "SetPoints", LANG_SERVER, LIGHTGREEN, GREEN, names, LIGHTGREEN, pointstoset);
				PrintToChat(choose, "%c[ Stamm ] %T", GREEN, "SetPoints2", LANG_SERVER, LIGHTGREEN, GREEN, pointstoset);
				
				CheckVip(choose);
			}
			
			pointsnumber[client] = 0;
			
			return Plugin_Handled;
		}
		else if (StrEqual(text, admin_menu))
		{	
			if (IsAdmin(client))
			{
				SendPanelToClient(adminpanel, client, AdminHandler, 30);
				
				return Plugin_Handled;
			}
		}
		else if (StrEqual(text, model_change_cmd))
		{	
			if (IsClientInGame(client) && model_change && PlayerHasModel[client])
			{
				PlayerHasModel[client] = 0;
				PlayerModel[client] = "";
				
				PrintToChat(client, "%c[ Stamm ] %T", GREEN, "NewModel", LANG_SERVER, LIGHTGREEN, GREEN, LIGHTGREEN);
				
				return Plugin_Handled;
			}
		}
		else
		{
			if (autochat && WantChat[client])
			{
				if (!stamm_level)
				{
					if (playervip[client])
					{
						new index = FindCharInString(text, '*');
						
						if (index == 0)
						{
							ReplaceString(text, sizeof(text), "*", "");

							if (GetClientTeam(client) == 2) CPrintToChatAll("{red}[%s] {green}%s{default}:{red} %s", MessageTag, name, text);
							if (GetClientTeam(client) == 3) CPrintToChatAll("{blue}[%s] {green}%s{default}:{blue} %s", MessageTag, name, text);
							
							return Plugin_Handled;
						}
					}
				}
				else
				{
					if (playerchat[client])
					{
						new index = FindCharInString(text, '*');

						if (index == 0)
						{
							ReplaceString(text, sizeof(text), "*", "");
							
							if (GetClientTeam(client) == 2) CPrintToChatAll("{red}[%s] {green}%s{default}:{red} %s", MessageTag, name, text);
							if (GetClientTeam(client) == 3) CPrintToChatAll("{blue}[%s] {green}%s{default}:{blue} %s", MessageTag, name, text);
							
							return Plugin_Handled;
						}
					}
				}
			}
			if (own_chat && WantVipChat[client])
			{
				if (!stamm_level)
				{
					if (playervip[client])
					{
						new index = FindCharInString(text, '#');

						if (index == 0)
						{
							ReplaceString(text, sizeof(text), "#", "");
							
							if (GetClientTeam(client) == 2) CPrintToChatAll("{red}[%s] {green}%s{default}:{red} %s", OwnChatTag, name, text);
							if (GetClientTeam(client) == 3) CPrintToChatAll("{blue}[%s] {green}%s{default}:{blue} %s", OwnChatTag, name, text);
							
							return Plugin_Handled;
						}
					}
				}
				else
				{
					if (playervipchat[client])
					{
						new index = FindCharInString(text, '#');

						if (index == 0)
						{
							ReplaceString(text, sizeof(text), "#", "");
							
							if (GetClientTeam(client) == 2) CPrintToChatAll("{red}[%s] {green}%s{default}:{red} %s", OwnChatTag, name, text);
							if (GetClientTeam(client) == 3) CPrintToChatAll("{blue}[%s] {green}%s{default}:{blue} %s", OwnChatTag, name, text);
							
							return Plugin_Handled;
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}	

/* Panel/Menu Handler */

public ChangePanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		decl String:ChangeChoose[16];
		
		GetMenuItem(menu, param2, ChangeChoose, sizeof(ChangeChoose));
		
		if (StrEqual(ChangeChoose, "dTag")) WantTag[param1] = 0;
		if (StrEqual(ChangeChoose, "eTag")) WantTag[param1] = 1;
		if (StrEqual(ChangeChoose, "dJoin")) WantJoin[param1] = 0;
		if (StrEqual(ChangeChoose, "eJoin")) WantJoin[param1] = 1;
		if (StrEqual(ChangeChoose, "dHoly")) WantHoly[param1] = 0;
		if (StrEqual(ChangeChoose, "eHoly")) WantHoly[param1] = 1;
		if (StrEqual(ChangeChoose, "dVipChat")) WantVipChat[param1] = 0;
		if (StrEqual(ChangeChoose, "eVipChat")) WantVipChat[param1] = 1;
		if (StrEqual(ChangeChoose, "dChat")) WantChat[param1] = 0;
		if (StrEqual(ChangeChoose, "eChat")) WantChat[param1] = 1;
		
		
		if (!StrEqual(ChangeChoose, "close")) FakeClientCommand(param1, "say !schange");
	}
}

public ResetHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if (param2 == 1)
		{
			decl String:DelDatabase[64];
			
			Format(DelDatabase, sizeof(DelDatabase), "DELETE FROM %s", tablename);
			
			SQL_TQuery(db, DeleteDatabaseHandler, DelDatabase);
		}
	}
}

public ModelMenuCall(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		decl String:ModelChoose[128];
		
		GetMenuItem(ModelMenu, param2, ModelChoose, sizeof(ModelChoose));
		
		if (!StrEqual(ModelChoose, "standard"))
		{
			SetEntityModel(param1, ModelChoose);
			PlayerHasModel[param1] = 1;
			PlayerModel[param1] = ModelChoose;
		}
		if (StrEqual(ModelChoose, "standard")) PlayerHasModel[param1] = 1;
		
	}
}

public PanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if (param2 == 6) SendPanelToClient(info, param1, InfoHandler, 20);
	}
}

public PassPanelHandler(Handle:menu, MenuAction:action, param1, param2) {}

public PlayerListHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select) 
	{
		decl String:menuinfo[32];
		
		GetMenuItem(menu, param2, menuinfo, sizeof(menuinfo));
		
		new client = StringToInt(menuinfo);
		
		pointsnumber[param1] = client;
		
		PrintToChat(param1, "%c[ Stamm ] %T", GREEN, "WritePoints", LANG_SERVER, LIGHTGREEN, GREEN);
		PrintToChat(param1, "%c[ Stamm ] %T", GREEN, "WritePointsInfo", LANG_SERVER, LIGHTGREEN, GREEN, LIGHTGREEN);
	}
}

public PlayerListHandlerDelete(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select) 
	{
		decl String:query[256];
		decl String:menuinfo[32];
		decl String:name[MAX_NAME_LENGTH+1];
		decl String:steamid[64];
	
		GetMenuItem(menu, param2, menuinfo, sizeof(menuinfo));
		
		new client = StringToInt(menuinfo);
		
		GetClientName(client, name, sizeof(name));
		GetClientAuthString(client, steamid, sizeof(steamid));
		
		
		PrintToChat(param1, "%c[ Stamm ] %T", GREEN, "DeletedPoints", LANG_SERVER, LIGHTGREEN, GREEN, name);
		PrintToChat(client, "%c[ Stamm ] %T", GREEN, "YourDeletedPoints", LANG_SERVER,LIGHTGREEN, GREEN);
		PrintToChat(client, "%c[ Stamm ] %T", GREEN, "YourDeletedPoints", LANG_SERVER,LIGHTGREEN, GREEN);
		PrintToChat(client, "%c[ Stamm ] %T", GREEN, "YourDeletedPoints", LANG_SERVER,LIGHTGREEN, GREEN);
		
		playervip[client] = 0;
		playertag[client] = 0;
		playermoney[client] = 0;
		playerchat[client] = 0;
		playervipchat[client] = 0;
		playerjoinsound[client] = 0;
		playerwelcome[client] = 0;
		playerdisconnect[client] = 0;
		playermodel[client] = 0;
		playerslot[client] = 0;
		playerholy[client] = 0;
		playerpoints[client] = 0;
		playerlevel[client] = 0;
				
		Format(query, sizeof(query), "UPDATE %s SET VIP=0,level=0,rounds=0,kills=0,time=0,tag=0,money=0,chat=0,vipchat=0,joinsound=0,welcome=0,disconnect=0,model=0,slot=0,holy=0 WHERE steamid='%s'", tablename, steamid);
		
		if (SQL_Query(db, query) == INVALID_HANDLE && stammdebug) {SQL_GetError(db, SQLError, sizeof(SQLError));LogToFile(DebugFile, "[ STAMM ] Error on Executing Command on Line 1169: %s", SQLError);}
	}
}

public FeatureHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		decl String:choose[32];
		
		GetMenuItem(menu, param2, choose, sizeof(choose));
		
		if (!strcmp(choose, "back", false)) SendPanelToClient(info, param1, InfoHandler, 20);
	}
}

public CmdlistHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if (param2 == 1) FakeClientCommandEx(param1, "say %s", texttowrite);
		if (param2 == 2) FakeClientCommandEx(param1, "say %s", viplist);
		if (param2 == 3) FakeClientCommandEx(param1, "say %s", viprank);
		if (param2 == 4 && !allow_change && model_change) FakeClientCommandEx(param1, "say %s", model_change_cmd);
		if (param2 == 4 && allow_change && !model_change) FakeClientCommandEx(param1, "say !schange");
		if (param2 == 4 && allow_change && model_change) FakeClientCommandEx(param1, "say %s", model_change_cmd);
		if (param2 == 4 && !allow_change && !model_change) SendPanelToClient(info, param1, InfoHandler, 20);
		if (param2 == 5 && (!allow_change || !model_change) || (!allow_change && !model_change)) SendPanelToClient(info, param1, InfoHandler, 20);
		if (param2 == 5 && allow_change && model_change) FakeClientCommandEx(param1, "say !schange");
		if (param2 == 6 && allow_change && model_change) SendPanelToClient(info, param1, InfoHandler, 20);
	}
}

public InfoHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if (param2 == 3) SendPanelToClient(credits, param1, PanelHandler, 20);
		if (param2 == 2) SendPanelToClient(cmdlist, param1, CmdlistHandler, 20);
		if (param2 == 1) DisplayMenu(featurelist, param1, 20);
		
	}
}

public AdminHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		decl String:Chooseit[128];
		
		Format(Chooseit, sizeof(Chooseit), "%T", "ChoosePlayer", LANG_SERVER);
		
		if (param2 == 1)
		{	
			new Handle:playerlist = CreateMenu(PlayerListHandler);
			
			SetMenuTitle(playerlist, Chooseit);
			
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && !IsClientBot(i))
				{
					decl String:clientname[MAX_NAME_LENGTH+1];
					decl String:clientString[MAXPLAYERS + 1];
					
					Format(clientString, MaxClients + 1, "%i", i);
					
					GetClientName(i, clientname, sizeof(clientname));
					
					AddMenuItem(playerlist, clientString, clientname);
				}
			}
			DisplayMenu(playerlist, param1, 30);
		}
		if (param2 == 2)
		{	
			new Handle:playerlist = CreateMenu(PlayerListHandlerDelete);
			
			SetMenuTitle(playerlist, Chooseit);
			
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && !IsClientBot(i))
				{
					decl String:clientname[MAX_NAME_LENGTH+1];
					decl String:clientString[MAXPLAYERS + 1];
					
					Format(clientString, MaxClients + 1, "%i", i);
					
					GetClientName(i, clientname, sizeof(clientname));
					
					AddMenuItem(playerlist, clientString, clientname);
				}
			}
			DisplayMenu(playerlist, param1, 30);
		}
		if (param2 == 3) SendPanelToClient(resetpanel, param1, ResetHandler, 30);
		if (param2 == 4)
		{	
			if (!happyhouron) MakeHappyHour(param1);
			if (happyhouron) PrintToChat(param1, "%c[ Stamm ] %T", GREEN, "HappyRunning", LANG_SERVER, LIGHTGREEN, GREEN);
		}
		if (param2 == 5) CheckForUpdate(param1);
		
	}
}

/* Socket Handler */

public OnSocketConnected(Handle:socket, any:arg) 
{
	decl String:requestStr[100];
	
	Format(requestStr, sizeof(requestStr), "GET /%s HTTP/1.0\r\nHost: %s\r\nConnection: close\r\n\r\n", "stamm_update_sm.php", "www.pup-board.de");
	
	SocketSend(socket, requestStr);
}

public OnSocketReceive(Handle:socket, String:receiveData[], const dataSize, any:client)
{
	if (IsClientConnected(client))
	{
		decl String:thecontent[512];
		decl String:thenew[512];
		
		strcopy(thecontent, sizeof(thecontent), receiveData);
		
		SplitString(thecontent, "\r\n\r\n", thenew, sizeof(thenew));
		ReplaceString(thecontent, sizeof(thecontent), thenew, "");
		ReplaceString(thecontent, sizeof(thecontent), "\n", "");
		ReplaceString(thecontent, sizeof(thecontent), "\r", "");
		ReplaceString(thecontent, sizeof(thecontent), "\t", "");
		ReplaceString(thecontent, sizeof(thecontent), " ", "");
		
		new Float:newversion = StringToFloat(thecontent);
		new Float:oldversion = StringToFloat(Plugin_Version);
		
		if (newversion > oldversion)
		{
			for (new i=0; i < 20; i++) PrintToChat(client, "%cDownload %cNEW STAMM %cV %s %cat %chttp://forums.alliedmods.net/showthread.php?t=142073", LIGHTGREEN, GREEN, LIGHTGREEN, thecontent, GREEN, LIGHTGREEN);
			
			PrintCenterText(client, "Download NEW STAMM V %s at http://forums.alliedmods.net/showthread.php?t=142073", thecontent);
			PrintHintText(client, "Download NEW STAMM V %s at http://forums.alliedmods.net/showthread.php?t=142073", thecontent);
		}
		else PrintToChat(client, "%c[ Stamm ]%c Stamm is %cUp to Date", GREEN, LIGHTGREEN, GREEN);
		
	}
}

public OnSocketDisconnected(Handle:socket, any:client) CloseHandle(socket);


public OnSocketError(Handle:socket, const errorType, const errorNum, any:client)
{
	if (stammdebug) LogToFile(LogFile, "[ Stamm ] Socket error %d (errno %d)", errorType, errorNum);
	
	CloseHandle(socket);
}

/* Database Blocks */

public LoadDB(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		PrintToServer("[ STAMM ] Stamm couldn't connect to the Database!! Error: %s", error);
		LogToFile(LogFile, "[ STAMM ] Stamm couldn't connect to the Database!! Error: %s", error);
		db = INVALID_HANDLE;
		return;
	} 
	else 
	{	
		if (stammdebug)
		{
			PrintToServer("[ STAMM ] Connect to Database");
			LogToFile(LogFile, "[ STAMM ] Connected to Database");
		}
	}

	db = hndl;
	decl String:query2[1024];
	
	Format(query2, sizeof(query2), "CREATE TABLE IF NOT EXISTS %s (steamid VARCHAR( 20 ) NOT NULL DEFAULT '', VIP INT( 1 ) NOT NULL DEFAULT 0, level INT(1) NOT NULL DEFAULT 0, rounds INT( 255 ) NOT NULL DEFAULT 0, kills INT( 255 ) NOT NULL DEFAULT 0, time INT( 255 ) NOT NULL DEFAULT 0, name VARCHAR( 255 ) NOT NULL DEFAULT '', tag INT(1) NOT NULL DEFAULT 0, money INT(1) NOT NULL DEFAULT 0, chat INT(1) NOT NULL DEFAULT 0, vipchat INT(1) NOT NULL DEFAULT 0, joinsound INT(1) NOT NULL DEFAULT 0, welcome INT(1) NOT NULL DEFAULT 0, disconnect INT(1) NOT NULL DEFAULT 0, model INT(1) NOT NULL DEFAULT 0, slot INT(1) NOT NULL DEFAULT 0, holy INT(1) NOT NULL DEFAULT 0, wanttag INT(1) NOT NULL DEFAULT 1, wantholy INT(1) NOT NULL DEFAULT 1, wantjoin INT(1) NOT NULL DEFAULT 1, wantvipchat INT(1) NOT NULL DEFAULT 1, wantchat INT(1) NOT NULL DEFAULT 1, PRIMARY KEY (steamid))", tablename);
	
	if (SQL_Query(db, query2) == INVALID_HANDLE && stammdebug) {SQL_GetError(db, SQLError, sizeof(SQLError));LogToFile(DebugFile, "[ STAMM ] Error on Executing Command on Line 1353: %s", SQLError);}
}

public DeleteDatabaseHandler(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(!CheckCon(hndl, "Create Database after deleting it", error, 1358)) return;
	
	decl String:CreateDatabase[1024];
	
	Format(CreateDatabase, sizeof(CreateDatabase), "CREATE TABLE IF NOT EXISTS %s (steamid VARCHAR( 20 ) NOT NULL DEFAULT '', VIP INT( 1 ) NOT NULL DEFAULT 0, level INT(1) NOT NULL DEFAULT 0, rounds INT( 255 ) NOT NULL DEFAULT 0, kills INT( 255 ) NOT NULL DEFAULT 0, time INT( 255 ) NOT NULL DEFAULT 0, name VARCHAR( 255 ) NOT NULL DEFAULT '', tag INT(1) NOT NULL DEFAULT 0, money INT(1) NOT NULL DEFAULT 0, chat INT(1) NOT NULL DEFAULT 0, vipchat INT(1) NOT NULL DEFAULT 0, joinsound INT(1) NOT NULL DEFAULT 0, welcome INT(1) NOT NULL DEFAULT 0, disconnect INT(1) NOT NULL DEFAULT 0, model INT(1) NOT NULL DEFAULT 0, slot INT(1) NOT NULL DEFAULT 0, holy INT(1) NOT NULL DEFAULT 0, wanttag INT(1) NOT NULL DEFAULT 1, wantholy INT(1) NOT NULL DEFAULT 1, wantjoin INT(1) NOT NULL DEFAULT 1, wantvipchat INT(1) NOT NULL DEFAULT 1, wantchat INT(1) NOT NULL DEFAULT 1, PRIMARY KEY (steamid))", tablename);
	
	if (SQL_Query(db, CreateDatabase) == INVALID_HANDLE && stammdebug) {SQL_GetError(db, SQLError, sizeof(SQLError));LogToFile(DebugFile, "[ STAMM ] Error on Executing Command on Line 1364: %s", SQLError);}
	
	for(new i=1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsClientBot(i))
		{
			new client = i;
			
			playervip[client] = 0;
			playertag[client] = 0;
			playermoney[client] = 0;
			playerchat[client] = 0;
			playervipchat[client] = 0;
			playerjoinsound[client] = 0;
			playerwelcome[client] = 0;
			playerdisconnect[client] = 0;
			playermodel[client] = 0;
			playerslot[client] = 0;
			playerholy[client] = 0;
			playerpoints[client] = 0;
			playerlevel[client] = 0;
		
		}
	}
	
	PrintToChatAll("%c[ Stamm ] %T", GREEN, "DeletedDB", LANG_SERVER, LIGHTGREEN, GREEN);
}

public InsertThePlayer(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	decl String:name[MAX_NAME_LENGTH+1];
	decl String:name2[2 * MAX_NAME_LENGTH+2];

	decl String:steamid[64];
	decl String:infotext[128];
	
	if ( !client || !IsClientConnected(client)) return;
	
	GetClientAuthString(client, steamid, sizeof(steamid));
	GetClientName(client, name, sizeof(name));
	
	Format(infotext, sizeof(infotext), "Insert Player / Get Player Infos (%s)", steamid);
	
	if(!CheckCon(hndl, infotext, error, 1407)) return;
	
	SQL_EscapeString(db, name, name2, sizeof(name2));

	if(!SQL_FetchRow(hndl))
	{
		decl String:query2[256];
		
		Format(query2, sizeof(query2), "INSERT INTO %s (steamid, name) VALUES ('%s', '%s')", tablename, steamid, name2);
		
		SQL_TQuery(db, SQLErrorCheckCallback, query2, 1417);
		
		playervip[client] = 0;
		playertag[client] = 0;
		playermoney[client] = 0;
		playerchat[client] = 0;
		playervipchat[client] = 0;
		playerjoinsound[client] = 0;
		playerwelcome[client] = 0;
		playerdisconnect[client] = 0;
		playermodel[client] = 0;
		playerslot[client] = 0;
		playerholy[client] = 0;
		playerpoints[client] = 0;
		playerlevel[client] = 0;
		WantTag[client] = 1;
		WantHoly[client] = 1;
		WantJoin[client] = 1;
		WantVipChat[client] = 1;
		WantChat[client] = 1;
	}
	else
	{
		playervip[client] = SQL_FetchInt(hndl, 0);
		playertag[client] = SQL_FetchInt(hndl, 1);
		playermoney[client] = SQL_FetchInt(hndl, 2);
		playerchat[client] = SQL_FetchInt(hndl, 3);
		playervipchat[client] = SQL_FetchInt(hndl, 4);
		playerjoinsound[client] = SQL_FetchInt(hndl, 5);
		playerwelcome[client] = SQL_FetchInt(hndl, 6);
		playerdisconnect[client] = SQL_FetchInt(hndl, 7);
		playermodel[client] = SQL_FetchInt(hndl, 8);
		playerslot[client] = SQL_FetchInt(hndl, 9);
		playerholy[client] = SQL_FetchInt(hndl, 10);
		playerlevel[client] = SQL_FetchInt(hndl, 14);
		WantTag[client] = SQL_FetchInt(hndl, 15);
		WantHoly[client] = SQL_FetchInt(hndl, 16);
		WantJoin[client] = SQL_FetchInt(hndl, 17);
		WantVipChat[client] = SQL_FetchInt(hndl, 18);
		WantChat[client] = SQL_FetchInt(hndl, 19);
		
		if (StrEqual(vip_type, "kills")) playerpoints[client] = SQL_FetchInt(hndl, 13);
		if (StrEqual(vip_type, "time")) playerpoints[client] = SQL_FetchInt(hndl, 12);
		if (StrEqual(vip_type, "rounds")) playerpoints[client] = SQL_FetchInt(hndl, 11);
		
		decl String:setname[256];
		
		Format(setname, sizeof(setname), "UPDATE %s SET name='%s' WHERE steamid='%s'", tablename, name2, steamid);
		
		if (SQL_Query(db, setname) == INVALID_HANDLE && stammdebug) {SQL_GetError(db, SQLError, sizeof(SQLError));LogToFile(DebugFile, "[ STAMM ] Error on Executing Command on Line 1466: %s", SQLError);}
	}
	if (!allow_change)
	{
		WantTag[client] = 1;
		WantHoly[client] = 1;
		WantJoin[client] = 1;
		WantVipChat[client] = 1;
		WantChat[client] = 1;
	}
	
	PlayerHasModel[client] = 0;
	pointsnumber[client] = 0;
	happynumber[client] = 0;
	happyfactor[client] = 0;
	
	if (enable_vip_slot) VipSlotCheck(client);	
	
	ClientReady[client] = true;
	
	if (stammdebug)
	{
		LogToFile(LogFile, "[ STAMM ] Player is Ready: \"%s\"", steamid);
		PrintToServer("[ STAMM ] Player is Ready: \"%s\"", steamid);
	}
	
	DoRestOfInsert(client);
}


public GetVIPTopQuery(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	new Handle:Top10Menu = CreatePanel();
	new IsAVip;
	decl String:top_text[128];
	decl String:steamid[64];
	decl String:infotext[128];
	
	GetClientAuthString(client, steamid, sizeof(steamid));
	
	Format(infotext, sizeof(infotext), "Generate Player Top (%s)", steamid);
	
	if(!CheckCon(hndl, infotext, error, 1508)) return;
	
	
	SetPanelTitle(Top10Menu, "TOP VIP's");
	
	while (SQL_FetchRow(hndl))
	{
		decl String:name[MAX_NAME_LENGTH+1];
		SQL_FetchString(hndl, 0, name, sizeof(name));
		
		IsAVip = 1;
		new top_points = SQL_FetchInt(hndl, 1);
		
		if (StrEqual(vip_type, "kills")) Format(top_text, sizeof(top_text), "%s (%i %T)", name, top_points, "Kills", LANG_SERVER);
		if (StrEqual(vip_type, "rounds")) Format(top_text, sizeof(top_text), "%s (%i %T)", name, top_points, "Rounds", LANG_SERVER);
		if (StrEqual(vip_type, "time")) 
		{
			new hours = top_points / 60;
			new minutes = top_points - (hours * 60);
			Format(top_text, sizeof(top_text), "%s (%T)", name, "RankTime2", LANG_SERVER, hours, minutes);
		}
		
		DrawPanelItem(Top10Menu, top_text);
	}
	
	if (!IsAVip)
	{
		PrintToChat(client, "%c[ Stamm ] %T", GREEN, "NoVips", LANG_SERVER, LIGHTGREEN, GREEN);
		return;
	}
	
	SendPanelToClient(Top10Menu, client, PassPanelHandler, 30);
	
}

public GetVIPRankQuery(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	decl String:steamid[64];
	decl String:infotext[128];
	
	new counter = 0;
	new end = 0;
	
	GetClientAuthString(client, steamid, sizeof(steamid));
	
	Format(infotext, sizeof(infotext), "Generate Player Rank (%s)", steamid);
	
	if(!CheckCon(hndl, infotext, error, 1555)) return;
	
	
	while (SQL_FetchRow(hndl))
	{
		counter++;
		
		decl String:steamid_query[64];
		new top_points = SQL_FetchInt(hndl, 0);
		
		SQL_FetchString(hndl, 1, steamid_query, sizeof(steamid_query));
		
		if ( StrEqual(steamid_query, steamid))
		{
			if (StrEqual(vip_type, "kills")) PrintToChat(client, "%c[ Stamm ] %T", GREEN, "RankKills", LANG_SERVER, LIGHTGREEN, GREEN, counter, LIGHTGREEN, GREEN, top_points);
			if (StrEqual(vip_type, "rounds")) PrintToChat(client, "%c[ Stamm ] %T", GREEN, "RankRounds", LANG_SERVER, LIGHTGREEN, GREEN, counter, LIGHTGREEN, GREEN, top_points);
			
			if (StrEqual(vip_type, "time"))
			{
				new hours = top_points / 60;
				new minutes = top_points - (hours * 60);
				
				PrintToChat(client, "%c[ Stamm ] %T", GREEN, "RankTime", LANG_SERVER, LIGHTGREEN, GREEN, counter, LIGHTGREEN, GREEN, hours, LIGHTGREEN, GREEN, minutes);
			}
			
			end = 1;
			break;
		}
	}
	
	if (end) return;
	
	PrintToChat(client, "%c[ Stamm ] %T", GREEN, "NoVIP", LANG_SERVER, LIGHTGREEN, GREEN);
}

public SQLErrorCheckCallback(Handle:owner, Handle:hndl, const String:error[], any:line)
{
	if(!StrEqual("", error) && stammdebug)
	{
		LogToFile(LogFile, "[ STAMM ] Database Error at line %i:   %s", line, error);
		PrintToServer("[ STAMM ] Database Error at line %i:   %s", line, error);
	}
}

/* ConVar Changes */

public stammdebug_change(Handle:cvar, const String:oldVal[], const String:newVal[])
{ 
	stammdebug = StringToInt(newVal); 
}

public giveflagadmin_change(Handle:cvar, const String:oldVal[], const String:newVal[])
{ 
	giveflagadmin = StringToInt(newVal); 
}

public bot_kill_counter_change(Handle:cvar, const String:oldVal[], const String:newVal[])
{ 
	bot_kill_counter = StringToInt(newVal); 
}

public min_player_change(Handle:cvar, const String:oldVal[], const String:newVal[])
{ 
	min_player = StringToInt(newVal); 
}

public enable_filter_change(Handle:cvar, const String:oldVal[], const String:newVal[])
{ 
	enable_filter = StringToInt(newVal); 
}

public enable_models_change(Handle:cvar, const String:oldVal[], const String:newVal[])
{ 
	enable_models = StringToInt(newVal); 
}

public autochat_change(Handle:cvar, const String:oldVal[], const String:newVal[])
{ 
	autochat = StringToInt(newVal); 
}

public own_chat_change(Handle:cvar, const String:oldVal[], const String:newVal[])
{ 
	own_chat = StringToInt(newVal); 
}

public viplistmin_change(Handle:cvar, const String:oldVal[], const String:newVal[])
{ 
	viplistmin = StringToInt(newVal); 
}

public vipcash_change(Handle:cvar, const String:oldVal[], const String:newVal[])
{ 
	vipcash = StringToInt(newVal); 
}

public model_change_change(Handle:cvar, const String:oldVal[], const String:newVal[])
{ 
	model_change = StringToInt(newVal); 
}

public enable_holy_grenade_change(Handle:cvar, const String:oldVal[], const String:newVal[])
{ 
	enable_holy_grenade = StringToInt(newVal); 
}

public hear_holy_grenade_change(Handle:cvar, const String:oldVal[], const String:newVal[])
{ 
	hear_holy_grenade = StringToInt(newVal); 
}

public enable_vip_slot_change(Handle:cvar, const String:oldVal[], const String:newVal[])
{ 
	enable_vip_slot = StringToInt(newVal); 
}

public let_free_change(Handle:cvar, const String:oldVal[], const String:newVal[])
{ 
	let_free = StringToInt(newVal); 
}

public stamm_tag_on_off_change(Handle:cvar, const String:oldVal[], const String:newVal[])
{ 
	stamm_tag_on_off = StringToInt(newVal); 
}

public stammtagkick_change(Handle:cvar, const String:oldVal[], const String:newVal[])
{ 
	stammtagkick = StringToInt(newVal); 
}

public see_text_change(Handle:cvar, const String:oldVal[], const String:newVal[])
{ 
	see_text = StringToInt(newVal); 
}

public join_show_change(Handle:cvar, const String:oldVal[], const String:newVal[])
{ 
	join_show = StringToInt(newVal); 
}

public vip_chatwelcome_change(Handle:cvar, const String:oldVal[], const String:newVal[])
{ 
	vip_chatwelcome = StringToInt(newVal); 
}

public vip_chatgoodbye_change(Handle:cvar, const String:oldVal[], const String:newVal[])
{ 
	vip_chatgoodbye = StringToInt(newVal); 
}

public updateaddon_change(Handle:cvar, const String:oldVal[], const String:newVal[])
{ 
	updateaddon = StringToInt(newVal); 
}

public lvl_up_sound_change(Handle:cvar, const String:oldVal[], const String:newVal[])
{ 
	Format(lvl_up_sound, sizeof(lvl_up_sound), newVal);
}

public MessageTag_change(Handle:cvar, const String:oldVal[], const String:newVal[])
{ 
	Format(MessageTag, sizeof(MessageTag), newVal);
}

public OwnChatTag_change(Handle:cvar, const String:oldVal[], const String:newVal[])
{ 
	Format(OwnChatTag, sizeof(OwnChatTag), newVal);
}

public vip_kick_message_change(Handle:cvar, const String:oldVal[], const String:newVal[])
{ 
	Format(vip_kick_message, sizeof(vip_kick_message), newVal);
}

public vip_kick_message2_change(Handle:cvar, const String:oldVal[], const String:newVal[])
{ 
	Format(vip_kick_message2, sizeof(vip_kick_message2), newVal);
}

public vip_joinsound_change(Handle:cvar, const String:oldVal[], const String:newVal[])
{ 
	Format(vip_joinsound, sizeof(vip_joinsound), newVal);
}

/* Own Blocks */

public DoRestOfInsert(client)
{
	if (IsClientConnected(client))
	{
		decl String:name[MAX_NAME_LENGTH + 1];
		
		GetClientName(client, name, sizeof(name));
		
		if (stamm_tag_on_off) NameCheck(client);	
		if (enable_filter) CheckDLFilter(client);
	}
}

CheckFlagAdmin(client)
{
	new AdminId:adminid = GetUserAdmin(client);
	
	if (!IsClientBot(client))
	{
		if (giveflagadmin == 1)
		{
			if (GetAdminFlag(adminid, Admin_Custom1)) GiveFastVIP(client);
		}
		if (giveflagadmin == 2)
		{
			if (GetAdminFlag(adminid, Admin_Custom2)) GiveFastVIP(client);
		}
		if (giveflagadmin == 3)
		{
			if (GetAdminFlag(adminid, Admin_Custom3)) GiveFastVIP(client);
		}
		if (giveflagadmin == 4)
		{
			if (GetAdminFlag(adminid, Admin_Custom4)) GiveFastVIP(client);
		}
		if (giveflagadmin == 5)
		{
			if (GetAdminFlag(adminid, Admin_Custom5)) GiveFastVIP(client);
		}
		if (giveflagadmin == 6)
		{
			if (GetAdminFlag(adminid, Admin_Custom6)) GiveFastVIP(client);
		}
	}
}

GiveFastVIP(client)
{
	if (!stamm_level && !playervip[client]) 
	{
		playerpoints[client] = points_to_become_vip;
		CheckVip(client);
	}
	if (stamm_level && playerlevel[client] <= 3)
	{
		playerpoints[client] = stamm_platinum;
		CheckVip(client);
	}
}

public CheckForUpdate(client)
{
	if (IsAdmin(client))
	{
		new Handle:socket = SocketCreate(SOCKET_TCP, OnSocketError);
		SocketSetArg(socket, client);
		SocketConnect(socket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, "www.pup-board.de", 80);
	}
}

ShowPlayerPoints(client)
{
	if (IsClientInGame(client))
	{
		decl String:name[MAX_NAME_LENGTH+1];
		decl String:type[64];
		
		if (StrEqual(vip_type, "kills")) Format(type, sizeof(type), "%T", "Kills", LANG_SERVER);
		if (StrEqual(vip_type, "rounds")) Format(type, sizeof(type), "%T", "Rounds", LANG_SERVER);
		
		GetClientName(client, name, sizeof(name));
		
		if (!stamm_level)
		{
			if (StrEqual(vip_type, "kills") || StrEqual(vip_type, "rounds"))
			{
				if (!see_text)
				{
					if (!playervip[client]) PrintToChat(client, "%c[ Stamm ] %T", GREEN, "NoLevelNoVIPClient", LANG_SERVER, LIGHTGREEN, GREEN, playerpoints[client], LIGHTGREEN, type, GREEN, LIGHTGREEN, (points_to_become_vip - playerpoints[client]), points_to_become_vip, GREEN);
					if (playervip[client]) PrintToChat(client, "%c[ Stamm ] %T", GREEN, "NoLevelVIPClient",LANG_SERVER,  LIGHTGREEN, GREEN, playerpoints[client], LIGHTGREEN, type, GREEN);
				}
				else
				{
					if (!playervip[client]) PrintToChatAll("%c[ Stamm ] %T", GREEN, "NoLevelNoVIPAll", LANG_SERVER, LIGHTGREEN, name, GREEN, playerpoints[client], LIGHTGREEN, type, GREEN, LIGHTGREEN, (points_to_become_vip - playerpoints[client]), points_to_become_vip, GREEN);
					if (playervip[client]) PrintToChatAll("%c[ Stamm ] %T", GREEN, "NoLevelVIPAll", LANG_SERVER, LIGHTGREEN, name, GREEN, playerpoints[client], LIGHTGREEN, type, GREEN);
				}
			}
			if (StrEqual(vip_type, "time"))
			{
				new hours = playerpoints[client] / 60;
				new minutes = playerpoints[client] - (hours * 60);
				new resttime = points_to_become_vip - playerpoints[client];
				
				if (!see_text)
				{
					if (!playervip[client]) PrintToChat(client, "%c[ Stamm ] %T", GREEN, "NoLevelNoVIPClientTime", LANG_SERVER, LIGHTGREEN, GREEN, hours, LIGHTGREEN, GREEN, minutes, LIGHTGREEN, GREEN, resttime, points_to_become_vip, LIGHTGREEN);
					if (playervip[client]) PrintToChat(client, "%c[ Stamm ] %T", GREEN, "NoLevelVIPClientTime", LANG_SERVER, LIGHTGREEN, GREEN, hours, LIGHTGREEN, GREEN, minutes, LIGHTGREEN);
				}
				else
				{
					if (!playervip[client]) PrintToChatAll("%c[ Stamm ] %T", GREEN, "NoLevelNoVIPAllTime", LANG_SERVER, LIGHTGREEN, name, GREEN, hours, LIGHTGREEN, GREEN, minutes, LIGHTGREEN, GREEN, resttime, points_to_become_vip, LIGHTGREEN);
					if (playervip[client]) PrintToChatAll("%c[ Stamm ] %T", GREEN, "NoLevelVIPAllTime", LANG_SERVER, LIGHTGREEN, name, GREEN, hours, LIGHTGREEN, GREEN, minutes, LIGHTGREEN);
				}
			}
		}
		else
		{		
			if (StrEqual(vip_type, "kills") || StrEqual(vip_type, "rounds"))
			{
				if (!see_text)
				{
					if (!playerlevel[client]) PrintToChat(client, "%c[ Stamm ] %T", GREEN, "LevelNoVIPClientBronze", LANG_SERVER, LIGHTGREEN, GREEN, playerpoints[client], LIGHTGREEN, type, GREEN, LIGHTGREEN, (stamm_bronze - playerpoints[client]), stamm_bronze, GREEN);
					if (playerlevel[client] == 1) PrintToChat(client, "%c[ Stamm ] %T", GREEN, "LevelNoVIPClientSilver", LANG_SERVER, LIGHTGREEN, GREEN, playerpoints[client], LIGHTGREEN, type, GREEN, LIGHTGREEN, (stamm_silver - playerpoints[client]), stamm_silver, GREEN);		
					if (playerlevel[client] == 2) PrintToChat(client, "%c[ Stamm ] %T", GREEN, "LevelNoVIPClientGold", LANG_SERVER, LIGHTGREEN, GREEN, playerpoints[client], LIGHTGREEN, type, GREEN, LIGHTGREEN, (stamm_gold - playerpoints[client]), stamm_gold, GREEN);
					if (playerlevel[client] == 3) PrintToChat(client, "%c[ Stamm ] %T", GREEN, "LevelNoVIPClientPlatinum",LANG_SERVER, LIGHTGREEN, GREEN, playerpoints[client], LIGHTGREEN, type, GREEN, LIGHTGREEN, (stamm_platinum - playerpoints[client]), stamm_platinum, GREEN);
					if (playerlevel[client] == 4) PrintToChat(client, "%c[ Stamm ] %T", GREEN, "LevelVIPClient", LANG_SERVER, LIGHTGREEN, GREEN, playerpoints[client], LIGHTGREEN, type, GREEN);
				}
				else
				{
					if (!playerlevel[client]) PrintToChatAll("%c[ Stamm ] %T", GREEN, "LevelNoVIPAllBronze", LANG_SERVER, LIGHTGREEN, name, GREEN, playerpoints[client], LIGHTGREEN, type, GREEN, LIGHTGREEN, (stamm_bronze - playerpoints[client]), stamm_bronze, GREEN);
					if (playerlevel[client] == 1) PrintToChatAll("%c[ Stamm ] %T", GREEN, "LevelNoVIPAllSilver", LANG_SERVER, LIGHTGREEN, name, GREEN, playerpoints[client], LIGHTGREEN, type, GREEN, LIGHTGREEN, (stamm_silver - playerpoints[client]), stamm_silver, GREEN);			
					if (playerlevel[client] == 2) PrintToChatAll("%c[ Stamm ] %T", GREEN, "LevelNoVIPAllGold", LANG_SERVER, LIGHTGREEN, name, GREEN, playerpoints[client], LIGHTGREEN, type, GREEN, LIGHTGREEN, (stamm_gold - playerpoints[client]), stamm_gold, GREEN);
					if (playerlevel[client] == 3) PrintToChatAll("%c[ Stamm ] %T", GREEN, "LevelNoVIPAllPlatinum", LANG_SERVER, LIGHTGREEN, name, GREEN, playerpoints[client], LIGHTGREEN, type, GREEN, LIGHTGREEN, (stamm_platinum - playerpoints[client]), stamm_platinum, GREEN);
					if (playerlevel[client] == 4) PrintToChatAll("%c[ Stamm ] %T", GREEN, "LevelVIPAll", LANG_SERVER, LIGHTGREEN, name, GREEN, playerpoints[client], LIGHTGREEN, type, GREEN);
				}
			}
			if (StrEqual(vip_type, "time"))
			{
				new hours = playerpoints[client] / 60;
				new minutes = playerpoints[client] - (hours * 60);
				new resttime;
				
				if (!playerlevel[client]) resttime = stamm_bronze - playerpoints[client];
				if (playerlevel[client] == 1) resttime = stamm_silver - playerpoints[client];
				if (playerlevel[client] == 2) resttime = stamm_gold - playerpoints[client];
				if (playerlevel[client] == 3) resttime = stamm_platinum - playerpoints[client];
				if (playerlevel[client] == 4) resttime = 0;
				
				if (!see_text)
				{
					if (!playerlevel[client]) PrintToChat(client, "%c[ Stamm ] %T", GREEN, "LevelNoVIPClientBronzeTime", LANG_SERVER, LIGHTGREEN, GREEN, hours, LIGHTGREEN, GREEN, minutes, LIGHTGREEN, GREEN, resttime, stamm_bronze, LIGHTGREEN);
					if (playerlevel[client] == 1) PrintToChat(client, "%c[ Stamm ] %T", GREEN, "LevelNoVIPClientSilverTime", LANG_SERVER, LIGHTGREEN, GREEN, hours, LIGHTGREEN, GREEN, minutes, LIGHTGREEN, GREEN, resttime, stamm_silver, LIGHTGREEN)	;			
					if (playerlevel[client] == 2) PrintToChat(client, "%c[ Stamm ] %T", GREEN, "LevelNoVIPClientGoldTime", LANG_SERVER, LIGHTGREEN, GREEN, hours, LIGHTGREEN, GREEN, minutes, LIGHTGREEN, GREEN, resttime, stamm_gold, LIGHTGREEN);
					if (playerlevel[client] == 3) PrintToChat(client, "%c[ Stamm ] %T", GREEN, "LevelNoVIPClientPlatinumTime", LANG_SERVER, LIGHTGREEN, GREEN, hours, LIGHTGREEN, GREEN, minutes, LIGHTGREEN, GREEN, resttime, stamm_platinum, LIGHTGREEN);
					if (playerlevel[client] == 4) PrintToChat(client, "%c[ Stamm ] %T", GREEN, "LevelVIPClientTime", LANG_SERVER, LIGHTGREEN, GREEN, hours, LIGHTGREEN, GREEN, minutes, LIGHTGREEN);
				}
				else
				{
					if (!playerlevel[client]) PrintToChatAll("%c[ Stamm ] %T", GREEN, "LevelNoVIPAllBronzeTime", LANG_SERVER, LIGHTGREEN, name, GREEN, hours, LIGHTGREEN, GREEN, minutes, LIGHTGREEN, GREEN, resttime, stamm_bronze, LIGHTGREEN);
					if (playerlevel[client] == 1) PrintToChatAll("%c[ Stamm ] %T", GREEN, "LevelNoVIPAllSilverTime", LANG_SERVER, LIGHTGREEN, name, GREEN, hours, LIGHTGREEN, GREEN, minutes, LIGHTGREEN, GREEN, resttime, stamm_silver, LIGHTGREEN);			
					if (playerlevel[client] == 2) PrintToChatAll("%c[ Stamm ] %T", GREEN, "LevelNoVIPAllGoldTime", LANG_SERVER, LIGHTGREEN, name, GREEN, hours, LIGHTGREEN, GREEN, minutes, LIGHTGREEN, GREEN, resttime, stamm_gold, LIGHTGREEN);
					if (playerlevel[client] == 3) PrintToChatAll("%c[ Stamm ] %T", GREEN, "LevelNoVIPAllPlatinumTime", LANG_SERVER, LIGHTGREEN, name, GREEN, hours, LIGHTGREEN, GREEN, minutes, LIGHTGREEN, GREEN, resttime, stamm_platinum, LIGHTGREEN);
					if (playerlevel[client] == 4) PrintToChatAll("%c[ Stamm ] %T", GREEN, "LevelVIPAllTime", LANG_SERVER, LIGHTGREEN, name, GREEN, hours, LIGHTGREEN, GREEN, minutes, LIGHTGREEN);
				}
			}
		}
	}
}


public GivePlayerPoints(client)
{
	playerpoints[client] = playerpoints[client] + points;
	PublicPlayerGetPoints(client, points);
}

public bool:IsClientBot(client)
{
	if (client > 0)
	{
		decl String:SteamID[64];

		GetClientAuthString(client, SteamID, sizeof(SteamID));

		if (!IsFakeClient(client) && !StrEqual(SteamID, "BOT") && !StrEqual(SteamID, "STEAM_ID_PENDING")) return false;
	}
	
	return true;
}

public InsertPlayer(client)
{
	if (db != INVALID_HANDLE)
	{
		if (!IsClientBot(client))
		{
			decl String:query[512];
			decl String:steamid[64];
			
			GetClientAuthString(client, steamid, sizeof(steamid));
			
			Format(query, sizeof(query), "SELECT VIP, tag, money, chat, vipchat, joinsound, welcome, disconnect, model, slot, holy, rounds, time, kills, level, wanttag, wantholy, wantjoin, wantvipchat, wantchat FROM %s WHERE steamid = '%s'", tablename, steamid);
				
			SQL_TQuery(db, InsertThePlayer, query, client);
		}
	}
}


SavePlayer(client)
{
	if (db != INVALID_HANDLE && IsClientConnected(client) && ClientReady[client])
	{
		decl String:query[256];
		decl String:steamid[64];
		
		GetClientAuthString(client, steamid, sizeof(steamid));
		
		if (stammdebug)
		{
			PrintToServer("[ STAMM ] Save Player: \"%s\"", steamid);
			LogToFile(LogFile, "[ STAMM ] Save Player: \"%s\"", steamid);
		}
	
		if (allow_change)
		{
			if (StrEqual(vip_type, "kills")) Format(query, sizeof(query), "UPDATE %s SET kills=%i, wanttag='%i', wantholy='%i', wantjoin='%i', wantvipchat='%i', wantchat='%i' WHERE steamid='%s'", tablename, playerpoints[client], WantTag[client], WantHoly[client], WantJoin[client], WantVipChat[client], WantChat[client], steamid);
			if (StrEqual(vip_type, "rounds")) Format(query, sizeof(query), "UPDATE %s SET rounds=%i, wanttag='%i', wantholy='%i', wantjoin='%i', wantvipchat='%i', wantchat='%i' WHERE steamid='%s'", tablename, playerpoints[client], WantTag[client], WantHoly[client], WantJoin[client], WantVipChat[client], WantChat[client], steamid);
			if (StrEqual(vip_type, "time")) Format(query, sizeof(query), "UPDATE %s SET time=%i, wanttag='%i', wantholy='%i', wantjoin='%i', wantvipchat='%i', wantchat='%i' WHERE steamid='%s'", tablename, playerpoints[client], WantTag[client], WantHoly[client], WantJoin[client], WantVipChat[client], WantChat[client], steamid);
		}
		else
		{
			if (StrEqual(vip_type, "kills")) Format(query, sizeof(query), "UPDATE %s SET kills=%i WHERE steamid='%s'", tablename, playerpoints[client], steamid);
			if (StrEqual(vip_type, "rounds")) Format(query, sizeof(query), "UPDATE %s SET rounds=%i WHERE steamid='%s'", tablename, playerpoints[client], steamid);
			if (StrEqual(vip_type, "time")) Format(query, sizeof(query), "UPDATE %s SET time=%i WHERE steamid='%s'", tablename, playerpoints[client], steamid);
		}
		
		SQL_TQuery(db, SQLErrorCheckCallback, query, 1980);
	}
}

public PublicPlayerGetPoints(client, number)
{
	Call_StartForward(stamm_get);
	
	Call_PushCell(client);
	Call_PushCell(number);
	
	Call_Finish();
}

public PublicPlayerBecomeVip(client)
{
	Call_StartForward(player_stamm);
	
	Call_PushCell(client);
	
	Call_Finish();
}

CheckVip(client)
{
	if (db != INVALID_HANDLE)
	{
		decl String:steamid[64];
		decl String:query[128];
		new clientpoints = playerpoints[client];
		
		GetClientAuthString(client, steamid, sizeof(steamid));
		if (!stamm_level)
		{
			if (!playervip[client] && clientpoints >= points_to_become_vip)
			{
				decl String:name[MAX_NAME_LENGTH+1];
				
				playervip[client] = 1;
				
				GetClientName(client, name, sizeof(name));
				
				Format(query, sizeof(query), "UPDATE %s SET VIP=1 WHERE steamid='%s'", tablename, steamid);
				
				if (SQL_Query(db, query) == INVALID_HANDLE && stammdebug) {SQL_GetError(db, SQLError, sizeof(SQLError));LogToFile(DebugFile, "[ STAMM ] Error on Executing Command on Line 2024: %s", SQLError);}
				
				PrintToChatAll("%c[ Stamm ] %T", GREEN, "NoLevelNowVIP", LANG_SERVER, LIGHTGREEN, name);
				PrintToChat(client, "%c[ Stamm ] %T", GREEN, "JoinVIP", LANG_SERVER, LIGHTGREEN);
				
				PublicPlayerBecomeVip(client);
				
				if (!StrEqual(lvl_up_sound, "0")) EmitSoundToAll(lvl_up_sound);
			}
			if (playervip[client] && clientpoints < points_to_become_vip)
			{	
				playervip[client] = 0;
				
				Format(query, sizeof(query), "UPDATE %s SET VIP=0 WHERE steamid='%s'", tablename, steamid);
				
				if (SQL_Query(db, query) == INVALID_HANDLE && stammdebug) {SQL_GetError(db, SQLError, sizeof(SQLError));LogToFile(DebugFile, "[ STAMM ] Error on Executing Command on Line 2039: %s", SQLError);}
			}
		}
		else
		{
			new levelstufe = 0;
			
			if (clientpoints < stamm_platinum) levelstufe = 3;
			if (clientpoints < stamm_gold) levelstufe = 2;
			if (clientpoints < stamm_silver) levelstufe = 1;
			if (clientpoints < stamm_bronze) levelstufe = -1;
			if (clientpoints >= stamm_bronze) levelstufe = 1;
			if (clientpoints >= stamm_silver) levelstufe = 2;
			if (clientpoints >= stamm_gold) levelstufe = 3;
			if (clientpoints >= stamm_platinum) levelstufe = 4;

			if (levelstufe > 0 && levelstufe != playerlevel[client])
			{		
				decl String:name[MAX_NAME_LENGTH+1];
				decl String:setquery[256];
				decl String:levelname[64];
				
				if (levelstufe == 1) Format(levelname, sizeof(levelname), "%T", "Bronze", LANG_SERVER);
				if (levelstufe == 2) Format(levelname, sizeof(levelname), "%T", "Silver", LANG_SERVER);
				if (levelstufe == 3) Format(levelname, sizeof(levelname), "%T", "Gold", LANG_SERVER);
				if (levelstufe == 4) Format(levelname, sizeof(levelname), "%T", "Platinum", LANG_SERVER);
				
				playervip[client] = 1;
				playerlevel[client] = levelstufe;
				
				GetClientName(client, name, sizeof(name));
				
				PrintToChatAll("%c[ Stamm ] %T", GREEN, "LevelNowVIP", LANG_SERVER, LIGHTGREEN, name, levelname);
				PrintToChat(client, "%c[ Stamm ] %T", GREEN, "JoinVIP", LANG_SERVER, LIGHTGREEN);
				
				PublicPlayerBecomeVip(client);
				
				if (!StrEqual(lvl_up_sound, "0")) EmitSoundToAll(lvl_up_sound);
				
				if (levels[FEATURE_TAG] <= levelstufe) playertag[client] = 1;
				if (levels[FEATURE_TAG] > levelstufe) playertag[client] = 0;

				if (levels[FEATURE_MONEY] <= levelstufe) playermoney[client] = 1;
				if (levels[FEATURE_MONEY] > levelstufe) playermoney[client] = 0;

				if (levels[FEATURE_JOINSOUND] <= levelstufe) playerjoinsound[client] = 1;
				if (levels[FEATURE_JOINSOUND] > levelstufe) playerjoinsound[client] = 0;
				
				if (levels[FEATURE_WELCOME] <= levelstufe) playerwelcome[client] = 1;
				if (levels[FEATURE_WELCOME] > levelstufe) playerwelcome[client] = 0;

				if (levels[FEATURE_LEAVE] <= levelstufe) playerdisconnect[client] = 1;
				if (levels[FEATURE_LEAVE] > levelstufe) playerdisconnect[client] = 0;
				
				if (levels[FEATURE_MODEL] <= levelstufe) playermodel[client] = 1;
				if (levels[FEATURE_MODEL] > levelstufe) playermodel[client] = 0;
				
				if (levels[FEATURE_VIPCHAT] <= levelstufe) playervipchat[client] = 1;
				if (levels[FEATURE_VIPCHAT] > levelstufe) playervipchat[client] = 0;
				
				if (levels[FEATURE_CHAT] <= levelstufe) playerchat[client] = 1;
				if (levels[FEATURE_CHAT] > levelstufe) playerchat[client] = 0;
				
				if (levels[FEATURE_SLOT] <= levelstufe) playerslot[client] = 1;
				if (levels[FEATURE_SLOT] > levelstufe) playerslot[client] = 0;
				
				if (levels[FEATURE_HOLY] <= levelstufe) playerholy[client] = 1;
				if (levels[FEATURE_HOLY] > levelstufe) playerholy[client] = 0;

				Format(setquery, sizeof(setquery), "UPDATE %s SET VIP=1, level='%i', tag='%i',money='%i',chat='%i',vipchat='%i',joinsound='%i',welcome='%i',disconnect='%i',model='%i',slot='%i',holy='%i' WHERE steamid='%s'", tablename, levelstufe, playertag[client], playermoney[client], playerchat[client], playervipchat[client], playerjoinsound[client], playerwelcome[client], playerdisconnect[client], playermodel[client], playerslot[client], playerholy[client], steamid);
				
				if (SQL_Query(db, setquery) == INVALID_HANDLE && stammdebug) {SQL_GetError(db, SQLError, sizeof(SQLError));LogToFile(DebugFile, "[ STAMM ] Error on Executing Command on Line 2110: %s", SQLError);}
			}
			else
			{
				if (levelstufe == -1 && levelstufe != playerlevel[client])
				{
					decl String:queryback[512];
									
					playervip[client] = 0;
					playertag[client] = 0;
					playermoney[client] = 0;
					playerchat[client] = 0;
					playervipchat[client] = 0;
					playerjoinsound[client] = 0;
					playerwelcome[client] = 0;
					playerdisconnect[client] = 0;
					playermodel[client] = 0;
					playerslot[client] = 0;
					playerholy[client] = 0;
					playerlevel[client] = 0;

					Format(queryback, sizeof(queryback), "UPDATE %s SET VIP=0,level=0,tag=0,money=0,chat=0,vipchat=0,joinsound=0,welcome=0,disconnect=0,model=0,slot=0,holy=0 WHERE steamid='%s'", tablename, steamid);
					
					if (SQL_Query(db, queryback) == INVALID_HANDLE && stammdebug) {SQL_GetError(db, SQLError, sizeof(SQLError));LogToFile(DebugFile, "[ STAMM ] Error on Executing Command on Line 2133: %s", SQLError);}
				}
			}
		}
		SavePlayer(client);
	}
}

public bool:CheckCon(Handle:hndl, const String:run[], const String:error[], line)
{
	if (hndl == INVALID_HANDLE || !StrEqual(error, ""))
	{
		if (stammdebug)
		{
			LogToFile(LogFile, "[ STAMM ] Database Error while \"%s\" on Line %i, Error: %s", run, line, error);
			PrintToServer("[ STAMM ] Database Error while \"%s\" on Line %i, Error: %s", run, line, error);
		}
		
		return false;
	}
	if (stammdebug)
	{
		PrintToServer("[ STAMM ] Execute Action: \"%s\"", run);
		LogToFile(LogFile, "[ STAMM ] Execute Action: \"%s\"", run);
	}
	
	return true;
}

VipSlotCheck(client)
{
	new max_players = MaxClients;
	new current_players = GetClientCount(false);
	new max_slots = max_players - current_players;
	
	if (vip_slots > max_slots)
	{
			if (!stamm_level)
			{
				if (!playervip[client] && !IsAdmin(client)) KickClient(client, vip_kick_message);
			}
			else
			{
				if (!playerslot[client] && !IsAdmin(client)) KickClient(client, vip_kick_message);
			}
	}
	
	current_players = GetClientCount(false);
	max_slots = max_players - current_players;
	
	if (let_free)
	{
		if (!max_slots)
		{
			new bool:playeringame = false;
			
			while(!playeringame)
			{
				new RandPlayer = GetRandomInt(1, 64);
				
				playeringame = false;
				
				if (IsClientConnected(RandPlayer) && !IsClientBot(RandPlayer))
				{
					if (!stamm_level)
					{
						if (!playervip[client] && !IsAdmin(client))
						{
							KickClient(client, vip_kick_message2);
							playeringame = true;
						}
						
					}
					else
					{
						if (!playerslot[client] && !IsAdmin(client))
						{						
							KickClient(client, vip_kick_message2);
							playeringame = true;
						}
					}		
				}
			}
		}
	}
}

public bool:IsAdmin(client)
{
	new AdminId:adminid = GetUserAdmin(client);
		
	if (( GetAdminFlag(adminid, Admin_Custom6) || GetAdminFlag(adminid, Admin_Root)) && !IsClientBot(client)) return true;
	
	return false;
}

NameCheck(client)
{
	decl String:name[MAX_NAME_LENGTH+1];
	
	GetClientName(client, name, sizeof(name));
	
	if (StrContains(name, stammtag) != -1)
	{
		if (stammtagkick)
		{
			if (!stamm_level)
			{
				if (!playervip[client]) KickClient(client, "%T", "NoVIPUseTag", LANG_SERVER);
			}
			if (stamm_level)
			{
				if (!playertag[client]) KickClient(client, "%T", "NoVIPUseTag", LANG_SERVER);
			}
		}
	}
}

CheckDLFilter(client)
{
	QueryClientConVar(client, "cl_downloadfilter", DLCheckQuery, client);
}


/* Onies */

CheckGame()
{
	decl String:GameName[10];
	GetGameFolderName(GameName, sizeof(GameName));
	
	if(StrEqual(GameName, "tf")) IsTF = 1;
	if(!StrEqual(GameName, "tf")) IsTF = 0;
}

MakeHappyHour(client)
{
	happynumber[client] = 1;
	PrintToChat(client, "%c[ Stamm ] %T", GREEN, "WriteHappyTime", LANG_SERVER, LIGHTGREEN, GREEN);
	PrintToChat(client, "%c[ Stamm ] %T", GREEN, "WriteHappyTimeInfo", LANG_SERVER, LIGHTGREEN, GREEN, LIGHTGREEN);
}

PrepareSameModels(client)
{
	if (!PlayerHasModel[client] && ((!admin_model && !IsAdmin(client)) || admin_model))
	{ 
		decl String:ModelChooseLang[256];
		decl String:StandardModel[256];
		
		Format(ModelChooseLang, sizeof(ModelChooseLang), "%T", "ChooseModel", LANG_SERVER);
		Format(StandardModel, sizeof(StandardModel), "%T", "StandardModel", LANG_SERVER);
		
		ModelMenu = CreateMenu(ModelMenuCall);
		
		SetMenuTitle(ModelMenu, ModelChooseLang);
		SetMenuExitButton(ModelMenu, false);
		
		if (GetClientTeam(client) == 2)
		{
			if (!StrEqual(T_1_MODEL, "") && !StrEqual(T_1_MODEL, "0") && !StrEqual(T_1_MODEL, " ")) AddMenuItem(ModelMenu, T_1_MODEL, T_1_NAME);
			if (!StrEqual(T_2_MODEL, "") && !StrEqual(T_2_MODEL, "0") && !StrEqual(T_2_MODEL, " ")) AddMenuItem(ModelMenu, T_2_MODEL, T_2_NAME);
		}
		if (GetClientTeam(client) == 3)
		{
			if (!StrEqual(CT_1_MODEL, "") && !StrEqual(CT_1_MODEL, "0") && !StrEqual(CT_1_MODEL, " ")) AddMenuItem(ModelMenu, CT_1_MODEL, CT_1_NAME);
			if (!StrEqual(CT_2_MODEL, "") && !StrEqual(CT_2_MODEL, "0") && !StrEqual(CT_2_MODEL, " ")) AddMenuItem(ModelMenu, CT_2_MODEL, CT_2_NAME);
		}
		
		AddMenuItem(ModelMenu, "standard", StandardModel);
		
		DisplayMenu(ModelMenu, client, MENU_TIME_FOREVER);
	}
	else
	{
		if (PlayerHasModel[client]) SetEntityModel(client, PlayerModel[client]);
	}
}

PrepareRandomModels(client)
{
	new TMODELS = 0;
	new CTMODELS = 0;
	
	if (!StrEqual(T_1_MODEL, "") && !StrEqual(T_1_MODEL, "0") && !StrEqual(T_1_MODEL, " ")) TMODELS++;
	if (!StrEqual(T_2_MODEL, "") && !StrEqual(T_2_MODEL, "0") && !StrEqual(T_2_MODEL, " ")) TMODELS++;
	if (!StrEqual(CT_1_MODEL, "") && !StrEqual(CT_1_MODEL, "0") && !StrEqual(CT_1_MODEL, " ")) CTMODELS++;
	if (!StrEqual(CT_2_MODEL, "") && !StrEqual(CT_2_MODEL, "0") && !StrEqual(CT_2_MODEL, " ")) CTMODELS++;
	
	new RandModelT = GetRandomInt(1, TMODELS);
	new RandModelCT = GetRandomInt(1, CTMODELS);
	
	if ((!admin_model && !IsAdmin(client)) || admin_model)
	{
		if (GetClientTeam(client) == 2)
		{
			if (TMODELS == 1)
			{
				if (!StrEqual(T_1_MODEL, "") && !StrEqual(T_1_MODEL, "0") && !StrEqual(T_1_MODEL, " ") && !StrEqual(T_1_MODEL, "\0")) SetEntityModel(client, T_1_MODEL);
				if (!StrEqual(T_2_MODEL, "") && !StrEqual(T_2_MODEL, "0") && !StrEqual(T_2_MODEL, " ") && !StrEqual(T_2_MODEL, "\0")) SetEntityModel(client, T_2_MODEL);
			}
			
			if (TMODELS == 2)
			{
				if (RandModelT == 1)
				{
					if (!StrEqual(T_1_MODEL, "") && !StrEqual(T_1_MODEL, "0") && !StrEqual(T_1_MODEL, " ") && !StrEqual(T_1_MODEL, "\0")) SetEntityModel(client, T_1_MODEL);
				}
				if (RandModelT == 2)
				{
					if (!StrEqual(T_2_MODEL, "") && !StrEqual(T_2_MODEL, "0") && !StrEqual(T_2_MODEL, " ") && !StrEqual(T_2_MODEL, "\0")) SetEntityModel(client, T_2_MODEL);
				}
			}
		}
		if (GetClientTeam(client) == 3)
		{
			if (CTMODELS == 1)
			{
				if (!StrEqual(CT_1_MODEL, "") && !StrEqual(CT_1_MODEL, "0") && !StrEqual(CT_1_MODEL, " ") && !StrEqual(CT_1_MODEL, "\0")) SetEntityModel(client, CT_1_MODEL);
				if (!StrEqual(CT_2_MODEL, "") && !StrEqual(CT_2_MODEL, "0") && !StrEqual(CT_2_MODEL, " ") && !StrEqual(CT_2_MODEL, "\0")) SetEntityModel(client, CT_2_MODEL);
			}
			
			if (CTMODELS == 2)
			{
				if (RandModelCT == 1)
				{
					if (!StrEqual(CT_1_MODEL, "") && !StrEqual(CT_1_MODEL, "0") && !StrEqual(CT_1_MODEL, " ") && !StrEqual(CT_1_MODEL, "\0")) SetEntityModel(client, CT_1_MODEL);
				}
				if (RandModelCT == 2)
				{
					if (!StrEqual(CT_2_MODEL, "") && !StrEqual(CT_2_MODEL, "0") && !StrEqual(CT_2_MODEL, " ") && !StrEqual(CT_2_MODEL, "\0")) SetEntityModel(client, CT_2_MODEL);
				}
			}
		}
	}
}


public DLCheckQuery(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[])
{
	if (!StrEqual(cvarValue, "all") && IsClientInGame(client))
	{
		ChangeClientTeam(client, 0);
		PrintToChat(client, "%c[ Stamm ] %T", GREEN, "DownloadFilter", LANG_SERVER, LIGHTGREEN, GREEN, LIGHTGREEN, GREEN, LIGHTGREEN, GREEN);
		PrintToChat(client, "%ccl_downloadfilter %c\"all\"", LIGHTGREEN, GREEN);
	}
}

GetVIPTop(client)
{
	if (db != INVALID_HANDLE)
	{
		decl String:query[128];
		
		if (StrEqual(vip_type, "kills")) Format(query, sizeof(query), "SELECT name, kills FROM %s WHERE kills >= '%i' and VIP = 1 ORDER BY kills DESC", tablename, viplistmin);
		if (StrEqual(vip_type, "rounds")) Format(query, sizeof(query), "SELECT name, rounds FROM %s WHERE rounds >= '%i' and VIP = 1 ORDER BY rounds DESC", tablename, viplistmin);
		if (StrEqual(vip_type, "time")) Format(query, sizeof(query), "SELECT name, time FROM %s WHERE time >= '%i' and VIP = 1 ORDER BY time DESC", tablename, viplistmin);
	
		SQL_TQuery(db, GetVIPTopQuery, query, client);
	}
}

GetVIPRank(client)
{
	if(db != INVALID_HANDLE)
	{
		decl String:query[128];
		
		if (StrEqual(vip_type, "kills")) Format(query, sizeof(query), "SELECT kills, steamid FROM %s WHERE VIP = 1 ORDER BY kills DESC", tablename);
		if (StrEqual(vip_type, "rounds")) Format(query, sizeof(query), "SELECT rounds, steamid FROM %s WHERE VIP = 1 ORDER BY rounds DESC", tablename);
		if (StrEqual(vip_type, "time")) Format(query, sizeof(query), "SELECT time, steamid FROM %s WHERE VIP = 1 ORDER BY time DESC", tablename);
		
		SQL_TQuery(db, GetVIPRankQuery, query, client);
	}
}

CreateConfig()
{
	CreateConVar("stamm_ver", Plugin_Version, "Stamm Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	stammdebugc = CreateConVar("stamm_debug", "1", "1=Log important Stamm steps, 0 = OFF");
	HookConVarChange(stammdebugc, stammdebug_change);
	
	serveridc = CreateConVar("stamm_serverid", "1", "If you have more than one Server, type here your Server number in, e.g. 1. Server = 1");
	giveflagadminc = CreateConVar("stamm_oflag", "0", "not 0 = a Player with the a special Flag become VIP (1='o', 2='p' , 3='q', 4='r', 5='s', 6='t'), 0 = Off");
	HookConVarChange(giveflagadminc, giveflagadmin_change);
	allow_changec = CreateConVar("stamm_allow_change", "1", "1 = Players can switch there Specials between on/off 0 = They can't");
	vip_typec = CreateConVar("stamm_vip_type", "kills", "\"rounds\" to count rounds, \"kills\" to count kills or \"time\" to count the playtime on the Server, to become VIP");
	stamm_levelc = CreateConVar("stamm_stamm_level", "0", "1 = Level Stamm ON 0 = OFF");
	bot_kill_counterc = CreateConVar("stamm_bot_kill_counter", "1", "1 = Count BOT Kills, too, 0 = Don't count BOT Kills");
	HookConVarChange(bot_kill_counterc, bot_kill_counter_change);
	lvl_up_soundc = CreateConVar("stamm_lvl_up_sound", "stamm/lvl_up.mp3", "0 = Level Up Sound OFF, otherwise the Path to the sound, beginning after sound/");
	HookConVarChange(lvl_up_soundc, lvl_up_sound_change);
	min_playerc = CreateConVar("stamm_min_player", "0", "Number of Players, which have to be on the Server, to count rounds/kills/time");
	HookConVarChange(min_playerc, min_player_change);
	infotimec = CreateConVar("stamm_infotime", "300", "Info Message Interval in seconds (300 = 5 minutes)");

	points_to_become_vipc = CreateConVar("stamm_points_to_become_vip", "2000", "How much rounds/kills/time must a Player have, to become VIP, if Stamm Level is off (Time in Hours)");
	
	stamm_bronzec = CreateConVar("stamm_stamm_bronze", "500", "How much rounds/kills/time must a Player have, to become Bronze VIP, (Time in Hours)");
	stamm_silverc = CreateConVar("stamm_stamm_silver", "1000", "How much rounds/kills/time must a Player have, to become Silver VIP, (Time in Hours)");
	stamm_goldc = CreateConVar("stamm_stamm_gold", "1500", "How much rounds/kills/time must a Player have, to become Gold VIP, (Time in Hours)");
	stamm_platinumc = CreateConVar("stamm_stamm_platinum", "2000", "How much rounds/kills/time must a Player have, to become Platinum VIP, (Time in Hours)");
		
	enable_filterc = CreateConVar("stamm_enable_filter", "0", "1 = if a Player haven't cl_downloadfilter to \"all\", he have to change it, 0 = OFF");
	HookConVarChange(enable_filterc, enable_filter_change);
	
	enable_modelsc = CreateConVar("stamm_enable_models", "1", "1 = Enable VIP Skins, 0 = OFF");
	HookConVarChange(enable_modelsc, enable_models_change);
	same_modelsc = CreateConVar("stamm_same_models", "0", "1 = Vip's get always the same Skin 0 = Random Skin every Round");
	model_changec = CreateConVar("stamm_model_change", "1", "0 = Players can only change models, when changing team, 1 = Players can always change it");
	HookConVarChange(model_changec, model_change_change);
	model_change_cmdc = CreateConVar("stamm_model_change_cmd", "!smodel", "Command to change model");
	admin_modelc = CreateConVar("stamm_admin_model", "1", "Should Admins also get a VIP Skin 1 = Yes, 0 = No");
	
	texttowritec = CreateConVar("stamm_texttowrite", "!stamm", "Command to see currently rounds/kills/time");
	admin_menuc = CreateConVar("stamm_admin_menu", "!sadmin", "Command for Admin Menu");
	viplistc = CreateConVar("stamm_viplist", "!slist", "Command for VIP Top");
	viplistminc = CreateConVar("stamm_viplistmin", "100", "How much points a Player must have, to come in the VIP Top, Time in Minutes (if you have much VIP's, make this number greater than the number to become VIP)");
	HookConVarChange(viplistminc, viplistmin_change);
	viprankc = CreateConVar("stamm_viprank", "!srank", "Command for VIP Rank");
	
	autochatc = CreateConVar("stamm_autochat", "1", "0 = No VIP Chat Tag 1 = VIP's get a special chat tag, if they start the message with '*'");
	HookConVarChange(autochatc, autochat_change);
	MessageTagc = CreateConVar("stamm_messagetag", "VIP Message", "Tag when a player writes something as a VIP");
	HookConVarChange(MessageTagc, MessageTag_change);
	own_chatc = CreateConVar("stamm_own_chat", "1", "0 = VIP's get no own chat 1 = VIP's get a own chat, if they start the message with '#'");
	HookConVarChange(own_chatc, own_chat_change);
	OwnChatTagc = CreateConVar("stamm_ownchattag", "VIP Chat", "Tag when a player writes something in the VIP Chat");
	HookConVarChange(OwnChatTagc, OwnChatTag_change);

	vipcashc = CreateConVar("stamm_vipcash", "2000", "0 = No VIP Cash x = Cash, what a VIP gets, when he join");
	HookConVarChange(vipcashc, vipcash_change);
	
	enable_holy_grenadec = CreateConVar("stamm_enable_holy_grenade", "1", "Should VIP's get a Holy Grenade? 1 = yes, 0 = no");
	HookConVarChange(enable_holy_grenadec, enable_holy_grenade_change);
	hear_holy_grenadec = CreateConVar("stamm_hear_holy_grenade", "1", "Should all Player hear the Holy Grenade? 1 = yes, 0 = no");
	HookConVarChange(hear_holy_grenadec, hear_holy_grenade_change);

	enable_vip_slotc = CreateConVar("stamm_enable_vip_slot", "0", "Should VIP's get a Reserve Slot ? 1 = yes, 0 = no ( Own Reserve Slot Function )");
	HookConVarChange(enable_vip_slotc, enable_vip_slot_change);
	vip_slotsc = CreateConVar("stamm_vip_slots", "0", "How many Reserve Slots should there be ?");
	vip_kick_messagec = CreateConVar("stamm_vip_kick_message", "You joined on a Reserve Slot", "Message, when someone join on a Reserve Slot");
	HookConVarChange(vip_kick_messagec, vip_kick_message_change);
	let_freec = CreateConVar("stamm_let_free", "0", "1 = Let a Slot always free and kick a random Player  0 = Off");
	HookConVarChange(let_freec, let_free_change);
	vip_kick_message2c = CreateConVar("stamm_vip_kick_message2", "You get kicked, to let a VIP slot free", "Message for the random kicked person");
	HookConVarChange(vip_kick_message2c, vip_kick_message2_change);

	stamm_tag_on_offc = CreateConVar("stamm_stamm_tag_on_off", "1", "1 = VIP's get a VIP Tag, 0 = OFF");
	HookConVarChange(stamm_tag_on_offc, stamm_tag_on_off_change);
	stammtagkickc = CreateConVar("stamm_stammtagkick", "1", "1 = Kicks Player, which use Stamm Tag, but aren't VIPs, 0 = No Kick");
	HookConVarChange(stammtagkickc, stammtagkick_change);
	stammtagc = CreateConVar("stamm_stammtag", "--> *VIP*", "Stamm Tag, which a VIP gets, make a clearly tag, not only one letter");
	stammtag_posc = CreateConVar("stamm_stammtag_pos", "x", "x = Tag before the name y = Tag behind the name");

	see_textc = CreateConVar("stamm_see_text", "1", "1 = All see rounds/kills/time , 0 = only the player, who write it in the chat");
	HookConVarChange(see_textc, see_text_change);
	join_showc = CreateConVar("stamm_join_show", "1", "1 = When a Player join, he see his rounds/kills/time, 0 = OFF");
	HookConVarChange(join_showc, join_show_change);
	
	vip_joinsoundc = CreateConVar("stamm_vip_joinsound", "stamm/vip_join_fix.mp3", "0 = No VIP Join Sound, otherwise the Path to the sound, beginning after sound/");
	HookConVarChange(vip_joinsoundc, vip_joinsound_change);
	vip_chatwelcomec = CreateConVar("stamm_vip_chatwelcome", "1", "Message when a VIP join the Server 1 = yes, 0 = no");
	HookConVarChange(vip_chatwelcomec, vip_chatwelcome_change);
	vip_chatgoodbyec = CreateConVar("stamm_vip_chatgoodbye", "1", "Message when a VIP leave the Server 1 = yes, 0 = no");
	HookConVarChange(vip_chatgoodbyec, vip_chatgoodbye_change);
	
	updateaddonc = CreateConVar("stamm_updateaddon", "1", "1 = Get Update Infomations, 0 = OFF");
	HookConVarChange(updateaddonc, updateaddon_change);

	AutoExecConfig(true, "stamm_config", "stamm");
	
}

ReadConfig()
{	
	stammdebug = GetConVarInt(stammdebugc);
	
	serverid = GetConVarInt(serveridc);

	giveflagadmin = GetConVarInt(giveflagadminc);
	allow_change = GetConVarInt(allow_changec);
	GetConVarString(vip_typec, vip_type, sizeof(vip_type));
	stamm_level = GetConVarInt(stamm_levelc);
	bot_kill_counter = GetConVarInt(bot_kill_counterc);
	GetConVarString(lvl_up_soundc, lvl_up_sound, sizeof(lvl_up_sound));
	min_player = GetConVarInt(min_playerc);
	infotime = GetConVarFloat(infotimec);

	points_to_become_vip = GetConVarInt(points_to_become_vipc);
	stamm_bronze = GetConVarInt(stamm_bronzec);
	stamm_silver = GetConVarInt(stamm_silverc);
	stamm_gold = GetConVarInt(stamm_goldc);
	stamm_platinum = GetConVarInt(stamm_platinumc);

	enable_filter = GetConVarInt(enable_filterc);

	enable_models = GetConVarInt(enable_modelsc);
	same_models = GetConVarInt(same_modelsc);
	model_change = GetConVarInt(model_changec);
	GetConVarString(model_change_cmdc, model_change_cmd, sizeof(model_change_cmd));
	admin_model = GetConVarInt(admin_modelc);

	GetConVarString(texttowritec, texttowrite, sizeof(texttowrite));
	GetConVarString(admin_menuc, admin_menu, sizeof(admin_menu));
	GetConVarString(viplistc, viplist, sizeof(viplist));
	GetConVarString(viprankc, viprank, sizeof(viprank));
	viplistmin = GetConVarInt(viplistminc);

	autochat = GetConVarInt(autochatc);
	GetConVarString(MessageTagc, MessageTag, sizeof(MessageTag));
	own_chat = GetConVarInt(own_chatc);
	GetConVarString(OwnChatTagc, OwnChatTag, sizeof(OwnChatTag));

	vipcash = GetConVarInt(vipcashc);

	enable_holy_grenade = GetConVarInt(enable_holy_grenadec);
	hear_holy_grenade = GetConVarInt(hear_holy_grenadec);

	enable_vip_slot = GetConVarInt(enable_vip_slotc);
	vip_slots = GetConVarInt(vip_slotsc);
	GetConVarString(vip_kick_messagec, vip_kick_message, sizeof(vip_kick_message));
	let_free = GetConVarInt(let_freec);
	GetConVarString(vip_kick_message2c, vip_kick_message2, sizeof(vip_kick_message2));

	stamm_tag_on_off = GetConVarInt(stamm_tag_on_offc);
	stammtagkick = GetConVarInt(stammtagkickc);
	GetConVarString(stammtagc, stammtag, sizeof(stammtag));
	GetConVarString(stammtag_posc, stammtag_pos, sizeof(stammtag_pos));

	see_text = GetConVarInt(see_textc);
	join_show = GetConVarInt(join_showc);

	GetConVarString(vip_joinsoundc, vip_joinsound, sizeof(vip_joinsound));
	vip_chatwelcome = GetConVarInt(vip_chatwelcomec);
	vip_chatgoodbye = GetConVarInt(vip_chatgoodbyec);

	updateaddon = GetConVarInt(updateaddonc);
	
	level_settings = CreateKeyValues("LevelSettings");
	model_settings = CreateKeyValues("ModelSettings");
	
	FileToKeyValues(level_settings, "cfg/stamm/LevelSettings.txt");
	FileToKeyValues(model_settings, "cfg/stamm/ModelSettings.txt");
		
	levels[FEATURE_TAG] = KvGetNum(level_settings, "tag");
	levels[FEATURE_MONEY] = KvGetNum(level_settings, "money");
	levels[FEATURE_JOINSOUND] = KvGetNum(level_settings, "joinsound");
	levels[FEATURE_WELCOME] = KvGetNum(level_settings, "welcome");
	levels[FEATURE_LEAVE] = KvGetNum(level_settings, "leave");
	levels[FEATURE_MODEL] = KvGetNum(level_settings, "model");
	levels[FEATURE_VIPCHAT] = KvGetNum(level_settings, "vipchat");
	levels[FEATURE_CHAT] = KvGetNum(level_settings, "chat");
	levels[FEATURE_SLOT] = KvGetNum(level_settings, "slot");
	levels[FEATURE_HOLY] = KvGetNum(level_settings, "holy");
	
		
	KvGetString(model_settings, "T_1_MODEL", T_1_MODEL, sizeof(T_1_MODEL));
	KvGetString(model_settings, "T_1_NAME", T_1_NAME, sizeof(T_1_NAME));
	KvGetString(model_settings, "T_2_MODEL", T_2_MODEL, sizeof(T_2_MODEL));
	KvGetString(model_settings, "T_2_NAME", T_2_NAME, sizeof(T_2_NAME));
	KvGetString(model_settings, "CT_1_MODEL", CT_1_MODEL, sizeof(CT_1_MODEL));
	KvGetString(model_settings, "CT_1_NAME", CT_1_NAME, sizeof(CT_1_NAME));
	KvGetString(model_settings, "CT_2_MODEL", CT_2_MODEL, sizeof(CT_2_MODEL));
	KvGetString(model_settings, "CT_2_NAME", CT_2_NAME, sizeof(CT_2_NAME));
	
	CloseHandle(model_settings);
	CloseHandle(level_settings);
	
	if (StrEqual(vip_type, "time"))
	{
		points_to_become_vip = points_to_become_vip * 60;
		stamm_bronze = stamm_bronze * 60;
		stamm_silver = stamm_silver * 60;
		stamm_gold = stamm_gold * 60;
		stamm_platinum = stamm_platinum * 60;
	}
}

ModelDownloads()
{
	new Handle:downloadfile = OpenFile("cfg/stamm/ModelDownloads.txt", "rb");
	
	while( !IsEndOfFile(downloadfile))
	{
		decl String:filecontent[512];
		
		ReadFileLine(downloadfile, filecontent, sizeof(filecontent));
		ReplaceString(filecontent, sizeof(filecontent), " ", "");
		ReplaceString(filecontent, sizeof(filecontent), "\n", "");
		ReplaceString(filecontent, sizeof(filecontent), "\t", "");
		ReplaceString(filecontent, sizeof(filecontent), "\r", "");
		
		if (!StrEqual(filecontent, "")) AddFileToDownloadsTable(filecontent);
	}
	
	CloseHandle(downloadfile);
}

CreatePanels()
{
	decl String:stammcmd[128], String:srankcmd[128], String:stopcmd[128], String:changecmd[128], String:modelchangecmd[128];
	decl String:reset_list[256], String:close[256], String:resetit[256];
	decl String:TagInfo[256];
	decl String:getskin[256], String:getchattag[256], String:getownchat[256], String:getmoney[256], String:getholy[256], String:getslot[256], String:gettag[256], String:getjoin[256], String:getwelcome[256], String:getleave[256];
	decl String:btext[256], String:stext[256], String:gtext[256], String:ptext[256];
	decl String:back[256];
	decl String:AdminMenuText[256];
	decl String:RPoints[256], String:KPoints[256], String:TPoints[256];
	decl String:stammcmds[256];
	decl String:stammfts[256];
	decl String:resetplayertext[256];
	decl String:resetdbtext[256];
	decl String:happyhourtext[256];
	decl String:updatetext[256];
	
	Format(TagInfo, sizeof(TagInfo), "%T", "TagInfo", LANG_SERVER);
	Format(AdminMenuText, sizeof(AdminMenuText), "%T", "AdminMenu", LANG_SERVER);
	Format(RPoints, sizeof(RPoints), "%T", "RoundsOfPlayer", LANG_SERVER);
	Format(KPoints, sizeof(KPoints), "%T", "KillsOfPlayer", LANG_SERVER);
	Format(TPoints, sizeof(TPoints), "%T", "TimeOfPlayer", LANG_SERVER);
	Format(stammcmds, sizeof(stammcmds), "%T", "StammCMD", LANG_SERVER);
	Format(stammfts, sizeof(stammfts), "%T", "StammFeatures", LANG_SERVER);
	Format(resetplayertext, sizeof(resetplayertext), "%T", "ResetPlayer", LANG_SERVER);
	Format(resetdbtext, sizeof(resetdbtext), "%T", "ResetDatabase", LANG_SERVER);
	Format(happyhourtext, sizeof(happyhourtext), "%T", "HappyHour", LANG_SERVER);
	Format(updatetext, sizeof(updatetext), "%T", "Update", LANG_SERVER);
	Format(stammcmd, sizeof(stammcmd), "%T %s", "StammPoints", LANG_SERVER, texttowrite);
	Format(srankcmd, sizeof(srankcmd), "%T %s", "StammTop", LANG_SERVER, viplist);
	Format(stopcmd, sizeof(stopcmd), "%T %s", "StammRank", LANG_SERVER, viprank);
	Format(changecmd, sizeof(changecmd), "%T !schange", "StammChange", LANG_SERVER);
	Format(modelchangecmd, sizeof(modelchangecmd), "%T", "ModelChangeCmd", LANG_SERVER, model_change_cmd);
	Format(reset_list, sizeof(reset_list), "%T", "DelStammList", LANG_SERVER);
	Format(close, sizeof(close), "%T", "Close", LANG_SERVER);
	Format(resetit, sizeof(resetit), "%T", "Reset", LANG_SERVER);
	Format(getskin, sizeof(getskin), "%T", "GetSkin",LANG_SERVER);
	Format(getchattag, sizeof(getchattag), "%T", "GetChatTag",LANG_SERVER);
	Format(getownchat, sizeof(getownchat), "%T", "GetOwnChat",LANG_SERVER);
	Format(getmoney, sizeof(getmoney), "%T", "GetMoney",LANG_SERVER, vipcash);
	Format(getholy, sizeof(getholy), "%T", "GetHoly",LANG_SERVER);
	Format(getslot, sizeof(getslot), "%T", "GetSlot",LANG_SERVER);
	Format(gettag, sizeof(gettag), "%T", "GetTag",LANG_SERVER, stammtag);
	Format(getjoin, sizeof(getjoin), "%T", "GetJoin",LANG_SERVER);
	Format(getwelcome, sizeof(getwelcome), "%T", "GetWelcome",LANG_SERVER);
	Format(getleave, sizeof(getleave), "%T", "GetLeave",LANG_SERVER);	
	Format(btext, sizeof(btext), "%T", "Bronze",LANG_SERVER);
	Format(stext, sizeof(stext), "%T", "Silver",LANG_SERVER);
	Format(gtext, sizeof(gtext), "%T", "Gold",LANG_SERVER);
	Format(ptext, sizeof(ptext), "%T", "Platinum",LANG_SERVER);
	Format(back, sizeof(back), "%T", "Back", LANG_SERVER);
	
	credits = CreatePanel();
	info = CreatePanel();
	cmdlist = CreatePanel();
	adminpanel = CreatePanel();
	resetpanel = CreatePanel();
	
	featurelist = CreateMenu(FeatureHandler);
	
	SetPanelTitle(resetpanel, reset_list);
	DrawPanelText(resetpanel, "---------------------------");
	DrawPanelItem(resetpanel, resetit);
	DrawPanelText(resetpanel, "---------------------------");
	DrawPanelItem(resetpanel, close);
	
	SetMenuTitle(featurelist, "%T", "HaveFeatures", LANG_SERVER);
	
	if (stamm_level == 0)
	{	
		if (enable_models) AddMenuItem(featurelist, "1", getskin);
		if (autochat) AddMenuItem(featurelist, "2", getchattag);
		if (own_chat) AddMenuItem(featurelist, "3", getownchat);		
		if (vipcash && !IsTF) AddMenuItem(featurelist, "4", getmoney);	
		if (enable_holy_grenade && !IsTF) AddMenuItem(featurelist, "5", getholy);
		if (enable_vip_slot) AddMenuItem(featurelist, "6", getslot);	
		if (stamm_tag_on_off) AddMenuItem(featurelist, "7", gettag);
		if (!StrEqual(vip_joinsound, "0")) AddMenuItem(featurelist, "8", getjoin);
		if (vip_chatwelcome) AddMenuItem(featurelist, "9", getwelcome);
		if (vip_chatgoodbye) AddMenuItem(featurelist, "10", getleave);
	}
	if (stamm_level == 1)
	{
		if (enable_models) 
		{
			decl String:featuretext[128];
			
			if (levels[FEATURE_MODEL] == 1) Format(featuretext, sizeof(featuretext), "%s (%s)", getskin, btext);
			if (levels[FEATURE_MODEL] == 2) Format(featuretext, sizeof(featuretext), "%s (%s)", getskin, stext);
			if (levels[FEATURE_MODEL] == 3) Format(featuretext, sizeof(featuretext), "%s (%s)", getskin, gtext);
			if (levels[FEATURE_MODEL] == 4) Format(featuretext, sizeof(featuretext), "%s (%s)", getskin, ptext);
			
			AddMenuItem(featurelist, "1", featuretext);
		}
		if (autochat) 
		{
			decl String:featuretext[128];
			
			if (levels[FEATURE_CHAT] == 1) Format(featuretext, sizeof(featuretext), "%s (%s)", getchattag, btext);
			if (levels[FEATURE_CHAT] == 2) Format(featuretext, sizeof(featuretext), "%s (%s)", getchattag, stext);
			if (levels[FEATURE_CHAT] == 3) Format(featuretext, sizeof(featuretext), "%s (%s)", getchattag, gtext);
			if (levels[FEATURE_CHAT] == 4) Format(featuretext, sizeof(featuretext), "%s (%s)", getchattag, ptext);
			
			AddMenuItem(featurelist, "2", featuretext);
		}
		if (own_chat)
		{
			decl String:featuretext[128];
			
			if (levels[FEATURE_VIPCHAT] == 1) Format(featuretext, sizeof(featuretext), "%s (%s)", getownchat, btext);
			if (levels[FEATURE_VIPCHAT] == 2) Format(featuretext, sizeof(featuretext), "%s (%s)", getownchat, stext);
			if (levels[FEATURE_VIPCHAT] == 3) Format(featuretext, sizeof(featuretext), "%s (%s)", getownchat, gtext);
			if (levels[FEATURE_VIPCHAT] == 4) Format(featuretext, sizeof(featuretext), "%s (%s)", getownchat, ptext);
			
			AddMenuItem(featurelist, "3", featuretext);
		}
		if (vipcash && !IsTF) 
		{
			decl String:featuretext[128];
			
			if (levels[FEATURE_MONEY] == 1) Format(featuretext, sizeof(featuretext), "%s (%s)", getmoney, btext);
			if (levels[FEATURE_MONEY] == 2) Format(featuretext, sizeof(featuretext), "%s (%s)", getmoney, stext);
			if (levels[FEATURE_MONEY] == 3) Format(featuretext, sizeof(featuretext), "%s (%s)", getmoney, gtext);
			if (levels[FEATURE_MONEY] == 4) Format(featuretext, sizeof(featuretext), "%s (%s)", getmoney, ptext);
			
			AddMenuItem(featurelist, "4", featuretext);
		}
		if (enable_holy_grenade && !IsTF) 
		{
			decl String:featuretext[128];
			
			if (levels[FEATURE_HOLY] == 1) Format(featuretext, sizeof(featuretext), "%s (%s)", getholy, btext);
			if (levels[FEATURE_HOLY] == 2) Format(featuretext, sizeof(featuretext), "%s (%s)", getholy, stext);
			if (levels[FEATURE_HOLY] == 3) Format(featuretext, sizeof(featuretext), "%s (%s)", getholy, gtext);
			if (levels[FEATURE_HOLY] == 4) Format(featuretext, sizeof(featuretext), "%s (%s)", getholy, ptext);
			
			AddMenuItem(featurelist, "5", featuretext);
		}
		if (enable_vip_slot) 
		{
			decl String:featuretext[128];
			
			if (levels[FEATURE_SLOT] == 1) Format(featuretext, sizeof(featuretext), "%s (%s)", getslot, btext);
			if (levels[FEATURE_SLOT] == 2) Format(featuretext, sizeof(featuretext), "%s (%s)", getslot, stext);
			if (levels[FEATURE_SLOT] == 3) Format(featuretext, sizeof(featuretext), "%s (%s)", getslot, gtext);
			if (levels[FEATURE_SLOT] == 4) Format(featuretext, sizeof(featuretext), "%s (%s)", getslot, ptext);
			
			AddMenuItem(featurelist, "6", featuretext);
		}
		if (stamm_tag_on_off) 
		{
			decl String:featuretext[128];
			
			if (levels[FEATURE_TAG] == 1) Format(featuretext, sizeof(featuretext), "%s (%s)", gettag, btext);
			if (levels[FEATURE_TAG] == 2) Format(featuretext, sizeof(featuretext), "%s (%s)", gettag, stext);
			if (levels[FEATURE_TAG] == 3) Format(featuretext, sizeof(featuretext), "%s (%s)", gettag, gtext);
			if (levels[FEATURE_TAG] == 4) Format(featuretext, sizeof(featuretext), "%s (%s)", gettag, ptext);
			
			AddMenuItem(featurelist, "7", featuretext);
		}
		if (!StrEqual(vip_joinsound, "0"))
		{
			decl String:featuretext[128];
			
			if (levels[FEATURE_JOINSOUND] == 1) Format(featuretext, sizeof(featuretext), "%s (%s)", getjoin, btext);
			if (levels[FEATURE_JOINSOUND] == 2) Format(featuretext, sizeof(featuretext), "%s (%s)", getjoin, stext);
			if (levels[FEATURE_JOINSOUND] == 3) Format(featuretext, sizeof(featuretext), "%s (%s)", getjoin, gtext);
			if (levels[FEATURE_JOINSOUND] == 4) Format(featuretext, sizeof(featuretext), "%s (%s)", getjoin, ptext);
			
			AddMenuItem(featurelist, "8", featuretext);
		}
		if (vip_chatwelcome)
		{
			decl String:featuretext[128];
			
			if (levels[FEATURE_WELCOME] == 1) Format(featuretext, sizeof(featuretext), "%s (%s)", getwelcome, btext);
			if (levels[FEATURE_WELCOME] == 2) Format(featuretext, sizeof(featuretext), "%s (%s)", getwelcome, stext);
			if (levels[FEATURE_WELCOME] == 3) Format(featuretext, sizeof(featuretext), "%s (%s)", getwelcome, gtext);
			if (levels[FEATURE_WELCOME] == 4) Format(featuretext, sizeof(featuretext), "%s (%s)", getwelcome, ptext);
		
			AddMenuItem(featurelist, "9", featuretext);
		}
		if (vip_chatgoodbye) 
		{
			decl String:featuretext[128];
			
			if (levels[FEATURE_LEAVE] == 1) Format(featuretext, sizeof(featuretext), "%s (%s)", getleave, btext);
			if (levels[FEATURE_LEAVE] == 2) Format(featuretext, sizeof(featuretext), "%s (%s)", getleave, stext);
			if (levels[FEATURE_LEAVE] == 3) Format(featuretext, sizeof(featuretext), "%s (%s)", getleave, gtext);
			if (levels[FEATURE_LEAVE] == 4) Format(featuretext, sizeof(featuretext), "%s (%s)", getleave, ptext);
			
			AddMenuItem(featurelist, "10", featuretext);
		}
	}
	
	AddMenuItem(featurelist, "back", back);
	
	SetPanelTitle(adminpanel, AdminMenuText);
	DrawPanelText(adminpanel, "----------------------------------------------------");
	if (StrEqual(vip_type, "kills")) DrawPanelItem(adminpanel, KPoints);
	if (StrEqual(vip_type, "time")) DrawPanelItem(adminpanel, TPoints);
	if (StrEqual(vip_type, "rounds")) DrawPanelItem(adminpanel, RPoints);
	DrawPanelItem(adminpanel, resetplayertext);
	DrawPanelItem(adminpanel, resetdbtext);
	DrawPanelItem(adminpanel, happyhourtext);
	DrawPanelItem(adminpanel, updatetext);
	DrawPanelText(adminpanel, "----------------------------------------------------");
	DrawPanelItem(adminpanel, close);
	
	
	SetPanelTitle(cmdlist, stammcmds);
	DrawPanelText(cmdlist, "-------------------------------------------");
	DrawPanelItem(cmdlist, stammcmd);
	DrawPanelItem(cmdlist, srankcmd);
	DrawPanelItem(cmdlist, stopcmd);
	if (model_change && same_models) DrawPanelItem(cmdlist, modelchangecmd);
	if (allow_change) DrawPanelItem(cmdlist, changecmd);
	DrawPanelText(cmdlist, "-------------------------------------------");
	DrawPanelItem(cmdlist, back);
	DrawPanelItem(cmdlist, close);
	
	SetPanelTitle(credits, "Stamm Credits");
	DrawPanelText(credits, "-------------------------------------------");
	DrawPanelText(credits, "Author:");
	DrawPanelItem(credits, "Stamm Author is Popoklopsi");
	DrawPanelText(credits, "-------------------------------------------");
	DrawPanelText(credits, "Official Stamm Page: http://www.pup-board.de");
	DrawPanelText(credits, "-------------------------------------------");
	DrawPanelText(credits, "Stamm Beta Testers:");
	DrawPanelText(credits, "-------------------------------------------");
	DrawPanelItem(credits, "Billy1987, nukke, -D!ce-");
	DrawPanelItem(credits, "yumpschtyle, Xabot, SachsenHorst");
	DrawPanelItem(credits, "goranche, GGF_Morpheus, Lucker");
	DrawPanelItem(credits, "Poledis, Commi, pup-board.de");
	DrawPanelText(credits, "-------------------------------------------");
	DrawPanelItem(credits, back);
	DrawPanelItem(credits, close);
	
	
	decl String:stammtagtext[256];
	
	Format(stammtagtext, sizeof(stammtagtext), "Stamm Tag: %s", stammtag);
	
	SetPanelTitle(info, "Stamm by Popoklopsi");
	DrawPanelText(info, "Visit http://www.pup-board.de");
	DrawPanelText(info, "-------------------------------------------");
	DrawPanelText(info, stammtagtext);
	DrawPanelText(info, TagInfo);
	DrawPanelText(info, "-------------------------------------------");
	DrawPanelItem(info, stammfts);
	DrawPanelItem(info, stammcmds);
	DrawPanelItem(info, "Credits");
	DrawPanelText(info, "-------------------------------------------");
	DrawPanelText(info, "Official Page");
	DrawPanelText(info, "http://www.pup-board.de");
	DrawPanelText(info, "-------------------------------------------");
	DrawPanelItem(info, close);
}

DownloadHoly()
{
	AddFileToDownloadsTable("sound/stamm/throw1.wav");
	AddFileToDownloadsTable("sound/stamm/explode1.wav");
	AddFileToDownloadsTable("materials/holy_grenade/holy_grenade.vtf");
	AddFileToDownloadsTable("models/holy_grenade/holy_grenade.mdl");
	AddFileToDownloadsTable("models/holy_grenade/holy_grenade.xbox.vtx");
	AddFileToDownloadsTable("materials/holy_grenade/holy_grenade.vmt");
	AddFileToDownloadsTable("models/holy_grenade/holy_grenade.vvd");
	AddFileToDownloadsTable("models/holy_grenade/holy_grenade.sw.vtx");
	AddFileToDownloadsTable("models/holy_grenade/holy_grenade.phy");
	AddFileToDownloadsTable("models/holy_grenade/holy_grenade.dx80.vtx");
	AddFileToDownloadsTable("models/holy_grenade/holy_grenade.dx90.vtx");
}

DownloadLevel()
{
	decl String:downloadfile[257];
	
	Format(downloadfile, sizeof(downloadfile), "sound/%s", lvl_up_sound);
	
	AddFileToDownloadsTable(downloadfile);
}

DownloadJoin()
{
	decl String:downloadfile[257];
	
	Format(downloadfile, sizeof(downloadfile), "sound/%s", vip_joinsound);
	
	AddFileToDownloadsTable(downloadfile);
}

/* Natives */

public Native_GetClientStammPoints(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	if (client && !IsClientBot(client) && IsClientInGame(client)) return playerpoints[client];
	else
	{
		ThrowNativeError(1, "[ Stamm ] Client is invalid, bot or not connected!");
		return -1;
	}
}

public Native_GetStammLevels(Handle:plugin, numParams)
{
	new type = GetNativeCell(1);
	
	if (!type) return points_to_become_vip;
	
	if (type == 1)
	{
		if (!stamm_level)
		{
			ThrowNativeError(2, "[ Stamm ] Stamm Level is OFF!");
			return -1;
		}
		
		return stamm_bronze;
	}
	
	if (type == 2)
	{
		if (!stamm_level)
		{
			ThrowNativeError(2, "[ Stamm ] Stamm Level is OFF!");
			return -1;
		}
		
		return stamm_silver;
	}
	
	if (type == 3)
	{
		if (!stamm_level)
		{
			ThrowNativeError(2, "[ Stamm ] Stamm Level is OFF!");
			return -1;
		}
		
		return stamm_gold;
	}
	
	if (type == 4)
	{
		if (!stamm_level)
		{
			ThrowNativeError(2, "[ Stamm ] Stamm Level is OFF!");
			return -1;
		}
		
		return stamm_platinum;
	}

	return -1;
}

public Native_GetStammType(Handle:plugin, numParams)
{
	if (StrEqual(vip_type, "kills")) return 1;
	if (StrEqual(vip_type, "rounds")) return 2;
	if (StrEqual(vip_type, "time")) return 3;
	
	return 0;
}

public Native_SetClientStammPoints(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	new pointschange = GetNativeCell(2);
	
	if (client && !IsClientBot(client) && IsClientInGame(client)) 
	{
		if (pointschange >= 0)
		{
			playerpoints[client] = pointschange;
			CheckVip(client);
		}
		else ThrowNativeError(2, "[ Stamm ] The Number of Points to set is invalid!");	
	}
	else ThrowNativeError(1, "[ Stamm ] Client is invalid, bot or not connected!");
	
}

public Native_AddClientStammPoints(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	new pointschange = GetNativeCell(2);
	
	if (client && !IsClientBot(client) && IsClientInGame(client)) 
	{
		if (pointschange > 0)
		{
			playerpoints[client] = playerpoints[client] + pointschange;
			PublicPlayerGetPoints(client, pointschange);
			CheckVip(client);
		}
		else ThrowNativeError(2, "[ Stamm ] The Number of Points to add is invalid!");
		
	}
	else ThrowNativeError(1, "[ Stamm ] Client is invalid, bot or not connected!");
	
}

public Native_DelClientStammPoints(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	new pointschange = GetNativeCell(2);
	
	if (client && !IsClientBot(client) && IsClientInGame(client)) 
	{
		if (pointschange > 0)
		{
			playerpoints[client] = playerpoints[client] - pointschange;
			if (playerpoints[client] < 0) playerpoints[client] = 0;
			PublicPlayerGetPoints(client, pointschange*-1);
			CheckVip(client);
		}
		else ThrowNativeError(2, "[ Stamm ] The Number of Points to delete is invalid!");	
	}
	else ThrowNativeError(1, "[ Stamm ] Client is invalid, bot or not connected!");
	
}

public Native_IsClientVip(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	new type = GetNativeCell(2);
	new bool:min = GetNativeCell(3);
	
	if (client && !IsClientBot(client) && IsClientInGame(client)) 
	{
		if (!type)
		{
			if (playervip[client]) return true;
			else return false;
		}
		
		if (type == 1)
		{
			if (!stamm_level)
			{
				ThrowNativeError(2, "[ Stamm ] Stamm Level is OFF!");
				return false;
			}
			if (min)
			{
				if (playerlevel[client] > 0) return true;
				else return false;
			}
			else
			{
				if (playerlevel[client] == 1) return true;
				else return false;
				
			}
		}
		
		if (type == 2)
		{
			if (!stamm_level)
			{
				ThrowNativeError(2, "[ Stamm ] Stamm Level is OFF!");
				return false;
			}
			if (min)
			{
				if (playerlevel[client] > 1) return true;
				else return false;
				
			}
			else
			{
				if (playerlevel[client] == 2) return true;
				else return false;
			}
		}
		
		if (type == 3)
		{
			if (!stamm_level)
			{
				ThrowNativeError(2, "[ Stamm ] Stamm Level is OFF!");
				return false;
			}
			if (min)
			{
				if (playerlevel[client] > 2) return true;
				else return false;
			}
			else
			{
				if (playerlevel[client] == 3) return true;
				else return false;
				
			}
		}
		
		if (type == 4)
		{
			if (!stamm_level)
			{
				ThrowNativeError(2, "[ Stamm ] Stamm Level is OFF!");
				return false;
			}
			if (playerlevel[client] == 4) return true;
			else return false;
		}
	}
	
	return false;
}

public Native_IsStammLevelOn(Handle:plugin, numParams)
{
	if (stamm_level) return true;
	else return false;
}

stock ClearTimer(&Handle:timer, bool:autoClose=false)
{
	if(timer != INVALID_HANDLE)
		KillTimer(timer, autoClose);
	timer = INVALID_HANDLE;
}