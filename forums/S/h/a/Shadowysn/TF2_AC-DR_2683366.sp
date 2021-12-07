#define PLUGIN_NAME "[TF2] All-Class Dead Ringer"
#define PLUGIN_AUTHOR "Mentlegen, Shadowysn"
#define PLUGIN_DESC "Use sm_fd to activate the AC-DR."
#define PLUGIN_VERSION "1.2.0"
#define PLUGIN_URL "https://forums.alliedmods.net/showthread.php?p=2683366"
#define PLUGIN_NAME_SHORT "All-Class Dead Ringer"
#define PLUGIN_NAME_TECH "ac_dr"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
//#include <sendproxy>
#include <tf2_stocks>

#define GAMEDATA "tf2.allclass-deadringer"

#define DEBUG 1

#define TYPE_GLOVES			0
#define TYPE_POWERJACK		1
#define TYPE_BEARCLAWS		2
#define TYPE_ZATOICHI		3
#define TYPE_CANDYCANE		4
#define TYPE_CLASSIC		5
#define TYPE_NEONLATOR		6
#define TYPE_SPYCICLE		7
#define TYPE_MANMELTER		8
#define TYPE_THIRDDEGREE	9
#define TYPE_PHLOG			10
#define TYPE_EREWARD		11
#define TYPE_WPRICK			12

#define ACTIVE_STR "A-C DR ACTIVE"
#define INACTIVE_STR "A-C DR INACTIVE"
#define UNCLOAK_SND "Player.Spy_UnCloakFeignDeath"
#define STOP_SND "BaseCombatCharacter.StopWeaponSounds"
#define FALLGIB_SND "Player.FallDamage"

#define CHANGE_DAMAGE_HOOK SDKHook_OnTakeDamage
#define THINK_POST_HOOK SDKHook_ThinkPost
#define POST_THINK_HOOK SDKHook_PostThink

//#define TF_COND_INVULNERABLE 5
//#define TF_COND_INVULNERABLE_HIDE_UNLESS_DAMAGED 51
//#define TF_COND_INVULNERABLE_USER_BUFF 52
//#define TF_COND_INVULNERABLE_CARD_EFFECT 57
//#define scene_targetname "ac_dr_scene_ent"

#pragma semicolon 1
#pragma newdecls required

static bool can[MAXPLAYERS+1];
static bool trigger[MAXPLAYERS+1];
static bool isCloaked[MAXPLAYERS+1];
//static int g_Ragdoll[MAXPLAYERS+1] = INVALID_ENT_REFERENCE;

ConVar DeadRinger_RechargeTime;
ConVar DeadRinger_CloakTime;
ConVar DeadRinger_AfterburnImmune;
ConVar DeadRinger_SpeedBoost;
ConVar DeadRinger_FriendlyDisguise;
ConVar DeadRinger_ClassRestrictSpy;
ConVar DeadRinger_ExtraEffects;
ConVar DeadRinger_DamageRes_Min;
ConVar DeadRinger_DamageRes_Max;

ConVar DeadRinger_BotSpawn;

//char g_wep_netclass_attacker[MAXPLAYERS+1];

//static Handle g_UncloakTimer[MAXPLAYERS+1] = null;
static float g_UncloakTimer[MAXPLAYERS+1] = -1.0;
//static Handle g_BoostTimer[MAXPLAYERS+1] = null;
//static float g_BoostTimer[MAXPLAYERS+1] = -1.0;
//static Handle g_ReadyTimer[MAXPLAYERS+1] = null;
static float g_ReadyTimer[MAXPLAYERS+1] = -1.0;
static float g_ResistTimer[MAXPLAYERS+1] = -1.0;

static float g_fClientWait[MAXPLAYERS+1] = 0.0;
#define THINK_WAITTIME 0.5

ConVar version_cvar;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() == Engine_TF2)
	{
		return APLRes_Success;
	}
	strcopy(error, err_max, "Plugin only supports Team Fortress 2.");
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
	char temp_str[128];
	char desc_str[256];
	
	DeadRinger_RechargeTime = CreateConVar("sm_ac_dr_recharge_timelimit", "8.0", "Set the time limit until the AC-DR fully recharges.", FCVAR_ARCHIVE, true, 0.0, false, 1000.0);
	DeadRinger_CloakTime = CreateConVar("sm_ac_dr_cloak_timelimit", "6.5", "Set the time limit the AC-DR cloaks the user for.", FCVAR_ARCHIVE, true, 0.0, false, 1000.0);
	DeadRinger_SpeedBoost = CreateConVar("sm_ac_dr_speedboost", "1.0", "Toggle speed-boost upon AC-DR usage.", FCVAR_ARCHIVE, true, 0.0, true, 1.0);
	DeadRinger_AfterburnImmune = CreateConVar("sm_ac_dr_afterburn_immune", "1.0", "Toggle afterburn-immunity upon AC-DR usage.", FCVAR_ARCHIVE, true, 0.0, true, 1.0);
	DeadRinger_FriendlyDisguise = CreateConVar("sm_ac_dr_friendlydis", "0.0", "Makes Spies drop the corpse of the friendly disguise instead of themselves.", FCVAR_ARCHIVE, true, 0.0, true, 1.0);
	DeadRinger_ClassRestrictSpy = CreateConVar("sm_ac_dr_classrestrict_spy", "0.0", "Restrict Spies from using the AC-DR.", FCVAR_ARCHIVE, true, 0.0, true, 1.0);
	DeadRinger_ExtraEffects = CreateConVar("sm_ac_dr_extra_effects", "0.0", "Give other effects, most likely to attackers, that the normal DR couldn't.", FCVAR_ARCHIVE, true, 0.0, true, 1.0);
	
	strcopy(temp_str, sizeof(temp_str), "Damage is multiplied by this value for cloaked AC-DR users with %s charge. Do <0.9 for lesser damage.");
	Format(desc_str, sizeof(desc_str), temp_str, "low");
	DeadRinger_DamageRes_Min = CreateConVar("sm_ac_dr_damage_res_min", "0.2", desc_str, FCVAR_ARCHIVE, true, 0.0);
	Format(desc_str, sizeof(desc_str), temp_str, "high");
	DeadRinger_DamageRes_Max = CreateConVar("sm_ac_dr_damage_res_max", "0.65", desc_str, FCVAR_ARCHIVE, true, 0.0);

	DeadRinger_BotSpawn = CreateConVar("sm_ac_dr_botspawn_toggle", "0.0", "Force bots to enable their AC-DR on spawn.", FCVAR_ARCHIVE, true, 0.0, true, 1.0);
	
	version_cvar = CreateConVar("sm_ac_dr_version", PLUGIN_VERSION, "All-Class Dead Ringer version", 0|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if (version_cvar != null)
		SetConVarString(version_cvar, PLUGIN_VERSION);
	
	HookEvent("player_hurt", player_hurt, EventHookMode_Pre);
	HookEvent("player_death", player_death, EventHookMode_Post);
	HookEvent("player_spawn", player_spawn, EventHookMode_Post);
	HookEvent("player_changeclass", player_changeclass, EventHookMode_Pre);
	RegConsoleCmd("sm_fd", ACDR_Command, "Toggle the All-Class Dead Ringer.");
	#if DEBUG
	RegConsoleCmd("sm_testfd", ACDR_Test, "testfd.");
	#endif
	RegAdminCmd("sm_fd_ply", ACDR_Force_Command, ADMFLAG_GENERIC, "Toggle the All-Class Dead Ringer on a specified player.");
	for (int client = 1; client <= MAXPLAYERS; client++)
	{
		can[client] = true;
		trigger[client] = false;
	}
	
	LoadTranslations("common.phrases");
	AutoExecConfig(true, "TF2_AC_DR");
}

public void OnPluginEnd()
{
	if (DeadRinger_RechargeTime != null) CloseHandle(DeadRinger_RechargeTime);
	if (DeadRinger_SpeedBoost != null) CloseHandle(DeadRinger_SpeedBoost);
	if (DeadRinger_AfterburnImmune != null) CloseHandle(DeadRinger_AfterburnImmune);
	if (DeadRinger_FriendlyDisguise != null) CloseHandle(DeadRinger_FriendlyDisguise);
	
	int ply_manager = FindEntityByClassname(-1, "tf_player_manager");
	if (RealValidEntity(ply_manager))
	{ SDKUnhook(ply_manager, THINK_POST_HOOK, Hook_OnThinkPost); }
	
	UnhookEvent("player_hurt", player_hurt, EventHookMode_Pre);
	UnhookEvent("player_death", player_death, EventHookMode_Post);
	UnhookEvent("player_spawn", player_spawn, EventHookMode_Post);
	UnhookEvent("player_changeclass", player_changeclass, EventHookMode_Pre);
	for (int client = 1; client <= MAXPLAYERS; client++)
	{
		can[client] = false;
		trigger[client] = false;
		isCloaked[client] = false;
		
		if (!IsValidClient(client))
		{ continue; }
		HookThink(client, false);
		//RemoveACDRRagdoll(client);
		//Hook_Manager_AliveProp(client, false);
		/*if (SendProxy_IsHooked(client, "m_lifeState"))
		{
			SendProxy_Unhook(client, "m_lifeState", ProxyCallback_lifestate); // SendProxy 1.3
		}*/
	}
}

// Scene Entity Start v
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

void StopScene(int client)
{
	int scene = CreateEntityByName("instanced_scripted_scene");
	
	/*TFClassType class = view_as<TFClassType>(GetEntProp(client, Prop_Send, "m_nDisguiseClass"));
	if (!IsDisguisedAsFriendly(client))
	{ class = TF2_GetPlayerClass(client); }
	
	char temp_str[64];
	switch (class)
	{
		case TFClass_Scout:		strcopy(temp_str, sizeof(temp_str), "scout");
		case TFClass_Soldier:	strcopy(temp_str, sizeof(temp_str), "soldier");
		case TFClass_Pyro:		strcopy(temp_str, sizeof(temp_str), "pyro");
		case TFClass_DemoMan:	strcopy(temp_str, sizeof(temp_str), "demoman");
		case TFClass_Heavy:		strcopy(temp_str, sizeof(temp_str), "heavy");
		case TFClass_Engineer:	strcopy(temp_str, sizeof(temp_str), "engineer");
		case TFClass_Medic:		strcopy(temp_str, sizeof(temp_str), "medic");
		case TFClass_Sniper:	strcopy(temp_str, sizeof(temp_str), "sniper");
		case TFClass_Spy:		strcopy(temp_str, sizeof(temp_str), "spy");
	}
	
	Format(temp_str, sizeof(temp_str), "scenes/player/%s/low/idleloop01.vcd", temp_str);*/
	DispatchKeyValue(scene, "SceneFile", "scenes/Player/Scout/low/456.vcd");
	SetEntPropEnt(scene, Prop_Data, "m_hOwner", client);
	DispatchKeyValue(scene, "busyactor", "0");
	DispatchSpawn(scene);
	ActivateEntity(scene);
	AcceptEntityInput(scene, "Start");
	SetVariantString("OnUser1 !self:Cancel::0.01:1");
	AcceptEntityInput(scene, "AddOutput");
	AcceptEntityInput(scene, "FireUser1");
}

/*void DoClientScream_FrameCallback(int client)
{
	if (!IsValidClient(client)) return;
	
	EmitGameSoundToAll(STOP_SND, client);
}*/

void DoClientScream(int client, int type = 1)
{
	if (!IsValidClient(client))
	{ return; }
	if (!IsPlayerAlive(client))
	{ return; }
	
	EmitGameSoundToAll(STOP_SND, client);
	
	if (type == 3)
	{
		EmitGameSoundToAll(FALLGIB_SND, client);
		//RequestFrame(DoClientScream_FrameCallback, client);
		StopScene(client);
		return;
	}
	
	int num_low_crit = -1; int num_high_crit = -1;
	int num_low_medium = -1; int num_high_medium = -1;
	int num_low = -1; int num_high = -1;
	char targetclassname_cl[128];
	TFClassType class = view_as<TFClassType>(GetEntProp(client, Prop_Send, "m_nDisguiseClass"));
	//int team = GetClientTeam(client);
	//int disguise_team = GetEntProp(client, Prop_Send, "m_nDisguiseTeam");
	if (!IsDisguisedAsFriendly(client))
	{ class = TF2_GetPlayerClass(client); }
	
	switch (class)
	{
		case TFClass_Scout: // Scout
		{
			num_low_crit = 458; num_high_crit = 460;
			num_low_medium = 461; num_high_medium = 463;
			num_low = 464; num_high = 466;
			strcopy(targetclassname_cl, sizeof(targetclassname_cl), "scout");
		}
		case TFClass_Soldier: // Soldier
		{
			num_low_crit = 1162; num_high_crit = 1164;
			num_low_medium = 1165; num_high_medium = 1167;
			num_low = 1168; num_high = 1170;
			strcopy(targetclassname_cl, sizeof(targetclassname_cl), "soldier");
		}
		case TFClass_Pyro: // Pyro
		{
			num_low_crit = 1578; num_high_crit = 1580;
			num_low_medium = 1581; num_high_medium = 1583;
			num_low = 1584; num_high = 1593;
			strcopy(targetclassname_cl, sizeof(targetclassname_cl), "pyro");
		}
		case TFClass_DemoMan: // Demoman
		{
			num_low_crit = 980; num_high_crit = 982;
			num_low_medium = 983; num_high_medium = 985;
			num_low = 986; num_high = 988;
			strcopy(targetclassname_cl, sizeof(targetclassname_cl), "demoman");
		}
		case TFClass_Heavy: // Heavy
		{
			num_low_crit = 294; num_high_crit = 296;
			num_low_medium = 297; num_high_medium = 299;
			num_low = 300; num_high = 302;
			strcopy(targetclassname_cl, sizeof(targetclassname_cl), "heavy");
		}
		case TFClass_Engineer: // Engineer
		{
			num_low_crit = 130; num_high_crit = 132;
			num_low_medium = 133; num_high_medium = 135;
			num_low = 136; num_high = 138;
			strcopy(targetclassname_cl, sizeof(targetclassname_cl), "engineer");
		}
		case TFClass_Medic: // Medic
		{
			num_low_crit = 630; num_high_crit = 632;
			num_low_medium = 633; num_high_medium = 635;
			num_low = 636; num_high = 638;
			strcopy(targetclassname_cl, sizeof(targetclassname_cl), "medic");
		}
		case TFClass_Sniper: // Sniper
		{
			num_low_crit = 1697; num_high_crit = 1699;
			num_low_medium = 1700; num_high_medium = 1702;
			num_low = 1703; num_high = 1705;
			strcopy(targetclassname_cl, sizeof(targetclassname_cl), "sniper");
		}
		case TFClass_Spy: // Spy
		{
			num_low_crit = 800; num_high_crit = 802;
			num_low_medium = 803; num_high_medium = 805;
			num_low = 806; num_high = 808;
			strcopy(targetclassname_cl, sizeof(targetclassname_cl), "spy");
		}
	}
	
	/*static char name[128];
	//static char prev_name[128] = "";
	GetEntPropString(client, Prop_Data, "m_iName", name, sizeof(name));
	if (name[0])
	{
		prev_name = name;
	}*/
	
	/*for (int loopclient = 1; loopclient <= MaxClients; loopclient++)
	{
		if (!IsValidClient(loopclient)) continue;
		if (loopclient == client) continue;
		static char loopName[128];
		GetEntPropString(loopclient, Prop_Data, "m_iName", loopName, sizeof(loopName));
		if (loopName[0] && StrEqual(loopName, targetclassname_cl, false))
		{
			//static char new_loopName[128];
			//Format(new_loopName, sizeof(new_loopName), "%s_%i", targetclassname_cl, GetClientUserId(loopclient));
			//DispatchKeyValue(loopclient, "targetname", new_loopName);
			DispatchKeyValue(loopclient, "targetname", "");
		}
	}
	if (!StrEqual(targetclassname_cl, name, false))
	{ DispatchKeyValue(client, "targetname", targetclassname_cl); }*/
	
	char scream_str[128];
	int num_low_used = -1; int num_high_used = -1;
	switch (type)
	{
		case 0:
		{ num_low_used = num_low; num_high_used = num_high; }
		case 1:
		{ num_low_used = num_low_medium; num_high_used = num_high_medium; }
		case 2:
		{ num_low_used = num_low_crit; num_high_used = num_high_crit; }
	}
	
	Format(scream_str, sizeof(scream_str), "scenes/Player/%s/low/%i", targetclassname_cl, GetRandomInt(num_low_used, num_high_used));
	
	PlayScene(client, scream_str);
	
	//return class;
}
// Scene Entity End ^

/* Action ProxyCallback_bAlive(entity, const char[] propname, &iValue, element, client)
{
	if (!IsValidClient(entity) || !IsValidClient(client))
	{ return Plugin_Continue; }
	if (GetClientTeam(entity) != GetClientTeam(client) && !IsClientObserver(client))
	{
		iValue = 0;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}*/
void Hook_OnThinkPost(int entity) {
	if (!RealValidEntity(entity))
	{ return; }
	
	/*int offset_bAlive = FindSendPropInfo("CTFPlayerResource", "m_bAlive");
	int offset_iPCWK = FindSendPropInfo("CTFPlayerResource", "m_iPlayerClassWhenKilled");
	
	int bClientAlive[MAXPLAYERS+1];
	int bClientPCWK[MAXPLAYERS+1];
	GetEntDataArray(entity, offset_bAlive, bClientAlive, MaxClients+1);
	GetEntDataArray(entity, offset_iPCWK, bClientPCWK, MaxClients+1);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i))
		{ continue; }
		if (isCloaked[i])
		{
			bClientAlive[i] = 0;
			if (IsDisguisedAsFriendly(i))
			{ bClientPCWK[i] = GetEntProp(i, Prop_Send, "m_nDisguiseClass"); }
			else
			{ bClientPCWK[i] = GetEntProp(i, Prop_Send, "m_iClass"); }
		}
		//if (bClientAlive[i] > 0)
		//{ PrintToChatAll("%i", bClientAlive[i]); }
	}
	
	SetEntDataArray(entity, offset_bAlive, bClientAlive, MaxClients+1);
	SetEntDataArray(entity, offset_iPCWK, bClientPCWK, MaxClients+1);*/
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i))
		{ continue; }
		if (isCloaked[i])
		{
			int class = GetEntProp(i, Prop_Send, "m_iClass");
			int disguise_class = GetEntProp(i, Prop_Send, "m_nDisguiseClass");
			SetEntProp(entity, Prop_Send, "m_bAlive", 0, 2, i);
			if (IsDisguisedAsFriendly(i))
			{ SetEntProp(entity, Prop_Send, "m_iPlayerClassWhenKilled", disguise_class, 2, i); }
			else
			{ SetEntProp(entity, Prop_Send, "m_iPlayerClassWhenKilled", class, 2, i); }
		}
		//if (bClientAlive[i] > 0)
		//{ PrintToChatAll("%i", bClientAlive[i]); }
	}
}
/*Action ProxyCallback_lifestate(entity, const char[] propname, &iValue, element, client)
{
	if (!IsValidClient(entity) || !IsValidClient(client))
	{ return Plugin_Continue; }
	if (TF2_IsPlayerInCondition(TFCond_BurningPyro))
	{ return Plugin_Continue; }
	if (GetClientTeam(entity) != GetClientTeam(client) && !IsClientObserver(client))
	{
		iValue = 1;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}*/

public void OnMapStart() {
	//PrecacheSound(SND, true);
	//AddFileToDownloadsTable("sound/puppet/poof1.wav");
	PrecacheSound(UNCLOAK_SND, true);
	PrecacheSound(STOP_SND, true);
	PrecacheSound(FALLGIB_SND, true);
	
	int ply_manager = FindEntityByClassname(-1, "tf_player_manager");
	if (RealValidEntity(ply_manager))
	{ SDKHook(ply_manager, THINK_POST_HOOK, Hook_OnThinkPost); }
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (g_fClientWait[client] >= THINK_WAITTIME)
		{
			g_fClientWait[client] = 0.0;
		}
	}
}

bool shouldTrigger = true;
public void OnEntityCreated(int ent, const char[] class)
{
	if (!RealValidEntity(ent) || 
	//(class[0] != 't' && class[0] != 'i') || 
	//(!StrEqual(class, "tf_ragdoll", false) && !StrEqual(class, "instanced_scripted_scene", false))) return;
	class[0] != 't' || 
	!StrEqual(class, "tf_ragdoll", false)) return;
	
	if (!shouldTrigger)
	{
		PrintToServer("burn: %i", GetEntProp(ent, Prop_Send, "m_bBurning"));
		//PrintToServer("Found a: %s", class);
		//if (class[0] == 'i') AcceptEntityInput(ent, "Stop");
		AcceptEntityInput(ent, "Kill");
	}
}

/*public void OnClientPutInServer(int client)
{
	if (!ResetACDRStuff(client)) return;
	
	HookThink(client);
}*/

public void OnClientDisconnect(int client)
{
	if (!ResetACDRStuff(client)) return;
	
	HookThink(client, false); // this might be useless or not
}

bool ResetACDRStuff(int client)
{
	can[client]	= true;
	trigger[client]	= false;
	isCloaked[client] = false;
	g_UncloakTimer[client] = 0.0;
	//g_BoostTimer[client] = 0.0;
	g_ReadyTimer[client] = 0.0;
	
	if (!IsValidClient(client)) return false;
	
	//RemoveACDRRagdoll(client);
	SDKUnhook(client, CHANGE_DAMAGE_HOOK, Hook_OnTakeDamage);
	return true;
}

Action ACDR_Command(int client, any args) {
	if (!IsValidClient(client)) return Plugin_Handled;
	TFClassType class = TF2_GetPlayerClass(client);
	if (class == TFClass_Spy && 
	DeadRinger_ClassRestrictSpy != null && GetConVarBool(DeadRinger_ClassRestrictSpy) && !trigger[client]) return Plugin_Handled;
	TriggerACDR(client, true, false, false, false);
	return Plugin_Handled;
}

#if DEBUG
Action ACDR_Test(int client, int args)
{
	if (!IsValidClient(client) || !IsPlayerAliveOrNotGhost(client)) return Plugin_Handled;
	
	/*float meter = GetEntPropFloat(client, Prop_Send, "m_flCloakMeter");
	TFClassType class = TF2_GetPlayerClass(client);
	
	if (TF2_IsPlayerInCondition(client, TFCond_Cloaked))
	{ TF2_RemoveCondition(client, TFCond_Cloaked); }
	SetEntPropFloat(client, Prop_Send, "m_flCloakMeter", 100.0);
	SetEntProp(client, Prop_Send, "m_iClass", TFClass_Spy);
	SetEntProp(client, Prop_Send, "m_bFeignDeathReady", 1);
	SDKHooks_TakeDamage(client, 0, 0, 1.0, DMG_GENERIC, -1);
	SetEntPropFloat(client, Prop_Send, "m_flCloakMeter", meter);
	if (class != TFClass_Spy) SetEntProp(client, Prop_Send, "m_iClass", view_as<int>(class));
	
	if (!TF2_IsPlayerInCondition(client, TFCond_DeadRingered)) return Plugin_Handled;
	
	TF2_RemoveCondition(client, TFCond_DeadRingered);
	TF2_RemoveCondition(client, TFCond_Cloaked);
	TF2_RemoveCondition(client, TFCond_SpeedBuffAlly);
	
	DoClientScream(client, 2);
	
	//int old_rag = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	
	for (int i = 0; i < GetMaxEntities(); i++)
	{
		if (!RealValidEntity(i)) continue;
		//if (old_rag == i) continue;
		
		char classname[PLATFORM_MAX_PATH+1];
		GetEntityClassname(i, classname, sizeof(classname));
		if (classname[0] != 't' || !StrEqual(classname, "tf_ragdoll", false)) continue;
		PrintToChatAll("ltime: %i", GetEntPropFloat(i, Prop_Data, "m_flLocalTime"));
		float pos[3], ragPos[3];
		GetClientAbsOrigin(client, pos);
		GetEntPropVector(i, Prop_Data, "m_vecOrigin", ragPos);
		
		if (pos[0]!=ragPos[0] || pos[1]!=ragPos[1] || pos[2]!=ragPos[2]) continue;
		
	//	int owner = GetEntPropEnt(i, Prop_Send, "m_iPlayerIndex");
	//	PrintToChatAll("i: %i, owner: %i", i, owner);
	//	if (owner != client) continue;
		
		//bool bFeignDeath = view_as<bool>(GetEntProp(i, Prop_Send, "m_bFeignDeath"));
		//if (!bFeignDeath) continue;
		
		AcceptEntityInput(i, "Kill");
	}*/
	
	TF2_IgnitePlayer(client, client, 15.0);
	TF2_AddCondition(client, TFCond_Bleeding, 15.0);
	
	return Plugin_Handled;
}
#endif

Action ACDR_Force_Command(int client, any args) {
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
		
		int trigger_func = TriggerACDR(target_list[i], true, false, false, false);
		if (trigger_func > 0)
		{ ReplyToCommand(client, "[SM] Successfully toggled %N's AC-DR status to active.", target_list[i]); }
		else if (trigger_func == 0)
		{ ReplyToCommand(client, "[SM] Successfully toggled %N's AC-DR status to inactive.", target_list[i]); }
		else
		{ ReplyToCommand(client, "[SM] Could not toggle %N's AC-DR status.", target_list[i]); }
	}
	
	return Plugin_Handled;
}

/*void RemoveACDRRagdoll(int client)
{
	if (RealValidEntity(g_Ragdoll[client]))
	{
		char classname[PLATFORM_MAX_PATH+1];
		GetEntityClassname(g_Ragdoll[client], classname, sizeof(classname));
		if (StrEqual(classname, "tf_ragdoll", false))
		{
			AcceptEntityInput(g_Ragdoll[client], "Kill");
		}
		//SetEntProp(client, Prop_Send, "m_hRagdoll", -1);
		g_Ragdoll[client] = INVALID_ENT_REFERENCE;
	}
}*/

void DisguiseRagdollFix(int client)
{
	if (!IsValidClient(client))
	{ return; }
	// NOTICE: The spy disguise assumed has the Uber skin that could be seen for a milisecond. Get a more proper fix.
	int team = GetClientTeam(client);
	//int skin = GetEntProp(client, Prop_Send, "m_iPlayerSkinOverride");
	int disguise_team = GetEntProp(client, Prop_Send, "m_nDisguiseTeam");
	int disguise_class = GetEntProp(client, Prop_Send, "m_nDisguiseClass");
	//int disguise_index = GetEntProp(client, Prop_Send, "m_iDisguiseTargetIndex");
	//int disguise_skin = GetEntProp(client, Prop_Send, "m_nDisguiseSkinOverride");
	if (disguise_class > 0 && disguise_class != 8 && (!GetConVarBool(DeadRinger_FriendlyDisguise) || disguise_team != team))
	{
		SetEntProp(client, Prop_Send, "m_nDisguiseTeam", GetClientTeam(client));
		SetEntProp(client, Prop_Send, "m_nDisguiseClass", 8);
		//SetEntProp(client, Prop_Send, "m_nDisguiseSkinOverride", skin);
		//TF2_RemoveCondition(client, TFCond_Disguised);
		DataPack pack = CreateDataPack(); // Doing just DataPack pack; makes the plugin error.
		pack.WriteCell(client);
		pack.WriteCell(disguise_class);
		pack.WriteCell(disguise_team);
		RequestFrame(DisguiseRagdollFix_ReqFrame, pack);
	}
}

void DisguiseRagdollFix_ReqFrame(DataPack pack)
{
	pack.Reset();
	int client = pack.ReadCell();
	int disguise_class = pack.ReadCell();
	int disguise_team = pack.ReadCell();
	//int disguise_skin = pack.ReadCell();
	if (pack != null)
	{ CloseHandle(pack); }
	
	if (!IsValidClient(client) || !IsPlayerAlive(client) || disguise_class <= 0 ) return;
	
	//TF2_AddCondition(client, TFCond_Disguised);
	SetEntProp(client, Prop_Send, "m_nDisguiseTeam", disguise_team);
	SetEntProp(client, Prop_Send, "m_nDisguiseClass", disguise_class);
	//SetEntProp(client, Prop_Send, "m_nDisguiseSkinOverride", disguise_skin);
}

void SpawnACDRRagdoll(int client, int weapon, const float damage, int damageType, const float damageForce[3], int damagecustom)
{
	//SDKCall(hCreateRagdollEntity, client);
	
	//RemoveACDRRagdoll(client);
	
	int ragdoll = CreateEntityByName("tf_ragdoll");
	// IMPORTANT NOTICE: The real ragdoll created by the player will bug and stay indefinitely, should the player have created 
	// an AC-DR corpse which gets set as a 'real' ragdoll in m_hRagdoll. Watch out!
	if (!RealValidEntity(ragdoll)) return;
	
	float PlayerPosition[3];
	
	GetClientAbsOrigin(client, PlayerPosition);
	SetEntPropVector(ragdoll, Prop_Send, "m_vecRagdollOrigin", PlayerPosition);
	SetEntPropVector(ragdoll, Prop_Send, "m_vecForce", damageForce);
	TeleportEntity(ragdoll, PlayerPosition, NULL_VECTOR, NULL_VECTOR);
	
	SetEntPropString(ragdoll, Prop_Data, "m_iName", "");
	
	TFClassType class = TF2_GetPlayerClass(client);
	int team = GetClientTeam(client);
	
	TFClassType disguise_class = view_as<TFClassType>(GetEntProp(client, Prop_Send, "m_nDisguiseClass"));
	int disguise_team = GetEntProp(client, Prop_Send, "m_nDisguiseTeam");
	//int disguise_index = GetEntProp(client, Prop_Send, "m_iDisguiseTargetIndex");
	if (IsDisguisedAsFriendly(client))
	{
		SetEntProp(ragdoll, Prop_Send, "m_iClass", disguise_class);
		SetEntProp(ragdoll, Prop_Send, "m_iTeam", disguise_team);
		//SetEntProp(ragdoll, Prop_Send, "m_bFeignDeath", 1);
		SetEntProp(ragdoll, Prop_Send, "m_bWasDisguised", 1); // This makes the ragdoll use the disguise cosmetics instead of the real spy's cosmetics.
	}
	else
	{
		SetEntProp(ragdoll, Prop_Send, "m_iClass", class);
		SetEntProp(ragdoll, Prop_Send, "m_iTeam", team);
	} // NOTE: There's a glitch with disguises where the gibs are the fake class.
	//if (!IsDisguised(client))
	SetEntPropEnt(ragdoll, Prop_Send, "m_iPlayerIndex", client);
	// TF_CUSTOM_BURNING accounts for regular flamethrow burn, afterburn, hadouken burn, dragon fury annd some others
	// TF_CUSTOM_BURNING_FLARE accounts for flares including indirect detonation from Detonator but not Scorch direct
	
	if (((damagecustom & TF_CUSTOM_BURNING) && !(damagecustom & TF_CUSTOM_BLEEDING)) || (damagecustom & TF_CUSTOM_BURNING_FLARE) && 
	class != TFClass_Pyro && disguise_class != TFClass_Pyro)
		SetEntProp(ragdoll, Prop_Send, "m_bBurning", 1);
	
	Handle playergib_cvar = FindConVar("tf_playergib");
	
	int skin = GetEntProp(client, Prop_Send, "m_iPlayerSkinOverride"); // Check for Voodoo cosmetics
	if (IsDisguisedAsFriendly(client))
	{ skin = GetEntProp(client, Prop_Send, "m_nDisguiseSkinOverride"); }
	
	int wepType = GetWeaponType(weapon);
	
	/*int wep_index = -1;
	if (RealValidEntity(weapon) && HasEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{ wep_index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"); }*/
	if
	(
		(
			(
				(damageType & DMG_BLAST)
				|| // or
				wepType == TYPE_CLASSIC
			)
			&& // and
			(
				damage > 10.0
				|| // or
				(damageType & DMG_CRIT)
			)
			&& // and
			GetConVarInt(playergib_cvar) == 1
			|| // or
			GetConVarInt(playergib_cvar) >= 2
		)
	)
	{
		if (skin != 1)
		{ 
			SetEntProp(ragdoll, Prop_Send, "m_bFeignDeath", 1); // This allows creating multiple gib groups but screws up bodygroups
			if (wepType == TYPE_CLASSIC)
			{
				SetEntProp(ragdoll, Prop_Send, "m_bCritOnHardHit", 1);
				/*float EyePosition[3];
				GetClientEyePosition(client, EyePosition);
				// The Classic's gibbing effect (1098), but how to detect if shot was fully charged? tfc_sniper_mist tfc_sniper_mist2
				int particle = CreateEntityByName("info_particle_system");
				DispatchKeyValue(particle, "effect_name", "tfc_sniper_mist");
				DispatchSpawn(particle);
				ActivateEntity(particle);
				TeleportEntity(particle, EyePosition, NULL_VECTOR, NULL_VECTOR);
				AcceptEntityInput(particle, "Start");
				SetVariantString("OnUser1 !self:Kill::0.1:-1");
				AcceptEntityInput(particle, "AddOutput");
				AcceptEntityInput(particle, "FireUser1");*/
			}
		}
		SetEntProp(ragdoll, Prop_Send, "m_bGib", 1);
		//int gibHead = CreateEntityByName("raggib");
		//SetEntPropVector(gibHead, Prop_Send, "m_vecOrigin", PlayerPosition);
	}
	if (playergib_cvar != null) CloseHandle(playergib_cvar);
	if (damagecustom)
	{ SetEntProp(ragdoll, Prop_Send, "m_iDamageCustom", damagecustom); }
	
	if (RealValidEntity(weapon))
	{
		char wep_netclass_attacker[PLATFORM_MAX_PATH+1];
		GetEntityClassname(weapon, wep_netclass_attacker, sizeof(wep_netclass_attacker));
		//PrintToChatAll("%s", wep_netclass_attacker); // Debug
		
		if (wep_netclass_attacker[0] && 
		(StrContains(wep_netclass_attacker, "tf_weapon*", false) || StrContains(wep_netclass_attacker, "tf_wearable*", false)) )
		{
			//PrintToChatAll("%i", wep_index); 
			//PrintToChatAll("%i", damagecustom);
			if (wepType == TYPE_NEONLATOR) // Neon Annihilator (For some reason it's assigned 2 IDs. https://steamcommunity.com/sharedfiles/filedetails/?id=504159631)
			{ SetEntProp(ragdoll, Prop_Send, "m_iDamageCustom", 46); }
			else if (wepType == TYPE_SPYCICLE && damagecustom == TF_CUSTOM_BACKSTAB) // Spy-cicle
			{ SetEntProp(ragdoll, Prop_Send, "m_bIceRagdoll", 1); }
			else if (wepType == TYPE_MANMELTER || wepType == TYPE_THIRDDEGREE || wepType == TYPE_PHLOG) // Manmelter (595) + The Third Degree (593) + Phlogistinator (594)
			{ SetEntProp(ragdoll, Prop_Send, "m_bBecomeAsh", 1); }
			else if (wepType == TYPE_EREWARD || wepType == TYPE_WPRICK) // Your Eternal Reward (225) + Wanga Prick (574)
			{ SetEntProp(ragdoll, Prop_Send, "m_bCloaked", 1); }
		}
	}
	
	SetEntProp(ragdoll, Prop_Send, "m_nForceBone", 0);
	if (RealValidEntity(GetEntPropEnt(client, Prop_Send, "m_hGroundEntity")))
	{ SetEntProp(ragdoll, Prop_Send, "m_bOnGround", 1); }
	
	SetEntPropFloat(ragdoll, Prop_Send, "m_flHeadScale", GetEntPropFloat(client, Prop_Send, "m_flHeadScale"));
	SetEntPropFloat(ragdoll, Prop_Send, "m_flTorsoScale", GetEntPropFloat(client, Prop_Send, "m_flTorsoScale"));
	SetEntPropFloat(ragdoll, Prop_Send, "m_flHandScale", GetEntPropFloat(client, Prop_Send, "m_flHandScale"));
	
	int old_rag = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (RealValidEntity(old_rag))
	{ AcceptEntityInput(old_rag, "Kill"); }
	SetEntPropEnt(client, Prop_Send, "m_hRagdoll", ragdoll);
	
	DispatchSpawn(ragdoll);
	ActivateEntity(ragdoll);
	
	//g_Ragdoll[client] = ragdoll;
}

/*void AlterACDRRagdoll(int ragdoll, int client, int weapon, const float damage, int damageType, const float damageForce[3], int damagecustom)
{
	//SDKCall(hCreateRagdollEntity, client);
	
	//RemoveACDRRagdoll(client);
	
	if (!RealValidEntity(ragdoll)) return;
	
	SetEntProp(ragdoll, Prop_Send, "m_bFeignDeath", 0);
	SetEntProp(ragdoll, Prop_Send, "m_bGib", 0);
	
	TFClassType disguise_class = view_as<TFClassType>(GetEntProp(client, Prop_Send, "m_nDisguiseClass"));
	int disguise_team = GetEntProp(client, Prop_Send, "m_nDisguiseTeam");
	//int disguise_index = GetEntProp(client, Prop_Send, "m_iDisguiseTargetIndex");
	if (IsDisguisedAsFriendly(client))
	{
		SetEntProp(ragdoll, Prop_Send, "m_iClass", disguise_class);
		SetEntProp(ragdoll, Prop_Send, "m_iTeam", disguise_team);
		//SetEntProp(ragdoll, Prop_Send, "m_bFeignDeath", 1);
		SetEntProp(ragdoll, Prop_Send, "m_bWasDisguised", 1); // This makes the ragdoll use the disguise cosmetics instead of the real spy's cosmetics.
	}
	SetEntPropEnt(ragdoll, Prop_Send, "m_iPlayerIndex", client);
	
	Handle playergib_cvar = FindConVar("tf_playergib");
	
	int skin = GetEntProp(client, Prop_Send, "m_iPlayerSkinOverride"); // Check for Voodoo cosmetics
	if (IsDisguisedAsFriendly(client))
	{ skin = GetEntProp(client, Prop_Send, "m_nDisguiseSkinOverride"); }
	
	int wepType = GetWeaponType(weapon);
	
	if
	(
		(
			(
				(damageType & DMG_BLAST)
				|| // or
				wepType == TYPE_CLASSIC
			)
			&& // and
			(
				damage > 10.0
				|| // or
				(damageType & DMG_CRIT)
			)
			&& // and
			GetConVarInt(playergib_cvar) == 1
			|| // or
			GetConVarInt(playergib_cvar) >= 2
		)
	)
	{
		if (skin != 1)
		{ 
			SetEntProp(ragdoll, Prop_Send, "m_bFeignDeath", 1); // This allows creating multiple gib groups but screws up bodygroups
			if (wepType == TYPE_CLASSIC)
			{
				SetEntProp(ragdoll, Prop_Send, "m_bCritOnHardHit", 1);
			}
		}
		SetEntProp(ragdoll, Prop_Send, "m_bGib", 1);
	}
	if (playergib_cvar != null) CloseHandle(playergib_cvar);
	if (damagecustom)
	{ SetEntProp(ragdoll, Prop_Send, "m_iDamageCustom", damagecustom); }
	
	if (RealValidEntity(weapon))
	{
		char wep_netclass_attacker[PLATFORM_MAX_PATH+1];
		GetEntityClassname(weapon, wep_netclass_attacker, sizeof(wep_netclass_attacker));
		//PrintToChatAll("%s", wep_netclass_attacker); // Debug
		
		if (wep_netclass_attacker[0] && 
		(StrContains(wep_netclass_attacker, "tf_weapon*", false) || StrContains(wep_netclass_attacker, "tf_wearable*", false)) )
		{
			//PrintToChatAll("%i", wep_index); 
			//PrintToChatAll("%i", damagecustom);
			if (wepType == TYPE_NEONLATOR) // Neon Annihilator (For some reason it's assigned 2 IDs. https://steamcommunity.com/sharedfiles/filedetails/?id=504159631)
			{ SetEntProp(ragdoll, Prop_Send, "m_iDamageCustom", 46); }
			else if (wepType == TYPE_SPYCICLE && damagecustom == TF_CUSTOM_BACKSTAB) // Spy-cicle
			{ SetEntProp(ragdoll, Prop_Send, "m_bIceRagdoll", 1); }
			else if (wepType == TYPE_MANMELTER || wepType == TYPE_THIRDDEGREE || wepType == TYPE_PHLOG) // Manmelter (595) + The Third Degree (593) + Phlogistinator (594)
			{ SetEntProp(ragdoll, Prop_Send, "m_bBecomeAsh", 1); }
			else if (wepType == TYPE_EREWARD || wepType == TYPE_WPRICK) // Your Eternal Reward (225) + Wanga Prick (574)
			{ SetEntProp(ragdoll, Prop_Send, "m_bCloaked", 1); }
		}
	}
	
	//SetEntProp(ragdoll, Prop_Send, "m_nForceBone", 0);
	//if (RealValidEntity(GetEntPropEnt(client, Prop_Send, "m_hGroundEntity")))
	//{ SetEntProp(ragdoll, Prop_Send, "m_bOnGround", 1); }
	int old_rag = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (RealValidEntity(old_rag))
	{ AcceptEntityInput(old_rag, "Kill"); }
	SetEntPropEnt(client, Prop_Send, "m_hRagdoll", ragdoll);
	
	//DispatchSpawn(ragdoll);
	//ActivateEntity(ragdoll);
	
	//g_Ragdoll[client] = ragdoll;
}*/

void ModelIndexToString(int index, char[] model, int size)
{
	int table = FindStringTable("modelprecache");
	ReadStringTable(table, index, model, size);
}

void WeaponAttackAvailable(int client, bool boolean)
{
	/*int cl_class = GetEntProp(client, Prop_Send, "m_iClass");
	if (cl_class != 8)
	{
		SetEntProp(client, Prop_Send, "m_bFeignDeathReady", boolean ? 0 : 1);
		return;
	}*/
	
	SetEntPropFloat(client, Prop_Send, "m_flNextAttack", boolean ? GetGameTime()+3 : GetGameTime() + 86400.0);
	int slotP = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
	int slotS = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
	int slotM = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
	int slotO = GetPlayerWeaponSlot(client, TFWeaponSlot_Grenade); // To be honest I don't know why I included this.
	int offset = FindSendPropInfo("CTFWeaponBase", "m_flNextPrimaryAttack");
	int offset2 = FindSendPropInfo("CTFWeaponBase", "m_flNextSecondaryAttack");
	
	if (RealValidEntity(slotP))
	{
		SetEntPropFloat(slotP, Prop_Data, "m_flNextPrimaryAttack", boolean ? GetGameTime()+3 : GetGameTime() + 86400.0);
		SetEntPropFloat(slotP, Prop_Data, "m_flNextSecondaryAttack", boolean ? GetGameTime()+3 : GetGameTime() + 86400.0);
		ChangeEdictState(slotP, offset);
		ChangeEdictState(slotP, offset2);
	}
	if (RealValidEntity(slotS))
	{
		SetEntPropFloat(slotS, Prop_Data, "m_flNextPrimaryAttack", boolean ? GetGameTime()+3 : GetGameTime() + 86400.0);
		SetEntPropFloat(slotS, Prop_Data, "m_flNextSecondaryAttack", boolean ? GetGameTime()+3 : GetGameTime() + 86400.0);
		ChangeEdictState(slotS, offset);
		ChangeEdictState(slotS, offset2);
	}
	if (RealValidEntity(slotM))
	{
		SetEntPropFloat(slotM, Prop_Data, "m_flNextPrimaryAttack", boolean ? GetGameTime()+3 : GetGameTime() + 86400.0);
		SetEntPropFloat(slotM, Prop_Data, "m_flNextSecondaryAttack", boolean ? GetGameTime()+3 : GetGameTime() + 86400.0);
		ChangeEdictState(slotM, offset);
		ChangeEdictState(slotM, offset2);
	}
	if (RealValidEntity(slotO))
	{
		SetEntPropFloat(slotO, Prop_Data, "m_flNextPrimaryAttack", boolean ? GetGameTime()+3 : GetGameTime() + 86400.0);
		SetEntPropFloat(slotO, Prop_Data, "m_flNextSecondaryAttack", boolean ? GetGameTime()+3 : GetGameTime() + 86400.0);
		ChangeEdictState(slotO, offset);
		ChangeEdictState(slotO, offset2);
	}
}

/*bool HasSlotWeaponType(int client, int slot, int type)
{
	int slotEnt = GetPlayerWeaponSlot(client, slot);
	
	int wep_index = -1;
	if (HasEntProp(slotEnt, Prop_Send, "m_iItemDefinitionIndex"))
	{ wep_index = GetEntProp(slotEnt, Prop_Send, "m_iItemDefinitionIndex"); }
	
	if (wep_index != -1 && wep_index == type) return true;
	
	return false;
}*/

int GetWeaponType(int slotEnt)
{
	if (!RealValidEntity(slotEnt)) return -1;
	
	char model[64];
	//GetEntPropString(slotEnt, Prop_Data, "m_ModelName", model, sizeof(model));
	int modelidx = GetEntProp(slotEnt, Prop_Send, "m_iWorldModelIndex");
	ModelIndexToString(modelidx, model, sizeof(model));
	//PrintToChatAll("Model Name: %s", model);
	
	if (StrContains(model, "boxing_gloves", false) >= 0)
	{ return TYPE_GLOVES; }
	else if (StrContains(model, "powerjack", false) >= 0)
	{ return TYPE_POWERJACK; }
	else if (StrContains(model, "bear_claw", false) >= 0)
	{ return TYPE_BEARCLAWS; }
	else if (StrContains(model, "shogun_katana", false) >= 0)
	{ return TYPE_ZATOICHI; }
	else if (StrContains(model, "candy_cane", false) >= 0)
	{ return TYPE_CANDYCANE; }
	else if (StrContains(model, "tfc_sniperrifle", false) >= 0)
	{ return TYPE_CLASSIC; }
	else if (StrContains(model, "sd_neonsign", false) >= 0)
	{ return TYPE_NEONLATOR; }
	else if (StrContains(model, "xms_cold_shoulder", false) >= 0)
	{ return TYPE_SPYCICLE; }
	else if (StrContains(model, "drg_manmelter", false) >= 0)
	{ return TYPE_MANMELTER; }
	else if (StrContains(model, "drg_thirddegree", false) >= 0)
	{ return TYPE_THIRDDEGREE; }
	else if (StrContains(model, "drg_phlogistinator", false) >= 0)
	{ return TYPE_PHLOG; }
	else if (StrContains(model, "eternal_reward", false) >= 0)
	{ return TYPE_EREWARD; }
	else if (StrContains(model, "voodoo_pin", false) >= 0)
	{ return TYPE_WPRICK; }
	
	return -1;
}

void player_spawn(Handle event, const char[] name, bool dontBroadcast) 
{
	//int death_flags = GetEventInt(event, "death_flags");
	//if (death_flags & TF_DEATHFLAG_DEADRINGER) {PrintToChatAll("Flags"); return;}
	
	int userID = GetEventInt(event, "userid");
	int client = GetClientOfUserId(userID);
	if (!IsValidClient(client))
	{ return; }
	
	//if (IsPlayerAlive(client))
	//{ return; }
	
	if (isCloaked[client])
	{ ACDRUncloak(client); }
	else if (trigger[client])
	{ TriggerACDR(client, true, true, true, false); }
	
	if (GetConVarBool(DeadRinger_BotSpawn) && IsFakeClient(client))
	{ TriggerACDR(client, false, true, true, true); }
}

void player_hurt(Handle event, const char[] name, bool dontBroadcast) 
{
	int clientID = GetEventInt(event, "userid");
	int client = GetClientOfUserId(clientID);
	if (!IsValidClient(client))
	{ return; }
	
	if (trigger[client])
	{ SetEventInt(event, "health", 0); }
	
	if (isCloaked[client])
	{ SetEventBroadcast(event, true); }
}

void player_death(Handle event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	RequestFrame(player_death_RequestFrame_check, client);
}
void player_death_RequestFrame_check(int client)
{
	if (!IsValidClient(client) || IsPlayerAliveOrNotGhost(client))
	{ return; }
	
	player_death_ResetACDR(client);
}
void player_death_ResetACDR(int client)
{
	if (isCloaked[client])
	{ ACDRUncloak(client); }
	else if (trigger[client])
	{ TriggerACDR(client, true, true, true, false); }
	if (isCloaked[client] || !can[client])
	{ Timer_Ready(client); }
	ResetACDRStuff(client);
}

Action Hook_OnTakeDamage(int client, int& attacker, int& inflictor, float& damage, int& damageType, int& weapon, 
float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (!shouldTrigger) return Plugin_Continue;
	//PrintToChatAll("%i %i %i %f %i", client, attacker, inflictor, damage, damageType);
	//PrintToChatAll("can: %i trigger: %i isCloaked: %i", can[client], trigger[client], isCloaked[client]);
	if (damage <= 0.0)
	{ return Plugin_Continue; }
	
	if (!IsValidClient(client)) 
	{ return Plugin_Continue; }
	if (!canTriggerDR(client))
	{ return Plugin_Continue; }
	if (!GetConVarBool(FindConVar("mp_friendlyfire")) && RealValidEntity(attacker))
	{
		if (GetEntProp(attacker, Prop_Data, "m_iTeamNum") == GetClientTeam(client) && attacker != client)
		{ return Plugin_Continue; }
	}
	float game_time = GetGameTime();
	
	float old_damage = damage;
	
	float finalResult = damage;
	// if (can[client] && trigger[client] || g_ResistTimer[client] > game_time)
	if (g_ResistTimer[client] > game_time)
	{
		float cloak_time = g_UncloakTimer[client]-GetGameTime();
		if (trigger[client]) // If client has trigger state then always assume the max
		{ cloak_time = GetConVarFloat(DeadRinger_CloakTime); }
		float cvar_float_max = GetConVarFloat(DeadRinger_DamageRes_Max);
		float cvar_float_min = GetConVarFloat(DeadRinger_DamageRes_Min);
		
		if (cloak_time >= 0.0 && cvar_float_max >= cvar_float_min)
		{
			float maxMinusMin = cvar_float_max-cvar_float_min; // 0.65 - 0.2 = 0.45
			float minAndMMM = maxMinusMin / (cloak_time+1.0);
			// 0.45 / 7.5 = 0.06
			// 0.45 / 7.4 = 0.06[number gibberish, how tf do i condense it to just 0.06?]
			// 0.45 / 1.0 = 0.45
			
			maxMinusMin = cvar_float_max-minAndMMM;
			// 0.65 - 0.06 = 0.59
			finalResult = damage*maxMinusMin;
		}
	}
	
	if (!can[client] || !trigger[client])
	{
		damage = finalResult;
		return Plugin_Changed;
	}
	
	float meter = GetEntPropFloat(client, Prop_Send, "m_flCloakMeter");
	TFClassType class = TF2_GetPlayerClass(client);
	
	if (TF2_IsPlayerInCondition(client, TFCond_Cloaked))
	{ TF2_RemoveCondition(client, TFCond_Cloaked); }
	SetEntPropFloat(client, Prop_Send, "m_flCloakMeter", 100.0);
	SetEntProp(client, Prop_Send, "m_iClass", TFClass_Spy);
	SetEntProp(client, Prop_Send, "m_bFeignDeathReady", 1);
	
	int infl = RealValidEntity(inflictor) ? inflictor : 0;
	int atta = RealValidEntity(attacker) ? attacker : 0;
	
	shouldTrigger = false;
	SDKHooks_TakeDamage(client, infl, atta, finalResult, damageType, weapon, damageForce, damagePosition);
	shouldTrigger = true;
	damage = 0.0;
	
	SetEntPropFloat(client, Prop_Send, "m_flCloakMeter", meter);
	if (class != TFClass_Spy) SetEntProp(client, Prop_Send, "m_iClass", class);
	
	if (!IsPlayerAliveOrNotGhost(client))
	{
		StopScene(client);
		player_death_ResetACDR(client);
		return Plugin_Continue;
	}
	
	if (TF2_IsPlayerInCondition(client, TFCond_DeadRingered))
	{
		TF2_RemoveCondition(client, TFCond_DeadRingered);
		TF2_RemoveCondition(client, TFCond_Cloaked);
		TF2_RemoveCondition(client, TFCond_SpeedBuffAlly);
	}
	
	if ( ((damageType & DMG_CRIT) || (damageType & DMG_CLUB)) && !(damageType & DMG_BLAST))
	{ DoClientScream(client, 2); }
	else if (damageType & DMG_BLAST)
	{ DoClientScream(client, 0); }
	else if (damageType & DMG_FALL)
	{ DoClientScream(client, 3); }
	else
	{ DoClientScream(client, 1); }
	
	DisguiseRagdollFix(client);
	SpawnACDRRagdoll(client, weapon, old_damage, damageType, damageForce, damagecustom);
	
	ACDRCloak(client, attacker, weapon, damageForce);
	return Plugin_Changed;
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float[3] vel, float[3] angles, int& weapon)
{
	if (!IsValidClient(client) || !IsPlayerAliveOrNotGhost(client)) return Plugin_Continue;
	
	if (!isCloaked[client]) return Plugin_Continue;
	
	bool hasChanged = false;
	
	if (buttons & IN_ATTACK)
    {
		buttons &= ~IN_ATTACK;
		hasChanged = true;
	}
	if (buttons & IN_ATTACK2)
    {
		buttons &= ~IN_ATTACK2;
		hasChanged = true;
	}
	
	if (hasChanged)
	{ return Plugin_Changed; }
	return Plugin_Continue;
}

void ACDRCloak(int client, int attacker, int weapon, const float damageForce[3])
{
	HookThink(client);
	
	if (IsValidClient(client))
	{
		float uncloak_time = 6.5;
		if (DeadRinger_CloakTime != null)
		{ uncloak_time = GetConVarFloat(DeadRinger_CloakTime); }
		
		float ready_time = 8.0;
		if (DeadRinger_RechargeTime != null)
		{ ready_time = GetConVarFloat(DeadRinger_RechargeTime); }
		
		float game_time = GetGameTime();
		
		//{ g_UncloakTimer[client] = CreateTimer(time, Timer_Uncloak, client); }
		//g_BoostTimer[client] = CreateTimer(3.0, Timer_Boost, client);
		
		g_UncloakTimer[client] = game_time+uncloak_time;
		//g_BoostTimer[client] = game_time+3.0;
		g_ReadyTimer[client] = g_UncloakTimer[client]+ready_time;
		g_ResistTimer[client] = game_time+3.0;
		
		TF2_AddCondition(client, TFCond_StealthedUserBuffFade);
		if (GetConVarBool(DeadRinger_AfterburnImmune)) TF2_AddCondition(client, TFCond_AfterburnImmune, 3.0);
		if (GetConVarBool(DeadRinger_SpeedBoost)) TF2_AddCondition(client, TFCond_SpeedBuffAlly, 3.0);
		
		//SpawnACDRWeaponAmmoBox(client);
		if (DeadRinger_CloakTime == null || GetConVarFloat(DeadRinger_CloakTime) > 0.0)
		{ WeaponAttackAvailable(client, false); }
		
		FakeClientCommand(client, "dropitem"); FakeClientCommand(client, "dropitem"); FakeClientCommand(client, "dropitem");
		
		if (TF2_IsPlayerInCondition(client, TFCond_OnFire))
		{ TF2_RemoveCondition(client, TFCond_OnFire); }
		if (TF2_IsPlayerInCondition(client, TFCond_Bleeding))
		{ TF2_RemoveCondition(client, TFCond_Bleeding); }
		if (TF2_IsPlayerInCondition(client, TFCond_BurningPyro))
		{ TF2_RemoveCondition(client, TFCond_BurningPyro); }
		if (TF2_IsPlayerInCondition(client, TFCond_Cloaked))
		{ TF2_RemoveCondition(client, TFCond_Cloaked); }
		//if (TF2_IsPlayerInCondition(client, TFCond_Taunting))
		//{ TF2_RemoveCondition(client, TFCond_Taunting); }
		
		if (IsValidClient(attacker) && attacker != client)
		{
			if (TF2_IsHolidayActive(TFHoliday_Halloween))
			{
				float EyePosition[3];
				GetClientEyePosition(client, EyePosition);
				int soul = CreateEntityByName("halloween_souls_pack");
				SetEntProp(soul, Prop_Send, "m_iTeamNum", GetClientTeam(client));
				SetEntPropEnt(soul, Prop_Send, "m_hTarget", attacker);
				
				TeleportEntity(soul, EyePosition, NULL_VECTOR, NULL_VECTOR);
				DispatchSpawn(soul);
				ActivateEntity(soul);
			}
			
			if (GetConVarBool(DeadRinger_ExtraEffects))
			{
				//PrintToChatAll("%i", wep_index);
				int killcount_last_deploy = GetEntProp(attacker, Prop_Send, "m_iKillCountSinceLastDeploy");
				SetEntProp(attacker, Prop_Send, "m_iKillCountSinceLastDeploy", killcount_last_deploy + 1);
				// ^ This is to make sure the katana can unsheath again without self damage
				
				int wepType = GetWeaponType(weapon);
				
				if (wepType >= 0)
				{
					// Active Weapon Buffs
					if (wepType == TYPE_GLOVES) // Killing Gloves Of Boxing (5-Second Crit Boost)
					{ TF2_AddCondition(attacker, TFCond_CritOnKill, 5.0); }
					else if (wepType == TYPE_POWERJACK) // Powerjack (Health Boost)
					{ GiveHealth(attacker, 25); }
					else if (wepType == TYPE_BEARCLAWS) // Warrior's Spirit (Health Boost)
					{ GiveHealth(attacker, 50); }
					else if (wepType == TYPE_ZATOICHI) // Half-Zatoichi (Health Boost)
					{
						GiveHealth(attacker, (GetResourceProperty(attacker, "m_iMaxHealth")/2), true, false);
						//PrintToChatAll("%i", HasEntProp(weapon, Prop_Send, "m_bIsBloody"));
						//if (HasEntProp(weapon, Prop_Send, "m_bIsBloody")) SetEntProp(weapon, Prop_Send, "m_bIsBloody", 1);
					}
				}
				
				int meleeWepType = GetWeaponType(GetPlayerWeaponSlot(attacker, TFWeaponSlot_Melee));
				// Passive Weapon Buffs
				if (meleeWepType == TYPE_CANDYCANE) // Candy Cane (Health-pack Drop)
				{
					SpawnPack(client, damageForce);
				}
			}
		}
		
		int medigun = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
		if (RealValidEntity(medigun))
		{
			if (HasEntProp(medigun, Prop_Send, "m_hHealingTarget") && HasEntProp(medigun, Prop_Send, "m_bHealing"))
			{
				int healClient = GetEntPropEnt(medigun, Prop_Send, "m_hHealingTarget");
				if (IsValidClient(healClient))
				{ TF2_RemoveCondition(healClient, TFCond_Healing); }
				SetEntProp(medigun, Prop_Send, "m_hHealingTarget", -1);
				SetEntProp(medigun, Prop_Send, "m_bHealing", 0);
				if (HasEntProp(medigun, Prop_Send, "m_flChargeLevel"))
				{
					float chargeLevel = GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel");
					if (chargeLevel > 90.0)
					{ SetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel", 90.0); }
				}
			}
		}
		
		if (HasEntProp(client, Prop_Send, "m_nNumHealers") && GetEntProp(client, Prop_Send, "m_nNumHealers") > 0)
		{
			for (int loopclient = 1; loopclient <= MAXPLAYERS; loopclient++)
			{
				if (!IsValidClient(loopclient))
				{ continue; }
				if (!IsPlayerAlive(loopclient))
				{ continue; }
				
				int loopmedigun = GetPlayerWeaponSlot(loopclient, TFWeaponSlot_Secondary);
				if (!RealValidEntity(loopmedigun))
				{ continue; }
				if (!HasEntProp(loopmedigun, Prop_Send, "m_hHealingTarget") || !HasEntProp(loopmedigun, Prop_Send, "m_bHealing"))
				{ continue; }
				
				int healingTarget = GetEntPropEnt(loopmedigun, Prop_Send, "m_hHealingTarget");
				int healingBool = GetEntProp(loopmedigun, Prop_Send, "m_bHealing");
				if (healingBool && IsValidClient(healingTarget) && healingTarget == client)
				{
					TF2_RemoveCondition(client, TFCond_Healing);
					SetEntProp(loopmedigun, Prop_Send, "m_hHealingTarget", -1);
					SetEntProp(loopmedigun, Prop_Send, "m_bHealing", 0);
				}
			}
		}
		
		//SendProxy_Hook(client, "m_lifeState", Prop_Int, ProxyCallback_lifestate);
		//Hook_Manager_AliveProp(client);
		
		//PrintToServer("%i", GetEntProp(ply_manager, Prop_Send, "m_bAlive"));
	}
	can[client] = false;
	trigger[client] = false;
	isCloaked[client] = true;
	
	PrintHintText(client, "DR activated.");
}

void ACDRUncloak(int client, bool killtimer = true)
{
	if (!IsValidClient(client))
	{ return; }
	//if (g_UncloakTimer[client] != null && killtimer)
	//{ KillTimer(g_UncloakTimer[client]); }
	if (killtimer)
	{ g_UncloakTimer[client] = -1.0; }
	if (IsPlayerAlive(client)) {
		//SetEntityRenderColor(client, 255, 255, 255, 255);
		if (TF2_IsPlayerInCondition(client, TFCond_StealthedUserBuffFade))
		{ TF2_RemoveCondition(client, TFCond_StealthedUserBuffFade); }
		TF2_AddCondition(client, TFCond_Cloaked);
		TF2_RemoveCondition(client, TFCond_Cloaked);
	}
	EmitGameSoundToAll(UNCLOAK_SND, client);
	WeaponAttackAvailable( client, true );
	
	//g_ReadyTimer[client] = CreateTimer(ready_time, Timer_Ready, client);
	PrintHintText(client, "DR Uncloaked.");
	
	isCloaked[client] = false;
	
	//if (SendProxy_IsHooked(client, "m_lifeState"))
	//{ SendProxy_Unhook(client, "m_lifeState", ProxyCallback_lifestate); }
	//Hook_Manager_AliveProp(client, false);
}

void HookThink(int entity, bool boolean = true)
{
    if (!IsValidClient(entity)) return;
    if (boolean)
    { SDKHook(entity, POST_THINK_HOOK, Hook_Charge_OnThinkPost); g_fClientWait[entity] = 0.0; }
    else
    { SDKUnhook(entity, POST_THINK_HOOK, Hook_Charge_OnThinkPost); }
}

public void OnMapEnd()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (g_fClientWait[i] >= THINK_WAITTIME)
		{
			g_fClientWait[i] = 0.0;
		}
	}
}

void Hook_Charge_OnThinkPost(int client)
{
	if (!IsServerProcessing()) return;
	
	if (!IsValidClient(client) || IsPlayerAliveOrNotGhost(client))
	{
		if (GetGameTime() - g_fClientWait[client] >= 0.0)
		{
			UpdateACDRTimers(client);
			g_fClientWait[client] = g_fClientWait[client] + THINK_WAITTIME;
		}
	}
}

void UpdateACDRTimers(int client)
{
	float game_time = GetGameTime();
	
	if (g_UncloakTimer[client] <= game_time && isCloaked[client])
	{ Timer_Uncloak(client); }
	//if (g_BoostTimer[client] <= game_time)
	//{ Timer_Boost(client); }
	if (g_ReadyTimer[client] <= game_time && !can[client])
	{ Timer_Ready(client); }
}

void Timer_Uncloak(int client)
{
	ACDRUncloak(client, false);
}
/*void Timer_Boost(int client)
{
	g_BoostTimer[client] = null;
}*/
void Timer_Ready(int client)
{
	HookThink(client, false);
	can[client] = true;
	PrintHintText(client, "DR is ready.");
}

// Timers end

void player_changeclass(Handle event, const char[] name, bool dontBroadcast) 
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsValidClient(client)) return;
	
	RequestFrame(player_death_ResetACDR, client);
}

// Stocks //
int TriggerACDR(int client, bool hint = true, bool clean = true, bool override = false, bool override_bool = false)
{
	if (!IsValidClient(client))
	{ return -1; }
	
	if (IsPlayerAliveOrNotGhost(client) && can[client] && !trigger[client] && (!override || override_bool))
	{
		trigger[client] = true;
		SDKUnhook(client, CHANGE_DAMAGE_HOOK, Hook_OnTakeDamage); // Make sure hooks don't keep piling up
		SDKHook(client, CHANGE_DAMAGE_HOOK, Hook_OnTakeDamage);
		if (hint)
		{ PrintHintText(client, ACTIVE_STR); }
		if (clean)
		{
			/*if (g_UncloakTimer[client] != null)
			{ KillTimer(g_UncloakTimer[client], true); }
			if (g_BoostTimer[client] != null)
			{ KillTimer(g_BoostTimer[client], true); }
			if (g_ReadyTimer[client] != null)
			{ KillTimer(g_ReadyTimer[client], true); }
			g_UncloakTimer[client] = null;
			g_BoostTimer[client] = null;
			g_ReadyTimer[client] = null;*/
			g_UncloakTimer[client] = -1.0;
			//g_BoostTimer[client] = -1.0;
			g_ReadyTimer[client] = -1.0;
		}
		return 1;
	}
	else if (can[client] && trigger[client] && (!override || !override_bool))
	{
		trigger[client] = false;
		SDKUnhook(client, CHANGE_DAMAGE_HOOK, Hook_OnTakeDamage);
		if (hint)
		{ PrintHintText(client, INACTIVE_STR); }
		if (clean)
		{
			/*if (g_UncloakTimer[client] != null)
			{ KillTimer(g_UncloakTimer[client], true); }
			if (g_BoostTimer[client] != null)
			{ KillTimer(g_BoostTimer[client], true); }
			if (g_ReadyTimer[client] != null)
			{ KillTimer(g_ReadyTimer[client], true); }
			g_UncloakTimer[client] = null;
			g_BoostTimer[client] = null;
			g_ReadyTimer[client] = null;*/
			//Hook_Manager_AliveProp(client, false);
			g_UncloakTimer[client] = -1.0;
			//g_BoostTimer[client] = -1.0;
			g_ReadyTimer[client] = -1.0;
		}
		return 0;
	}
	return -1;
}

/*bool IsDisguised(int client)
{
	int disguise_class = GetEntProp(client, Prop_Send, "m_nDisguiseClass");
	int disguise_index = GetEntProp(client, Prop_Send, "m_iDisguiseTargetIndex");
	if (TF2_IsPlayerInCondition(client, TFCond_Disguised) && disguise_index > 0 && disguise_class > 0)
	{
		return true;
	}
	return false;
}*/

bool IsDisguisedAsFriendly(int client)
{
	//int class = GetEntProp(client, Prop_Send, "m_iClass");
	int team = GetClientTeam(client);
	
	int disguise_class = GetEntProp(client, Prop_Send, "m_nDisguiseClass");
	int disguise_team = GetEntProp(client, Prop_Send, "m_nDisguiseTeam");
	int disguise_index = GetEntProp(client, Prop_Send, "m_iDisguiseTargetIndex");
	if (TF2_IsPlayerInCondition(client, TFCond_Disguised) && GetConVarBool(DeadRinger_FriendlyDisguise) && disguise_index > -1 &&
	disguise_class > 0 && disguise_team == team)
	{
		return true;
	}
	return false;
}

bool IsValidClient(int client, bool replaycheck = true)
{
	if (client <= 0 || client > MaxClients || 
	!IsClientInGame(client) || 
	GetEntProp(client, Prop_Send, "m_bIsCoaching")) return false;
	if (replaycheck)
	{
		if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	}
	return true;
}

bool IsPlayerAliveOrNotGhost(int client)
{
	return (IsPlayerAlive(client) && !TF2_IsPlayerInCondition(client, TFCond_HalloweenGhostMode));
}

bool RealValidEntity(int entity)
{
	return (entity > 0 && IsValidEntity(entity));
}

bool canTriggerDR(int client)
{
	if (GetEntProp(client, Prop_Data, "m_takedamage") <= 0 || 
	TF2_IsPlayerInCondition(client, TFCond_Ubercharged) || 
	TF2_IsPlayerInCondition(client, TFCond_UberchargedHidden) ||
	TF2_IsPlayerInCondition(client, TFCond_UberchargedCanteen) || 
	TF2_IsPlayerInCondition(client, TFCond_UberchargedOnTakeDamage) ||
	TF2_IsPlayerInCondition(client, TFCond_Taunting) )
	{ return false; }
	return true;
}

int GetResourceProperty(int client, const char[] str)
{
	int ply_manager = FindEntityByClassname(-1, "tf_player_manager");
	if (RealValidEntity(ply_manager))
	{
		return GetEntProp(ply_manager, Prop_Send, str, _, client);
	}
	return -1;
}

void GiveHealth(int client, int total_Heal = 0, bool overheal = false, bool event = true)
{
	if (total_Heal <= 0) return;
	
	int HP = GetClientHealth(client);
	int max_HP = GetResourceProperty(client, "m_iMaxHealth");
	if (overheal)
	{ max_HP = max_HP+(max_HP/2); }
	
	/*if (total_Heal+HP >= max_HP)
	{ SetEntityHealth(client, max_HP); }
	else
	{ SetEntityHealth(client, total_Heal+HP); }*/
	if (HP < max_HP)
	{
		if (total_Heal+HP >= max_HP)
		{ SetEntityHealth(client, max_HP); }
		else
		{ SetEntityHealth(client, total_Heal+HP); }
	}
	
	if (event)
	{
		Event player_healonhit = CreateEvent("player_healonhit", true);
		SetEventInt(player_healonhit, "amount", total_Heal);
		SetEventInt(player_healonhit, "entindex", EntRefToEntIndex(client));
		FireEvent(player_healonhit);
	}
}

void SpawnPack(int client, const float damageForce[3])
{
	// ent_create item_healthkit_small AutoMaterialize 0 targetname "mahboi"
	// ent_fire item_healthkit_small addoutput "OnPlayerTouch !self:Kill::0:-1"
	
	int pack = CreateEntityByName("item_healthkit_small");
	DispatchKeyValue(pack, "AutoMaterialize", "0");
	//DispatchKeyValue(pack, "velocity", "0.0 0.0 1.0");
	//DispatchKeyValue(pack, "basevelocity", "0.0 0.0 1.0");
	//SetEntPropEnt(pack, Prop_Data, "m_hOwner", client);
	
	float cl_pos[3];
	GetClientEyePosition(client, cl_pos);
	
	float pack_vel[3]; //pack_vel = (view_as<float>({0, 0, -100}));
	pack_vel[0] = damageForce[0]; pack_vel[1] = damageForce[1]; pack_vel[2] = damageForce[2]-100.0;
	
	TeleportEntity(pack, cl_pos, NULL_VECTOR, pack_vel);
	
	SetEntProp(pack, Prop_Data, "m_bActivateWhenAtRest", 1);
	//SetEntProp(pack, Prop_Data, "m_nNextThinkTick", -1);
	SetEntProp(pack, Prop_Send, "m_ubInterpolationFrame", 0);
	SetEntPropEnt(pack, Prop_Send, "m_hOwnerEntity", client);
	SetEntityGravity(pack, 1.0);
	
	DispatchSpawn(pack);
	ActivateEntity(pack);
	
	SetEntityMoveType(pack, MOVETYPE_FLYGRAVITY);
	SetEntProp(pack, Prop_Send, "movecollide", 1); // These two...
	SetEntProp(pack, Prop_Data, "m_MoveCollide", 1); // ...allow the pack to bounce.
	
	DispatchKeyValue(pack, "nextthink", "0.5"); // The fix to the laggy physics.
	//SetEntProp(pack, Prop_Send, "movetype", MOVETYPE_FLYGRAVITY);
	//SetEntProp(pack, Prop_Data, "m_MoveType", MOVETYPE_FLYGRAVITY);
	
	SetVariantString("OnPlayerTouch !self:Kill::0:-1");
	AcceptEntityInput(pack, "AddOutput");
	
	SetVariantString("OnUser1 !self:Kill::30.0:-1");
	AcceptEntityInput(pack, "AddOutput");
	AcceptEntityInput(pack, "FireUser1");
}

/*void FakeFinalHitsound(int client)
{
	if (!IsValidClient(client) || IsFakeClient(client)) return;
	
	Event fakeEvent = CreateEvent("npc_hurt", true);
	SetEventInt(fakeEvent, "attacker_player", GetClientUserId(client));
	//SetEventInt(fakeEvent, "entindex", Ent);
	SetEventInt(fakeEvent, "health", 0);
	SetEventInt(fakeEvent, "damageamount", 1);
	
	FireEvent(fakeEvent);
}*/

/*void Hook_Manager_AliveProp(int client, bool boolean = true)
{
	int ply_manager = FindEntityByClassname(-1, "tf_player_manager");
	if (RealValidEntity(ply_manager))
	{
		//int offset = FindSendPropInfo("CTFPlayerResource", "m_bAlive");
		//if (boolean)
		//{ SendProxy_HookArrayProp(ply_manager, "m_bAlive", 0, Prop_Int, ProxyCallback_bAlive); }
		//else if (SendProxy_IsHookedArrayProp(ply_manager, "m_bAlive", 0))
		//{ SendProxy_UnhookArrayProp(ply_manager, "m_bAlive", 0, Prop_Int, ProxyCallback_bAlive); }
		//if (boolean)
		//{ SetEntProp(ply_manager, Prop_Send, "m_bAlive", client); }
		//else if (SendProxy_IsHookedArrayProp(ply_manager, "m_bAlive", client))
		//{ SendProxy_UnhookArrayProp(ply_manager, "m_bAlive", client, Prop_Int, ProxyCallback_bAlive); }
		if (boolean)
		{ SDKHook(ply_manager, THINK_POST_HOOK, Hook_OnThinkPost); }
		else
		{ SDKUnhook(ply_manager, THINK_POST_HOOK, Hook_OnThinkPost); }
	}
}*/

/*void Hurt(Handle event, const char[] name, bool dontBroadcast) 
{
	int damage = GetEventInt(event,"damageamount");
	if (damage < 1) return Plugin_Continue;
	
	int clientID = GetEventInt(event, "userid");
	int client = GetClientOfUserId(clientID);
	int aID = GetEventInt(event,"attacker");
	int a = GetClientOfUserId(aID);
	int wepID = GetEventInt(event, "weaponid");
	int wep = EntIndexToEntRef(wepID);
	int custom = GetEventInt(event, "custom");
	char wep_netclass_attacker[PLATFORM_MAX_PATH+1];
	if (RealValidEntity(wep))
	{
		GetEntityClassname(wep, wep_netclass_attacker, sizeof(wep_netclass_attacker) );
	}
	
	if (!IsValidClient(client)) 
		return Plugin_Continue;
	
	if (can[client] && trigger[client]) 
	{
		Handle event1 = CreateEvent("player_death");
		
		if (event1 != null)
		{
			SetEventInt(event1, "userid", clientID);
			SetEventInt(event1, "victim_entindex", EntRefToEntIndex(client));
			SetEventInt(event1, "inflictor_entindex", EntRefToEntIndex(a));
			SetEventInt(event1, "attacker", GetEventInt(event, "attacker"));
			//SetEventInt(event1, "weapon", wep);
			SetEventInt(event1, "weaponid", GetEventInt(event, "weaponid"));
			SetEventInt(event1, "damagebits", TF_DEATHFLAG_DEADRINGER);
			SetEventInt(event1, "customkill", custom);
			if (RealValidEntity(wep) && wep_netclass_attacker[1]) {
				SetEventString(event1, "weapon", wep_netclass_attacker);
				SetEventString(event1, "weapon_logclassname", wep_netclass_attacker);
			}
			//if (RealValidEntity(g_wep_netclass_attacker[client]) ) {
			//SetEventInt(event1, "weapon_logclassname", g_wep_netclass_attacker[client]);
			//}
			//g_wep_netclass_attacker[client] = -1;
			SetEventInt(event1, "weapon_def_index", wepID);
			
			bool crit = GetEventBool(event, "crit");
			bool minicrit = GetEventBool(event, "minicrit");
			if (crit == true) 
			{
				SetEventInt(event1, "crit_type", 2);
			}
			else 
			{
			if (minicrit == true) SetEventInt(event1, "crit_type", 1);
			}
			
			FireEvent(event1);
		}
		
		if (IsValidClient(client))
		{
			//SetEntityRenderMode(client,RENDER_GLOW);
			TF2_AddCondition(client, TFCond_StealthedUserBuffFade);
			TF2_AddCondition(client, TFCond_AfterburnImmune);
			TF2_AddCondition(client, TFCond_SpeedBuffAlly);
			//SetEntityRenderColor(client, 255, 255, 255, 0);
			
			//SetEventInt(event, "damageamount", damage / 1.5)
			
			AlterACDRRagdoll(client, damage, damageType);
			SpawnACDRWeaponAmmoBox(client);
			
			WeaponAttackAvailable( client, false );
			
			if (TF2_IsPlayerInCondition(client, TFCond_OnFire))
				{ TF2_RemoveCondition(client, TFCond_OnFire); }
			if (TF2_IsPlayerInCondition(client, TFCond_BurningPyro))
				{ TF2_RemoveCondition(client, TFCond_BurningPyro); }
			
			//Hook_Manager_AliveProp(client);
			
			g_UncloakTimer[client] = CreateTimer(6.5, Timer_Uncloak, client);
			g_BoostTimer[client] = CreateTimer(3.0, Timer_Boost, client);
		}
		can[client] = false;
		trigger[client] = false;
		
		PrintHintText(client, "DR activated.");
		//EmitSoundToAll(SND, g_Ragdoll[client]);
	}
	return Plugin_Continue;
}*/