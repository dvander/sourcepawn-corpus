#define PLUGIN_VERSION "1.1h-2023/12/27"

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

#define DEBUG 0
#define HAS_BIT(%0,%1,%2) (%0 && %1 & (1 << %2))
// --------------------------------------------------------------
// CONST
// --------------------------------------------------------------
const int PAIN_SOUND_LEN = 54;
static const float L4D_Z_MULT = 1.6;
static const int SOUND_MIN = 1;
static const int SOUND_MAX[8] = {7 ,4, 8, 6, 9, 7, 11, 5};
static const char FORMAT_PAIN_SOUND[] = "player/survivor/voice/%s/hurtcritical0%d.wav";

static const char FORMAT_MESSAGE_1C[] = "\x04%N\x01 was \x02%s\x01 by \x04%N\x01!";
static const char FORMAT_MESSAGE_1[] = "%N was %s by %N!";
static const char FORMAT_MESSAGE_2C[] = "\x01You \x02%s \x04%N";
static const char FORMAT_MESSAGE_2[] = "You %s %N";
static const char FORMAT_MESSAGE_3C[] = "\x01Got \x02%s by \x04%N!";
static const char FORMAT_MESSAGE_3[] = "Got %s by %N!";
static const char FORMAT_MESSAGE_TYPE[][] = {"shoved", "slapped"};

static const char INFECTED_CLAW[][]=
{
	"",
	"smoker_claw",
	"boomer_claw",
	"hunter_claw",
	"spitter_claw",
	"jockey_claw",
	"charger_claw"
};

#define L4D_SURVIVOR_CHARACTER_OFFSET 4

enum
{
	SC_INVALID = -1,
	SC_NICK,
	SC_ROCHELLE,
	SC_COACH,
	SC_ELLIS,
	SC_BILL,
	SC_ZOEY,
	SC_FRANCIS,
	SC_LOUIS,
	SC_SIZE
}

stock const char L4D2_LIB_SURVIVOR_CHARACTER[8][] =
{
	"gambler",
	"producer",
	"coach",
	"mechanic",
	"namvet", // L4D_SURVIVOR_CHARACTER_OFFSET
	"teengirl",
	"biker",
	"manager"
};
// --------------------------------------------------------------
// GLOBAL VARS
// --------------------------------------------------------------
enum
{
	Ability_Shove,
	Ability_Slap,
	Ability_Size
}

bool g_bCvarEnabled;
int g_iCvarFlags[Ability_Size], g_iCvarIncapFlags, g_iCvarAnnounce;
float g_fCvarPower, g_fCvarZMult, g_fCvarAbilityCooldown[Ability_Size], g_fCooldownExpires[MAXPLAYERS+1];
// --------------------------------------------------------------
// CORE
// --------------------------------------------------------------
public Plugin myinfo =
{
	name = "[L4D & L4D2] Special Infected Ability",
	author = "raziEiL [disawar1]",
	description = "Provides to Special Infected the ability to slap and shove Survivors.",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/raziEiL"
}

bool g_bL4D2Version;
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion test = GetEngineVersion();

    if( test == Engine_Left4Dead )
    {
        g_bL4D2Version = false;
    }
    else if( test == Engine_Left4Dead2 )
    {
        g_bL4D2Version = true;
    }
    else
    {
        strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
        return APLRes_SilentFailure;
    }

    return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("l4d_si_ability_version", PLUGIN_VERSION, "L4D & L4D2 Special Infected Slap/Shove Ability Plugin Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);

	ConVar cVar = CreateConVar("l4d_si_ability_enabled", "1", "Enable/Disable the Special Infected Slap/Shove Ability Plugin.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_bCvarEnabled = cVar.BoolValue;
	cVar.AddChangeHook(OnCvarChange_Enabled);

	cVar = CreateConVar("l4d_si_ability_power", "150", "How much force is applied to the victim (Slap ability).", FCVAR_NOTIFY, true, 0.0);
	g_fCvarPower = cVar.FloatValue;
	cVar.AddChangeHook(OnCvarChange_Power);

	cVar = CreateConVar("l4d_si_ability_vertical_mult", "1.5", "Vertical force multiplier (Slap ability).", FCVAR_NOTIFY, true, 0.0);
	g_fCvarZMult = cVar.FloatValue;
	cVar.AddChangeHook(OnCvarChange_ZMult);

	cVar = CreateConVar("l4d_si_ability_cooldown_slap", "1.0", "0=Off, >0: Seconds before SI can slap again.", FCVAR_NOTIFY, true, 0.0);
	g_fCvarAbilityCooldown[Ability_Slap] = cVar.FloatValue;
	cVar.AddChangeHook(OnCvarChange_SlapCooldown);

	cVar = CreateConVar("l4d_si_ability_cooldown_shove", "1.0", "0=Off, >0: Seconds before SI can shove again.", FCVAR_NOTIFY, true, 0.0);
	g_fCvarAbilityCooldown[Ability_Shove] = cVar.FloatValue;
	cVar.AddChangeHook(OnCvarChange_ShoveCooldown);

	cVar = CreateConVar("l4d_si_ability_announce", "1", "0=Off, 1=Chat, 2=Center chat, 3=Hint.", FCVAR_NOTIFY, true, 0.0, true, 3.0);
	g_iCvarAnnounce = cVar.IntValue;
	cVar.AddChangeHook(OnCvarChange_Announce);

	cVar = CreateConVar("l4d_si_ability_incap", "68", "Slapping incapacitating people. Add numbers together: 0=Off, 2=Smoker, 4=Boomer, 8=Hunter, 16=Spitter, 32=Jockey, 64=Charger, 126=All. Default: Boomer|Charger.", FCVAR_NOTIFY, true, 0.0, true, 126.0);
	g_iCvarIncapFlags = cVar.IntValue;
	cVar.AddChangeHook(OnCvarChange_IncapFlags);

	cVar = CreateConVar("l4d_si_ability_slap", "68", "Special Infected who can slap. Add numbers together: 0=Off, 2=Smoker, 4=Boomer, 8=Hunter, 16=Spitter, 32=Jockey, 64=Charger, 126=All. Default: Boomer|Charger.", FCVAR_NOTIFY, true, 0.0, true, 126.0);
	g_iCvarFlags[Ability_Slap] = cVar.IntValue;
	cVar.AddChangeHook(OnCvarChange_SlapFlags);

	cVar = CreateConVar("l4d_si_ability_shove", "18", "Special Infected who can shove. Add numbers together: 0=Off, 2=Smoker, 4=Boomer, 8=Hunter, 16=Spitter, 32=Jockey, 64=Charger, 126=All. Default: Smoker|Spitter.", FCVAR_NOTIFY, true, 0.0, true, 126.0);
	g_iCvarFlags[Ability_Shove] = cVar.IntValue;
	cVar.AddChangeHook(OnCvarChange_ShoveFlags);

	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_death", Event_PlayerDeath);

	AutoExecConfig(true, "l4d_si_ability");
#if DEBUG
	RegServerCmd("sm_si_ability_cvar", CommandCvar);
	RegServerCmd("sm_si_ability_test", CommandTest);
#endif
}

public void OnMapStart()
{
	char painSound[PAIN_SOUND_LEN];
	for (int i; i < 8; i++){
		for (int n = SOUND_MIN; n <= SOUND_MAX[i]; n++){
			FormatEx(painSound, sizeof(painSound), FORMAT_PAIN_SOUND, L4D2_LIB_SURVIVOR_CHARACTER[i], n);
#if DEBUG
			PrintToServer("%d, %s", PrecacheSound(painSound, true), painSound);
#else
			PrecacheSound(painSound, true);
#endif
		}
	}
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (g_bCvarEnabled)
		g_fCooldownExpires[GetClientOfUserId(event.GetInt("userid"))] = 0.0;
}

public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bCvarEnabled) return;

	int slapper = GetClientOfUserId(event.GetInt("attacker"));
	if (!IsInfectedAndInGame(slapper) || !CanSlapAgain(slapper) || L4D_GetPinnedSurvivor(slapper) > 0) return;

	int target = GetClientOfUserId(event.GetInt("userid"));
	if (!IsSurvivorAndInGame(target)) return;
	if (L4D_IsPlayerIncapacitated(target) || L4D_IsPlayerHangingFromLedge(target)) return;
	if (L4D_GetPinnedInfected(target) > 0) return;


	int class = GetEntProp(slapper, Prop_Send, "m_zombieClass");
	bool bIncaped = L4D_IsPlayerIncapacitated(target);
	int bSlap = HAS_BIT(!bIncaped, g_iCvarFlags[Ability_Slap], class) || HAS_BIT(bIncaped, g_iCvarIncapFlags, class);

	if (!(bSlap || HAS_BIT(!bIncaped, g_iCvarFlags[Ability_Shove], class))) return;

	int type = event.GetInt("type");
	if(!(type & DMG_CLUB)) return;

	static char sWeapon[14];
	event.GetString("weapon", sWeapon, sizeof(sWeapon));

	if (sWeapon[0] &&   StrEqual(sWeapon, INFECTED_CLAW[class]))
	{
		if (g_iCvarAnnounce && !IsFakeClient(target))
			Print(slapper, target, bSlap);

		PlaySurvivorPainSound(target);

		if (bSlap){
			// math code by AtomicStryker https://forums.alliedmods.net/showthread.php?t=97952
			float HeadingVector[3], resulting[3];
			GetClientEyeAngles(slapper, HeadingVector);
			GetEntPropVector(target, Prop_Data, "m_vecVelocity", resulting);

			resulting[0] += Cosine(DegToRad(HeadingVector[1])) * g_fCvarPower;
			resulting[1] += Sine(DegToRad(HeadingVector[1])) * g_fCvarPower;
			resulting[2] = g_fCvarPower * g_fCvarZMult;

			if (g_bL4D2Version){
				resulting[2] *= L4D_Z_MULT;
				TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, resulting);
			}
			else
				L4D2_CTerrorPlayer_Fling(target, slapper, resulting);
		}
		else {
			float fPos[3];
			GetClientAbsOrigin(slapper, fPos);
			L4D_StaggerPlayer(target, slapper, fPos);
		}

		if (g_fCvarAbilityCooldown[bSlap])
			g_fCooldownExpires[slapper] = GetEngineTime() + g_fCvarAbilityCooldown[bSlap];
#if DEBUG
		SetEntityHealth(target, 100);
#endif
	}
}

bool CanSlapAgain(int client)
{
	return g_fCooldownExpires[client] ? FloatCompare(GetEngineTime(), g_fCooldownExpires[client]) != -1 : true;
}

void PlaySurvivorPainSound(int target)
{
	int survIndex = GetSurvivorIndex(target);
	if (survIndex == SC_INVALID) return;

	char painSound[PAIN_SOUND_LEN];
	FormatEx(painSound, sizeof(painSound), FORMAT_PAIN_SOUND, L4D2_LIB_SURVIVOR_CHARACTER[survIndex], GetRandomInt(SOUND_MIN, SOUND_MAX[survIndex]));
	EmitSoundToAll(painSound, target, _, SNDLEVEL_SCREAMING);
}

void Print(int slapper, int target, int type, bool allChat = true)
{
	switch (g_iCvarAnnounce)
	{
		case 1:
		{
			if (allChat)
				PrintToChatAll(FORMAT_MESSAGE_1C, target, FORMAT_MESSAGE_TYPE[type], slapper);
			else {
				PrintToChat(slapper, FORMAT_MESSAGE_2C, FORMAT_MESSAGE_TYPE[type], target);
				PrintToChat(target, FORMAT_MESSAGE_3C, FORMAT_MESSAGE_TYPE[type], slapper);
			}
		}
		case 2:
		{
			if (allChat)
				PrintCenterTextAll(FORMAT_MESSAGE_1, target, FORMAT_MESSAGE_TYPE[type], slapper);
			else {
				PrintCenterText(slapper, FORMAT_MESSAGE_2, FORMAT_MESSAGE_TYPE[type], target);
				PrintCenterText(target, FORMAT_MESSAGE_3, FORMAT_MESSAGE_TYPE[type], slapper);
			}
		}
		case 3:
		{
			if (allChat)
				PrintHintTextToAll(FORMAT_MESSAGE_1, target, FORMAT_MESSAGE_TYPE[type], slapper);
			else {
				PrintHintText(slapper, FORMAT_MESSAGE_2, FORMAT_MESSAGE_TYPE[type], target);
				PrintHintText(target, FORMAT_MESSAGE_3, FORMAT_MESSAGE_TYPE[type], slapper);
			}
		}
	}
}
// --------------------------------------------------------------
// CONVARS
// --------------------------------------------------------------
public void OnCvarChange_Enabled(ConVar cVar, const char[] sOldVal, const char[] sNewVal)
{
	if (!StrEqual(sOldVal, sNewVal))
		g_bCvarEnabled = cVar.BoolValue;
}

public void OnCvarChange_Power(ConVar cVar, const char[] sOldVal, const char[] sNewVal)
{
	if (!StrEqual(sOldVal, sNewVal))
		g_fCvarPower = cVar.FloatValue;
}

public void OnCvarChange_ZMult(ConVar cVar, const char[] sOldVal, const char[] sNewVal)
{
	if (!StrEqual(sOldVal, sNewVal))
		g_fCvarZMult = cVar.FloatValue;
}

public void OnCvarChange_SlapCooldown(ConVar cVar, const char[] sOldVal, const char[] sNewVal)
{
	if (!StrEqual(sOldVal, sNewVal))
		g_fCvarAbilityCooldown[Ability_Slap] = cVar.FloatValue;
}

public void OnCvarChange_ShoveCooldown(ConVar cVar, const char[] sOldVal, const char[] sNewVal)
{
	if (!StrEqual(sOldVal, sNewVal))
		g_fCvarAbilityCooldown[Ability_Shove] = cVar.FloatValue;
}

public void OnCvarChange_Announce(ConVar cVar, const char[] sOldVal, const char[] sNewVal)
{
	if (!StrEqual(sOldVal, sNewVal))
		g_iCvarAnnounce = cVar.IntValue;
}

public void OnCvarChange_IncapFlags(ConVar cVar, const char[] sOldVal, const char[] sNewVal)
{
	if (!StrEqual(sOldVal, sNewVal))
		g_iCvarIncapFlags = cVar.IntValue;
}

public void OnCvarChange_SlapFlags(ConVar cVar, const char[] sOldVal, const char[] sNewVal)
{
	if (!StrEqual(sOldVal, sNewVal))
		g_iCvarFlags[Ability_Slap] = cVar.IntValue;
}

public void OnCvarChange_ShoveFlags(ConVar cVar, const char[] sOldVal, const char[] sNewVal)
{
	if (!StrEqual(sOldVal, sNewVal))
		g_iCvarFlags[Ability_Shove] = cVar.IntValue;
}
// --------------------------------------------------------------
// DEBUG
// --------------------------------------------------------------
#if DEBUG
// blocks si ability
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (buttons & IN_ATTACK && IsInfected(client) && IsFakeClient(client))
		buttons &= ~IN_ATTACK;
	return Plugin_Continue;
}

public Action CommandCvar(int args)
{
	PrintToServer("l4d test");
	for (int i = ZC_SMOKER; i <= ZC_HUNTER; i++){
		PrintToServer("%d. fling %d, stagger %d, %s", i, g_iCvarFlags[Ability_Shove] & (1 << i), g_iCvarFlags[Ability_Slap] & (1 << i), L4D_LIB_INFECTED_CHARACTER_NAME[i]);
	}
	PrintToServer("l4d2 test");
	for (int i = ZC2_SMOKER; i <= ZC2_CHARGER; i++){
		PrintToServer("%d. fling %d, stagger %d, %s", i, g_iCvarFlags[Ability_Shove] & (1 << i), g_iCvarFlags[Ability_Slap] & (1 << i), L4D2_LIB_INFECTED_CHARACTER_NAME[i]);
	}
}

enum (<<= 1)
{
	BIT_SMOKER = 2,
	BIT_BOOMER,
	BIT_HUNTER,
	BIT_SPITTER,
	BIT_JOCKEY,
	BIT_CHARGER
}

#define CONDITION(%0,%1,%2,%3,%4) (HAS_BIT(!%0,%2,%1) || HAS_BIT(%0,%3,%1) || HAS_BIT(!%0,%4,%1))

public Action CommandTest(int args)
{
	PrintToServer("%d, %d, %d, %d, %d, %d", BIT_SMOKER, BIT_BOOMER, BIT_HUNTER, BIT_SPITTER, BIT_JOCKEY, BIT_CHARGER);

	int cvarSlap, cvarIncap, cvarShove;
	bool bIncap;
	// ---------------------TEST 1: bIncap = false-------------------------------
	bIncap = false;
	cvarIncap = 0;
	cvarSlap = 0;
	cvarShove = 0;
	for (int class = ZC2_SMOKER; class <= ZC2_CHARGER; class++)
		PrintToServer("#1 Test %s [%s]", CONDITION(bIncap, class, cvarSlap, cvarIncap, cvarShove) ? "not passed!"  : "passed!", L4D2_LIB_INFECTED_CHARACTER_NAME[class]);
	// --------------------TEST 2: bIncap = true-------------------------------
	bIncap = true;
	cvarIncap = 0;
	cvarSlap = 0;
	cvarShove = 0;
	for (int class = ZC2_SMOKER; class <= ZC2_CHARGER; class++)
		PrintToServer("#2 Test %s [%s]", CONDITION(bIncap, class, cvarSlap, cvarIncap, cvarShove) ? "not passed!"  : "passed!", L4D2_LIB_INFECTED_CHARACTER_NAME[class]);
	// --------------------TEST 3: cvarIncap-------------------------------
	bIncap = true;
	cvarIncap = BIT_BOOMER;
	cvarSlap = 0;
	cvarShove = 0;
	for (int class = ZC2_SMOKER; class <= ZC2_CHARGER; class++)
		if (CONDITION(bIncap, class, cvarSlap, cvarIncap, cvarShove))
			PrintToServer("#3 Test %s [%s]", class != ZC2_BOOMER ? "not passed!" : "passed!", L4D2_LIB_INFECTED_CHARACTER_NAME[class]);
	// --------------------TEST 4: cvarSlap-------------------------------
	bIncap = false;
	cvarIncap = BIT_SMOKER|BIT_HUNTER;
	cvarSlap = BIT_BOOMER;
	cvarShove = 0;
	for (int class = ZC2_SMOKER; class <= ZC2_CHARGER; class++)
		if (CONDITION(bIncap, class, cvarSlap, cvarIncap, cvarShove))
			PrintToServer("#4 Test %s [%s]", class != ZC2_BOOMER ? "not passed!" : "passed!", L4D2_LIB_INFECTED_CHARACTER_NAME[class]);
	// --------------------TEST 5: cvarShove-------------------------------
	bIncap = false;
	cvarIncap = BIT_SMOKER|BIT_HUNTER;
	cvarSlap = 0;
	cvarShove = BIT_BOOMER;
	for (int class = ZC2_SMOKER; class <= ZC2_CHARGER; class++){
		if (CONDITION(bIncap, class, cvarSlap, cvarIncap, cvarShove))
			PrintToServer("#5 Test %s [%s]", class != ZC2_BOOMER ? "not passed!" : "passed!", L4D2_LIB_INFECTED_CHARACTER_NAME[class]);
	}
	// --------------------TEST 6: cvarIncap|cvarShove|cvarShove-------------------------------
	bIncap = true;
	cvarIncap = BIT_SMOKER;
	cvarSlap = BIT_HUNTER;
	cvarShove = BIT_BOOMER;
	for (int class = ZC2_SMOKER; class <= ZC2_CHARGER; class++){
		if (CONDITION(bIncap, class, cvarSlap, cvarIncap, cvarShove))
			PrintToServer("#6 Test %s [%s]", (class == ZC2_BOOMER || class == ZC2_SMOKER || class == ZC2_HUNTER) ? "passed!" : "not passed!", L4D2_LIB_INFECTED_CHARACTER_NAME[class]);
	}
}
#endif

stock bool IsInfectedAndInGame(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3;
}

stock bool IsPlayerBussy(int client, int team)
{
	return !IsPlayerAlive(client) || (team == 2 ? (L4D_GetPinnedInfected(client) > 0 || L4D_IsPlayerIncapacitated(client) || L4D_IsPlayerHangingFromLedge(client)) :
		L4D_GetPinnedSurvivor(client) > 0);
}

stock bool IsSurvivorAndInGame(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2;
}

stock int GetSurvivorIndex(int client)
{
	if (g_bL4D2Version == false){
		static int survIndex;
		survIndex = GetEntProp(client, Prop_Send, "m_survivorCharacter");
		return survIndex < 0 ? SC_INVALID : survIndex + L4D_SURVIVOR_CHARACTER_OFFSET;
	}

	static char g_sTemp[256];
	GetClientModel(client, g_sTemp, sizeof(g_sTemp));
	switch (g_sTemp[29]){
		case 'b':
			return SC_NICK;
		case 'd':
			return SC_ROCHELLE;
		case 'c':
			return SC_COACH;
		case 'h':
			return SC_ELLIS;
		case 'v':
			return SC_BILL;
		case 'n':
			return SC_ZOEY;
		case 'e':
			return SC_FRANCIS;
		case 'a':
			return SC_LOUIS;
	}
	return SC_INVALID;
}