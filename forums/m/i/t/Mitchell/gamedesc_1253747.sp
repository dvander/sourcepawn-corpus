#include <sdkhooks>

#pragma semicolon 1

#define GAMEDESC  "Team-Fortress: Source"

new bool:MS_overrideGameDesc = false;

public OnMapStart()
{
	MS_overrideGameDesc = true;
}

public OnMapEnd()
{
	MS_overrideGameDesc = false;
}

public Action:OnGetGameDescription(String:gameDesc[64])
{
	if (MS_overrideGameDesc)
	{
		strcopy(gameDesc, sizeof(gameDesc), GAMEDESC);
		return Plugin_Changed;
	}

	return Plugin_Continue;
}