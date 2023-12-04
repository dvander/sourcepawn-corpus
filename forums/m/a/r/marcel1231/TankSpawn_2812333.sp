#include <sourcemod>
#include <sdkhooks>
public Plugin myinfo =
{
    name = "Tank Spawn",
    author = "marcel",
    description = "Add to game for Survival gamemode spawn tankers",
    version = "1.0",
    url = ""
};

ConVar noSpecialZombies; // zmienna na specjalnych zarazonych
ConVar noZombies; // zmienna na zwyklych zombie
ConVar GameModes; // zmienna okresla jaki to rodzaj gamemoda aktualnie jest ogrywany

public void OnPluginStart()
{
	char namess[32];
	noZombies = FindConVar("z_common_limit");
	noSpecialZombies = FindConVar("director_no_specials");
	GameModes = FindConVar("mp_gamemode");
	GameModes.GetString(namess,sizeof(namess));
	
	// this plugin are only in survival, so checks if gamemode is it, if not so change.
	if(!StrEqual(namess,"survival"))GameModes.SetString("survival");
}

public void OnConfigsExecuted()
{
	// now we can change values of cvar's
	noZombies.IntValue = 0;
	noSpecialZombies.IntValue = 1;
}