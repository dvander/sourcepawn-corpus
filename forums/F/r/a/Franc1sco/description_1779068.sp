#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>


new bool:g_IsMapLoaded;

public Action:OnGetGameDescription(String:gameDescription[64])
{
	if (g_IsMapLoaded)
	{
		strcopy(gameDescription, sizeof(gameDescription), "Your game description"); // edit and compile
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public OnMapStart()
{
	g_IsMapLoaded = true;
}

public OnMapEnd()
{
	g_IsMapLoaded = false;
}

