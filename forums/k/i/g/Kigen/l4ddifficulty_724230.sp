#include <sourcemod>

new Handle:g_CVAR_Difficulty;

public Plugin:myinfo = 
{
	name = "L4D Difficulty",
	author = "Kigen",
	description = "What is that difficulty?",
	version = "1.0",
	url = "http://www.codingdirect.com/"
};

public OnPluginStart()
{
	CreateConVar("sm_l4ddifficulty_version", "1.0", "L4D Difficulty Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	RegConsoleCmd("say", SayTrigger);
	g_CVAR_Difficulty = FindConVar("z_difficulty");
	if ( g_CVAR_Difficulty == INVALID_HANDLE )
		SetFailState("Unable to find z_difficulty.");
}

public OnClientPutInServer(client)
{
	decl String:difficulty[64];
	GetConVarString(g_CVAR_Difficulty, difficulty, sizeof(difficulty));
	if ( strlen(difficulty) < 1 )
		return;
	if ( strcmp(difficulty, "impossible", false) == 0 )
	 	strcopy(difficulty, sizeof(difficulty), "Expert");
	else
		CharToUpper(difficulty[0]);
	PrintToChat(client, "[SM] Difficulty is: %s.", difficulty);
}

public Action:SayTrigger(client, args)
{
	// A little from Base Triggers by AlliedModders, LLC.
	decl String:text[192], String:command[64], String:difficulty[64];
	new startidx = 0;
	if (GetCmdArgString(text, sizeof(text)) < 1)
	{
		return Plugin_Continue;
	}
	
	if (text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}

	if (strcmp(command, "say2", false) == 0)
		startidx += 4;

	if (strcmp(text[startidx], "difficulty", false) == 0 || strcmp(text[startidx], "skill", false) == 0)
	{
		GetConVarString(g_CVAR_Difficulty, difficulty, sizeof(difficulty));
		if ( strlen(difficulty) < 1 )
			return Plugin_Continue; // Error, better not log so someone can't spam the crap out of it. - Kigen
		if ( strcmp(difficulty, "impossible", false) == 0 )
		 	strcopy(difficulty, sizeof(difficulty), "Expert");
		else
			CharToUpper(difficulty[0]);
		PrintToChatAll("[SM] Difficulty is: %s.", difficulty);
	}
	return Plugin_Continue;
}