#define PLUGIN_NAME "[L4D2] Gunner Tank"
#define PLUGIN_AUTHOR "hihi1210, Shadowysn (new syntax)"
#define PLUGIN_DESC "Allows Tank to use guns"
#define PLUGIN_VERSION "1.0.4"
#define PLUGIN_URL "https://forums.alliedmods.net/showthread.php?t=165129"
#define PLUGIN_NAME_SHORT "Gunner Tank"
#define PLUGIN_NAME_TECH "l4d2_gunnertank"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

//int g_GameInstructor[MAXPLAYERS+1];
bool bdelay[MAXPLAYERS+1];
bool dp[MAXPLAYERS + 1];

static ConVar cvar_HP, cvar_M60, cvar_Reload,
cvar_DisplayAmmo, cvar_Damage, cvar_Allow;
int g_iHP, g_iReload, g_iAllow;
bool g_bM60, g_bDisplayAmmo;
float g_fDamage;

#define BITFLAG_RELOADBYDROP	(1 << 0)
#define BITFLAG_RELOADBYSPAWN	(1 << 1)

#define TEAM_SURVIVORS 2
#define TEAM_INFECTED 3

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESC,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}

//bool g_bLateLoad = false;
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() == Engine_Left4Dead2)
	{
		//g_bLateLoad = late;
		return APLRes_Success;
	}
	strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
	return APLRes_SilentFailure;
}

public void OnPluginStart()
{
	HookEvent("bot_player_replace", Event_PlayerReplaceBot, EventHookMode_Pre);
	HookEvent("player_spawn", reset, EventHookMode_Pre);
	//HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Pre);
	HookEvent("player_shoved", player_shoved, EventHookMode_Post);
	
	static char desc_str[64];
	Format(desc_str, sizeof(desc_str), "%s version.", PLUGIN_NAME_SHORT);
	static char cmd_str[64];
	Format(cmd_str, sizeof(cmd_str), "%s_version", PLUGIN_NAME_TECH);
	ConVar version_cvar = CreateConVar(cmd_str, PLUGIN_VERSION, desc_str, FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if (version_cvar != null)
		SetConVarString(version_cvar, PLUGIN_VERSION);
	
	Format(cmd_str, sizeof(cmd_str), "%s_allow", PLUGIN_NAME_TECH);
	cvar_Allow = CreateConVar(cmd_str, "1", "0 = Plugin off. 1 = Plugin on. 2 = root admin only.", FCVAR_NONE);
	cvar_Allow.AddChangeHook(CC_GT_Allow);
	
	Format(cmd_str, sizeof(cmd_str), "%s_hp", PLUGIN_NAME_TECH);
	cvar_HP = CreateConVar(cmd_str, "800", "Tank's health will drop to this amount when they pick up a gun. (0 = no change.)", FCVAR_NONE);
	cvar_HP.AddChangeHook(CC_GT_HP);
	
	Format(cmd_str, sizeof(cmd_str), "%s_m60", PLUGIN_NAME_TECH);
	cvar_M60 = CreateConVar(cmd_str, "0", "0 = Disallow M60. 1 = Allow M60.", FCVAR_NONE);
	cvar_M60.AddChangeHook(CC_GT_M60);
	
	Format(cmd_str, sizeof(cmd_str), "%s_reload", PLUGIN_NAME_TECH);
	cvar_Reload = CreateConVar(cmd_str, "3", "0 = Disallow reloading ammo. 1 = Allow reloading ammo by picking up weapon_xxxx guns. 2 = Allow reloading ammo by picking up weapon_spawn guns. 3 = Both.", FCVAR_NONE);
	cvar_Reload.AddChangeHook(CC_GT_Reload);
	
	Format(cmd_str, sizeof(cmd_str), "%s_displayammo", PLUGIN_NAME_TECH);
	cvar_DisplayAmmo = CreateConVar(cmd_str, "1", "0 = No display. 1 = Display.", FCVAR_NONE);
	cvar_DisplayAmmo.AddChangeHook(CC_GT_DisplayAmmo);
	
	Format(cmd_str, sizeof(cmd_str), "%s_damage_multiplier", PLUGIN_NAME_TECH);
	cvar_Damage = CreateConVar(cmd_str, "0.18", "Weapon damage modifier. (1.0 = full damage)", FCVAR_NONE);
	cvar_Damage.AddChangeHook(CC_GT_Damage);
	
	AutoExecConfig(true, PLUGIN_NAME_TECH);
	SetCvarValues();
}

void CC_GT_Allow(ConVar convar, const char[] oldValue, const char[] newValue)			{ g_iAllow =			convar.IntValue;		}
void CC_GT_HP(ConVar convar, const char[] oldValue, const char[] newValue)				{ g_iHP =			convar.IntValue;		}
void CC_GT_M60(ConVar convar, const char[] oldValue, const char[] newValue)			{ g_bM60 =			convar.BoolValue;		}
void CC_GT_Reload(ConVar convar, const char[] oldValue, const char[] newValue)			{ g_iReload =		convar.IntValue;		}
void CC_GT_DisplayAmmo(ConVar convar, const char[] oldValue, const char[] newValue)		{ g_bDisplayAmmo =	convar.BoolValue;		}
void CC_GT_Damage(ConVar convar, const char[] oldValue, const char[] newValue)			{ g_fDamage =		convar.FloatValue;	}
void SetCvarValues()
{
	CC_GT_Allow(cvar_Allow, "", "");
	CC_GT_HP(cvar_HP, "", "");
	CC_GT_M60(cvar_M60, "", "");
	CC_GT_Reload(cvar_Reload, "", "");
	CC_GT_DisplayAmmo(cvar_DisplayAmmo, "", "");
	CC_GT_Damage(cvar_Damage, "", "");
}

void reset(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("userid", 0);
	int client = GetClientOfUserId(userid);
	bdelay[client] = false; dp[client] = false;
	
	if (!IsValidClient(client) || GetClientTeam(client) != TEAM_INFECTED || !IsClientTank(client) ||
	!IsPlayerAlive(client) || IsFakeClient(client)) return;
	
	//QueryClientConVar(client, "gameinstructor_enable", view_as<ConVarQueryFinished>(GameInstructor), client);
	//ClientCommand(client, "gameinstructor_enable 1");
	CreateTimer(2.0, DisplayInstructorHint, userid, TIMER_FLAG_NO_MAPCHANGE);
}

public void OnClientPutInServer(int client)
{ SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage); }
public void OnClientPostAdminCheck(int client)
{ bdelay[client] = false;dp[client] = false; }

void player_shoved(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid", 0));
	if (!IsValidClient(victim) || GetClientTeam(victim) != TEAM_SURVIVORS) return;
	int attacker = GetClientOfUserId(event.GetInt("attacker", 0));
	if (!IsValidClient(attacker) || !IsClientTank(attacker)) return;
	
	float game_time = GetGameTime();
	float staggerTime = GetEntDataFloat(victim, (FindSendPropInfo("CTerrorPlayer", "m_staggerTimer") + 8));
	if (staggerTime >= game_time) return;
	
	//if (IsThrowing(attacker))
	//{
	//	//SetDTCountdownTimer(victim, "m_staggerTimer", 0.0);
	//	return;
	//}
	
	if (view_as<bool>(GetEntProp(victim, Prop_Send, "m_isIncapacitated")))
	{
		SDKHooks_TakeDamage(victim, attacker, attacker, 12.0, DMG_SLASH);
	}
	else
	{
		float attackOrigin[3];
		GetClientAbsOrigin(attacker, attackOrigin);
		static char staggerChar[64];
		Format(staggerChar, sizeof(staggerChar), "self.Stagger(Vector(%f,%f,%f))", 
		attackOrigin[0], attackOrigin[1], attackOrigin[2]);
		SetVariantString(staggerChar);
		AcceptEntityInput(victim, "RunScriptCode");
		
		SetVariantString("PainLevel:Major:0.05");
		AcceptEntityInput(victim, "AddContext");
		SetVariantString("Pain");
		AcceptEntityInput(victim, "SpeakResponseConcept");
	}
}


/*int GetZombieClass(int client)
{
	if (IsValidClient(client) && IsPlayerAlive(client) && GetClientTeam(client) == TEAM_INFECTED)
	{
		return GetEntProp(client, Prop_Send, "m_zombieClass");
	}
	return -1;
}*/
bool IsClientTank(int client)
{
	if (GetEntProp(client, Prop_Send, "m_zombieClass") == /*(g_isSequel ? */8/* : 4)*/) return true;
	return false;
}
bool IsThrowing(int client)
{
	/*int ability = GetInfectedAbility(client);
	if (!RealValidEntity(ability)) return false;
	
	if (HasEntProp(ability, Prop_Send, "m_nextActivationTimer"))
	{
		float ab_float = GetEntDataFloat(ability, (FindSendPropInfo("CThrow", "m_nextActivationTimer") + 8));
		if ((GetGameTime() - ab_float) > 0)
			return true;
	}*/
	int recentChild = GetEntPropEnt(client, Prop_Data, "m_hMoveChild");
	static char class[10];
	GetEntityClassname(recentChild, class, sizeof(class));
	if (strcmp(class, "tank_rock") != 0) return false;
	
	return true;
}
/*stock int GetInfectedAbility(int client)
{
	int ability_ent = -1;
	if (HasEntProp(client, Prop_Send, "m_customAbility"))
		ability_ent = GetEntPropEnt(client, Prop_Send, "m_customAbility");
	return ability_ent;
}*/
void SetDTCountdownTimer(int client, const char[] timer_str, float duration)
{
	int info = FindSendPropInfo("CTerrorPlayer", timer_str);
	SetEntDataFloat(client, (info+4), duration, true);
	SetEntDataFloat(client, (info+8), GetGameTime()+duration, true);
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon)
{
	if (g_iAllow != 1 && (g_iAllow != 2 || !CheckCommandAccess(client,  "", ADMFLAG_ROOT, true))) return Plugin_Continue;
	
	// Is client human, ingame, infected, alive, not a ghost and pressing the button?
	if (!IsValidClient(client) || 
	IsFakeClient(client) || 
	GetClientTeam(client) != TEAM_INFECTED || 
	!IsPlayerAlive(client) || 
	view_as<bool>((GetEntProp(client, Prop_Send, "m_isGhost")))) return Plugin_Continue;
	
	// Is tank class?
	if (!IsClientTank(client)) return Plugin_Continue;
	
	bool hasChanged = false;
	if (IsThrowing(client) && buttons & IN_ATTACK2)
	{
		buttons &= ~IN_ATTACK2;
		hasChanged = true;
	}
	
	// Get detonation button
	if (!(buttons & IN_USE)) return Plugin_Continue;
	
	if (bdelay[client]) return Plugin_Continue;
	
	int gun = GetClientAimTarget(client, false);
	static char ent_name[32];
	if (!RealValidEntity(gun))
	{
		int Meds = GetPlayerWeaponSlot(client, 0);
		
		bool isValidMeds = RealValidEntity(Meds);
		if (isValidMeds)
			GetEntityClassname(Meds, ent_name, sizeof(ent_name));
		
		if (!isValidMeds || strcmp(ent_name, "weapon_tank_claw") != 0)
		{
			int claw = CreateEntityByName("weapon_tank_claw");
			if (DispatchSpawn(claw))
			{
				SDKHooks_DropWeapon(client, Meds);
				EquipPlayerWeapon(client, claw);
				bdelay[client] = true;
				CreateTimer(1.0, ResetDelay, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
				dp[client] = false;
			}
		}
		return Plugin_Continue;
	}
	else
	{
		if (!RealValidEntity(gun)) return Plugin_Continue;
		
		GetEntityClassname(gun, ent_name, sizeof(ent_name)); 
		if (
			(strncmp(ent_name, "weapon_rifle", 12, false) == 0 || 
			strncmp(ent_name, "weapon_smg", 10, false) == 0 || 
			strncmp(ent_name, "weapon_sniper", 13, false) == 0 || 
			strncmp(ent_name, "weapon_hunting_rifle", 20, false) == 0 || 
			strncmp(ent_name, "weapon_grenade_launcher", 23, false) == 0 || 
			StrContains(ent_name, "shotgun", false) != -1)
			&&
			StrContains(ent_name, "spawn", false) == -1
		)
		{
			bool isM60 = strncmp(ent_name, "weapon_rifle_m60", 16, false) == 0;
			if (!g_bM60 && isM60) return Plugin_Continue;
			
			float VecOrigin[3], VecAngles[3];
			GetClientAbsOrigin(client, VecOrigin);
			GetEntPropVector(gun, Prop_Data, "m_vecOrigin", VecAngles);
			
			if (GetVectorDistance(VecOrigin, VecAngles) >= 80) return Plugin_Continue;
			
			int Meds = GetPlayerWeaponSlot(client, 0);
			
			int foundgunammo = GetEntProp(gun, Prop_Send, "m_iExtraPrimaryAmmo");
			int ammo_offset = GetEntProp(gun, Prop_Send, "m_iPrimaryAmmoType");
			
			if (RealValidEntity(Meds))
			{
				GetEntityClassname(Meds, ent_name, sizeof(ent_name)); // Reuse ent_name
				if (strcmp(ent_name, "weapon_tank_claw") == 0)
				{
					RemovePlayerItem(client, Meds);
					AcceptEntityInput(Meds, "Kill");
				}
				else
				{
					SDKHooks_DropWeapon(client, Meds);
				}
			}
			EquipPlayerWeapon(client, gun);
			
			if (!isM60)
			{
				if (g_iReload & BITFLAG_RELOADBYDROP)
				{
					SetEntProp(client, Prop_Send, "m_iAmmo", foundgunammo, _, ammo_offset);
				}
			}
			
			int userid = GetClientUserId(client);
			bdelay[client] = true;
			CreateTimer(1.0, ResetDelay, userid, TIMER_FLAG_NO_MAPCHANGE);
			
			if (dp[client] == false && RealValidEntity(GetPlayerWeaponSlot(client, 0)))
			{
				dp[client] = true;
				if (g_bDisplayAmmo)
					CreateTimer(0.1, PAd, userid, TIMER_FLAG_NO_MAPCHANGE);
			}
			
			if (g_iHP != 0)
			{
				if (GetClientHealth(client) > g_iHP) 
					SetEntityHealth(client, g_iHP);
			}
		}
		else if (strncmp(ent_name, "weapon", 6, false) == 0 && StrContains(ent_name, "spawn", false) != -1) 
		{
			float VecOrigin[3], VecAngles[3];
			GetClientAbsOrigin(client, VecOrigin);
			GetEntPropVector(gun, Prop_Data, "m_vecOrigin", VecAngles);
			
			if (GetVectorDistance(VecOrigin, VecAngles) >= 80) return Plugin_Continue;
			
			static char modelname[128];
			GetEntPropString(gun, Prop_Data, "m_ModelName", modelname, sizeof(modelname));
			
			int entity;
			if (strcmp(modelname, "models/w_models/weapons/w_autoshot_m4super.mdl") == 0)
				entity = CreateEntityByName("weapon_autoshotgun");
			else if (strcmp(modelname, "models/w_models/weapons/w_desert_rifle.mdl") == 0)
				entity = CreateEntityByName("weapon_rifle_desert");
			else if (strcmp(modelname, "models/w_models/weapons/w_grenade_launcher.mdl") == 0)
				entity = CreateEntityByName("weapon_grenade_launcher");
			else if (strcmp(modelname, "models/w_models/weapons/w_pumpshotgun_A.mdl") == 0)
				entity = CreateEntityByName("weapon_shotgun_chrome");
			else if (strcmp(modelname, "models/w_models/weapons/w_rifle_ak47.mdl") == 0)
				entity = CreateEntityByName("weapon_rifle_ak47");
			else if (strcmp(modelname, "models/w_models/weapons/w_rifle_b.mdl") == 0)
				entity = CreateEntityByName("weapon_rifle");
			else if (strcmp(modelname, "models/w_models/weapons/w_rifle_m16a2.mdl") == 0)
				entity = CreateEntityByName("weapon_rifle");
			else if (strcmp(modelname, "models/w_models/weapons/w_shotgun.mdl") == 0)
				entity = CreateEntityByName("weapon_pumpshotgun");
			else if (strcmp(modelname, "models/w_models/weapons/w_shotgun_spas.mdl") == 0)
				entity = CreateEntityByName("weapon_shotgun_spas");
			else if (strcmp(modelname, "models/w_models/weapons/w_smg_uzi.mdl") == 0)
				entity = CreateEntityByName("weapon_smg");
			else if (strcmp(modelname, "models/w_models/weapons/w_smg_a.mdl") == 0)
				entity = CreateEntityByName("weapon_smg_silenced");
			else if (strcmp(modelname, "models/w_models/weapons/w_sniper_military.mdl") == 0)
				entity = CreateEntityByName("weapon_sniper_military");
			else if (strcmp(modelname, "models/w_models/weapons/w_sniper_mini14.mdl") == 0)
				entity = CreateEntityByName("weapon_hunting_rifle");
			else if (strcmp(modelname, "models/w_models/weapons/w_m60.mdl") == 0)
			{
				if (g_bM60)
					entity = CreateEntityByName("weapon_rifle_m60");
				else
					return Plugin_Continue;
			}
			else
				return Plugin_Continue;
			
			int Meds = GetPlayerWeaponSlot(client, 0);
			if (!DispatchSpawn(entity)) return Plugin_Continue;
			
			GetEntityClassname(Meds, ent_name, sizeof(ent_name)); // Reuse ent_name
			if (strcmp(ent_name, "weapon_tank_claw") == 0)
			{
				RemovePlayerItem(client, Meds);
				AcceptEntityInput(Meds, "Kill");
			}
			else
			{
				SDKHooks_DropWeapon(client, Meds);
			}
			EquipPlayerWeapon(client, entity);
			
			int userid = GetClientUserId(client);
			bdelay[client] = true;
			CreateTimer(1.0, ResetDelay, userid, TIMER_FLAG_NO_MAPCHANGE);
			
			if (dp[client] == false && RealValidEntity(GetPlayerWeaponSlot(client, 0)))
			{
				dp[client] = true;
				if (g_bDisplayAmmo)
					CreateTimer(0.1, PAd, userid, TIMER_FLAG_NO_MAPCHANGE);
			}
			
			if (g_iReload & BITFLAG_RELOADBYSPAWN)
			{
				StripAndExecuteClientCommand(client, "give", "ammo", "", "");
			}
			
			if (g_iHP != 0)
			{
				if (GetClientHealth(client) > g_iHP) 
					SetEntityHealth(client, g_iHP);
			}
		}
	}
	if (hasChanged) return Plugin_Changed;
	return Plugin_Continue;
}
Action ResetDelay(Handle timer, int userid)
{ int client = GetClientOfUserId(userid); bdelay[client] = false; return Plugin_Continue; }

void Event_PlayerReplaceBot(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("player", 0);
	int client = GetClientOfUserId(userid);
	
	if (!IsValidClient(client) || !IsPlayerAlive(client) || GetClientTeam(client) != TEAM_INFECTED || 
	!IsClientTank(client)) return;
	
	//QueryClientConVar(client, "gameinstructor_enable", view_as<ConVarQueryFinished>(GameInstructor), client);
	//ClientCommand(client, "gameinstructor_enable 1");
	CreateTimer(2.0, DisplayInstructorHint, userid, TIMER_FLAG_NO_MAPCHANGE);
}

Action DisplayInstructorHint(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (g_iAllow != 1 && (g_iAllow != 2 || !CheckCommandAccess(client,  "", ADMFLAG_ROOT, true))) return Plugin_Continue;
	
	static char s_TargetName[32], s_Message[128];
	
	int i_Ent = CreateEntityByName("env_instructor_hint");
	FormatEx(s_TargetName, sizeof(s_TargetName), "hint%d", client);
	
	if (g_iHP != 0)
		FormatEx(s_Message, sizeof(s_Message), "Aim crosshair on a gun and press USE to equip. Drop it by pressing USE again. (Your health will drop to %d!)", g_iHP);
	else
		FormatEx(s_Message, sizeof(s_Message), "Aim crosshair on a gun and press USE to equip. Drop it by pressing USE again.");
	
	PrintHintText(client,s_Message);
	ReplaceString(s_Message, sizeof(s_Message), "\n", " ");
	DispatchKeyValue(client, "targetname", s_TargetName);
	DispatchKeyValue(i_Ent, "hint_target", s_TargetName);
	DispatchKeyValue(i_Ent, "hint_timeout", "5");
	DispatchKeyValue(i_Ent, "hint_range", "0.01");
	DispatchKeyValue(i_Ent, "hint_icon_onscreen", "use_binding");
	DispatchKeyValue(i_Ent, "hint_caption", s_Message);
	DispatchKeyValue(i_Ent, "hint_color", "255 255 255");
	DispatchKeyValue(i_Ent, "hint_binding", "+use");
	DispatchSpawn(i_Ent);
	AcceptEntityInput(i_Ent, "ShowHint");
	
	DispatchKeyValue(i_Ent, "OnUser1", "!self,Kill,,5.0,1");
	AcceptEntityInput(i_Ent, "FireUser1");
	
	//CreateTimer(5.0, RemoveInstructorHint, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

//void GameInstructor(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue)
//{ g_GameInstructor[client] = StringToInt(cvarValue); }

/*Action RemoveInstructorHint(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	
	//if (!g_GameInstructor[client])
	//	ClientCommand(client, "gameinstructor_enable 0");
	return Plugin_Continue;
}*/

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
bool RealValidEntity(int entity)
{ return (entity > 0 && IsValidEntity(entity)); }

void StripAndExecuteClientCommand(int client, const char[] command, const char[] param1, const char[] param2, const char[] param3)
{
	//LogAction(0, -1, "DEBUG:stripandexecuteclientcommand");
	
	//if (!IsValidClient(client) || IsFakeClient(client)) return;
	
	int flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s %s %s", command, param1, param2, param3);
	SetCommandFlags(command, flags);
}

Action PAd(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	
	if (!IsValidClient(client) || !IsPlayerAlive(client) || IsFakeClient(client) || !IsClientTank(client))
	{
		dp[client] = false;
		return Plugin_Continue;
	}
	
	int wep_slot = GetPlayerWeaponSlot(client, 0);
	if (RealValidEntity(wep_slot))
	{
		static char ent_name[32];
		GetEntityClassname(wep_slot, ent_name, sizeof(ent_name));
		
		int ammo_offset = GetEntProp(wep_slot, Prop_Send, "m_iPrimaryAmmoType");
		int currentammo = GetEntProp(client, Prop_Send, "m_iAmmo", _, ammo_offset); //get targets current ammo
		
		int clip = GetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_iClip1");
		//int ammo = GetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_iExtraPrimaryAmmo");
		if (strncmp(ent_name, "weapon_rifle_m60", 16, false) == 0)
			PrintHintText(client, "Primary Ammo : %d", clip);
		else if (strncmp(ent_name, "weapon_tank_claw", 16, false) == 0)
			PrintHintText(client, "Tank Claw");
		else
			PrintHintText(client, "Primary Ammo : %d / %d", clip, currentammo);
		
		if (dp[client])
			CreateTimer(0.5, PAd, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		else
			dp[client] = false;
	}
	return Plugin_Continue;
}

Action OnTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype)
{
	if (!IsValidClient(victim) || !IsValidClient(attacker)) return Plugin_Continue;
	if (GetClientTeam(victim) != TEAM_SURVIVORS || GetClientTeam(attacker) != TEAM_INFECTED || 
	!IsClientTank(attacker)) return Plugin_Continue;
	
	static char ent_name[64];
	if (attacker == inflictor) // case: attack with an equipped weapon (guns, claws)
		GetClientWeapon(inflictor, ent_name, sizeof(ent_name));
	else
		GetEntityClassname(inflictor, ent_name, sizeof(ent_name)); // tank special case?
	
	if (strncmp(ent_name, "weapon_rifle", 12, false) == 0 || 
	strncmp(ent_name, "weapon_smg", 10, false) == 0 || 
	strncmp(ent_name, "weapon_sniper", 13, false) == 0 || 
	strncmp(ent_name, "weapon_hunting_rifle", 20, false) == 0 || 
	strncmp(ent_name, "weapon_grenade_launcher", 23, false) == 0 || 
	StrContains(ent_name, "shotgun", false) != -1)
	{
		damage = RoundToFloor(damage * g_fDamage) * 1.0;
		//PrintToChat(attacker, "inflictor: %s,damage: %f", ent_name, damage);
		return Plugin_Changed;
	}
	return Plugin_Continue;
}