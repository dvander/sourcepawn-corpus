#include <sourcemod>
#include <tf2_stocks>
#include <colors>
#undef REQUIRE_PLUGIN

#tryinclude <updater>

#define PLUGIN_VERSION "2.7.1"
#define UPDATE_URL "https://giovanifsa.jhost.org/images/sampledata/plugins/powerups/update.txt"

//***********************************************
//*					SOUNDS						*
//***********************************************

#define SOUND_RESPAWN "weapons/teleporter_send.wav"
#define SOUND_UBERON "player/invulnerable_on.wav"
#define SOUND_UBEROFF "player/invulnerable_off.wav"
#define SOUND_CRITICALS "items/powerup_pickup_uber.wav"
#define SOUND_BIMU "items/powerup_pickup_resistance.wav"
#define SOUND_BUFF "items/powerup_pickup_agility.wav"
#define SOUND_REGEN "items/regenerate.wav"
#define SOUND_SLOWED "vo/heavy_jeers02.mp3"
#define SOUND_BLEED "player/pain.wav"
#define SOUND_IAMMO "vo/taunts/heavy_taunts03.mp3"

//Class specific sounds
#define SOUND_SUICIDE_SCOUT "vo/scout_paincrticialdeath02.mp3"
#define SOUND_SUICIDE_SOLDIER "vo/soldier_paincrticialdeath01.mp3"
#define SOUND_SUICIDE_PYRO "vo/pyro_paincrticialdeath02.mp3"
#define SOUND_SUICIDE_DEMOMAN "vo/demoman_paincrticialdeath04.mp3"
#define SOUND_SUICIDE_HEAVY "vo/heavy_paincrticialdeath03.mp3"
#define SOUND_SUICIDE_ENGINEER "vo/engineer_paincrticialdeath02.mp3"
#define SOUND_SUICIDE_MEDIC "vo/medic_paincrticialdeath01.mp3"
#define SOUND_SUICIDE_SNIPER "vo/sniper_paincrticialdeath01.mp3"
#define SOUND_SUICIDE_SPY "vo/spy_paincrticialdeath03.mp3"

//***********************************************
//*				WEAPON INDEX DEFINES			*
//***********************************************

#define ITEM_CRUZADERS 305
#define ITEM_CRUZADERS_FESTIVE 1079
#define ITEM_MANGLER 441
#define ITEM_BISON 442
#define ITEM_POMSON 588

//***********************************************
//*					GLOBAL VARS					*
//***********************************************

//Prefix
new String:PLUGIN_PREFIX[32];
new String:PLUGIN_PREFIX_NOCOLOR[32];

//Handles
new Handle:message_time; 
new Handle:ismessageon;
new Handle:client_points; 
new Handle:points_time; 
new Handle:waittime;
new Handle:randompower_IsOn;
static String:KVPath[PLATFORM_MAX_PATH];
new Handle:plugin_message[MAXPLAYERS+1];
new Handle:client_spawn;
new Handle:client_spawn_bad;

//Powerup Costs and timers
new Handle:luck_cost;
new Handle:respawn_cost;
new Handle:uber_cost; 
new Handle:criticals_cost; 
new Handle:bimu_cost; 
new Handle:buff_cost; 
new Handle:regen_cost;
new Handle:uber_time; 
new Handle:criticals_time; 
new Handle:bimu_time; 
new Handle:buff_time;
new Handle:badeffect_time;
new Handle:iammo_cost;
new Handle:iammo_time;

//Client Timers and vars
new Handle:client_givepointstimer[MAXPLAYERS+1];
new bool:ClientIsConnected[MAXPLAYERS+1];

//Offsets
new g_speed;
new g_Itemdef;
new g_ClipOffset;
new g_AmmoOffset;

//Vars to check if the player have the active powerup.
new uber_active[MAXPLAYERS+1];
new critical_active[MAXPLAYERS+1];
new bimu_active[MAXPLAYERS+1];
new buff_active[MAXPLAYERS+1];
new slowed_active[MAXPLAYERS+1];
new bleeding_active[MAXPLAYERS+1];
new bleeding_sum[MAXPLAYERS+1];
new slowed_sum[MAXPLAYERS+1];
new iammo_active[MAXPLAYERS+1];

//Stores the real clip size of the weapon for use in Unlimited Ammo
new WeaponClipCache[MAXPLAYERS+1];
new WeaponClipCache_Secondary[MAXPLAYERS+1];

//Client handles for powerup timers
new Handle:powerup_handle_uber[MAXPLAYERS+1];
new Handle:powerup_handle_criticals[MAXPLAYERS+1];
new Handle:powerup_handle_bimu[MAXPLAYERS+1];
new Handle:powerup_handle_buff[MAXPLAYERS+1];
new Handle:powerup_handle_slowed[MAXPLAYERS+1];
new Handle:powerup_handle_bleeding[MAXPLAYERS+1];
new Handle:powerup_handle_iammo[MAXPLAYERS+1];
new Handle:powerup_handle_iammo2[MAXPLAYERS+1];

new Handle:Autoupdater_handle;
//***********************************************


public Plugin:myinfo = {
	name = "[TF2] Powerups",
	author = "Nescau",
	description = "Buy powerups using points.",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/nescaufsa/"
};

public OnPluginStart()
{
	//***********************************************
	//*			COMMANDS, TESTS AND CFG				*
	//***********************************************
	BuildPath(Path_SM, KVPath, sizeof(KVPath), "data/powerups.txt"); 
	AutoExecConfig(true, "powerups");
	
	CheckFiles();
	
	LoadTranslations("common.phrases");
	LoadTranslations("powerups.phrases");
	RegConsoleCmd("sm_powerups", POWERUPS, "Powerups menu");
	RegAdminCmd("sm_forcepowerup", FORCEPOWERUP, ADMFLAG_ROOT, "Force a powerup on someone");
	RegAdminCmd("sm_addpoints", ADDPOINTS, ADMFLAG_ROOT, "Add points to someone");
	RegAdminCmd("sm_removepoints", RPOINTS, ADMFLAG_ROOT, "Remove points from someone");
	
	//***********************************************
	//*					CVARS						*
	//***********************************************
	client_spawn = CreateConVar("pp_death_keep", "1", "If the client dies with an active powerup, letting this ConVar active (1) will make the player respawn with the powerup");
	client_spawn_bad = CreateConVar("pp_death_keep_bad", "0", "If the client dies with an bad effect, he will respawn with it?", FCVAR_NOTIFY);
	client_points = CreateConVar("pp_points", "1", "Define here how much points will be given to the client", FCVAR_NOTIFY);
	points_time = CreateConVar("pp_points_givetime", "1800", "Define here the time to give points to the client.", FCVAR_NOTIFY);
	waittime = CreateConVar("pp_wait_time", "300", "Time the client will need to wait to buy another Powerup", FCVAR_NOTIFY);
	ismessageon = CreateConVar("pp_showmessages", "1", "Will the plugin show chat advertisements?", FCVAR_NOTIFY);
	message_time = CreateConVar("pp_message_time", "300", "Time to show chat advertisements.", FCVAR_NOTIFY);
	randompower_IsOn = CreateConVar("pp_randompower_on", "1", "Defines if the players will be able to buy random powerups in Test your luck", FCVAR_NOTIFY);
	
	//***********************************************
	//*				POWERUPS COST AND TIME			*
	//***********************************************
	luck_cost = CreateConVar("pp_luckcost", "1", "Points Reduction: Test your luck Cost", FCVAR_NOTIFY);
	respawn_cost = CreateConVar("pp_respawn_cost", "1", "Points Reduction: Respawn Cost", FCVAR_NOTIFY);
	uber_cost = CreateConVar("pp_uber_cost", "3", "Points Reduction: Ubercharge Cost", FCVAR_NOTIFY);
	uber_time = CreateConVar("pp_uber_time", "60", "Seconds to remove Ubercharge powerup from the client.", FCVAR_NOTIFY);
	criticals_cost = CreateConVar("pp_criticals_cost", "2", "Points Reduction: Criticals Cost", FCVAR_NOTIFY);
	criticals_time = CreateConVar("pp_criticals_time", "60", "Seconds to remove Criticals powerup from the client.", FCVAR_NOTIFY);
	bimu_cost = CreateConVar("pp_bimu_cost", "2", "Points Reduction: Bullet Immunity Cost", FCVAR_NOTIFY);
	bimu_time = CreateConVar("pp_bimu_time", "60", "Seconds to remove Bullet Immunity powerup from the client.", FCVAR_NOTIFY);
	buff_cost = CreateConVar("pp_buff_cost", "2", "Points Reduction: Buff Cost", FCVAR_NOTIFY);
	buff_time = CreateConVar("pp_buff_time", "60", "Seconds to remove Buff powerup from the client.", FCVAR_NOTIFY);
	regen_cost = CreateConVar("pp_regen_cost", "2", "Points Reduction: Instant Regeneration Cost", FCVAR_NOTIFY);
	iammo_cost = CreateConVar("pp_iammo_cost", "3", "Defines the cost of the Infinite Amoo powerup.", FCVAR_NOTIFY);
	iammo_time = CreateConVar("pp_iammo_time", "60", "Defines how much time the player will have Infinite Ammo", FCVAR_NOTIFY);
	badeffect_time = CreateConVar("pp_badeffect_time", "20", "Defines bad effects time.", FCVAR_NOTIFY);
	
	//***********************************************
	//*				PREFIX AND UPDATER				*
	//***********************************************
	Format(PLUGIN_PREFIX, 32, "%T", "Prefix", LANG_SERVER);
	Format(PLUGIN_PREFIX_NOCOLOR, 32, "%T", "PrefixNocolor", LANG_SERVER);
	
	#if defined _updater_included
		if (LibraryExists("updater"))
		{
			Updater_AddPlugin(UPDATE_URL);
		}
	#endif
	
	//***********************************************
	//*				EVENTS AND OFFSETS 				*
	//***********************************************
	HookEvent("player_spawn", PLAYER_SPAWNED);
	LookupOffset(g_speed, "CTFPlayer", "m_flMaxspeed");
	LookupOffset(g_Itemdef, "CBaseCombatWeapon", "m_iItemDefinitionIndex");
	LookupOffset(g_ClipOffset, "CTFWeaponBase", "m_iClip1");
	LookupOffset(g_AmmoOffset, "CTFPlayer","m_iAmmo");
	
	//***********************************************
	//*	CHECK IF THERE'S ALREADY PLAYERS CONNECTED 	*
	//***********************************************
	CheckForPlayersInGame();
}

//***********************************************
//*					PRECACHES					*
//***********************************************

public OnMapStart()
{
	PrecacheSound(SOUND_RESPAWN);
	PrecacheSound(SOUND_UBERON);
	PrecacheSound(SOUND_UBEROFF);
	PrecacheSound(SOUND_CRITICALS);
	PrecacheSound(SOUND_BIMU);
	PrecacheSound(SOUND_BUFF);
	PrecacheSound(SOUND_REGEN);
	PrecacheSound(SOUND_SLOWED);
	PrecacheSound(SOUND_BLEED);
	PrecacheSound(SOUND_IAMMO);
	
	PrecacheSound(SOUND_SUICIDE_SCOUT);
	PrecacheSound(SOUND_SUICIDE_SOLDIER);
	PrecacheSound(SOUND_SUICIDE_PYRO);
	PrecacheSound(SOUND_SUICIDE_DEMOMAN);
	PrecacheSound(SOUND_SUICIDE_HEAVY);
	PrecacheSound(SOUND_SUICIDE_ENGINEER);
	PrecacheSound(SOUND_SUICIDE_MEDIC);
	PrecacheSound(SOUND_SUICIDE_SNIPER);
	PrecacheSound(SOUND_SUICIDE_SPY);
}

//***********************************************
//*					UPDATER 					*
//***********************************************

public OnLibraryAdded(const String:name[])
{
	#if defined _updater_included
		if (StrEqual(name, "updater"))
		{
			Updater_AddPlugin(UPDATE_URL);
		}
	#endif
}

#if defined _updater_included

public Updater_OnPluginUpdated()
{
	new c = 0;
	Autoupdater_handle = CreateTimer(30.0, CheckActivePowerups, c, TIMER_REPEAT);
}

public Action:CheckActivePowerups(Handle:updater_timer, any:variable)
{
	new bool:active = false;
	for (new a = 1;a <= MaxClients;a++)
	{
		if (uber_active[a] == 1 || 
		critical_active[a] == 1 || 
		bimu_active[a] == 1 || 
		buff_active[a] == 1 || 
		slowed_active[a] == 1 || 
		bleeding_active[a] == 1 || 
		iammo_active[a] == 1)
		{
			active = true;
		}
	}
	
	if (!active)
	{
		RestartPluginNow();
	}
}

public RestartPluginNow()
{
	KillTimer(Autoupdater_handle);
	ReloadPlugin();
}

#endif

//***********************************************
//*				CLEAR PLAYER VARS				*
//***********************************************

public OnClientDisconnect(client)
{
	ExecDisconnect(client);
}

public ExecDisconnect(client)
{
	if ((ClientIsConnected[client])&& (client <= MaxClients))
	{
		ClientIsConnected[client] = false;
		KillTimer(client_givepointstimer[client]);
		if (plugin_message[client] != INVALID_HANDLE)
		{
			KillTimer(plugin_message[client]);
		}
		if (uber_active[client] == 1)
		{
			KillTimer(powerup_handle_uber[client]);
			TF2_RemoveCondition(client, TFCond_UberchargedCanteen);
			uber_active[client] = 0;
		}
		if (critical_active[client] == 1)
		{
			KillTimer(powerup_handle_criticals[client]);
			TF2_RemoveCondition(client, TFCond_CritCanteen);
			critical_active[client] = 0;
		}
		if (bimu_active[client] == 1)
		{
			KillTimer(powerup_handle_bimu[client]);
			TF2_RemoveCondition(client, TFCond_BulletImmune);
			bimu_active[client] = 0;
		}
		if (buff_active[client] == 1)
		{
			KillTimer(powerup_handle_buff[client]);
			TF2_RemoveCondition(client, TFCond_RegenBuffed);
			buff_active[client] = 0;
		}
		if (slowed_active[client] == 1)
		{
			KillTimer(powerup_handle_slowed[client]);
			slowed_active[client] = 0;
			slowed_sum[client] = 0;
		}
		if (bleeding_active[client == 1])
		{
			KillTimer(powerup_handle_bleeding[client]);
			bleeding_active[client] = 0;
			bleeding_sum[client] = 0;
		}
		if  (iammo_active[client] == 1)
		{
			KillTimer(powerup_handle_iammo[client]);
			KillTimer(powerup_handle_iammo2[client]);
			ResetWeaponClipCache(client);
			iammo_active[client] = 0;
		}
	}
}

public OnPluginEnd()
{
	for (new b = 1;b <= MaxClients;b++)
	{
		if (IsClientInGame(b))
		{
			ExecDisconnect(b);
		}
	}
}

//***********************************************
//*				PLAYER SPAWN CODE				*
//***********************************************

public Action:PLAYER_SPAWNED(Handle:event, const String:name[], bool:dontBroadcast)
{
	new bool:IsOn = GetConVarBool(client_spawn);
	new bool:IsOn2 = GetConVarBool(client_spawn_bad);
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsOn)
	{
		if (uber_active[client] == 1)
		{
			TF2_AddCondition(client, TFCond_UberchargedCanteen, TFCondDuration_Infinite);
		}
		if (critical_active[client] == 1)
		{
			TF2_AddCondition(client, TFCond_CritCanteen, TFCondDuration_Infinite);
		}
		if (bimu_active[client] == 1)
		{
			TF2_AddCondition(client, TFCond_BulletImmune, TFCondDuration_Infinite);
		}
		if (buff_active[client] == 1)
		{
			TF2_AddCondition(client, TFCond_RegenBuffed, TFCondDuration_Infinite);
		}
		if  (iammo_active[client] == 1)
		{
			SaveWeaponClipCache(client);
		}
	} else {
		if (uber_active[client] == 1)
		{
			KillTimer(powerup_handle_uber[client]);
			TF2_RemoveCondition(client, TFCond_UberchargedCanteen);
			uber_active[client] = 0;
		}
		if (critical_active[client] == 1)
		{
			KillTimer(powerup_handle_criticals[client]);
			TF2_RemoveCondition(client, TFCond_CritCanteen);
			critical_active[client] = 0;
		}
		if (bimu_active[client] == 1)
		{
			KillTimer(powerup_handle_bimu[client]);
			TF2_RemoveCondition(client, TFCond_BulletImmune);
			bimu_active[client] = 0;
		}
		if (buff_active[client] == 1)
		{
			KillTimer(powerup_handle_buff[client]);
			TF2_RemoveCondition(client, TFCond_RegenBuffed);
			buff_active[client] = 0;
		}
		if  (iammo_active[client] == 1)
		{
			KillTimer(powerup_handle_iammo[client]);
			KillTimer(powerup_handle_iammo2[client]);
			ResetWeaponClipCache(client);
			iammo_active[client] = 0;
		}
	}
	if (IsOn2)
	{
		//Nothing here yet
	} else {
		if (slowed_active[client] == 1)
		{
			KillTimer(powerup_handle_slowed[client]);
			slowed_active[client] = 0;
			slowed_sum[client] = 0;
		}
		if (bleeding_active[client == 1])
		{
			KillTimer(powerup_handle_bleeding[client]);
			bleeding_active[client] = 0;
			bleeding_sum[client] = 0;
		}
	}
}

//***********************************************
//*				TRANSLATIONS CHECK				*
//***********************************************

public CheckFiles()
{
	new String:sTranslationsMain_Path[PLATFORM_MAX_PATH];
	new String:sCommonPhrasesMain_Path[PLATFORM_MAX_PATH];
	new String:sTranslationsPT_Path[PLATFORM_MAX_PATH];
	new AdditionalTranslationsNotFound;
	
	BuildPath(Path_SM, sTranslationsMain_Path, sizeof(sTranslationsMain_Path), "translations/powerups.phrases.txt");
	BuildPath(Path_SM, sCommonPhrasesMain_Path, sizeof(sCommonPhrasesMain_Path), "translations/common.phrases.txt");
	BuildPath(Path_SM, sTranslationsPT_Path, sizeof(sTranslationsPT_Path), "translations/pt/powerups.phrases.txt");
	
	PrintToServer("\n******************* Running [TF2]Powerups files existance test *******************");
	
	if (FileExists(KVPath))
	{
		PrintToServer("*[PP] Plugin data file exists...");
	} else {
		PrintToServer("*[PP] Plugin data file not found, maybe it's being created...");
	}
	
	if (FileExists(sTranslationsMain_Path))
	{
		PrintToServer("*[PP] Main translation file found...")
	} else {
		SetFailState("*[PP] Main translation file not found, plugin cannot start.");
	}
	
	if (!FileExists(sCommonPhrasesMain_Path))
	{
		PrintToServer("*[PP] Translation file common.phrases.txt not found, this may cause plugin errors.");
		AdditionalTranslationsNotFound++;
	}
	
	if (!FileExists(sTranslationsPT_Path))
	{
		AdditionalTranslationsNotFound++;
	}
	
	if (AdditionalTranslationsNotFound > 0)
	{
		PrintToServer("*[TF2]Powerups files existence test found problems: %d additional translation file(s) doesn't exist.",AdditionalTranslationsNotFound);
	} else {
		PrintToServer("******************* [TF2]Powerups files existence test finished, no problems found! *******************\n");
	}
}

//***********************************************
//*			WHEN A PLAYER CONNECTS				*
//***********************************************

public OnClientPostAdminCheck(client)
{
	PutPlayerInPointsQueue(client);
}

public PutPlayerInPointsQueue(client)
{
	if (client <= MaxClients)
	{
		ClientIsConnected[client] = true;
		new bool:IsOn;
		IsOn = GetConVarBool(ismessageon);
		if (IsOn)
		{
			new String:message[256];
			Format(message, 256, "%T", "ConnectMSG", LANG_SERVER, PLUGIN_PREFIX);
			
			CPrintToChat(client, message);
			new Float:time = float(GetConVarInt(message_time));
			plugin_message[client] = CreateTimer(time, TIMER_CLIENTMESSAGE, client, TIMER_REPEAT);
		} else {
			plugin_message[client] = INVALID_HANDLE;
		}
		new Float:pointstime = float(GetConVarInt(points_time));
		new givepoints = GetConVarInt(client_points);
		if (pointstime >= 0.1 && givepoints >= 1)
		{
			client_givepointstimer[client] = CreateTimer(pointstime, GIVECLIENTPOINTS_TIMER, client, TIMER_REPEAT);
		} else {
			PrintToServer("[TF2 Powerups] WARNING: Points or give points time are defined to a incorrect value, reseting to the default value. Please check cfg/sourcemod/powerups.cfg");
			SetConVarInt(client_points, 1);
			SetConVarInt(points_time, 1800);
			client_givepointstimer[client] = CreateTimer(1800.0, GIVECLIENTPOINTS_TIMER, client, TIMER_REPEAT);
		}
	}
}

public CheckForPlayersInGame()
{	
	for (new a = 1;a <= MaxClients;a++)
	{
		if (IsClientInGame(a))
		{
			PutPlayerInPointsQueue(a);
		}
	}
}

//***********************************************
//*				MAIN FUNCTIONS					*
//***********************************************

public Action:ADDPOINTS(client, args)
{
	if (args == 2)
	{
		new String:arg1[MAX_NAME_LENGTH];
		new String:arg2[10];
		GetCmdArg(1, arg1, sizeof(arg1));
		new target = FindTarget(client, arg1, true);
		if (target == -1){return Plugin_Handled;}
		GetCmdArg(2, arg2, 10);
		new arg2int = StringToInt(arg2);
		Points_System(target, arg2int, 1);
	} else {
		new String:message[256];
		Format(message, 256, "%T", "UsageWarnAddPoints", LANG_SERVER, PLUGIN_PREFIX_NOCOLOR);
		ReplyToCommand(client, message);
	}
	return Plugin_Handled;
}

public Action:RPOINTS(client, args)
{
	if (args == 2)
	{
		new String:arg1[MAX_NAME_LENGTH];
		new String:arg2[10];
		GetCmdArg(1, arg1, sizeof(arg1));
		new target = FindTarget(client, arg1, true);
		if (target == -1){return Plugin_Handled;}
		GetCmdArg(2, arg2, 10);
		new arg2int = StringToInt(arg2);
		Points_System(target, arg2int, 2);
	} else {
		new String:message[256];
		Format(message, 256, "%T", "UsageWarnRmvPoints", LANG_SERVER, PLUGIN_PREFIX_NOCOLOR)
		ReplyToCommand(client, message);
	}
	return Plugin_Handled;
}

public Action:TIMER_CLIENTMESSAGE(Handle:timer, any:client)
{
	new bool:IsOn = GetConVarBool(ismessageon);
	if (IsOn)
	{
		new String:message[256];
		Format(message, 256, "%T", "ConnectMSG", LANG_SERVER, PLUGIN_PREFIX);
		if (IsClientInGame(client))
		{
			CPrintToChat(client, "%s",message);
		}
	}
}

public Action:POWERUPS(client, args)
{
	if (client > 0 && client <= MaxClients)
	{
		ShowMenu(client);
	} else {
		new String:message[256];
		Format(message, 256, "%T", "NotInGame", LANG_SERVER, PLUGIN_PREFIX_NOCOLOR);
		ReplyToCommand(client, message);
	}
	
}

public Action:FORCEPOWERUP(client, args)
{
	new String:arg1[MAX_NAME_LENGTH];
	new String:arg2[10];
	
	GetCmdArg(1, arg1, sizeof(arg1));
	new target = FindTarget(client, arg1, true);
	if (target == -1){return Plugin_Handled;}
	if (target > MaxClients)
	{
		new String:message[256];
		Format(message, 256, "%T", "TargetNotInGame", client, PLUGIN_PREFIX_NOCOLOR);
		ReplyToCommand(client, message);
		return Plugin_Handled;
	}
	if (!IsPlayerAlive(client))
	{
		new String:death_message[256];
		Format(death_message, 256, "%T", "TargetIsDead", LANG_SERVER, PLUGIN_PREFIX_NOCOLOR);
		ReplyToCommand(client, death_message);
		return Plugin_Handled;
	}
	
	GetCmdArg(2, arg2, 10);
	new arg2int = StringToInt(arg2);
	
	if (uber_active[target] == 0 	 &&
		critical_active[target] == 0 &&
		bimu_active[target] == 0	 &&
		buff_active[target] == 0	 &&
		slowed_active[target] == 0	 &&
		bleeding_active[target] == 0 &&
		iammo_active[target] == 0)
	{
		if (IsClientInGame(target))
		{
			if (arg2int == 1
			 || arg2int == 2 
			 || arg2int == 3 
			 || arg2int == 4 
			 || arg2int == 5 
			 || arg2int == 6 
			 || arg2int == 7 
			 || arg2int == 8)
			{
				switch (arg2int)
				{
					case 1:
					{
						RandomPowerup(target);
					}
					case 2:
					{
						Respawn(target);
					}
					case 3:
					{
						Uber(target);
					}
					case 4:
					{
						Criticals(target);
					}
					case 5:
					{
						Bimu(target);
					}
					case 6:
					{
						Buff(target);
					}
					case 7:
					{
						Regen(target);
					}
					case 8:
					{
						InfiniteAmmo(target);
					}
				}
			}
		}
	} else {
		new String:clientname[MAX_NAME_LENGTH];
		GetClientName(target, clientname, sizeof(clientname));
		new String:message[256];
		Format(message, 256, "%T", "TargetAlreadyHaveActivePowerup", LANG_SERVER, PLUGIN_PREFIX_NOCOLOR, clientname);
		ReplyToCommand(client, message);
		
	}
	return Plugin_Handled;
}

public ShowMenu(client)
{
	if (IsClientInGame(client))
	{
		new TFTeam:team = TF2_GetClientTeam(client);
		if (team == TFTeam_Red || team == TFTeam_Blue)
		{
			new Handle:menu = CreateMenu(powerups_menu, MenuAction_Select | MenuAction_End);
			
			new String:luckmenu[64];
			new String:respawnmenu[64];
			new String:ubermenu[64];
			new String:critmenu[64];
			new String:bimumenu[64];
			new String:buffmenu[64];
			new String:regenmenu[64];
			new String:iammomenu[64];
			
			new String:luckprice[32];
			new String:respawnprice[32];
			new String:uberprice[32];
			new String:critprice[32];
			new String:bimuprice[32];
			new String:buffprice[32];
			new String:regenprice[32];
			new String:iammoprice[32];
			
			new String:ubertime[32];
			new String:crittime[32];
			new String:bimutime[32];
			new String:bufftime[32];
			new String:iammotime[32];
			
			GetConVarString(luck_cost, luckprice, 32);
			GetConVarString(respawn_cost, respawnprice, 32);
			GetConVarString(uber_cost, uberprice, 32);
			GetConVarString(criticals_cost, critprice, 32);
			GetConVarString(bimu_cost, bimuprice, 32);
			GetConVarString(buff_cost, buffprice, 32);
			GetConVarString(regen_cost, regenprice, 32);
			GetConVarString(uber_time, ubertime, 32);
			GetConVarString(criticals_time, crittime, 32);
			GetConVarString(bimu_time, bimutime, 32);
			GetConVarString(buff_time, bufftime, 32);
			GetConVarString(iammo_cost, iammoprice, 32);
			GetConVarString(iammo_time, iammotime, 32);
			
			Format(luckmenu, 64, "%T", "TestYourLuck", LANG_SERVER, luckprice)
			Format(respawnmenu, 64, "%T", "RespawnTranslation", LANG_SERVER, respawnprice);
			Format(ubermenu, 64, "%T", "UberchargeTranslation", LANG_SERVER, uberprice, ubertime);
			Format(critmenu, 64, "%T", "CriticalsTranslation", LANG_SERVER, critprice, crittime);
			Format(bimumenu, 64, "%T", "BulletTranslation", LANG_SERVER, bimuprice, bimutime);
			Format(buffmenu, 64, "%T", "BuffTranslation", LANG_SERVER, buffprice, bufftime);
			Format(regenmenu, 64, "%T", "InstantRegenTranslation", LANG_SERVER, regenprice);
			Format(iammomenu, 64, "%T", "InfiniteAmmoTranslation", LANG_SERVER, iammoprice, iammotime);
			
			new String:title[64];
			Format(title, 64, "%T", "PowerupsTranslation", LANG_SERVER);
			
			new String:pointsmenu[64];
			new point_int = Points_System(client, 0, 3);
			Format(pointsmenu, 64, "%T", "Points", LANG_SERVER, point_int);
			
			SetMenuTitle(menu, "%s\n%s",title, pointsmenu);
			
			new bool:LuckIsOn = GetConVarBool(randompower_IsOn);
			if (LuckIsOn)
			{
				AddMenuItem(menu, "m_luck", luckmenu);
			}
			
			AddMenuItem(menu, "m_resp", respawnmenu);
			AddMenuItem(menu, "m_uber", ubermenu);
			AddMenuItem(menu, "m_crit", critmenu);
			AddMenuItem(menu, "m_bimu", bimumenu);
			AddMenuItem(menu, "m_buff", buffmenu);
			AddMenuItem(menu, "m_regen", regenmenu);
			AddMenuItem(menu, "m_iammo", iammomenu);
			
			DisplayMenu(menu, client, MENU_TIME_FOREVER);
		} else {
			new String:message[256];
			Format(message, 256, "%T", "InvalidTeam", LANG_SERVER, PLUGIN_PREFIX);
			CPrintToChat(client, message);
		}
	}		
}

public powerups_menu(Handle:menu, MenuAction:action, client, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			new String:NoPoints[256];
			new String:NeedToWaitMinute[256];
			new String:NeedToWait[256];
			new String:death_message[256];
			Format(death_message, 256, "%T", "ClientIsDead", LANG_SERVER, PLUGIN_PREFIX);
			Format(NoPoints, 256, "%T", "DontHaveEnoughPoints", LANG_SERVER, PLUGIN_PREFIX);
			Format(NeedToWaitMinute, 256, "%T", "NeedToWaitMinute", LANG_SERVER, PLUGIN_PREFIX);
			
			new String:item[64];
			GetMenuItem(menu, param2, item, sizeof(item));
			
			if (uber_active[client] == 0 	&&
				critical_active[client] == 0&&
				bimu_active[client] == 0	&&
				buff_active[client] == 0	&&
				slowed_active[client] == 0	&&
				bleeding_active[client] == 0&&
				iammo_active[client] == 0)
			{
				if (StrEqual(item, "m_luck"))
				{	new bool:IsRandomOn = GetConVarBool(randompower_IsOn);
					if (IsRandomOn)
					{
						if (IsPlayerAlive(client))
						{
							new cost = GetConVarInt(luck_cost);
							new test = Points_System(client, cost, 3);
							if (test < cost)
							{
								CPrintToChat(client, NoPoints);
							} else {
								new test2 = WaitTime(client, 2);
								if (test2 == 0)
								{
									new test3 = WaitTime(client, 3);
									if (test3 == 0)
									{
										CPrintToChat(client, NeedToWaitMinute);
									} else {
										Format(NeedToWait, 256, "%T", "NeedToWait", LANG_SERVER, PLUGIN_PREFIX, test3);
										CPrintToChat(client, NeedToWait);
									}
									
								} else {
									WaitTime(client, 1);
									Points_System(client, cost, 2);
									RandomPowerup(client);
								}
							}	
						} else {
							CPrintToChat(client, death_message);
						}
					} else {
						new String:message[256];
						Format(message, 256, "%T", "FunctionDisabled", LANG_SERVER, PLUGIN_PREFIX);
						CPrintToChat(client, message);
					}
				}
				else if (StrEqual(item, "m_resp"))
				{
					new cost = GetConVarInt(respawn_cost);
					new test = Points_System(client, cost, 3);
					if (test < cost)
					{
						CPrintToChat(client, NoPoints);
					} else {
						new test2 = WaitTime(client, 2);
						if (test2 == 0)
						{
							new test3 = WaitTime(client, 3);
							if (test3 == 0)
							{
								CPrintToChat(client, NeedToWaitMinute);
							} else {
								Format(NeedToWait, 256, "%T", "NeedToWait", LANG_SERVER, PLUGIN_PREFIX, test3);
								CPrintToChat(client, NeedToWait);
							}
							
						} else {
							WaitTime(client, 1);
							Points_System(client, cost, 2);
							Respawn(client);
						}
					}		
				}
				else if (StrEqual(item, "m_uber"))
				{
					if (IsPlayerAlive(client))
					{
						new cost = GetConVarInt(uber_cost);
						new test = Points_System(client, cost, 3);
						if (test < cost)
						{
							CPrintToChat(client, NoPoints);
						} else {
							new test2 = WaitTime(client, 2);
							if (test2 == 0)
							{
								new test3 = WaitTime(client, 3);
								if (test3 == 0)
								{
									CPrintToChat(client, NeedToWaitMinute);
								} else {
									Format(NeedToWait, 256, "%T", "NeedToWait", LANG_SERVER, PLUGIN_PREFIX, test3);
									CPrintToChat(client, NeedToWait);
								}
							} else {
								WaitTime(client, 1);
								Points_System(client, cost, 2);
								Uber(client);
							}
						}		
					} else {
						CPrintToChat(client, death_message);
					}
				}
				else if (StrEqual(item, "m_crit"))
				{
					if (IsPlayerAlive(client))
					{
						new cost = GetConVarInt(criticals_cost);
						new test = Points_System(client, cost, 3);
						if (test < cost)
						{
							CPrintToChat(client, NoPoints);
						} else {
							new test2 = WaitTime(client, 2);
							if (test2 == 0)
							{
								new test3 = WaitTime(client, 3);
								if (test3 == 0)
								{
									CPrintToChat(client, NeedToWaitMinute);
								} else {
									Format(NeedToWait, 256, "%T", "NeedToWait", LANG_SERVER, PLUGIN_PREFIX, test3);
									CPrintToChat(client, NeedToWait);
								}
								
							} else {
								WaitTime(client, 1);
								Points_System(client, cost, 2);
								Criticals(client);
							}
						}
					} else {
						CPrintToChat(client, death_message);
					}					
				}
				else if (StrEqual(item, "m_bimu"))
				{
					if (IsPlayerAlive(client))
					{
						new cost = GetConVarInt(bimu_cost);
						new test = Points_System(client, cost, 3);
						if (test < cost)
						{
							CPrintToChat(client, NoPoints);
						} else {
							new test2 = WaitTime(client, 2);
							if (test2 == 0)
							{
								new test3 = WaitTime(client, 3);
								if (test3 == 0)
								{
									CPrintToChat(client, NeedToWaitMinute);
								} else {
									Format(NeedToWait, 256, "%T", "NeedToWait", LANG_SERVER, PLUGIN_PREFIX, test3);
									CPrintToChat(client, NeedToWait);
								}
								
							} else {
								WaitTime(client, 1);
								Points_System(client, cost, 2);
								Bimu(client);
							}
						}	
					} else {
						CPrintToChat(client, death_message);
					}
				}
				else if (StrEqual(item, "m_buff"))
				{
					if (IsPlayerAlive(client))
					{
						new cost = GetConVarInt(buff_cost);
						new test = Points_System(client, cost, 3);
						if (test < cost)
						{
							CPrintToChat(client, NoPoints);
						} else {
							new test2 = WaitTime(client, 2);
							if (test2 == 0)
							{
								new test3 = WaitTime(client, 3);
								if (test3 == 0)
								{
									CPrintToChat(client, NeedToWaitMinute);
								} else {
									Format(NeedToWait, 256, "%T", "NeedToWait", LANG_SERVER, PLUGIN_PREFIX, test3);
									CPrintToChat(client, NeedToWait);
								}
								
							} else {
								WaitTime(client, 1);
								Points_System(client, cost, 2);
								Buff(client);
							}
						}	
					} else {
						CPrintToChat(client, death_message);
					}
				}
				else if (StrEqual(item, "m_regen"))
				{
					if (IsPlayerAlive(client))
					{
						new cost = GetConVarInt(regen_cost);
						new test = Points_System(client, cost, 3);
						if (test < cost)
						{
							CPrintToChat(client, NoPoints);
						} else {
							new test2 = WaitTime(client, 2);
							if (test2 == 0)
							{
								new test3 = WaitTime(client, 3);
								if (test3 == 0)
								{
									CPrintToChat(client, NeedToWaitMinute);
								} else {
									Format(NeedToWait, 256, "%T", "NeedToWait", LANG_SERVER, PLUGIN_PREFIX, test3);
									CPrintToChat(client, NeedToWait);
								}
								
							} else {
								WaitTime(client, 1);
								Points_System(client, cost, 2);
								Regen(client);
							}
						}
					} else {
						CPrintToChat(client, death_message);
					}
				}
				else if (StrEqual(item, "m_iammo"))
				{
					if (IsPlayerAlive(client))
					{
						new cost = GetConVarInt(iammo_cost);
						new test = Points_System(client, cost, 3);
						if (test < cost)
						{
							CPrintToChat(client, NoPoints);
						} else {
							new test2 = WaitTime(client, 2);
							if (test2 == 0)
							{
								new test3 = WaitTime(client, 3);
								if (test3 == 0)
								{
									CPrintToChat(client, NeedToWaitMinute);
								} else {
									Format(NeedToWait, 256, "%T", "NeedToWait", LANG_SERVER, PLUGIN_PREFIX, test3);
									CPrintToChat(client, NeedToWait);
								}
								
							} else {
								WaitTime(client, 1);
								Points_System(client, cost, 2);
								InfiniteAmmo(client);
							}
						}	
					} else {
						CPrintToChat(client, death_message);
					}
				}
			} else {
				new String:message[256];
				Format(message, 256, "%T", "AlreadyHaveActivePowerup", client, PLUGIN_PREFIX_NOCOLOR);
				ReplyToCommand(client, message);
			}
		}

		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

public Action:GIVECLIENTPOINTS_TIMER(Handle:timer_givepoints, any:client)
{
	new givepoints = GetConVarInt(client_points);
	if (givepoints >= 1)
	{
		Points_System(client, givepoints, 1);
	} else {
		PrintToServer("[TF2 Powerups] ERROR: Points are defined to a incorrect value, reseting to the default value. Please check cfg/sourcemod/powerups.cfg");
		SetConVarInt(client_points, 1);
		Points_System(client, 1, 1);
	}
}

//------------------------------------------------------- Plugin Actions -------------------------------------------------------

public Points_System(client, points, mode)
{
/* client is for who the points will be given;
   points is how much points will be given;
   mode = 1 for increment, 2 for reduction, 3 for check;
   HAVE A RETURN IF THE MODE IS 3.
*/

	if (mode == 1)
	{
		/////Adding Points/////
		
		new Handle:DB = CreateKeyValues("Powerups");
		FileToKeyValues(DB, KVPath);

		new String:SID[32];
		GetClientAuthId(client, AuthId_Steam3, SID, sizeof(SID));
		
		if(KvJumpToKey(DB, SID, true))
		{			
			new PointsNum;
			PointsNum = KvGetNum(DB, "Points", 0);
			
			PointsNum = PointsNum + points;
			
			KvSetNum(DB, "Points", PointsNum);	
		}
		KvRewind(DB);
		KeyValuesToFile(DB, KVPath);
		CloseHandle(DB);
		new String:received_message[256];
		Format(received_message, 256, "%T", "ReceivedPoints", LANG_SERVER, PLUGIN_PREFIX, points);
		CPrintToChat(client, received_message);
	}
	else if (mode == 2)
	{
		/////Removing Points/////
		
		new Handle:DB = CreateKeyValues("Powerups");
		FileToKeyValues(DB, KVPath);

		new String:SID[32];
		GetClientAuthId(client, AuthId_Steam3, SID, sizeof(SID));
		
		if(KvJumpToKey(DB, SID, true))
		{			
			new PointsNum;
			PointsNum = KvGetNum(DB, "Points", 0);
			
			if (PointsNum <= 0)
			{
				KvSetNum(DB, "Points", 0);
			} else {
				PointsNum = PointsNum - points;
				KvSetNum(DB, "Points", PointsNum);
				PointsNum = KvGetNum(DB, "Points", 0);
				if (PointsNum <= 0)
				{
					KvSetNum(DB, "Points", 0);
				}
			}
			new String:removed_points[256];
			Format(removed_points, 256, "%T", "RemovePoints", LANG_SERVER, PLUGIN_PREFIX, points);
			CPrintToChat(client, removed_points);
		}
		KvRewind(DB);
		KeyValuesToFile(DB, KVPath);
		CloseHandle(DB);
	}
	else if (mode == 3)
	{
		/////Checking Points/////
	
		new PointsNum;
		new Handle:DB = CreateKeyValues("Powerups");
		FileToKeyValues(DB, KVPath);

		new String:SID[32];
		GetClientAuthId(client, AuthId_Steam3, SID, sizeof(SID));
		
		if(KvJumpToKey(DB, SID, true))
		{			
			PointsNum = KvGetNum(DB, "Points", 0);
		}
		KvRewind(DB);
		KeyValuesToFile(DB, KVPath);
		CloseHandle(DB);
		
		return PointsNum;
	}
	return 0;
}

public WaitTime(client, mode)
{
/* client is for who the WaitTime is going to check/save;
   mode: 1 for saving time, 2 to obtain true/false, 3 to obtain time.
   HAVE A RETURN IN MODE 2.
*/
	
	new systime = GetTime();
	new PointsNum;
	
	if (mode == 1)
	{
		new Handle:DB = CreateKeyValues("Powerups");
		FileToKeyValues(DB, KVPath);

		new String:SID[32];
		GetClientAuthId(client, AuthId_Steam3, SID, sizeof(SID));
		
		if(KvJumpToKey(DB, SID, true))
		{	
			PointsNum = KvGetNum(DB, "Time", 0);
			new wait = GetConVarInt(waittime);
			PointsNum = systime + wait;
			KvSetNum(DB, "Time", PointsNum);
		}
		KvRewind(DB);
		KeyValuesToFile(DB, KVPath);
		CloseHandle(DB);
		
	} 
	else if (mode == 2)
	{
	
		new Handle:DB = CreateKeyValues("Powerups");
		FileToKeyValues(DB, KVPath);

		new String:SID[32];
		GetClientAuthId(client, AuthId_Steam3, SID, sizeof(SID));
		
		if(KvJumpToKey(DB, SID, true))
		{	
			PointsNum = KvGetNum(DB, "Time", 0);
			if (PointsNum <= systime)
			{
				KvSetNum(DB, "Time", 0);
				KvRewind(DB);
				KeyValuesToFile(DB, KVPath);
				CloseHandle(DB);
				
				return 1;
				
			} else {
				KvRewind(DB);
				KeyValuesToFile(DB, KVPath);
				CloseHandle(DB);
				
				return 0;
			}
		}
	}
	else if (mode == 3)
	{
		new Handle:DB = CreateKeyValues("Powerups");
		FileToKeyValues(DB, KVPath);

		new String:SID[32];
		GetClientAuthId(client, AuthId_Steam3, SID, sizeof(SID));
		
		if(KvJumpToKey(DB, SID, true))
		{	
			PointsNum = KvGetNum(DB, "Time", 0);
			PointsNum = PointsNum - systime;
			PointsNum = PointsNum / 60;
		}
		KvRewind(DB);
		KeyValuesToFile(DB, KVPath);
		CloseHandle(DB);
		if (PointsNum <= 0)
		{
			return 0;
		} else {
			return PointsNum;
		}
	}
	return 0;
}

public Respawn(client)
{
	EmitSoundToAll(SOUND_RESPAWN, client);
	new String:clientname[MAX_NAME_LENGTH];
	GetClientName(client, clientname, sizeof(clientname));
	TF2_RespawnPlayer(client);
	new String:message[256];
	Format(message, 256, "%T", "BoughtRespawn", LANG_SERVER, PLUGIN_PREFIX, clientname);
	CPrintToChatAll(message);
}

public Uber(client)
{
	EmitSoundToAll(SOUND_UBERON, client);
	new String:clientname[MAX_NAME_LENGTH];
	GetClientName(client, clientname, sizeof(clientname));
	new Float:time = float(GetConVarInt(uber_time));
	TF2_AddCondition(client, TFCond_UberchargedCanteen, TFCondDuration_Infinite);
	uber_active[client] = 1;
	new String:message[256];
	Format(message, 256, "%T", "BoughtUber", LANG_SERVER, PLUGIN_PREFIX, clientname);
	CPrintToChatAll(message);
	powerup_handle_uber[client] = CreateTimer(time, UBER_FINISH, client);
}

public Action:UBER_FINISH(Handle:uber, any:client)
{
	if (IsPlayerAlive(client))
	{
		EmitSoundToAll(SOUND_UBEROFF, client);
	}
	new String:clientname[MAX_NAME_LENGTH];
	GetClientName(client, clientname, sizeof(clientname));
	TF2_RemoveCondition(client, TFCond_UberchargedCanteen);
	uber_active[client] = 0;
	new String:message[256];
	Format(message, 256, "%T", "PowerRanOut", LANG_SERVER, PLUGIN_PREFIX, clientname);
	CPrintToChatAll(message);
}

public Criticals(client)
{
	EmitSoundToAll(SOUND_CRITICALS, client);
	new String:clientname[MAX_NAME_LENGTH];
	GetClientName(client, clientname, sizeof(clientname));
	new Float:time = float(GetConVarInt(criticals_time));
	TF2_AddCondition(client, TFCond_CritCanteen, TFCondDuration_Infinite);
	critical_active[client] = 1;
	new String:message[256];
	Format(message, 256, "%T", "BoughtCrits", LANG_SERVER, PLUGIN_PREFIX, clientname);
	CPrintToChatAll(message);
	powerup_handle_criticals[client] = CreateTimer(time, CRITICALS_FINISH, client);
}

public Action:CRITICALS_FINISH(Handle:crit, any:client)
{
	new String:clientname[MAX_NAME_LENGTH];
	GetClientName(client, clientname, sizeof(clientname));
	TF2_RemoveCondition(client, TFCond_CritCanteen);
	new String:message[256];
	Format(message, 256, "%T", "PowerRanOut", LANG_SERVER, PLUGIN_PREFIX, clientname);
	CPrintToChatAll(message);
	critical_active[client] = 0;
}

public Bimu(client)
{
	EmitSoundToAll(SOUND_BIMU, client);
	new String:clientname[MAX_NAME_LENGTH];
	GetClientName(client, clientname, sizeof(clientname));
	new Float:time = float(GetConVarInt(bimu_time));
	TF2_AddCondition(client, TFCond_BulletImmune, TFCondDuration_Infinite);
	bimu_active[client] = 1;
	new String:message[256];
	Format(message, 256, "%T", "BoughtBimu", LANG_SERVER, PLUGIN_PREFIX, clientname);
	CPrintToChatAll(message);
	powerup_handle_bimu[client] = CreateTimer(time, BIMU_FINISH, client);
}

public Action:BIMU_FINISH(Handle:bimu, any:client)
{
	TF2_RemoveCondition(client, TFCond_BulletImmune);
	bimu_active[client] = 0;
	new String:clientname[MAX_NAME_LENGTH];
	GetClientName(client, clientname, sizeof(clientname));
	new String:message[256];
	Format(message, 256, "%T", "PowerRanOut", LANG_SERVER, PLUGIN_PREFIX, clientname);
	CPrintToChatAll(message);
}

public Buff(client)
{
	EmitSoundToAll(SOUND_BUFF, client);
	new String:clientname[MAX_NAME_LENGTH];
	GetClientName(client, clientname, sizeof(clientname));
	new Float:time = float(GetConVarInt(buff_time));
	TF2_AddCondition(client, TFCond_RegenBuffed, TFCondDuration_Infinite);
	buff_active[client] = 1;
	new String:message[256];
	Format(message, 256, "%T", "BoughtBuff", LANG_SERVER, PLUGIN_PREFIX, clientname);
	CPrintToChatAll(message);
	powerup_handle_buff[client] = CreateTimer(time, BUFF_FINISH, client);
}

public Action:BUFF_FINISH(Handle:buff, any:client)
{
	new String:clientname[MAX_NAME_LENGTH];
	GetClientName(client, clientname, sizeof(clientname));
	TF2_RemoveCondition(client, TFCond_RegenBuffed);
	buff_active[client] = 0;
	new String:message[256];
	Format(message, 256, "%T", "PowerRanOut", LANG_SERVER, PLUGIN_PREFIX, clientname);
	CPrintToChatAll(message);
}

public Regen(client)
{
	EmitSoundToAll(SOUND_REGEN, client);
	TF2_RegeneratePlayer(client);
	new String:clientname[MAX_NAME_LENGTH];
	GetClientName(client, clientname, sizeof(clientname));
	new String:message[256];
	Format(message, 256, "%T", "BoughtRegen", LANG_SERVER, PLUGIN_PREFIX, clientname);
	CPrintToChatAll(message);
}

public Slowed(client)
{
	EmitSoundToAll(SOUND_SLOWED, client);
	new String:clientname[MAX_NAME_LENGTH];
	GetClientName(client, clientname, sizeof(clientname));
	slowed_sum[client] = GetConVarInt(badeffect_time);
	slowed_sum[client] = slowed_sum[client] * 10;
	
	SetEntDataFloat(client, g_speed, 50.0);
	slowed_active[client] = 1;
	
	new String:message[256];
	Format(message, 256, "%T", "Slowed", LANG_SERVER, PLUGIN_PREFIX, clientname);
	CPrintToChatAll(message);
	
	powerup_handle_slowed[client] = CreateTimer(0.1, MAKESLOW, client, TIMER_REPEAT);
}

public Action:MAKESLOW(Handle:slowed, any:client)
{	
	if (slowed_sum[client] <= 0)
	{
		slowed_sum[client] = 0;
		new String:clientname[MAX_NAME_LENGTH];
		GetClientName(client, clientname, sizeof(clientname));
		slowed_active[client] = 0;
		new String:message[256];
		Format(message, 256, "%T", "BadEffectRanOut", LANG_SERVER, PLUGIN_PREFIX, clientname);
		CPrintToChatAll(message);
		TF2_AddCondition(client, TFCond_SpeedBuffAlly, 0.1);
		KillTimer(powerup_handle_slowed[client]);
	} else {
		slowed_sum[client]--;
		if (IsPlayerAlive(client))
		{
			SetEntDataFloat(client, g_speed, 50.0);
		}	
	}	
}

public Bleed(client)
{
	new String:clientname[MAX_NAME_LENGTH];
	GetClientName(client, clientname, sizeof(clientname));
	bleeding_sum[client] = GetConVarInt(badeffect_time);
	bleeding_active[client] = 1;
	new String:message[256];
	Format(message, 256, "%T", "Bleeding", LANG_SERVER, PLUGIN_PREFIX, clientname);
	CPrintToChatAll(message);
	TF2_MakeBleed(client, client, 1.0);
	EmitSoundToClient(client, SOUND_BLEED);
	
	powerup_handle_bleeding[client] = CreateTimer(1.0, MAKEBLEED, client, TIMER_REPEAT);
}

public Action:MAKEBLEED(Handle:mbleed, any:client)
{
	if (bleeding_sum[client] <= 0)
	{
		bleeding_sum[client] = 0;
		new String:clientname[MAX_NAME_LENGTH];
		GetClientName(client, clientname, sizeof(clientname));
		bleeding_active[client] = 0;
		new String:message[256];
		Format(message, 256, "%T", "BadEffectRanOut", LANG_SERVER, PLUGIN_PREFIX, clientname);
		CPrintToChatAll(message);
		KillTimer(powerup_handle_bleeding[client]);
	} else {
		bleeding_sum[client]--;
		if (IsPlayerAlive(client))
		{
			EmitSoundToClient(client, SOUND_BLEED);
			TF2_MakeBleed(client, client, 1.0);
		}	
	}	
}

public Suicide(client)
{
	new TFClassType:class = TF2_GetPlayerClass(client);
	
	switch (class)
	{
		case TFClass_Scout:
		{
			EmitSoundToAll(SOUND_SUICIDE_SCOUT, client);
		}
		case TFClass_Soldier:
		{
			EmitSoundToAll(SOUND_SUICIDE_SOLDIER, client);
		}
		case TFClass_Pyro:
		{
			EmitSoundToAll(SOUND_SUICIDE_PYRO, client);
		}
		case TFClass_DemoMan:
		{
			EmitSoundToAll(SOUND_SUICIDE_DEMOMAN, client);
		}
		case TFClass_Heavy:
		{
			EmitSoundToAll(SOUND_SUICIDE_HEAVY, client);
		}
		case TFClass_Engineer:
		{
			EmitSoundToAll(SOUND_SUICIDE_ENGINEER, client);
		}
		case TFClass_Medic:
		{
			EmitSoundToAll(SOUND_SUICIDE_MEDIC, client);
		}
		case TFClass_Sniper:
		{
			EmitSoundToAll(SOUND_SUICIDE_SNIPER, client);
		}
		case TFClass_Spy:
		{
			EmitSoundToAll(SOUND_SUICIDE_SPY, client);
		}
	}
	ForcePlayerSuicide(client);
	new String:clientname[MAX_NAME_LENGTH];
	new String:message[256];
	GetClientName(client, clientname, sizeof(clientname));
	Format(message, 256, "%T", "Suicide", LANG_SERVER, PLUGIN_PREFIX, clientname);
	CPrintToChatAll(message);
}

public InfiniteAmmo(client)
{
	EmitSoundToAll(SOUND_IAMMO, client);
	new String:clientname[MAX_NAME_LENGTH];
	new String:message[256];
	new Float:time = float(GetConVarInt(iammo_time));
	iammo_active[client] = 1;
	GetClientName(client, clientname, sizeof(clientname));
	Format(message, 256, "%T", "InfiniteAmmo", LANG_SERVER, PLUGIN_PREFIX, clientname);
	CPrintToChatAll(message);
	
	SaveWeaponClipCache(client);
	
	powerup_handle_iammo[client] = CreateTimer(0.1, START_IAMMO, client, TIMER_REPEAT);
	powerup_handle_iammo2[client] = CreateTimer(time, END_IAMMO, client);
}

public Action:START_IAMMO(Handle:iammo, any:client)
{
	if (IsPlayerAlive(client))
	{
		new WeaponIndex = GetPlayerWeaponSlot(client, 0);
		new WeaponIndexSecondary = GetPlayerWeaponSlot(client, 1);
		
		new WeaponData = 0;
		new WeaponData2 = 0;
		
		if (WeaponIndex >= 0)
		{
			WeaponData = GetEntData(WeaponIndex, g_Itemdef);
		}
		if (WeaponIndexSecondary >= 0)
		{
			WeaponData2 = GetEntData(WeaponIndexSecondary, g_Itemdef);
		}
		
		SetEntData(client, g_AmmoOffset+(4*3), 200);
		if (WeaponIndex >= 0)
		{
			if (WeaponData != ITEM_CRUZADERS && WeaponData != ITEM_CRUZADERS_FESTIVE && WeaponData != ITEM_MANGLER && WeaponData != ITEM_POMSON && WeaponData >= 0)
			{
				SetEntData(WeaponIndex, g_ClipOffset, 99, _, true);
			}
			else if (WeaponData == ITEM_MANGLER || WeaponData == ITEM_POMSON)
			{
				SetEntPropFloat(WeaponIndex, Prop_Send, "m_flEnergy", 20.0);
			}
		}
		
		if (WeaponIndexSecondary >= 0)
		{
			if (WeaponData2 == ITEM_BISON)
			{
				SetEntPropFloat(WeaponIndexSecondary, Prop_Send, "m_flEnergy", 20.0);
			}
			else if (WeaponData2 >= 0)
			{
				SetEntData(WeaponIndexSecondary, g_ClipOffset, 99, _, true);
			}	
		}
	}
}

public Action:END_IAMMO(Handle:iammo2, any:client)
{
	KillTimer(powerup_handle_iammo[client]);
	iammo_active[client] = 0;
	if (IsPlayerAlive(client))
	{
		new WeaponIndex = GetPlayerWeaponSlot(client, 0);
		new WeaponIndexSecondary = GetPlayerWeaponSlot(client, 1);
		
		if (WeaponIndex > MaxClients)
		{
			SetEntData(WeaponIndex, g_ClipOffset, WeaponClipCache[client], _, true);
		}
		if (WeaponIndexSecondary > MaxClients)
		{
			SetEntData(WeaponIndexSecondary, g_ClipOffset, WeaponClipCache_Secondary[client], _, true);
		}
	}
	new String:clientname[MAX_NAME_LENGTH];
	new String:message[256];
	GetClientName(client, clientname, sizeof(clientname));
	Format(message, 256, "%T", "IammoEnd", LANG_SERVER, PLUGIN_PREFIX, clientname);
	CPrintToChatAll(message);
}

public LowHP(client)
{
	SetEntityHealth(client, 1);
	FakeClientCommand(client, "voicemenu 0 0");
	new String:clientname[MAX_NAME_LENGTH];
	new String:message[256];
	GetClientName(client, clientname, sizeof(clientname));
	Format(message, 256, "%T", "LowHP", LANG_SERVER, PLUGIN_PREFIX, clientname);
	CPrintToChatAll(message);
}

public RandomPowerup(client)
{
	new String:chatmessage[256];
	new String:clientname[MAX_NAME_LENGTH];
	GetClientName(client, clientname, sizeof(clientname));
	Format(chatmessage, 256, "%T", "BoughtLuck", LANG_SERVER, PLUGIN_PREFIX, clientname);
	CPrintToChatAll(chatmessage);
	new random = GetRandomInt(1, 8);
	
	switch (random)
	{
		case 1:
		{
			Respawn(client);
		}
		case 2:
		{
			Slowed(client);
		}
		case 3:
		{
			Uber(client);
		}
		case 4:
		{
			Bleed(client);
		}
		case 5:
		{
			Criticals(client);
		}
		case 6:
		{
			Suicide(client);
		}
		case 7:
		{
			Bimu(client);
		}
		case 8:
		{
			LowHP(client);
		}
		case 9:
		{
			Buff(client);
		}
		case 10:
		{
			Regen(client);
		}
		case 11:
		{
			InfiniteAmmo(client);
		}
	}
}

LookupOffset(&iOffset, const String:strClass[], const String:strProp[])
{
        iOffset = FindSendPropInfo(strClass, strProp);
        if(iOffset <= 0)
        {
                SetFailState("%s Could not locate offset for %s::%s!",PLUGIN_PREFIX_NOCOLOR, strClass, strProp);
        }
}

public SaveWeaponClipCache(client)
{
	new slotBuffer1 = GetPlayerWeaponSlot(client, 0);
	new slotBuffer2 = GetPlayerWeaponSlot(client, 1);
	
	if (slotBuffer1 > MaxClients)
	{
		new Weapon = GetEntData(slotBuffer1, g_ClipOffset);
		WeaponClipCache[client] = Weapon;
	}
	
	if (slotBuffer2 > MaxClients)
	{
		new WeaponS = GetEntData(slotBuffer2, g_ClipOffset);
		WeaponClipCache_Secondary[client] = WeaponS;
	}	
}

public ResetWeaponClipCache(client)
{
	WeaponClipCache[client] = 0;
	WeaponClipCache_Secondary[client] = 0;
}
