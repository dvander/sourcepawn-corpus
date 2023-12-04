#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma newdecls required
#pragma semicolon 1

#define PLUGIN_NAME "[L4D2] Vulnerable Passing Bots"
#define PLUGIN_AUTHOR "Shadowysn"
#define PLUGIN_DESC "Makes Team 4 (Passing) Bots vulnerable."
#define PLUGIN_VERSION "1.0.8b"
#define PLUGIN_URL "https://forums.alliedmods.net/showthread.php?t=338941"
#define PLUGIN_NAME_SHORT "Vulnerable Passing Bots"
#define PLUGIN_NAME_TECH "l4d1_td_bot"

//#define COMMANDABOT_REACT_TO_OTHER "CommandABot({cmd=%i,bot=GetPlayerFromUserID(%i),target=GetPlayerFromUserID(%i)})"
//#define COMMANDABOT_REACT_TO_ENT "CommandABot({cmd=%i,bot=GetPlayerFromUserID(%i),target=%i})"
//#define COMMANDABOT_MOVE "CommandABot({cmd=1,pos=Vector(%f,%f,%f),bot=GetPlayerFromUserID(%i)})"
//#define COMMANDABOT_RESET "CommandABot({cmd=3,bot=GetPlayerFromUserID(%i)})"

#define BOT_CMD_ATTACK 0
#define BOT_CMD_MOVE 1
#define BOT_CMD_RETREAT 2
#define BOT_CMD_RESET 3

#define AUTOEXEC_CFG "L4D2_Passing_Bot_Vulnerable"

//#define SWARM_TARG_NAME "plugin_insect_swarm_t4_targ"

#define DEBUG 0

ConVar Damage_Enable, Damage_Debug;
bool g_bEnable, g_bDebug;

DataPack g_DamageData[MAXPLAYERS+1];
float g_fInvulnFrameTime[MAXPLAYERS+1];
float g_fPainDelay[MAXPLAYERS+1];
int g_iStoredMelee[MAXPLAYERS+1];

bool g_bLateLoad = false;
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if(GetEngineVersion() == Engine_Left4Dead2)
	{
		g_bLateLoad = late;
		return APLRes_Success;
	}
	strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
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

// TakeDamage
public void OnPluginStart()
{
	static char temp_str[64];
	static char desc_str[128];
	
	Format(temp_str, sizeof(temp_str), "sm_%s_version", PLUGIN_NAME_TECH);
	Format(desc_str, sizeof(desc_str), "Version of the %s plugin.", PLUGIN_NAME_SHORT);
	ConVar version_cvar = CreateConVar(temp_str, PLUGIN_VERSION, desc_str, FCVAR_NONE|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if (version_cvar != null)
		version_cvar.SetString(PLUGIN_VERSION);
	
	Format(temp_str, sizeof(temp_str), "sm_%s_enable", PLUGIN_NAME_TECH);
	Format(desc_str, sizeof(desc_str), "Enable the %s plugin.", PLUGIN_NAME_SHORT);
	Damage_Enable = CreateConVar(temp_str, "1.0", desc_str, FCVAR_NONE, true, 0.0, true, 1.0);
	Damage_Enable.AddChangeHook(CC_PBV_Enable);
	
	Format(temp_str, sizeof(temp_str), "sm_%s_debug", PLUGIN_NAME_TECH);
	Format(desc_str, sizeof(desc_str), "Enable %s debugging messages.", PLUGIN_NAME_SHORT);
	Damage_Debug = CreateConVar(temp_str, "0.0", desc_str, FCVAR_NONE, true, 0.0, true, 1.0);
	Damage_Debug.AddChangeHook(CC_PBV_Debug);
	
	AutoExecConfig(true, AUTOEXEC_CFG);
	SetCvarValues();
	
	HookEvent("player_death", player_death, EventHookMode_Pre);
	HookEvent("revive_success", revive_success, EventHookMode_Pre);
	HookEvent("player_first_spawn", player_first_spawn, EventHookMode_Post);
	HookEvent("player_spawn", player_spawn, EventHookMode_Post);
	
	if (g_bLateLoad)
		HookDamageToAllClients();
	
	#if DEBUG
	RegAdminCmd("sm_vuld", vulDebug, ADMFLAG_ROOT, "debug");
	#endif
}

void CC_PBV_Enable(ConVar convar, const char[] oldValue, const char[] newValue)	{ g_bEnable =	convar.BoolValue;	}
void CC_PBV_Debug(ConVar convar, const char[] oldValue, const char[] newValue)		{ g_bDebug =		convar.BoolValue;	}
void SetCvarValues()
{
	CC_PBV_Enable(Damage_Enable, "", "");
	CC_PBV_Debug(Damage_Debug, "", "");
}
#if DEBUG
Action vulDebug(int client, int args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_vuld <target>");
		return Plugin_Handled;
	}
	
	//for (int i = MAXPLAYERS; i < GetMaxEntities(); i++)
	//{
	//	if (!RealValidEntity(i)) continue;
	//	
	//	static char name[28];
	//	GetEntityClassname(i, name, sizeof(name));
	//	if (strcmp(name, "weapon_melee", false) != 0) continue;
	//	
	//	PrintToServer("m_hOwnerEntity: %i", GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity"));
	//}
	
	static char arg1[128];
	// Get the first argument
	GetCmdArg(1, arg1, sizeof(arg1));
	
	// 
	// target_name - stores the noun identifying the target(s)
	// target_list - array to store clients
	// target_count - variable to store number of clients
	// tn_is_ml - stores whether the noun must be translated
	// 
	static char target_name[MAX_TARGET_LENGTH]; target_name[0] = '\0';
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE, // Only allow alive players
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		// This function replies to the admin with a failure message
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (int i = 0; i < target_count; i++)
	{
		if (!IsValidClient(target_list[i], true, true)) continue;
		
		for (int j = 0; j <= 55; j++)
		{
			//int myWeapon = GetEntPropEnt(target_list[i], Prop_Send, "m_hMyWeapons", j);
			int myWeapon = GetPlayerWeaponSlot(target_list[i], j);
			if (myWeapon != -1)
			{
				static char classname[64];
				GetEntityClassname(myWeapon, classname, sizeof(classname));
				PrintToServer("m_hMyWeapons[%i]: %i %s", j, myWeapon, classname);
			}
		}
	}
	
	return Plugin_Handled;
}
#endif
public void OnPluginEnd()
{
	UnhookEvent("player_death", player_death, EventHookMode_Pre);
	UnhookEvent("revive_success", revive_success, EventHookMode_Pre);
	UnhookEvent("player_first_spawn", player_first_spawn, EventHookMode_Post);
	UnhookEvent("player_spawn", player_spawn, EventHookMode_Post);
	
	HookDamageToAllClients(false);
}

public void OnClientConnected(int client)
{
	HookDamage(client);
}

public void OnClientDisconnect(int client)
{
	HookDamage(client, false);
}

void HookDamageToAllClients(bool boolean = true)
{
	for (int client = 1; client <= MAXPLAYERS; client++) {
		if (!IsValidClient(client) || !IsFakeClient(client) || !IsPassingSurvivor(client)) continue;
		if (boolean)
		{ HookDamage(client); }
		else
		{ HookDamage(client, false); }
	}
}

void HookDamage(int client, bool boolean = true)
{
	if (!IsValidClient(client) || !IsFakeClient(client)) return;
	if (boolean)
	{ SDKHook(client, SDKHook_OnTakeDamagePost, Hook_OnTakeDamagePost); }
	else
	{ SDKUnhook(client, SDKHook_OnTakeDamagePost, Hook_OnTakeDamagePost); }
}

void Hook_OnTakeDamagePost(int client, int attacker, int inflictor, float damage, int damageType, int weapon, 
const float damageForce[3], const float damagePosition[3])
{
	if (!g_bEnable) return;
	
	if (!IsValidClient(client) || !IsPassingSurvivor(client) || !IsPlayerAlive(client)) return;
	float game_time = GetGameTime();
	if (g_fInvulnFrameTime[client] > game_time) return;
	if (RealValidEntity(attacker))
	{
		/*if (IsValidClient(attacker) && IsInfected(attacker))
		{
			g_fInvulnFrameTime[client] = game_time+0.5;
		}*/
		static char class[9];
		GetEntityClassname(attacker, class, sizeof(class));
		if (strcmp(class, "infected", false) == 0)
		{
			g_fInvulnFrameTime[client] = game_time+0.5;
		}
		else if (GetEntityMoveType(attacker) == MOVETYPE_VPHYSICS)
		{
			g_fInvulnFrameTime[client] = game_time+0.25;
		}
	}
	if (RealValidEntity(inflictor))
	{
		if (GetEntityMoveType(inflictor) == MOVETYPE_VPHYSICS)
		{
			g_fInvulnFrameTime[client] = game_time+0.25;
		}
	}
	
	int health = GetClientHealth(client);
	float health_Buffer = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	int health_Buffer_int = RoundToCeil(health_Buffer);
	
	int full_Health;
	if (health <= 1 && health_Buffer >= 1.0)
	{ full_Health = health_Buffer_int; }
	else if (health_Buffer < 1.0)
	{ full_Health = health; }
	else
	{ full_Health = health_Buffer_int + health; }
	
	int rounded_Damage = RoundToCeil(damage);
	
	if (g_bDebug)
	{ PrintToServer("Damage: %i Full Health: %i Health: %i Health Buffer: %i Attacker: %i Inflictor: %i", 
	rounded_Damage, full_Health, health, health_Buffer_int, attacker, inflictor); }
	
	int event_attacker = IsValidClient(attacker) ? GetClientUserId(attacker) : -1;
	int event_attackerent = RealValidEntity(attacker) ? EntRefToEntIndex(attacker) : -1;
	static char event_weapon[64] = "world"; event_weapon[0] = '\0';
	if (RealValidEntity(weapon))
	{ GetEntityClassname(weapon, event_weapon, sizeof(event_weapon)); }
	
	bool canTakeDamage = (GetEntProp(client, Prop_Data, "m_takedamage") == 2);
	
	int damage_Main = health - rounded_Damage;
	int damage_Buffer = 0;
	if (damage_Main < 1)
	{
		damage_Buffer = health_Buffer_int - (rounded_Damage - damage_Main);
		damage_Main = 1;
		if (damage_Buffer < 1)
		{
			IncapPassingSurvivor(client, attacker, damage, damageType, weapon);
			damage_Main = 0;
		}
		else if (canTakeDamage)
		{ SetEntPropFloat(client, Prop_Send, "m_healthBuffer", damage_Buffer*1.0); }
	}
	
	if (damage_Main > 0 && canTakeDamage)
	{ SetEntityHealth(client, damage_Main); }
	
	int new_healthBuffer = RoundToCeil(GetEntPropFloat(client, Prop_Send, "m_healthBuffer"));
	if (g_bDebug)
	{
		PrintToServer("NEW Damage: %i Full Health: %i Health: %i Health Buffer: %i",
		rounded_Damage, damage_Main + new_healthBuffer, damage_Main, new_healthBuffer);
	}
	
	static char temp_str[15];
	GetEntityClassname(inflictor, temp_str, sizeof(temp_str));
	
	//PrintToServer("%i", damageType);
	//PrintToServer("%i", GetEntProp(client, Prop_Send, "m_vocalizationSubject"));
	int is_Incapped = GetEntProp(client, Prop_Send, "m_isIncapacitated");
	if (damageType & 263168 || strncmp(temp_str, "insect_swarm", 12, false) == 0)
	{
		/*Format(temp_str, sizeof(temp_str), "%s_%i", SWARM_TARG_NAME, inflictor);
		int targ_ent = FindEntityByTargetname(-1, temp_str);
		if (!RealValidEntity(targ_ent))
		{
			targ_ent = CreateEntityByName("info_infected_zoo_puppet");
			
			float origin[3];
			GetEntPropVector(inflictor, Prop_Data, "m_vecOrigin", origin);
			
			TeleportEntity(inflictor, origin, NULL_VECTOR, NULL_VECTOR);
			
			DispatchSpawn(targ_ent);
			ActivateEntity(targ_ent);
			
			DispatchKeyValue(targ_ent, "targetname", temp_str);
			
			SetVariantString("!activator");
			AcceptEntityInput(targ_ent, "SetParent", inflictor);
		}*/
		
		SetVariantString("GooedBySpitter");
		AcceptEntityInput(client, "SpeakResponseConcept");
		
		//Logic_RunScript("Msg(EntIndexToHScript(%i))", EntRefToEntIndex(targ_ent));
		//Logic_RunScript(COMMANDABOT_REACT_TO_ENT, BOT_CMD_RETREAT, GetClientUserId(client), EntRefToEntIndex(targ_ent));
		
		static char name_str[64];
		GetSurvivorSceneName(client, false, name_str, sizeof(name_str));
		Format(name_str, sizeof(name_str), "SaidGooedBySpitter:1:20,Talk%s:1:3", name_str);
		SetVariantString(name_str);
		AcceptEntityInput(client, "AddContext");
	}
	else if (IsValidClient(GetEntPropEnt(client, Prop_Send, "m_pounceAttacker")))
	{
		SetVariantString("ScreamWhilePounced");
		AcceptEntityInput(client, "SpeakResponseConcept");
	}
	else if (RealValidEntity(attacker) && g_fPainDelay[client] <= game_time)
	{
		SetVariantString("Team:Survivor:0.05");
		AcceptEntityInput(client, "AddContext");
		
		if (is_Incapped)
		{ SetVariantString("PainLevel:Incapacitated:0.5"); }
		else if (damage >= 34)
		{ SetVariantString("PainLevel:Critical:0.5"); g_fPainDelay[client] = game_time+2.0; }
		else if (damage >= 16)
		{ SetVariantString("PainLevel:Major:0.5"); g_fPainDelay[client] = game_time+2.0; }
		else
		{ SetVariantString("PainLevel:Minor:0.5"); g_fPainDelay[client] = game_time+2.0; }
		AcceptEntityInput(client, "AddContext");
		SetVariantString("Pain");
		AcceptEntityInput(client, "SpeakResponseConcept");
	}
	//static char temp[128];
	//GetEntPropString(client, Prop_Data, "m_ResponseContexts", temp, sizeof(temp));
	//PrintToServer(temp);
	//PrintToServer("%i", GetEntProp(client, Prop_Data, "m_ResponseContexts"));
	
	int userid = GetClientUserId(client);
	Event hurt_event = CreateEvent("player_hurt");
	hurt_event.SetInt("userid", userid);
	hurt_event.SetInt("attacker", event_attacker);
	hurt_event.SetInt("attackerentid", event_attackerent);
	hurt_event.SetInt("health", GetClientHealth(client));
	hurt_event.SetInt("armor", new_healthBuffer);
	hurt_event.SetString("weapon", event_weapon);
	hurt_event.SetInt("dmg_health", rounded_Damage - damage_Main);
	hurt_event.SetInt("dmg_armor", (rounded_Damage - damage_Main) - damage_Buffer);
	hurt_event.SetInt("type", damageType);
	hurt_event.Fire();
	
	Event concise_hurt_event = CreateEvent("player_hurt_concise");
	concise_hurt_event.SetInt("userid", userid);
	concise_hurt_event.SetInt("attackerentid", event_attackerent);
	concise_hurt_event.SetInt("type", damageType);
	concise_hurt_event.SetInt("dmg_health", rounded_Damage);
	concise_hurt_event.Fire();
	
	/*Handle splatter_usermsg = StartMessageAll("Splatter");
	
	EndMessage();*/
	
	//PrintToServer("Damage: %f Health: %i", damage, health);
}

bool IncapPassingSurvivor(int client, int attacker, float damage, int damageType, int weapon)
{
	if (!IsValidClient(client) || !IsPassingSurvivor(client) || !IsPlayerAlive(client)) return false;
	
	int is_Incapped = GetEntProp(client, Prop_Send, "m_isIncapacitated");
	int is_Hanging = GetEntProp(client, Prop_Send, "m_isHangingFromLedge");
	int is_LedgeFalling = GetEntProp(client, Prop_Send, "m_isFallingFromLedge");
	int max_Incaps = GetConVarInt(FindConVar("survivor_max_incapacitated_count"));
	int revive_Count = GetEntProp(client, Prop_Send, "m_currentReviveCount");
	
	if (is_Hanging)
	{
		SetEntProp(client, Prop_Send, "m_isIncapacitated", 0);
		SetEntProp(client, Prop_Send, "m_isHangingFromLedge", 0);
		SetEntProp(client, Prop_Send, "m_isFallingFromLedge", 1);
	}
	else if (revive_Count >= max_Incaps || is_LedgeFalling || max_Incaps <= 0 || is_Incapped || (damageType & DMG_FALL && damage > 100))
	{
		if (g_DamageData[client] && g_DamageData[client] != null)
		{ CloseHandle(g_DamageData[client]); g_DamageData[client] = null; }
		g_DamageData[client] = CreateDataPack();
		WritePackCell(g_DamageData[client], RealValidEntity(attacker) ? attacker : -1);
		WritePackCell(g_DamageData[client], damageType);
		WritePackCell(g_DamageData[client], RealValidEntity(weapon) ? weapon : -1);
		ForcePlayerSuicide(client);
	}
	else if (!is_Incapped)
	{
		int event_attacker = IsValidClient(attacker) ? GetClientUserId(attacker) : -1;
		int event_attackerent = RealValidEntity(attacker) ? EntRefToEntIndex(attacker) : -1;
		static char event_weapon[64] = "world"; event_weapon[0] = '\0';
		if (RealValidEntity(weapon))
		{
			GetEntityClassname(weapon, event_weapon, sizeof(event_weapon));
		}
		
		int userid = GetClientUserId(client);
		Event start_incap_event = CreateEvent("player_incapacitated_start");
		start_incap_event.SetInt("userid", userid);
		start_incap_event.SetInt("attacker", event_attacker);
		start_incap_event.SetInt("attackerentid", event_attackerent);
		start_incap_event.SetString("weapon", event_weapon);
		start_incap_event.SetInt("type", damageType);
		start_incap_event.Fire();
		
		SetEntProp(client, Prop_Send, "m_isIncapacitated", 1);
		SetEntityHealth(client, 300);
		if (HasEntProp(client, Prop_Send, "m_reviveTarget"))
		{
			int revive_Target = GetEntPropEnt(client, Prop_Send, "m_reviveTarget");
			if (IsValidClient(revive_Target))
			{
				SetEntProp(client, Prop_Send, "m_reviveTarget", -1);
				SetEntProp(revive_Target, Prop_Send, "m_reviveOwner", -1);
				//Handle revive_end_event = CreateEvent("revive_end");
			}
		}
		int slot1 = GetPlayerWeaponSlot(client, 1); // get secondary slot
		if (slot1 != -1)
		{
			static char className[17];
			GetEntityClassname(slot1, className, sizeof(className));
			if (className[0] == 'w' && 
			(strcmp(className, "weapon_melee", false) == 0 ||
			strcmp(className, "weapon_chainsaw", false) == 0))
			{
				/*for (int j = 0; j <= 12; j++)
				{
					int myWeapon = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", j);
					if (myWeapon == slot1)
					{
						//SetEntProp(client, Prop_Send, "m_hMyWeapons", -1, j);;
						GiveWeapon(client, "weapon_pistol");
						break;
					}
				}*/
				g_iStoredMelee[client] = EntIndexToEntRef(slot1);
				RemovePlayerItem(client, slot1);
				GiveWeapon(client, "weapon_pistol");
			}
		}
		else
		{ GiveWeapon(client, "weapon_pistol"); }
		
		Event incap_event = CreateEvent("player_incapacitated");
		incap_event.SetInt("userid", userid);
		incap_event.SetInt("attacker", event_attacker);
		incap_event.SetInt("attackerentid", event_attackerent);
		incap_event.SetString("weapon", event_weapon);
		incap_event.SetInt("type", damageType);
		incap_event.Fire();
		
		SetVariantString("PlayerIncapacitated");
		AcceptEntityInput(client, "SpeakResponseConcept");
	}
	return true;
}
// TakeDamage End

stock void GiveWeapon(int client, const char[] wep_class)
{
	int new_weapon = CreateEntityByName(wep_class);
	if (new_weapon == -1) return;
	
	float cl_origin[3];
	GetClientEyePosition(client, cl_origin);
	
	DispatchKeyValueVector(new_weapon, "origin", cl_origin);
	
	DispatchSpawn(new_weapon);
	ActivateEntity(new_weapon);
	
	AcceptEntityInput(new_weapon, "Use", client, new_weapon);
}

// Event Hooks
void player_spawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid", 0));
	if (client == 0 || !IsPassingSurvivor(client) || !IsFakeClient(client)) return;
	
	if (g_iStoredMelee[client] != 0)
	{
		int storedMelee = EntRefToEntIndex(g_iStoredMelee[client]);
		if (storedMelee != -1)
		{
			RegainMelee(client, storedMelee);
		}
	}
}

void player_first_spawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid", 0));
	if (client == 0) return;
	HookDamage(client);
}

void revive_success(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("subject", 0));
	if (client == 0 || g_iStoredMelee[client] == 0) return;
	
	int storedMelee = EntRefToEntIndex(g_iStoredMelee[client]);
	if (storedMelee == -1)
	{
		g_iStoredMelee[client] = 0;
		return;
	}
	
	RegainMelee(client, storedMelee);
}

void RegainMelee(int client, int storedMelee)
{
	int slot1 = GetPlayerWeaponSlot(client, 1); // get secondary slot
	if (slot1 != -1)
	{
		RemovePlayerItem(client, slot1);
		AcceptEntityInput(slot1, "Kill");
	}
	
	/*for (int j = 0; j <= 55; j++)
	{
		int myWeapon = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", j);
		if (myWeapon != -1) continue;
		
		SetEntPropEnt(client, Prop_Send, "m_hMyWeapons", storedMelee, j);
		break;
	}*/
	EquipPlayerWeapon(client, storedMelee);
	g_iStoredMelee[client] = 0;
}

void player_death(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid", 0));
	if (client == 0 || !IsPassingSurvivor(client) || !IsFakeClient(client) || g_DamageData[client] == null) return;
	
	ResetPack(g_DamageData[client], false);
	int attacker = ReadPackCell(g_DamageData[client]);
	int damageType = ReadPackCell(g_DamageData[client]);
	int weapon = ReadPackCell(g_DamageData[client]);
	CloseHandle(g_DamageData[client]);
	g_DamageData[client] = null;
	//PrintToServer("attacker: %i damageType: %i weapon: %i", attacker, damageType, weapon);
	int event_attacker = IsValidClient(attacker) ? GetClientUserId(attacker) : -1;
	int event_attackerent = RealValidEntity(attacker) ? EntRefToEntIndex(attacker) : -1;
	
	char event_weapon[64] = "world";
	if (RealValidEntity(weapon))
	{ GetEntityClassname(weapon, event_weapon, sizeof(event_weapon)); }
	
	char event_attackername[MAX_NAME_LENGTH] = "";
	bool event_attackerisbot = false;
	if (IsValidClient(attacker))
	{
		GetClientName(attacker, event_attackername, sizeof(event_attackername));
		if (IsFakeClient(attacker))
		{ event_attackerisbot = true; }
	}
	
	SetEventInt(event, "attacker", event_attacker);
	SetEventString(event, "attackername", event_attackername);
	SetEventInt(event, "attackerentid", event_attackerent);
	SetEventString(event, "weapon", event_weapon);
	SetEventBool(event, "attackerisbot", event_attackerisbot);
	SetEventInt(event, "type", damageType);
}
// Event Hooks End

void GetSurvivorSceneName(int client, bool is_victim = false, char[] str, int maxlength)
{
	if (!IsValidClient(client)) return;
	
	static char cl_model[42];
	GetClientModel(client, cl_model, sizeof(cl_model));
	//PrintToServer("%s", cl_model);
	if (strcmp(cl_model, "models/survivors/survivor_gambler.mdl", false) == 0)
	{ is_victim ? strcopy(str, maxlength, "nick") : strcopy(str, maxlength, "gambler"); }
	else if (strcmp(cl_model, "models/survivors/survivor_producer.mdl", false) == 0)
	{ is_victim ? strcopy(str, maxlength, "rochelle") : strcopy(str, maxlength, "producer"); }
	else if (strcmp(cl_model, "models/survivors/survivor_coach.mdl", false) == 0)
	{ is_victim ? strcopy(str, maxlength, "coach") : strcopy(str, maxlength, "coach"); }
	else if (strcmp(cl_model, "models/survivors/survivor_mechanic.mdl", false) == 0)
	{ is_victim ? strcopy(str, maxlength, "ellis") : strcopy(str, maxlength, "mechanic"); }
	else if (strcmp(cl_model, "models/survivors/survivor_namvet.mdl", false) == 0)
	{ is_victim ? strcopy(str, maxlength, "bill") : strcopy(str, maxlength, "namvet"); }
	else if (strcmp(cl_model, "models/survivors/survivor_teenangst.mdl", false) == 0)
	{ is_victim ? strcopy(str, maxlength, "zoey") : strcopy(str, maxlength, "teengirl"); }
	else if (strcmp(cl_model, "models/survivors/survivor_biker.mdl", false) == 0)
	{ is_victim ? strcopy(str, maxlength, "francis") : strcopy(str, maxlength, "biker"); }
	else if (strcmp(cl_model, "models/survivors/survivor_manager.mdl", false) == 0)
	{ is_victim ? strcopy(str, maxlength, "louis") : strcopy(str, maxlength, "manager"); }
}

/*#define PLUGIN_SCRIPTLOGIC "plugin_scripting_logic_entity"

void Logic_RunScript(const char[] sCode, any ...) 
{
	int iScriptLogic = FindEntityByTargetname(-1, PLUGIN_SCRIPTLOGIC);
	if (!RealValidEntity(iScriptLogic))
	{
		iScriptLogic = CreateEntityByName("logic_script");
		DispatchKeyValue(iScriptLogic, "targetname", PLUGIN_SCRIPTLOGIC);
		DispatchSpawn(iScriptLogic);
	}
	
	static char sBuffer[512]; 
	VFormat(sBuffer, sizeof(sBuffer), sCode, 2); 
	
	SetVariantString(sBuffer); 
	AcceptEntityInput(iScriptLogic, "RunScriptCode");
}

int FindEntityByTargetname(int index, const char[] findname)
{
	for (int i = index; i < GetMaxEntities(); i++) {
		if (!RealValidEntity(i)) continue;
		static char name[128];
		GetEntPropString(i, Prop_Data, "m_iName", name, sizeof(name));
		if (strcmp(name, findname, false) != 0) continue;
		return i;
	}
	return -1;
}*/

stock bool RealValidEntity(int entity)
{ return (entity > 0 && IsValidEntity(entity)); }

stock bool IsValidClient(int client, bool replaycheck = true, bool isLoop = false)
{
	if ((isLoop || client > 0 && client <= MaxClients) && IsClientInGame(client))
	{
		if (HasEntProp(client, Prop_Send, "m_bIsCoaching")) // TF2, CSGO?
			if (view_as<bool>(GetEntProp(client, Prop_Send, "m_bIsCoaching"))) return false;
		if (replaycheck)
		{
			if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
		}
		return true;
	}
	return false;
}

stock bool IsPassingSurvivor(int client)
{ return (GetClientTeam(client) == 4); }

/*stock bool IsInfected(int client)
{
	if (!IsValidClient(client)) return false;
	if (GetClientTeam(client) == 3) return true;
	return false;
}*/