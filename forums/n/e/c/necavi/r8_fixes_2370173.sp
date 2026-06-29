#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

public Plugin myinfo = 
{
	name = "R8 Revolver Fixes",
	author = "necavi & zipcore",
	description = "A selection of fixes for the R8 Revolver.",
	version = "0.0.2",
	url = ""
};

ConVar g_cvFreezetime;

bool g_bInWeaponFire[MAXPLAYERS + 1];

public void OnPluginStart()
{
	HookEvent("bomb_begindefuse", Event_BombBeginDefuse);
	HookEvent("bomb_abortdefuse", Event_BombEndDefuse);
	HookEvent("bomb_defused", Event_BombEndDefuse);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_freeze_end", Event_RoundFreezeEnd);
	g_cvFreezetime = FindConVar("mp_freezetime");
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if(g_cvFreezetime.IntValue > 0)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if(IsClientConnected(i) && IsClientInGame(i))
			{
				SetNextSecondaryAttack(i, 100.0);
			}
		}
	}
}

public Action Event_RoundFreezeEnd(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && IsClientInGame(i))
		{
			SetNextSecondaryAttack(i, 1.0);
		}
	}
}

public Action Event_BombBeginDefuse(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	SetNextSecondaryAttack(client, 100.0);
}

public Action Event_BombEndDefuse(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	SetNextSecondaryAttack(client, 1.0);
}

void SetNextSecondaryAttack(int client, float time)
{
	int weapon = GetPlayerWeaponSlot(client, 1);
	if(weapon > -1)
	{
		SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", GetGameTime() + time);
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3])
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client)) 
	{
		return Plugin_Continue;
	}
		
	if (buttons & IN_ATTACK2)
	{
		if(g_bInWeaponFire[client])
		{
			return Plugin_Continue;
		}
			
		int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		int weaponIndex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
		
		if (weaponIndex == 64)
		{
			float fTime = GetGameTime();
			
			float fNextSecondaryAttack = GetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack");
			
			if(fNextSecondaryAttack <= fTime + 0.1)
			{
				g_bInWeaponFire[client] = true;
				CreateEvent_WeaponFire(client, "deagle", false);
			}
		}
	}
	else 
	{
		g_bInWeaponFire[client] = false;
	}
	
	return Plugin_Continue;
}

void CreateEvent_WeaponFire(int client, const char[] weapon, bool silenced)
{
	Event event = CreateEvent("weapon_fire");
	if (event == null)
	{
		return;
	}
 
	event.SetInt("userid", GetClientUserId(client));
	event.SetString("weapon", weapon);
	event.SetBool("silenced", silenced);
	event.Fire();
}