#define PLUGIN_VERSION		"1.1"
#define PLUGIN_PREFIX		"l4d2_"
#define PLUGIN_NAME			"death_bell"
#define PLUGIN_NAME_FULL	"[L4D2] Death Bell - Graves & Music & Death Motivation"
#define PLUGIN_DESCRIPTION	"death motivation, glow graves, death bell music"
#define PLUGIN_AUTHOR		"NoroHime"
#define PLUGIN_LINK			"https://forums.alliedmods.net/showthread.php?t=340537"

/*
 *	v1.0 just released; 24-November-2022
 *	v1.1 delete ConVar *_duration and split to ConVars *_duration_adren / *_duration_music,
 *		fix bell not stop in rare situation; 24-November-2022
 */

#include <sdkhooks>
#include <sourcemod>
#include <sdktools>

//the corpse teleportation
#define PRIVATE_STUFF false

#define IsClient(%1) ((1 <= %1 <= MaxClients) && IsClientInGame(%1))
#define IsEntity(%1) (2048 >= %1 > MaxClients)
#define IsSurvivor(%1) (IsClient(%1) && GetClientTeam(%1) == 2)

public Plugin myinfo = {
	name =			PLUGIN_NAME_FULL,
	author =		PLUGIN_AUTHOR,
	description =	PLUGIN_DESCRIPTION,
	version =		PLUGIN_VERSION,
	url = 			PLUGIN_LINK
};

#define SOUND_BELL			"plats/churchbell_begin_loop.wav"

// Part Graves Taken from Dartz8901
// source thread https://forums.alliedmods.net/showthread.php?p=2793165
char MODELS_GRAVE[][] = {
	// graves
	"models/props_cemetery/grave_01.mdl",
	"models/props_cemetery/grave_02.mdl",
	"models/props_cemetery/grave_03.mdl",
	"models/props_cemetery/grave_04.mdl",
	"models/props_cemetery/grave_06.mdl",
	"models/props_cemetery/grave_07.mdl",

	// avoiding the "Late precache" message on the client console.
	"models/props_cemetery/gibs/grave_02a_gibs.mdl",
	"models/props_cemetery/gibs/grave_02b_gibs.mdl",
	"models/props_cemetery/gibs/grave_02c_gibs.mdl",
	"models/props_cemetery/gibs/grave_02d_gibs.mdl",
	"models/props_cemetery/gibs/grave_02e_gibs.mdl",
	"models/props_cemetery/gibs/grave_02f_gibs.mdl",
	"models/props_cemetery/gibs/grave_02g_gibs.mdl",
	"models/props_cemetery/gibs/grave_02h_gibs.mdl",
	"models/props_cemetery/gibs/grave_02i_gibs.mdl",
	"models/props_cemetery/gibs/grave_03a_gibs.mdl",
	"models/props_cemetery/gibs/grave_03b_gibs.mdl",
	"models/props_cemetery/gibs/grave_03c_gibs.mdl",
	"models/props_cemetery/gibs/grave_03d_gibs.mdl",
	"models/props_cemetery/gibs/grave_03e_gibs.mdl",
	"models/props_cemetery/gibs/grave_03f_gibs.mdl",
	"models/props_cemetery/gibs/grave_03g_gibs.mdl",
	"models/props_cemetery/gibs/grave_03h_gibs.mdl",
	"models/props_cemetery/gibs/grave_03i_gibs.mdl",
	"models/props_cemetery/gibs/grave_03j_gibs.mdl",
	"models/props_cemetery/gibs/grave_06a_gibs.mdl",
	"models/props_cemetery/gibs/grave_06b_gibs.mdl",
	"models/props_cemetery/gibs/grave_06c_gibs.mdl",
	"models/props_cemetery/gibs/grave_06d_gibs.mdl",
	"models/props_cemetery/gibs/grave_06e_gibs.mdl",
	"models/props_cemetery/gibs/grave_06f_gibs.mdl",
	"models/props_cemetery/gibs/grave_06g_gibs.mdl",
	"models/props_cemetery/gibs/grave_06h_gibs.mdl",
	"models/props_cemetery/gibs/grave_06i_gibs.mdl",
	"models/props_cemetery/gibs/grave_07a_gibs.mdl",
	"models/props_cemetery/gibs/grave_07b_gibs.mdl",
	"models/props_cemetery/gibs/grave_07c_gibs.mdl",
	"models/props_cemetery/gibs/grave_07d_gibs.mdl",
	"models/props_cemetery/gibs/grave_07e_gibs.mdl",
	"models/props_cemetery/gibs/grave_07f_gibs.mdl"
};


// Random Color List Taken From from HarryPotter
// source https://github.com/fbef0102/L4D1_2-Plugins/tree/master/l4d_graves

char COLORS[][] = {
	"255 0 0",
	"0 255 0",
	"0 0 255",
	"155 0 255",
	"0 255 255",
	"255 155 0",
	"255 255 255",
	"255 0 150",
	"128 255 0",
	"128 0 0",
	"0 128 128",
	"255 255 0",
	"50 50 50",
}

native void BonusHealing(int client, float amount, int action = 0);

bool isBonusHealingExists = false;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {

	MarkNativeAsOptional("BonusHealing");

	return APLRes_Success; 
}

public void OnAllPluginsLoaded() {
	if( LibraryExists("l4d_bonus_healing") )
		isBonusHealingExists = true;
}

public void OnLibraryAdded(const char[] name) {
	if( strcmp(name, "l4d_bonus_healing") == 0 )
		isBonusHealingExists = true;
}

public void OnLibraryRemoved(const char[] name) {
	if( strcmp(name, "l4d_bonus_healing") == 0 )
		isBonusHealingExists = false;
}

enum {
	GLOW_GRAVES = 1,
	GLOW_CORPSE = 2
}

enum {
	ACTION_TEMP_HEALTH = 0,
	ACTION_HEALTH,
	ACTION_EXTRALIFE,
	ACTION_ADRENALINE
}

enum L4D2GlowType
{
	L4D2Glow_None					= 0,
	L4D2Glow_OnUse					= 1,
	L4D2Glow_OnLookAt				= 2,
	L4D2Glow_Constant				= 3
}

ConVar cDelay;			float flDelay;
ConVar cDurationAdren;	float flDurationAdren;
ConVar cDurationMusic;	float flDurationMusic;
ConVar cMotivation;		int iMotivation;
ConVar cGrave;			bool bGrave;
ConVar cGraveHealth;	char sGraveHealth[16];
ConVar cGravePos;		float flGravePos;
ConVar cGraveGlowColor;	char sGraveGlowColor[32];
ConVar cGraveGlowMin;	char sGraveGlowMin[16];
ConVar cGraveGlowMax;	char sGraveGlowMax[16];
ConVar cGraveFlash;		bool bGraveFlash;

public void OnPluginStart() {

	CreateConVar					(PLUGIN_NAME, PLUGIN_VERSION,				"Version of " ... PLUGIN_NAME_FULL, FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cDelay =			CreateConVar(PLUGIN_NAME ... "_delay", "1.0",			"time to delay spawn grave and death motivation", FCVAR_NOTIFY);
	cDurationAdren =	CreateConVar(PLUGIN_NAME ... "_duration_adren", "13.0",	"duration of death motivation adrenaline time 0=disable", FCVAR_NOTIFY);
	cDurationMusic =	CreateConVar(PLUGIN_NAME ... "_duration_music", "13.0",	"duration of death bell music time 0=disable", FCVAR_NOTIFY);
	cMotivation =		CreateConVar(PLUGIN_NAME ... "_motivation", "-1",		"death motivation range, -1=use *_glow_max 0=disabled death motivation", FCVAR_NOTIFY);
	cGrave =			CreateConVar(PLUGIN_NAME ... "_grave", "1",				"does create the grave 1=yes 0=no", FCVAR_NOTIFY);
	cGraveHealth =		CreateConVar(PLUGIN_NAME ... "_grave_health", "300",	"grave health, leave empty to make un-Solid(no collision)", FCVAR_NOTIFY);
	cGravePos =			CreateConVar(PLUGIN_NAME ... "_grave_pos", "50",		"grave offset position -50=make grave put on legs", FCVAR_NOTIFY);
	cGraveGlowColor =	CreateConVar(PLUGIN_NAME ... "_grave_glow", "-1",		"grave glow color, RGB values, leave empty=disabled glow -1=random color exmaple: '150 0 0'", FCVAR_NOTIFY);
	cGraveGlowMin =		CreateConVar(PLUGIN_NAME ... "_grave_glow_min", "200",	"grave glow min range, gets closer cant see glow", FCVAR_NOTIFY);
	cGraveGlowMax =		CreateConVar(PLUGIN_NAME ... "_grave_glow_max", "800",	"grave glow max range 0=unlimited get farer cant see glow", FCVAR_NOTIFY);
	cGraveFlash =		CreateConVar(PLUGIN_NAME ... "_grave_glow_flash", "1",	"make grave glow flashing", FCVAR_NOTIFY);

	AutoExecConfig(true, PLUGIN_PREFIX ... PLUGIN_NAME);

	cDelay.AddChangeHook(OnConVarChanged);
	cDurationAdren.AddChangeHook(OnConVarChanged);
	cDurationMusic.AddChangeHook(OnConVarChanged);
	cMotivation.AddChangeHook(OnConVarChanged);
	cGrave.AddChangeHook(OnConVarChanged);
	cGraveHealth.AddChangeHook(OnConVarChanged);
	cGravePos.AddChangeHook(OnConVarChanged);
	cGraveGlowColor.AddChangeHook(OnConVarChanged);
	cGraveGlowMin.AddChangeHook(OnConVarChanged);
	cGraveGlowMax.AddChangeHook(OnConVarChanged);
	cGraveFlash.AddChangeHook(OnConVarChanged);

	ApplyCvars();

	HookEvent("player_death", OnPlayerDeath);
	HookEvent("round_start", OnRoundStart, EventHookMode_PostNoCopy)
	
	#if PRIVATE_STUFF
	HookEvent("defibrillator_used_fail", OnDefibrillatorUsedFail);
	#endif
}

public void OnMapStart() {

	for ( int i = 0; i < sizeof(MODELS_GRAVE); i++ )
		PrecacheModel(MODELS_GRAVE[i]);

	PrecacheSound(SOUND_BELL);
}

void ApplyCvars() {

	flDelay = cDelay.FloatValue;


	flDurationAdren = cDurationAdren.FloatValue;
	flDurationMusic = cDurationMusic.FloatValue;

	iMotivation = cMotivation.IntValue;

	if (iMotivation < 0) {

		iMotivation = cGraveGlowMax.IntValue;

		if (iMotivation == 0)
			iMotivation = -1; //unlimited
	}

	bGrave = cGrave.BoolValue;
	cGraveHealth.GetString(sGraveHealth, sizeof(sGraveHealth));
	flGravePos = cGravePos.FloatValue;

	cGraveGlowColor.GetString(sGraveGlowColor, sizeof(sGraveGlowColor));

	cGraveGlowMin.GetString(sGraveGlowMin, sizeof(sGraveGlowMin));
	cGraveGlowMax.GetString(sGraveGlowMax, sizeof(sGraveGlowMax));
	bGraveFlash = cGraveFlash.BoolValue;
}

void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	ApplyCvars();
}
 
public void OnConfigsExecuted() {
	ApplyCvars();
}

Handle timer_stopbell = null;
Handle timer_startbell = null;

void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast) {

	int victim = GetClientOfUserId(event.GetInt("userid"));

	if (IsSurvivor(victim)) {

		StopBell(null);

		if (iMotivation && flDurationAdren)

			for (int i = 1; i <= MaxClients; i++) {
				
				if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i)) {

					if (iMotivation == -1 || GetDistanceByEntities(victim, i) < iMotivation) {

						if (isBonusHealingExists)

							BonusHealing(i, flDurationAdren, ACTION_ADRENALINE);

						else {

							float adrenaline = Terror_GetAdrenalineTime(i);

							if (adrenaline > 0)
								Terror_SetAdrenalineTime(i, adrenaline + flDurationAdren);
							else
								Terror_SetAdrenalineTime(i, flDurationAdren);
						}
					}
				}
			}

		if (flDurationMusic) {

			if (timer_startbell != null)
				delete timer_startbell;

			timer_startbell = CreateTimer(flDelay, StartBell, _, TIMER_FLAG_NO_MAPCHANGE)

			if (timer_stopbell != null)
				delete timer_stopbell;

			timer_stopbell = CreateTimer(flDurationMusic + flDelay, StopBell, _, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

void StopSoundAll(int channel, const char[] sample) {

	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i)) {
			// i dont kown doesnt really needed 4 times stops to doing stop
			StopSound(i, channel, sample);
			StopSound(i, channel, sample);
			StopSound(i, channel, sample);
			StopSound(i, channel, sample);
		}
}

Action StartBell(Handle timer) {

	EmitSoundToAll(SOUND_BELL, SOUND_FROM_PLAYER, SNDCHAN_AUTO);

	timer_startbell = null;

	return Plugin_Stop;
}


Action StopBell(Handle timer) {

	// sound file is looping, must stop manual
	StopSoundAll(SNDCHAN_AUTO, SOUND_BELL);
	EmitSoundToAll(SOUND_BELL, SOUND_FROM_PLAYER, SNDCHAN_AUTO, _, SND_STOPLOOPING);

	timer_stopbell = null;

	return Plugin_Stop;
}

void OnRoundStart(Event event, const char[] name, bool dontBroadcast) {

	if (timer_startbell != null)
		delete timer_startbell;

	if (timer_stopbell != null)
		delete timer_stopbell;

	StopBell(null);
}


int grave_by_corpse [2048];

public void OnEntityCreated(int entity, const char[] classname) {

	if ( strcmp(classname, "survivor_death_model") == 0 ) {

		if (bGrave)
			CreateTimer(flDelay, DelaySpawn, EntIndexToEntRef(entity));
	}

}
public void OnEntityDestroyed(int entity) {

	if (IsEntity(entity) && grave_by_corpse[entity]) {

		int grave = EntRefToEntIndex(grave_by_corpse[entity]);

		if (grave != INVALID_ENT_REFERENCE) {

			RemoveEntity(grave);

			grave_by_corpse[entity] = 0;
		}
	}
}


Action DelaySpawn(Handle timer, int corpse) {

	corpse = EntRefToEntIndex(corpse)

	if (corpse != INVALID_ENT_REFERENCE) {

		int grave = CreateEntityByName("prop_dynamic_override");

		if (grave != INVALID_ENT_REFERENCE) {

			float vOrigin[3], vAngles[3], vOriginGrave[3];

			GetEntPropVector(corpse, Prop_Send, "m_vecOrigin", vOrigin);
			GetEntPropVector(corpse, Prop_Send, "m_angRotation", vAngles);

			MoveForward(vOrigin, vAngles, vOriginGrave, flGravePos);

			// non-empty mean has health
			if (sGraveHealth[0]) {
				//make solid and has health
				DispatchKeyValue(grave, "health", sGraveHealth);
				DispatchKeyValue(grave, "solid", "2");
			} else //make no collision
				DispatchKeyValue(grave, "solid", "0"); 

			// non-empty mean allow glow
			if (sGraveGlowColor[0]) {

				DispatchKeyValue(grave, "glowrange", sGraveGlowMax);
				DispatchKeyValue(grave, "glowrangemin", sGraveGlowMin);
				// -1 make random color
				if (strcmp(sGraveGlowColor, "-1") == 0)
					DispatchKeyValue(grave, "glowcolor", COLORS[ GetRandomInt(0, sizeof(COLORS) - 1) ]);
				else
					DispatchKeyValue(grave, "glowcolor", sGraveGlowColor);

				if (bGraveFlash)
					SetEntProp(grave, Prop_Send, "m_bFlashing", bGraveFlash);
			}

			SetEntityModel(grave, MODELS_GRAVE[GetRandomInt(0, 5)]);
			TeleportEntity(grave, vOriginGrave, vAngles, NULL_VECTOR);
			DispatchSpawn(grave);

			// must start after spawned
			if (sGraveGlowColor[0])
				AcceptEntityInput(grave, "StartGlowing");

			grave_by_corpse[corpse] = EntIndexToEntRef(grave);
		}
	}

	return Plugin_Stop;
}

#if PRIVATE_STUFF
void OnDefibrillatorUsedFail(Event event, const char[] name, bool dontBroadcast) {

	int user = GetClientOfUserId(event.GetInt("userid"));

	int corpse = INVALID_ENT_REFERENCE;

	while ((corpse = FindEntityByClassname(corpse, "survivor_death_model")) != INVALID_ENT_REFERENCE)

		if (IsEntity(corpse) && grave_by_corpse[corpse] && IsClient(user) && GetDistanceByEntities(user, corpse) > 500) {

			int grave = EntRefToEntIndex(grave_by_corpse[corpse]);

			if (grave != INVALID_ENT_REFERENCE) {

				float vOriginClient[3];
				GetEntPropVector(user, Prop_Data, "m_vecOrigin", vOriginClient);

				float vOriginCorpse[3], vAngles[3], vOriginDest[3];

				GetEntPropVector(corpse, Prop_Send, "m_angRotation", vAngles);

				GetEntPropVector(corpse, Prop_Data, "m_vecOrigin", vOriginCorpse);

				MoveForward(vOriginCorpse, vAngles, vOriginDest, flGravePos);

				TeleportEntity(corpse, vOriginClient, NULL_VECTOR, NULL_VECTOR);
				TeleportEntity(grave, vOriginClient, vOriginDest, NULL_VECTOR);

				PrintToChat(user, "Corpse Coming haha");

				return;
			}
		}

}
#endif

float GetDistanceByEntities(int entity1, int entity2) {

	float vOrigin1[3], vOrigin2[3];
	GetEntPropVector(entity1, Prop_Send, "m_vecOrigin", vOrigin1);
	GetEntPropVector(entity2, Prop_Send, "m_vecOrigin", vOrigin2);

	return GetVectorDistance(vOrigin1, vOrigin2);
}

// Vector Function Taken from Silvers
void MoveForward(const float vPos[3], const float vAng[3], float vReturn[3], float fDistance) {
	fDistance *= -1.0;
	float vDir[3];
	GetAngleVectors(vAng, vDir, NULL_VECTOR, NULL_VECTOR);
	vReturn = vPos;
	vReturn[0] += vDir[0] * fDistance;
	vReturn[1] += vDir[1] * fDistance;
}

/////////////////////////////////////////////
// Below Stocks from Left 4 DHooks Direct //
///////////////////////////////////////////

/**
 * Sets the adrenaline effect duration of a survivor.
 *
 * @param iClient		Client index of the survivor.
 * @param flDuration		Duration of the adrenaline effect.
 *
 * @error			Invalid client index.
 **/
// L4D2 only.
void Terror_SetAdrenalineTime(int iClient, float flDuration) {
	// Get CountdownTimer address
	static int timerAddress = -1;
	if(timerAddress == -1)
		timerAddress = FindSendPropInfo("CTerrorPlayer", "m_bAdrenalineActive") - 12;
	
	//timerAddress + 4 = Duration
	//timerAddress + 8 = TimeStamp
	SetEntDataFloat(iClient, timerAddress + 4, flDuration);
	SetEntDataFloat(iClient, timerAddress + 8, GetGameTime() + flDuration);
	SetEntProp(iClient, Prop_Send, "m_bAdrenalineActive", (flDuration <= 0.0 ? 0 : 1), 1);
}

/**
 * Returns the remaining duration of a survivor's adrenaline effect.
 *
 * @param iClient		Client index of the survivor.
 *
 * @return 			Remaining duration or -1.0 if there's no effect.
 * @error			Invalid client index.
 **/
// L4D2 only.
float Terror_GetAdrenalineTime(int iClient) {

	if (!GetEntProp(iClient, Prop_Send, "m_bAdrenalineActive"))
		return -1.0;

	// Get CountdownTimer address
	static int timerAddress = -1;

	if(timerAddress == -1)
		timerAddress = FindSendPropInfo("CTerrorPlayer", "m_bAdrenalineActive") - 12;
	
	//timerAddress + 8 = TimeStamp
	float flGameTime = GetGameTime();
	float flTime = GetEntDataFloat(iClient, timerAddress + 8);
	if(flTime <= flGameTime)
		return -1.0;
	
	return flTime - flGameTime;
}