#define PLUGIN_VERSION "1.0"
#include <sourcemod>
#include <sdktools>
#pragma semicolon 1
#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY

new speedOffset = -1;
new Handle:h_ChargersSpeed;
new Float:f_ChargersSpeed;
new Handle:RangeCheckTimer[MAXPLAYERS+1];
new bool:Grabbed[MAXPLAYERS+1];

public Plugin:myinfo = 

{
	name = "Charge 'n' Move",
	author = "Olj",
	description = "Wanna move while charging? No problem!",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
}

public OnPluginStart()
{
	CreateConVar("l4d_chargerwalk_version", PLUGIN_VERSION, "Version of Charger Walk plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	h_ChargersSpeed = CreateConVar("l4d_chargewalk_speed", "0.42", "Charger's speed modifier", CVAR_FLAGS);
	speedOffset = FindSendPropInfo("CTerrorPlayer","m_flLaggedMovementValue");
	f_ChargersSpeed = GetConVarFloat(h_ChargersSpeed);
	HookConVarChange(h_ChargersSpeed, ChargersSpeedChanged);
	HookEvent("charger_pummel_start", GrabEvent, EventHookMode_Pre);
	HookEvent("charger_pummel_end", ReleaseEvent, EventHookMode_Pre);
	AutoExecConfig(true, "l4d_chargewalk");
}

public ChargersSpeedChanged(Handle:convar, const String:oldValue[], const String:newValue[])
	{
		f_ChargersSpeed = GetConVarFloat(h_ChargersSpeed);
	}			

	
public Action:GrabEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Charger = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsFakeClient(Charger)) return Plugin_Continue;
	new Handle:pack;
	Grabbed[Charger] = true;
	new Victim = GetClientOfUserId(GetEventInt(event, "victim"));
	SetEntityMoveType(Charger, MOVETYPE_ISOMETRIC);
	SetEntDataFloat(Charger, speedOffset, f_ChargersSpeed, true);
	RangeCheckTimer[Charger] = CreateDataTimer(0.2, RangeCheckTimerFunction, pack, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	WritePackCell(pack, Charger);
	WritePackCell(pack, Victim);
	//new Float:speed = GetEntDataFloat(Charger, speedOffset);
	//PrintToChatAll("Speed: %f", speed);
	return Plugin_Continue;
}

public Action:RangeCheckTimerFunction(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new Charger = ReadPackCell(pack);
	if ((!IsValidClient(Charger))||(GetClientTeam(Charger)!=3)||(IsFakeClient(Charger))||(Grabbed[Charger] = false))
			{
				RangeCheckTimer[Charger] = INVALID_HANDLE;
				return Plugin_Stop;
			}
			
	new Victim = ReadPackCell(pack);
	if ((!IsValidClient(Victim))||(GetClientTeam(Victim)!=2)||(Grabbed[Charger] = false))
			{
				RangeCheckTimer[Charger] = INVALID_HANDLE;
				return Plugin_Stop;
			}
			
	new Float:ChargerPosition[3];
	new Float:VictimPosition[3];
	GetClientAbsOrigin(Charger,ChargerPosition);
	GetClientAbsOrigin(Victim,VictimPosition);
	return Plugin_Continue;
}

public Action:ReleaseEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Charger = GetClientOfUserId(GetEventInt(event, "userid"));
	Grabbed[Charger] = false;
	SetEntityMoveType(Charger, MOVETYPE_CUSTOM);
	SetEntDataFloat(Charger, speedOffset, 1.0, true);
	if (RangeCheckTimer[Charger] != INVALID_HANDLE)
				{
					KillTimer(RangeCheckTimer[Charger], true);
					RangeCheckTimer[Charger] = INVALID_HANDLE;
				}
	//new Float:speed = GetEntDataFloat(Charger, speedOffset);
	//PrintToChatAll("Release Event Fired, Speed: %f", speed);
}

public IsValidClient(client)
{
	if (client == 0)
		return false;
	
	if (!IsClientConnected(client))
		return false;
	
	//if (IsFakeClient(client))
		//return false;
	
	if (!IsClientInGame(client))
		return false;
	
	if (!IsPlayerAlive(client))
		return false;
	return true;
}