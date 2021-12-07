#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

char allowedWeapons[] = {"weapon_awp", "weapon_knife"};

public void OnPluginStart()
{
	HookEvent("player_spawn", Event_PlayerSpawn);
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_WeaponCanUse, WeaponCanUse_Callback);
}

public Action WeaponCanUse_Callback(int client, int weapon)
{
	if (!IsValidClient(client))
	{
		return Plugin_Continue;
	}
	
	char classname[32];
	GetEntityClassname(weapon, classname, sizeof(classname));
	
	if (!IsWeaponAllowed(classname))
	{
		return Plugin_Handled;
	}
	else
	{
		return Plugin_Continue;
	}
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	RequestFrame(RequestFrame_Callback, event.GetInt("userid"));
}

public void RequestFrame_Callback(int userid)
{
	LoopWeapons(GetClientOfUserId(userid));
}

void LoopWeapons(int client)
{
    for (int i = 0; i < 5; i++)
    {
        int entity = GetPlayerWeaponSlot(client, i);
        if (IsValidEntity(entity))
		{
			char classname[32];
			GetEntityClassname(entity, classname, sizeof(classname));

			if (!IsWeaponAllowed(classname))
			{
				AcceptEntityInput(entity, "Kill");
			}
		}
    }
}

bool IsWeaponAllowed(char[] classname)
{
	bool found = false;
	int index = 0;
	while (!found && index < sizeof(allowedWeapons))
	{
		if (StrEqual(classname, allowedWeapons[index]))
		{
			found = true;
		}
		else
		{
			index++;
		}
	}
	
	return found;
}

bool IsValidClient(int client, bool bAllowBots = false, bool bAllowDead = true)
{
	if(!(1 <= client <= MaxClients) || !IsClientInGame(client) || (IsFakeClient(client) && !bAllowBots) || IsClientSourceTV(client) || IsClientReplay(client) || (!bAllowDead && !IsPlayerAlive(client)))
	{
		return false;
	}
	return true;
}
