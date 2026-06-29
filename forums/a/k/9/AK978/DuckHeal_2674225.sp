#include <sourcemod>
#include <sdktools>


new Handle:duck_heal;
new Handle:HealClientTimer[66];
new Handle:ducktimeout;
new Handle:ducktimestar;
new Handle:PlayerDuckhealTimer[66];


public OnPluginStart()
{
	duck_heal = CreateConVar("duck_heal", "1", "恢復的血量");
	ducktimeout = CreateConVar("duck_time_out", "1", "恢復血量持續時間");
	ducktimestar = CreateConVar("duck_time_star", "多少秒恢復一次");
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_spawn", Event_Player_Spawn);
	
	AutoExecConfig(true, "Duck_Heal");
}

public OnMapStart()
{
	PrecacheSound("ui/helpful_event_1.wav", true);
}

public OnClientDisconnect(Client)
{
	if (HealClientTimer[Client] != INVALID_HANDLE)
	{
		KillTimer(HealClientTimer[Client]);
		HealClientTimer[Client] = INVALID_HANDLE;		
	}
}
public Action:Event_RoundStart(Handle:event, String:name[], bool:dontBroadcast)
{
	CreateTimer(30.0, KillHealTime);
	CreateTimer(40.0, DuckHeal);
}

public Action:KillHealTime(Handle:timer)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (HealClientTimer[i] != INVALID_HANDLE)
		{
			KillTimer(HealClientTimer[i]);
			HealClientTimer[i] = INVALID_HANDLE;		
		}
	}
}

public Action:DuckHeal(Handle:timer)
{
	new Float:timestar = GetConVarFloat(ducktimestar);
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsSurvivor(i))
		{
			if (!HealClientTimer[i])
			{
				HealClientTimer[i] = CreateTimer(timestar, ChargeTimer, i, 1);
			}
		}
	}
}

public Action:Event_PlayerDeath(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsSurvivor(client))
	{
		if (HealClientTimer[client])
		{
			KillTimer(HealClientTimer[client]);
			HealClientTimer[client] = INVALID_HANDLE;
		}
	}
}

public Action:Event_Player_Spawn(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (IsSurvivor(client))
	{
		if (HealClientTimer[client] != INVALID_HANDLE)
		{
			KillTimer(HealClientTimer[client]);
			HealClientTimer[client] = INVALID_HANDLE;		
		}
		CreateTimer(10.0, DuckHeal);
	}
}

public Action:ChargeTimer(Handle:timer, any:client)
{
	new buttons;
	new HP = GetClientHealth(client);
	new Float:timeout = GetConVarFloat(ducktimeout);
	buttons = GetClientButtons(client);
	if (buttons & 4)
	{
		if (IsPlayerIncapped(client))
		{
			return Plugin_Handled;
			
			//new damage = GetConVarInt(duck_heal);
			//SetEntProp(client, PropType:1, "m_iHealth", damage + HP, 4, 0);
		}	
		new MaxHP = GetEntProp(client, PropType:1, "m_iMaxHealth", 4, 0);
		if (MaxHP > HP)
		{
			new damage = GetConVarInt(duck_heal);
			new Float:NowLocation[3] = 0.0;
			GetClientAbsOrigin(client, NowLocation);
			EmitAmbientSound("ui/helpful_event_1.wav", NowLocation, 0, 75, 0, 1.0, 100, 0.0);
			SetEntProp(client, PropType:1, "m_iHealth", damage + HP, 4, 0);
			ScreenFade(client, 200, 0, 0, 200, 100, 1);
			CreateTimer(timeout, DuckhealTimer, client, 0);
		}
		else
		{
			if (MaxHP < HP)
			{
				SetEntProp(client, PropType:1, "m_iHealth", MaxHP, 4, 0);
			}
		}
	}
	return Plugin_Continue;
}

public Action:DuckhealTimer(Handle:timer, any:client)
{
	if (PlayerDuckhealTimer[client])
	{
		KillTimer(PlayerDuckhealTimer[client]);
		PlayerDuckhealTimer[client] = INVALID_HANDLE;
	}
}

public ScreenFade(target, red, green, blue, alpha, duration, type)
{
	new Handle:msg = StartMessageOne("Fade", target, 0);
	BfWriteShort(msg, 500);
	BfWriteShort(msg, duration);
	if (type)
	{
		BfWriteShort(msg, 17);
	}
	else
	{
		BfWriteShort(msg, 10);
	}
	BfWriteByte(msg, red);
	BfWriteByte(msg, green);
	BfWriteByte(msg, blue);
	BfWriteByte(msg, alpha);
	EndMessage();
}

bool:IsPlayerIncapped(Client)
{
	if (GetEntProp(Client, PropType:0, "m_isIncapacitated", 4, 0) == 1)
	{
		return true;
	}
	return false;
}

stock bool:IsSurvivor(client) 
{
	if (IsValidClient(client)) 
	{
		if (GetClientTeam(client) == 2) 
		{
			return true;
		}
	}
	return false;
}

stock bool:IsValidClient(client) 
{
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) return false;      
    return true; 
}