#define PLUGIN_NAME "[L4D1?/2] 5+ Survivor Friendly Fire Quote Fix"
#define PLUGIN_AUTHOR "Shadowysn"
#define PLUGIN_DESC "Mainly fixes friendly fire lines for 5+ survivors."
#define PLUGIN_VERSION "1.1.5d"
#define PLUGIN_URL "https://forums.alliedmods.net/showthread.php?p=2681697"
#define PLUGIN_NAME_SHORT "Scene Adjustments"
#define PLUGIN_NAME_TECH "l4d_sceneadjust"

#define DEBUG 0

#include <sourcemod>
//#include <sceneprocessor>
#include <sdktools>
#include <sdkhooks>

#pragma newdecls required
#pragma semicolon 1

//static bool pounced[MAXPLAYERS+1] = false; // Hunter pounce zoeyfix/oof //
//static bool hasMourned[MAXPLAYERS+1] = false; // L4D1 passing survivor mourn fix //
bool canMourn[MAXPLAYERS+1] = {false}; // L4D1 passing survivor mourn fix //
float g_vecLastLivingOrigin[3][MAXPLAYERS+1]; // L4D1 passing survivor mourn fix //
int targetClient[MAXPLAYERS+1] = {INVALID_ENT_REFERENCE}; // L4D1 passing survivor mourn fix //

float friendlyFire_Time[MAXPLAYERS+1] = {0.0}; // Friendly Fire fix //
bool hasFriendlyFired = false; // Friendly Fire fix //
#define FRIENDLYFIRE_DELAY 10.0 // Friendly Fire fix //

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
ConVar Scene_OofSounds, Scene_FriendlyFire, Scene_L4D1Mourn;

public void OnPluginStart()
{
	static char desc_str[128];
	Format(desc_str, sizeof(desc_str), "%s version.", PLUGIN_NAME_SHORT);
	static char cmd_str[64];
	Format(cmd_str, sizeof(cmd_str), "sm_%s_version", PLUGIN_NAME_TECH);
	ConVar version_cvar = CreateConVar(cmd_str, PLUGIN_VERSION, desc_str, FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if (version_cvar != null)
		version_cvar.SetString(PLUGIN_VERSION);
	
	if (g_isSequel)
	{
		//Format(cmd_str, sizeof(cmd_str), "sm_%s_zoey_pounce", PLUGIN_NAME_TECH);
		//Format(desc_str, sizeof(desc_str), "Should %s fix Zoey's lines while pounced?", PLUGIN_NAME_SHORT);
		//Scene_ZoeyPounced = CreateConVar(cmd_str, "1", desc_str, FCVAR_ARCHIVE, true, 0.0, true, 1.0);
		
		Format(cmd_str, sizeof(cmd_str), "sm_%s_oof", PLUGIN_NAME_TECH);
		Format(desc_str, sizeof(desc_str), "Should %s make Survivors play their minor hurt sounds upon getting pounced/charged?", PLUGIN_NAME_SHORT);
		Scene_OofSounds = CreateConVar(cmd_str, "1", desc_str, FCVAR_ARCHIVE, true, 0.0, true, 1.0);
	
		Format(cmd_str, sizeof(cmd_str), "sm_%s_l4d1mourn", PLUGIN_NAME_TECH);
		Format(desc_str, sizeof(desc_str), "Should %s fix the L4D1 survivors on L4D2 set not mourning their own group?", PLUGIN_NAME_SHORT);
		Scene_L4D1Mourn = CreateConVar(cmd_str, "0", desc_str, FCVAR_ARCHIVE, true, 0.0, true, 1.0);
	}
	else
	{
		//delete Scene_ZoeyPounced;
		delete Scene_OofSounds;
		delete Scene_L4D1Mourn;
	}
	
	Format(cmd_str, sizeof(cmd_str), "sm_%s_friendlyfire", PLUGIN_NAME_TECH);
	Format(desc_str, sizeof(desc_str), "Should %s fix friendly fire quotes not playing for 5+ survivors?", PLUGIN_NAME_SHORT);
	Scene_FriendlyFire = CreateConVar(cmd_str, "1", desc_str, FCVAR_ARCHIVE, true, 0.0, true, 1.0);
	
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
	if (!IsServerProcessing()) return Plugin_Continue;
	
	if (Scene_L4D1Mourn == null || !GetConVarBool(Scene_L4D1Mourn)) return Plugin_Continue;
	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsValidClient(client) || !IsPlayerAlive(client)) continue;
		
		int is_Incap = GetEntProp(client, Prop_Send, "m_isIncapacitated");
		//if (IsClientL4D1Survivor(client) && !is_Incap && !hasMourned[client])
		if (!IsClientL4D1Survivor(client) || is_Incap) continue;
		
		for (int loopclient = 1; loopclient <= MaxClients; loopclient++)
		{
			if (!IsValidClient(loopclient)) continue;
			if (!IsSurvivor(loopclient) || !IsClientL4D1Survivor(loopclient) || IsPlayerAlive(loopclient)) continue;
			if (IsValidClient(targetClient[client]) && targetClient[client] == loopclient) continue;
			
			int character = GetEntProp(client, Prop_Send, "m_survivorCharacter");
			int loopchar = GetEntProp(loopclient, Prop_Send, "m_survivorCharacter");
			
			static char weapon_name[128];
			GetClientWeapon(loopclient, weapon_name, sizeof(weapon_name));
			if (character == loopchar || strcmp(weapon_name, "weapon_defibrillator", false) == 0) continue;
			float client_pos[3];
			float other_pos[3];
			other_pos[0] = g_vecLastLivingOrigin[0][loopclient];
			other_pos[1] = g_vecLastLivingOrigin[1][loopclient];
			other_pos[2] = g_vecLastLivingOrigin[2][loopclient];
			
			//if (!HasEntProp(loopclient, Prop_Data, "m_vecAbsOrigin")) continue;
			if (other_pos[0] == 0.0 && other_pos[1] == 0.0 && other_pos[2] == 0.0) continue;
			
			GetClientAbsOrigin(client, client_pos);
			
			float distance = GetVectorDistance(client_pos, other_pos);
			if (distance <= 50.0 && canMourn[client])
			//if (distance <= 50.0 && canMourn[client])
			{
				canMourn[client] = false;
				SurvivorMourn(client, loopclient);
				targetClient[client] = loopclient;
				break;
			}
			else if (distance > 200.0 && !canMourn[client])
			{
				canMourn[client] = true;
				//targetClient[client] = INVALID_ENT_REFERENCE;
				break;
			}
		}
	}
	return Plugin_Continue;
}

void SurvivorMourn(int client, int victim)
{
	//char client_namestr[PLATFORM_MAX_PATH];
	static char victim_namestr[32];
	//GetSurvivorSceneName(client, false, client_namestr, sizeof(client_namestr));
	GetSurvivorSceneName(victim, false, victim_namestr, sizeof(victim_namestr));
	
	static char context_str[64];
	//int worldspawn = 0;
	
	Format(context_str, sizeof(context_str), "DeadCharacter:%s:0.1", victim_namestr);
	SetVariantString(context_str);
	AcceptEntityInput(client, "AddContext");
	//hasMourned[client] = true;
	//SetVariantString("SaidSomeoneDied:1:10");
	//AcceptEntityInput(worldspawn, "AddContext");
	SetVariantString("PlayerSeeDeadPlayer");
	AcceptEntityInput(client, "SpeakResponseConcept");
}

void player_death(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid", 0));
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
void lunge_pounce(Event event, const char[] name, bool dontBroadcast)
{
	#if DEBUG
	PrintToChatAll("Lunge pounce!");
	#endif
	int client = GetClientOfUserId(event.GetInt("victim", 0));
	//if (IsZoey(client) && RealValidEntity(GetEntPropEnt(client, Prop_Send, "m_pounceAttacker")))
	if (IsValidClient(client) && IsSurvivor(client) && IsPlayerAlive(client) && 
	Scene_OofSounds != null && GetConVarBool(Scene_OofSounds))
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

/*void pounce_end(Event event, const char[] name, bool dontBroadcast)
{
	#if DEBUG
	PrintToChatAll("Pounce end!");
	#endif
	int client = GetClientOfUserId(event.GetInt("victim", 0));
	//if (IsZoey(client) && !RealValidEntity(GetEntPropEnt(client, Prop_Send, "m_pounceAttacker")))
	if (IsZoey(client) && pounced[client])
	{ pounced[client] = false; }
}

Action ScreamThink(Handle timer, int client)
{
	if (!IsServerProcessing()) return;
	if (IsValidClient(client) && IsSurvivor(client) && IsPlayerAlive(client) && pounced[client] && 
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
void charger_carry_start(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("victim", 0));
	if (IsValidClient(client) && IsSurvivor(client) && IsPlayerAlive(client) && 
	Scene_OofSounds != null && GetConVarBool(Scene_OofSounds))
	{
		SetVariantString("PainLevel:Minor:0.5");
		AcceptEntityInput(client, "AddContext");
		SetVariantString("Pain");
		AcceptEntityInput(client, "SpeakResponseConcept");
	}
}
// Charger Oof sound end //

/*void player_shoved(Event event, const char[] name, bool dontBroadcast)
{
	#if DEBUG
	PrintToChatAll("Shoved1!");
	#endif
	int client = GetClientOfUserId(event.GetInt("userid", 0));
	//int client = GetClientOfUserId(event.GetInt("entityid", 0));
	//int attacker = GetClientOfUserId(event.GetInt("attacker", 0));
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		#if DEBUG
		PrintToChatAll("Shoved!");
		#endif
	}
}*/

// Friendly Fire fix //
void friendly_fire(Event event, const char[] name, bool dontBroadcast)
{
	if (Scene_FriendlyFire == null || !GetConVarBool(Scene_FriendlyFire)) return;
	
	int client = GetClientOfUserId(event.GetInt("victim", 0));
	if (!IsValidClient(client) || !IsSurvivor(client)) return;
	
	float game_Time = GetGameTime();
	if (friendlyFire_Time[client] > game_Time) return;
	
	friendlyFire_Time[client] = game_Time+FRIENDLYFIRE_DELAY;
}

void player_hurt(Event event, const char[] name, bool dontBroadcast)
{
	if (Scene_FriendlyFire == null || !GetConVarBool(Scene_FriendlyFire)) return;
	
	if (hasFriendlyFired) return;
	
	int clientID = event.GetInt("userid", 0);
	int client = GetClientOfUserId(clientID);
	//if (!IsSurvivor(client) || !IsExtraSurvivor(client)) return;
	if (!IsValidClient(client) || !IsSurvivor(client)) return;
	
	float game_Time = GetGameTime();
	if (friendlyFire_Time[client] > game_Time) return;
	
	int attackerID = event.GetInt("attacker", 0);
	int attacker = GetClientOfUserId(attackerID);
	if (!IsValidClient(attacker) || !IsSurvivor(attacker) || attacker == client) return;
	
	int type = event.GetInt("type", 0);
	if (!(type & DMG_BULLET) && !(type & DMG_BLAST) && !(type & DMG_CLUB) && !(type & DMG_SLASH))
	return;
	
	friendlyFire_Time[client] = game_Time+FRIENDLYFIRE_DELAY;
	
	Event ff_ev = CreateEvent("friendly_fire");
	ff_ev.SetInt("attacker", attackerID);
	ff_ev.SetInt("victim", clientID);
	ff_ev.SetInt("guilty", attackerID);
	ff_ev.SetInt("type", type);
	ff_ev.Fire();
	
	Event award_ev = CreateEvent("award_earned");
	award_ev.SetInt("userid", clientID);
	award_ev.SetInt("entityid", client);
	award_ev.SetInt("subjectentid", attacker);
	award_ev.SetInt("award", 87);
	award_ev.Fire();
	
	static char name_str[32];
	GetSurvivorSceneName(attacker, false, name_str, sizeof(name_str));
	
	//if (RecognizesOther(client, attacker))
	//{
	static char context_str[64];
	//Format(context_str, sizeof(context_str), "%sFriendlyFire:1:10", name_str);
	Format(context_str, sizeof(context_str), "Subject:%s:0.6", name_str);
	SetVariantString(context_str);
	AcceptEntityInput(client, "AddContext");
	//}
	
	hasFriendlyFired = true;
	CreateTimer(0.5, Timer_FFResponse, clientID, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.0, Timer_hasFriendlyFired, _, TIMER_FLAG_NO_MAPCHANGE);
}

Action Timer_FFResponse(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (!IsValidClient(client) || !IsSurvivor(client)) return Plugin_Continue;
	
	SetVariantString("PlayerFriendlyFire");
	AcceptEntityInput(client, "SpeakResponseConcept");
	return Plugin_Continue;
}

Action Timer_hasFriendlyFired(Handle timer)
{
	hasFriendlyFired = false;
	return Plugin_Continue;
}
// Friendly Fire fix end //

void GetSurvivorSceneName(int client, bool is_victim = false, char[] str, int maxlength)
{
	if (!IsValidClient(client) || !IsSurvivor(client)) return;
	
	static char cl_model[48];
	GetClientModel(client, cl_model, sizeof(cl_model));
	//PrintToChatAll("%s", cl_model);
	if 		(strncmp(cl_model, "models/survivors/survivor_gambler.mdl", 37, false) == 0)		is_victim ? strcopy(str, maxlength, "nick") :		strcopy(str, maxlength, "Gambler");
	else if	(strncmp(cl_model, "models/survivors/survivor_producer.mdl", 38, false) == 0)	is_victim ? strcopy(str, maxlength, "rochelle") :	strcopy(str, maxlength, "Producer");
	else if	(strncmp(cl_model, "models/survivors/survivor_coach.mdl", 35, false) == 0)		is_victim ? strcopy(str, maxlength, "coach") :		strcopy(str, maxlength, "Coach");
	else if	(strncmp(cl_model, "models/survivors/survivor_mechanic.mdl", 38, false) == 0)	is_victim ? strcopy(str, maxlength, "ellis") :		strcopy(str, maxlength, "Mechanic");
	else if	(strncmp(cl_model, "models/survivors/survivor_namvet.mdl", 36, false) == 0)		is_victim ? strcopy(str, maxlength, "bill") :		strcopy(str, maxlength, "NamVet");
	else if (strncmp(cl_model, "models/survivors/survivor_teenangst.mdl", 39, false) == 0)	is_victim ? strcopy(str, maxlength, "zoey") :		strcopy(str, maxlength, "TeenGirl");
	else if (strncmp(cl_model, "models/survivors/survivor_biker.mdl", 35, false) == 0)		is_victim ? strcopy(str, maxlength, "francis") :	strcopy(str, maxlength, "Biker");
	else if (strncmp(cl_model, "models/survivors/survivor_manager.mdl", 37, false) == 0)		is_victim ? strcopy(str, maxlength, "louis") :		strcopy(str, maxlength, "Manager");
	else	strcopy(str, maxlength, "Unknown");
}

/*bool IsZoey(int client)
{
	static char cl_model[PLATFORM_MAX_PATH];
	if (IsValidClient(client))
	{ GetClientModel(client, cl_model, sizeof(cl_model)); }
	if (IsValidClient(client) && IsSurvivor(client) && (
	GetEntProp(client, Prop_Send, "m_survivorCharacter") == 5 || // For Zoey in The Passing set
	GetEntProp(client, Prop_Send, "m_survivorCharacter") == 1 && strncmp(cl_model, "models/survivors/survivor_teenangst.mdl", 39, false) == 0 ) ) // For Zoey in the L4D1 survivor set
	{
		return true;
	}
	return false;
}*/

/*bool RecognizesOther(int client, int other)
{
	if (!IsValidClient(client) || !IsSurvivor(client) || !IsValidClient(other) || !IsSurvivor(other)) return false;
	
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
{ int team = GetClientTeam(client); return (team == 2 || team == 4); }

bool IsClientL4D1Survivor(int client)
{
	if (!HasEntProp(client, Prop_Send, "m_survivorCharacter")) return false;
	
	int character = GetEntProp(client, Prop_Send, "m_survivorCharacter");
	return (character >= 4 && character <= 7);
}

bool IsValidClient(int client, bool replaycheck = true, bool isLoop = false)
{
	if ((isLoop || client > 0 && client <= MaxClients) && IsClientInGame(client))
	{
		if (replaycheck)
		{
			if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
		}
		return true;
	}
	return false;
}

//bool RealValidEntity(int entity)
//{ return (entity > 0 && IsValidEntity(entity)); }