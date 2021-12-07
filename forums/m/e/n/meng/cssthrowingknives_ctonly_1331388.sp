#include <sourcemod>
#include <sdktools>

#define NAME "CSS Throwing Knives"
#define VERSION "1.1.3"
#define KNIFE_MDL "models/weapons/w_knife_ct.mdl"
#define KNIFEHIT_SOUND "weapons/knife/knife_hit3.wav"
#define TRAIL_MDL "materials/sprites/lgtning.vmt"
#define TRAIL_COLOR {177, 177, 177, 117}
#define ADD_OUTPUT "OnUser1 !self:Kill::1.7:1"

new Handle:g_CVarEnable;
new Handle:g_hLethalArray;
new Handle:g_CVarVelocity;
new Float:g_fVelocity;
new Handle:g_CVarKnives;
new Handle:g_CVarDamage;
new String:g_sDamage[8];
new Handle:g_CVarHSDamage;
new String:g_sHSDamage[8];
new Handle:g_CVarSteal;
new Handle:g_CVarTrail;
new bool:g_bTrail;
new Handle:g_CVarNoBlock;
new bool:g_bNoBlock;
new Handle:g_CVarFF;
new const Float:g_fSpin[3] = {1877.4, 0.0, 0.0};
new const Float:g_fMinS[3] = {-16.0, -16.0, -16.0};
new const Float:g_fMaxS[3] = {16.0, 16.0, 16.0};
new g_iKnives[MAXPLAYERS+1];
new g_iKnifeMI;
new g_iPointHurt;
new g_iEnvBlood;
new g_iTrailMI;

public Plugin:myinfo = {

	name = NAME,
	author = "meng",
	version = VERSION,
	description = "Throwing knives for CSS",
	url = "http://www.sourcemod.net"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) {

	CreateNative("SetClientThrowingKnives", NativeSetClientThrowingKnives);
	RegPluginLibrary("cssthrowingknives");
	return APLRes_Success;
}

public OnPluginStart() {

	CreateConVar("sm_cssthrowingknives", VERSION, NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_CVarEnable = CreateConVar("sm_throwingknives_enable", "1", "Enable/disable plugin.", _, true, 0.0, true, 1.0);
	g_CVarVelocity = CreateConVar("sm_throwingknives_velocity", "5", "Velocity (speed) adjustment.", _, true, 1.0, true, 10.0);
	g_CVarKnives = CreateConVar("sm_throwingknives_count", "3", "Amount of knives players spawn with.", _, true, 0.0, true, 100.0);
	g_CVarDamage = CreateConVar("sm_throwingknives_damage", "57", "Damage adjustment.", _, true, 20.0, true, 200.0);
	g_CVarHSDamage = CreateConVar("sm_throwingknives_hsdamage", "127", "Headshot damage adjustment.", _, true, 20.0, true, 200.0);
	g_CVarSteal = CreateConVar("sm_throwingknives_steal", "1", "0 = Off 1 = Knife kill gets the victims remaining knives.", _, true, 0.0, true, 1.0);
	g_CVarTrail = CreateConVar("sm_throwingknives_trail", "0", "Enable/disable trail effect.", _, true, 0.0, true, 1.0);
	g_CVarNoBlock = CreateConVar("sm_throwingknives_noblock", "0", "Set to \"1\" if using noblock for players.", _, true, 0.0, true, 1.0);
	g_CVarFF = FindConVar("mp_friendlyfire");

	HookConVarChange(g_CVarEnable, CVarChange);
	g_fVelocity = (1000.0 + (250.0 * GetConVarFloat(g_CVarVelocity)));
	HookConVarChange(g_CVarVelocity, CVarChange);
	GetConVarString(g_CVarDamage, g_sDamage, sizeof(g_sDamage));
	HookConVarChange(g_CVarDamage, CVarChange);
	GetConVarString(g_CVarHSDamage, g_sHSDamage, sizeof(g_sHSDamage));
	HookConVarChange(g_CVarHSDamage, CVarChange);
	g_bTrail = GetConVarBool(g_CVarTrail);
	HookConVarChange(g_CVarTrail, CVarChange);
	g_bNoBlock = GetConVarBool(g_CVarNoBlock);
	HookConVarChange(g_CVarNoBlock, CVarChange);

	AutoExecConfig(true, "throwingknives");

	g_hLethalArray = CreateArray();

	AddNormalSoundHook(NormalSHook:SoundsHook);
	HookEvent("round_start", EventRoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_spawn", EventPlayerSpawn);
	HookEvent("weapon_fire", EventWeaponFire);
	HookEvent("player_death", EventPlayerDeath);
}

public CVarChange(Handle:convar, const String:oldValue[], const String:newValue[]) {

	if ((convar == g_CVarEnable) && (StringToInt(newValue) == 1)) {
		if (g_iPointHurt == -1)
			CreateEnts();
		for (new i = 1; i <= MaxClients; i++)
			g_iKnives[i] = GetConVarInt(g_CVarKnives);
	}
	else if (convar == g_CVarVelocity)
		g_fVelocity = (1000.0 + (250.0 * StringToFloat(newValue)));
	else if (convar == g_CVarDamage)
		strcopy(g_sDamage, sizeof(g_sDamage), newValue);
	else if (convar == g_CVarHSDamage)
		strcopy(g_sHSDamage, sizeof(g_sHSDamage), newValue);
	else if (convar == g_CVarTrail)
		g_bTrail = GetConVarBool(g_CVarTrail);
	else if (convar == g_CVarNoBlock)
		g_bNoBlock = GetConVarBool(g_CVarNoBlock); 
}

public OnMapStart() {

	g_iKnifeMI = PrecacheModel(KNIFE_MDL);
	g_iTrailMI = PrecacheModel(TRAIL_MDL);
	PrecacheSound(KNIFEHIT_SOUND);
}

public EventRoundStart(Handle:event, const String:name[], bool:dontBroadcast) {

	g_iPointHurt = -1;
	g_iEnvBlood = -1;
	ClearArray(g_hLethalArray);
	if (GetConVarBool(g_CVarEnable))
		CreateEnts();
}

public EventPlayerSpawn(Handle:event,const String:name[],bool:dontBroadcast) {

	if (GetConVarBool(g_CVarEnable)) {
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		g_iKnives[client] = GetConVarInt(g_CVarKnives);
	}
}

public EventWeaponFire(Handle:event,const String:name[],bool:dontBroadcast) { /* only fires for primary attack */

	if (GetConVarBool(g_CVarEnable)) {
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		static String:sWeapon[32];
		GetEventString(event, "weapon", sWeapon, sizeof(sWeapon));
		if (!IsFakeClient(client) && StrEqual(sWeapon, "knife") && (g_iKnives[client] > 0) && (GetClientTeam(client) == 3))
			ThrowKnife(client);
	}
}

public EventPlayerDeath(Handle:event,const String:name[],bool:dontBroadcast) {

	if (GetConVarBool(g_CVarEnable) && GetConVarBool(g_CVarSteal)) {
		decl String:sWeapon[32];
		GetEventString(event, "weapon", sWeapon, sizeof(sWeapon));
		if (StrEqual(sWeapon, "knife")) {
			new victim = GetClientOfUserId(GetEventInt(event, "userid"));
			new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
			if ((attacker != 0) && (attacker != victim)) {
				g_iKnives[attacker] = (g_iKnives[attacker] + g_iKnives[victim]);
				PrintHintText(attacker, "Throwing Knives : %i", g_iKnives[attacker]);
			}
		}
	}
}

ThrowKnife(client) {

	static Float:fPos[3], Float:fAng[3], Float:fVel[3];
	GetClientEyePosition(client, fPos);
	/* simple noblock fix. prevent throw if it will spawn inside another client */
	if (g_bNoBlock && IsClientIndex(GetTraceHullEntityIndex(fPos, client)))
		return;
	/* create & spawn entity. set model & owner. set to kill itself OnUser1 */
	new entity = CreateEntityByName("flashbang_projectile");
	if ((entity != -1) && DispatchSpawn(entity)) {
		SetEntityModel(entity, KNIFE_MDL);
		SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
		SetVariantString(ADD_OUTPUT);
		AcceptEntityInput(entity, "AddOutput");
		/* calc & set spawn position, angle, velocity & spin */
		GetClientEyeAngles(client, fAng);
		GetAngleVectors(fAng, fVel, NULL_VECTOR, NULL_VECTOR);
		ScaleVector(fVel, g_fVelocity);
		SetEntPropVector(entity, Prop_Data, "m_vecAngVelocity", g_fSpin);
		SetEntPropFloat(entity, Prop_Send, "m_flElasticity", 0.2);
		/* add to lethal knife array then teleport... */
		PushArrayCell(g_hLethalArray, entity);
		TeleportEntity(entity, fPos, fAng, fVel);
		--g_iKnives[client];
		PrintHintText(client, "Throwing Knives : %i", g_iKnives[client]);
		if (g_bTrail) {
			TE_SetupBeamFollow(entity, g_iTrailMI, 0, 0.7, 7.7, 7.7, 3, TRAIL_COLOR);
			TE_SendToAll();
		}
	}
}

public Action:SoundsHook(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags) {

	if (GetConVarBool(g_CVarEnable) && StrEqual(sample, "weapons/flashbang/grenade_hit1.wav", false)) {
		new index = FindValueInArray(g_hLethalArray, entity);
		if (index != -1) {
			volume = 0.2;
			RemoveFromArray(g_hLethalArray, index); /* delethalize on first "hit" */
			new attacker = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
			static Float:fKnifePos[3], Float:fAttPos[3], Float:fVicEyePos[3];
			GetEntPropVector(entity, Prop_Data, "m_vecOrigin", fKnifePos);
			new victim = GetTraceHullEntityIndex(fKnifePos, attacker);
			if (IsClientIndex(victim) && IsClientInGame(attacker)) {
				RemoveEdict(entity);
				if (GetConVarBool(g_CVarFF) || (GetClientTeam(victim) != GetClientTeam(attacker))) {
					GetClientAbsOrigin(attacker, fAttPos);
					GetClientEyePosition(victim, fVicEyePos);
					EmitAmbientSound(KNIFEHIT_SOUND, fKnifePos, victim, SNDLEVEL_NORMAL, _, 0.7);
					Hurt(victim, attacker, fAttPos, (FloatAbs(fKnifePos[2] - fVicEyePos[2]) < 4.7) ? g_sHSDamage : g_sDamage);
					Bleed(victim);
				}
			}
			else /* didn't hit a player, kill itself in a few moments */
				AcceptEntityInput(entity, "FireUser1");
			return Plugin_Changed;
		}
		else if (GetEntProp(entity, Prop_Send, "m_nModelIndex") == g_iKnifeMI) {
			volume = 0.2;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

GetTraceHullEntityIndex(Float:pos[3], xindex) {

	TR_TraceHullFilter(pos, pos, g_fMinS, g_fMaxS, MASK_SHOT, THFilter, xindex);
	return TR_GetEntityIndex();
}

public bool:THFilter(entity, contentsMask, any:data) {

	return IsClientIndex(entity) && (entity != data);
}

bool:IsClientIndex(index) {

	return (index > 0) && (index <= MaxClients);
}

CreateEnts() {

	if (((g_iPointHurt = CreateEntityByName("point_hurt")) != -1) && DispatchSpawn(g_iPointHurt)) {
		DispatchKeyValue(g_iPointHurt, "DamageTarget", "hurt");
		DispatchKeyValue(g_iPointHurt, "DamageType", "0");
	}
	if (((g_iEnvBlood = CreateEntityByName("env_blood")) != -1) && DispatchSpawn(g_iEnvBlood)) {
		DispatchKeyValue(g_iEnvBlood, "spawnflags", "13");
		DispatchKeyValue(g_iEnvBlood, "amount", "1000");
	}
}

Hurt(victim, attacker, Float:attackerPos[3], String:damage[]) {

	if (IsValidEntity(g_iPointHurt)) {
		DispatchKeyValue(victim, "targetname", "hurt");
		DispatchKeyValue(g_iPointHurt, "Damage", damage);
		DispatchKeyValue(g_iPointHurt, "classname", "weapon_knife");
		TeleportEntity(g_iPointHurt, attackerPos, NULL_VECTOR, NULL_VECTOR);
		AcceptEntityInput(g_iPointHurt, "Hurt", attacker);
		DispatchKeyValue(g_iPointHurt, "classname", "point_hurt");
		DispatchKeyValue(victim, "targetname", "nohurt");
	}
}

Bleed(client) {

	if (IsValidEntity(g_iEnvBlood))
		AcceptEntityInput(g_iEnvBlood, "EmitBlood", client);
}

public NativeSetClientThrowingKnives(Handle:plugin, numParams) {

	new client = GetNativeCell(1);
	new num = GetNativeCell(2);
	g_iKnives[client] = num;
	if (IsClientInGame(client))
		PrintHintText(client, "Throwing Knives : %i", num);
}