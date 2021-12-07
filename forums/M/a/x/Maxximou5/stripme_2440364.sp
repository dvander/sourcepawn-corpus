#include <sdkhooks>
#include <sdktools>
// Defined Variables
#define PLUGIN_VERSION          "1.0.0"
#define PLUGIN_NAME             "Strip Me!"
#define PLUGIN_AUTHOR           "Maxximou5"
#define PLUGIN_DESCRIPTION      "Removes all weapons from players on spawn."
#define PLUGIN_URL              "http://maxximou5.com/"
// Plugin Creator Info
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
	if (IsValidClient(client))
	{
		RemoveClientWeapons(client);
	}

	return Plugin_Handled;
}

void RemoveClientWeapons(int client)
{
	if (IsValidClient(client))
	{
		for (int i = 0; i < 4; i++)
		{
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