#define PLUGIN_NAME "[L4D2] Scene Adjustments"
#define PLUGIN_AUTHOR "Shadowysn"
#define PLUGIN_DESC "Re-adds some quotes as well as fixing friendly fire lines for 5+ survivors."
#define PLUGIN_VERSION "1.1.5"
#define PLUGIN_URL "https://forums.alliedmods.net/showthread.php?p=2681697"
#define PLUGIN_NAME_SHORT "Scene Adjustments"
#define PLUGIN_NAME_TECH "l4d_sceneadjust"

#define DEBUG 0

#pragma semicolon 1
#include <sourcemod>
//#include <sceneprocessor>
#include <sdktools>
#include <sdkhooks>

#pragma newdecls required
#pragma semicolon 1

//static bool pounced[MAXPLAYERS+1] = false; // Hunter pounce zoeyfix/oof //
//static bool hasMourned[MAXPLAYERS+1] = false; // L4D1 passing survivor mourn fix //
static bool canMourn[MAXPLAYERS+1] = false; // L4D1 passing survivor mourn fix //
static float g_vecLastLivingOrigin[3][MAXPLAYERS+1]; // L4D1 passing survivor mourn fix //
static int targetClient[MAXPLAYERS+1] = INVALID_ENT_REFERENCE; // L4D1 passing survivor mourn fix //

static float friendlyFire_Time[MAXPLAYERS+1] = 0.0; // Friendly Fire fix //
static bool hasFriendlyFired = false; // Friendly Fire fix //
#define FRIENDLYFIRE_DELAY 10.0 // Friendly Fire fix //

ConVar version_cvar;

public Plugin myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESC,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}

static bool g_isSequel = false;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() == Engine_Left4Dead2)
	{
		g_isSequel = true;
		return APLRes_Success;
	}
	else if (GetEngineVersion() == Engine_Left4Dead)
	{
		g_isSequel = false;
		return APLRes_Success;
	}
	strcopy(error, err_max, "Plugin only supports Left 4 Dead and Left 4 Dead 2.");
	return APLRes_SilentFailure;
}

//ConVar Scene_ZoeyPounced;
ConVar Scene_OofSounds;
ConVar Scene_FriendlyFire;
ConVar Scene_L4D1Mourn;

public void OnPluginStart()
{
	char cvar_desc_str[500];
	Format(cvar_desc_str, sizeof(cvar_desc_str), "%s plugin version.", PLUGIN_NAME_SHORT);
	version_cvar = CreateConVar("sm_l4d_sceneadjust_ver", PLUGIN_VERSION, cvar_desc_str, 0|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if (version_cvar != null)
		SetConVarString(version_cvar, PLUGIN_VERSION);
	
	char cvar_str[128];
	
	if (g_isSequel)
	{
		//Format(cvar_str, sizeof(cvar_str), "sm_%s_zoey_pounce", PLUGIN_NAME_TECH);
		//Format(cvar_desc_str, sizeof(cvar_desc_str), "Should %s fix Zoey's lines while pounced?", PLUGIN_NAME_SHORT);
		//Scene_ZoeyPounced = CreateConVar(cvar_str, "1", cvar_desc_str, FCVAR_ARCHIVE, true, 0.0, true, 1.0);
		
		Format(cvar_str, sizeof(cvar_str), "sm_%s_oof", PLUGIN_NAME_TECH);
		Format(cvar_desc_str, sizeof(cvar_desc_str), "Should %s make Survivors play their minor hurt sounds upon getting pounced/charged?", PLUGIN_NAME_SHORT);
		Scene_OofSounds = CreateConVar(cvar_str, "1", cvar_desc_str, FCVAR_ARCHIVE, true, 0.0, true, 1.0);
	
		Format(cvar_str, sizeof(cvar_str), "sm_%s_l4d1mourn", PLUGIN_NAME_TECH);
		Format(cvar_desc_str, sizeof(cvar_desc_str), "Should %s fix the L4D1 survivors on L4D2 set not mourning their own group?", PLUGIN_NAME_SHORT);
		Scene_L4D1Mourn = CreateConVar(cvar_str, "1", cvar_desc_str, FCVAR_ARCHIVE, true, 0.0, true, 1.0);
	}
	else
	{
		//delete Scene_ZoeyPounced;
		delete Scene_OofSounds;
		delete Scene_L4D1Mourn;
	}
	
	Format(cvar_str, sizeof(cvar_str), "sm_%s_friendlyfire", PLUGIN_NAME_TECH);
	Format(cvar_desc_str, sizeof(cvar_desc_str), "Should %s fix friendly fire quotes not playing for 5+ survivors?", PLUGIN_NAME_SHORT);
	Scene_FriendlyFire = CreateConVar(cvar_str, "1", cvar_desc_str, FCVAR_ARCHIVE, true, 0.0, true, 1.0);
	
	if (g_isSequel)
	{
		HookEvent("lunge_pounce", lunge_pounce); // Hunter pounce zoeyfix/oof //
		//HookEvent("pounce_end", pounce_end); // Hunter pounce zoeyfix/oof //
		HookEvent("charger_carry_start", charger_carry_start); // Charger Oof sound //
		//HookEvent("player_spawn", player_spawn);
		HookEvent("player_death", player_death);
		//HookEvent("player_shoved", player_shoved);
		CreateTimer(1.0, TimerUpdate_Mourn, _, TIMER_REPEAT); // L4D1 passing survivor mourn fix //
	}
	HookEvent("player_hurt", player_hurt, EventHookMode_Post); // Friendly Fire fix //
	HookEvent("friendly_fire", friendly_fire, EventHookMode_Pre); // Friendly Fire fix //
	
	AutoExecConfig(true, "l4d_sceneadjust");
}

public void OnPluginEnd()
{
	if (g_isSequel)
	{
		//UnhookEvent("lunge_pounce", lunge_pounce);
		//UnhookEvent("pounce_end", pounce_end);
		UnhookEvent("charger_carry_start", charger_carry_start);
		//UnhookEvent("player_spawn", player_spawn);
		UnhookEvent("player_death", player_death);
		//UnhookEvent("player_shoved", player_shoved);
	}
	
	UnhookEvent("player_hurt", player_hurt, EventHookMode_Post);
	UnhookEvent("friendly_fire", friendly_fire, EventHookMode_Pre);
}

// L4D1 passing survivor mourn fix //
Action TimerUpdate_Mourn(Handle timer)
{
	if (!IsServerProcessing()) return;
	
	if (Scene_L4D1Mourn == null || !GetConVarBool(Scene_L4D1Mourn)) return;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && IsPlayerAlive(i))
		{
			int is_Incap = GetEntProp(i, Prop_Send, "m_isIncapacitated");
			//if (IsClientL4D1Survivor(i) && !is_Incap && !hasMourned[i])
			if (IsClientL4D1Survivor(i) && !is_Incap)
			{
				for (int loopclient = 1; loopclient <= MaxClients; loopclient++)
				{
					if (!IsValidClient(loopclient)) continue;
					if (!IsSurvivor(loopclient) || !IsClientL4D1Survivor(loopclient) || IsPlayerAlive(loopclient)) continue;
					if (IsValidClient(targetClient[i]) && targetClient[i] == loopclient) continue;
					int character = GetEntProp(i, Prop_Send, "m_survivorCharacter");
					int loopchar = GetEntProp(loopclient, Prop_Send, "m_survivorCharacter");
					char weapon_name[128];
					GetClientWeapon(loopclient, weapon_name, sizeof(weapon_name));
					if (character == loopchar || StrEqual(weapon_name, "weapon_defibrillator", false)) continue;
					float client_pos[3];
					float other_pos[3];
					other_pos[0] = g_vecLastLivingOrigin[0][loopclient];
					other_pos[1] = g_vecLastLivingOrigin[1][loopclient];
					other_pos[2] = g_vecLastLivingOrigin[2][loopclient];
					
					//if (!HasEntProp(loopclient, Prop_Data, "m_vecAbsOrigin")) continue;
					if (other_pos[0] == 0.0 && other_pos[1] == 0.0 && other_pos[2] == 0.0) continue;
					
					GetClientAbsOrigin(i, client_pos);
					
					float distance = GetVectorDistance(client_pos, other_pos);
					if (distance <= 50.0 && canMourn[i])
					//if (distance <= 50.0 && canMourn[i])
					{
						canMourn[i] = false;
						SurvivorMourn(i, loopclient);
						targetClient[i] = loopclient;
						break;
					}
					else if (distance > 200.0 && !canMourn[i])
					{
						canMourn[i] = true;
						//targetClient[i] = INVALID_ENT_REFERENCE;
						break;
					}
				}
			}
		}
	}
}

void SurvivorMourn(int client, int victim)
{
	//char client_namestr[PLATFORM_MAX_PATH];
	char victim_namestr[PLATFORM_MAX_PATH];
	//GetSurvivorSceneName(client, false, client_namestr, sizeof(client_namestr));
	GetSurvivorSceneName(victim, false, victim_namestr, sizeof(victim_namestr));
	
	char temp_str[128];
	//int worldspawn = 0;
	
	Format(temp_str, sizeof(temp_str), "DeadCharacter:%s:0.1", victim_namestr);
	SetVariantString(temp_str);
	AcceptEntityInput(client, "AddContext");
	//hasMourned[client] = true;
	//SetVariantString("SaidSomeoneDied:1:10");
	//AcceptEntityInput(worldspawn, "AddContext");
	SetVariantString("PlayerSeeDeadPlayer");
	AcceptEntityInput(client, "SpeakResponseConcept");
}

void player_death(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsValidClient(client) && !IsPlayerAlive(client) && IsSurvivor(client))
	{
		//hasMourned[client] = false;
		if (IsClientL4D1Survivor(client))
		{
			float other_pos[3];
			GetClientAbsOrigin(client, other_pos);
			g_vecLastLivingOrigin[0][client] = other_pos[0];
			g_vecLastLivingOrigin[1][client] = other_pos[1];
			g_vecLastLivingOrigin[2][client] = other_pos[2];
			/*for (int loopclient = 1; loopclient <= MaxClients; loopclient++)
			{
				if (!IsValidClient(loopclient)) continue;
				if (!IsSurvivor(loopclient)) continue;
				//hasMourned[loopclient] = false;
			}*/
		}
	}
}
// L4D1 passing survivor mourn fix end //

// Hunter pounce zoeyfix/oof //
void lunge_pounce(Handle event, const char[] name, bool dontBroadcast)
{
	#if DEBUG
	PrintToChatAll("Lunge pounce!");
	#endif
	int client = GetClientOfUserId(GetEventInt(event, "victim"));
	//if (IsZoey(client) && IsValidEntity(GetEntPropEnt(client, Prop_Send, "m_pounceAttacker")))
	if (IsSurvivor(client) && IsPlayerAlive(client) && Scene_OofSounds != null && GetConVarBool(Scene_OofSounds))
	{
		SetVariantString("PainLevel:Minor:0.5");
		AcceptEntityInput(client, "AddContext");
		SetVariantString("Pain");
		AcceptEntityInput(client, "SpeakResponseConcept");
	}
	
	/*if (IsZoey(client) && IsPlayerAlive(client) && !pounced[client] && 
	Scene_ZoeyPounced != null && GetConVarBool(Scene_ZoeyPounced))
	{
		pounced[client] = true;
		CreateTimer(2.0, ScreamThink, client, TIMER_REPEAT && TIMER_FLAG_NO_MAPCHANGE);
		SetVariantString("PainLevel:None");
		AcceptEntityInput(client, "AddContext");
	}*/
}

/*void pounce_end(Handle event, const char[] name, bool dontBroadcast)
{
	#if DEBUG
	PrintToChatAll("Pounce end!");
	#endif
	int client = GetClientOfUserId(GetEventInt(event, "victim"));
	//if (IsZoey(client) && !IsValidEntity(GetEntPropEnt(client, Prop_Send, "m_pounceAttacker")))
	if (IsZoey(client) && pounced[client])
	{ pounced[client] = false; }
}

Action ScreamThink(Handle timer, int client)
{
	if (!IsServerProcessing()) return;
	if (IsSurvivor(client) && IsPlayerAlive(client) && pounced[client] && 
	Scene_ZoeyPounced != null && GetConVarBool(Scene_ZoeyPounced))
	{
		#if DEBUG
		PrintToChatAll("Being pounced!");
		#endif
		switch (GetRandomInt(1, 4))
		{
			//case 1:PerformScene(client, "", "scenes/teengirl/screamwhilepounced01.vcd");
			case 1:PlayScene(client, "scenes/teengirl/screamwhilepounced01.vcd");
			case 2:PlayScene(client, "scenes/teengirl/screamwhilepounced02.vcd");
			case 3:PlayScene(client, "scenes/teengirl/screamwhilepounced04.vcd");
			case 4:PlayScene(client, "scenes/teengirl/screamwhilepounced06.vcd");
			default:return;
		}
	}
	else
	{
		SetVariantString("PainLevel:None:0.01");
		AcceptEntityInput(client, "AddContext");
		KillTimer(timer);
	}
}*/

/*void PlayScene(int client, const char[] str)
{
	int scene = CreateEntityByName("instanced_scripted_scene");
	DispatchKeyValue(scene, "SceneFile", str);
	SetEntPropEnt(scene, Prop_Data, "m_hActor", client);
	DispatchKeyValue(scene, "busyactor", "0");
	DispatchSpawn(scene);
	ActivateEntity(scene);
	AcceptEntityInput(scene, "Start");
}*/
// Hunter pounce zoeyfix/oof end //

// Charger Oof sound //
void charger_carry_start(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "victim"));
	if (IsSurvivor(client) && IsPlayerAlive(client) && Scene_OofSounds != null && GetConVarBool(Scene_OofSounds))
	{
		SetVariantString("PainLevel:Minor:0.5");
		AcceptEntityInput(client, "AddContext");
		SetVariantString("Pain");
		AcceptEntityInput(client, "SpeakResponseConcept");
	}
}
// Charger Oof sound end //

/*void player_shoved(Handle event, const char[] name, bool dontBroadcast)
{
	#if DEBUG
	PrintToChatAll("Shoved1!");
	#endif
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	//int client = GetClientOfUserId(GetEventInt(event, "entityid"));
	//int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		#if DEBUG
		PrintToChatAll("Shoved!");
		#endif
	}
}*/

// Friendly Fire fix //
void friendly_fire(Handle event, const char[] name, bool dontBroadcast)
{
	if (Scene_FriendlyFire == null || !GetConVarBool(Scene_FriendlyFire)) return;
	
	int client = GetClientOfUserId(GetEventInt(event, "victim"));
	if (!IsSurvivor(client)) return;
	
	float game_Time = GetGameTime();
	if (friendlyFire_Time[client] > game_Time) return;
	
	friendlyFire_Time[client] = game_Time+FRIENDLYFIRE_DELAY;
}

void player_hurt(Event event, const char[] name, bool dontBroadcast)
{
	if (Scene_FriendlyFire == null || !GetConVarBool(Scene_FriendlyFire)) return;
	
	if (hasFriendlyFired) return;
	
	int clientID = GetEventInt(event, "userid");
	int client = GetClientOfUserId(clientID);
	//if (!IsSurvivor(client) || !IsExtraSurvivor(client)) return;
	if (!IsSurvivor(client)) return;
	
	float game_Time = GetGameTime();
	if (friendlyFire_Time[client] > game_Time) return;
	
	int attackerID = GetEventInt(event, "attacker");
	int attacker = GetClientOfUserId(attackerID);
	if (!IsSurvivor(attacker) || attacker == client) return;
	
	int type = GetEventInt(event, "type");
	if (!(type & DMG_BULLET) && !(type & DMG_BLAST) && !(type & DMG_CLUB) && !(type & DMG_SLASH))
	return;
	
	friendlyFire_Time[client] = game_Time+FRIENDLYFIRE_DELAY;
	
	Handle friendly_fire_ev = CreateEvent("friendly_fire");
	SetEventInt(friendly_fire_ev, "attacker", GetClientUserId(attacker));
	SetEventInt(friendly_fire_ev, "victim", GetClientUserId(client));
	SetEventInt(friendly_fire_ev, "guilty", GetClientUserId(attacker));
	SetEventInt(friendly_fire_ev, "type", type);
	FireEvent(friendly_fire_ev);
	
	Handle award_earned = CreateEvent("award_earned");
	SetEventInt(award_earned, "userid", GetClientUserId(client));
	SetEventInt(award_earned, "entityid", EntRefToEntIndex(client));
	SetEventInt(award_earned, "subjectentid", EntRefToEntIndex(attacker));
	SetEventInt(award_earned, "award", 87);
	FireEvent(award_earned);
	
	char name_str[32];
	GetSurvivorSceneName(attacker, false, name_str, sizeof(name_str));
	
	//if (RecognizesOther(client, attacker))
	//{
	char temp_str[128];
	//Format(temp_str, sizeof(temp_str), "%sFriendlyFire:1:10", name_str);
	Format(temp_str, sizeof(temp_str), "Subject:%s:0.6", name_str);
	SetVariantString(temp_str);
	AcceptEntityInput(client, "AddContext");
	//}
	
	hasFriendlyFired = true;
	CreateTimer(0.5, Timer_FFResponse, client, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.0, Timer_hasFriendlyFired, -1, TIMER_FLAG_NO_MAPCHANGE);
}

Action Timer_FFResponse(Handle timer, int client)
{
	if (!IsSurvivor(client)) return;
	
	SetVariantString("PlayerFriendlyFire");
	AcceptEntityInput(client, "SpeakResponseConcept");
}

Action Timer_hasFriendlyFired(Handle timer)
{
	hasFriendlyFired = false;
}
// Friendly Fire fix end //

void GetSurvivorSceneName(int client, bool is_victim = false, char[] str, int maxlength)
{
	if (!IsSurvivor(client)) return;
	
	static char cl_model[PLATFORM_MAX_PATH];
	GetClientModel(client, cl_model, sizeof(cl_model));
	//PrintToChatAll("%s", cl_model);
	if (StrEqual(cl_model, "models/survivors/survivor_gambler.mdl", false))
	{ is_victim ? strcopy(str, maxlength, "nick") : strcopy(str, maxlength, "Gambler"); }
	else if (StrEqual(cl_model, "models/survivors/survivor_producer.mdl", false))
	{ is_victim ? strcopy(str, maxlength, "rochelle") : strcopy(str, maxlength, "Producer"); }
	else if (StrEqual(cl_model, "models/survivors/survivor_coach.mdl", false))
	{ is_victim ? strcopy(str, maxlength, "coach") : strcopy(str, maxlength, "Coach"); }
	else if (StrEqual(cl_model, "models/survivors/survivor_mechanic.mdl", false))
	{ is_victim ? strcopy(str, maxlength, "ellis") : strcopy(str, maxlength, "Mechanic"); }
	else if (StrEqual(cl_model, "models/survivors/survivor_namvet.mdl", false))
	{ is_victim ? strcopy(str, maxlength, "bill") : strcopy(str, maxlength, "NamVet"); }
	else if (StrEqual(cl_model, "models/survivors/survivor_teenangst.mdl", false))
	{ is_victim ? strcopy(str, maxlength, "zoey") : strcopy(str, maxlength, "TeenGirl"); }
	else if (StrEqual(cl_model, "models/survivors/survivor_biker.mdl", false))
	{ is_victim ? strcopy(str, maxlength, "francis") : strcopy(str, maxlength, "Biker"); }
	else if (StrEqual(cl_model, "models/survivors/survivor_manager.mdl", false))
	{ is_victim ? strcopy(str, maxlength, "louis") : strcopy(str, maxlength, "Manager"); }
	else
	{ strcopy(str, maxlength, "Unknown"); }
}

/*bool IsZoey(int client)
{
	char cl_model[PLATFORM_MAX_PATH];
	if (IsValidClient(client))
	{ GetClientModel(client, cl_model, sizeof(cl_model)); }
	if (IsValidClient(client) && IsSurvivor(client) && (
	GetEntProp(client, Prop_Send, "m_survivorCharacter") == 5 || // For Zoey in The Passing set
	GetEntProp(client, Prop_Send, "m_survivorCharacter") == 1 && StrEqual(cl_model,"models/survivors/survivor_teenangst.mdl", false) ) ) // For Zoey in the L4D1 survivor set
	{
		return true;
	}
	return false;
}*/

/*bool RecognizesOther(int client, int other)
{
	if (!IsSurvivor(client) || !IsSurvivor(other)) return false;
	
	switch (IsClientL4D1Survivor(client))
	{
		case 1: // true
		{
			if (IsClientL4D1Survivor(other)) return true;
		}
		case 0: // not true
		{
			if (!IsClientL4D1Survivor(other)) return true;
		}
	}
	return false;
}*/

bool IsSurvivor(int client)
{
	if (!IsValidClient(client)) return false;
	if (GetClientTeam(client) == 2 || GetClientTeam(client) == 4) return true;
	return false;
}

bool IsClientL4D1Survivor(int client)
{
	if (!IsSurvivor(client)) return false;
	int character = GetEntProp(client, Prop_Send, "m_survivorCharacter");
	if (character >= 4 && character <= 7) return true;
	return false;
}

bool IsValidClient(int client, bool replaycheck = true)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	//if (GetEntProp(client, Prop_Send, "m_bIsCoaching")) return false;
	if (replaycheck)
	{
		if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	}
	return true;
}