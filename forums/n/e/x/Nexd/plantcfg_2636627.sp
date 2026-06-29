#include <sourcemod>

ConVar plantedcfg;
ConVar roundstartcfg;

public Plugin myinfo = 
{
	name = "plantcfg",
	author = "Nexd",
	description = "https://forums.alliedmods.net/showthread.php?t=313866",
	version = "1.0"
};

public void OnPluginStart()
{
	HookEvent("bomb_planted", Event_BombPlanted);
	HookEvent("round_start", Event_RoundStart);

	plantedcfg = CreateConVar("sm_plantedcfg", "planted");
	roundstartcfg = CreateConVar("sm_roundstartcfg", "roundstart");

	AutoExecConfig(true, "plugin_plant");
}

public Action Event_BombPlanted(Event event, const char[] name, bool dontBroadcast)
{
	new String:Config1[11];
	GetConVarString(plantedcfg, Config1, sizeof(Config1));
	ServerCommand("exec %s", Config1);
	PrintToServer("Plant config loaded");
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	new String:Config2[11];
	GetConVarString(roundstartcfg, Config2, sizeof(Config2));
	ServerCommand("exec %s", Config2);
	PrintToServer("Default round config loaded");
}