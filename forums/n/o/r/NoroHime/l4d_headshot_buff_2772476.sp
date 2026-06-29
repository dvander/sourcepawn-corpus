#define PLUGIN_VERSION		"1.1"
#define PLUGIN_NAME			"headshot_buff"
#define PLUGIN_NAME_FULL	"[L4D & L4D2] Headshot Buff / Ding Sounds"
#define PLUGIN_DESCRIPTION	"gain the buff and play reward sound when you doing headshot"
#define PLUGIN_AUTHOR		"NoroHime"
#define PLUGIN_LINK			"https://forums.alliedmods.net/showthread.php?p=2772476"
/**
 *	v1.0 just releases; 26-2-22
 *		now all the idea about kill well done i may wont made more, i have to learn more other
 *	v1.0.1 fix player zombies not works; 28-2-22
 *	v1.0.2 fix issue 'wrong param cause buff time sharing between clients'; 6-June-2022 
 *	v1.0.3 optional *flTtempHurt *flTtempKill to control gives temp hp, prevent trigger on victim survivor; 6-November-2022 
 *	v1.1 new ConVar *_effects_kill to show headshot particle effects on zombie head,
 *		 regular the code styles,
 *		 delete ConVar *_enabled, if needed just unmount the plugin; 6-December-2022
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#define IMPACT_EXPLOSION_AMMO_BODY		"impact_explosive_ammo_small"
#define IMPACT_INCENDIARY_AMMO			"impact_incendiary_generic"

enum {
	EFFECT_SPARKS =		(1 << 0),
	EFFECT_INCENDIARY =	(1 << 1),
	EFFECT_EXPLOSIVE =	(1 << 2),
}

forward void WH_OnMeleeSwing(int client, int weapon, float &speedmodifier);

forward void WH_OnReloadModifier(int client, int weapon, int weapontype, float &speedmodifier);

forward void WH_OnGetRateOfFire(int client, int weapon, int weapontype, float &speedmodifier);

forward void WH_OnDeployModifier(int client, int weapon, int weapontype, float &speedmodifier);

ConVar cDurationHurt;	float flDurationHurt;
ConVar cDurationKill;	float flDurationKill;
ConVar cKeepSwitch;		bool bKeepSwitch;
ConVar cSoundHurt;		char sSoundHurt[64];
ConVar cSoundKill;		char sSoundKill[64];
ConVar cDeathOnly;		bool bDeathOnly;
ConVar cSpeedRate;		float flSpeedRate;
ConVar cBuffActions;	int iBuffActions;
ConVar cTempHurt;		float flTempHurt;
ConVar cTempKill;		float flTempKill;
ConVar cEffectsKill;	int iEffectsKill;

public Plugin myinfo = {
	name =			PLUGIN_NAME_FULL,
	author =		PLUGIN_AUTHOR,
	description =	PLUGIN_DESCRIPTION,
	version =		PLUGIN_VERSION,
	url = 			PLUGIN_LINK
};

public void OnPluginStart() {

	CreateConVar					(PLUGIN_NAME ... "_version", PLUGIN_VERSION,	"Version of 'Headshot Buff'", FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cDurationHurt =		CreateConVar(PLUGIN_NAME ... "_gain_hurt", "0.3",			"buff duration gains of headshot hurt 0:sound only", FCVAR_NOTIFY);
	cDurationKill =		CreateConVar(PLUGIN_NAME ... "_gain_kill", "0.6",			"buff duration gains of headshot killed 0:sound only", FCVAR_NOTIFY);
	cKeepSwitch =		CreateConVar(PLUGIN_NAME ... "_keep", "0",					"keep buff when switch weapon 0:clear 1:keep", FCVAR_NOTIFY);
	cSoundHurt =		CreateConVar(PLUGIN_NAME ... "_sound_hurt",					"ui/littlereward.wav", "which sound wanna play for headshot hurt empty:noplay", FCVAR_NOTIFY);
	cSoundKill =		CreateConVar(PLUGIN_NAME ... "_sound_kill",					"level/bell_normal.wav", "which sound wanna play for headshot kill empty:noplay", FCVAR_NOTIFY);
	cDeathOnly =		CreateConVar(PLUGIN_NAME ... "_death", "0",					"death only, ignore headshot hurt", FCVAR_NOTIFY);
	cSpeedRate =		CreateConVar(PLUGIN_NAME ... "_speed", "1.5",				"buff speed rate 2:double speed", FCVAR_NOTIFY);
	cBuffActions =		CreateConVar(PLUGIN_NAME ... "_actions", "-1",				"buff actions 1=Firing 2=Deploying 4=Reloading 8=MeleeSwinging", FCVAR_NOTIFY);
	cTempHurt =			CreateConVar(PLUGIN_NAME ... "_temp_hurt", "0.16",			"temp health gives when headshot hurt", FCVAR_NOTIFY);
	cTempKill =			CreateConVar(PLUGIN_NAME ... "_temp_kill", "0.33",			"temp health gives when headshot kill", FCVAR_NOTIFY);
	cEffectsKill =		CreateConVar(PLUGIN_NAME ... "_effects_kill", "4",			"which effects show on headshot kill 1=spark 2=incendiary 4=explosive", FCVAR_NOTIFY);

	AutoExecConfig(true, "l4d_" ... PLUGIN_NAME);

	cDurationHurt.AddChangeHook(OnConVarChanged);
	cDurationKill.AddChangeHook(OnConVarChanged);
	cKeepSwitch.AddChangeHook(OnConVarChanged);
	cSoundHurt.AddChangeHook(OnConVarChanged);
	cSoundKill.AddChangeHook(OnConVarChanged);
	cDeathOnly.AddChangeHook(OnConVarChanged);
	cSpeedRate.AddChangeHook(OnConVarChanged);
	cBuffActions.AddChangeHook(OnConVarChanged);
	cTempHurt.AddChangeHook(OnConVarChanged);
	cTempKill.AddChangeHook(OnConVarChanged);
	cEffectsKill.AddChangeHook(OnConVarChanged);


	HookEvent("player_death", OnPlayerDeath);
	HookEvent("infected_hurt", OnInfectedHurt);
	HookEvent("player_hurt", OnInfectedHurt);
	HookEvent("bullet_impact", OnBulletImpact);

	ApplyCvars();
}

public void OnMapStart() {
	PrecacheSounds();
	PrecacheParticle(IMPACT_EXPLOSION_AMMO_BODY);
	PrecacheParticle(IMPACT_INCENDIARY_AMMO);
}

void PrecacheSounds() {

	if (sSoundHurt[0])
		PrecacheSound(sSoundHurt);

	if (sSoundKill[0])
		PrecacheSound(sSoundKill);
}

public void ApplyCvars() {

	flDurationHurt = cDurationHurt.FloatValue;
	flDurationKill = cDurationKill.FloatValue;
	bKeepSwitch = cKeepSwitch.BoolValue;
	cSoundHurt.GetString(sSoundHurt, sizeof(sSoundHurt));
	cSoundKill.GetString(sSoundKill, sizeof(sSoundKill));
	bDeathOnly = cDeathOnly.BoolValue;
	flSpeedRate = cSpeedRate.FloatValue;
	iBuffActions = cBuffActions.IntValue;
	flTempHurt = cTempHurt.FloatValue;
	flTempKill = cTempKill.FloatValue;
	iEffectsKill = cEffectsKill.IntValue;
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {

	ApplyCvars();

	if (convar == cSoundHurt || convar == cSoundKill)
		PrecacheSounds();
}

public void OnConfigsExecuted() {
	ApplyCvars();
}

float buff_remain[MAXPLAYERS + 1];
Handle timer_buff[MAXPLAYERS + 1];

float vImpactLast[3];

void OnBulletImpact(Event event, const char[] name, bool dontBroadcast) {
	vImpactLast[0] = event.GetFloat("x");
	vImpactLast[1] = event.GetFloat("y");
	vImpactLast[2] = event.GetFloat("z");
}

void OnInfectedHurt(Event event, const char[] name, bool dontBroadcast) {

	if (event.GetInt("hitgroup") == 1 && !bDeathOnly) {

		int	attacker = GetClientOfUserId(event.GetInt("attacker")),
			type_damage = event.GetInt("type");

		if ( name[0] == 'p' && isAliveSurvivor(GetClientOfUserId(event.GetInt("userid"))) ) //event player_hurt doesnt hurt zombie
			return;

		if (isAliveSurvivor(attacker) && !(type_damage & DMG_BURN)) {
			
			if (flDurationHurt > 0) {

				buff_remain[attacker] += flDurationHurt;

				if (!timer_buff[attacker])
					timer_buff[attacker] = CreateTimer(1.0, Timer_Countdown, attacker, TIMER_REPEAT);
			}

			if (sSoundHurt[0] && !IsFakeClient(attacker)) 
				EmitSoundToClient(attacker, sSoundHurt, SOUND_FROM_PLAYER);

			if (flTempHurt > 0)
				AddTempHealth(attacker, flTempHurt);
		}
	}
}

void AddTempHealth(int client, float add) {

	float temp = GetTempHealth(client);

	int health = GetClientHealth(client);

	int health_max = GetMaxHealth(client);

	if (health + temp + add >= health_max)
		SetTempHealth(client, float(health_max - health));
	else
		SetTempHealth(client, temp + add);
}

void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast) {

	if (event.GetBool("headshot")) {

		int attacker = GetClientOfUserId(event.GetInt("attacker"));
		int type_damage = event.GetInt("type");

		if (isAliveSurvivor(attacker) && !(type_damage & DMG_BURN)) {

			if (type_damage & DMG_BULLET) {

				if (iEffectsKill & EFFECT_SPARKS) {

					float vAngles[3], vDir[3];
					GetClientEyeAngles(attacker, vAngles);
					GetAngleVectors(vAngles, vDir, NULL_VECTOR, NULL_VECTOR);

					TE_SetupSparks(vImpactLast, vDir, GetRandomInt(1, 2), GetRandomInt(1, 2));
					TE_SendToAll();
				}

				if (iEffectsKill & EFFECT_EXPLOSIVE)
					CreateParticle(IMPACT_EXPLOSION_AMMO_BODY, vImpactLast);

				if (iEffectsKill & EFFECT_INCENDIARY)
					CreateParticle(IMPACT_INCENDIARY_AMMO, vImpactLast);
			}

			if (flDurationKill > 0) {

				buff_remain[attacker] += flDurationKill;

				if (!timer_buff[attacker])
					timer_buff[attacker] = CreateTimer(1.0, Timer_Countdown, attacker, TIMER_REPEAT);
			}

			if (sSoundKill[0] && !IsFakeClient(attacker)) 
				EmitSoundToClient(attacker, sSoundKill, SOUND_FROM_PLAYER);

			if (flTempKill > 0)
				AddTempHealth(attacker, flTempKill);
		}
	}
}

void CreateParticle(const char[] name_particle, float vPos[3]) {

	int particle = CreateEntityByName("info_particle_system");

	if (particle != -1) {

		TeleportEntity(particle, vPos, NULL_VECTOR, NULL_VECTOR);

		DispatchKeyValue(particle, "effect_name", name_particle);
		DispatchKeyValue(particle, "targetname", "particle");

		DispatchSpawn(particle);
		ActivateEntity(particle);

		AcceptEntityInput(particle, "start");

		SetVariantString("OnUser1 !self:Kill::3.0:-1");
		AcceptEntityInput(particle, "AddOutput");
		AcceptEntityInput(particle, "FireUser1");
	}
}

// Taken from Silvers
void PrecacheParticle(const char[] sEffectName) {
	static int table = INVALID_STRING_TABLE;
	if( table == INVALID_STRING_TABLE )
		table = FindStringTable("ParticleEffectNames");
 
	if( FindStringIndex(table, sEffectName) == INVALID_STRING_INDEX ) {
		bool save = LockStringTables(false);
		AddToStringTable(table, sEffectName);
		LockStringTables(save);
	}
}

Action Timer_Countdown(Handle timer, int client) {

	if (buff_remain[client] > 0) {

		buff_remain[client]--;
		return Plugin_Continue;
	}

	timer_buff[client] = null;
	return Plugin_Stop;
}

void StopCountdown(int client) {

	if (timer_buff[client])
		delete timer_buff[client];

	buff_remain[client] = 0.0;

}
public void OnClientPutInServer(int client) {

	SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitchPost);
}

public void OnClientDisconnect_Post(int client) {

	StopCountdown(client);

	SDKUnhook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitchPost);
}

void OnWeaponSwitchPost(int client, int weapon) {

	if (isAliveSurvivor(client) && !bKeepSwitch) 
		StopCountdown(client);
}

enum {
	Firing = 0,
	Deploying,
	Reloading,
	MeleeSwinging
}

public void WH_OnMeleeSwing(int client, int weapon, float &speedmodifier) {
	if (iBuffActions & (1 << MeleeSwinging) && buff_remain[client] > 0)
		speedmodifier *= flSpeedRate;
}

public  void WH_OnReloadModifier(int client, int weapon, int weapontype, float &speedmodifier) {
	if (iBuffActions & (1 << Reloading) && buff_remain[client] > 0)
		speedmodifier *= flSpeedRate;
}

public void WH_OnGetRateOfFire(int client, int weapon, int weapontype, float &speedmodifier) {
	if (iBuffActions & (1 << Firing) && buff_remain[client] > 0)
		speedmodifier *= flSpeedRate;
}

public void WH_OnDeployModifier(int client, int weapon, int weapontype, float &speedmodifier) {
	if (iBuffActions & (1 << Deploying) && buff_remain[client] > 0)
		speedmodifier *= flSpeedRate;
}

/*Stocks below*/

stock bool isAliveSurvivor(int client) {
	return IsClient(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client);
}

stock bool IsClient(int client) {
	return (1 <= client <= MaxClients) && IsClientInGame(client);
}

stock int GetMaxHealth(int client) {

	if (HasEntProp(client, Prop_Send, "m_iMaxHealth"))
		return GetEntProp(client, Prop_Send, "m_iMaxHealth");

	return -1;
}


// ====================================================================================================
//										STOCKS - HEALTH (left4dhooks.sp)
// ====================================================================================================
float GetTempHealth(int client)
{
	static float fPillsDecay = -1.0;

	if (fPillsDecay == -1.0)
		fPillsDecay =  FindConVar("pain_pills_decay_rate").FloatValue;

	float fGameTime = GetGameTime();
	float fHealthTime = GetEntPropFloat(client, Prop_Send, "m_healthBufferTime");
	float fHealth = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	fHealth -= (fGameTime - fHealthTime) * fPillsDecay;
	return fHealth < 0.0 ? 0.0 : fHealth;
}

void SetTempHealth(int client, float fHealth)
{
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", fHealth < 0.0 ? 0.0 : fHealth);
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
}