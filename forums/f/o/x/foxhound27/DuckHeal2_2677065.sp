#include <sourcemod>
#include <sdktools>


Handle duck_heal,HealClientTimer[66],ducktimestar;
float timestar, NowLocation2[MAXPLAYERS+1][3];
int key_run[MAXPLAYERS+1];


public void OnPluginStart()
{
	duck_heal = CreateConVar("duck_heal", "1", "Recover HP");
	ducktimestar = CreateConVar("duck_time_star", "10.0", "How many seconds to recover default 10");
	
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_ledge_grab", Event_player_ledge_grab);
	HookEvent("player_ledge_release", Event_player_ledge_release);
	HookEvent("player_hurt", Event_player_hurt);
	
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

public Action OnPlayerRunCmd(int iClient, int &iButtons, int &iImpulse, float fVel[3], float fAngles[3], int &iWeapon, int &iSubtype, int &iCmdnum, int &iTickcount, int &iSeed, int iMouse[2])
{	
	if (key_run[iClient] == 0)
	{
		if (iButtons & 4)
		{
			if (HealClientTimer[iClient] == INVALID_HANDLE)
			{
				if (IsSurvivor(iClient) && !IsFakeClient(iClient) && IsPlayerAlive(iClient))
				{
					key_run[iClient] = 1;
					timestar = GetConVarFloat(ducktimestar);
					GetClientAbsOrigin(iClient, NowLocation2[iClient]);
					HealClientTimer[iClient] = CreateTimer(timestar, ChargeTimer, iClient);
				}
			}
		}
	}
}

public Action Event_player_ledge_grab(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	key_run[client] = 1;
}

public Action Event_player_ledge_release(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	key_run[client] = 0;
}

public Action Event_player_hurt(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "client"));

	if (HealClientTimer[client] != INVALID_HANDLE)
	{
		KillTimer(HealClientTimer[client]);
		HealClientTimer[client] = INVALID_HANDLE;		
	}
}

public Action Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (HealClientTimer[client] != INVALID_HANDLE)
	{
		KillTimer(HealClientTimer[client]);
		HealClientTimer[client] = INVALID_HANDLE;
	}
}

public Action ChargeTimer(Handle timer, any client)
{
	key_run[client] = 0;
	int buttons;
	int HP = GetClientHealth(client);
	buttons = GetClientButtons(client);
	if (buttons & 4)
	{
		if (IsPlayerIncapped(client))
		{
			HealClientTimer[client] = INVALID_HANDLE;
			return Plugin_Handled;
		}	
		int MaxHP = GetEntProp(client, Prop_Data, "m_iMaxHealth");
		if (MaxHP > HP)
		{
			int damage = GetConVarInt(duck_heal);
			float NowLocation[3];
			GetClientAbsOrigin(client, NowLocation);
			float distance = GetVectorDistance(NowLocation2[client] , NowLocation);
			if (distance <= 5.0)
			{
				EmitAmbientSound("ui/helpful_event_1.wav", NowLocation, client, 75, 0, 1.0, 100, 0.0);
				SetEntProp(client, Prop_Data, "m_iHealth", damage + HP);
				ScreenFade(client, 200, 0, 0, 200, 100, 1);
				PerformGlow(client, 3, 2048, 255, 0, 0);
				CreateTimer(0.5, close_light, client);
			}
		}
		else
		{
			if (MaxHP < HP)
			{
				SetEntProp(client, Prop_Data, "m_iHealth", MaxHP);
			}
		}
	}
	HealClientTimer[client] = INVALID_HANDLE;
	return Plugin_Continue;
}

public Action close_light(Handle timer, any client)
{
	PerformGlow(client, 3, 2048, 0, 0, 0);
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

stock void PerformGlow(int client, int Type, int Range = 0, int Red = 0, int Green = 0, int Blue = 0)
{
	char Color;
	Color = Red + Green * 256 + Blue * 65536;
	SetEntProp(client, Prop_Send, "m_iGlowType", Type);
	SetEntProp(client, Prop_Send, "m_nGlowRange", Range);
	SetEntProp(client, Prop_Send, "m_glowColorOverride", Color);
}

stock bool IsPlayerIncapped(int Client)
{
	if (GetEntProp(Client, Prop_Send, "m_isIncapacitated", 1) == 1)
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

stock bool IsValidClient(int client) 
{
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) return false;      
    return true; 
}