#include <sdkhooks>
#include <sdktools>

#define PLUGIN_VERSION          "1.0.1"
#define PLUGIN_NAME             "Bot Stripper"
#define PLUGIN_AUTHOR           "Maxximou5"
#define PLUGIN_DESCRIPTION      "Removes all weapons from bots on spawn."
#define PLUGIN_URL              "http://maxximou5.com/"

public Plugin myinfo =
{
    name                        = PLUGIN_NAME,
    author                      = PLUGIN_AUTHOR,
    description                 = PLUGIN_DESCRIPTION,
    version                     = PLUGIN_VERSION,
    url                         = PLUGIN_URL
}

public void OnPluginStart()
{
	HookEvent("player_spawn", Event_OnPlayerSpawn, EventHookMode_Post);
}

public Action Event_OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidClient(client) && IsFakeClient(client))
	{
		CreateTimer(1.0, Timer_RemoveClientWeapons, GetClientSerial(client));
	}

	return Plugin_Handled;
}

public Action Timer_RemoveClientWeapons(Handle timer, any serial)
{
	int client = GetClientFromSerial(serial);
	if (IsValidClient(client))
	{
		RemoveClientWeapons(client);
	}
}

void RemoveClientWeapons(int client)
{
	if (IsValidClient(client))
	{
		FakeClientCommand(client, "use weapon_knife");
		for (int i = 0; i < 4; i++)
		{
			if (i == 2) continue; /* Keep knife. */
			int entityIndex;
			while ((entityIndex = GetPlayerWeaponSlot(client, i)) != -1)
			{
				RemovePlayerItem(client, entityIndex);
				AcceptEntityInput(entityIndex, "Kill");
			}
		}
	}
}

stock bool IsValidClient(int client)
{
	if (!(0 < client <= MaxClients)) return false;
	if (!IsClientInGame(client)) return false;
	return true;
}