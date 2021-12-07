#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.3"
#define GAME_LENGTH 64

public Plugin:myinfo =
{
	name = "[L4D2] Give Grenade Launcher",
	author = "Black David",
	description = "Gives you a grenade launcher in round start",
	version = "PLUGIN_VERSION",
	url =  "https://forums.alliedmods.net/showthread.php?p=2531006"
}

new Handle:h_GiveGrenadeLauncherEnabled = INVALID_HANDLE;

public OnPluginStart()
{
	decl String:game_name[GAME_LENGTH];
	GetGameFolderName(game_name, sizeof(game_name));
	if (StrContains(game_name, "left4dead2", false) < 0)
	{
		SetFailState("Plugin supports Left 4 Dead 2 only.");
	}
	
	HookEvent("round_start", EventGiveGrenadeLauncher, EventHookMode_Post);
	CreateConVar("l4d2_give_grenade_launcher_version", PLUGIN_VERSION, "[L4D2] Give Grenade Launcher Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	h_GiveGrenadeLauncherEnabled = CreateConVar("l4d2_give_grenade_launcher", "1", "0 = Disable Plugin 1 = Enable Plugin. Setting this to 1 will spawn a Grenade Launcher start of the map.", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	AutoExecConfig(true, "[L4D2] Give Grenade Launcher");
}

public onMapStart()
{
	if (!GetConVarBool(h_GiveGrenadeLauncherEnabled)) return;
	GiveGrenadeLauncherAll();
}

public EventGiveGrenadeLauncher(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(10.0, GiveGrenadeLauncherDelay);
}

public Action:GiveGrenadeLauncherDelay(Handle:timer)
{
	GiveGrenadeLauncherAll()
}

public GiveGrenadeLauncherAll()
{
	new flags = GetCommandFlags("give");
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i)==2) FakeClientCommand(i, "give grenade launcher");
	}
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
}

public OnMapEnd()
{
	GiveGrenadeLauncherAll();
}