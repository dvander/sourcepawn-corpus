#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.3"

new propinfoghost;
new bool:jumpdelay[MAXPLAYERS+1];
new Handle:Boomerbool = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "L4D_Ghostpounce",
	author = " AtomicStryker",
	description = "Left 4 Dead Ghost Leap",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=99519"
}

public OnPluginStart()
{
	propinfoghost = FindSendPropInfo("CTerrorPlayer", "m_isGhost");
	CreateConVar("l4d_ghostpounce_version", PLUGIN_VERSION, " Ghost Leap Plugin Version ", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	Boomerbool = CreateConVar("l4d_ghostpounce_boomerallowed", "1", "Allow or Disallow Boomers to Ghost Pounce", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);

	AutoExecConfig(true, "l4d_ghostpounce");
}

public OnGameFrame()
{
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			new buttons = GetEntProp(i, Prop_Data, "m_nButtons", buttons);
			if(buttons & IN_RELOAD && jumpdelay[i] == false)
			{
				PlayerPressesAttack2(i);
			}
		}
	}
}

public Action:PlayerPressesAttack2(client)
{
	if (GetClientTeam(client)!=3) return Plugin_Continue;
	if (!IsPlayerSpawnGhost(client)) return Plugin_Continue;
	
	if (!GetConVarBool(Boomerbool))
	{
		decl String:playerclass[36];
		GetClientModel(client, playerclass, sizeof(playerclass));
		if (StrContains(playerclass, "boomer", false) != -1)
		{
			PrintCenterText(client, "This server disallows Boomers to Ghost Pounce");
			return Plugin_Continue;
		}
	}
	
	jumpdelay[client] = true;
	CreateTimer(1.0, ResetJumpDelay, client);
	DoPounce(client);
	return Plugin_Continue;
}

DoPounce(any:client)
{
	decl Float:vec[3];
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", vec);
	
	if (vec[2] != 0)
	{
		PrintCenterText(client, "You must be on even ground to ghost pounce");
		return;
	}
	if (vec[0] == 0 && vec[1] == 0)
	{
		PrintCenterText(client, "You must be on the move to ghost pounce");
		return;
	}
	
	vec[0] *= 3;
	vec[1] *= 3;
	vec[2] = 750.0;
	
	TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vec);
}

bool:IsPlayerSpawnGhost(client)
{
	if (GetEntData(client, propinfoghost, 1)) return true;
	else return false;
}

public Action:ResetJumpDelay(Handle:timer, Handle:client)
{
	jumpdelay[client] = false;
}