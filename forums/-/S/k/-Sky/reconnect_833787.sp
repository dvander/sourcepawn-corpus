#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION         "1.0.0.0"

public Plugin:myinfo = 
{
    name = "Force Reconnect",
    author = "Alm",
    description = "Forces players to recconect",
    version = PLUGIN_VERSION,
};

public OnPluginStart()
{
	RegAdminCmd("sm_retry", ForceRetry, ADMFLAG_ROOT, "<name> Forces player to reconnect");
}

public Action:ForceRetry(Client, Args)
{
	if(Args == 0)
	{
		PrintToConsole(Client, "[Reconnect] Usage: <name>");
		return Plugin_Handled;
	}

	decl String:TargetName[32];
	decl String:PlayerName[32];
	decl Target;
	Target = -1;

	GetCmdArgString(TargetName, 32);

	StripQuotes(TargetName);
	TrimString(TargetName);

	for(new X = 1; X <= GetMaxClients(); X++)
	{
		if(Target == -1 && IsClientInGame(X))
		{
			GetClientName(X, PlayerName, 32);

			if(StrContains(PlayerName, TargetName, false) != -1)
			{
				Target = X;
			}
		}
	}

	if(Target == -1)
	{
		PrintToConsole(Client, "[Reconnect] Target not in-game.");
		return Plugin_Handled;
	}

	ClientCommand(Target, "retry");
	
	PrintToConsole(Client, "[SM] Forced %s to reconnect.", PlayerName);

	return Plugin_Handled;
}