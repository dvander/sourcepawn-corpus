#define PLUGIN_VERSION		"1.3"
#define PLUGIN_NAME			"rider_kick"
#define PLUGIN_NAME_FULL	"[L4D2] Rider Kick"
#define PLUGIN_DESCRIPTION	"jump and kick and explode"
#define PLUGIN_AUTHOR		"NoroHime"
#define PLUGIN_LINK			"https://forums.alliedmods.net/showthread.php?p=2792907"

/*
 *	v1.0 just released; 16-November-2022
 *	v1.0.1 change fall on ground detect to frame by frame, more accuracy; 18-November-2022
 *	v1.1 new ConVar *_air to make kicking can trigger on air, trigger explode even incapped; 23-November-2022
 *	v1.2 make *_key full match mode, you can set 2049(fire and shove) etc make trigger only both pressed; 25-November-2022
 *	v1.3 new features: i dont known why i continuing this plugin
 *		- new command sm_kicks to toggle does enable 'Rider Kick', status will storage on server over clientprefs,
 *		- new ConVar *_access to control who can access command sm_kicks,
 *		- new ConVar *_hurt_air to control does damage res start on kicking, rather than res on explosion only,
 *		- new ConVar *_default to set client default sm_kicks status,
 *		- if *_hurt set to 0 made cant receive damage on kicking included fetal falling camera; 7-December-2022
 */

#include <sdkhooks>
#include <sourcemod>
#include <sdktools>
#include <clientprefs>

#define IsClient(%1) ((1 <= %1 <= MaxClients) && IsClientInGame(%1))
#define IsSurvivor(%1) (IsClient(%1) && GetClientTeam(%1) == 2)
#define IsAliveHumanSurvivor(%1) (IsSurvivor(%1) && !IsFakeClient(%1) && IsPlayerAlive(%1))

forward Action L4D2_OnStagger(int target, int source);
native void L4D2_Charger_ThrowImpactedSurvivor(int victim, int attacker);
native int L4D_DetonateProjectile(int entity);
native int L4D2_GrenadeLauncherPrj(int client, const float vecPos[3], const float vecAng[3]);
native int L4D_PipeBombPrj(int client, const float vecPos[3], const float vecAng[3]);
native int L4D_TankRockPrj(int client, const float vecPos[3], const float vecAng[3]);

bool bLateLoad = false;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {

	MarkNativeAsOptional("L4D2_Charger_ThrowImpactedSurvivor");
	MarkNativeAsOptional("L4D_DetonateProjectile");
	MarkNativeAsOptional("L4D2_GrenadeLauncherPrj");
	MarkNativeAsOptional("L4D_PipeBombPrj");
	MarkNativeAsOptional("L4D_TankRockPrj");

	if (late)
		bLateLoad = true;

	return APLRes_Success; 
}

Cookie ckKickEnables;


public Plugin myinfo = {
	name =			PLUGIN_NAME_FULL,
	author =		PLUGIN_AUTHOR,
	description =	PLUGIN_DESCRIPTION,
	version =		PLUGIN_VERSION,
	url = 			PLUGIN_LINK
};

ConVar cHurt;		float flHurt;
ConVar cKey;		int iKey;
ConVar cType;		int iType;
ConVar cAir;		int bAir;
ConVar cCmdAccess;	int iCmdAccess;
ConVar cHurtAir;	bool bHurtAir;
ConVar cDefault;	int iDefault;

public void OnPluginStart() {

	CreateConVar				(PLUGIN_NAME, PLUGIN_VERSION,			"Version of " ... PLUGIN_NAME_FULL, FCVAR_DONTRECORD|FCVAR_NOTIFY);
	cHurt =			CreateConVar(PLUGIN_NAME ... "_hurt", "1.0",		"damage scale to self of kicking explosion, becareful if set to 0 will prevent all falling damage", FCVAR_NOTIFY);
	cKey =			CreateConVar(PLUGIN_NAME ... "_key", "2049",		"the trigger key when doing jump 32=USE key 2049=(fire+shove) 0=disable 'Rider Kick'\nsee more in entity_prop_stocks.inc", FCVAR_NOTIFY);
	cType =			CreateConVar(PLUGIN_NAME ... "_type", "1",			"explosion type 1=pipe bomb 2=GL grenade 3=rock(funny only)", FCVAR_NOTIFY);
	cAir =			CreateConVar(PLUGIN_NAME ... "_air", "1",			"allow trigger on Air", FCVAR_NOTIFY);
	cCmdAccess =	CreateConVar(PLUGIN_NAME ... "_access", "",			"admin flags to access sm_kicks, toggle kicks enabled.\nf=sm_slay empty=everyone allow. see more on /configs/admin_levels.cfg", FCVAR_NOTIFY);
	cHurtAir =		CreateConVar(PLUGIN_NAME ... "_hurt_air", "1",		"damage res on kicking, rather than res on explosion only", FCVAR_NOTIFY);
	cDefault =		CreateConVar(PLUGIN_NAME ... "_default", "1",		"default client enables, this will reverses all client setting", FCVAR_NOTIFY);

	AutoExecConfig(true, "l4d2_" ... PLUGIN_NAME);

	cHurt.AddChangeHook(OnConVarChanged);
	cKey.AddChangeHook(OnConVarChanged);
	cType.AddChangeHook(OnConVarChanged);
	cAir.AddChangeHook(OnConVarChanged);
	cCmdAccess.AddChangeHook(OnConVarChanged);
	cHurtAir.AddChangeHook(OnConVarChanged);
	cDefault.AddChangeHook(OnConVarChanged);

	HookEvent("player_jump", OnPlayerJump);

	RegConsoleCmd("sm_kicks", CommandKicks, "toggle did enable " ... PLUGIN_NAME_FULL);

	ckKickEnables = new Cookie(PLUGIN_NAME ... "_enables", PLUGIN_NAME_FULL ... "clients cookies", CookieAccess_Protected);

	ApplyCvars();

	if (bLateLoad)
		for (int i = 1; i <= MaxClients; i++)
			if ( IsClientInGame(i) && AreClientCookiesCached(i) )
				OnClientCookiesCached(i);
}

void ApplyCvars() {

	static char flags[32];

	flHurt = cHurt.FloatValue;
	iKey = cKey.IntValue;
	iType = cType.IntValue;
	bAir = cAir.BoolValue;

	cCmdAccess.GetString(flags, sizeof(flags));
	iCmdAccess = flags[0] ? ReadFlagString(flags) : 0;

	bHurtAir = cHurtAir.BoolValue;
	iDefault = cDefault.BoolValue;
}
 
void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	ApplyCvars();
}
 
public void OnConfigsExecuted() {
	ApplyCvars();
}

int iKickEnabled [MAXPLAYERS + 1];
bool kick_activating [MAXPLAYERS + 1];

Action CommandKicks(int client, int args) {

	if ( (1 <= client <= MaxClients) && IsClientInGame(client) ) {

		if (HasPermission(client, iCmdAccess)) {

			iKickEnabled[client] ^= 1;

			ckKickEnables.Set(client, iKickEnabled[client] ? "1" : "0");

			static char announce[32];

			FormatEx(announce, sizeof(announce), "%s%s", PLUGIN_NAME_FULL, iKickEnabled[client] ^ iDefault ? " Enabled" : " Disabled");

			PrintToChat(client, announce);

		} else
			ReplyToCommand(client, "Permission Denied.");
	}

	return Plugin_Handled;
}


bool HasPermission(int client, int flag) {

	int flag_client = GetUserFlagBits(client);

	if (!flag || flag_client & ADMFLAG_ROOT) return true;

	return view_as<bool>(flag_client & flag);
}


public void OnClientCookiesCached(int client) {

	if (IsFakeClient(client))
		return;

	static char setting[2];

	ckKickEnables.Get(client, setting, sizeof(setting));
	iKickEnabled[client] = StringToInt(setting);
}

void StartKicking(int client) {

	if (iKickEnabled[client] ^ iDefault) {

		if (flHurt >= 0 && bHurtAir)
			SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamageKicking);

		kick_activating[client] = true;

		RequestFrame(ExplodeOnFallFrame, GetClientUserId(client));
		L4D2_Charger_ThrowImpactedSurvivor(client, client);
	}
}

void EndKicking(int client) {
	
	kick_activating[client] = false;

	if (flHurt >= 0)
		SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamageKicking);

	kick_activating[client] = false;
}

Action OnPlayerJump(Event event, const char[] name, bool dontBroadcast) {

	int client = GetClientOfUserId(event.GetInt("userid"));

	if (IsAliveHumanSurvivor(client)) {

		int buttons = GetClientButtons(client);

		if (buttons & iKey == iKey && buttons & (IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT) && !kick_activating[client])
			StartKicking(client);
	}
	
	return Plugin_Continue;
}

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2]) {

	if (!bAir)
		return;

	static buttons_last [MAXPLAYERS + 1];

	bool key_preesed = buttons & iKey == iKey && (buttons_last[client] & iKey) != iKey;

	if (key_preesed && !kick_activating[client] && IsAliveHumanSurvivor(client) && buttons & (IN_FORWARD|IN_BACK|IN_MOVELEFT|IN_MOVERIGHT) && !(GetEntityFlags(client) & FL_ONGROUND))
		StartKicking(client);

	buttons_last[client] = buttons;
}


public void OnClientDisconnect_Post(int client) {
	kick_activating[client] = false;
}


void ExplodeOnFallFrame(int client) {

	client = GetClientOfUserId(client);

	if (IsAliveHumanSurvivor(client)) {

		if ( GetEntityFlags(client) & FL_ONGROUND ) {

			if (flHurt >= 0 && !bHurtAir)
				SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamageKicking);

			float vOrigin[3];
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", vOrigin);

			int projectile = -1;

			switch (iType) {
				case 1: projectile = L4D_PipeBombPrj(client, vOrigin, NULL_VECTOR);
				case 2: projectile = L4D2_GrenadeLauncherPrj(client, vOrigin, NULL_VECTOR);
				case 3: projectile = L4D_TankRockPrj(client, vOrigin, NULL_VECTOR);
			}

			if (projectile != -1)
				L4D_DetonateProjectile(projectile);

			EndKicking(client);

		} else
			RequestFrame(ExplodeOnFallFrame, GetClientUserId(client))
	} else
		EndKicking(client);
}

Action OnTakeDamageKicking(int victim, int& attacker, int& inflictor, float& damage, int& damagetype) {

	if (flHurt > 0) {

		damage *= flHurt;
		return Plugin_Changed;
	}
	return Plugin_Handled;
}

public Action L4D_OnFatalFalling(int client, int camera) {

	if (kick_activating[client] && flHurt == 0 && bHurtAir)

		return Plugin_Handled;

	return Plugin_Continue;
}

public Action L4D2_OnStagger(int target, int source) {

	if (1 <= target <= MaxClients && kick_activating[target])

		return Plugin_Handled;

	return Plugin_Continue;
}