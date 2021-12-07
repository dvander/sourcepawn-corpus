#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION "1.0.0"

new Float:ConnectionSeconds = 0.0;
new Handle:ClientTimer[MAXPLAYERS+1] = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "No Stuck Connect",
	author = "TnTSCS aka ClarkKent",
	description = "Kicks players who get stuck in connecting",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
}

public OnPluginStart()
{
	CreateConVar("sm_nsc_version", PLUGIN_VERSION, "The version of \"No Stuck Connect\"", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_DONTRECORD);
	
	new Handle:hRandom; // KyleS hates handles
	
	HookConVarChange((hRandom = CreateConVar("sm_nsc_seconds", "120.0", 
	"Number of seconds to allow player to remain in connecting state before they are kicked.")), SecondsChange);
	ConnectionSeconds = GetConVarFloat(hRandom);
	
	CloseHandle(hRandom); // KyleS hates handles
}

public OnClientConnected(client)
{
	if(!IsFakeClient(client))
		ClientTimer[client] = CreateTimer(ConnectionSeconds, Timer_Connection, client);
}

public OnClientPutInServer(client)
{
	if(!IsFakeClient(client))
		ClearTimer(ClientTimer[client]);
}

public OnClientDisconnect(client)
{
	ClearTimer(ClientTimer[client]);
}

public Action:Timer_Connection(Handle:timer, any:client)
{
	ClientTimer[client] = INVALID_HANDLE;
	
	if(!IsClientInGame(client))
	{
		LogMessage("%L is stuck connecting and will be kicked.", client);
		KickClient(client, "You've been in the \"CONNECTING\" state too long, please retry");
	}
}

public SecondsChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	ConnectionSeconds = GetConVarFloat(cvar);
}

stock ClearTimer(&Handle:timer)
{
	if (timer != INVALID_HANDLE)
	{
		KillTimer(timer);
		timer = INVALID_HANDLE;
	}     
}