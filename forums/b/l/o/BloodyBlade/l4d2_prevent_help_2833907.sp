#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

#define PLUGIN_NAME       "[L4D2] Prevent Help"
#define PLUGIN_DESCRIPTION    "Prevent Survivor bot Help incap survivor when tank/witch alive."
#define PLUGIN_VERSION      "1.1"
#define PLUGIN_AUTHOR       "Iciaria/oblivcheck"
#define PLUGIN_URL        ""

#define WITCH 0
#define COUNT_FRAME 5
#define COUNT_CMD 10

ArrayList aWitchList = null, aTankList = null, aShouldBlockAreaList = null;
int counter[MAXPLAYERS + 1] = {0, ...};
bool allow = false;

public void OnPluginStart()
{
	HookEvent("witch_harasser_set", Event_Witch_Harasser_Set);
	HookEvent("tank_spawn", Event_Tank_Spawn);
	aWitchList = CreateArray(1);
	aTankList = CreateArray(1);
	aShouldBlockAreaList = CreateArray(2);
}

void Event_Witch_Harasser_Set(Event event, const char[] name, bool dontBroadcast)
{
	aWitchList.Push(event.GetInt("witchid"));
}

void Event_Tank_Spawn(Event event, const char[] name, bool dontBroadcast)
{
	aTankList.Push(event.GetInt("tankid"));
}

public void OnEntityDestroyed( int entity)
{
	int index = aWitchList.FindValue(entity);
	if(index != -1)
	{
		aWitchList.Erase(index);
		return;
	}

	index = aTankList.FindValue(entity);
	if(index != -1)
	{
		aTankList.Erase(index);
	}
	return;
}

public void OnClientPutInServer(int client)
{
	if(client > 0)
	{
		counter[client] = 0;
	}
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum)
{
	if(client > 0 && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
	{
		if(L4D_IsPlayerHangingFromLedge(client) || L4D_IsPlayerIncapacitated (client))
		{
			float pos[3];
			GetClientAbsOrigin(client, pos);
			Address area =  L4D_GetNearestNavArea(pos);
			if(area == view_as<Address>(0) )
			PrintToServer("Cant Found NavArea(incap player: %N)", client);
			else
			aShouldBlockAreaList.Push(area);
		}
		else if(IsFakeClient(client))
		{
			if(counter[client] == 0)
			{
				counter[client] = cmdnum;
			}

			if( (cmdnum - counter[client]) > COUNT_CMD)
			{
				float pos[3];
				GetClientAbsOrigin(client, pos);
				Address area =  L4D_GetNearestNavArea(pos);
				float speed[3];
				for(int i = 0; i < 3; i++)
				speed[i] = GetRandomFloat(50.0, 200.0); 
				if(aShouldBlockAreaList.FindValue(area) != -1)
				TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, speed);
				counter[client] = 0;
			}
		}

		int Length = aShouldBlockAreaList.Length;
		if(Length)
		{
			if(IsFakeClient(client))
			{
				#if WITCH
				if(aWitchList.Length || aTankList.Length)
				#else
				if(aTankList.Length)
				allow = true;
				#endif
				else allow = false;
			}
			else
			{
				return Plugin_Continue;
			}
		}
		else
		{
			return Plugin_Continue;
		}
	}
	else
	{
		allow = false;
		return Plugin_Continue;
	}
	return Plugin_Continue;
}

int skip = 0;
public void OnGameFrame()
{
	skip++;
	if(skip > COUNT_FRAME)
	{
		skip = 0;
	}
	else
	{
		return;
	}

	Address area;
	for(int i = 0; i < aShouldBlockAreaList.Length; i++)
	{
		if(allow)
		{
			area = aShouldBlockAreaList.Get(i);
			int flags = L4D_GetNavArea_AttributeFlags(area);
			aShouldBlockAreaList.Set(i, flags, 1);
			L4D_SetNavArea_AttributeFlags(area, flags | NAV_BASE_PLAYERCLIP);
		}
		else
		{
			area = aShouldBlockAreaList.Get(i);
			int flags = L4D_GetNavArea_AttributeFlags(area);
			L4D_SetNavArea_AttributeFlags(area, flags & ~NAV_BASE_PLAYERCLIP);
			aShouldBlockAreaList.Clear(); 
		}
	}
}
