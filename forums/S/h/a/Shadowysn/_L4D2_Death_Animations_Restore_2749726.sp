/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
* [L4D2] Restore Survivor Death Animations
* 
* About : This plugin restores the Survivor Death Animations while
* also fixing the bug where the animations would endlessly loop and
* the survivors would never actually die
* 
* =============================
* ===      Change Log       ===
* =============================
* Version 1.0    2014-09-02  (48 views)
* - Initial Release
* =============================
* Version 1.1    2014-09-05
* - Semi Major code re-write, moved from using a "player_hurt" event hook
*   to SDK_Tools OnTakeDamagePost (Huge thanks to Mr.Zero for that, as he did most of it)
* 
* - Hopefully, there should no longer be any cases were survivors
*   endlessly loop through their death animations and never die
* =============================
* Version 1.3	 2014-09-09
* - Survivors are no longer able to perform any actions while
*   in the middle of their death animations  (except vocalizing under certain circumstances).
* =============================
* Version 1.4    03-25-2015
* - Complete Plugin Rewrite, this plugin no longer uses shitty damage detection!
* - This plugin will now ALWAYS 100% Guarantee work as intended, this is done by the new check
* - The plugin now instead of predicting when you die, it will instead check for clients
*   to see if they are in the dying animation instead, this means now players will only
*   die when the game decides it and this thus removes any and all faulty damage detections
* ==============================
Version 1.5	 	03-29-2015
- Blocked survivors who are in dying animation from attempting to heal or reviving incapped survivors
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
// #include <defibfix>

#pragma newdecls required
#pragma semicolon 1

#define DEBUG 0

#define PLUGIN_NAME "[L4D2] Restore Survivor Death Animations"
#define PLUGIN_AUTHOR "DeathChaos25, Shadowysn"
#define PLUGIN_DESC "Restores the Death Animations for survivors while fixing the bug where the animation would loop endlessly and the survivors would never die."
#define PLUGIN_VERSION "1.8"
#define PLUGIN_URL "https://forums.alliedmods.net/showthread.php?t=247488"
#define PLUGIN_NAME_SHORT "Restore Survivor Death Animations"
#define PLUGIN_NAME_TECH "death_anim_restore"

#define MODEL_NICK		"models/survivors/survivor_gambler.mdl"
#define MODEL_ROCHELLE	"models/survivors/survivor_producer.mdl"
#define MODEL_COACH		"models/survivors/survivor_coach.mdl"
#define MODEL_ELLIS		"models/survivors/survivor_mechanic.mdl"
#define MODEL_BILL		"models/survivors/survivor_namvet.mdl"
#define MODEL_ZOEY		"models/survivors/survivor_teenangst.mdl"
#define MODEL_FRANCIS	"models/survivors/survivor_biker.mdl"
#define MODEL_LOUIS		"models/survivors/survivor_manager.mdl"

#define DEATH_ANIM_STR "ACT_TERROR_DIE_FROM_STAND"

static int g_DeathAnims[8][5];
static bool isAnimsSet = false;

static bool g_bIsSurvivorInDeathAnimation[MAXPLAYERS + 1] = false;

ConVar version_cvar;

public Plugin myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESC,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}

public void OnPluginStart()
{
	char temp_str[64];
	char desc_str[128];
	
	Format(temp_str, sizeof(temp_str), "sm_%s_version", PLUGIN_NAME_TECH);
	Format(desc_str, sizeof(desc_str), "Version of the %s plugin.", PLUGIN_NAME_SHORT);
	version_cvar = CreateConVar(temp_str, PLUGIN_VERSION, desc_str, FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if (version_cvar != null)
		SetConVarString(version_cvar, PLUGIN_VERSION);
	
	if (IsValidEntity(0))
	{
		GetDeathAnims();
	}
	
	SetConVarInt(FindConVar("survivor_death_anims"), 1);
	
	CreateTimer(0.1, TimerUpdate, _, TIMER_REPEAT);
	#if DEBUG
	HookEvent("defibrillator_begin", DefibStart_Event);
	#endif
	//AutoExecConfig(true, "l4d2_death_animations_restore");
	HookEvent("weapon_fire", Event_BlockInputs);
	HookEvent("revive_begin", Event_BlockInputs);
}

public void OnMapStart()
{
	GetDeathAnims();
}

void GetDeathAnims()
{
	if (isAnimsSet) return;
	
	isAnimsSet = true;
	for (int i = 0; i <= 7; i++)
	{
		switch (i)
		{
			case 0:
			{
				g_DeathAnims[i][4] = GetAnimationFromMdl(MODEL_NICK, DEATH_ANIM_STR);
				continue;
			}
			case 1:
			{
				g_DeathAnims[i][4] = GetAnimationFromMdl(MODEL_ROCHELLE, DEATH_ANIM_STR);
				continue;
			}
			case 2:
			{
				g_DeathAnims[i][4] = GetAnimationFromMdl(MODEL_COACH, DEATH_ANIM_STR);
				continue;
			}
			case 3:
			{
				g_DeathAnims[i][4] = GetAnimationFromMdl(MODEL_ELLIS, DEATH_ANIM_STR);
				continue;
			}
			case 4:
			{
				g_DeathAnims[i][4] = GetAnimationFromMdl(MODEL_BILL, DEATH_ANIM_STR);
				continue;
			}
			case 5:
			{
				g_DeathAnims[i][4] = GetAnimationFromMdl(MODEL_ZOEY, DEATH_ANIM_STR);
				continue;
			}
			case 6:
			{
				g_DeathAnims[i][4] = GetAnimationFromMdl(MODEL_FRANCIS, DEATH_ANIM_STR);
				continue;
			}
			case 7:
			{
				g_DeathAnims[i][4] = GetAnimationFromMdl(MODEL_LOUIS, DEATH_ANIM_STR);
				continue;
			}
		}
	}
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);
}

public void OnAllPluginsLoaded()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsValidClient(client) || !IsSurvivor(client)) continue;
		
		SDKHook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);
	}
}

Action TimerUpdate(Handle timer)
{
	if (!IsServerProcessing()) return Plugin_Continue;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i) || !IsSurvivor(i) || !IsPlayerAlive(i) || g_bIsSurvivorInDeathAnimation[i]) continue;
		
		int i_CurrentAnimation = GetEntProp(i, Prop_Send, "m_nSequence");
		char model[PLATFORM_MAX_PATH];
		GetClientModel(i, model, sizeof(model));
		
		if (i_CurrentAnimation == g_DeathAnims[6][4] && StrEqual(model, MODEL_FRANCIS, false)
			|| i_CurrentAnimation == g_DeathAnims[5][4] && StrEqual(model, MODEL_ZOEY, false)
			|| i_CurrentAnimation == g_DeathAnims[4][4] && StrEqual(model, MODEL_BILL, false)
			|| i_CurrentAnimation == g_DeathAnims[7][4] && StrEqual(model, MODEL_LOUIS, false)
			|| i_CurrentAnimation == g_DeathAnims[0][4] && StrEqual(model, MODEL_NICK, false)
			|| i_CurrentAnimation == g_DeathAnims[3][4] && StrEqual(model, MODEL_ELLIS, false)
			|| i_CurrentAnimation == g_DeathAnims[2][4] && StrEqual(model, MODEL_COACH, false)
			|| i_CurrentAnimation == g_DeathAnims[1][4] && StrEqual(model, MODEL_ROCHELLE, false))
		{
			g_bIsSurvivorInDeathAnimation[i] = true;
			CreateTimer(3.03, ForcePlayerSuicideTimer, GetClientUserId(i), TIMER_FLAG_NO_MAPCHANGE);
			return Plugin_Continue;
		}
	}
	return Plugin_Continue;
}

Action ForcePlayerSuicideTimer(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (!IsValidClient(client)) return;
	
	ForcePlayerSuicide(client);
	g_bIsSurvivorInDeathAnimation[client] = false;
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float ang[3], int& weapon)
{
	if (!IsValidClient(client) || !IsSurvivor(client) || !IsPlayerAlive(client) || !g_bIsSurvivorInDeathAnimation[client])
		return Plugin_Continue;
	return Plugin_Handled;
}

int GetAnimationFromMdl(const char[] model, const char[] sequence)
{
	int temp_ent = CreateEntityByName("prop_dynamic");
	if (!RealValidEntity(temp_ent)) return -1;
	SetEntityModel(temp_ent, model);
	
	SetVariantString(sequence);
	AcceptEntityInput(temp_ent, "SetAnimation");
	int result = GetEntProp(temp_ent, Prop_Send, "m_nSequence");
	RemoveEdict(temp_ent);
	
	return result;
}

bool IsSurvivor(int client)
{
	return (GetClientTeam(client) == 2 || GetClientTeam(client) == 4);
}

bool RealValidEntity(int entity)
{
	return (entity > 0 && IsValidEntity(entity));
}

bool IsValidClient(int client, bool replaycheck = true)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (replaycheck)
	{
		if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	}
	return true;
}

// blocks weapon change when in dying animation
Action OnWeaponSwitch(int client, int weapon)
{
	if (IsValidClient(client) && IsSurvivor(client) && IsPlayerAlive(client) && g_bIsSurvivorInDeathAnimation[client])
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

#if DEBUG
void DefibStart_Event(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int subject = GetClientOfUserId(GetEventInt(event, "subject"));
	//SetEntProp(client, Prop_Send, "m_reviveTarget", subject);
	char message[PLATFORM_MAX_PATH] = "";
	Format(message, sizeof(message), "Player %N is reviving Player %N with a Defib!", client, subject);
	PrintToChatAll(message);
}
#endif

// Even with all the checks and action blocks, survivors are still able to attempt to use
// medkits while in the death animation, and while they can't heal they can still
// interrupt the death animation, so we use weapon_fire to (hopefully) stop that
Action Event_BlockInputs(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!IsValidClient(client) || !IsSurvivor(client))
	{
		return Plugin_Continue;
	}
	
	if (g_bIsSurvivorInDeathAnimation[client])
	{
		#if DEBUG
		{
			char message[PLATFORM_MAX_PATH] = "";
			Format(message, sizeof(message), "Player %N is trying to use a weapon while in Death Animation!", client);
			PrintToChatAll(message);
		}
		#endif
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

