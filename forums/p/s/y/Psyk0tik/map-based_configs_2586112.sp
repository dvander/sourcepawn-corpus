#include <sourcemod>
#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name = "[L4D & L4D2] Map-based Configs",
	author = "Chi_Nai",
	version = "1.2",
	description = "Allows for custom settings for each map.",
	url = "https://forums.alliedmods.net/showthread.php?t=306525"
};

public void OnAutoConfigsBuffered()
{
	char sMapConfig[128];
	GetCurrentMap(sMapConfig, sizeof(sMapConfig));
	Format(sMapConfig, sizeof(sMapConfig), "cfg/sourcemod/map_cvars/%s.cfg", sMapConfig);
	if (FileExists(sMapConfig, true))
	{
		strcopy(sMapConfig, sizeof(sMapConfig), sMapConfig[4]);
		ServerCommand("exec \"%s\"", sMapConfig);
	}
}