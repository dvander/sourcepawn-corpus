// if lemurs had knives,
// they would throw them!

#include <sourcemod>
#include <sdktools>

#define NAME "CSS Throwing Knives"
#define VERSION "1.2.2b-lm"
#define KNIFE_MDL "models/weapons/w_knife_ct.mdl"
#define KNIFEHIT_SOUND "weapons/knife/knife_hit3.wav"
#define TRAIL_MDL "materials/sprites/lgtning.vmt"
#define TRAIL_COLOR {177, 177, 177, 117}
#define ADD_OUTPUT "OnUser1 !self:Kill::1.5:1"
#define COUNT_TXT "Throwing Knives : %i"

new Handle:g_CVarEnable;
new Handle:g_CVarEnableDev;
new bool:g_bDev;
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
new Handle:g_CVarDisplay;
new g_iDisplay;
new Handle:g_CVarFF;
new const Float:g_fSpin[3] = {4877.4, 0.0, 0.0};
new const Float:g_fMinS[3] = {-24.0, -24.0, -24.0};
new const Float:g_fMaxS[3] = {24.0, 24.0, 24.0};
new g_iKnives[MAXPLAYERS+1];
new g_iKnifeMI;
new g_iPointHurt;
new g_iEnvBlood;
new g_iTrailMI;
new Handle:g_hKTForward;
new Handle:g_hKHForward;
new Handle:g_hKKForward;

public Plugin:myinfo = {

	name = NAME,
	author = "meng",
	version = VERSION,
	description = "Throwing knives for CSS",
	url = "http://www.sourcemod.net"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) {

	CreateNative("SetClientThrowingKnives", NativeSetClientThrowingKnives);
	CreateNative("GetClientThrowingKnives", NativeGetClientThrowingKnives);
	RegPluginLibrary("cssthrowingknives");
	return APLRes_Success;
}

public OnPluginStart() {

	CreateConVar("sm_cssthrowingknives", VERSION, NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_CVarEnable = CreateConVar("sm_throwingknives_enable", "1", "Enable/disable plugin.", _, true, 0.0, true, 1.0);
	g_CVarEnableDev = CreateConVar("sm_throwingknives_dev", "0", "Enable/disable dev. mode.", _, true, 0.0, true, 1.0);
	g_CVarVelocity = CreateConVar("sm_throwingknives_velocity", "5", "Velocity (speed) adjustment.", _, true, 1.0, true, 10.0);
	g_CVarKnives = CreateConVar("sm_throwingknives_count", "3", "Amount of knives players spawn with.", _, true, 0.0, true, 100.0);
	g_CVarDamage = CreateConVar("sm_throwingknives_damage", "57", "Damage adjustment.", _, true, 10.0, true, 200.0);
	g_CVarHSDamage = CreateConVar("sm_throwingknives_hsdamage", "127", "Headshot damage adjustment.", _, true, 20.0, true, 200.0);
	g_CVarSteal = CreateConVar("sm_throwingknives_steal", "1", "If enabled, knife kills get the victims remaining knives. 0 = Disabled | 1 = Melee kills only | 2 = All knife kills", _, true, 0.0, true, 2.0);
	g_CVarTrail = CreateConVar("sm_throwingknives_trail", "0", "Enable/disable trail effect.", _, true, 0.0, true, 1.0);
	g_CVarNoBlock = CreateConVar("sm_throwingknives_noblock", "0", "Set to \"1\" if using noblock for players.", _, true, 0.0, true, 1.0);
	g_CVarDisplay = CreateConVar("sm_throwingknives_display", "1", "Knives remaining display location. 1 = Hint | 2 = Key Hint", _, true, 1.0, true, 2.0);
	g_CVarFF = FindConVar("mp_friendlyfire");

	// initialize global vars, hook CVar changes
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
	g_iDisplay = GetConVarInt(g_CVarDisplay);
	HookConVarChange(g_CVarDisplay, CVarChange);
	g_bDev = GetConVarBool(g_CVarEnableDev);
	HookConVarChange(g_CVarEnableDev, CVarChange);

	AutoExecConfig(true, "throwingknives");

	g_hLethalArray = CreateArray();
	g_hKTForward = CreateGlobalForward("OnKnifeThrow", ET_Event, Param_Cell);
	g_hKHForward = CreateGlobalForward("OnKnifeHit", ET_Event, Param_Cell, Param_Cell, Param_Cell);
	g_hKKForward = CreateGlobalForward("OnPostKnifeKill", ET_Event, Param_Cell, Param_Cell, Param_Cell);

	AddNormalSoundHook(NormalSHook:SoundsHook);
	HookEvent("round_start", EventRoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_spawn", EventPlayerSpawn);
	HookEvent("weapon_fire", EventWeaponFire);
	HookEvent("player_death", EventPlayerDeath, EventHookMode_Pre);
//	HookEvent("player_hurt", Event_PlayerHurt);
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
	else if (convar == g_CVarDisplay)
		g_iDisplay = GetConVarInt(g_CVarDisplay);
	else if (convar == g_CVarEnableDev)
		g_bDev = GetConVarBool(g_CVarNoBlock);
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

public EventWeaponFire(Handle:event,const String:name[],bool:dontBroadcast) { // only fires for primary attack

	if (GetConVarBool(g_CVarEnable)) {
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		static String:sWeapon[32];
		GetEventString(event, "weapon", sWeapon, sizeof(sWeapon));
		if (!IsFakeClient(client) && StrEqual(sWeapon, "knife") && (g_iKnives[client] > 0))
			ThrowKnife(client);
	}
}

public Event_PlayerHurt(Handle:event,const String:name[],bool:dontBroadcast)
{
	decl String:sWeapon[32];
	GetEventString(event, "weapon", sWeapon, sizeof(sWeapon));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new dmg_health = GetEventInt(event, "dmg_health");
	new dmg_armor = GetEventInt(event, "dmg_armor");

	if (attacker && !IsFakeClient(attacker)) //StrEqual(sWeapon, "weapon_knife") &&
		PrintCenterText(attacker, "%s Damage: %ihp %ia", sWeapon, dmg_health, dmg_armor);
}


public EventPlayerDeath(Handle:event,const String:name[],bool:dontBroadcast) {

	if (GetConVarBool(g_CVarEnable)) {
		new victim = GetClientOfUserId(GetEventInt(event, "userid"));
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		decl String:sWeapon[32];
		GetEventString(event, "weapon", sWeapon, sizeof(sWeapon));
		new bool:tknife = StrEqual(sWeapon, "tknife");
		new bool:tknifehs = StrEqual(sWeapon, "tknifehs");
		if (tknife || tknifehs) {
			// the event is pre-hooked,
			// setting the weapon string will change the icon used in the kill notification
			SetEventString(event, "weapon", "knife");
			if (g_bDev) {
				Call_StartForward(g_hKKForward);
				Call_PushCell(victim);
				Call_PushCell(attacker);
				Call_PushCell(tknifehs);
				// since i cant prevent the victim from dying at this point,
				// i dont care what the return value is
				Call_Finish();
			}
			if ((GetConVarInt(g_CVarSteal) > 1) && (GetClientTeam(attacker) != GetClientTeam(victim)))
				KnifeCount(attacker, (g_iKnives[attacker] = (g_iKnives[attacker] + g_iKnives[victim])));
		}
		else if (StrEqual(sWeapon, "knife") && (GetConVarInt(g_CVarSteal) > 0) && (GetClientTeam(attacker) != GetClientTeam(victim)))
			KnifeCount(attacker, (g_iKnives[attacker] = (g_iKnives[attacker] + g_iKnives[victim])));
	}
}

ThrowKnife(client) {

	// anybody care if this dude throws a knife?
	if (g_bDev) {
		new value;
		Call_StartForward(g_hKTForward);
		Call_PushCell(client);
		Call_Finish(_:value);
		if (value != 0)
			return;
	}

	static Float:fPos[3], Float:fAng[3], Float:fVel[3], Float:fPVel[3];
	GetClientEyePosition(client, fPos);
	// simple noblock fix. prevent throw if it will spawn inside another client
	if (g_bNoBlock && IsClientIndex(GetTraceHullEntityIndex(fPos, client)))
		return;

	// create & spawn entity. set model & owner. set to kill itself OnUser1
	// calc & set spawn position, angle, velocity & spin
	// add to lethal knife array, teleport, add trial, ...
	new entity = CreateEntityByName("flashbang_projectile");
	if ((entity != -1) && DispatchSpawn(entity)) {
		SetEntityModel(entity, KNIFE_MDL);
		SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
		SetVariantString(ADD_OUTPUT);
		AcceptEntityInput(entity, "AddOutput");
		GetClientEyeAngles(client, fAng);
		GetAngleVectors(fAng, fVel, NULL_VECTOR, NULL_VECTOR);
		ScaleVector(fVel, g_fVelocity);
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", fPVel);
		AddVectors(fVel, fPVel, fVel);
		SetEntPropVector(entity, Prop_Data, "m_vecAngVelocity", g_fSpin);
		SetEntPropFloat(entity, Prop_Send, "m_flElasticity", 0.2);
		PushArrayCell(g_hLethalArray, entity);
		TeleportEntity(entity, fPos, fAng, fVel);
		KnifeCount(client, --g_iKnives[client]);
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
			RemoveFromArray(g_hLethalArray, index); // delethalize on first bounce
			new attacker = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
			static Float:fKnifePos[3], Float:fAttPos[3], Float:fVicEyePos[3];
			GetEntPropVector(entity, Prop_Data, "m_vecOrigin", fKnifePos);
			new victim = GetTraceHullEntityIndex(fKnifePos, attacker);
			if (IsClientIndex(victim) && IsClientInGame(attacker)) {
				RemoveEdict(entity);
				if (GetConVarBool(g_CVarFF) || (GetClientTeam(victim) != GetClientTeam(attacker))) {
					GetClientAbsOrigin(attacker, fAttPos);
					GetClientEyePosition(victim, fVicEyePos);
					EmitAmbientSound(KNIFEHIT_SOUND, fKnifePos, victim, SNDLEVEL_NORMAL, _, 0.8);
					// HURT!
					if (IsValidEntity(g_iPointHurt)) {
						new bool:headShot = (FloatAbs(fKnifePos[2] - fVicEyePos[2]) < 4.7) ? true : false;
						// last chance to stop this thing were doing
						if (g_bDev) {
							new value;
							Call_StartForward(g_hKHForward);
							Call_PushCell(victim);
							Call_PushCell(attacker);
							Call_PushCell(headShot);
							Call_Finish(_:value);
							if (value != 0)
								return Plugin_Changed;
						}
						DispatchKeyValue(victim, "targetname", "hurt");
						DispatchKeyValue(g_iPointHurt, "Damage", (headShot) ? g_sHSDamage : g_sDamage);
						DispatchKeyValue(g_iPointHurt, "classname", (headShot) ? "weapon_tknifehs" : "weapon_tknife");
						TeleportEntity(g_iPointHurt, fAttPos, NULL_VECTOR, NULL_VECTOR);
						AcceptEntityInput(g_iPointHurt, "Hurt", attacker);
						DispatchKeyValue(g_iPointHurt, "classname", "point_hurt");

						AcceptEntityInput(g_iPointHurt, "Kill");
						if (((g_iPointHurt = CreateEntityByName("point_hurt")) != -1) && DispatchSpawn(g_iPointHurt)) {
							DispatchKeyValue(g_iPointHurt, "DamageTarget", "hurt");
							DispatchKeyValue(g_iPointHurt, "DamageType", "0");
						}

						DispatchKeyValue(victim, "targetname", "nohurt");
						SetVariantString("BloodImpact");
						AcceptEntityInput(entity, "DispatchEffect");
						if (IsValidEntity(g_iEnvBlood))
							AcceptEntityInput(g_iEnvBlood, "EmitBlood", victim);
					}
				}
			}
			else // didn't hit a player, kill itself in a few seconds
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

KnifeCount(client, count) {

	if (IsClientInGame(client)) {
		switch (g_iDisplay) {
			case 1: // Hint
				PrintHintText(client, COUNT_TXT, count);
			case 2: { // Key Hint
				static String:sBuffer[64];
				Format(sBuffer, 64, COUNT_TXT, count);
				new Handle:hKHT = StartMessageOne("KeyHintText", client);
				BfWriteByte(hKHT, 1);
				BfWriteString(hKHT, sBuffer);
				EndMessage();
			}
		}
	}
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

public NativeSetClientThrowingKnives(Handle:plugin, numParams) {

	new client = GetNativeCell(1);
	new num = GetNativeCell(2);
	KnifeCount(client, g_iKnives[client] = num);
}

public NativeGetClientThrowingKnives(Handle:plugin, numParams) {

	new client = GetNativeCell(1);
	return g_iKnives[client];
}