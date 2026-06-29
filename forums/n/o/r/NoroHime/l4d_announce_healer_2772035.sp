#define PLUGIN_VERSION	"1.2.1"
#define PLUGIN_NAME		"l4d_announce_healer"
#define PLUGIN_PHRASES	"l4d_announce_healer.phrases"

/**
 *	v1.0 just releases; 21-2-22
 *	v1.0.1 remove unused code, fix isDying not works; 22-2-22
 *	v1.0.2 
 *		fix issue 'wrong to use GameTime cause cooldown not work on next round'
 *		use OnClientPutInServer to solve client bind multiple listener; 23-2-22
 *	v1.1 add feature: announce adrenaline duration; 28-2-22;
 *	v1.1.1 fix some format error cause multiple announce; 28-2-22
 *	v1.1.2 make announce delay show compatible for thirdparty plugin health changes; 25-April-22
 *	v1.1.3 fix wrong adrenaline duration, thanks to Silvers; 17-October-2022
 *	v1.1.4 add support for Late Load, add support for plugin '[L4D & L4D2] Heartbeat'; 14-November-2022
 *	v1.2 (8-February-2023)
 *		- add support for L4D1
 *		- change dying text to actually third striked
 *		- add ConVar *_aim to control show message when aim to survivor
 *		- allow show survivor health for special infected when aim
 *		- allow special infected health when aim
 *	v1.2.1 (4-June-2023)
 *		- fix andrenaline feature not working by previous change
 */

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#define ANNOUNCE_CENTER	(1 << 0)
#define ANNOUNCE_CHAT	(1 << 1)
#define ANNOUNCE_HINT	(1 << 2)

#define SOUND_READY		"buttons/bell1.wav"
#define SOUND_REJECT	"buttons/button11.wav"

static const char medicine_classes[][] = {
	"pain_pills",
	"adrenaline",
	"defibrillator",
	"first_aid_kit"
};

enum {
	PILLS			= (1 << 0),
	ADRENALINE		= (1 << 1)
}

enum {
	WEAPONID_PILLS 		= 15,
	WEAPONID_ADRENALINE	= 23
}

enum {
	PLAY_READY		= (1 << 0),
	PLAY_FULLED		= (1 << 1)
}

enum {
	PICKUP			= (1 << 0),
	TRANSFERRING	= (1 << 1),
	HEALING			= (1 << 2),
	DEFIBRILLATING	= (1 << 3),
	REVIVED			= (1 << 4),
	PILLS_USED		= (1 << 5),
	ADRENALINE_USED	= (1 << 6),
	MEDIC_SWITCHED	= (1 << 7)
}

enum {
	ALLOW_SI_RECEIVE =	(1 << 0),
	ALLOW_GOT_SI =		(1 << 1),
}

/**
 * @brief Gets the revive count of a client.
 * @remarks Because this plugin overwrites "m_currentReviveCount" netprop in L4D1, this native allows you to get the actual revive count for clients.
 *
 * @param client          Client index to affect.
 *
 * @return                Number or revives
 */
native int Heartbeat_GetRevives(int client);

bool bIsHeartbeatExists, bLateLoad, hasTranslations, bIsLeft4Dead2;

public void OnAllPluginsLoaded() {

	if( LibraryExists("l4d_heartbeat") == true ) {
		bIsHeartbeatExists = true;
	}
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {

	if (late)
		bLateLoad = true;
	bIsLeft4Dead2 = GetEngineVersion() == Engine_Left4Dead2;
	
	MarkNativeAsOptional("Heartbeat_GetRevives");
	return APLRes_Success; 
}


public void OnLibraryAdded(const char[] name) {
	if( strcmp(name, "l4d_heartbeat") == 0 ) {
		bIsHeartbeatExists = true;
	}
}

public void OnLibraryRemoved(const char[] name) {
	if( strcmp(name, "l4d_heartbeat") == 0 ) {
		bIsHeartbeatExists = false;
	}
}


ConVar Enabled;
ConVar Announce_types;		int announce_types;
ConVar Announce_events;		int announce_events;
ConVar Announce_also;		int announce_also;
ConVar Announce_sounds;		int announce_sounds;
ConVar Announce_cooldown;	float announce_cooldown;
ConVar Announce_medicines;	int announce_medicines;
ConVar Announce_aim;		int announce_aim;
ConVar Announce_SI;			int announce_SI;

public Plugin myinfo = {
	name = "[L4D & L4D2] Announce Health",
	author = "NoroHime",
	description = "Info Announce to healer & defiber & reviver & AIMer",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/NoroHime/"
}

public void OnPluginStart() {

	CreateConVar("announce_healer_version", PLUGIN_VERSION, "Version of 'Announce Health for Healer'", FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	Enabled = 			CreateConVar("announce_healer_enabled", "1", "Enabled 'Announce Health for Healer'", FCVAR_NOTIFY);
	Announce_types =	CreateConVar("announce_healer_types", "2", "announce positions 1=center 2=chat 4=hint 7=all. add together you want", FCVAR_NOTIFY);
	Announce_events =	CreateConVar("announce_healer_events", "255", "which event about medicines wanna anounce 1=pickup medicines 2=transfer\n4=healing 8=defib 16=revive 32=used pill 64=use adrenaline 128=switch to medicines 255=all. add together you want", FCVAR_NOTIFY);
	Announce_also =		CreateConVar("announce_healer_also", "28", "which event also announce to be-heal player 2=transfer 4=healing 8=defib 16=revive. 28=all listed. add together you want", FCVAR_NOTIFY);
	Announce_sounds =	CreateConVar("announce_healer_sounds", "3", "which sound wanna play 1=allowed 2=reject 3=all", FCVAR_NOTIFY);
	Announce_cooldown =	CreateConVar("announce_healer_cooldown", "1.5", "cooldown time for announce player info 0:disable", FCVAR_NOTIFY);
	Announce_medicines =CreateConVar("announce_healer_medicines", "11", "which medicine be switched/received/pickup you want to announce 1=pill 2=adrenaline 4=defib 8=first aid 15=all", FCVAR_NOTIFY);
	Announce_aim =		CreateConVar("announce_healer_aim", "30", "when aim to survivor then show the message to AIMer, 30=detect frames, 0=disabled", FCVAR_NOTIFY);
	Announce_SI =		CreateConVar("announce_healer_si", "3", "1=special infected can received health message 2=can got SI health message 3=both", FCVAR_NOTIFY);

	AutoExecConfig(true, PLUGIN_NAME);

	Enabled.AddChangeHook(OnConVarChanged);
	Announce_types.AddChangeHook(OnConVarChanged);
	Announce_events.AddChangeHook(OnConVarChanged);
	Announce_also.AddChangeHook(OnConVarChanged);
	Announce_sounds.AddChangeHook(OnConVarChanged);
	Announce_cooldown.AddChangeHook(OnConVarChanged);
	Announce_medicines.AddChangeHook(OnConVarChanged);
	Announce_aim.AddChangeHook(OnConVarChanged);
	Announce_SI.AddChangeHook(OnConVarChanged);

	PrecacheSound(SOUND_REJECT, false);

	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "translations/%s.txt", PLUGIN_PHRASES);
	hasTranslations = FileExists(path);

	if (hasTranslations)
		LoadTranslations(PLUGIN_PHRASES);
	
	ApplyCvars();

	// Late Load
	if (bLateLoad)
		for(int i = 1; i <= MaxClients; i++)
			if(IsClientInGame(i))
				OnClientPutInServer(i);
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	ApplyCvars();
}

public void OnConfigsExecuted() {
	ApplyCvars();
}

public void ApplyCvars() {

	static bool hooked = false;
	bool enabled = Enabled.BoolValue;

	if (enabled && !hooked) {

		if (bIsLeft4Dead2) {
			
			HookEvent("defibrillator_used_fail", OnDefibFail, EventHookMode_Post);
			HookEvent("adrenaline_used", OnArenalineUsed, EventHookMode_Post);
		}

		HookEvent("heal_begin", OnHealBegin, EventHookMode_Post);
		HookEvent("weapon_given", OnWeaponGiven, EventHookMode_Post);
		HookEvent("pills_used", OnPillsUsed, EventHookMode_Post);
		HookEvent("pills_used_fail", OnPillsUsedFail, EventHookMode_Post);
		HookEvent("revive_success", OnReviveSuccess, EventHookMode_Post);
		HookEvent("item_pickup", OnItemPickup, EventHookMode_Post);

		hooked = true;

	} else if (!enabled && hooked) {

		if (bIsLeft4Dead2) {
			UnhookEvent("adrenaline_used", OnArenalineUsed, EventHookMode_Post);
			UnhookEvent("defibrillator_used_fail", OnDefibFail, EventHookMode_Post);
		}
		
		UnhookEvent("pills_used_fail", OnPillsUsedFail, EventHookMode_Post);
		UnhookEvent("heal_begin", OnHealBegin, EventHookMode_Post);
		UnhookEvent("weapon_given", OnWeaponGiven, EventHookMode_Post);
		UnhookEvent("pills_used", OnPillsUsed, EventHookMode_Post);
		UnhookEvent("revive_success", OnReviveSuccess, EventHookMode_Post);
		UnhookEvent("item_pickup", OnItemPickup, EventHookMode_Post);

		hooked = false;
	}

	announce_types = Announce_types.IntValue;
	announce_events = Announce_events.IntValue;
	announce_also = Announce_also.IntValue;
	announce_sounds = Announce_sounds.IntValue;
	announce_cooldown = Announce_cooldown.FloatValue;
	announce_medicines = Announce_medicines.IntValue;
	announce_aim = Announce_aim.IntValue;
	announce_SI = Announce_SI.IntValue;
}

public void OnGameFrame() {

	if (announce_aim == 0)
		return;

	static int skipped = 0;

	if ( ++skipped > announce_aim ) {

		for (int client = 1; client <= MaxClients; client++)

			if ( IsClientInGame(client) && !IsFakeClient(client) ) {

				static int aim_last[MAXPLAYERS + 1];

				int aimed = GetClientAimTarget(client, true);

				if (aimed != INVALID_ENT_REFERENCE && aim_last[client] == INVALID_ENT_REFERENCE && IsPlayerAlive(client))
					AnnounceHealth(aimed, client);

				aim_last[client] = aimed;
			}

		skipped = 0;
	}
}

public void OnItemPickup(Event event, const char[] name, bool dontBroadcast) {

	static char name_item[32];

	event.GetString("item", name_item, sizeof(name_item));

	int subject = GetClientOfUserId(event.GetInt("userid"));

	if (announce_events & PICKUP && IsAliveSurvivor(subject) && isAllowedMedicine(name_item)) {
		AnnounceHealth(subject, subject);
	}

}

bool isAllowedMedicine(const char[] name) {

	for (int i = 0; i < sizeof(medicine_classes); i++) 
		if ( StrContains(name, medicine_classes[i]) >= 0 && announce_medicines & (1 << i) )
			return true;

	return false;
}

public void OnClientPutInServer(int client) {

	SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitchPost);
}

public void OnWeaponSwitchPost(int client, int weapon) {

	static char name_weapon[32];

	if (IsAliveSurvivor(client) && weapon != INVALID_ENT_REFERENCE) {
		GetEntityClassname(weapon, name_weapon, sizeof(name_weapon));

		if (announce_events & MEDIC_SWITCHED && IsHumanSurvivor(client) && isAllowedMedicine(name_weapon))
			AnnounceHealth(client, client);
	}
}

public void OnArenalineUsed(Event event, const char[] name, bool dontBroadcast) {

	int	healer = GetClientOfUserId(event.GetInt("userid"));

	if (announce_events & ADRENALINE_USED && IsHumanSurvivor(healer))
		AnnounceHealth(healer, healer);
}

public void OnDefibFail(Event event, const char[] name, bool dontBroadcast) {

	int	healer = GetClientOfUserId(event.GetInt("userid")),
		subject = GetClientOfUserId(event.GetInt("subject"));

	if (announce_events & DEFIBRILLATING && IsAliveSurvivor(healer)) {

		AnnounceHealth(subject, healer);

		if (announce_also & DEFIBRILLATING)
			AnnounceHealth(subject, subject);
	}
}

public void OnHealBegin(Event event, const char[] name, bool dontBroadcast) {

	int	healer = GetClientOfUserId(event.GetInt("userid")),
		subject = GetClientOfUserId(event.GetInt("subject"));

	if (announce_events & HEALING && IsAliveSurvivor(healer)) {
		
		AnnounceHealth(subject, healer);

		if (announce_also & HEALING)
			AnnounceHealth(subject, subject);
	}
}


public void OnWeaponGiven(Event event, const char[] name, bool dontBroadcast) {

	int	giver = GetClientOfUserId(event.GetInt("giver")),
		subject = GetClientOfUserId(event.GetInt("userid")),
		weaponclass = event.GetInt("weapon");

	if (announce_events & TRANSFERRING && IsAliveSurvivor(subject))

		switch (weaponclass) {

			case WEAPONID_PILLS : {

				if (announce_medicines & PILLS) {
					AnnounceHealth(subject, giver);

					if (announce_also & TRANSFERRING)
						AnnounceHealth(subject, subject);
				}
			}
			case WEAPONID_ADRENALINE : {

				if (announce_medicines & ADRENALINE) {
					AnnounceHealth(subject, giver);

					if (announce_also & TRANSFERRING)
						AnnounceHealth(subject, subject);
				}
			}
		}
}

public void OnPillsUsed(Event event, const char[] name, bool dontBroadcast) {

	int	healer = GetClientOfUserId(event.GetInt("userid"));

	if (announce_events & PILLS_USED && IsHumanSurvivor(healer))
		AnnounceHealth(healer, healer);
}

public void OnPillsUsedFail(Event event, const char[] name, bool dontBroadcast) {

	int	healer = GetClientOfUserId(event.GetInt("userid"));

	if (announce_events & PILLS_USED && IsHumanSurvivor(healer))
		AnnounceHealth(healer, healer);
}

public void OnReviveSuccess(Event event, const char[] name, bool dontBroadcast) {

	int	healer = GetClientOfUserId(event.GetInt("userid")),
		subject = GetClientOfUserId(event.GetInt("subject"));

	if (announce_events & REVIVED && IsAliveSurvivor(subject)) {

		AnnounceHealth(subject, healer);

		if (announce_also & REVIVED)
			AnnounceHealth(subject, subject);
	}
}

void AnnounceHealth(int client, int receiver) {

	DataPack data = new DataPack();
	data.WriteCell(GetClientUserId(client));
	data.WriteCell(GetClientUserId(receiver));
	data.Reset();

	RequestFrame(AnnounceHealthPost, data);
}

public void AnnounceHealthPost(DataPack data) {

	int client, receiver;

	client = GetClientOfUserId(data.ReadCell());
	receiver = GetClientOfUserId(data.ReadCell());

	delete data;

	static ConVar HealthMax;
	static char buffer[254];
	static float time_announced_last[MAXPLAYERS];

	if (!HealthMax) 
		HealthMax = FindConVar("first_aid_kit_max_heal");

	if (IsClientInGame(client) && IsPlayerAlive(client) && IsClientInGame(receiver)) {

		if (announce_SI & ALLOW_GOT_SI == 0 && GetClientTeam(client) == 3)
			return;

		if (announce_SI & ALLOW_SI_RECEIVE == 0 && GetClientTeam(receiver) == 3)
			return;

		int health = GetClientHealth(client),
			health_buffer = L4D_GetPlayerTempHealth(client),
			revived = bIsHeartbeatExists ? Heartbeat_GetRevives(client) : L4D_GetPlayerReviveCount(client);

		bool isDying = bIsLeft4Dead2 && IsOnBlackNWhiteScreen(client);

		float time = GetEngineTime();

		float adrenaline_duration = bIsLeft4Dead2 ? Terror_GetAdrenalineTime(client) : 0.0;

		if (!hasTranslations) {
			PrintToServer("translation file %s not loaded.", PLUGIN_PHRASES);
			return;
		}

		SetGlobalTransTarget(receiver);

		Format(buffer, sizeof(buffer), "%t%t", "Name", client, "Health", health);

		if (health_buffer > 0 )
			Format(buffer, sizeof(buffer), "%s%t", buffer, "Buffer", health_buffer);

		if (revived > 0)
			Format(buffer, sizeof(buffer), "%s%t", buffer, "Revived", revived);

		if (isDying)
			Format(buffer, sizeof(buffer), "%s%t", buffer, "Dying");

		if (bIsLeft4Dead2 && adrenaline_duration > 0)
			Format(buffer, sizeof(buffer), "%s%t", buffer, "Adrenaline Left", adrenaline_duration);

		if (!announce_cooldown || (time - time_announced_last[receiver]) > announce_cooldown) {

			Announce(receiver, "%s", buffer);
			time_announced_last[receiver] = time;

			if (announce_sounds & PLAY_FULLED && HealthMax && (health + health_buffer) >= (HealthMax.IntValue - 1) )

				EmitSoundToClient(receiver, SOUND_REJECT, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL);

			else if (announce_sounds & PLAY_READY && revived)

				EmitSoundToClient(receiver, SOUND_READY, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
		}
		
	}
}


void Announce(int client, const char[] format, any ...) {

	static char buffer[254];

	SetGlobalTransTarget(client);
	VFormat(buffer, sizeof(buffer), format, 3);
	ReplaceColor(buffer, sizeof(buffer));

	if (IsClient(client)) {

		if (announce_types & ANNOUNCE_CHAT)
			PrintToChat(client, "%s", buffer);

		if (announce_types & ANNOUNCE_HINT)
			PrintHintText(client, "%s", buffer);

		if (announce_types & ANNOUNCE_CENTER)
			PrintCenterText(client, "%s", buffer);
	}
}

void ReplaceColor(char[] message, int maxLen) {

	ReplaceString(message, maxLen, "{white}", "\x01", false);
	ReplaceString(message, maxLen, "{default}", "\x01", false);
	ReplaceString(message, maxLen, "{cyan}", "\x03", false);
	ReplaceString(message, maxLen, "{lightgreen}", "\x03", false);
	ReplaceString(message, maxLen, "{orange}", "\x04", false);
	ReplaceString(message, maxLen, "{olive}", "\x04", false);
	ReplaceString(message, maxLen, "{green}", "\x05", false);
}

bool IsHumanSurvivor(int client) {
	return IsClient(client) && GetClientTeam(client) == 2 && !IsFakeClient(client);
}

bool IsAliveSurvivor(int client) {
	return IsClient(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client);
}

bool IsClient(int client) {
	return (1 <= client <= MaxClients) && IsClientInGame(client);
}

bool IsOnBlackNWhiteScreen(int client) {
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_bIsOnThirdStrike"));
}

// ==================================================
// STOCKS (left4dhooks_stocks.inc)
// ==================================================


/**
 * Return player current revive count.
 *
 * @param client		Client index.
 * @return				Survivor's current revive count.
 * @error				Invalid client index.
 */
int L4D_GetPlayerReviveCount(int client)
{
	return GetEntProp(client, Prop_Send, "m_currentReviveCount");
}


/**
 * Returns player temporarily health.
 *
 * Note: This will not work with mutations or campaigns that alters the decay
 * rate through vscript'ing. If you want to be sure that it works no matter
 * the mutation, you will have to detour the OnGetScriptValueFloat function.
 * Doing so you are able to capture the altered decay rate and calculate the
 * temp health the same way as this function does.
 *
 * @param client		Client index.
 * @return				Player's temporarily health, -1 if unable to get.
 * @error				Invalid client index or unable to find pain_pills_decay_rate cvar.
 */
int L4D_GetPlayerTempHealth(int client)
{
	static ConVar painPillsDecayCvar;
	if (painPillsDecayCvar == null)
	{
		painPillsDecayCvar = FindConVar("pain_pills_decay_rate");
		if (painPillsDecayCvar == null)
		{
			return -1;
		}
	}

	int tempHealth = RoundToCeil(GetEntPropFloat(client, Prop_Send, "m_healthBuffer") - ((GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * painPillsDecayCvar.FloatValue)) - 1;
	return tempHealth < 0 ? 0 : tempHealth;
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
float Terror_GetAdrenalineTime(int iClient)
{
	// Get CountdownTimer address
	static int timerAddress = -1;
	if(timerAddress == -1)
	{
		timerAddress = FindSendPropInfo("CTerrorPlayer", "m_bAdrenalineActive") - 12;
	}
	
	//timerAddress + 8 = TimeStamp
	float flGameTime = GetGameTime();
	float flTime = GetEntDataFloat(iClient, timerAddress + 8);
	if(flTime <= flGameTime)
		return -1.0;

	if (!GetEntProp(iClient, Prop_Send, "m_bAdrenalineActive"))
		return -1.0;
	
	return flTime - flGameTime;
}
