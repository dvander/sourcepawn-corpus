#pragma semicolon 1

#include <sourcemod>
#define PLUGIN_VERSION "1.0.8"

public Plugin myinfo = 
{
	name = "L4D Kick Load Stuckers",
	author = "AtomicStryker",
	description = "Kicks Clients that get stuck in server connecting state",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=103203"
}

static Handle LoadingTimer[MAXPLAYERS+1] 	= INVALID_HANDLE;
static Handle cvarDuration 					= INVALID_HANDLE;

public void OnPluginStart()
{
	RegAdminCmd("sm_kickloading", KickLoaders, ADMFLAG_KICK, "Kicks everyone Connected but not ingame");
	CreateConVar("l4d_kickloadstuckers_version", PLUGIN_VERSION, "Version of L4D Kick Load Stuckers on this server ", 0|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cvarDuration = CreateConVar("l4d_kickloadstuckers_duration", 	"60", 			" How long before a connected but not ingame player is kicked. (default 60) ", 	0|FCVAR_NOTIFY);
}

public Action KickLoaders(int clients, int args)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientConnected(i)) continue;
		if (!IsClientInGame(i))
		{
			PrintToChatAll("%N was admin kicked for being stuck in connecting state", i);
			
			//BanClient(i, 0, BANFLAG_AUTO, "Slowass Loading", "Slowass Loader");
			KickClient(i, "You were stuck Connecting for too long");
		}
	}
	return Plugin_Handled;
}

public void OnClientConnected(int client)
{
	LoadingTimer[client] = CreateTimer(GetConVarFloat(cvarDuration), CheckClientIngame, client, TIMER_FLAG_NO_MAPCHANGE); //on successfull connect the Timer is set in motion
}

public void OnClientDisconnect(int client)
{
	if ( !AreHumansConnected() ) return;
	
	if (LoadingTimer[client] != INVALID_HANDLE) 
	{
		KillTimer(LoadingTimer[client]);
		LoadingTimer[client] = INVALID_HANDLE;
	}
}

public Action CheckClientIngame(Handle timer, any client)
{
	LoadingTimer[client] = INVALID_HANDLE;

	if (!IsClientConnected(client)) return; //onclientdisconnect should handle this, but you never know
	
	if (!IsClientInGame(client))
	{
		//player log file code. name and steamid only
		char file[PLATFORM_MAX_PATH];
		char steamid[128];
		BuildPath(Path_SM, file, sizeof(file), "logs/stuckplayerlog.log");
	
		GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
		if (FindAdminByIdentity(AUTHMETHOD_STEAM, steamid) != INVALID_ADMIN_ID)
		{
			LogToFileEx(file, "%s - %N - NOT KICKED DUE TO ADMIN STATUS", steamid, client);
			return;
		}
	
		PrintToChatAll("%N was kicked for being stuck in connecting state for %i seconds", client, RoundToNearest(GetConVarFloat(cvarDuration)));
		
		KickClient(client, "You were stuck Connecting for too long");
		
		LogToFileEx(file, "%s - %N", steamid, client); // this logs their steamids and names. to be banned.
	}
}

stock bool AreHumansConnected()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && !IsFakeClient(i)) return true;
	}
	return false;
}