#define PLUGIN_VERSION "1.2"
#include <sourcemod>
#include <sdktools>
#pragma semicolon 1
#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY

new speedOffset = -1;
new Handle:h_SmokersSpeed;
new Float:f_SmokersSpeed;
new Handle:RangeCheckTimer[MAXPLAYERS+1];
new bool:Grabbed[MAXPLAYERS+1];
new Handle:h_TongueMaxStretch;
new TongueMaxStretch;
new TankSpawnID;  //---------------------------- Tank Slap Fix

public Plugin:myinfo = 

{
	name = "Smoke'n Move",
	author = "Olj",
	description = "Wanna move while smoking? No problem!",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
}

public OnPluginStart()
{
	CreateConVar("l4d_smokeit_version", PLUGIN_VERSION, "Version of Smoke It plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	h_SmokersSpeed = CreateConVar("l4d_smokeit_speed", "0.42", "Smoker's speed modifier", CVAR_FLAGS);
	h_TongueMaxStretch = CreateConVar("l4d_smokeit_tongue_stretch", "950", "Smoker's max tongue stretch (tongue will be released if beyond this)", CVAR_FLAGS);
	speedOffset = FindSendPropInfo("CTerrorPlayer","m_flLaggedMovementValue");
	f_SmokersSpeed = GetConVarFloat(h_SmokersSpeed);
	TongueMaxStretch = GetConVarInt(h_TongueMaxStretch);
	HookConVarChange(h_SmokersSpeed, SmokersSpeedChanged);
	HookConVarChange(h_TongueMaxStretch, TongueMaxStretchChanged);
	HookEvent("tongue_grab", GrabEvent, EventHookMode_Pre);
	HookEvent("tongue_release", ReleaseEvent, EventHookMode_Pre);
	HookEvent("tank_spawn", Event_TankSpawn); //---------------------------- Tank Slap Fix
	AutoExecConfig(true, "l4d_smokeit");
}

public SmokersSpeedChanged(Handle:convar, const String:oldValue[], const String:newValue[])
	{
		f_SmokersSpeed = GetConVarFloat(h_SmokersSpeed);
	}			

public TongueMaxStretchChanged(Handle:convar, const String:oldValue[], const String:newValue[])
	{
		TongueMaxStretch = GetConVarInt(h_TongueMaxStretch);
	}
	
			
public Action:Event_TankSpawn(Handle:event, String:event_name[], bool:dontBroadcast) //---------------------------- Tank Slap Fix
{
	TankSpawnID = GetClientOfUserId(GetEventInt(event, "userid"));	
}
	
public Action:GrabEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Smoker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsFakeClient(Smoker)) return Plugin_Continue;
	new Handle:pack;
	Grabbed[Smoker] = true;
	new Victim = GetClientOfUserId(GetEventInt(event, "victim"));
	SetEntityMoveType(Smoker, MOVETYPE_ISOMETRIC);
	SetEntDataFloat(Smoker, speedOffset, f_SmokersSpeed, true);
	RangeCheckTimer[Smoker] = CreateDataTimer(0.2, RangeCheckTimerFunction, pack, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	WritePackCell(pack, Smoker);
	WritePackCell(pack, Victim);
	//new Float:speed = GetEntDataFloat(Smoker, speedOffset);
	//PrintToChatAll("Speed: %f", speed);
	return Plugin_Continue;
}

public Action:RangeCheckTimerFunction(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new Smoker = ReadPackCell(pack);
	
	if ((!IsValidClient(Smoker))||(GetClientTeam(Smoker)!=3)||(IsFakeClient(Smoker))||(Grabbed[Smoker] = false)||(Smoker==TankSpawnID)) //---------------------------- Tank Slap Fix
			{
				RangeCheckTimer[Smoker] = INVALID_HANDLE;
				TankSpawnID = 0;    //---------------------------- Tank Slap Fix
				return Plugin_Stop;
			}
			
	new Victim = ReadPackCell(pack);
	if ((!IsValidClient(Victim))||(GetClientTeam(Victim)!=2)||(Grabbed[Smoker] = false))
			{
				RangeCheckTimer[Smoker] = INVALID_HANDLE;
				return Plugin_Stop;
			}
			
	new Float:SmokerPosition[3];
	new Float:VictimPosition[3];
	GetClientAbsOrigin(Smoker,SmokerPosition);
	GetClientAbsOrigin(Victim,VictimPosition);
	new distance = RoundToNearest(GetVectorDistance(SmokerPosition, VictimPosition));
	//PrintToChatAll("Distance: %i", distance);
	

	if (distance>TongueMaxStretch)
		{
			SlapPlayer(Smoker, 0, false);
			//PrintToChatAll("\x03BREAK");
		}
	return Plugin_Continue;
}

public Action:ReleaseEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Smoker = GetClientOfUserId(GetEventInt(event, "userid"));
	Grabbed[Smoker] = false;
	SetEntityMoveType(Smoker, MOVETYPE_CUSTOM);
	SetEntDataFloat(Smoker, speedOffset, 1.0, true);
	if (RangeCheckTimer[Smoker] != INVALID_HANDLE)
				{
					KillTimer(RangeCheckTimer[Smoker], true);
					RangeCheckTimer[Smoker] = INVALID_HANDLE;
				}
	//new Float:speed = GetEntDataFloat(Smoker, speedOffset);
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