#pragma semicolon 1
#include <sourcemod>
#define PLUGIN_VERSION "1.3"

#if !defined DEBUG_MULTIWITCHES
	#define DEBUG_MULTIWITCHES 0
#endif

public Plugin:myinfo = 
{
	name = "[L4D & L4D2] Multiwitches",
	author = "McFlurry",
	description = "Spawns more witches.",
	version = PLUGIN_VERSION,
	url = "N/A"
}

new Handle:hEnable = INVALID_HANDLE;
new Handle:hCount = INVALID_HANDLE;
new Handle:hModes = INVALID_HANDLE;

new witchcount = 0;
new ignorecount = 0;

public OnPluginStart()
{
	decl String:game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (!StrEqual(game_name, "left4dead2", false) && !StrEqual(game_name, "left4dead", false))
	{		
		SetFailState("Plugin supports Left 4 Dead series only.");
	}
	CreateConVar("l4d_multiwitches_version", PLUGIN_VERSION, "Version of MultiWitches on this server!", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	hEnable = CreateConVar("l4d_multiwitches_enable", "1", "Enable or Disable this plugin?", FCVAR_PLUGIN|FCVAR_NOTIFY);
	hCount = CreateConVar("l4d_multiwitches_witches", "1", "How many extra witches to create?", FCVAR_PLUGIN|FCVAR_NOTIFY);
	hModes = CreateConVar("l4d_multiwitches_modes", "coop,realism,versus,teamversus","Which gamemodes allow extra witches",FCVAR_PLUGIN|FCVAR_NOTIFY);
	AutoExecConfig(true, "l4d_multiwitches");
	HookEvent("witch_spawn", Event_Witch);
}

public OnMapStart()
{	
	witchcount = 0;
	ignorecount = 0;
	PrecacheModel("models/infected/witch.mdl", true);
}	

stock bool:IsAllowedGameMode()
{
	decl String:gamemode[24], String:gamemodeactive[128];
	GetConVarString(FindConVar("mp_gamemode"), gamemode, sizeof(gamemode));
	GetConVarString(hModes, gamemodeactive, sizeof(gamemodeactive));
	return (StrContains(gamemodeactive, gamemode) != -1);
}

public AddWitch()
{
	if(CreateEdict() == 0) return;
	new flags = GetCommandFlags("z_spawn");
	SetCommandFlags("z_spawn", flags & ~FCVAR_CHEAT);
	for(new i=1;i<=MaxClients;i++)
	{
		if(IsClientInGame(i))
		{
			FakeClientCommand(i, "z_spawn witch auto");
			break;
		}
	}	
	SetCommandFlags("z_spawn", flags|FCVAR_CHEAT);
	#if(DEBUG_MULTIWITCHES)
	{
		PrintToChatAll("AddWitch() Called!");
		PrintToServer("AddWitch() Called!");
	}	
	#endif
}

public Action:Event_Witch(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(ignorecount > 0)
	{
		ignorecount--;
		return;
	}	
	if(GetConVarBool(hEnable) && IsAllowedGameMode())
	{
		witchcount = 0;
		new spawnct = GetConVarInt(hCount);
		while(witchcount < spawnct)
		{
			ignorecount++;
			witchcount++;
			AddWitch();
		}
	}
}

public OnEntityCreated(entity, const String:classname[])
{
	if(StrEqual(classname, "witch", false))
	{
		#if(DEBUG_MULTIWITCHES)
		{
			PrintToChatAll("Witch %d Created!", entity);
			PrintToServer("Witch %d Created!", entity);
		}
		#endif
	}
}	