#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <clientprefs>
#include "morecolors.inc"

#pragma newdecls required
#pragma semicolon 1

#define PLUGIN_VERSION "21w43a"

#define SND_YOUDIDITAGAIN "items/halloween/cat03.wav"
#define COOKIE_BLOCKSTATE "GrapplingHookBlocked"
#define GRAPPLE_COOLDOWN 2.2

#define C_RED "\x07C83232"
#define C_GREEN "\x07489632"

public Plugin myinfo = {
	name = "[TF2] Don't Grapple Me",
	author = "reBane",
	description = "Allows players to disable being grappled",
	version = PLUGIN_VERSION,
	url = "N/A"
}

bool g_blockGrapple[MAXPLAYERS+1];
bool g_blockGrappleRespawn[MAXPLAYERS+1];
bool g_clientInSpawn[MAXPLAYERS+1];
bool g_clientReminded[MAXPLAYERS+1]; //used to print stat on spawn once
int g_warnedDontGrapple[MAXPLAYERS+1];
float g_grappleCooldown[MAXPLAYERS+1];
ArrayList g_hooks;
Handle g_thinkTimer;
ConVar g_cvarBlockAction;
ConVar g_cvarBlockDamage;
int g_blockAction;
int g_blockDamage;
ConVar g_cvarBlockDefault;
Cookie g_cookieBlocked;

public void OnPluginStart() {
	//prep stuff
	if (g_hooks == null)
		g_hooks = new ArrayList();
	else
		g_hooks.Clear();
	g_thinkTimer = CreateTimer(0.15, CheckHooks,_,TIMER_REPEAT);
	Prechache();
	
	//commands
	RegConsoleCmd("sm_dng", Command_ToggleGrapple, "Toggle whether players can grapple you");
	RegConsoleCmd("sm_blockgrapple", Command_ToggleGrapple, "Toggle whether players can grapple you");
	
	//convars
	g_cvarBlockDefault = CreateConVar("sm_blockgrapple_default", "0", "Block player grappling by default (on connect)", 0, true, 0.0, true, 1.0);
	//players are not connection often enough for me to bother with caching cvarBlockDefault
	g_cvarBlockAction = CreateConVar("sm_blockgrapple_action", "0", "How to react to sm_blockgrapple: 0=Instant Toggle, 1=Require respawn, 2=Kill player", 0, true, 0.0, true, 2.0);
	g_cvarBlockDamage = CreateConVar("sm_blockgrapple_damage", "1", "Control grappling hook damage: 0=Allow damage, 1=Block if /dng, 2=Block all damage", 0, true, 0.0, true, 2.0);
	g_cvarBlockAction.AddChangeHook(OnBlockActionChanged);
	g_cvarBlockDamage.AddChangeHook(OnBlockDamageChanged);
	OnBlockActionChanged(g_cvarBlockAction,"","");
	OnBlockDamageChanged(g_cvarBlockDamage,"","");
	
	//cookies
	g_cookieBlocked = new Cookie(COOKIE_BLOCKSTATE, "Save when the player blocked being grappled. Toggle with commands", CookieAccess_Protected);
	
	//hooks
	HookEvent("post_inventory_application", OnClientInventoryRegeneratePost);
	
	//reload handling
	bool blockDefault = g_cvarBlockDefault.BoolValue;
	for (int i=1;i<=MaxClients;i++) {
		if (IsValidClient(i)) {
			g_clientReminded[i] = false;
			if (AreClientCookiesCached(i)) {
				OnClientCookiesCached(i);
			} else { //defaults
				g_blockGrapple[i] = blockDefault;
			}
			RemindClientState(i);
			SDKHookClient(i);
		}
	}
}
public void OnPluginEnd() {
	delete g_thinkTimer;
}
public void OnMapStart() {
	Prechache();
}
static void Prechache() {
	PrecacheSound(SND_YOUDIDITAGAIN);
}

public void OnBlockActionChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	g_blockAction = convar.IntValue;
}
public void OnBlockDamageChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	g_blockDamage = convar.IntValue;
}

//command stuff

public Action Command_ToggleGrapple(int client, int args) {
	if (g_blockAction && !g_clientInSpawn[client]) {
		if (g_blockAction>1) {
			g_blockGrappleRespawn[client] = true;
			ForcePlayerSuicide(client);
		} else {
			g_blockGrappleRespawn[client] = !g_blockGrappleRespawn[client];
		}
		if (g_blockGrappleRespawn[client]) {
			if (g_blockGrapple[client])
				CPrintToChat(client, "[SM] Grappling you will be "...C_GREEN..."enabled\x01 after respawn");
			else
				CPrintToChat(client, "[SM] Grappling you will be "...C_RED..."blocked\x01 after respawn");
		} else {
			PrintToChat(client, "[SM] Do not grapple change cancelled");
		}
	} else {
		ToggleGrapple(client);
	}
	return Plugin_Handled;
}

//handle cookies, no menu tho i think... just save the state

public void OnClientCookiesCached(int client) {
	char val[2];
	if (g_cookieBlocked != INVALID_HANDLE) {
		g_cookieBlocked.Get(client, val, sizeof(val));
		if (val[0]!=0) {
			g_blockGrapple[client] = !!(StringToInt(val));
		} else {
			if ((g_blockGrapple[client] = g_cvarBlockDefault.BoolValue)) {
				g_cookieBlocked.Set(client, "1");
			} else {
				g_cookieBlocked.Set(client, "0");
			}
		}
	} else {
		PrintToServer("Failed to find cookie");
	}
}

//other plugin logic below

public void OnEntityCreated(int entity, const char[] classname) {
	if (StrEqual(classname, "tf_projectile_grapplinghook")) {
		RequestFrame(HookGrapplingHookProjectile, entity);
	} else if (StrEqual(classname, "func_respawnroom", false)) {
		SDKHook(entity, SDKHook_Touch, HookSpawnTouch);
		SDKHook(entity, SDKHook_EndTouch, HookSpawnEndTouch);
	} else if (StrEqual(classname, "player")) {
		SDKHookClient(entity);
	}
}
static void SDKHookClient(int client) {
	SDKHook(client, SDKHook_SpawnPost, OnClientSpawnPost);
	SDKHook(client, SDKHook_OnTakeDamage, OnClientTakeDamage);
}
static Action HookSpawnTouch(int spawn, int client) {
	if (IsValidClient(client) && GetEntProp(spawn, Prop_Send, "m_iTeamNum") == GetClientTeam(client))
		g_clientInSpawn[client] = true;
	return Plugin_Continue;
}
static Action HookSpawnEndTouch(int spawn, int client) {
	if (IsValidClient(client))
		g_clientInSpawn[client] = false;
	return Plugin_Continue;
}
public void OnClientInventoryRegeneratePost(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid", 0));
	OnClientSpawnPost(client);
}
public void OnClientSpawnPost(int client) {
	if (g_blockGrappleRespawn[client]) {
		ToggleGrapple(client);
	}
	RemindClientState(client);
}
public Action OnClientTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3]) {
	if (!g_blockDamage) return Plugin_Continue;
	int widx = (IsValidEntity(weapon) && HasEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex")) 
				? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1;
	return (widx == 1152 && (g_blockDamage == 2 || g_blockGrapple[victim])) ? Plugin_Handled : Plugin_Continue;
}

//ment as a one-time reminder after joining the server
static void RemindClientState(int client) {
	if (!g_clientReminded[client]) {
		CPrintToChat(client, "[SM] \x07C832C8Don't Grapple me\x01 : Currently %s\x01", g_blockGrapple[client]?C_RED..."blocked":C_GREEN..."allowed");
		g_clientReminded[client] = true;
	}
}

static void ToggleGrapple(int client) {
	bool newValue =! g_blockGrapple[client];
	g_blockGrappleRespawn[client] = false;
	g_blockGrapple[client] = newValue;
	
	//notify player :)
	if (newValue) {
		if (g_cookieBlocked != INVALID_HANDLE)
			g_cookieBlocked.Set(client, "1");
		CPrintToChat(client, "[SM] You "...C_RED..."can't\x01 be grappled");
	} else {
		if (g_cookieBlocked != INVALID_HANDLE)
			g_cookieBlocked.Set(client, "0");
		CPrintToChat(client, "[SM] Players "...C_GREEN..."can\x01 grapple you");
	}
}

public void OnClientConnected(int client) {
	g_grappleCooldown[client] = 0.0;
//	g_blockGrapple[client] = g_cvarBlockDefault.BoolValue; //will be set in the cookie cache callback
	g_blockGrappleRespawn[client] = false;
	g_warnedDontGrapple[client] = 0;
	g_clientReminded[client] = false;
}

public Action CheckHooks(Handle timer) {
	int ent;
	for (int i=g_hooks.Length-1; i>=0; i--) {
		ent = EntRefToEntIndex(g_hooks.Get(i));
		if (ent == INVALID_ENT_REFERENCE) {
			g_hooks.Erase(i);
			continue;
		}
		
		int owner = GetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity");
		int parent = GetEntPropEnt(ent, Prop_Data, "m_hMoveParent");
		
		if (IsValidClient(parent) && g_blockGrapple[parent]) {
			if ( GetClientOfUserId( g_warnedDontGrapple[owner] ) == parent ) {
				CPrintToChat(owner, "[SM] "...C_RED..."Stop it\x01, you've been warned!");
				TF2_MakeBleed(owner, owner, 1.5);
				float dir = GetRandomFloat(0.0, 3.141529*2);
				float vec[3];
				vec[0] = Cosine(dir)*160.0;
				vec[1] = Sine(dir)*160.0;
				vec[2] = 512.0;
				TeleportEntity(owner, NULL_VECTOR, NULL_VECTOR, vec);
				EmitSoundToClient(owner, SND_YOUDIDITAGAIN, _, _, _, _, 0.33);
			} else {
				PrintToChat(owner, "[SM] %N does not wish to be grappled", parent);
				g_warnedDontGrapple[owner] = GetClientUserId( parent );
			}
			ForceUnhook(ent);
			g_grappleCooldown[owner] = GetGameTime()+GRAPPLE_COOLDOWN; //prevent double grapple on accident
			g_hooks.Erase(i);
		}
	}
}

static void HookGrapplingHookProjectile(int entity) {
	if (!IsValidEntity(entity)) return; //deleted
	int owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	if (owner != INVALID_ENT_REFERENCE && (1<=owner<=MaxClients)) {
		if (g_grappleCooldown[owner] < GetGameTime())
			g_hooks.Push(EntIndexToEntRef(entity));
		else {
			ForceUnhook(entity);
		}
	}
}

static bool IsValidClient(int entity) {
	return (1<=entity<=MaxClients) && IsClientInGame(entity);
}

static void ForceUnhook(int hook) {
	int hooker = GetEntPropEnt(hook, Prop_Data, "m_hOwnerEntity");
	int hookee = GetEntPropEnt(hook, Prop_Data, "m_hMoveParent");
	AcceptEntityInput(hook, "kill"); //stop grapple
	if (IsValidClient(hooker)) {
		//this will break "quick grapple" in that the grappling hook will stay the active weapon, but eh
		SetEntProp(hooker, Prop_Send, "m_bUsingActionSlot", 0);
		SetEntPropEnt(hooker, Prop_Send, "m_hGrapplingHookTarget", -1);
		RequestFrame(Unhook_AndRemoveConditions_Hooker, hooker);
	}
	if (IsValidClient(hookee)) {
		TF2_MakeBleed(hookee, hooker, 0.0); //removes bleed soon
		RequestFrame(Unhook_AndRemoveConditions_Hookee, hookee);
	}
}
static void Unhook_AndRemoveConditions_Hookee(int hookee) {
	if (!IsValidClient(hookee)) return;
	TF2_RemoveCondition(hookee, TFCond_Bleeding);
	TF2_RemoveCondition(hookee, TFCond_GrapplingHookBleeding);
	TF2_RemoveCondition(hookee, TFCond_GrappledByPlayer);
}
static void Unhook_AndRemoveConditions_Hooker(int hooker) {
	if (!IsValidClient(hooker)) return;
	TF2_RemoveCondition(hooker, TFCond_GrapplingHook);
	TF2_RemoveCondition(hooker, TFCond_GrapplingHookLatched);
	TF2_RemoveCondition(hooker, TFCond_GrappledToPlayer);
	TF2_RemoveCondition(hooker, TFCond_GrapplingHookSafeFall);
}
