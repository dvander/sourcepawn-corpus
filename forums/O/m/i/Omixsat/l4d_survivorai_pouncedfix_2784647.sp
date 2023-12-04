#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.2.2"
#define PLUGIN_NAME "[L4D1 & L4D2] Survivor AI Pounced Fix"
#define DEBUG 0

#pragma semicolon 1;
#pragma newdecls required;

public Plugin myinfo = {
	name = PLUGIN_NAME,
	author = "AtomicStryker, Merudo, Omixsat",
	description = " Fixes Survivor Bots neglecting Teammates in need ",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=99664"
};

static bool IsL4D2 = false;
static bool IsTongued[MAXPLAYERS+1] = { false, ...};
ConVar Cvar_Range;
ConVar Cvar_Delay;
static float TimeLastOrder[MAXPLAYERS+1];

public void OnPluginStart()
{
	CheckGame();
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Post);
	HookEvent("tongue_grab", Event_Tongued, EventHookMode_Post);
	HookEvent("tongue_release", Event_Saved, EventHookMode_Post);
	HookEvent("choke_end", Event_Saved, EventHookMode_Post);
	HookEvent("choke_start", Event_Dominated, EventHookMode_PostNoCopy);	
	HookEvent("lunge_pounce", Event_Dominated, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	if(IsL4D2 == true)
	{
		HookEvent("jockey_ride", Event_Dominated, EventHookMode_PostNoCopy);
		HookEvent("charger_pummel_start", Event_Dominated, EventHookMode_PostNoCopy);
		//HookEvent("charger_carry_start", Event_Dominated, EventHookMode_PostNoCopy);	
	}
	CreateConVar("l4d_survivoraipouncedfix_version", PLUGIN_VERSION, " Version of L4D Survivor AI Pounced Fix on this server ", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	Cvar_Range = CreateConVar("l4d_survivoraipouncedfix_range", "800", "Maximum range the survivor bots will go after infected", FCVAR_NOTIFY);
	Cvar_Delay = CreateConVar("l4d_survivoraipouncedfix_delay", "0.5", "Delay, in seconds, before survivor bot takes another order", FCVAR_NOTIFY);	
	
	AutoExecConfig(true, "l4d_survivoraipouncedfix");
	
}

// ------------------------------------------------------------------------
// When a player is hurt and getting dominated, call the bots
// ------------------------------------------------------------------------
Action Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	static int attacker;
	static int victim;
	attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	victim = GetClientOfUserId(GetEventInt(event, "userid"));

	if(attacker > 0 && victim > 0)
	{
		if(attacker <= MaxClients && victim <= MaxClients && IsClientInGame(attacker) && IsClientInGame(victim) && GetClientTeam(attacker) == 3 && GetClientTeam(victim) == 2)
		{
			if (FindDominator(victim) == attacker)
			{
				CallBots();
				#if DEBUG
					PrintToChatAll("%N is in trouble!", victim);
				#endif
			}
		}
	}
	
	return Plugin_Continue;
}

Action Event_Tongued(Event event, const char[] name, bool dontBroadcast)
{
	static int attacker;
	static int victim;
	attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	victim = GetClientOfUserId(GetEventInt(event, "victim"));
	IsTongued[victim] = true;
	#if DEBUG
		PrintToChatAll("%N is tongued by %N. Tongued Status: %i", victim, attacker, IsTongued[victim]);
	#endif
	static float EyePos[3];
	static float AimOnDominator[3];
	static float AimAngles[3];
	static float DominatorPos[3];
	if(isVisibleTo(victim,attacker,1) && IsFakeClient(victim))
	{
		GetClientAbsOrigin(attacker, DominatorPos);
		GetClientEyePosition(victim, EyePos);
		MakeVectorFromPoints(EyePos, DominatorPos, AimOnDominator); //position is the attackers pos
		GetVectorAngles(AimOnDominator, AimAngles);
		if(IsL4D2)
		{
			L4D2_RunScript("CommandABot({cmd=3,bot=GetPlayerFromUserID(%i)})", GetClientUserId(victim)); //Stop all actions and shoot
			L4D2_RunScript("CommandABot({cmd=0,bot=GetPlayerFromUserID(%i),target=GetPlayerFromUserID(%i)})", GetClientUserId(victim), GetClientUserId(attacker));
			TeleportEntity(victim, NULL_VECTOR, AimAngles, NULL_VECTOR);
			#if DEBUG
				PrintToChatAll("GAME - L4D2: %N tongued status is %i", victim, IsTongued[victim]);
				PrintToChatAll("GAME - L4D2: %N is performing a TONGUE TWISTER on %N", victim, attacker );
			#endif
		}
		else if(!IsL4D2)
		{
			TeleportEntity(victim, NULL_VECTOR, AimAngles, NULL_VECTOR);
			#if DEBUG
				PrintToChatAll("GAME - L4D1: %N tongued status is %i", victim, IsTongued[victim]);
				PrintToChatAll("GAME - L4D1: %N is performing a TONGUE TWISTER on %N", victim, attacker );
			#endif
		}
	}

	return Plugin_Continue;
}

Action Event_Saved(Event event, const char[] name, bool dontBroadcast)
{
	static int victim;
	victim = GetClientOfUserId(GetEventInt(event, "victim"));
	IsTongued[victim] = false;

	#if DEBUG
		PrintToChatAll("%N tongued status is %i", victim, IsTongued[victim]);
	#endif

	return Plugin_Continue;
}

void Event_Dominated(Event event, const char[] name, bool dontBroadcast)
{
	CallBots();
}

// ------------------------------------------------------------------------
// Each time a survivor is getting damaged by a infected & is dominated, call bots
// Each bot will aim at the closest infected that is dominating a survivor
// ------------------------------------------------------------------------
static void CallBots()
{
	for (int bot = 1; bot <= MaxClients; bot++)
	{
		if (IsClientInGame(bot) && IsPlayerAlive(bot) && GetClientTeam(bot) == 2 && IsFakeClient(bot) && !IsIncapacitated(bot) && !IsReviving(bot)) // make sure bot is a live Survivor Bot that isn't reviving
		{
			if (( GetGameTime() - TimeLastOrder[bot] ) > Cvar_Delay.FloatValue)
			{
				static int target;
				target = FindClosestDominator(bot);
				static float EyePos[3];
				static float AimOnDominator[3];
				static float AimAngles[3];
				static float DominatorPos[3];
				if (!target) continue; // if no target, no command
				TimeLastOrder[bot] =  GetGameTime();
				if(IsL4D2)
				{
					if(FindDominator(bot) == -1 && IsTongued[bot] == false)
					{
						L4D2_RunScript("CommandABot({cmd=0,bot=GetPlayerFromUserID(%i),target=GetPlayerFromUserID(%i)})", GetClientUserId(bot), GetClientUserId(target));
						#if DEBUG
							PrintToChatAll("GAME - L4D2: %N is targeting a %N", bot, target );
						#endif
						if(isVisibleTo(bot,target,1))
						{
							GetClientAbsOrigin(target, DominatorPos);
							GetClientEyePosition(bot, EyePos);
							MakeVectorFromPoints(EyePos, DominatorPos, AimOnDominator); //position is the attackers pos
							GetVectorAngles(AimOnDominator, AimAngles);
							TeleportEntity(bot, NULL_VECTOR, AimAngles, NULL_VECTOR);
							#if DEBUG
								PrintToChatAll("GAME - L4D2: %N is aiming at a %N", bot, target );
							#endif
						}
						if(!isVisibleTo(bot,target,1))
						{
							L4D2_RunScript("CommandABot({cmd=3,bot=GetPlayerFromUserID(%i)})", GetClientUserId(bot));
							#if DEBUG
								PrintToChatAll("GAME - L4D2: %N will attempt to shove pinned survivor", bot);
							#endif
						}
						continue;
					}
					else if (FindDominator(bot) > 0)
					{
						#if DEBUG
							PrintToChatAll("GAME - L4D2: %N is pinned", bot);
						#endif
						continue;
					}
				}
				if(!IsL4D2)
				{
					if(isVisibleTo(bot,target,1) && FindDominator(bot) == -1 && IsTongued[bot] == false)
					{
						GetClientAbsOrigin(target, DominatorPos);
						GetClientEyePosition(bot, EyePos);
						MakeVectorFromPoints(EyePos, DominatorPos, AimOnDominator); //position is the attackers pos
						GetVectorAngles(AimOnDominator, AimAngles);
						TeleportEntity(bot, NULL_VECTOR, AimAngles, NULL_VECTOR);
						#if DEBUG
							PrintToChatAll("GAME - L4D1: %N is aiming at a %N", bot, target );
						#endif
						continue;
					}
					else if (FindDominator(bot) > 0 )
					{
						#if DEBUG
							PrintToChatAll("GAME - L4D1: %N is pinned", bot);
						#endif
						continue;
					}
				}
			}
		}
	}
}

// ------------------------------------------------------------------------
// Find the infected currently dominating that's the closest to the client
// ------------------------------------------------------------------------
static int FindClosestDominator(int client)
{
	static float clientPos[3];
	GetClientAbsOrigin(client, clientPos);
	
	static float dominatorPos[3];
	
	static int target = 0;
	static float dist;
	dist = Cvar_Range.FloatValue;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || GetClientTeam(i) != 2 || !IsPlayerAlive(i) || IsIncapacitated(i))
		{
			continue;
		}
		
		static int dominator;
		dominator = FindDominator(i);
		
		if (dominator > 0 && IsClientInGame(dominator) && IsPlayerAlive(dominator) && GetClientTeam(dominator) == 3)
		{
			GetClientAbsOrigin(dominator, dominatorPos);
			if (GetVectorDistance(clientPos, dominatorPos) < dist)
			{
				target = dominator;
				dist   = GetVectorDistance(clientPos, dominatorPos);
			}
		}
	}
	return target;
}


void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	#if DEBUG
		PrintToChatAll("-----==== IS TONGUED LIST CLEARED ====-----");
	#endif
	for(int i = 1 ; i <= MaxClients; i++)
	{
		IsTongued[i] = false;
	}
}

// ------------------------------------------------------------------------
// Return infected that is dominating the client (-1 if not happening)
// ------------------------------------------------------------------------
static int FindDominator(int client)
{
	if (GetEntPropEnt(client, Prop_Send, "m_tongueOwner")    > 0) return GetEntPropEnt(client, Prop_Send, "m_tongueOwner");
	if (GetEntPropEnt(client, Prop_Send, "m_pounceAttacker") > 0) return GetEntPropEnt(client, Prop_Send, "m_pounceAttacker");
	if (IsL4D2 && GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker") > 0) return GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker");
	if (IsL4D2 && GetEntPropEnt(client, Prop_Send, "m_pummelAttacker") > 0) return GetEntPropEnt(client, Prop_Send, "m_pummelAttacker");
	if (IsL4D2 && GetEntPropEnt(client, Prop_Send, "m_carryAttacker" ) > 0) return GetEntPropEnt(client, Prop_Send, "m_carryAttacker");
	return -1;
}

void L4D2_RunScript(const char[] sCode, any ...)
{
	static int iScriptLogic = INVALID_ENT_REFERENCE;
	if(iScriptLogic == INVALID_ENT_REFERENCE || !IsValidEntity(iScriptLogic)) {
		iScriptLogic = EntIndexToEntRef(CreateEntityByName("logic_script"));
		if(iScriptLogic == INVALID_ENT_REFERENCE || !IsValidEntity(iScriptLogic))
			SetFailState("Could not create 'logic_script'");
		
		DispatchSpawn(iScriptLogic);
	}
	
	static char sBuffer[512];
	VFormat(sBuffer, sizeof(sBuffer), sCode, 2);
	
	SetVariantString(sBuffer);
	AcceptEntityInput(iScriptLogic, "RunScriptCode");
}

static void CheckGame()
{
	char game[32];	GetGameFolderName(game, sizeof(game));
	
	if 		(StrEqual(game, "left4dead",  false))	IsL4D2 = false;	
	else if (StrEqual(game, "left4dead2", false))	IsL4D2 = true;
	else SetFailState("Plugin is for Left For Dead 1/2 only");
}

static bool IsReviving(int client)
{
	if(GetEntPropEnt(client, Prop_Send, "m_reviveTarget") > 0)
		return true;
	return false;
}

static bool traceFilter(int entity, int mask, any self)
{
	return entity != self;
}

static bool IsIncapacitated(int client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1) > 0)
		return true;
	return false;
}

// For L4D1
static bool isVisibleTo(int client, int target, int AimType)
{
	static bool hasVisual = false;
	static float aim_angles[3];
	static float self_pos[3];
	
	GetClientEyePosition(client, self_pos);
	computeAimAngles(client, target, aim_angles, AimType);
	
	Handle trace = TR_TraceRayFilterEx(self_pos, aim_angles, MASK_VISIBLE, RayType_Infinite, traceFilter, client);
	if (TR_DidHit(trace)) {
		static int hit;
		hit = TR_GetEntityIndex(trace);
		if (hit == target) {
			hasVisual = true;
		}
	}

	delete trace;
	return hasVisual;
}

// Calculate the angles from client to target (FOR L4D1)
void computeAimAngles(int client, int target, float angles[3], int type)
{	
	static float target_pos[3];
	static float self_pos[3];
	static float lookat[3];
	
	GetClientEyePosition(client, self_pos);
	switch (type) {
		case 1: { // Eye (Default)
			GetClientEyePosition(target, target_pos);
		}
		case 2: { // Body
			GetEntPropVector(target, Prop_Data, "m_vecAbsOrigin", target_pos);
		}
		case 3: { // Chest
			GetClientAbsOrigin(target, target_pos);
			target_pos[2] += 45.0;
		}
	}
	MakeVectorFromPoints(self_pos, target_pos, lookat);
	GetVectorAngles(lookat, angles);
}