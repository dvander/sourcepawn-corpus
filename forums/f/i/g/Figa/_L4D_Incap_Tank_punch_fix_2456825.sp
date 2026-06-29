#pragma semicolon 1
#include <sdkhooks>

#define PLUGIN_AUTHOR "DeathChaos25, Figa"
#define PLUGIN_VERSION "1.1"

#include <sourcemod>
#include <sdktools>

new bool:gotslapped;

public Plugin:myinfo = 
{
	name = "[L4D] Incap Survivor Tank Punch FLY", 
	author = PLUGIN_AUTHOR, 
	description = "Allows survivors to be sent flying if punched by a tank while incapped", 
	version = PLUGIN_VERSION, 
	url = "https://forums.alliedmods.net/showthread.php?t=264599"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	char s_GameFolder[32];
	GetGameFolderName(s_GameFolder, sizeof(s_GameFolder));
	if (!StrEqual(s_GameFolder, "left4dead", false))
	{
		strcopy(error, err_max, "This plugin is for Left 4 Dead Only!");
		return APLRes_Failure;
	}
	return APLRes_Success;
}
public OnPluginStart()
{
	CreateConVar("sm_tank_incap_fix", PLUGIN_VERSION, "[L4D] Incap Tank Punch Version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	HookEvent("player_hurt", PlayerHurt_Event);
}
public PlayerHurt_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if (!IsSurvivor(victim))
	{
		return;
	}
	if (IsIncaped(victim))
	{
		if (attacker > 0 && GetClientTeam(attacker) == 3)
		{
			new class = GetEntProp(attacker, Prop_Send, "m_zombieClass");
			if (class != 5) return;
			
			new damage = GetEventInt(event, "health");
			SetIncapState(victim, 0);
			SetHealth(victim, 1);
			Handle pack = CreateDataPack();
			WritePackCell(pack, damage);
			WritePackCell(pack, GetClientUserId(victim));
			CreateTimer(0.01, DamageDelay, pack, TIMER_FLAG_NO_MAPCHANGE | TIMER_DATA_HNDL_CLOSE);
			if (!gotslapped)
			{
				gotslapped = true;
				CreateTimer(2.0, ResetSlapped);
				decl Float:fPos[3], Float:fClientPos[3], Float:fDistance;
				for (new i = 1; i <= MaxClients; i++)
				{
					if (IsClientInGame(i) && IsPlayerAlive(i) && i != victim && !IsIncaped(i))
					{
						GetEntPropVector(attacker, Prop_Send, "m_vecOrigin", fPos);
						GetClientAbsOrigin(i, fClientPos);
						fDistance = GetVectorDistance(fClientPos, fPos);
						//new Float:RandomDamage = GetRandomFloat(5.0, 30.0);
						if (fDistance <= 200.0)
						{
							if (0.0 <= fDistance <= 50.0) SDKHooks_TakeDamage(i, attacker, attacker, 20.0, DMG_GENERIC);
							else if (50.0 < fDistance <= 100.0) SDKHooks_TakeDamage(i, attacker, attacker, 10.0, DMG_GENERIC);
							else if (100.0 < fDistance <= 200.0) SDKHooks_TakeDamage(i, attacker, attacker, 5.0, DMG_GENERIC);
							
							decl Float:HeadingVector[3], Float:AimVector[3];
							new Float:power = 150.0;

							GetClientEyeAngles(attacker, HeadingVector);
						
							AimVector[0] = FloatMul( Cosine( DegToRad(HeadingVector[1])  ) , power);
							AimVector[1] = FloatMul( Sine( DegToRad(HeadingVector[1])  ) , power);
							
							decl Float:current[3];
							GetEntPropVector(i, Prop_Data, "m_vecVelocity", current);
							
							decl Float:resulting[3];
							resulting[0] = FloatAdd(current[0], AimVector[0]);	
							resulting[1] = FloatAdd(current[1], AimVector[1]);
							resulting[2] = power*2;
							
							TeleportEntity(i, NULL_VECTOR, NULL_VECTOR, resulting);
						}
					}
				}
			}
		}
	}
}
public Action:DamageDelay(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new damage = ReadPackCell(pack);
	new victim = GetClientOfUserId(ReadPackCell(pack));
	if (!IsSurvivor(victim))
	{
		return;
	}
	SetIncapState(victim, 1);
	SetHealth(victim, damage);
}
// stock bools
stock bool:IsSurvivor(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2)
	{
		return true;
	}
	return false;
}
stock bool:IsInfected(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 1)
	{
		return true;
	}
	return false;
}
stock bool:IsIncaped(client)
{
	return bool:GetEntProp(client, Prop_Send, "m_isIncapacitated", 1);
}
stock SetIncapState(client, isIncapacitated)
{
	SetEntProp(client, Prop_Send, "m_isIncapacitated", isIncapacitated);
}
stock SetHealth(client, health)
{
	SetEntProp(client, Prop_Send, "m_iHealth", health);
}
public Action:ResetSlapped(Handle:timer)
{
	gotslapped = false;
}