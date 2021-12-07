#include <sourcemod>
#include <sdktools>


new Handle:duck_heal;
new Handle:HealClientTimer[66];
new Handle:ducktimestar;
new Float:timestar;
new key_run[MAXPLAYERS+1];
new Float:NowLocation2[MAXPLAYERS+1][3];

public OnPluginStart()
{
	duck_heal = CreateConVar("duck_heal", "1", "恢復的血量");
	ducktimestar = CreateConVar("duck_time_star", "多少秒恢復一次");
	
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_ledge_grab", Event_player_ledge_grab);
	HookEvent("player_ledge_release", Event_player_ledge_release);
	HookEvent("player_hurt", Event_player_hurt);
	
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

public Action:Event_player_ledge_grab(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	key_run[client] = 1;
}

public Action:Event_player_ledge_release(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	key_run[client] = 0;
}

public Action:Event_player_hurt(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "client"));

	if (HealClientTimer[client] != INVALID_HANDLE)
	{
		KillTimer(HealClientTimer[client]);
		HealClientTimer[client] = INVALID_HANDLE;		
	}
}

public Action:Event_PlayerDeath(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (HealClientTimer[client] != INVALID_HANDLE)
	{
		KillTimer(HealClientTimer[client]);
		HealClientTimer[client] = INVALID_HANDLE;
	}
}

public Action:ChargeTimer(Handle:timer, any:client)
{
	key_run[client] = 0;
	new buttons;
	new HP = GetClientHealth(client);
	buttons = GetClientButtons(client);
	if (buttons & 4)
	{
		if (IsPlayerIncapped(client))
		{
			HealClientTimer[client] = INVALID_HANDLE;
			return Plugin_Handled;
		}	
		new MaxHP = GetEntProp(client, PropType:1, "m_iMaxHealth", 4, 0);
		if (MaxHP > HP)
		{
			new damage = GetConVarInt(duck_heal);
			new Float:NowLocation[3];
			GetClientAbsOrigin(client, NowLocation);
			float distance = GetVectorDistance(NowLocation2[client] , NowLocation);
			if (distance <= 5.0)
			{
				EmitAmbientSound("ui/helpful_event_1.wav", NowLocation, 0, 75, 0, 1.0, 100, 0.0);
				SetEntProp(client, PropType:1, "m_iHealth", damage + HP, 4, 0);
				ScreenFade(client, 200, 0, 0, 200, 100, 1);
				PerformGlow(client, 3, 2048, 255, 0, 0);
				CreateTimer(0.5, close_light, client);
			}
		}
		else
		{
			if (MaxHP < HP)
			{
				SetEntProp(client, PropType:1, "m_iHealth", MaxHP, 4, 0);
			}
		}
	}
	HealClientTimer[client] = INVALID_HANDLE;
	return Plugin_Continue;
}

public Action:close_light(Handle:timer, any:client)
{
	PerformGlow(client, 3, 2048, 0, 0, 0);
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

stock PerformGlow(client, Type, Range = 0, Red = 0, Green = 0, Blue = 0)
{
	decl Color;
	Color = Red + Green * 256 + Blue * 65536;
	SetEntProp(client, Prop_Send, "m_iGlowType", Type);
	SetEntProp(client, Prop_Send, "m_nGlowRange", Range);
	SetEntProp(client, Prop_Send, "m_glowColorOverride", Color);
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