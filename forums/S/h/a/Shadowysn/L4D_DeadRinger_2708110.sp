#define PLUGIN_NAME "[L4D2] Dead Ringer"
#define PLUGIN_AUTHOR "Shadowysn"
#define PLUGIN_DESC "Use sm_fd to activate the Dead Ringer."
#define PLUGIN_VERSION "1.0"
#define PLUGIN_URL "tobeadded"

//A few functions and signatures have been taken from the Infected Release plugin:
//https://forums.alliedmods.net/showthread.php?p=994506

//Special thanks to Martt for fixing my broken code:
//https://forums.alliedmods.net/showthread.php?p=2675444#post2675444

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
//#include <sendproxy>
//https://forums.alliedmods.net/showpost.php?p=2210301&postcount=270
//#include <sceneprocessor>
//https://forums.alliedmods.net/showthread.php?p=2147410

#define GAMEDATA "l4d_dead_ringer"

#define ACTIVE_STR "DEAD-RINGER ACTIVE"
#define INACTIVE_STR "DEAD-RINGER INACTIVE"
//#define UNCLOAK_SND "Player.Spy_UnCloakFeignDeath"
#define NECKSNAP_SND "player/neck_snap_01.wav"

#define MAIN_DAMAGE_HOOK SDKHook_OnTakeDamagePost
#define TRANSMIT_HOOK SDKHook_SetTransmit
#define THINK_HOOK SDKHook_ThinkPost

#define SURVIVORTEAM 2
#define INFECTEDTEAM 3
#define SURVIVORTEAM_PASSING 4
#define ZOMBIECLASS_SMOKER	1
#define ZOMBIECLASS_BOOMER	2
#define ZOMBIECLASS_HUNTER	3
#define ZOMBIECLASS_SPITTER	4
#define ZOMBIECLASS_JOCKEY	5
#define ZOMBIECLASS_CHARGER	6
#define ZOMBIECLASS_TANK	8

#define S_CHAR_GAMBLER 0
#define S_CHAR_PRODUCER 1
#define S_CHAR_COACH 2
#define S_CHAR_MECHANIC 3
#define S_CHAR_NAMVET 4
#define S_CHAR_TEENANGST 5
#define S_CHAR_BIKER 6
#define S_CHAR_MANAGER 7
#define S_CHAR_UNKNOWN 8

#define BOOMER_M_MDL "models/infected/boomer.mdl"
#define BOOMER_F_MDL "models/infected/boomette.mdl"
#define BOOMER_M_GIB "models/infected/limbs/exploded_boomer.mdl"
#define BOOMER_F_GIB "models/infected/limbs/exploded_boomette.mdl"

#pragma semicolon 1
#pragma newdecls required

int g_Ragdoll[MAXPLAYERS+1] = -1;
int g_BloodPool[MAXPLAYERS+1] = -1;
static bool isTriggerable[MAXPLAYERS+1];
static bool isActive[MAXPLAYERS+1];
static bool isCloaked[MAXPLAYERS+1];
static bool hasEffects[2048] = false;
//static int initialAlpha[2048] = 255;
//static RenderMode initialRender[2048] = RENDER_NORMAL;

ConVar DeadRinger_EnableComm;
ConVar DeadRinger_RechargeTime;
ConVar DeadRinger_FakeWeaponTime;
ConVar DeadRinger_DisableAttack;
ConVar DeadRinger_RemovePins;
ConVar DeadRinger_CloakTime;
ConVar DeadRinger_CorpseMode;
ConVar DeadRinger_Transmit;

static Handle g_UncloakTimer[MAXPLAYERS+1] = null;
static Handle g_BoostTimer[MAXPLAYERS+1] = null;
static Handle g_ReadyTimer[MAXPLAYERS+1] = null;

Handle hConf = null;
static Handle hOnPummelEnded = null;
static Handle hOnPounceEnd = null;
static Handle hStartActivationTimer = null;
static Handle hReleaseTongueVictim = null;
static Handle hOnRideEnded = null;
#define NAME_ONPUMMELENDED "CTerrorPlayer::OnPummelEnded"
#define NAME_ONPOUNCEEND "CTerrorPlayer::OnPounceEnd"
#define NAME_RELEASETONGUEVICTIM "CTerrorPlayer::ReleaseTongueVictim"
#define NAME_ONRIDEENDED "CTerrorPlayer::OnRideEnded"
#define NAME_STARTACTIVATIONTIMER "CBaseAbility::StartActivationTimer"

// Don't hardcode these in!
#define SIG_ONPUMMELENDED_LINUX "@_ZN13CTerrorPlayer13OnPummelEndedEbPS_"
#define SIG_ONPUMMELENDED_WINDOWS "\\x55\\x8B\\x2A\\x8B\\x2A\\x2A\\x2A\\x2A\\x2A\\x53\\x56\\x8B\\x2A\\x8B\\x2A\\x2A\\x2A\\x2A\\x2A\\x57"
#define SIG_ONPOUNCEEND_LINUX "@_ZN13CTerrorPlayer13OnPounceEndedEv"
#define SIG_ONPOUNCEEND_WINDOWS "\\x55\\x8B\\xEC\\x51\\x53\\x8B\\xD9\\x80\\xBB\\xAC\\x3E\\x00\\x00\\x00"
#define SIG_RELEASETONGUEVICTIM_LINUX "@_ZN13CTerrorPlayer19ReleaseTongueVictimEb"
#define SIG_RELEASETONGUEVICTIM_WINDOWS "\\x53\\x8B\\x2A\\x83\\x2A\\x2A\\x83\\x2A\\x2A\\x83\\x2A\\x2A\\x55\\x8B\\x2A\\x2A\\x89\\x2A\\x2A\\x2A\\x8B\\x2A\\x83\\x2A\\x2A\\x8B\\x81\\x2A\\x2A\\x2A\\x2A"
#define SIG_ONRIDEENDED_LINUX "@_ZN13CTerrorPlayer11OnRideEndedEPS_"
#define SIG_ONRIDEENDED_WINDOWS "\\x55\\x8B\\x2A\\x83\\x2A\\x2A\\x53\\x56\\x57\\x68\\x14\\x2A\\x2A\\x2A"
#define SIG_STARTACTIVATIONTIMER_LINUX "@_ZN12CBaseAbility20StartActivationTimerEff"
#define SIG_STARTACTIVATIONTIMER_WINDOWS "\\x55\\x8B\\xEC\\xF3\\x0F\\x10\\x4D\\x0C\\x0F\\x57\\xC0"

ConVar version_cvar;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if(GetEngineVersion() == Engine_Left4Dead2)
	{
		return APLRes_Success;
	}
	strcopy(error, err_max, "Plugin only supports Left 4 Dead 2");
	return APLRes_SilentFailure;
}

public Plugin myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESC,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}

public void OnPluginStart()
{
	version_cvar = CreateConVar("sm_l4d_dr_version", PLUGIN_VERSION, "L4D Dead Ringer version", 0|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if(version_cvar != null)
		SetConVarString(version_cvar, PLUGIN_VERSION);
	
	DeadRinger_EnableComm = CreateConVar("sm_l4d_dr_enable_fdcmd", "1.0", "Toggle whether the sm_fd command is available for use.", FCVAR_ARCHIVE, true, 0.0, true, 1.0);
	DeadRinger_RechargeTime = CreateConVar("sm_l4d_dr_recharge_timelimit", "8.0", "Set the time limit until the Dead Ringer fully recharges.", FCVAR_ARCHIVE, true, 0.0, true, 100.0);
	DeadRinger_FakeWeaponTime = CreateConVar("sm_l4d_dr_wepfake_time", "5.0", "How long the fake weapons last. 0 = forever.", FCVAR_ARCHIVE, true, 0.0, true, 100.0);
	DeadRinger_DisableAttack = CreateConVar("sm_l4d_dr_no_attack", "1.0", "Toggle whether cloaked users can attack.", FCVAR_ARCHIVE, true, 0.0, true, 1.0);
	DeadRinger_RemovePins = CreateConVar("sm_l4d_dr_remove_pins", "1.0", "Remove pins from pinning infected on DR use?", FCVAR_ARCHIVE, true, 0.0, true, 1.0);
	DeadRinger_CloakTime = CreateConVar("sm_l4d_dr_cloak_timelimit", "6.5", "Set the time limit the Dead Ringer cloaks the user for.", FCVAR_ARCHIVE, true, 0.0, true, 100.0);
	DeadRinger_CorpseMode = CreateConVar("sm_l4d_dr_corpse_type", "0.0", "Toggle which corpse type to use for survivors. 0 = static, 1 = ragdoll, 2 = none.", FCVAR_ARCHIVE, true, 0.0, true, 2.0);
	DeadRinger_Transmit = CreateConVar("sm_l4d_dr_hide_from_team", "0.0", "Hide cloaked users from their teammates?", FCVAR_ARCHIVE, true, 0.0, true, 1.0);
	for (int client = 1; client <= MaxClients; client++) {
		isTriggerable[client] = true;
		isActive[client] = false;
	}
	RegConsoleCmd("sm_fd", DeadRinger_Command, "Toggle the L4D Dead Ringer.");
	RegAdminCmd("sm_fd_ply", DeadRinger_Force_Command, ADMFLAG_SLAY, "Toggle the Dead Ringer on a specified player.");
	RegAdminCmd("sm_hitself", HitMyself_Command, ADMFLAG_SLAY, "Manually activate the DR.");
	
	int ply_manager = FindEntityByClassname(-1, "terror_player_manager");
	if (IsValidEntity(ply_manager))
	{ SDKHook(ply_manager, THINK_HOOK, Hook_OnThinkPost); }
	
	AutoExecConfig(true, "l4d_deadringer");
	
	char filePath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, filePath, sizeof(filePath), "gamedata/%s.txt", GAMEDATA);
	if( FileExists(filePath) )
	{
		hConf = LoadGameConfigFile(GAMEDATA); // For some reason this doesn't return null even for invalid files, so check they exist first.
	} else {
		PrintToServer("[SM] %s unable to get %s.txt gamedata file. Generating...", PLUGIN_NAME, GAMEDATA);
		
		Handle fileHandle = OpenFile(filePath, "w"); 
		if (fileHandle == null)
		{ SetFailState("[SM] Couldn't generate gamedata file!"); }
		
		WriteFileLine(fileHandle, "\"Games\"");
		WriteFileLine(fileHandle, "{");
		WriteFileLine(fileHandle, "	\"left4dead2\"");
		WriteFileLine(fileHandle, "	{");
		WriteFileLine(fileHandle, "		\"Signatures\"");
		WriteFileLine(fileHandle, "		{");
		WriteFileLine(fileHandle, "			// Below 3 signatures were taken from https://forums.alliedmods.net/showthread.php?t=109715");
		WriteFileLine(fileHandle, "			// Except OnPummelEnded's windows signature. I had to get a fresh new one.");
		WriteFileLine(fileHandle, "			\"%s\"", NAME_ONPUMMELENDED);
		WriteFileLine(fileHandle, "			{");
		WriteFileLine(fileHandle, "				\"library\"	\"server\"");
		WriteFileLine(fileHandle, "				\"linux\"	\"%s\"", SIG_ONPUMMELENDED_LINUX);
		WriteFileLine(fileHandle, "				\"windows\"	\"%s\"", SIG_ONPUMMELENDED_WINDOWS);
		WriteFileLine(fileHandle, "				\"mac\"		\"%s\"", SIG_ONPUMMELENDED_LINUX);
		WriteFileLine(fileHandle, "			}");
		WriteFileLine(fileHandle, "			\"%s\"", NAME_ONPOUNCEEND);
		WriteFileLine(fileHandle, "			{");
		WriteFileLine(fileHandle, "				\"library\"	\"server\"");
		WriteFileLine(fileHandle, "				\"linux\"	\"%s\"", SIG_ONPOUNCEEND_LINUX);
		WriteFileLine(fileHandle, "				\"windows\"	\"%s\"", SIG_ONPOUNCEEND_WINDOWS);
		WriteFileLine(fileHandle, "				\"mac\"		\"%s\"", SIG_ONPOUNCEEND_LINUX);
		WriteFileLine(fileHandle, "				/* 55 8B EC 51 53 8B D9 80 BB AC 3E 00 00 00  */");
		WriteFileLine(fileHandle, "			}");
		WriteFileLine(fileHandle, "			\"%s\"", NAME_STARTACTIVATIONTIMER);
		WriteFileLine(fileHandle, "			{");
		WriteFileLine(fileHandle, "				\"library\"	\"server\"");
		WriteFileLine(fileHandle, "				\"linux\"	\"%s\"", SIG_STARTACTIVATIONTIMER_LINUX);
		WriteFileLine(fileHandle, "				\"windows\"	\"%s\"", SIG_STARTACTIVATIONTIMER_WINDOWS);
		WriteFileLine(fileHandle, "				\"mac\"		\"%s\"", SIG_STARTACTIVATIONTIMER_LINUX);
		WriteFileLine(fileHandle, "				/* 55 8B EC F3 0F 10 4D 0C 0F 57 C0  */");
		WriteFileLine(fileHandle, "			}");
		WriteFileLine(fileHandle, "			\"%s\"", NAME_RELEASETONGUEVICTIM);
		WriteFileLine(fileHandle, "			{");
		WriteFileLine(fileHandle, "				\"library\"	\"server\"");
		WriteFileLine(fileHandle, "				\"linux\"	\"%s\"", SIG_RELEASETONGUEVICTIM_LINUX);
		WriteFileLine(fileHandle, "				\"windows\"	\"%s\"", SIG_RELEASETONGUEVICTIM_WINDOWS);
		WriteFileLine(fileHandle, "				\"mac\"		\"%s\"", SIG_RELEASETONGUEVICTIM_LINUX);
		WriteFileLine(fileHandle, "			}");
		WriteFileLine(fileHandle, "			\"%s\"", NAME_ONRIDEENDED);
		WriteFileLine(fileHandle, "			{");
		WriteFileLine(fileHandle, "				\"library\"	\"server\"");
		WriteFileLine(fileHandle, "				\"linux\"	\"%s\"", SIG_ONRIDEENDED_LINUX);
		WriteFileLine(fileHandle, "				\"windows\"	\"%s\"", SIG_ONRIDEENDED_WINDOWS);
		WriteFileLine(fileHandle, "				\"mac\"		\"%s\"", SIG_ONRIDEENDED_LINUX);
		WriteFileLine(fileHandle, "			}");
		WriteFileLine(fileHandle, "		}");
		WriteFileLine(fileHandle, "	}");
		WriteFileLine(fileHandle, "}");
		
		CloseHandle(fileHandle);
		hConf = LoadGameConfigFile(GAMEDATA);
		if (hConf == null)
		{ SetFailState("[SM] Failed to load auto-generated gamedata file!"); }
	}
}

public void OnPluginEnd()
{
	int ply_manager = FindEntityByClassname(-1, "terror_player_manager");
	if (IsValidEntity(ply_manager))
	{ SDKUnhook(ply_manager, THINK_HOOK, Hook_OnThinkPost); }
	for (int i = 1; i <= 2048; i++) {
		if (!IsValidEntity(i)) continue;
		SetTransmit(i, false);
		if (hasEffects[i])
		{ ApplyEffectsToEntity(i, false); }
	}
	for (int client = 1; client <= MaxClients; client++) {
		if (IsValidEntity(g_BloodPool[client]))
		{
			char class[128];
			GetEntityClassname(g_BloodPool[client], class, sizeof(class));
			if (StrEqual(class, "info_particle_system", false))
			{
				AcceptEntityInput(g_BloodPool[client], "Stop"); 
				AcceptEntityInput(g_BloodPool[client], "Kill"); 
			}
		}
		if (!IsValidClient(client)) continue;
		isTriggerable[client] = false;
		isActive[client] = false;
		RemoveCorpse(client);
	}
}

public void OnMapStart() {
	int ply_manager = FindEntityByClassname(-1, "terror_player_manager");
	if (IsValidEntity(ply_manager))
	{ SDKHook(ply_manager, THINK_HOOK, Hook_OnThinkPost); }
	//PrecacheScriptSound(NECKSNAP_SND);
}

void Hook_OnThinkPost(int entity) {
	if (!IsValidEntity(entity))
	{ return; }
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i))
		{ continue; }
		if (isCloaked[i])
		{
			if (GetEntProp(entity, Prop_Send, "m_bAlive", 2, i) > 0)
			{ SetEntProp(entity, Prop_Send, "m_bAlive", 0, 2, i); }
			if (GetEntProp(entity, Prop_Send, "m_isIncapacitated", 2, i) > 0)
			{ SetEntProp(entity, Prop_Send, "m_isIncapacitated", 0, 2, i); }
			if (GetEntProp(entity, Prop_Send, "m_iHealth", 2, i) > 0)
			{ SetEntProp(entity, Prop_Send, "m_iHealth", 0, 2, i); }
			if (GetEntProp(entity, Prop_Send, "m_grenade", 2, i) > 0)
			{ SetEntProp(entity, Prop_Send, "m_grenade", 0, 2, i); }
			if (GetEntProp(entity, Prop_Send, "m_firstAidSlot", 2, i) > 0)
			{ SetEntProp(entity, Prop_Send, "m_firstAidSlot", 0, 2, i); }
			if (GetEntProp(entity, Prop_Send, "m_pillsSlot", 2, i) > 0)
			{ SetEntProp(entity, Prop_Send, "m_pillsSlot", 0, 2, i); }
		}
		//if (bClientAlive[i] > 0)
		//{ PrintToChatAll("%i", bClientAlive[i]); }
	}
}

Action DeadRinger_Command(int client, char args) {
	if (!IsValidClient(client)) return Plugin_Handled;
	if (!GetConVarBool(DeadRinger_EnableComm) && !isCloaked[client]) return Plugin_Handled;
	TriggerDeadRinger(client, true, false, false, false);
	return Plugin_Handled;
}

/*Action DeadRinger_Force_Command(int client, char args) {
	if (args != 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_fd_ply <target>");
		return Plugin_Handled;
	}
	
	char arg1[32];
	//Get the first argument
	GetCmdArg(1, arg1, sizeof(arg1));
	
	//target_name - stores the noun identifying the target(s)
	//target_list - array to store clients
	//target_count - variable to store number of clients
	//tn_is_ml - stores whether the noun must be translated
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE, //Only allow alive players
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		//This function replies to the admin with a failure message
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (int i = 0; i < target_count; i++)
	{
		int trigger_func = TriggerDeadRinger(i, true, false, false, false);
		if (trigger_func > 0)
		{ ReplyToCommand(client, "[SM] Successfully toggled %s's AC-DR status to active.", arg1); }
		else if (trigger_func == 0)
		{ ReplyToCommand(client, "[SM] Successfully toggled %s's AC-DR status to inactive.", arg1); }
		else
		{ ReplyToCommand(client, "[SM] Could not toggle %s's AC-DR status.", arg1); }
	}
	return Plugin_Handled;
}*/

Action DeadRinger_Force_Command(int client, char args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_fd_ply <target>");
		return Plugin_Handled;
	}
	
	char arg1[32];
	/* Get the first argument */
	GetCmdArg(1, arg1, sizeof(arg1));
	
	/**
	 * target_name - stores the noun identifying the target(s)
	 * target_list - array to store clients
	 * target_count - variable to store number of clients
	 * tn_is_ml - stores whether the noun must be translated
	 */
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE, /* Only allow alive players */
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		/* This function replies to the admin with a failure message */
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (int i = 0; i < target_count; i++)
	{
		if (!IsValidClient(target_list[i])) continue;
		
		int trigger_func = TriggerDeadRinger(target_list[i], true, false, false, false);
		if (trigger_func > 0)
		{ ReplyToCommand(client, "[SM] Successfully toggled %N's AC-DR status to active.", target_list[i]); }
		else if (trigger_func == 0)
		{ ReplyToCommand(client, "[SM] Successfully toggled %N's AC-DR status to inactive.", target_list[i]); }
		else
		{ ReplyToCommand(client, "[SM] Could not toggle %N's AC-DR status.", target_list[i]); }
	}
	
	return Plugin_Handled;
}

Action HitMyself_Command(int client, char args) {
	if (!IsValidClient(client)) return Plugin_Handled;
	if (args < 1 || args > 1)
	{
		//SDKHooks_TakeDamage(client, client, client, 1.0, DMG_GENERIC, -1);
		BeginDeadRingerFromDamage(client, client, client, 1.0, 0, -1);
		return Plugin_Handled;
	}
	char arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	int ply = FindTarget(client, arg1, false, false);
	if (ply == -1 || !IsValidClient(ply))
	{
		ReplyToCommand(client, "[SM] %s is not a valid player!", arg1);
		return Plugin_Handled;
	}
	char ply_name[MAX_NAME_LENGTH];
	GetClientName(ply, ply_name, sizeof(ply_name));
	if (!IsPlayerAlive(ply) || IsClientObserver(ply))
	{
		ReplyToCommand(client, "[SM] %s is either dead or a spectator!", ply_name);
		return Plugin_Handled;
	}
	
	BeginDeadRingerFromDamage(ply, ply, ply, 1.0, 0, -1);
	return Plugin_Handled;
}

public void OnClientDisconnect(int client)
{
	isTriggerable[client] = true;
	isActive[client] = false;
	isCloaked[client] = false;
	RemoveCorpse(client);
	SDKUnhook(client, MAIN_DAMAGE_HOOK, Hook_OnTakeDamagePost);
	//SDKUnhook(client, CHANGE_DAMAGE_HOOK, Hook_OnTakeDamage);
}

Action Hook_SetTransmit(int client, int entity)
{
	if (!IsValidClient(client)) return Plugin_Continue;
	int affected_entity = entity;
	if (!IsValidClient(entity) && HasEntProp(entity, Prop_Send, "moveparent"))
	{
		int moveparent = GetEntPropEnt(entity, Prop_Send, "moveparent");
		if (IsValidClient(moveparent))
		{ affected_entity = moveparent; }
	}
	if( client == affected_entity || !GetConVarBool(DeadRinger_Transmit) &&
	(IsValidClient(affected_entity) && GetClientTeam(client) == GetClientTeam(affected_entity) || IsClientObserver(client)) )
	{ return Plugin_Continue; }
	return Plugin_Handled;
}

void Hook_OnTakeDamagePost(int client, int attacker, int inflictor, float damage, int damageType, int weapon, 
const float damageForce[3], const float damagePosition[3])
{
	BeginDeadRingerFromDamage(client, attacker, inflictor, damage, damageType, weapon);
}

void BeginDeadRingerFromDamage(int client, int attacker, int inflictor, float damage, int damageType, int weapon)
{
	if (damage <= 0.0)
	{ return; }
	
	if (!IsValidClient(client)) 
	{ return; }
	if (!canTriggerDR(client))
	{ return; }
	if (!IsPlayerAlive(client) && (isActive[client] || isCloaked[client]))
	{
		TriggerDeadRinger(client, true, true, true, false);
		if (isCloaked[client])
		{
			DeadRingerUncloak(client);
		}
		return;
	}
	/*if (GetConVarInt(FindConVar("mp_friendlyfire")) <= 0 && IsValidClient(attacker))
	{
		if (GetClientTeam(attacker) == GetClientTeam(client) && attacker != client)
		{ return; }
	}*/
	
	if (isCloaked[client])
	{ return; }
	
	if (isTriggerable[client] && isActive[client])
	{
		DeadRingerCloak(client, attacker, inflictor, damageType, weapon);
	}
}

void DeadRingerCloak(int client, int attacker, int inflictor, int damageType, int weapon)
{
	isTriggerable[client] = false;
	isActive[client] = false;
	isCloaked[client] = true;
	
	char class_infl[PLATFORM_MAX_PATH+1];
	if (IsValidEntity(inflictor))
	{ GetEntityClassname(inflictor, class_infl, sizeof(class_infl) ); }
	
	int event_victim = GetClientUserId(client);
	int event_attacker = IsValidClient(attacker) ? GetClientUserId(attacker) : -1;
	
	Handle event1 = CreateEvent("player_death");
	if (event1 != null)
	{
		char event_attackername[MAX_NAME_LENGTH] = "";
		char event_victimname[MAX_NAME_LENGTH] = "";
		bool event_attackerisbot = false;
		bool event_victimisbot = false;
		if (IsValidClient(attacker))
		{
			GetClientName(attacker, event_attackername, sizeof(event_attackername));
			if (IsFakeClient(attacker))
			{ event_attackerisbot = true; }
		}
		if (IsFakeClient(client))
		{ event_victimisbot = true; }
		GetClientName(client, event_victimname, sizeof(event_victimname));
		
		char event_weapon[MAX_NAME_LENGTH] = "world";
		if (IsValidEntity(weapon))
		{ GetEntityClassname(weapon, event_weapon, sizeof(event_weapon)); }
		
		SetEventInt(event1, "userid", event_victim);
		SetEventInt(event1, "entityid", EntRefToEntIndex(client));
		SetEventInt(event1, "attacker", event_attacker);
		SetEventString(event1, "attackername", event_attackername);
		SetEventInt(event1, "attackerentid", EntRefToEntIndex(client));
		SetEventString(event1, "weapon", event_weapon);
		SetEventBool(event1, "attackerisbot", event_attackerisbot);
		SetEventString(event1, "victimname", event_victimname);
		SetEventBool(event1, "victimisbot", event_victimisbot);
		SetEventInt(event1, "type", damageType);
		
		FireEvent(event1);
	}
	
	if(IsValidClient(client))
	{
		SDKUnhook(client, MAIN_DAMAGE_HOOK, Hook_OnTakeDamagePost);
		SpawnCorpse(client);
		SetTransmit(client);
		DoStuffToWeapons(client);
		ApplyEffectsToEntity(client);
		if (DeadRinger_CloakTime != null)
		{ g_UncloakTimer[client] = CreateTimer(GetConVarFloat(DeadRinger_CloakTime), Timer_Uncloak, client); }
		else
		{ g_UncloakTimer[client] = CreateTimer(6.5, Timer_Uncloak, client); }
		g_BoostTimer[client] = CreateTimer(3.0, Timer_Boost, client);
		
		if (DeadRinger_CloakTime == null || GetConVarFloat(DeadRinger_CloakTime) > 0.0)
		{ WeaponAttackAvailable(client, false); }
		RemovePinFromClient(client);
		CreateTimer(0.75, Timer_Vocals, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	/*static int other_Clients[MaxClients+1] = -1;
	for (int loopclient = 1; loopclient <= MaxClients; loopclient++)
	{
		if (!IsValidClient(loopclient)) return;
		if (loopclient == client) return;
		other_Clients[loopclient] = loopclient;
	}*/
	
	//Handle music_usermsg = StartMessage("MusicCmd", other_Clients, sizeof(other_Clients));
	//Handle music_usermsg = StartMessageAll("MusicCmd");
	//BfWriteByte(music_usermsg, 901);
	//EndMessage();
	
	PrintHintText(client, "DR activated.");
}

void DeadRingerUncloak(int client, bool killtimer = true)
{
	if (!IsValidClient(client))
	{ return; }
	SetTransmit(client, false);
	DoStuffToWeapons(client, false);
	ApplyEffectsToEntity(client, false);
	if (g_UncloakTimer[client] != null && killtimer)
	{ KillTimer(g_UncloakTimer[client]); }
	if (IsPlayerAlive(client)) {
		//SetEntityRenderColor(client, 255, 255, 255, 255);
	}
	//EmitGameSoundToAll(UNCLOAK_SND, client);
	WeaponAttackAvailable(client, true);
	
	if (DeadRinger_RechargeTime != null)
	{ g_ReadyTimer[client] = CreateTimer(GetConVarFloat(DeadRinger_RechargeTime), Timer_Ready, client); }
	else
	{ g_ReadyTimer[client] = CreateTimer(8.0, Timer_Ready, client); }
	PrintHintText(client, "DR Uncloaked.");
	
	isCloaked[client] = false;
}
// Below function taken and modified from infected_release plugin.
void RemovePinFromClient(int client)
{
	if (!GetConVarBool(DeadRinger_RemovePins)) return;
	if (IsValidClient(client) && IsSurvivor(client))
	{
		int j_attack = GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker");
		int h_attack = GetEntPropEnt(client, Prop_Send, "m_pounceAttacker");
		int c_attack = GetEntPropEnt(client, Prop_Send, "m_pummelAttacker");
		int c_carrier = GetEntPropEnt(client, Prop_Send, "m_carryAttacker");
		int s_attack = GetEntPropEnt(client, Prop_Send, "m_tongueOwner");
		//PrintToChatAll("Attack: %i Carry: %i", c_attack, c_carrier);
		
		if (IsValidClient(j_attack) && GetEntProp(j_attack, Prop_Send, "m_zombieClass") == ZOMBIECLASS_JOCKEY)
		//{ ExecuteCheatCommand(j_attack, "dismount"); }
		{ CallOnRideEnded(j_attack, client); }
		else if (IsValidClient(h_attack) && GetEntProp(h_attack, Prop_Send, "m_zombieClass") == ZOMBIECLASS_HUNTER)
		{ CallOnPounceEnd(h_attack); }
		else if (IsValidClient(c_attack) && GetEntProp(c_attack, Prop_Send, "m_zombieClass") == ZOMBIECLASS_CHARGER)
		{
			CallOnPummelEnded(c_attack);
			CallResetAbility(c_attack, GetConVarFloat(FindConVar("z_charge_interval")));
		}
		else if (IsValidClient(c_carrier) && GetEntProp(c_carrier, Prop_Send, "m_zombieClass") == ZOMBIECLASS_CHARGER)
		{
			SetEntProp(client, Prop_Send, "m_carryAttacker", -1);
			SetEntProp(c_carrier, Prop_Send, "m_carryVictim", -1);
		}
		else if (IsValidClient(s_attack) && GetEntProp(s_attack, Prop_Send, "m_zombieClass") == ZOMBIECLASS_SMOKER)
		{
			CallReleaseTongueVictim(s_attack);
			//SlapPlayer(s_attack, 0, false);
			//if (!IsSoundPrecached(NECKSNAP_SND))
			//{
				PrecacheSound(NECKSNAP_SND);
			//}
			EmitGameSoundToAll(NECKSNAP_SND, client);
		}
	}
}

void ApplyEffectsToEntity(int entity, bool boolean = true)
{
	if (!IsValidEntity(entity)) return;
	if (boolean && !hasEffects[entity])
	{
		//initialRender[entity] = GetEntityRenderMode(entity);
		hasEffects[entity] = true;
		SetEntityRenderMode(entity, RENDER_GLOW);
		int initial_r = 255;
		int initial_g = 255;
		int initial_b = 255;
		int initial_a = 255;
		GetEntityRenderColor(entity, initial_r, initial_g, initial_b, initial_a);
		//initialAlpha[entity] = initial_a;
		SetEntityRenderColor(entity, initial_r, initial_g, initial_b, 127);
	}
	else if (hasEffects[entity])
	{
		//SetEntityRenderMode(entity, initialRender[entity]);
		hasEffects[entity] = false;
		SetEntityRenderMode(entity, RENDER_NORMAL);
		int initial_r = 255;
		int initial_g = 255;
		int initial_b = 255;
		static int MUDA = 1337; // Translation: Useless!
		GetEntityRenderColor(entity, initial_r, initial_g, initial_b, MUDA);
		//SetEntityRenderColor(entity, initial_r, initial_g, initial_b, initialAlpha[entity]);
		SetEntityRenderColor(entity, initial_r, initial_g, initial_b, 255);
	}
}

Action Timer_Vocals(Handle timer, int client)
{
	if (!IsValidClient(client)) return;
	if (!IsSurvivor(client)) return;
	
	BeginVocalizations(client);
}

void BeginVocalizations(int client)
{
	if (!IsValidClient(client)) return;
	bool hasFirstVocal = false;
	bool hasSecondVocal = false;
	int backup_Survivor = -1;
	//bool hasEllis = false;
	//int survivorCount = 0;
	for (int loopclient = 1; loopclient <= MaxClients; loopclient++)
	{
		if (hasFirstVocal && hasSecondVocal) return;
		if (!IsValidClient(loopclient)) continue;
		if (!IsSurvivor(client) || GetClientTeam(loopclient) != GetClientTeam(client) || loopclient == client || 
		!IsPlayerAlive(loopclient) || isCloaked[loopclient]) continue;
		
		//survivorCount++;
		/*if (!hasEllis)
		{
			char surv_name[24];
			GetSurvivorSceneName(loopclient, true, surv_name, sizeof(surv_name));
			if (StrEqual(surv_name, "ellis", false))
			{ hasEllis = true; }
		}*/
		
		int set = GetClientSurvivorSet(client);
		int char_netprop = GetEntProp(client, Prop_Send, "m_survivorCharacter");
		if (set <= 0) continue;
		int loopchar_netprop = GetEntProp(loopclient, Prop_Send, "m_survivorCharacter");
		int loopset = GetClientSurvivorSet(loopclient);
		
		if (!IsValidEntity(backup_Survivor)) backup_Survivor = loopclient;
		
		if (hasFirstVocal && !hasSecondVocal)
		{
			hasSecondVocal = true;
			//SpoutPanicFromDeath(client, loopclient, backup_Survivor, hasEllis, survivorCount);
			SpoutPanicFromDeath(client, loopclient, backup_Survivor);
		}
		
		if (loopset <= 0 || set != loopset || char_netprop == loopchar_netprop) continue;
		
		if (!hasFirstVocal)
		{
			hasFirstVocal = true;
			SpoutDeathOfSurvivorName(client, loopclient);
		}
	}
}

void SpoutDeathOfSurvivorName(int victim, int client)
{
	if (!IsValidClient(victim) || !IsValidClient(client)) return;
	int char_netprop = GetEntProp(victim, Prop_Send, "m_survivorCharacter");
	int loopchar_netprop = GetEntProp(client, Prop_Send, "m_survivorCharacter");
	if (char_netprop == S_CHAR_UNKNOWN || loopchar_netprop == S_CHAR_UNKNOWN || char_netprop == loopchar_netprop) return;
	//PrintToChatAll("%i %i", char_netprop, loopchar_netprop);
	static char cl_model[PLATFORM_MAX_PATH];
	GetClientModel(client, cl_model, sizeof(cl_model));
	
	// Prepare survivor names for scenes.
	char cl_survname[24];
	GetSurvivorSceneName(client, false, cl_survname, sizeof(cl_survname));
	char cl_victimname[24];
	GetSurvivorSceneName(victim, true, cl_victimname, sizeof(cl_victimname));
	if (StrEqual(cl_survname, "", false) || StrEqual(cl_victimname, "", false)) return;
	
	// Get scene numbers
	int i_scenenum = GetCryOutNumber(cl_survname, cl_victimname);
	
	// Placeholder number for first scene
	char cl_placeHold_Num[2]; cl_placeHold_Num = "";
	if (i_scenenum < 10)
	{ cl_placeHold_Num = "0"; }
	
	// Debug
	//PrintToChatAll("cl_survname: %s cl_victimname: %s int: i_scenenum cl_placeHold_Num: %s", cl_survname, cl_victimname, cl_placeHold_Num);
	//if (StrEqual(cl_scenenum, "", false)) return;
	
	// First scene ([Nick!])
	char scene_str[128];
	Format(scene_str, sizeof(scene_str), "scenes/%s/name%s%s%i.vcd", cl_survname, cl_victimname, cl_placeHold_Num, i_scenenum);
	//PrintToChatAll("%s", scene_str);
	PlayScene(client, scene_str);
}

void PlayScene(int client, const char[] str)
{
	int scene = CreateEntityByName("instanced_scripted_scene");
	DispatchKeyValue(scene, "SceneFile", str);
	SetEntPropEnt(scene, Prop_Data, "m_hOwner", client);
	DispatchKeyValue(scene, "busyactor", "0");
	DispatchSpawn(scene);
	ActivateEntity(scene);
	AcceptEntityInput(scene, "Start");
}

//void SpoutPanicFromDeath(int victim, int client, int backup_cl, bool hasEllis = false, int survivorCount = 1)
void SpoutPanicFromDeath(int victim, int client, int backup_cl)
{
	if (!IsValidClient(victim) || !IsValidClient(client)) return;
	int char_netprop = GetEntProp(victim, Prop_Send, "m_survivorCharacter");
	int loopchar_netprop = GetEntProp(client, Prop_Send, "m_survivorCharacter");
	if (char_netprop == S_CHAR_UNKNOWN || loopchar_netprop == S_CHAR_UNKNOWN || char_netprop == loopchar_netprop) return;
	//PrintToChatAll("%i %i", char_netprop, loopchar_netprop);
	static char cl_model[PLATFORM_MAX_PATH];
	GetClientModel(client, cl_model, sizeof(cl_model));
	
	char cl_survname[24];
	GetSurvivorSceneName(client, false, cl_survname, sizeof(cl_survname));
	char cl_victimname[24];
	GetSurvivorSceneName(victim, true, cl_victimname, sizeof(cl_victimname));
	if (StrEqual(cl_survname, "", false) || StrEqual(cl_victimname, "", false)) return;
	
	bool useBackup = false;
	if (StrEqual(cl_survname, "biker", false))
	{
		useBackup = true;
		GetSurvivorSceneName(backup_cl, false, cl_survname, sizeof(cl_survname));
		if (StrEqual(cl_survname, "biker", false)) return;
	}
	char extra_str[24]; extra_str = "";
	//int i_dd_scenenum = GetDoubleDeathResponseNumber(cl_survname, extra_str, sizeof(extra_str), hasEllis, survivorCount);
	int i_dd_scenenum = GetDoubleDeathResponseNumber(cl_survname, extra_str, sizeof(extra_str));
	
	//PrintToChatAll("cl_survname: %s cl_victimname: %s int: i_scenenum", cl_survname, cl_victimname);
	//if (StrEqual(cl_scenenum, "", false)) return;
	
	char scene_str[128];
	Format(scene_str, sizeof(scene_str), "scenes/%s/doubledeathresponse%s0%i.vcd", cl_survname, extra_str, i_dd_scenenum);
	//PrintToChatAll("%s", scene_str);
	PlayScene(useBackup ? backup_cl : client, scene_str);
}

void GetSurvivorSceneName(int client, bool is_victim = false, char[] str, int maxlength)
{
	if (!IsValidClient(client)) return;
	
	static char cl_model[PLATFORM_MAX_PATH];
	GetClientModel(client, cl_model, sizeof(cl_model));
	//PrintToChatAll("%s", cl_model);
	if (StrEqual(cl_model, "models/survivors/survivor_gambler.mdl", false))
	{ is_victim ? strcopy(str, maxlength, "nick") : strcopy(str, maxlength, "gambler"); }
	else if (StrEqual(cl_model, "models/survivors/survivor_producer.mdl", false))
	{ is_victim ? strcopy(str, maxlength, "rochelle") : strcopy(str, maxlength, "producer"); }
	else if (StrEqual(cl_model, "models/survivors/survivor_coach.mdl", false))
	{ is_victim ? strcopy(str, maxlength, "coach") : strcopy(str, maxlength, "coach"); }
	else if (StrEqual(cl_model, "models/survivors/survivor_mechanic.mdl", false))
	{ is_victim ? strcopy(str, maxlength, "ellis") : strcopy(str, maxlength, "mechanic"); }
	else if (StrEqual(cl_model, "models/survivors/survivor_namvet.mdl", false))
	{ is_victim ? strcopy(str, maxlength, "bill") : strcopy(str, maxlength, "namvet"); }
	else if (StrEqual(cl_model, "models/survivors/survivor_teenangst.mdl", false))
	{ is_victim ? strcopy(str, maxlength, "zoey") : strcopy(str, maxlength, "teengirl"); }
	else if (StrEqual(cl_model, "models/survivors/survivor_biker.mdl", false))
	{ is_victim ? strcopy(str, maxlength, "francis") : strcopy(str, maxlength, "biker"); }
	else if (StrEqual(cl_model, "models/survivors/survivor_manager.mdl", false))
	{ is_victim ? strcopy(str, maxlength, "louis") : strcopy(str, maxlength, "manager"); }
}

int GetClientSurvivorSet(int client)
{
	if (!IsValidClient(client)) return 0;
	if (!IsSurvivor(client)) return 0;
	static char cl_model[PLATFORM_MAX_PATH];
	GetClientModel(client, cl_model, sizeof(cl_model));
	if (StrEqual(cl_model, "models/survivors/survivor_namvet.mdl", false) || 
	StrEqual(cl_model, "models/survivors/survivor_teenangst.mdl", false) || 
	StrEqual(cl_model, "models/survivors/survivor_biker.mdl", false) || 
	StrEqual(cl_model, "models/survivors/survivor_manager.mdl", false))
	{ return 1; }
	else if (StrEqual(cl_model, "models/survivors/survivor_gambler.mdl", false) || 
	StrEqual(cl_model, "models/survivors/survivor_producer.mdl", false) || 
	StrEqual(cl_model, "models/survivors/survivor_mechanic.mdl", false) || 
	StrEqual(cl_model, "models/survivors/survivor_coach.mdl", false))
	{ return 2; }
	return 0;
}

int GetCryOutNumber(const char[] cl_survname, const char[] cl_victimname)
{
	//PrintToChatAll("cl_survname: %s cl_victimname: %s", cl_survname, cl_victimname);
	if (StrEqual(cl_survname, "gambler", false))
	{
		if (StrEqual(cl_victimname, "rochelle", false)) {
			switch (GetRandomInt(1, 2)) {
				case 1: { return 1; }
				case 2: { return 12; }
			}
		} else if (StrEqual(cl_victimname, "coach", false)) {
			return GetRandomInt(1, 2);
		} else if (StrEqual(cl_victimname, "ellis", false)) {
			switch (GetRandomInt(1, 3)) {
				case 1: { return 4; }
				case 2: { return 7; }
				case 3: { return 13; }
			}
		}
	}
	else if (StrEqual(cl_survname, "producer", false))
	{
		if (StrEqual(cl_victimname, "nick", false)) {
			switch (GetRandomInt(1, 2)) {
				case 1: { return 9; }
				case 2: { return 10; }
			}
		} else if (StrEqual(cl_victimname, "coach", false)) {
			switch (GetRandomInt(1, 2)) {
				case 1: { return 3; }
				case 2: { return 5; }
			}
		} else if (StrEqual(cl_victimname, "ellis", false)) {
			switch (GetRandomInt(1, 2)) {
				case 1: { return 1; }
				case 2: { return 5; }
			}
		}
	}
	else if (StrEqual(cl_survname, "coach", false))
	{
		if (StrEqual(cl_victimname, "nick", false)) {
			switch (GetRandomInt(1, 3)) {
				case 1: { return 1; }
				case 2: { return 5; }
				case 3: { return GetRandomInt(7, 8); }
			}
		} else if (StrEqual(cl_victimname, "rochelle", false)) {
			return GetRandomInt(7, 8);
		} else if (StrEqual(cl_victimname, "ellis", false)) {
			switch (GetRandomInt(1, 2)) {
				case 1: { return GetRandomInt(1, 2); }	
				case 2: { return 4; }
			}
		}
	}
	else if (StrEqual(cl_survname, "mechanic", false))
	{
		if (StrEqual(cl_victimname, "nick", false)) {
			switch (GetRandomInt(1, 3)) {
				case 1: { return 1; }
				case 2: { return 13; }
				case 3: { return 15; }
			}
		} else if (StrEqual(cl_victimname, "rochelle", false)) {
			switch (GetRandomInt(1, 3)) {
				case 1: { return 2; }
				case 2: { return GetRandomInt(12, 13); }
				case 3: { return 15; }
			}
		} else if (StrEqual(cl_victimname, "coach", false)) {
			switch (GetRandomInt(1, 2)) {
				case 1: { return 4; }
				case 2: { return 7; }
			}
		}
	}
	else if (StrEqual(cl_survname, "teengirl", false))
	{
		if (StrEqual(cl_victimname, "bill", false)) {
			switch (GetRandomInt(1, 10)) {
				case 1: { return 1; }
				case 2: { return GetRandomInt(3, 4); }
				case 3: { return GetRandomInt(6, 7); }
				case 4: { return 9; }
				case 5: { return GetRandomInt(10, 13); }	
				case 6:	{ return GetRandomInt(15, 17); }
				case 7: { return GetRandomInt(22, 23); }
				case 8: { return 26; }
				case 9: { return 28; }
				case 10: { return 30; }
			}
		} else if (StrEqual(cl_victimname, "francis", false)) {
			switch (GetRandomInt(1, 5)) {
				case 1: { return GetRandomInt(2, 6); }
				case 2: { return 9; }
				case 3: { return GetRandomInt(10, 12); }
				case 4: { return 7; }
				case 5: { return GetRandomInt(20, 23); }
			}
		} else if (StrEqual(cl_victimname, "louis", false)) {
			switch (GetRandomInt(1, 2)) {
				case 1: { return 1; }
				case 2: { return GetRandomInt(4, 6); }
			}
		}
	}
	else if (StrEqual(cl_survname, "namvet", false) || StrEqual(cl_survname, "biker", false) || StrEqual(cl_survname, "manager", false))
	{ return GetRandomInt(1, 2); }
	return 0;
}

//int GetDoubleDeathResponseNumber(const char[] cl_survname, char[] str, int maxlength, bool hasEllis = false, int survivorCount = 1)
int GetDoubleDeathResponseNumber(const char[] cl_survname, char[] str, int maxlength)
{
	/*bool two_left = false;
	bool hasEllis = false;
	int survivorCount = 0;
	for (int loopclient = 1; loopclient <= MaxClients; loopclient++)
	{
		if (!IsValidClient(loopclient)) continue;
		if (!IsSurvivor(client) || GetClientTeam(loopclient) != GetClientTeam(client) || loopclient == client || 
		!IsPlayerAlive(loopclient) || isCloaked[loopclient]) continue;
		
		survivorCount++;
		
		if (!hasEllis)
		{
			char surv_name[24];
			GetSurvivorSceneName(loopclient, true, surv_name, sizeof(surv_name));
			if (StrEqual(surv_name, "ellis", false))
			{ hasEllis = true; }
		}
		if (loopclient == sizeof(MaxClients) && survivorCount == 2)
		{ two_left = true; }
	}*/
	bool two_left = false;
	int tmp_survivorCount = 0;
	for (int loopclient = 1; loopclient <= MaxClients; loopclient++)
	{
		if (!IsValidClient(loopclient)) continue;
		if (!IsSurvivor(loopclient) || !IsPlayerAlive(loopclient) || isCloaked[loopclient]) continue;
		tmp_survivorCount++;
		if (tmp_survivorCount > 2)
		{ break; }
	}
	if (tmp_survivorCount == 2)
	{ two_left = false; }
	
	if (StrEqual(cl_survname, "coach", false))
	{
		if (two_left)
		{
			switch (GetRandomInt(1, 2))
			{
				case 1: { return GetRandomInt(3, 7); }
				case 2: { strcopy(str, maxlength, "quiet"); return 1; }
			}
		}
		else
		{
			return GetRandomInt(1, 2);
		}
	}
	else if (StrEqual(cl_survname, "gambler", false))
	{
		if (two_left)
		{
			/*if (hasEllis && GetRandomInt(1, 3) == 1)
			{
				strcopy(str, maxlength, "mechanic");
				return GetRandomInt(1, 2);
			}
			else*/
			//{
				switch (GetRandomInt(1, 2))
				{
					case 1: { return GetRandomInt(1, 2); }
					case 2: { return 4; }
				}
			//}
		}
		else
		{
			switch (GetRandomInt(1, 2))
			{
				case 1: { return 3; }
				case 2: { return 5; }
			}
		}
	}
	else if (StrEqual(cl_survname, "manager", false))
	{ return GetRandomInt(1, 2); }
	else if (StrEqual(cl_survname, "mechanic", false))
	{
		if (two_left)
		{
			return GetRandomInt(1, 2)*2; // 2, 4
		}
		else
		{
			switch (GetRandomInt(1, 2))
			{
				case 1: { return 1; }
				case 2: { return 3; }
			}
		}
	}
	else if (StrEqual(cl_survname, "namvet", false) || StrEqual(cl_survname, "producer", false))
	{
		if (two_left)
		{
			return 4;
		}
		else
		{
			return GetRandomInt(1, 2);
		}
	}
	else if (StrEqual(cl_survname, "teengirl", false))
	{
		if (two_left)
		{
			return 2;
		}
		else
		{
			switch (GetRandomInt(1, 2))
			{
				case 1: { return 1; }
				case 2: { return 3; }
			}
		}
	}
	else if (two_left && StrEqual(cl_survname, "biker", false))
	{
		return GetRandomInt(1, 3);
	}
	return 0;
}

/*Action ProxyCallback_lifestate(int entity, const char[] propname, int &iValue, int element)
{
	if (isCloaked[entity])
	{
		iValue = 0;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}*/

Action Timer_Uncloak(Handle timer, int client) {
	if (!IsValidClient(client))
	{ return; }
	DeadRingerUncloak(client, false);
	
	g_UncloakTimer[client] = null;
}

Action Timer_Boost(Handle timer, int client) {
	if (!IsValidClient(client))
	{ return; }
	g_BoostTimer[client] = null;
}

Action Timer_Ready(Handle timer, int client) {
	if (!IsValidClient(client))
	{ return; }
	isTriggerable[client] = true;
	PrintHintText(client, "DR is ready.");
	//KillTimer(g_ReadyTimer, true);
	g_ReadyTimer[client] = null;
}

int TriggerDeadRinger(int client, bool hint, bool clean, bool override, bool override_bool)
{
	if (!IsValidClient(client))
	{ return -1; }
	
	if (IsPlayerAlive(client) && isTriggerable[client] && !isActive[client] && (!override || override_bool)) {
		isActive[client] = true;
		SDKHook(client, MAIN_DAMAGE_HOOK, Hook_OnTakeDamagePost);
		//SDKHook(client, CHANGE_DAMAGE_HOOK, Hook_OnTakeDamage);
		if (hint)
		{ PrintHintText(client, ACTIVE_STR); }
		if (clean)
		{
			if (g_UncloakTimer[client] != null)
			{ KillTimer(g_UncloakTimer[client], true); }
			if (g_BoostTimer[client] != null)
			{ KillTimer(g_BoostTimer[client], true); }
			if (g_ReadyTimer[client] != null)
			{ KillTimer(g_ReadyTimer[client], true); }
			g_UncloakTimer[client] = null;
			g_BoostTimer[client] = null;
			g_ReadyTimer[client] = null;
		}
		return 1;
	}
	else 
	if (isTriggerable[client] && isActive[client] && (!override || !override_bool)) {
		isActive[client] = false;
		SDKUnhook(client, MAIN_DAMAGE_HOOK, Hook_OnTakeDamagePost);
		//SDKUnhook(client, CHANGE_DAMAGE_HOOK, Hook_OnTakeDamage);
		if (hint)
		{ PrintHintText(client, INACTIVE_STR); }
		if (clean)
		{
			if (g_UncloakTimer[client] != null)
			{ KillTimer(g_UncloakTimer[client], true); }
			if (g_BoostTimer[client] != null)
			{ KillTimer(g_BoostTimer[client], true); }
			if (g_ReadyTimer[client] != null)
			{ KillTimer(g_ReadyTimer[client], true); }
			g_UncloakTimer[client] = null;
			g_BoostTimer[client] = null;
			g_ReadyTimer[client] = null;
			//Hook_Manager_AliveProp(client, false);
		}
		return 0;
	}
	return -1;
}

void CreateWeaponCloneFromEntity(int client, int entity)
{
	if (!IsValidEntity(entity)) return;
	
	//PrintToChatAll("%i", entity);
	float fPos[3];
	float fAng[3];
	GetClientEyePosition(client, fPos);
	//fPos[2] += 20;
	GetClientAbsAngles(client, fAng);
	
	char wep_model[PLATFORM_MAX_PATH+1];
	int modelidx = -1;
	if (HasEntProp(entity, Prop_Send, "m_iWorldModelIndex"))
	{ modelidx = GetEntProp(entity, Prop_Send, "m_iWorldModelIndex"); }
	else if (HasEntProp(entity, Prop_Data, "m_nModelIndex"))
	{ modelidx = GetEntProp(entity, Prop_Data, "m_nModelIndex"); }
	
	if (modelidx > 1)
	{ ModelIndexToString(modelidx, wep_model, sizeof(wep_model)); }
	
	char entity_cls[128];
	GetEntityClassname(entity, entity_cls, sizeof(entity_cls));
	int clone = CreateEntityByName(entity_cls);
	if (!IsValidEntity(clone))
	{ return; }
	
	/*int clone = CreateEntityByName("prop_physics_override");
	if (!IsValidEntity(clone))
	{ return; }
	DispatchKeyValue(clone, "spawnflags", "4");*/
	
	float velfloat[3];
	velfloat[0] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[0]")*30;
	velfloat[1] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[1]")*30;
	velfloat[2] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[2]")*30;
	SetEntProp(clone, Prop_Send, "m_CollisionGroup", 11);
	//SetEntityModel(clone, wep_model);
	TeleportEntity(clone, fPos, fAng, velfloat);
	DispatchSpawn(clone);
	ActivateEntity(clone);
	if (HasEntProp(clone, Prop_Data, "m_flNextPrimaryAttack"))
	{
		SetEntPropFloat(clone, Prop_Data, "m_flNextPrimaryAttack", GetGameTime() + 86400.0); 
		int offset = FindSendPropInfo("CWeaponCSBase", "m_flNextPrimaryAttack");
		ChangeEdictState(clone, offset);
	}
	if (HasEntProp(clone, Prop_Data, "m_flNextSecondaryAttack"))
	{
		SetEntPropFloat(clone, Prop_Data, "m_flNextSecondaryAttack", GetGameTime() + 86400.0);
		int offset2 = FindSendPropInfo("CWeaponCSBase", "m_flNextSecondaryAttack");
		ChangeEdictState(clone, offset2);
	}
	
	float var_time = GetConVarFloat(DeadRinger_FakeWeaponTime);
	if (var_time <= 0.0)
	{ return; }
	char variant_str[128];
	Format(variant_str, sizeof(variant_str), "OnUser1 !self:Kill::%f:1", var_time);
	SetVariantString(variant_str);
	AcceptEntityInput(clone, "AddOutput");
	AcceptEntityInput(clone, "FireUser1");
}

void ModelIndexToString(int index, char[] model, int size)
{
	int table = FindStringTable("modelprecache");
	ReadStringTable(table, index, model, size);
}

void DoStuffToSingleWeapon(int client, int entity, bool boolean = true, bool doClone = true)
{
	if (!IsValidEntity(entity)) return;
	if (doClone)
	{ CreateWeaponCloneFromEntity(client, entity); }
	
	if (boolean)
	{
		SetTransmit(entity);
		ApplyEffectsToEntity(entity);
	}
	else
	{
		SetTransmit(entity, false);
		ApplyEffectsToEntity(entity, false);
	}
}

void DoStuffToWeapons(int client, bool boolean = true)
{
	if (!IsSurvivor(client)) return;
	/*int slotP = GetPlayerWeaponSlot(client, 0);
	int slotS = GetPlayerWeaponSlot(client, 1);
	int slotGRN = GetPlayerWeaponSlot(client, 2);
	int slotMED = GetPlayerWeaponSlot(client, 3);
	int slotPLS = GetPlayerWeaponSlot(client, 4);
	
	DoStuffToSingleWeapon(client, slotP, boolean, boolean);
	DoStuffToSingleWeapon(client, slotS, boolean, false);
	DoStuffToSingleWeapon(client, slotGRN, boolean, boolean);
	DoStuffToSingleWeapon(client, slotMED, boolean, boolean);
	DoStuffToSingleWeapon(client, slotPLS, boolean, boolean);*/
	int slotS = GetPlayerWeaponSlot(client, 1);
	//DoStuffToSingleWeapon(client, GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"), boolean, boolean)
	for (int i = -1; i <= GetMaxEntities(); i++)
	{
		if (!IsValidEntity(i)) continue;
		if (IsValidClient(i)) continue;
		
		char class[128];
		GetEntityClassname(i, class, sizeof(class));
		if (StrEqual(class, "weapon_melee", false) || StrContains(class, "projectile", false)) continue;
		
		if (!StrContains(class, "prop_dynamic", false) && !StrContains(class, "commentary_dummy", false) && 
		!StrContains(class, "prop_physics", false) && !StrContains(class, "weapon", false)) continue;
		
		int parent = -1;
		int owner = -1;
		if (HasEntProp(i, Prop_Send, "moveparent"))
		{ parent = GetEntPropEnt(i, Prop_Send, "moveparent"); }
		if (HasEntProp(i, Prop_Send, "m_hOwnerEntity"))
		{ owner = GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity"); }
		
		if (IsValidClient(parent) && parent == client || IsValidClient(owner) && owner == client)
		{
			//PrintToChatAll("%s", class);
			if (!IsValidEntity(slotS) || i != slotS)
			{
				if (StrContains(class, "weapon", false))
				{ DoStuffToSingleWeapon(client, i, boolean, boolean); }
				else
				{ DoStuffToSingleWeapon(client, i, false, boolean); }
			}
			else
			{ DoStuffToSingleWeapon(client, i, boolean, false); }
		}
	}
}

/*public void OnEntityCreated(ent, const char[] class) // Debug purposes.
{
	if (!IsValidEntity(ent) || !StrEqual(class, "survivor_death_model", false)) return;
	CreateTimer(0.1, OnEntityCreatedDebug, ent);
}

Action OnEntityCreatedDebug(Handle timer, ent) {
	char debug_str[64];
	GetEntityClassname(ent, debug_str, sizeof(debug_str));
	PrintToChatAll("%s spawned! Index is: %i. Variable you're looking for is: %i.", debug_str,
	EntRefToEntIndex(ent), GetEntProp(ent, Prop_Send, "m_CollisionGroup"));
	//float vector[3];
	//GetEntPropVector(ent, Prop_Send, "m_vecMaxs", vector, sizeof(vector));
	//PrintToChatAll("%s spawned! Index is: %i. Vec 1: %f. Vec 2: %f. Vec 3: %f.", debug_str,
	//EntRefToEntIndex(ent), vector[0], vector[1], vector[2]);
}*/

void SpawnCorpse(int client)
{
	if (!IsValidClient(client)) return;
	RemoveCorpse(client);
	
	int zclass = GetEntProp(client, Prop_Send, "m_zombieClass");
	if (IsSurvivor(client) && GetConVarInt(DeadRinger_CorpseMode) < 1 || zclass == ZOMBIECLASS_TANK)
	{
		int corpse = CreateEntityByName(IsSurvivor(client) ? "commentary_dummy" : "prop_dynamic");
		if(!IsValidEntity(corpse))
		{ return; }
		g_Ragdoll[client] = corpse;
		
		int c_attack = GetEntPropEnt(client, Prop_Send, "m_pummelAttacker");
		int c_carrier = GetEntPropEnt(client, Prop_Send, "m_carryAttacker");
		static float origin[3];
		static float angles[3];
		if (IsValidClient(c_attack))
		{ GetClientAbsOrigin(c_attack, origin); }
		else if (IsValidClient(c_carrier))
		{ GetClientAbsOrigin(c_carrier, origin); }
		else
		{ GetClientAbsOrigin(client, origin); }
		GetClientAbsAngles(client, angles);
		TeleportEntity(corpse, origin, angles, NULL_VECTOR);
		
		static char cl_model[PLATFORM_MAX_PATH];
		GetClientModel(client, cl_model, sizeof(cl_model));
		
		SetEntityModel(corpse, cl_model);
		SetEntityMoveType(corpse, MOVETYPE_STEP);
		//SetEntProp(corpse, Prop_Send, "m_nSolidType", 0);
		SetEntProp(corpse, Prop_Send, "m_CollisionGroup", 1);
		SetEntPropVector(corpse, Prop_Send, "m_vecMins", view_as<float>({-16.0, -16.0, 0.0}));
		SetEntPropVector(corpse, Prop_Send, "m_vecMaxs", view_as<float>({16.0, 16.0, 14.0}));
		SetEntityGravity(corpse, 1.0);
		if (!IsSurvivor(client)) DispatchKeyValue(corpse, "solid", "0");
		SetEntProp(corpse, Prop_Send, "m_bClientSideAnimation", 1);
		if (IsSurvivor(client))
		{
			if (GetEntProp(client, Prop_Send, "m_isIncapacitated"))
			{ SetVariantString("ACT_DIE_INCAP"); }
			else
			{ SetVariantString("ACT_DIE_STANDING"); }
		}
		else if (zclass == ZOMBIECLASS_TANK)
		{
			int effect = GetEntPropEnt(client, Prop_Send, "m_hEffectEntity");
			if (IsValidEntity(effect))
			{
				char effectclass[64]; 
				GetEntityClassname(effect, effectclass, sizeof(effectclass));
				if (StrEqual(effectclass, "entityflame"))
				{ AcceptEntityInput(corpse, "Ignite"); }
			}
			if (GetClientButtons(client) & IN_FORWARD)
			{
				SetVariantString("OnUser1 !self:BecomeRagdoll::1.5:1");
				//SetVariantString("OnUser1 !self:Kill::3.25:1");
				AcceptEntityInput(corpse, "AddOutput");
				AcceptEntityInput(corpse, "FireUser1");
				SetVariantString("ACT_TERROR_DIE_WHILE_RUNNING");
			}
			else
			{
				SetVariantString("OnUser1 !self:BecomeRagdoll::3.2:1");
				//SetVariantString("OnUser1 !self:Kill::3.25:1");
				AcceptEntityInput(corpse, "AddOutput");
				AcceptEntityInput(corpse, "FireUser1");
				SetVariantString("ACT_TERROR_DIE_FROM_STAND");
			}
		}
		AcceptEntityInput(corpse, "SetAnimation");
		//PrintToChatAll("%i %i %i", GetEntProp(client, Prop_Send, "m_hGroundEntity") > -1, !IsValidEntity(g_BloodPool[client]), g_BloodPool[client] <= 0);
		//PrintToChatAll("%i %i", GetEntProp(client, Prop_Send, "m_hGroundEntity"), g_BloodPool[client]);
		
		if (GetEntProp(client, Prop_Send, "m_hGroundEntity") > -1)
		{
			float origin_endTR[3]; origin_endTR[0] = origin[0]; origin_endTR[1] = origin[1]; origin_endTR[2] = origin[2]-10.0;
			TR_TraceRayFilter(origin, origin_endTR, MASK_SHOT_PORTAL, RayType_EndPoint, TraceRay_FilterPlayers);
			//PrintToChatAll("%i", TR_GetEntityIndex());
			
			if (TR_DidHit() && (!IsValidEntity(g_BloodPool[client]) || g_BloodPool[client] <= 0))
			{
				TR_GetEndPosition(origin_endTR);
				int particle = CreateEntityByName("info_particle_system");
				if (IsValidEntity(particle))
				{
					g_BloodPool[client] = particle;
					DispatchKeyValue(particle, "effect_name", "blood_bleedout");
					DispatchSpawn(particle);
					ActivateEntity(particle);
					TeleportEntity(particle, origin_endTR, NULL_VECTOR, NULL_VECTOR);
					SetVariantString("OnUser1 !self:Kill::75.0:1");
					AcceptEntityInput(particle, "AddOutput");
					SetVariantString("OnUser1 !self:Start::0.5:1");
					AcceptEntityInput(particle, "AddOutput");
					AcceptEntityInput(particle, "FireUser1");
				}
				int extra_particle = CreateEntityByName("info_particle_system");
				if (IsValidEntity(extra_particle))
				{
					DispatchKeyValue(extra_particle, "effect_name", "blood_bleedout_3");
					DispatchSpawn(extra_particle);
					ActivateEntity(extra_particle);
					TeleportEntity(extra_particle, origin_endTR, NULL_VECTOR, NULL_VECTOR);
					SetVariantString("OnUser1 !self:Kill::5.0:1");
					AcceptEntityInput(extra_particle, "AddOutput");
					SetVariantString("OnUser1 !self:Start::0.5:1");
					AcceptEntityInput(extra_particle, "AddOutput");
					AcceptEntityInput(extra_particle, "FireUser1");
				}
			}
		}
	}
	else
	{ CreateRagdoll(client); }
}

bool TraceRay_FilterPlayers(int entity, int contentsMask)
{
	if (IsValidClient(entity)) return false;
	char class[32];
	GetEntityClassname(entity, class, sizeof(class));
	if (StrEqual(class, "commentary_dummy", false)) return false;
	return true;
}

void RemoveCorpse(int client)
{
	if(IsValidEntity(g_Ragdoll[client]))
	{
		char classname[PLATFORM_MAX_PATH+1];
		GetEntityClassname(g_Ragdoll[client], classname, sizeof(classname));
		if(StrEqual(classname, "commentary_dummy", false))
		{
			AcceptEntityInput(g_Ragdoll[client], "Kill");
		}
		g_Ragdoll[client] = -1;
	}
}

void CreateRagdoll(int client)
{
	if (!IsValidClient(client) || (!IsSurvivor(client) && GetClientTeam(client) != INFECTEDTEAM))
	return;
	
	int entity = CreateEntityByName("prop_dynamic");
	if (!IsValidEntity(entity)) return;
	
	float fPos[3];
	float fAng[3];
	GetClientAbsOrigin(client, fPos);
	GetClientAbsAngles(client, fAng);
	
	char sModel[64];
	GetEntPropString(client, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
	if (StrEqual(sModel, BOOMER_M_MDL, false))
	{ strcopy(sModel, sizeof(sModel), BOOMER_M_GIB); }
	else if (StrEqual(sModel, BOOMER_F_MDL, false))
	{ strcopy(sModel, sizeof(sModel), BOOMER_F_GIB); }
	
	DispatchKeyValue(entity, "model", sModel);
	DispatchKeyValue(entity, "solid", "0");
	TeleportEntity(entity, fPos, fAng, NULL_VECTOR);
	DispatchSpawn(entity);
	ActivateEntity(entity);
	
	SetEntProp(entity, Prop_Send, "m_nSequence", GetEntProp(client, Prop_Send, "m_nSequence"));
	SetEntPropFloat(entity, Prop_Send, "m_flCycle", GetEntPropFloat(client, Prop_Send, "m_flCycle"));
	SetEntPropFloat(entity, Prop_Send, "m_flPlaybackRate", 0.0);
	
	AcceptEntityInput(entity, "BecomeRagdoll");
	
	SetVariantString("OnUser1 !self:Kill::1.0:1");
	AcceptEntityInput(entity, "AddOutput");
	AcceptEntityInput(entity, "FireUser1");
	
	/*int Ragdoll = CreateEntityByName("cs_ragdoll");
	float fPos[3];
	float fAng[3];
	GetClientAbsOrigin(client, fPos);
	GetClientAbsAngles(client, fAng);
	
	TeleportEntity(Ragdoll, fPos, fAng, NULL_VECTOR);
	
	SetEntPropVector(Ragdoll, Prop_Send, "m_vecRagdollOrigin", fPos);
	SetEntProp(Ragdoll, Prop_Send, "m_nModelIndex", GetEntProp(client, Prop_Send, "m_nModelIndex"));
	SetEntProp(Ragdoll, Prop_Send, "m_iTeamNum", GetClientTeam(client));
	SetEntPropEnt(Ragdoll, Prop_Send, "m_hPlayer", client);
	SetEntProp(Ragdoll, Prop_Send, "m_iDeathPose", GetEntProp(client, Prop_Send, "m_nSequence"));
	SetEntProp(Ragdoll, Prop_Send, "m_iDeathFrame", GetEntProp(client, Prop_Send, "m_flAnimTime"));
	SetEntProp(Ragdoll, Prop_Send, "m_nForceBone", 0);
	
	if (IsSurvivor(client))
	{
		SetEntProp(Ragdoll, Prop_Send, "m_ragdollType", 4);
		SetEntProp(Ragdoll, Prop_Send, "m_survivorCharacter", GetEntProp(client, Prop_Send, "m_survivorCharacter"));
	}
	else if (GetClientTeam(client) == INFECTEDTEAM)
	{
		int infclass = GetEntProp(client, Prop_Send, "m_zombieClass", 1);
		if (infclass == 8)
		{ SetEntProp(Ragdoll, Prop_Send, "m_ragdollType", 3); }
		else
		{ SetEntProp(Ragdoll, Prop_Send, "m_ragdollType", 2); }
		SetEntProp(Ragdoll, Prop_Send, "m_zombieClass", infclass, 1);
		
		int effect = GetEntPropEnt(client, Prop_Send, "m_hEffectEntity");
		if (IsValidEntity(effect))
		{
			char effectclass[64]; 
			GetEntityClassname(effect, effectclass, sizeof(effectclass));
			if (StrEqual(effectclass, "entityflame"))
			{ SetEntProp(Ragdoll, Prop_Send, "m_bOnFire", 1, 1); }
		}
	}
	else
	{ SetEntProp(Ragdoll, Prop_Send, "m_ragdollType", 1); }
	
	SetVariantString("OnUser1 !self:Kill::1.0:1");
	AcceptEntityInput(Ragdoll, "AddOutput");
	AcceptEntityInput(Ragdoll, "FireUser1");*/
}

void WeaponAttackAvailable(int client, bool boolean) {
	if (!GetConVarBool(DeadRinger_DisableAttack))
	{ return; }
	//SetEntPropFloat(client, Prop_Send, "m_flNextAttack", boolean ? GetGameTime()+3 : GetGameTime() + 86400.0);
	int slotP = GetPlayerWeaponSlot(client, 0);
	int slotS = GetPlayerWeaponSlot(client, 1);
	int slotGRN = GetPlayerWeaponSlot(client, 2);
	int slotMED = GetPlayerWeaponSlot(client, 3);
	int slotPLS = GetPlayerWeaponSlot(client, 4);
	int offset = FindSendPropInfo("CWeaponCSBase", "m_flNextPrimaryAttack");
	int offset2 = FindSendPropInfo("CWeaponCSBase", "m_flNextSecondaryAttack");
	
	if (IsValidEntity(slotP))
	{
		SetEntPropFloat(slotP, Prop_Data, "m_flNextPrimaryAttack", boolean ? GetGameTime()+3 : GetGameTime() + 86400.0);
		SetEntPropFloat(slotP, Prop_Data, "m_flNextSecondaryAttack", boolean ? GetGameTime()+3 : GetGameTime() + 86400.0);
		ChangeEdictState(slotP, offset);
		ChangeEdictState(slotP, offset2);
	}
	if (IsValidEntity(slotS))
	{
		SetEntPropFloat(slotS, Prop_Data, "m_flNextPrimaryAttack", boolean ? GetGameTime()+3 : GetGameTime() + 86400.0);
		SetEntPropFloat(slotS, Prop_Data, "m_flNextSecondaryAttack", boolean ? GetGameTime()+3 : GetGameTime() + 86400.0);
		ChangeEdictState(slotS, offset);
		ChangeEdictState(slotS, offset2);
	}
	if (IsValidEntity(slotGRN))
	{
		SetEntPropFloat(slotGRN, Prop_Data, "m_flNextPrimaryAttack", boolean ? GetGameTime()+3 : GetGameTime() + 86400.0);
		SetEntPropFloat(slotGRN, Prop_Data, "m_flNextSecondaryAttack", boolean ? GetGameTime()+3 : GetGameTime() + 86400.0);
		ChangeEdictState(slotGRN, offset);
		ChangeEdictState(slotGRN, offset2);
	}
	if (IsValidEntity(slotMED))
	{
		SetEntPropFloat(slotMED, Prop_Data, "m_flNextPrimaryAttack", boolean ? GetGameTime()+3 : GetGameTime() + 86400.0);
		SetEntPropFloat(slotMED, Prop_Data, "m_flNextSecondaryAttack", boolean ? GetGameTime()+3 : GetGameTime() + 86400.0);
		ChangeEdictState(slotMED, offset);
		ChangeEdictState(slotMED, offset2);
	}
	if (IsValidEntity(slotPLS))
	{
		SetEntPropFloat(slotPLS, Prop_Data, "m_flNextPrimaryAttack", boolean ? GetGameTime()+3 : GetGameTime() + 86400.0);
		SetEntPropFloat(slotPLS, Prop_Data, "m_flNextSecondaryAttack", boolean ? GetGameTime()+3 : GetGameTime() + 86400.0);
		ChangeEdictState(slotPLS, offset);
		ChangeEdictState(slotPLS, offset2);
	}
}

void SetTransmit(int entity, bool boolean = true)
{
	//if (!GetConVarBool(DeadRinger_Transmit) && )
	if (!IsValidEntity(entity)) return;
	if (boolean)
	{ SDKHook(entity, TRANSMIT_HOOK, Hook_SetTransmit); }
	else
	{ SDKUnhook(entity, TRANSMIT_HOOK, Hook_SetTransmit); }
	/*if (IsValidClient(entity))
	{
		if (boolean && !SendProxy_IsHooked(entity, "m_lifeState"))
		{ SendProxy_Hook(entity, "m_lifeState", Prop_Int, ProxyCallback_lifestate); }
		else if (!boolean && SendProxy_IsHooked(entity, "m_lifeState"))
		{ SendProxy_Unhook(entity, "m_lifeState", ProxyCallback_lifestate); }
	}*/
}

bool canTriggerDR(int client)
{
	if (!IsValidClient(client)) return false;
	if (GetEntProp(client, Prop_Data, "m_takedamage") <= 0)
	{ return false; }
	return true;
}

bool IsSurvivor(int client)
{
	if (!IsValidClient(client)) return false;
	if (GetClientTeam(client) == SURVIVORTEAM || GetClientTeam(client) == SURVIVORTEAM_PASSING) return true;
	return false;
}

bool IsValidClient(int client, bool replaycheck = true)
//IsValidClient(client)
{
	if (!IsValidEntity(client)) return false;
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	//if (GetEntProp(client, Prop_Send, "m_bIsCoaching")) return false;
	if (replaycheck)
	{
		if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	}
	return true;
}
// Below functions taken and modified from infected_release plugin.
/*void ExecuteCheatCommand(client, const char[] cmd_Str)
{
	if (!IsValidClient(client)) return;
	int cmd_Flags = GetCommandFlags(cmd_Str);
    
	SetCommandFlags(cmd_Str, cmd_Flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s", cmd_Str);
	SetCommandFlags(cmd_Str, cmd_Flags);
}*/

void CallOnPummelEnded(int client)
{
	if (hOnPummelEnded == null){
		StartPrepSDKCall(SDKCall_Player);
		if (!PrepSDKCall_SetFromConf(hConf, SDKConf_Signature, NAME_ONPUMMELENDED))
		{ SetFailState("[SM] Failed to set %s signature from config!", NAME_ONPUMMELENDED); return; }
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer, VDECODE_FLAG_ALLOWNULL);
		hOnPummelEnded = EndPrepSDKCall();
		if (hOnPummelEnded == null)
		{ SetFailState("[SM] Can't get %s SDKCall!", NAME_ONPUMMELENDED); return; }
	}
	SDKCall(hOnPummelEnded, client, true, -1);
}

void CallOnPounceEnd(int client)
{
	if (hOnPounceEnd == null){
		StartPrepSDKCall(SDKCall_Player);
		if (!PrepSDKCall_SetFromConf(hConf, SDKConf_Signature, NAME_ONPOUNCEEND))
		{ SetFailState("[SM] Failed to set %s signature from config!", NAME_ONPOUNCEEND); return; }
		hOnPounceEnd = EndPrepSDKCall();
		if (hOnPounceEnd == null)
		{ SetFailState("[SM] Can't get %s SDKCall!", NAME_ONPOUNCEEND); return; }
	}
	SDKCall(hOnPounceEnd, client);
}

void CallReleaseTongueVictim(int client)
{
	if (hReleaseTongueVictim == null){
		StartPrepSDKCall(SDKCall_Player);
		if (!PrepSDKCall_SetFromConf(hConf, SDKConf_Signature, NAME_RELEASETONGUEVICTIM))
		{ SetFailState("[SM] Failed to set %s signature from config!", NAME_RELEASETONGUEVICTIM); return; }
		PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
		hReleaseTongueVictim = EndPrepSDKCall();
		if (hReleaseTongueVictim == null)
		{ SetFailState("[SM] Can't get %s SDKCall!", NAME_RELEASETONGUEVICTIM); return; }
	}
	SDKCall(hReleaseTongueVictim, client, false);
	//SetEntProp(client, Prop_Send, "m_tongueVictim", -1);
	//SetEntProp(target, Prop_Send, "m_tongueOwner", -1);
}

void CallOnRideEnded(int client, int target)
{
	if (hOnRideEnded == null){
		StartPrepSDKCall(SDKCall_Player);
		if (!PrepSDKCall_SetFromConf(hConf, SDKConf_Signature, NAME_ONRIDEENDED))
		{ SetFailState("[SM] Failed to set %s signature from config!", NAME_ONRIDEENDED); return; }
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
		hOnRideEnded = EndPrepSDKCall();
		if (hOnRideEnded == null)
		{ SetFailState("[SM] Can't get %s SDKCall!", NAME_ONRIDEENDED); return; }
	}
	SDKCall(hOnRideEnded, client, target);
}

void CallResetAbility(int client, float time)
{
	if (hStartActivationTimer == null)
	{
		StartPrepSDKCall(SDKCall_Entity);
		
		if (!PrepSDKCall_SetFromConf(hConf, SDKConf_Signature, NAME_STARTACTIVATIONTIMER))
		{ SetFailState("[SM] Failed to set %s signature from config!", NAME_STARTACTIVATIONTIMER); return; }
		PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
		
		hStartActivationTimer = EndPrepSDKCall();
		
		if (hStartActivationTimer == null)
		{ SetFailState("[SM] Can't get %s SDKCall!", NAME_STARTACTIVATIONTIMER); return; }            
	}
	int ability_ent = GetEntPropEnt(client, Prop_Send, "m_customAbility");
	if (!IsValidEntity(ability_ent)) return;
	SDKCall(hStartActivationTimer, ability_ent, time, 0.0);
}