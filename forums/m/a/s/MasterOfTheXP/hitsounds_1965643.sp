#include <sdktools>
#include <cstrike>

#define PLUGIN_VERSION "1.0"
public Plugin:myinfo = {
	name = "Hitsounds",
	author = "MasterOfTheXP",
	description = "Let's do the fork in the garbage disposal!",
	version = PLUGIN_VERSION,
	url = "http://mstr.ca/"
};

new bool:HitsoundsEnabled[MAXPLAYERS + 1];

new Handle:cvarDisplayDamage;
new Handle:cvarRules;
new Handle:cvarFriendlyFire;

new Handle:aSmokes;

public OnPluginStart()
{
	RegAdminCmd("hitsound", Command_togglesounds, 0);
	RegAdminCmd("hitsounds", Command_togglesounds, 0);
	RegAdminCmd("cs_dingalingaling", Command_togglesounds, 0);
	
	HookEvent("player_hurt", Event_Hurt);
	HookEvent("smokegrenade_detonate", Event_SmokeDetonate);
	HookEvent("smokegrenade_expired", Event_SmokeRemoved);
	HookEvent("round_start", Event_RoundStart);
	
	CreateConVar("sm_hitsoundscsgo_version", PLUGIN_VERSION, "Donut Touch", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY);
	cvarDisplayDamage = CreateConVar("sm_hitsounds_displaydamage", "1", "Display damage done to attacker", _, true, 0.0, true, 1.0);
	cvarRules = CreateConVar("sm_hitsounds_rules", "1", "Only play hitsound if target is visible", _, true, 0.0, true, 1.0);
	cvarFriendlyFire = CreateConVar("sm_hitsounds_friendlyfire", "0", "Play hitsound when injuring teammates", _, true, 0.0, true, 1.0);
	
	aSmokes = CreateArray(3);
}

public OnMapEnd() ClearArray(aSmokes);

public OnClientConnected(client) HitsoundsEnabled[client] = false;

public Action:Command_togglesounds(client, args)
{
	if (!client) return Plugin_Continue;
	HitsoundsEnabled[client] = !HitsoundsEnabled[client];
	ReplyToCommand(client, "\x01You've %sabled hitsounds.", HitsoundsEnabled[client] ? "en" : "dls");
	return Plugin_Handled;
}

public Action:Event_Hurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Handle:data; // Delay it to a frame later. If we use IsPlayerAlive(victim) here, it would always return true.
	CreateDataTimer(0.0, Timer_Hitsound, data, TIMER_FLAG_NO_MAPCHANGE);
	WritePackCell(data, GetEventInt(event, "attacker"));
	WritePackCell(data, GetEventInt(event, "userid"));
	WritePackCell(data, GetEventInt(event, "dmg_health"));
	ResetPack(data);
	
}
public Action:Timer_Hitsound(Handle:timer, Handle:data)
{
	new attacker	= GetClientOfUserId(ReadPackCell(data));
	new victim		= GetClientOfUserId(ReadPackCell(data));
	new damage		= ReadPackCell(data);
	if (!HitsoundsEnabled[attacker]) return;
	if (attacker <= 0 || attacker > MaxClients || victim <= 0 || victim > MaxClients || attacker == victim) return;
	if (GetClientTeam(attacker) == GetClientTeam(victim) && !GetConVarBool(cvarFriendlyFire)) return;
	if (IsPlayerAlive(victim) && GetConVarBool(cvarRules))
	{
		new numSmokes = GetArraySize(aSmokes), closest = -1, Float:closestdist = 600.0;
		if (numSmokes)
		{
			new Float:VictimPos[3];
			GetClientAbsOrigin(victim, VictimPos);
			for (new i = 0; i < numSmokes; i++)
			{
				decl Float:thisPos[3];
				GetArrayArray(aSmokes, i, thisPos, 3);
				new Float:dist = GetVectorDistance(VictimPos, thisPos);
				if (dist > closestdist) continue;
				closest = i, closestdist = dist;
			}
			if (closest > -1) return;
		}
		if (!HasClearSight(attacker, victim)) return;
	}
	ClientCommand(attacker, "playgamesound training/bell_normal.wav");
	if (GetConVarBool(cvarDisplayDamage)) PrintHintText(attacker, "%i", damage);
}

public Action:Event_SmokeDetonate(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Float:Pos[3];
	Pos[0] = GetEventFloat(event, "x");
	Pos[1] = GetEventFloat(event, "y");
	Pos[2] = GetEventFloat(event, "z");
	PushArrayArray(aSmokes, Pos, 3);
}

public Action:Event_SmokeRemoved(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Float:Pos[3];
	Pos[0] = GetEventFloat(event, "x");
	Pos[1] = GetEventFloat(event, "y");
	Pos[2] = GetEventFloat(event, "z");
	new numSmokes = GetArraySize(aSmokes), closest = -1, Float:closestdist = 400.0;
	for (new i = 0; i < numSmokes; i++)
	{
		decl Float:thisPos[3];
		GetArrayArray(aSmokes, i, thisPos, 3);
		new Float:dist = GetVectorDistance(Pos, thisPos);
		if (dist > closestdist) continue;
		closest = i, closestdist = dist;
	}
	if (closest == -1) return;
	RemoveFromArray(aSmokes, closest);
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
	ClearArray(aSmokes);
	
stock HasClearSight(client, target)
{
	new Float:ClientPos[3], Float:TargetPos[3], Float:Result[3];
	GetClientEyePosition(client, ClientPos);
	GetClientAbsOrigin(target, TargetPos);
	TargetPos[2] += 32.0;
	
	MakeVectorFromPoints(ClientPos, TargetPos, Result);
	GetVectorAngles(Result, Result);
	
	TR_TraceRayFilter(ClientPos, Result, MASK_SOLID, RayType_Infinite, TraceRayDontHitSelf, client);
	return target == TR_GetEntityIndex();
}
public bool:TraceRayDontHitSelf(Ent, Mask, any:Hit) return Ent != Hit;