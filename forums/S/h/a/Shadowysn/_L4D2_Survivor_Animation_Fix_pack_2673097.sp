// Thanks to GAMMACASE for solving the post-hook detour crashing!

#define PLUGIN_NAME "[L4D2] Survivor Animation Fix Pack"
#define PLUGIN_AUTHOR "DeathChaos25, Shadowysn"
#define PLUGIN_DESC "A few quality of life animation fixes for the survivors"
#define PLUGIN_VERSION "1.9b"
#define PLUGIN_URL ""
// Stopped check for pounce anim from getting spammed all the time.
#define GAMEDATA "l4d2_sequence"

#include <sourcemod>
#include <dhooks>
#include <sdktools>

#pragma newdecls required
#pragma semicolon 1

#define MODEL_NICK "models/survivors/survivor_gambler.mdl"
#define MODEL_ROCHELLE "models/survivors/survivor_producer.mdl"
#define MODEL_COACH "models/survivors/survivor_coach.mdl"
#define MODEL_ELLIS "models/survivors/survivor_mechanic.mdl"
#define MODEL_BILL "models/survivors/survivor_namvet.mdl"
#define MODEL_ZOEY "models/survivors/survivor_teenangst.mdl"
#define MODEL_LOUIS "models/survivors/survivor_manager.mdl"
#define MODEL_FRANCIS "models/survivors/survivor_biker.mdl"

#define PARAM_ACT_INCAP_IDLE 700
#define PARAM_ACT_INCAP_IDLE_ELITES 701

#define DEBUG 0

static int pounced_Seq[MAXPLAYERS + 1] = {0};
static int pouncedCheck_Seq[MAXPLAYERS + 1] = {0};
static int charged_Seq[MAXPLAYERS + 1] = {0};

ConVar AlternateIncap;
ConVar PistolEnabled;
ConVar PounceEnabled;
ConVar IncapChargeEnabled;
#if DEBUG
ConVar OverrideEnabled;
#endif

Handle hConf = null;

Handle sdkDoAnim;
Handle hSequenceSet;

#define NAME_SelectWeightedSequence "CTerrorPlayer::SelectWeightedSequence"
#define SIG_SelectWeightedSequence_LINUX "@_ZN13CTerrorPlayer22SelectWeightedSequenceE8Activity"
#define SIG_SelectWeightedSequence_WINDOWS "\\x55\\x8B\\x2A\\x56\\x57\\x8B\\x2A\\x2A\\x8B\\x2A\\x81\\x2A\\x2A\\x2A\\x2A\\x2A\\x75\\x2A"

#define NAME_DoAnimationEvent "CTerrorPlayer::DoAnimationEvent"
#define SIG_DoAnimationEvent_LINUX "@_ZN13CTerrorPlayer16DoAnimationEventE17PlayerAnimEvent_ti"
#define SIG_DoAnimationEvent_WINDOWS "\\x55\\x8B\\x2A\\x56\\x8B\\x2A\\x2A\\x57\\x8B\\x2A\\x83\\x2A\\x2A\\x74\\x2A\\x8B\\x2A\\x2A\\x2A\\x2A\\x2A\\x8B\\x2A"

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
	HookEvent("weapon_reload", Event_Reload);
	HookEvent("lunge_pounce", Event_Pounced);
	HookEvent("charger_carry_end", Event_CarryEnd);
	GetGamedata();
	
	//RegAdminCmd("sm_incapsetanim", Command_SetAnim, ADMFLAG_ROOT, "Set the animation the incap uses.");
	//RegAdminCmd("sm_testsetanim", Command_TestSetAnim, ADMFLAG_ROOT, "Set animation of yourself.");
	//RegAdminCmd("sm_testgetseq", Command_TestGetSeq, ADMFLAG_ROOT, "Get animation of player's model from a string.");
	
	AlternateIncap = CreateConVar("enable_alternate_incap_anims", "0", "Use IncapFrom_Charger for incap anims?", FCVAR_NONE, true, 0.0, true, 1.0);
	PistolEnabled = CreateConVar("enable_empty_pistol_anim_fix", "1", "Fix missing animation for empty pistol reloads?", FCVAR_NONE, true, 0.0, true, 1.0);
	PounceEnabled = CreateConVar("enable_pounce_anim_fix", "1", "Restore pounced to ground animation from original game?", FCVAR_NONE, true, 0.0, true, 1.0);
	IncapChargeEnabled = CreateConVar("enable_charge_incap_anim_fix", "1", "Restore IncapFrom_Charger animation in the most likely event?", FCVAR_NONE, true, 0.0, true, 1.0);
	#if DEBUG
	OverrideEnabled = CreateConVar("enable_override_anim", "-1", "Choose an anim for all survivors to use. Debug feature.", FCVAR_NONE);
	#endif
	
	AutoExecConfig(true, "l4d2_animations_fix");
}

/*public void OnPluginEnd()
{
	UnloadOffset();
}*/

/*Action Command_TestSetAnim(int client, any args)
{
	if (args < 3 || args > 3)
	{
		ReplyToCommand(client, "[SM] Usage: sm_testsetanim <player> <number> <set>");
		return Plugin_Handled;
	}
	char player[64];
	char num[64];
	char set[64];
	GetCmdArg(1, player, sizeof(player));
	GetCmdArg(2, num, sizeof(num));
	GetCmdArg(3, set, sizeof(set));
	int int_set = StringToInt(set);
	int player_id = FindTarget(client, player);
	
	SDKCall(sdkDoAnim, player_id, num, int_set);
	return Plugin_Handled;
}

Action Command_TestGetSeq(int client, any args)
{
	if (args < 2 || args > 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_testgetseq <player> <string>");
		return Plugin_Handled;
	}
	char player[64];
	char str[64];
	GetCmdArg(1, player, sizeof(player));
	GetCmdArg(2, str, sizeof(str));
	int player_id = FindTarget(client, player);
	
	PrintToChatAll("%s: %i", str, GetAnimation(player_id, str));
	return Plugin_Handled;
}*/

void Event_Reload(Event event, const char[] name, bool dontBroadcast)
{
	if (!GetConVarBool(PistolEnabled))
		return;
	
	int client = GetClientOfUserId(event.GetInt("userid", 0));
	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (!RealValidEntity(weapon)) return;
	
	static char wepstring[64];
	GetEntityClassname(weapon, wepstring, sizeof(wepstring));
	
	int clip = GetEntProp(weapon, Prop_Send, "m_iClip1");
	if (IsSurvivor(client) && !IsPlayerHeld(client) && (clip <= 0 || IsDualWielding(client) && clip <= 1) &&
	(StrEqual(wepstring, "weapon_pistol") || StrEqual(wepstring, "weapon_pistol_magnum")) )
	{
		SDKCall(sdkDoAnim, client, 4, 1);
	}
}

void Event_CarryEnd(Event event, const char[] name, bool dontBroadcast)
{
	if (!GetConVarBool(IncapChargeEnabled))
		return;
	
	int userid = event.GetInt("victim", 0);
	int victim = GetClientOfUserId(userid);
	if (IsSurvivor(victim))
	{
		charged_Seq[victim] = GetAnimation(victim, "ACT_TERROR_CHARGER_PUMMELED");
		CreateTimer(1.5, SETFALSE_CHARGE, userid, TIMER_FLAG_NO_MAPCHANGE);
	}
	else charged_Seq[victim] = 0;
}
Action SETFALSE_CHARGE(Handle timer, int client)
{
	client = GetClientOfUserId(client);
	charged_Seq[client] = 0;
	//SDKCall(sdkDoAnim, client, 92, 0);
	return Plugin_Continue;
}

void Event_Pounced(Event event, const char[] name, bool dontBroadcast)
{
	if (!GetConVarBool(PounceEnabled))
		return;
	
	int userid = event.GetInt("victim", 0);
	int victim = GetClientOfUserId(userid);
	if (IsSurvivor(victim))
	{
		pounced_Seq[victim] = GetAnimation(victim, "ACT_TERROR_INCAP_FROM_POUNCE");
		pouncedCheck_Seq[victim] = GetAnimation(victim, "ACT_IDLE_POUNCED");
		CreateTimer(0.9, SETFALSE_POUNCE, userid, TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		pounced_Seq[victim] = 0;
		pouncedCheck_Seq[victim] = 0;
	}
}
Action SETFALSE_POUNCE(Handle timer, int client)
{
	client = GetClientOfUserId(client);
	pounced_Seq[client] = 0;
	pouncedCheck_Seq[client] = 0;
	//SDKCall(sdkDoAnim, client, 92, 0);
	return Plugin_Continue;
}

public MRESReturn OnSequenceSet_Pre(int client, Handle hReturn, Handle hParams)
{
	/*if (!RealValidEntity(client) || !IsPlayerAlive(client) || !IsSurvivor(client)) return MRES_Ignored;
	int param = DHookGetParam(hParams, 1);
	if (incapped[client])
	{
		if (param == 20)
		{
			if (IsDualWielding(client))
			{ DHookSetParam(hParams, 1, PARAM_ACT_INCAP_IDLE_ELITES); }
			else
			{ DHookSetParam(hParams, 1, PARAM_ACT_INCAP_IDLE); }
			return MRES_ChangedHandled;
		}
	}*/
	return MRES_Ignored;
} // We need this pre hook even though it's empty, or else the post hook will crash the game.

public MRESReturn OnSequenceSet(int client, Handle hReturn, Handle hParams)
{
	if (!RealValidEntity(client) || !IsPlayerAlive(client) || !IsSurvivor(client)) return MRES_Ignored;
	int sequence = DHookGetReturn(hReturn);
	if (IsSurvivor(client) && IsPlayerAlive(client))
	{
		#if DEBUG
		int override = GetConVarInt(OverrideEnabled);
		if (override > -1)
		{ DHookSetReturn(hReturn, override); return MRES_Override; }
		#endif
		int pouncer = GetEntPropEnt(client, Prop_Send, "m_pounceAttacker");
		if (pounced_Seq[client] > 0 && RealValidEntity(pouncer) && IsInfected(pouncer) && IsPlayerAlive(pouncer))
		{
			int pouncer_victim = GetEntPropEnt(pouncer, Prop_Send, "m_pounceVictim");
			if (pouncer_victim == client && sequence == pouncedCheck_Seq[client])
			{
				//float angles[3];
				//GetClientAbsAngles(pouncer, angles);
				//float new_ang[3];
				//if (angles[1] > 0)
				//{ new_ang[1] = angles[1]-180; }
				//else if (angles[1] <= 0)
				//{ new_ang[1] = angles[1]+180; }
				//SetEntPropVector(client, Prop_Send, "m_angRotation", new_ang);
				DHookSetReturn(hReturn, pounced_Seq[client]);
				return MRES_Override;
			}
		}
		else if ((charged_Seq[client] > 0 || GetConVarBool(AlternateIncap)) && !IsPlayerHeld(client) && 
		IsIncapacitated(client) && IsInIncapSequence(client, sequence))
		{
			if (charged_Seq[client] <= 0)
			{ charged_Seq[client] = GetAnimation(client, "ACT_TERROR_CHARGER_PUMMELED"); }
			
			if (charged_Seq[client] > 0)
			{
				DHookSetReturn(hReturn, charged_Seq[client]);
				return MRES_Override;
			}
		}
	}
	return MRES_Ignored;
}

bool IsSurvivor(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && (GetClientTeam(client) == 2 || GetClientTeam(client) == 4));
}

bool IsInfected(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && (GetClientTeam(client) == 3));
}

bool IsPlayerHeld(int client)
{
	int jockey = GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker");
	int charger = GetEntPropEnt(client, Prop_Send, "m_pummelAttacker");
	int hunter = GetEntPropEnt(client, Prop_Send, "m_pounceAttacker");
	int smoker = GetEntPropEnt(client, Prop_Send, "m_tongueOwner");
	if (RealValidEntity(jockey) || RealValidEntity(charger) || RealValidEntity(hunter) || RealValidEntity(smoker))
	{
		return true;
	}
	return false;
}
bool IsIncapacitated(int client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1) > 0)
		return true;
	return false;
}

int GetAnimation(int entity, const char[] sequence)
{
	//if (!RealValidEntity(entity) || sdkGetSeqFromString == null) return -1;
	if (!RealValidEntity(entity)) return -1;
	
	static char model[64];
	GetClientModel(entity, model, sizeof(model));
	
	int temp_ent = CreateEntityByName("prop_dynamic");
	if (!RealValidEntity(temp_ent)) return -1;
	SetEntityModel(temp_ent, model);
	
	SetVariantString(sequence);
	AcceptEntityInput(temp_ent, "SetAnimation");
	int result = GetEntProp(temp_ent, Prop_Send, "m_nSequence");
	RemoveEdict(temp_ent);
	
	return result;
	//return SDKCall(sdkGetSeqFromString, entity, sequence);
}

bool IsInIncapSequence(int client, int sequence)
{
	if (IsSurvivor(client))
	{
		if (sequence == GetAnimation(client, "ACT_DIESIMPLE") || sequence == -1 || sequence == GetAnimation(client, "Death"))
		{
			return true;
		}
	}
	return false;
}

bool IsDualWielding(int client)
{
	if (!IsSurvivor(client)) return false;
	
	int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (!RealValidEntity(weapon)) return false;
	if (!HasEntProp(weapon, Prop_Send, "m_isDualWielding")) return false;
	int dual = GetEntProp(weapon, Prop_Send, "m_isDualWielding");
	if (dual > 0)
	return true;
	
	return false;
}

/*bool IsCrawling(int client)
{
	if (!IsSurvivor(client) || !IsPlayerAlive(client) || !IsIncapacitated(client)) return false;
	ConVar crawl_cvar = FindConVar("survivor_allow_crawling");
	if (!crawl_cvar || !GetConVarBool(crawl_cvar)) return false;
	int m_nButtons = GetEntProp(client, Prop_Data, "m_nButtons");
	if (m_nButtons & IN_FORWARD)
	{ return true; }
	return false;
}*/

void PrepSDKCall()
{
	if (hConf == null)
	{
		SetFailState("Error: Why do you not have this extension's gamedata file?!");
	}
	
	StartPrepSDKCall(SDKCall_Player);
	if (!PrepSDKCall_SetFromConf(hConf, SDKConf_Signature, NAME_DoAnimationEvent))
	{ SetFailState("Cant find %s Signature in gamedata file", NAME_DoAnimationEvent); }
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	sdkDoAnim = EndPrepSDKCall();
	if (sdkDoAnim == null)
	{ SetFailState("Cant initialize %s SDKCall, Signature broken", NAME_DoAnimationEvent); }
	
	hSequenceSet = DHookCreateDetour(Address_Null, CallConv_THISCALL, ReturnType_Int, ThisPointer_CBaseEntity);
	DHookSetFromConf(hSequenceSet, hConf, SDKConf_Signature, NAME_SelectWeightedSequence);
	DHookAddParam(hSequenceSet, HookParamType_Int);
	DHookEnableDetour(hSequenceSet, false, OnSequenceSet_Pre);
	DHookEnableDetour(hSequenceSet, true, OnSequenceSet);
	
	delete hConf;
}

bool RealValidEntity(int entity)
{
	if (entity <= 0 || !IsValidEntity(entity)) return false;
	return true;
}

void GetGamedata()
{
	static char filePath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, filePath, sizeof(filePath), "gamedata/%s.txt", GAMEDATA);
	if( FileExists(filePath) )
	{
		hConf = LoadGameConfigFile(GAMEDATA); // For some reason this doesn't return null even for invalid files, so check they exist first.
	}
	else
	{
		PrintToServer("[SM] %s unable to get %i.txt gamedata file. Generating...", PLUGIN_NAME, GAMEDATA);
		
		Handle fileHandle = OpenFile(filePath, "a+");
		if (fileHandle == null)
		{ SetFailState("[SM] Couldn't generate gamedata file!"); }
		
		WriteFileLine(fileHandle, "\"Games\"");
		WriteFileLine(fileHandle, "{");
		WriteFileLine(fileHandle, "	\"left4dead2\"");
		WriteFileLine(fileHandle, "	{");
		WriteFileLine(fileHandle, "		\"Signatures\"");
		WriteFileLine(fileHandle, "		{");
		WriteFileLine(fileHandle, "			\"%s\"", NAME_SelectWeightedSequence);
		WriteFileLine(fileHandle, "			{");
		WriteFileLine(fileHandle, "				\"library\"	\"server\"");
		WriteFileLine(fileHandle, "				\"linux\"	\"%s\"", SIG_SelectWeightedSequence_LINUX);
		WriteFileLine(fileHandle, "				\"windows\"	\"%s\"", SIG_SelectWeightedSequence_WINDOWS);
		WriteFileLine(fileHandle, "				\"mac\"		\"%s\"", SIG_SelectWeightedSequence_LINUX);
		WriteFileLine(fileHandle, "			}");
		WriteFileLine(fileHandle, "			\"%s\"", NAME_DoAnimationEvent);
		WriteFileLine(fileHandle, "			{");
		WriteFileLine(fileHandle, "				\"library\"	\"server\"");
		WriteFileLine(fileHandle, "				\"linux\"	\"%s\"", SIG_DoAnimationEvent_LINUX);
		WriteFileLine(fileHandle, "				\"windows\"	\"%s\"", SIG_DoAnimationEvent_WINDOWS);
		WriteFileLine(fileHandle, "				\"mac\"		\"%s\"", SIG_DoAnimationEvent_LINUX);
		WriteFileLine(fileHandle, "			}");
		WriteFileLine(fileHandle, "	}");
		WriteFileLine(fileHandle, "}");
		
		CloseHandle(fileHandle);
		hConf = LoadGameConfigFile(GAMEDATA);
		if (hConf == null)
		{ SetFailState("[SM] Failed to load auto-generated gamedata file!"); }
		
		PrintToServer("[SM] %s successfully generated %s.txt gamedata file!", PLUGIN_NAME, GAMEDATA);
	}
	PrepSDKCall();
}