#define PLUGIN_NAME "[TF2] Drop-Dead Plugin"
#define PLUGIN_AUTHOR "Shadowysn"
#define PLUGIN_DESC "Drop dead using the command sm_dd!"
#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>

#define DAMAGE_HOOK SDKHook_OnTakeDamagePost

//#pragma newdecls required

bool g_DropDead[MAXPLAYERS+1] = false;
static int g_Ragdoll[MAXPLAYERS+1];
static int g_Weapon[MAXPLAYERS+1];
static float g_NextAllowedCommandTime[MAXPLAYERS+1];
Handle g_TimeLimit[MAXPLAYERS+1];

ConVar version_cvar;
ConVar plugin_enable;
ConVar view_ragdoll;
ConVar cooldown_cmd;
ConVar timelimit_cmd;
ConVar limit_to_spy;

public Plugin myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESC,
	version = PLUGIN_VERSION,
	url = "nourl4u"
}

public void OnPluginStart()
{
	plugin_enable = CreateConVar("sm_dropdead_enable", "1.0", "Enable drop-dead ability?", FCVAR_ARCHIVE, true, 0.0, true, 1.0);
	view_ragdoll = CreateConVar("sm_dropdead_view_ragdoll", "0.0", "Should drop-dead users see from their corpse?", FCVAR_ARCHIVE, true, 0.0, true, 1.0);
	cooldown_cmd = CreateConVar("sm_dropdead_cooldown", "5.0", "How long users are unable to drop-dead, in seconds.", FCVAR_ARCHIVE, true, 0.0, true, 100.0);
	timelimit_cmd = CreateConVar("sm_dropdead_timelimit", "7.0", "How long users can stay in drop-dead mode, in seconds. Set to 0 to disable.", FCVAR_ARCHIVE, true, 0.0, true, 100.0);
	limit_to_spy = CreateConVar("sm_dropdead_limit_to_spy", "0.0", "Should drop-dead only be available to spies?", FCVAR_ARCHIVE, true, 0.0, true, 1.0);
	
	version_cvar = CreateConVar("sm_dropdead_version", PLUGIN_VERSION, "Drop-Dead plugin version", FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if(version_cvar != null)
	SetConVarString(version_cvar, PLUGIN_VERSION);
	RegConsoleCmd("sm_dd", Drop_Dead_Cmd);
	RegAdminCmd("sm_dd_ply", Drop_Dead_Debug, ADMFLAG_GENERIC, "Toggle Drop-Dead on a specified player.");
	
	HookEvent("player_death", player_death, EventHookMode_Pre);
	HookEvent("player_hurt", player_hurt, EventHookMode_Pre);
}

public void OnPluginEnd()
{
	UnhookEvent("player_death", player_death, EventHookMode_Pre);
	UnhookEvent("player_hurt", player_hurt, EventHookMode_Pre);
	for (int i=0; i<=MAXPLAYERS; i++) {
		if (IsValidEntity(g_Ragdoll[i]))
		{
			if(g_Ragdoll[i] > MaxClients) RemoveRagdoll(i);
			g_Ragdoll[i] = INVALID_ENT_REFERENCE;
		}
		if (g_DropDead[i])
		{
			Drop_Dead(i);
		}
		SDKUnhook(i, DAMAGE_HOOK, Hook_OnTakeDamagePost);
	}
}

public void OnClientPutInServer(int client) {
    g_NextAllowedCommandTime[client] = 0.0;
}

void Hook_OnTakeDamagePost(victim, attacker, inflictor, float damage, damageType, weapon, 
const float damageForce[3], const float damagePosition[3], damagecustom)
{
	if (!IsValidClient(victim)) 
	{ return; }
	if (TF2_IsPlayerAlive(victim))
	{ return; }
	if (!g_DropDead[victim])
	{ return; }
	
	Drop_Dead(victim);
}

public player_hurt(Handle event, const char[] name, bool lol) 
{
	int victimID = GetEventInt(event, "userid");
	int victim = GetClientOfUserId(victimID);
	if (!IsValidClient(victim))
	{ return Plugin_Continue; }
	
	if (g_DropDead[victim])
	{ return Plugin_Handled; }
	return Plugin_Continue;
}

public player_death(Handle event, const char[] name, bool lol) 
{
	int victimID = GetEventInt(event, "userid");
	int victim = GetClientOfUserId(victimID);
	if (!IsValidClient(victim))
	{ return; }
	
	if (!g_DropDead[victim])
	{ return; }
	
	Drop_Dead(victim);
	return;
}

Action Drop_Dead_Cmd(client, args)
{
	if (!IsValidClient(client))
	{ return Plugin_Handled; }
	
	if (!g_DropDead[client] && !GetConVarBool(plugin_enable))
	{ return Plugin_Handled; }
	
	TFClassType cl_class = TF2_GetPlayerClass(client);
	if (!g_DropDead[client] && GetConVarBool(limit_to_spy) && cl_class != TFClass_Spy)
	{ return Plugin_Handled; }
	
	if (GetGameTime()+0.5 < g_NextAllowedCommandTime[client]) {
        PrintHintText(client, "You cannot use the drop-dead command for %i second(s).", RoundFloat(g_NextAllowedCommandTime[client]-GetGameTime()));
        return Plugin_Handled;
    }
	
	static float cooldown_num = 2.0;
	if (cooldown_cmd != null)
	{ cooldown_num = GetConVarFloat(cooldown_cmd); }
	g_NextAllowedCommandTime[client] = GetGameTime() + cooldown_num;
	
	Drop_Dead(client);
	
	return Plugin_Handled;
}

void Drop_Dead(client, bool rem_timer = true)
{
	if (!IsValidClient(client))
	{ return; }
	
	TF2_RemoveCondition(client, TFCond_Disguised);
	TF2_RemoveCondition(client, TFCond_Disguising);
	TF2_RemoveCondition(client, TFCond_Cloaked);
	TF2_RemoveCondition(client, TFCond_Taunting);
	TF2_RemoveCondition(client, TFCond_Slowed);
	TF2_RemoveCondition(client, TFCond_Zoomed);
	SetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", {0.0, 0.0, 0.0});
	if (g_DropDead[client] || !TF2_IsPlayerAlive(client))
	{
		g_DropDead[client] = false;
		SDKUnhook(client, DAMAGE_HOOK, Hook_OnTakeDamagePost);
		
		if (rem_timer && g_TimeLimit[client] != null)
		{ CloseHandle(g_TimeLimit[client]); }
		
		RemoveRagdoll(client);
		RemoveWeapon(client);
		SetClientViewEntity(client, client);
		//TF2_RemoveCondition(client, TFCond_UberchargedHidden);
		SetVariantInt(0);
		AcceptEntityInput(client, "SetForcedTauntCam");
		WeaponAttackAvailable(client, true);
		//SetClientAlpha(client, 255);
		SetEntityRenderFx(client, RENDERFX_NONE);
		SetEntityMoveType(client, MOVETYPE_WALK);
		if (TF2_IsPlayerAlive && TF2_IsPlayerInCondition(client, TFCond_StealthedUserBuffFade))
		{ TF2_RemoveCondition(client, TFCond_StealthedUserBuffFade); }
	}
	else if (TF2_IsPlayerAlive(client))
	{
		g_DropDead[client] = true;
		SDKHook(client, DAMAGE_HOOK, Hook_OnTakeDamagePost);
		
		static float timelimit_num = 7.0;
		if (timelimit_cmd != null)
		{ timelimit_num = GetConVarFloat(timelimit_cmd); }
		if (timelimit_num > 0.0)
		{ g_TimeLimit[client] = CreateTimer(timelimit_num, Time_Limit, client); }
		
		SpawnRagdoll(client);
		SpawnWeapon(client);
		if (IsValidEntity(g_Ragdoll[client]) && (GetConVarFloat(view_ragdoll) > 0.0 || GetConVarInt(view_ragdoll) > 0)) 
			SetClientViewEntity(client, g_Ragdoll[client]);
		SetVariantInt(1);
		AcceptEntityInput(client, "SetForcedTauntCam");
		//TF2_AddCondition(client, TFCond_UberchargedHidden);
		WeaponAttackAvailable(client, false);
		//SetClientAlpha(client, 0);
		SetEntityRenderFx(client, RENDERFX_RAGDOLL);
		SetEntityMoveType(client, MOVETYPE_NONE);
		SetEntProp(client, Prop_Send, "m_hGroundEntity", -1)
		
		TF2_AddCondition(client,TFCond_StealthedUserBuffFade);
		if (TF2_IsPlayerInCondition(client, TFCond_OnFire))
			{ TF2_RemoveCondition(client, TFCond_OnFire); }
		if (TF2_IsPlayerInCondition(client, TFCond_BurningPyro))
			{ TF2_RemoveCondition(client, TFCond_BurningPyro); }
	}
}

Action Time_Limit(Handle timer, client) {
	if (!IsValidClient(client))
	{ return; }
	if (!g_DropDead[client])
	{ return; }
	Drop_Dead(client, false);
	//g_TimeLimit[client] = null;
	//if (g_TimeLimit[client] != null)
	//{ CloseHandle(g_TimeLimit[client]); }
}

Action Drop_Dead_Debug(client, args) {
	if (args != 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_dd_ply <target>");
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
	if (!TF2_IsPlayerAlive(ply) || IsClientObserver(ply))
	{
		ReplyToCommand(client, "[SM] %s is either dead or a spectator!", ply_name);
		return Plugin_Handled;
	}
	
	Drop_Dead(ply);
	return Plugin_Handled;
}

public OnClientDisconnect(client)
{
	if (IsValidEntity(g_Ragdoll[client]))
	{
		if(g_Ragdoll[client] > MaxClients) AcceptEntityInput(g_Ragdoll[client], "Kill");
		g_Ragdoll[client] = INVALID_ENT_REFERENCE;
	}
	SDKUnhook(client, DAMAGE_HOOK, Hook_OnTakeDamagePost);
}

/*public Action OnPlayerRunCmd(client, &buttons)
{
	if(!g_DropDead[client])
	{ return Plugin_Continue; }
	return Plugin_Handled;
	if(buttons & IN_ATTACK)
		buttons &= ~IN_ATTACK;
	if(buttons & IN_ATTACK2)
		buttons &= ~IN_ATTACK2;
	if(buttons & IN_FORWARD)
		buttons &= ~IN_FORWARD;
	if(buttons & IN_BACK)
		buttons &= ~IN_BACK;
	if(buttons & IN_MOVELEFT)
		buttons &= ~IN_MOVELEFT;
	if(buttons & IN_MOVERIGHT)
		buttons &= ~IN_MOVERIGHT;
	if(buttons & IN_USE)
		buttons &= ~IN_USE;
	//if (buttons > 0)
	//{ PrintToChatAll("%i", buttons); }
	return Plugin_Changed;
}*/

// These stocks were taken from RTD Revamped. https://forums.alliedmods.net/showthread.php?s=a05e9e26f27bb03b62350f7b35dc507c&t=278579
// Sorry for editing the values, I guess it makes me feel less and... more bad...?
/*stock void SetEntityAlpha(ent, value)
{
	SetEntityRenderMode(ent, RENDER_TRANSCOLOR);
	SetEntData(ent, GetEntSendPropOffs(ent, "m_clrRender") + 3, value, 1, true);
}

stock void SetClientAlpha(client, value)
{
	SetEntityAlpha(client, value);

	int weapon = 0;
	for(int i = 0; i < 5; i++)
	{
		weapon = GetPlayerWeaponSlot(client, i);
		if(weapon > MaxClients && IsValidEntity(weapon))
			SetEntityAlpha(weapon, value);
	}

	for(int i = MaxClients+1; i < GetMaxEntities(); i++)
		if(IsWearable(i, client))
			SetEntityAlpha(i, value);
}*/

stock bool IsWearable(ent, owner){
	if(!IsValidEntity(ent))
		return false;

	char sClass[24];
	GetEntityClassname(ent, sClass, 24);
	if(strlen(sClass) < 7)
		return false;

	if(strncmp(sClass, "tf_", 3) != 0)
		return false;

	if(strncmp(sClass[3], "wear", 4) != 0
	&& strncmp(sClass[3], "powe", 4) != 0)
		return false;

	if(GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") != owner)
		return false;

	return true;
}
// End of stocks taken from RTD Revamped.
void SpawnRagdoll(client)
{
	float PlayerPosition[3];
	
	RemoveRagdoll(client);
	
	int ragdoll = CreateEntityByName("tf_ragdoll");
	
	if (ragdoll)
	{
		//ActivateEntity(ragdoll);
		
		//PlayerPosition[2] = PlayerPosition[2]+25;
		GetClientAbsOrigin(client, PlayerPosition);
		SetEntPropVector(ragdoll, Prop_Send, "m_vecRagdollOrigin", PlayerPosition);
		TeleportEntity(ragdoll, PlayerPosition, NULL_VECTOR, NULL_VECTOR);
		
		TFClassType cl_class = TF2_GetPlayerClass(client);
		
		SetEntProp(ragdoll, Prop_Send, "m_iClass", cl_class);
		
		if ((TF2_IsPlayerInCondition(client, TFCond_OnFire) || TF2_IsPlayerInCondition(client, TFCond_BurningPyro)) && 
		cl_class != TFClass_Pyro)
		{
			SetEntProp(ragdoll, Prop_Send, "m_bBurning", 1);
		}
		
		SetEntPropEnt(ragdoll, Prop_Send, "m_iPlayerIndex", client);
		
		TFTeam team = TF2_GetClientTeam(client);
		SetEntProp(ragdoll, Prop_Send, "m_iTeam", team);
		
		SetEntPropFloat(ragdoll, Prop_Send, "m_flHeadScale", GetEntPropFloat(client, Prop_Send, "m_flHeadScale"));
		SetEntPropFloat(ragdoll, Prop_Send, "m_flTorsoScale", GetEntPropFloat(client, Prop_Send, "m_flTorsoScale"));
		SetEntPropFloat(ragdoll, Prop_Send, "m_flHandScale", GetEntPropFloat(client, Prop_Send, "m_flHandScale"));
		
		//SetEntPropEnt(client, Prop_Send, "m_hRagdoll", ragdoll, 0);
		
		DispatchSpawn(ragdoll);
		ActivateEntity(ragdoll);
		
		g_Ragdoll[client] = ragdoll;
	}
}

void RemoveRagdoll(client)
{	
	if(IsValidEntity(g_Ragdoll[client]))
	{
		char classname[32];
		GetEdictClassname(g_Ragdoll[client], classname, sizeof(classname));
		if(StrEqual(classname, "tf_ragdoll", false))
		{
			AcceptEntityInput(g_Ragdoll[client], "kill");
		}
		g_Ragdoll[client] = INVALID_ENT_REFERENCE;
	}
}

void SpawnWeapon(client)
{
	float Position[3];
	float Angles[3];
	
	GetClientAbsOrigin(client, Position);
	GetClientEyeAngles(client, Angles);
	
	// Weapon entity start v
	
	int active_wep = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (!IsValidEntity(active_wep)) return;
	
	int weapon = CreateEntityByName("tf_dropped_weapon"); // Old system
	char wep_model[PLATFORM_MAX_PATH+1];
	int modelidx = GetEntProp(active_wep, Prop_Send, "m_iWorldModelIndex");
	int table = FindStringTable("modelprecache");
	ReadStringTable(table, modelidx, wep_model, sizeof(wep_model));
	
	SetEntityModel(weapon, wep_model);
	int cl_class = GetClientTeam(client);
	SetEntProp(weapon, Prop_Data, "m_nSkin", (cl_class == 3) ? 1 : 0);
	
	SetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex", GetEntProp(active_wep, Prop_Send, "m_iItemDefinitionIndex"));
	SetEntProp(weapon, Prop_Send, "m_iEntityLevel", GetEntProp(active_wep, Prop_Send, "m_iEntityLevel"));
	SetEntProp(weapon, Prop_Send, "m_iItemIDHigh", GetEntProp(active_wep, Prop_Send, "m_iItemIDHigh"));
	SetEntProp(weapon, Prop_Send, "m_iItemIDLow", GetEntProp(active_wep, Prop_Send, "m_iItemIDLow"));
	SetEntProp(weapon, Prop_Send, "m_iAccountID", GetEntProp(active_wep, Prop_Send, "m_iAccountID"));
	SetEntProp(weapon, Prop_Send, "m_iEntityQuality", GetEntProp(active_wep, Prop_Send, "m_iEntityQuality"));
	SetEntProp(weapon, Prop_Send, "m_bOnlyIterateItemViewAttributes", 
	GetEntProp(active_wep, Prop_Send, "m_bOnlyIterateItemViewAttributes"));
	SetEntProp(weapon, Prop_Send, "m_iTeamNumber", GetClientTeam(client));
	
	SetEntProp(weapon, Prop_Send, "m_bInitialized", 0);
	
	SetHandPos(client, weapon);
	
	DispatchSpawn(weapon);
	ActivateEntity(weapon);
	
	g_Weapon[client] = weapon;
	
	// Weapon entity end ^
}

void RemoveWeapon(client)
{	
	if(IsValidEntity(g_Weapon[client]))
	{
		char classname[32];
		GetEdictClassname(g_Weapon[client], classname, sizeof(classname));
		if(StrEqual(classname, "tf_dropped_weapon", false))
		{
			AcceptEntityInput(g_Weapon[client], "kill");
		}
		g_Weapon[client] = INVALID_ENT_REFERENCE;
	}
}

stock WeaponAttackAvailable(cl, bool boolean) {
	int slotP = GetPlayerWeaponSlot(cl, 0);
	int slotS = GetPlayerWeaponSlot(cl, 1);
	int slotM = GetPlayerWeaponSlot(cl, 2);
	
	if (IsValidEntity(slotP))
	{
		SetEntPropFloat(slotP, Prop_Data, "m_flNextPrimaryAttack", boolean ? GetGameTime()+3 : GetGameTime() + 86400.0);
		SetEntPropFloat(slotP, Prop_Data, "m_flNextSecondaryAttack", boolean ? GetGameTime()+3 : GetGameTime() + 86400.0);
	}
	if (IsValidEntity(slotS))
	{
		SetEntPropFloat(slotS, Prop_Data, "m_flNextPrimaryAttack", boolean ? GetGameTime()+3 : GetGameTime() + 86400.0);
		SetEntPropFloat(slotS, Prop_Data, "m_flNextSecondaryAttack", boolean ? GetGameTime()+3 : GetGameTime() + 86400.0);
	}
	if (IsValidEntity(slotM))
	{
		SetEntPropFloat(slotM, Prop_Data, "m_flNextPrimaryAttack", boolean ? GetGameTime()+3 : GetGameTime() + 86400.0);
		SetEntPropFloat(slotM, Prop_Data, "m_flNextSecondaryAttack", boolean ? GetGameTime()+3 : GetGameTime() + 86400.0);
	}
	if (IsValidEntity(GetEntPropEnt( cl, Prop_Send, "m_hActiveWeapon" ))  ) {
		SetEntPropFloat(GetEntPropEnt(cl, Prop_Send, "m_hActiveWeapon"), Prop_Data, "m_flNextSecondaryAttack", boolean ? GetGameTime()+3 : GetGameTime() + 86400.0)
	}
}

SetHandPos(client, entity)
{
	float Position[3];
	float Angles[3];
	
	GetClientAbsOrigin(client, Position);
	GetClientEyeAngles(client, Angles);
	
	static char name[PLATFORM_MAX_PATH+1];
	GetEntPropString(client, Prop_Data, "m_iName", name, sizeof(name));
	if (!name[0])
	{
		char init_name[64];
		Format(init_name, sizeof(init_name), "client_%i", GetClientUserId(client))
		
		DispatchKeyValue(client, "targetname", init_name);
		name = init_name;
	}
	TeleportEntity(entity, Position, NULL_VECTOR, NULL_VECTOR);
	
	SetVariantString(name);
	AcceptEntityInput(entity, "SetParent", -1, -1);
	SetVariantString("effect_hand_r");
	AcceptEntityInput(entity, "SetParentAttachment", -1, -1);
	
	AcceptEntityInput(entity, "ClearParent", -1, -1);
	
	TeleportEntity(entity, NULL_VECTOR, Angles, NULL_VECTOR);
}

bool IsValidClient(client, bool replaycheck = true)
{
	if (!IsValidEntity(client)) return false;
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (GetEntProp(client, Prop_Send, "m_bIsCoaching")) return false;
	if (replaycheck)
	{
		if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	}
	return true;
}

bool TF2_IsPlayerAlive(client)
{
	if (!IsValidClient(client)) return false;
	if (!IsPlayerAlive(client)) return false;
	if (TF2_IsPlayerInCondition(client, TFCond_HalloweenGhostMode)) return false;
	return true;
}