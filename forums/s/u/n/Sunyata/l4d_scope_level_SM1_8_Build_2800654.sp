#define PLUGIN_VERSION		"2.3.1"
#define PLUGIN_PREFIX		"l4d_"
#define PLUGIN_NAME			"scope_level"
#define PLUGIN_NAME_FULL	"[L4D & L4D2] Scope Level Adjust"
#define PLUGIN_DESCRIPTION	"adjust scope level using forward and back key"
#define PLUGIN_AUTHOR		"NoroHime + edit by sunyata for l4d1 sm 1.8 build"
#define PLUGIN_LINK			"https://forums.alliedmods.net/showthread.php?t=341112"

/*
 *	v1.0 just released; 1-January-2023
 *	v1.1 new features and fix:
 *		- new ConVar *_hold to control which key hold to adjust scope level or vice versa,
 *		- new ConVar *_inc, *_dec to specify which key to adjust, defaults is forward and back,
 *		- new ConVar *_loop to allow loop zoom level when reached bound level, usually combined use when set *_inc only or *_dec only,
 *		- fix sg552 wrong scope level,
 *		- to cancel zoom dont have to tap zoom key twice anymore; 7-January-2023
 *	v2.0 new features and fixes:
 *		- add ConVar *_cancel to fix scope level wont cancel when reload/shove/jump, this option can use for support '[L4D & L4D2] Unscope Sniper On Shoot' if add 1=attack,
 *		- new ConVar *_fake to allow non-scopable weapon using scope with animation,
 *		- new ConVar *_fake_list to control which weapon allow access *_fake feature,
 *		- new ConVar *_sound to add extra zoom sound when open scope, to fix vanilla game only play on cancel zoom; 13-January-2023
 *	v2.1 new feature and fix:
 *		- support scope adjust hint on pickup available weapon and translation,
 *		- new ConVar *_announce to control pickup hint text position,
 *		- optimize fake scope logic to fix sometime work unexpected,
 *		- version tested on l4d1 and l4d2; 21-January-2023
 *	v2.1.1 fixes:
 *		- fix fake scope features not cancel properly by player being attacked,
 *		- fix *_cancel not included game default behavior keys cause issue; 21-January-2023
 *	v2.2 new features:
 *		- new experimental feature use mouse wheels to adjust level, but these is speculation,
 *		- new ConVar *_wheels to enabled mouse wheels features, 1=increase when failed speculation, 2=decrease,
 *		- fix pick hint message sometime not happen; 22-January-2023
 *	v2.3 new feature:
 *		- add negative value range for *_step, if set -20 will calc FOV as linear scope level automatically by 20%; 27-January-2023
 *	v2.3.1 for fake scope feature: cancel scope when auto-reload or be hurt, to make close to vanilla sniper behavior; 8-February-2023
 */


#include <sdkhooks>
#include <sourcemod>
#include <sdktools>

#define SOUND_ZOOM			"weapons/hunting_rifle/gunother/hunting_rifle_zoom.wav"
#define IsClient(%1)		((1 <= %1 <= MaxClients) && IsClientInGame(%1))
#define IsEntity(%1) (2048 >= %1 > MaxClients)
#define IsSurvivor(%1)		(IsClient(%1) && GetClientTeam(%1) == 2)

public Plugin myinfo = {
	name =			PLUGIN_NAME_FULL,
	author =		PLUGIN_AUTHOR,
	description =	PLUGIN_DESCRIPTION,
	version =		PLUGIN_VERSION,
	url = 			PLUGIN_LINK
};

static const char sWeaponsScopable[][] = 

{
	"weapon_rifle", //Sunyata note - had to add this l4d1 weapon code here for SM 1.8 builds -although its not needed for SM 1.10 build or higher
	"weapon_smg", //Sunyata note - had to add this l4d1 weapon code here for SM 1.8 builds -although its not needed for SM 1.10 build or higher
	"weapon_rifle_sg552",
	"weapon_hunting_rifle",
	"weapon_sniper_military",
	"weapon_sniper_scout",
	"weapon_sniper_awp"
}

static const int iWeaponsDefaultFOV[] = {
	55, 30, 30, 40, 40
}


bool hasTranslations;
bool bLateLoad;

StringMap mapSnipers;

ConVar cStep;		int iStep;
ConVar cMin;		int iMin;
ConVar cMax;		int iMax;
ConVar cHold;		int iHold;
ConVar cInc;		int iInc;
ConVar cDec;		int iDec;
ConVar cLoop;		bool bLoop;
ConVar cCancel;		int iCancel;
ConVar cFake;		int iFake;
ConVar cFakeList;	ArrayList listWeaponFakeList;
ConVar cSound;		bool bSound;
ConVar cAnnounce;	int iAnnounce;
ConVar cWhell;		int iWheel;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {

	if (late)
		bLateLoad = true;

	return APLRes_Success;
}

public void OnPluginStart() {

	CreateConVar			(PLUGIN_NAME, PLUGIN_VERSION,		"Version of " ... PLUGIN_NAME_FULL, FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cStep =		CreateConVar(PLUGIN_NAME ... "_step", "-33",	"zoom animating step, 5=linear fov but weird animating\n-20=calc to linear scope level by 20%", FCVAR_NOTIFY);
	cMin =		CreateConVar(PLUGIN_NAME ... "_min", "1",		"min fov zoom level, less mean see farer, dont suggest less than 1", FCVAR_NOTIFY);
	cMax =		CreateConVar(PLUGIN_NAME ... "_max", "89",		"max fov zoom level, greater mean see nearer\nhigher than 90 will cause 'ultra wide angle' and view can throuth the wall", FCVAR_NOTIFY);
	cHold =		CreateConVar(PLUGIN_NAME ... "_hold", "0",		"hold key to adjust level, negative is reverse logic\n131072=most hold shift -131072=if not hold shift key\nsee more key on /include/entity_prop_stocks.inc", FCVAR_NOTIFY);
	cInc =		CreateConVar(PLUGIN_NAME ... "_inc", "8",		"key to increase level 8=Forward(w) 0=disabled 32=Use(e)", FCVAR_NOTIFY);
	cDec =		CreateConVar(PLUGIN_NAME ... "_dec", "16",		"key to decrease level 16=Back(s), 0=disabled", FCVAR_NOTIFY);
	cLoop =		CreateConVar(PLUGIN_NAME ... "_loop", "1",		"when zoom level reached bound value, reset level to cause loop", FCVAR_NOTIFY);
	cCancel =	CreateConVar(PLUGIN_NAME ... "_cancel", "10242","key to cancel zoom level 2048=shove 8192=reload 1=attack 2=jump", FCVAR_NOTIFY);
	cFake =		CreateConVar(PLUGIN_NAME ... "_fake", "40",		"does enable fake scope on all non-scopable weapon 0=disabled 40=enabled with 40 initial fov", FCVAR_NOTIFY);
	cFakeList =	CreateConVar(PLUGIN_NAME ... "_fake_list", "weapon_rifle,weapon_rifle_m60,weapon_rifle_ak47,weapon_smg,weapon_smg_silenced,weapon_smg_mp5,weapon_rifle_sg552,weapon_rifle_desert",
																"weapon list of fake scope feature, separate by comma, no spaces", FCVAR_NOTIFY);
	cSound =	CreateConVar(PLUGIN_NAME ... "_sound", "1",		"add extra zoom sound when cancel/open zoom, to fix vanilla game only play on some zoom cancel", FCVAR_NOTIFY);
	cAnnounce =	CreateConVar(PLUGIN_NAME ... "_announce", "2",	"announce types 0=dont announce 1=center 2=chat 4=hint. add numbers together you want", FCVAR_NOTIFY);
	cWhell =	CreateConVar(PLUGIN_NAME ... "_wheels", "1",	"expermental feature, speculate mouse wheels to adjust scope level,\nprevent weapon switch, 1=enabled if speculation failed increase level\n2=same as 1 but decrease 0=disabled", FCVAR_NOTIFY);

	HookEvent("weapon_zoom", OnZoom);
	HookEvent("item_pickup", OnItemPickup);

	mapSnipers = new StringMap();
	listWeaponFakeList = new ArrayList(32);

	// build map for snipers
	for (int i = 0; i < sizeof(sWeaponsScopable); i++)
		mapSnipers.SetValue(sWeaponsScopable[i], iWeaponsDefaultFOV[i]);

	AutoExecConfig(true, PLUGIN_PREFIX ... PLUGIN_NAME);

	cStep.AddChangeHook(OnConVarChanged);
	cMin.AddChangeHook(OnConVarChanged);
	cMax.AddChangeHook(OnConVarChanged);
	cHold.AddChangeHook(OnConVarChanged);
	cInc.AddChangeHook(OnConVarChanged);
	cDec.AddChangeHook(OnConVarChanged);
	cLoop.AddChangeHook(OnConVarChanged);
	cCancel.AddChangeHook(OnConVarChanged);
	cFake.AddChangeHook(OnConVarChanged);
	cFakeList.AddChangeHook(OnConVarChanged);
	cSound.AddChangeHook(OnConVarChanged);
	cAnnounce.AddChangeHook(OnConVarChanged);
	cWhell.AddChangeHook(OnConVarChanged);

	ApplyCvars();

	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "translations/" ... PLUGIN_PREFIX ... PLUGIN_NAME ... ".phrases.txt");
	hasTranslations = FileExists(path);

	if (hasTranslations)
		LoadTranslations(PLUGIN_PREFIX ... PLUGIN_NAME ... ".phrases");
	else
		LogError("not translations file %s found yet, please check install guide for %s", PLUGIN_PREFIX ... PLUGIN_NAME ... ".phrases.txt", PLUGIN_NAME_FULL);

	// Late Load
	if (bLateLoad) {

		for (int i = MaxClients + 1; i < 2048; i++)
			if (IsValidEntity(i)) {
				char classname[32];
				GetEntityClassname(i, classname, sizeof(classname));
				OnEntityCreated(i, classname);
			}

		for(int i = 1; i <= MaxClients; i++)
			if(IsClientInGame(i))
				OnClientPutInServer(i);
	}
}

void ApplyCvars() {

	iStep = cStep.IntValue;
	iMin = cMin.IntValue;
	iMax = cMax.IntValue;
	iHold = cHold.IntValue;
	iInc = cInc.IntValue;
	iDec = cDec.IntValue;
	bLoop = cLoop.BoolValue;
	iCancel = cCancel.IntValue;
	iFake = cFake.IntValue;

	listWeaponFakeList.Clear();

	char sBuffer[256], sBufferSub[32][32];
	int size;
	cFakeList.GetString(sBuffer, sizeof(sBuffer));
	size = ExplodeString(sBuffer, ",", sBufferSub, 32, 32);
	for (int i = 0; i < size; i++)
		if (sBufferSub[i][0])
			listWeaponFakeList.PushString(sBufferSub[i]);

	bSound = cSound.BoolValue;
	iAnnounce = cAnnounce.IntValue;
	iWheel = cWhell.IntValue;
}
 
void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	ApplyCvars();
}

public void OnMapStart() {
	PrecacheSound(SOUND_ZOOM);
}

public void OnConfigsExecuted() {
	ApplyCvars();
}

bool bIsScoping [MAXPLAYERS + 1];
bool bIsFakeScoping [MAXPLAYERS + 1];
int iButtonsLast [MAXPLAYERS + 1];

public void OnClientDisconnect_Post(int client) {
	bIsScoping[client] = false;
	bIsFakeScoping[client] = false;
	iButtonsLast[client] = 0;
}

public void OnClientPutInServer(int client) {
	if (!IsFakeClient(client))
		SDKHook(client, SDKHook_WeaponCanUsePost, OnWeaponCanUsePost);
}

void OnItemPickup(Event event, const char[] name, bool dontBroadcast) {

	int client = GetClientOfUserId(event.GetInt("userid"));

	static char name_item[32];

	event.GetString("item", name_item, sizeof(name_item));
	Format(name_item, sizeof(name_item), "weapon_%s", name_item);

	if ( IsSurvivor(client) && !IsFakeClient(client) ) {

		int default_fov;

		if (mapSnipers.GetValue(name_item, default_fov))
			Announce(client, "%t", "AvailableSniper");

		if (listWeaponFakeList.FindString(name_item) != -1)
			Announce(client, "%t", "AvailableFakeScope");
	}
}


void OnWeaponCanUsePost(int client, int weapon) {

	if ( IsClient(client) && IsValidEntity(weapon) ) {

		DataPack data = new DataPack();

		data.WriteCell(GetClientUserId(client));
		data.WriteCell(EntIndexToEntRef(weapon));

		RequestFrame(OnWeaponUseFrame, data);
	}
}

void OnWeaponUseFrame(DataPack data) {

	data.Reset();

	int client = GetClientOfUserId(data.ReadCell()),
		weapon_after = EntRefToEntIndex(data.ReadCell());

	delete data;

	if (IsSurvivor(client) && weapon_after != INVALID_ENT_REFERENCE && weapon_after == GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon")) {

		static char class_after[32];
		GetEdictClassname(weapon_after, class_after, sizeof(class_after));

		int default_fov;

		if (mapSnipers.GetValue(class_after, default_fov))
			Announce(client, "%t", "AvailableSniper");

		if (listWeaponFakeList.FindString(class_after) != -1)
			Announce(client, "%t", "AvailableFakeScope");
	}
}

int IsSniperActived(int client) {

	static char name_weapon[32];

	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

	if (weapon != INVALID_ENT_REFERENCE) {

		GetEntityClassname(weapon, name_weapon, sizeof(name_weapon));

		int default_fov;

		if (mapSnipers.GetValue(name_weapon, default_fov))
			return default_fov
	}
	return 0;
}

public void OnEntityCreated(int entity, const char[] name_entity) {

	if (IsEntity(entity) && listWeaponFakeList.FindString(name_entity) != -1)
		SDKHook(entity, SDKHook_ReloadPost, OnWeaponReload);
}

void OnWeaponReload(int weapon, bool agreed) {

	if (agreed) {

		int owner = GetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity");

		if (owner != INVALID_ENT_REFERENCE && GetEntPropEnt(owner, Prop_Send, "m_hZoomOwner") != INVALID_ENT_REFERENCE)
			CancelScope(owner, true);
	}
}

void OnZoom(Event event, const char[] name, bool dontBroadcast) {

	int client = GetClientOfUserId(event.GetInt("userid"));

	if ( IsClient(client) ) {

		if (bIsFakeScoping[client] || bIsScoping[client])

			CancelScope(client, bSound);

		else {

			bIsFakeScoping[client] = false;
			bIsScoping[client] = true;

			if (bSound)
				EmitSoundToAll(SOUND_ZOOM, client); 
		}
	}
}

void AdjustFOV(client, bool increase, int fov) {

	int step = iStep > 0 ? iStep : RoundToCeil( fov * (float(-iStep) / 100) );

	if (increase) {

		if (fov + step < iMax)
			SetEntProp(client, Prop_Send, "m_iFOV", fov + step);
		else if (bLoop)
			SetEntProp(client, Prop_Send, "m_iFOV", iMin);
		else if (fov != iMax)
			SetEntProp(client, Prop_Send, "m_iFOV", iMax);

	} else {

		if (fov - step > iMin)
			SetEntProp(client, Prop_Send, "m_iFOV", fov - step);
		else if (bLoop)
			SetEntProp(client, Prop_Send, "m_iFOV", iMax);
		else if (fov != iMin)
			SetEntProp(client, Prop_Send, "m_iFOV", iMin);
	}
}

int WeaponsSlotRelation(int client, int weapon_before, int weapon_after) {

	if (weapon_before == weapon_after)
		return 0;

	int slots[5], slot_before, slot_after, availables;

	for (int i = 0; i < sizeof(slots); i++) {

		slots[i] = GetPlayerWeaponSlot(client, i);

		if (slots[i] == weapon_before)
			slot_before = i;

		if (slots[i] == weapon_after)
			slot_after = i;

		if (slots[i] != INVALID_ENT_REFERENCE)
			availables++;
	}

	if (availables > 2) {

		for (int i = 0; i < sizeof(slots); i++) {

			if (slots[i] != INVALID_ENT_REFERENCE) {

				if (slot_after > slot_before && slot_before < i < slot_after)
					return -1;

				if (slot_after < slot_before && slot_after < i < slot_before)
					return 1;
			}
		}

		return slot_after > slot_before ? 1 : -1;
	}

	return 0;
}

void CancelScope(int client, sound) {

	if (sound)
		EmitSoundToAll(SOUND_ZOOM, client); 

	SetEntProp(client, Prop_Send, "m_iFOV", GetEntProp(client, Prop_Send, "m_iDefaultFOV"));
	SetEntPropEnt(client, Prop_Send, "m_hZoomOwner", -1);

	bIsScoping[client] = false;
	bIsFakeScoping[client] = false;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon_switch, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2]) {

	static char name_weapon[32];

	if (bIsScoping[client] || bIsFakeScoping[client]) {

		if (GetEntPropEnt(client, Prop_Send, "m_hZoomOwner") != INVALID_ENT_REFERENCE) {

			int rate = GetEntProp(client, Prop_Send, "m_iFOV");

			// adjusting level
			if ( ( iHold < 0 && !(buttons & -iHold) ) || ( iHold > 0 && buttons & iHold ) || iHold == 0 ) {

				if (buttons & iDec)
					AdjustFOV(client, true, rate);
				else if (buttons & iInc)
					AdjustFOV(client, false, rate);
			}

			// mouse wheel speculation
			if (iWheel && weapon_switch) {

				int weapon_actived = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

				if (weapon_actived != INVALID_ENT_REFERENCE) {

					int switch_offset = WeaponsSlotRelation(client, weapon_actived, weapon_switch);

					if (switch_offset > 0)
						AdjustFOV(client, true, rate);
					else if (switch_offset < 0)
						AdjustFOV(client, false, rate);
					else
						AdjustFOV(client, iWheel != 1, rate);

					weapon_switch = 0;
					iButtonsLast[client] = buttons;
					return Plugin_Changed;
				}
			}

			// game default behavior support
			if ( bIsScoping[client] && (buttons & IN_ZOOM && !(iButtonsLast[client] & IN_ZOOM)) || buttons & iCancel ) {

				int fov = IsSniperActived(client);

				if (fov)
					SetEntProp(client, Prop_Send, "m_iFOV", fov);
			}

			// vanilla scoping simulation
			if ( bIsFakeScoping[client] ) {

				// cancel zoom
				if ( ( buttons & IN_ZOOM && !(iButtonsLast[client] & IN_ZOOM) ) || buttons & iCancel )

					CancelScope(client, true);
			}

		} else

			CancelScope(client, bSound);

	// try scope with non-scopable weapon
	} else if ( iFake > 0 && !bIsFakeScoping[client] && buttons & IN_ZOOM && !(iButtonsLast[client] & IN_ZOOM) && !IsFakeClient(client) ) {
		
		int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

		if (weapon != INVALID_ENT_REFERENCE) {
			
			GetEntityClassname(weapon, name_weapon, sizeof(name_weapon));

			if (listWeaponFakeList.FindString(name_weapon) != -1) {

 				EmitSoundToAll(SOUND_ZOOM, client); 

				SetEntProp(client, Prop_Send, "m_iFOV", iFake);

				bIsScoping[client] = false;
				bIsFakeScoping[client] = true;

				SetEntPropEnt(client, Prop_Send, "m_hZoomOwner", client);
				SetEntPropFloat(client, Prop_Send, "m_flFOVTime", GetGameTime());
				SetEntPropFloat(client, Prop_Send, "m_flFOVRate", 0.3000);
			}
		}
	}

	iButtonsLast[client] = buttons;
	return Plugin_Continue;
}



/////////////////////////////
// Stocks Below     ////////
///////////////////////////

enum {
	ANNOUNCE_CENTER =	(1 << 0),
	ANNOUNCE_CHAT	=	(1 << 1),
	ANNOUNCE_HINT	=	(1 << 2),
}

void Announce(int client, const char[] format, any ...) {

	static float time_announced_last [MAXPLAYERS + 1];

	if (!hasTranslations)
		return;

	static char buffer[254];

	float time = GetEngineTime();

	if (time - time_announced_last[client] < 0.1)
		return;
	else
		time_announced_last[client] = time;

	SetGlobalTransTarget(client);
	VFormat(buffer, sizeof(buffer), format, 3);
	ReplaceColor(buffer, sizeof(buffer));

	if (iAnnounce & ANNOUNCE_CHAT)
		PrintToChat(client, "%s", buffer);

	if (iAnnounce & ANNOUNCE_HINT)
		PrintHintText(client, "%s", buffer);

	if (iAnnounce & ANNOUNCE_CENTER)
		PrintCenterText(client, "%s", buffer);
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