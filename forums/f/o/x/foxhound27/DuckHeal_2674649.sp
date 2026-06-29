#include <sourcemod>
#include <sdktools>


Handle duck_heal;
Handle HealClientTimer[66];
Handle ducktimeout;
Handle ducktimestar;
Handle PlayerDuckhealTimer[66];


public void OnPluginStart()
{
	duck_heal = CreateConVar("duck_heal", "1", "恢復的血量");
	ducktimeout = CreateConVar("duck_time_out", "1", "恢復血量持續時間");
	ducktimestar = CreateConVar("duck_time_star", "多少秒恢復一次");
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_spawn", Event_Player_Spawn);
	
	AutoExecConfig(true, "Duck_Heal");
}

public void OnMapStart()
{
	PrecacheSound("ui/helpful_event_1.wav", true);
}

public void OnClientDisconnect(int Client)
{
	if (HealClientTimer[Client] != INVALID_HANDLE)
	{
		KillTimer(HealClientTimer[Client]);
		HealClientTimer[Client] = INVALID_HANDLE;		
	}
}
public Action Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	CreateTimer(30.0, KillHealTime);
	CreateTimer(40.0, DuckHeal);
}

public Action KillHealTime(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (HealClientTimer[i] != INVALID_HANDLE)
		{
			KillTimer(HealClientTimer[i]);
			HealClientTimer[i] = INVALID_HANDLE;		
		}
	}
}

public Action DuckHeal(Handle timer)
{
	float timestar = GetConVarFloat(ducktimestar);
	
	for (int i = 1; i <= MaxClients; i++)
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

public Action Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsSurvivor(client))
	{
		if (HealClientTimer[client])
		{
			KillTimer(HealClientTimer[client]);
			HealClientTimer[client] = INVALID_HANDLE;
		}
	}
}

public Action Event_Player_Spawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

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

public Action ChargeTimer(Handle timer, any client)
{
	int buttons;
	int HP = GetClientHealth(client);
	float timeout = GetConVarFloat(ducktimeout);
	buttons = GetClientButtons(client);
	if (buttons & 4)
	{
		if (IsPlayerIncapped(client))
		{
			return Plugin_Handled;
			
			//new damage = GetConVarInt(duck_heal);
			//SetEntProp(client, PropType:1, "m_iHealth", damage + HP, 4, 0);
		}	
		int MaxHP = GetEntProp(client, Prop_Data, "m_iMaxHealth");
		if (MaxHP > HP)
		{
			int damage = GetConVarInt(duck_heal);
			float NowLocation[3] = 0.0;
			GetClientAbsOrigin(client, NowLocation);
			EmitAmbientSound("ui/helpful_event_1.wav", NowLocation, 0, 75, 0, 1.0, 100, 0.0);
			SetEntProp(client, Prop_Data, "m_iHealth", damage + HP);
			ScreenFade(client, 200, 0, 0, 200, 100, 1);
			CreateTimer(timeout, DuckhealTimer, client, 0);
		}
		else
		{
			if (MaxHP < HP)
			{
				SetEntProp(client, Prop_Data, "m_iHealth", MaxHP);
			}
		}
	}
	return Plugin_Continue;
}



//prop type 1 Prop_Data
//prop type 0 Prop_Send


public Action DuckhealTimer(Handle timer, any client)
{
	if (PlayerDuckhealTimer[client])
	{
		KillTimer(PlayerDuckhealTimer[client]);
		PlayerDuckhealTimer[client] = INVALID_HANDLE;
	}
}

public void ScreenFade(int target, int red, int green, int blue, int alpha, int duration, int type)
{
	Handle msg = StartMessageOne("Fade", target);
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

stock bool IsPlayerIncapped(int Client)
{
	if (GetEntProp(Client, Prop_Send, "m_isIncapacitated",1))
	{
		return true;
	}
	return false;
}


stock bool IsSurvivor(int client) 
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

stock bool IsValidClient(int client) {
    return (1 <= client <= MaxClients && IsClientInGame(client));
} 