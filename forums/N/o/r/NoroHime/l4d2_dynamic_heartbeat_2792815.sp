#define PLUGIN_VERSION		"1.1.3"
#define PLUGIN_NAME			"dynamic_heartbeat"
#define PLUGIN_NAME_FULL	"[L4D2] Dynamic HeartBeat - Music & Screen & Glow"
#define PLUGIN_DESCRIPTION	"Replace HeartBeat to Drums Music, dynamic set black-white screen"
#define PLUGIN_AUTHOR		"NoroHime"
#define PLUGIN_LINK			"https://forums.alliedmods.net/showthread.php?p=2792690"

/*
 *	v1.0 just released; 15-November-2022
 *	v1.1 new ConVar *_music to control does plays drums music when third striked start, robust codes; 15-November-2022 (2nd time)
 *	v1.1.1 fix a negligence about plugin '[L4D2] HeartBeat by Silvers', fix a ConVar description text typo; 16-November-2022
 *	v1.1.2 fix drum music wont stop when spectator dead survivor; 25-November-2022
 *	v1.1.3 fix a rare situation drum music wont stop; 30-November-2022
 */

#include <sdkhooks>
#include <sourcemod>
#include <sdktools>

#define IsClient(%1) ((1 <= %1 <= MaxClients) && IsClientInGame(%1))
#define IsSurvivor(%1) (IsClient(%1) && GetClientTeam(%1) == 2)

native int Heartbeat_GetRevives(int client);

bool isHeartbeatExists = false;

public void OnLibraryAdded(const char[] name) {
	if( strcmp(name, "l4d_heartbeat") == 0 ) {
		isHeartbeatExists = true;
	}
}

public void OnLibraryRemoved(const char[] name) {
	if( strcmp(name, "l4d_heartbeat") == 0 ) {
		isHeartbeatExists = false;
	}
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {

	MarkNativeAsOptional("Heartbeat_GetRevives");

	return APLRes_Success;
}

#define SOUND_DRUM_END		"music/zombat/gatesofhell.wav"
#define SOUND_HEARTBEAT		"player/heartbeatloop.wav"

char MUSIC_DRUMS[][] = {
	"/music/scavenge/level_01_01.wav",
	"/music/scavenge/level_02_01.wav",
	"/music/scavenge/level_03_01.wav",
	"/music/scavenge/level_04_01.wav",
	"/music/scavenge/level_05_01.wav",
	"/music/scavenge/level_06_01.wav",
	"/music/scavenge/level_07_01.wav",
	"/music/scavenge/level_08_01.wav",
	"/music/scavenge/level_09_01.wav",
	"/music/scavenge/level_10_01.wav"
}


public Plugin myinfo = {
	name =			PLUGIN_NAME_FULL,
	author =		PLUGIN_AUTHOR,
	description =	PLUGIN_DESCRIPTION,
	version =		PLUGIN_VERSION,
	url = 			PLUGIN_LINK
};

ConVar cDetect;		int iDetect;
ConVar cReviveMax;	int iReviveMax;
ConVar cStriked;	int iStriked;
ConVar cGlow;		bool bGlow;
ConVar cGlowRange;	int iGlowRange;
ConVar cGlowFlash;	bool bGlowFlash;
ConVar cGlowType;	int iGlowType;
ConVar cHeartbeat;	bool bHeartbeat;
ConVar cMusic;		bool bMusic;

public void OnPluginStart() {

	CreateConVar				(PLUGIN_NAME, PLUGIN_VERSION,			"Version of " ... PLUGIN_NAME_FULL, FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cDetect =		CreateConVar(PLUGIN_NAME ... "_detect", "30",		"interval of frame(s) to detect black-white screen.", FCVAR_NOTIFY);
	cReviveMax =	FindConVar	("survivor_max_incapacitated_count");
	cStriked =		CreateConVar(PLUGIN_NAME ... "_striked", "40",		"only set black-white screen when health less than this value", FCVAR_NOTIFY);
	cGlow =			CreateConVar(PLUGIN_NAME ... "_glow", "1",			"does make glow when gets black-white screen.", FCVAR_NOTIFY);
	cGlowRange =	CreateConVar(PLUGIN_NAME ... "_glow_range", "200",	"max distance to see glow 0=unlimited.", FCVAR_NOTIFY);
	cGlowFlash =	CreateConVar(PLUGIN_NAME ... "_glow_flash", "1",	"does make glow flashing", FCVAR_NOTIFY);
	cGlowType =		CreateConVar(PLUGIN_NAME ... "_glow_type", "2",		"glow type 0=none 2=on look at 3=constant", FCVAR_NOTIFY);
	cHeartbeat =	CreateConVar(PLUGIN_NAME ... "_heartbeat", "0",		"dont prevent game native HeartBeat music\n0=prevent 1=dont change", FCVAR_NOTIFY);
	cMusic =		CreateConVar(PLUGIN_NAME ... "_music", "1",			"does play the drums music when third striked", FCVAR_NOTIFY);

	AutoExecConfig(true, "l4d2_" ... PLUGIN_NAME);

	cDetect.AddChangeHook(OnConVarChanged);
	cReviveMax.AddChangeHook(OnConVarChanged);
	cStriked.AddChangeHook(OnConVarChanged);
	cGlow.AddChangeHook(OnConVarChanged);
	cGlowRange.AddChangeHook(OnConVarChanged);
	cGlowFlash.AddChangeHook(OnConVarChanged);
	cGlowType.AddChangeHook(OnConVarChanged);
	cHeartbeat.AddChangeHook(OnConVarChanged);
	cMusic.AddChangeHook(OnConVarChanged);

	HookEvent("player_hurt", OnPlayerHurt);
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("bot_player_replace", OnBotReplaces);
	HookEvent("player_bot_replace", OnBotReplaces);
	HookEvent("revive_success", OnReviveSuccess);

	ApplyCvars();
}

public void OnMapStart() {

	for (int i = 0; i < sizeof(MUSIC_DRUMS); i++)
		PrecacheSound(MUSIC_DRUMS[i]);

	PrecacheSound(SOUND_DRUM_END);
}

void ApplyCvars() {

	iDetect = cDetect.IntValue;
	iReviveMax = cReviveMax.IntValue;
	iStriked = cStriked.IntValue;
	bGlow = cGlow.BoolValue;
	iGlowRange = cGlowRange.IntValue;
	bGlowFlash = cGlowFlash.BoolValue;
	iGlowType = cGlowType.IntValue;
	bHeartbeat = cHeartbeat.BoolValue;
	bMusic = cMusic.BoolValue;
}
 
void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	ApplyCvars();
}
 
public void OnConfigsExecuted() {
	ApplyCvars();
}

int drum_level[MAXPLAYERS + 1];

void ChangeDrumMuisc(int client, int level) {

	if (level < 0)
		level = 0;

	if (level > sizeof(MUSIC_DRUMS))
		level = sizeof(MUSIC_DRUMS);

	if (IsClient(client)) {
			
		if (drum_level[client]) {

			if (!level) {
				EmitSoundToClient(client, SOUND_DRUM_END, SOUND_FROM_PLAYER);
				EmitSoundToClient(client, MUSIC_DRUMS[drum_level[client] - 1], SOUND_FROM_PLAYER, SNDCHAN_STATIC, _, SND_STOPLOOPING); //stop previous sound
				StopSound(client, SNDCHAN_STATIC, MUSIC_DRUMS[drum_level[client] - 1]);
				drum_level[client] = 0;
			}

			if (level != drum_level[client]) {
				EmitSoundToClient(client, MUSIC_DRUMS[drum_level[client] - 1], SOUND_FROM_PLAYER, SNDCHAN_STATIC, _, SND_STOPLOOPING); //stop previous sound
				StopSound(client, SNDCHAN_STATIC, MUSIC_DRUMS[drum_level[client] - 1]);
			}
		}

		if (sizeof(MUSIC_DRUMS) >= level >= 1 && level != drum_level[client]) {
			EmitSoundToClient(client, MUSIC_DRUMS[level - 1], SOUND_FROM_PLAYER, SNDCHAN_STATIC);
			drum_level[client] = level;
		}
	}
}

public void OnClientDisconnect_Post(int client) {
	drum_level[client] = 0;
}

void OnBotReplaces(Event event, const char[] name, bool dontBroadcast) {

	int client = GetClientOfUserId(event.GetInt("player"));

	if (!bHeartbeat && IsClient(client))
		StopHeartBeat(client);

	if (IsClient(client) && bMusic)
		ChangeDrumMuisc(client, 0);
}

void StopHeartBeat(int client) {
	// must be 4th time to stop
	StopSound(client, SNDCHAN_STATIC, SOUND_HEARTBEAT);
	StopSound(client, SNDCHAN_STATIC, SOUND_HEARTBEAT);
	StopSound(client, SNDCHAN_STATIC, SOUND_HEARTBEAT);
	StopSound(client, SNDCHAN_STATIC, SOUND_HEARTBEAT);
}

void OnReviveSuccess(Event event, const char[] name, bool dontBroadcast) {

	int client = GetClientOfUserId(event.GetInt("subject"));

	if (!bHeartbeat && IsClient(client))
		StopHeartBeat(client);
}


void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast) {

	int client = GetClientOfUserId(event.GetInt("userid"));

	if (IsSurvivor(client)) {

		if (bMusic)
			ChangeDrumMuisc(client, 0);

		if (bGlow)
			L4D2_RemoveEntityGlow(client);

		EmitSoundToClient(client, SOUND_DRUM_END);
	}
}

void OnPlayerHurt(Event event, const char[] name, bool dontBroadcast) {

	int client = GetClientOfUserId(event.GetInt("userid"));

	if (IsSurvivor(client))
		SetSurvivorCorrectBlackNWhite(client);

}

public void OnGameFrame() {

	static skipped = 0;

	if (++skipped > iDetect) {

		for (int client = 1; client <= MaxClients; client++)

			if (IsSurvivor(client)) {

				if (IsPlayerAlive(client)) {

					if (!GetEntProp(client, Prop_Send, "m_isIncapacitated") && !GetEntProp(client, Prop_Send, "m_isHangingFromLedge"))
						SetSurvivorCorrectBlackNWhite(client);

				} else
					L4D2_RemoveEntityGlow(client);
			}

		skipped = 0;
	}
}

bool IsOnBlackNWhiteScreen(int client) {
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_bIsOnThirdStrike"));
}

void SetSurvivorCorrectBlackNWhite(int client) {

	static int white[3] = {255, 255, 255};

	if ( IsGoingToDie(client) ) {

		float health = GetTempHealth(client) + GetClientHealth(client);
		
		if (bMusic)
			ChangeDrumMuisc(client, RoundToCeil(health / sizeof(MUSIC_DRUMS)));

		if ( health <= iStriked ) {

			if (!IsOnBlackNWhiteScreen(client)) {

				if (bGlow)
					L4D2_SetEntityGlow(client, view_as<L4D2GlowType>(iGlowType), iGlowRange, 0, white, bGlowFlash)

				SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 1);
			}

		} else if (IsOnBlackNWhiteScreen(client)) {

			if (bGlow)
				L4D2_RemoveEntityGlow(client);

			SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 0);
		}

	} else {

		if (bMusic)
			ChangeDrumMuisc(client, 0);

		if (bGlow)
			L4D2_RemoveEntityGlow(client);

		SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 0);
	}
}

bool IsGoingToDie(int client) {

	static ConVar Heartbeat_MaxRevives = null;

	if (isHeartbeatExists && Heartbeat_MaxRevives == null)
		Heartbeat_MaxRevives = FindConVar("l4d_heartbeat_revives");

	if (isHeartbeatExists && Heartbeat_MaxRevives != null)
		return Heartbeat_GetRevives(client) == Heartbeat_MaxRevives.IntValue;
	else
		return iReviveMax == GetReviveCount(client);
}

enum L4D2GlowType
{
	L4D2Glow_None					= 0,
	L4D2Glow_OnUse					= 1,
	L4D2Glow_OnLookAt				= 2,
	L4D2Glow_Constant				= 3
}

int GetReviveCount(int client) {
	return isHeartbeatExists ? Heartbeat_GetRevives(client) : L4D_GetPlayerReviveCount(client);
}


// ====================================================================================================
//										STOCKS - HEALTH (left4dhooks.sp, left4dhooks_stocks.inc)
// ====================================================================================================
stock float GetTempHealth(int client)
{
	static ConVar painPillsDecayCvar;
	if (painPillsDecayCvar == null)
	{
		painPillsDecayCvar = FindConVar("pain_pills_decay_rate");
		if (painPillsDecayCvar == null)
		{
			return 0.0;
		}
	}

	float fGameTime = GetGameTime();
	float fHealthTime = GetEntPropFloat(client, Prop_Send, "m_healthBufferTime");
	float fHealth = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	fHealth -= (fGameTime - fHealthTime) * painPillsDecayCvar.FloatValue;
	return fHealth < 0.0 ? 0.0 : fHealth;
}

/**
 * Set entity glow. This is consider safer and more robust over setting each glow property on their own because glow offset will be check first.
 *
 * @param entity		Entity index.
 * @parma type			Glow type.
 * @param range			Glow max range, 0 for unlimited.
 * @param minRange		Glow min range.
 * @param colorOverride	Glow color, RGB.
 * @param flashing		Whether the glow will be flashing.
 * @return				True if glow was set, false if entity does not support glow.
 */
// L4D2 only.
stock bool L4D2_SetEntityGlow(int entity, L4D2GlowType type, int range, int minRange, colorOverride[3], bool flashing)
{
	if (!IsValidEntity(entity))
	{
		return false;
	}

	char netclass[128];
	GetEntityNetClass(entity, netclass, sizeof(netclass));

	int offset = FindSendPropInfo(netclass, "m_iGlowType");

	if (offset < 1)
	{
		return false;
	}

	L4D2_SetEntityGlow_Type(entity, type);
	L4D2_SetEntityGlow_Range(entity, range);
	L4D2_SetEntityGlow_MinRange(entity, minRange);
	L4D2_SetEntityGlow_Color(entity, colorOverride);
	L4D2_SetEntityGlow_Flashing(entity, flashing);
	return true;
}


/**
 * Set entity glow type.
 *
 * @param entity		Entity index.
 * @parma type			Glow type.
 * @noreturn
 * @error				Invalid entity index or entity does not support glow.
 */
// L4D2 only.
stock void L4D2_SetEntityGlow_Type(int entity, L4D2GlowType type)
{
	SetEntProp(entity, Prop_Send, "m_iGlowType", type);
}

/**
 * Set entity glow range.
 *
 * @param entity		Entity index.
 * @parma range			Glow range.
 * @noreturn
 * @error				Invalid entity index or entity does not support glow.
 */
// L4D2 only.
stock void L4D2_SetEntityGlow_Range(int entity, int range)
{
	SetEntProp(entity, Prop_Send, "m_nGlowRange", range);
}

/**
 * Set entity glow min range.
 *
 * @param entity		Entity index.
 * @parma minRange		Glow min range.
 * @noreturn
 * @error				Invalid entity index or entity does not support glow.
 */
// L4D2 only.
stock void L4D2_SetEntityGlow_MinRange(int entity, int minRange)
{
	SetEntProp(entity, Prop_Send, "m_nGlowRangeMin", minRange);
}

/**
 * Set entity glow color.
 *
 * @param entity		Entity index.
 * @parma colorOverride	Glow color, RGB.
 * @noreturn
 * @error				Invalid entity index or entity does not support glow.
 */
// L4D2 only.
stock void L4D2_SetEntityGlow_Color(int entity, int colorOverride[3])
{
	SetEntProp(entity, Prop_Send, "m_glowColorOverride", colorOverride[0] + (colorOverride[1] * 256) + (colorOverride[2] * 65536));
}

/**
 * Set entity glow flashing state.
 *
 * @param entity		Entity index.
 * @parma flashing		Whether glow will be flashing.
 * @noreturn
 * @error				Invalid entity index or entity does not support glow.
 */
// L4D2 only.
stock void L4D2_SetEntityGlow_Flashing(int entity, bool flashing)
{
	SetEntProp(entity, Prop_Send, "m_bFlashing", flashing);
}


/**
 * Removes entity glow.
 *
 * @param entity		Entity index.
 * @return				True if glow was removed, false if entity does not
 *						support glow.
 */
// L4D2 only.
stock bool L4D2_RemoveEntityGlow(int entity)
{
	return view_as<bool>(L4D2_SetEntityGlow(entity, L4D2Glow_None, 0, 0, { 0, 0, 0 }, false));
}


/**
 * Return player current revive count.
 *
 * @param client		Client index.
 * @return				Survivor's current revive count.
 * @error				Invalid client index.
 */
stock int L4D_GetPlayerReviveCount(int client)
{
	return GetEntProp(client, Prop_Send, "m_currentReviveCount");
}