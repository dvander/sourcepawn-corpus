#pragma semicolon 1
#define PLUGIN_VERSION  "indev"

public Plugin:myinfo = {
	name = "Query ConVars",
	author = "MasterOfTheXP",
	description = "Check clients' ConVar values.",
	version = PLUGIN_VERSION,
	url = "http://mstr.ca/"
};

public OnPluginStart() RegAdminCmd("sm_query", Command_querycvar, ADMFLAG_CONVARS);

new Querying = -1;

public Action:Command_querycvar(client, args)
{
	if (!args)
	{
		ReplyToCommand(client, "[SM] Usage: sm_querycvar <cvar> - Checks for a ConVar value on all clients.");
		return Plugin_Handled;
	}
	Querying = client;
	new String:arg1[128];
	GetCmdArgString(arg1, sizeof(arg1));
	ReplyToCommand(client, "[SM] Querying clients for ConVar \"%s\"...", arg1);
	for (new z = 1; z <= MaxClients; z++)
	{
		if (!IsClientInGame(z)) continue;
		if (IsFakeClient(z)) continue;
		QueryClientConVar(z, arg1, QueryClient);
	}
	return Plugin_Handled;
}

public QueryClient(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[])
{
	if (Querying == -1) return;
	if (Querying && !IsClientInGame(Querying)) return;
	if (!IsClientInGame(client)) return;
	new uid = GetClientUserId(client);
	if (result == ConVarQuery_Okay) PrintToAnywhere(Querying, "#%i %N - \"%s\"", uid, client, cvarValue);
	else if (result == ConVarQuery_NotFound) PrintToAnywhere(Querying, "#%i %N - Not found", uid, client);
	else if (result == ConVarQuery_NotValid) PrintToAnywhere(Querying, "#%i %N - Not valid", uid, client);
	else if (result == ConVarQuery_Protected) PrintToAnywhere(Querying, "#%i %N - Protected", uid, client);
	else PrintToAnywhere(Querying, "#%i %N - Unknown error", uid, client);
}

stock PrintToAnywhere(client, const String:text[], any:...)
{
	new String:buffer[192];
	VFormat(buffer, sizeof(buffer), text, 3);
	if (client) PrintToConsole(client, buffer);
	else LogToGame(buffer);
}