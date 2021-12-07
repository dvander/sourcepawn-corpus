#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

public Plugin:myinfo = 
{
	name = "CTrun",
	author = "Eun",
	description = "Allows CT's to pick up the bomb and run away.",
	version = "1.3SM",
	url = ""
}

new C4 = -1;
new bool:CtPicking;
new Handle:TmrBombPickup = INVALID_HANDLE;
new Handle:ctrun_allow_plant;
new Handle:ctrun_enabled;
public OnPluginStart()
{

	ctrun_allow_plant = CreateConVar("ctrun_allow_plant", "0", "Allow CT's to plant the bomb?", FCVAR_PLUGIN);
	ctrun_enabled = CreateConVar("ctrun_enabled", "1", "CTrun is enabled", FCVAR_PLUGIN);
	CreateConVar("ctrun_ver", "1.3SM", "Version of CTrun that you are using.", FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_SPONLY);

	HookEvent("round_start", RoundStart);
	HookEvent("round_end", RoundEnd);
	HookEvent("bomb_pickup", BombPickup);
	HookEvent("bomb_dropped", BombDropped);
		
}

public Action:RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	CtPicking = false;
	TmrBombPickup = INVALID_HANDLE;
	if (GetConVarBool(ctrun_enabled))
		C4 = FindC4();
}

public Action:RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (TmrBombPickup != INVALID_HANDLE)
	{
		KillTimer(TmrBombPickup);
		TmrBombPickup = INVALID_HANDLE;
	}
}  

public Action:BombPickup(Handle:event, const String:name[], bool:dontBroadcast )
{
	if (!CtPicking && !GetConVarBool(ctrun_allow_plant))
		BombZones(true);
	if (TmrBombPickup != INVALID_HANDLE)
	{
		KillTimer(TmrBombPickup);
		TmrBombPickup = INVALID_HANDLE;
	}
}

public Action:BombDropped(Handle:event, const String:name[], bool:dontBroadcast )
{
	CtPicking = false;
	if (GetConVarBool(ctrun_enabled))
		TmrBombPickup = CreateTimer(0.5, CTPickupBomb, _, TIMER_REPEAT);
}



public Action:CTPickupBomb(Handle:timer)
{
	new Float:bomborigin[3];
	new Float:origin[3];
	
	if (C4 == -1 || !IsValidEntity(C4))
		return Plugin_Continue;
	
	GetEntPropVector(C4, Prop_Data, "m_vecOrigin", bomborigin);
	
	for(new i=0;i<=MaxClients;i++)
		if ( IsValidEdict(i) && IsValidEntity(i) )
		{
			if (GetEntProp(i, Prop_Data, "m_lifeState") == 0 && GetEntProp(i, Prop_Data, "m_iTeamNum") == 3)
			{
				GetEntPropVector(i, Prop_Data, "m_vecOrigin", origin);
				if (GetVectorDistance(bomborigin, origin) <= 75)
				{
					CtPicking = true;
					if (!GetConVarBool(ctrun_allow_plant))
						BombZones(false);
					GiveC4(i);
					return Plugin_Continue;
				}
				
				
			}
		}
	return Plugin_Continue;
}


public FindC4()
{
	new maxent = GetMaxEntities(), String:weapon[64];
	for (new i=MaxClients;i<maxent;i++)
	{
		if ( IsValidEdict(i) && IsValidEntity(i) )
		{
			GetEdictClassname(i, weapon, sizeof(weapon));
			if ( StrContains(weapon, "weapon_c4") != -1 )
				return i;
		}
	}
	return -1;
}

public GiveC4(client)
{
	new bool:SwitchTeam = (GetEntProp(client, Prop_Data, "m_iTeamNum") == 3);
		
	AcceptEntityInput(C4, "Kill");
	if (SwitchTeam)
		SetEntProp(client, Prop_Data, "m_iTeamNum", 2);
	C4 = GivePlayerItem(client, "weapon_c4", 0);
	if (SwitchTeam)
		SetEntProp(client, Prop_Data, "m_iTeamNum", 3);
}

public BombZones(disable)
{
	new maxent = GetMaxEntities(), String:entity[64];
	for (new i=MaxClients + 1;i<=maxent;i++)
	{
		if ( IsValidEdict(i) && IsValidEntity(i) )
		{
			GetEdictClassname(i, entity, sizeof(entity));
			if (StrContains(entity, "func_bomb_target") != -1)
			{
				if (!disable)
					AcceptEntityInput(i,"disable");
				else
					AcceptEntityInput(i,"enable");
			}
		}
	}	
}

