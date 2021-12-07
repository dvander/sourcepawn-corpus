#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "0.4"
#define AUTHOR "Teki"
#define URL "https://forums.alliedmods.net/showthread.php?t=199800"

public Plugin:myinfo = 
{
	name = "Quick Map Rotation",
	author = AUTHOR,
	description = "This plugin will change the map if there is not enough real players on the server.",
	version = PLUGIN_VERSION,
	url = URL
};

new Handle:pluginEnabled = INVALID_HANDLE;
new Handle:pluginTime = INVALID_HANDLE;
new Handle:pluginQuota = INVALID_HANDLE;
new Handle:pluginManaged = INVALID_HANDLE;
new Handle:pluginMaps = INVALID_HANDLE;
new Handle:smNextmap = INVALID_HANDLE;
new Handle:timerGameEnd = INVALID_HANDLE;
new mapIndex;

stock CheckPlayerQuota()
{
	new players;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && !IsFakeClient(i))
		{
			players ++;
		}
	}
	
	new playerQuota = GetConVarInt(pluginQuota);
	
	if (players < playerQuota && timerGameEnd == INVALID_HANDLE)
	{
		new Float:timerDelay = GetConVarInt(pluginTime)*60.0;
		timerGameEnd = CreateTimer(timerDelay, GameEnd, _, TIMER_FLAG_NO_MAPCHANGE);
		PrintToServer("[SM] Not enough players, map will change in %d minutes.", GetConVarInt(pluginTime));
		PrintToChatAll("[SM] Not enough players, map will change in %d minutes.", GetConVarInt(pluginTime));
	}
	else if (players >= playerQuota && timerGameEnd != INVALID_HANDLE)
	{
		KillTimer(timerGameEnd);
		timerGameEnd = INVALID_HANDLE;
		PrintToServer("[SM] Player quota reached, map change cancelled.", GetConVarInt(pluginTime));
		PrintToChatAll("[SM] Player quota reached, map change cancelled.", GetConVarInt(pluginTime));
	}
}

public OnPluginStart()
{
	CreateConVar("sm_qmr_version", PLUGIN_VERSION, "Version of Quick Map Rotation.", FCVAR_NOTIFY);
	pluginEnabled = CreateConVar("sm_qmr_enable", "1", "(1)Enable or (0)Disable Quick Map Rotation. Default: 1", FCVAR_NOTIFY);
	pluginTime = CreateConVar("sm_qmr_timelimit", "10", "Time in minutes before changing map when no one is on the server. Default: 10", FCVAR_NOTIFY);
	pluginQuota = CreateConVar("sm_qmr_player_quota", "1", "Number of players needed to cancel anticipated change map. Default: 1", FCVAR_NOTIFY);
	pluginManaged = CreateConVar("sm_qmr_mapcycle_enabled", "0", "(1)Enable or (0)Disable managed mapcycle on empty server. Default: 0", FCVAR_NOTIFY);
	pluginMaps = CreateConVar("sm_qmr_mapcycle", "", "List of maps delimited by comas.", FCVAR_NOTIFY);
	
	smNextmap = FindConVar("sm_nextmap");
}

public OnMapStart()
{
	timerGameEnd = INVALID_HANDLE;
	if (GetConVarInt(pluginEnabled) == 1)
	{
		CheckPlayerQuota();
	}
}

public OnClientConnected(client)
{
	if (GetConVarInt(pluginEnabled) == 1)
	{
		CheckPlayerQuota();
	}
}

public OnClientDisconnect_Post(client)
{
	if (GetConVarInt(pluginEnabled) == 1)
	{
		CheckPlayerQuota();
	}
}

public Action:GameEnd(Handle:timer)
{
	CheckPlayerQuota();
	if (timerGameEnd != INVALID_HANDLE)
	{
		timerGameEnd = INVALID_HANDLE;
		new String:nextmap[32];
		
		if (GetConVarInt(pluginManaged) == 1)
		{
			decl String:buffer[256];
			new String:mapcycle[16][32];
			new mapsCount, i;
			
			GetConVarString(pluginMaps, buffer, sizeof(buffer));
			mapsCount = ExplodeString(buffer, ",", mapcycle, sizeof(mapcycle), sizeof(mapcycle[]), false);
			
			if (mapsCount > 0 && !StrEqual(mapcycle[0], "", false))
			{
				if (mapIndex == 0)
				{
					strcopy(nextmap, 32, mapcycle[0]);
				}
				else if (mapIndex < mapsCount)
				{
					strcopy(nextmap, 32, mapcycle[mapIndex]);
				}
				else if (mapIndex == mapsCount)
				{
					mapIndex = 0;
					strcopy(nextmap, 32, mapcycle[0]);
				}
				
				if (!IsMapValid(nextmap))
				{
					while (!IsMapValid(nextmap) && i <= mapsCount)
					{
						mapIndex++;
						if (mapIndex == 0)
						{
							strcopy(nextmap, 32, mapcycle[0]);
						}
						else if (mapIndex < mapsCount)
						{
							strcopy(nextmap, 32, mapcycle[mapIndex]);
						}
						else if (mapIndex == mapsCount)
						{
							mapIndex = 0;
							strcopy(nextmap, 32, mapcycle[mapIndex]);
						}
						
						if (i== mapsCount && (StrEqual(nextmap, "", false) || !IsMapValid(nextmap)))
						{
							GetNextMap(nextmap, sizeof(nextmap));
							PrintToServer("[SM] No valid maps in managed mapcycle, change map to %s...", nextmap);
						}
						else if (StrEqual(nextmap, "", false) || !IsMapValid(nextmap))
						{
							PrintToServer("[SM] Map %s is not valid, trying next map...", nextmap);
						}
						else
						{
							SetConVarString(smNextmap, nextmap, false, false);
							PrintToServer("[SM] Not enough players, change map to %s...", nextmap);
							PrintToChatAll("[SM] Not enough players, change map to %s...", nextmap);
							mapIndex++;
							i = mapsCount + 1;
						}
						i++;
					}
				}
				else
				{
					SetConVarString(smNextmap, nextmap, false, false);
					PrintToServer("[SM] Not enough players, change map to %s...", nextmap);
					PrintToChatAll("[SM] Not enough players, change map to %s...", nextmap);
					mapIndex++;
				}
			}
			else
			{
				GetNextMap(nextmap, sizeof(nextmap));
				PrintToServer("[SM] No valid maps in managed mapcycle, change map to %s...", nextmap);
			}
		}
		else
		{
			GetNextMap(nextmap, sizeof(nextmap));
			PrintToServer("[SM] Not enough players, change map to %s...", nextmap);
			PrintToChatAll("[SM] Not enough players, change map to %s...", nextmap);
		}
		
		//Routine by Tsunami to end the map
		new iGameEnd  = FindEntityByClassname(-1, "game_end");
		if (iGameEnd == -1 && (iGameEnd = CreateEntityByName("game_end")) == -1) 
		{     
			LogError("Unable to create entity \"game_end\"!");
		} 
		else 
		{     
			AcceptEntityInput(iGameEnd, "EndGame");
		}
	}
	else
	{
		PrintToServer("[SM] Player quota reached, map change cancelled.");
		PrintToChatAll("[SM] Player quota reached, map change cancelled.");
	}
}