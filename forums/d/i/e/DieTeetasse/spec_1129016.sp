#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

public OnPluginStart()
{
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("teamsay", Command_Say);
	RegConsoleCmd("sm_spec", Command_Spec);
	RegConsoleCmd("sm_spec_all", Command_Spec_All);
}

public Action:Command_Say(client, args)
{
	if (args < 1)
	{
		return Plugin_Continue;
	}
	
	decl String:text[15];
	GetCmdArg(1, text, sizeof(text));
	
	if (StrContains(text, "!spec all") == 0)
	{
		AllSpec(client);
		return Plugin_Handled;
	}	
	
	if (StrContains(text, "!spec") == 0)
	{
		ChangeClientTeam(client, 1);
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action:Command_Spec(client, args)
{
	ChangeClientTeam(client, 1);
	return Plugin_Continue;
}

public Action:Command_Spec_All(client, args)
{
	AllSpec(client);
	return Plugin_Continue;
}

AllSpec(initiator)
{
	if(GetUserAdmin(initiator) == INVALID_ADMIN_ID) 
	{
		PrintToChat(initiator, "[SM] No admin rights!");
		return;
	}
	
	for (new i = 1; i < MaxClients+1; i++)
	{
		//ingame?
		if (!IsClientInGame(i)) continue;
		
		//change to spec
		ChangeClientTeam(i, 1);
	}
}