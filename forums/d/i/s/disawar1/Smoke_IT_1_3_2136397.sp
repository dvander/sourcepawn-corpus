#define PLUGIN_VERSION "1.3"
#include <sourcemod>
#include <sdktools>
#pragma semicolon 1
#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY

new Float:f_SmokersSpeed;
new bool:Grabbed[MAXPLAYERS+1];
new TongueMaxStretch;

public Plugin:myinfo =

{
	name = "Smoke'n Move",
	author = "Olj, raziEiL [disawar1]",
	description = "Wanna move while smoking? No problem!",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
}

public OnPluginStart()
{
	CreateConVar("l4d_smokeit_version", PLUGIN_VERSION, "Version of Smoke It plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	new Handle:h_SmokersSpeed = CreateConVar("l4d_smokeit_speed", "0.42", "Smoker's speed modifier", CVAR_FLAGS);
	new Handle:h_TongueMaxStretch = CreateConVar("l4d_smokeit_tongue_stretch", "950", "Smoker's max tongue stretch (tongue will be released if beyond this)", CVAR_FLAGS);
	f_SmokersSpeed = GetConVarFloat(h_SmokersSpeed);
	TongueMaxStretch = GetConVarInt(h_TongueMaxStretch);
	HookConVarChange(h_SmokersSpeed, SmokersSpeedChanged);
	HookConVarChange(h_TongueMaxStretch, TongueMaxStretchChanged);
	HookEvent("tongue_grab", GrabEvent, EventHookMode_Pre);
	HookEvent("tongue_release", ReleaseEvent, EventHookMode_Pre);
	AutoExecConfig(true, "l4d_smokeit");
}

public SmokersSpeedChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	f_SmokersSpeed = GetConVarFloat(convar);
}

public TongueMaxStretchChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	TongueMaxStretch = GetConVarInt(convar);
}

public OnClientPutInServer(client)
{
	Grabbed[client] = false;
}

public GrabEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Smoker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsFakeClient(Smoker)) return;
	Grabbed[Smoker] = true;
	new Victim = GetClientOfUserId(GetEventInt(event, "victim"));
	SetEntityMoveType(Smoker, MOVETYPE_ISOMETRIC);
	SetEntPropFloat(Smoker, Prop_Send, "m_flLaggedMovementValue", f_SmokersSpeed);
	decl Handle:pack;
	CreateDataTimer(0.2, RangeCheckTimerFunction, pack, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	WritePackCell(pack, Smoker);
	WritePackCell(pack, Victim);
}

public Action:RangeCheckTimerFunction(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new Smoker = ReadPackCell(pack);

	if (!Grabbed[Smoker])
		return Plugin_Stop;

	new Victim = ReadPackCell(pack);

	if (!IsValidClient(Smoker) || GetClientTeam(Smoker) != 3 || IsFakeClient(Smoker) || !IsSmoker(Smoker) || !IsValidClient(Victim) || GetClientTeam(Victim) != 2)
	{
		Grabbed[Smoker] = false;
		return Plugin_Stop;
	}

	decl Float:SmokerPosition[3], Float:VictimPosition[3];
	GetClientAbsOrigin(Smoker,SmokerPosition);
	GetClientAbsOrigin(Victim,VictimPosition);

	if (RoundToNearest(GetVectorDistance(SmokerPosition, VictimPosition)) > TongueMaxStretch)
	{
		SlapPlayer(Smoker, 0, false);
	}
	return Plugin_Continue;
}

public ReleaseEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Smoker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!Grabbed[Smoker]) return;
	Grabbed[Smoker] = false;
	SetEntityMoveType(Smoker, MOVETYPE_CUSTOM);
	SetEntPropFloat(Smoker, Prop_Send, "m_flLaggedMovementValue", 1.0);
}

bool:IsValidClient(client)
{
	return client && IsClientInGame(client) && IsPlayerAlive(client);
}

bool:IsSmoker(client)
{
	return GetEntProp(client, Prop_Send, "m_zombieClass") == 1;
}