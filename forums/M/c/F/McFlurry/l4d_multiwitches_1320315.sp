#include <sourcemod>
#define PLUGIN_VERSION "1.1"
#pragma semicolon 1

#if !defined DEBUG
#define DEBUG	1
#endif

public Plugin:myinfo = 
{
	name = "[L4D & L4D2] Multiwitches",
	author = "McFlurry",
	description = "Spawns more witches.",
	version = PLUGIN_VERSION,
	url = "N/A"
}

new Handle:Enable;
new Handle:Count;
new Handle:Modes;
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
	CreateConVar("l4d_witches_version", PLUGIN_VERSION,"version",FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	Enable = CreateConVar("l4d_multiwitch_enable", "1","Enable or Disable this plugin?",FCVAR_PLUGIN);
	Count = CreateConVar("l4d_extra_witches", "1", "How many extra witches to create?", FCVAR_PLUGIN);
	Modes = CreateConVar("l4d_multiwitch_modes", "coop,realism,versus,teamversus","Which gamemodes allow extra witches",FCVAR_PLUGIN);
	AutoExecConfig(true, "l4d_multiwitches");
	HookEvent("witch_spawn", Event_Witch);
}

public OnMapStart()
{
	witchcount = 0;
	ignorecount = 0;
}	

stock bool:IsAllowedGameMode()
{
	decl String:gamemode[24], String:gamemodeactive[64];
	GetConVarString(FindConVar("mp_gamemode"), gamemode, sizeof(gamemode));
	GetConVarString(Modes, gamemodeactive, sizeof(gamemodeactive));
	if(strlen(gamemodeactive) == 0) return true;
	else return (StrContains(gamemodeactive, gamemode) != -1);
}

public AddWitch()
{
	CreateEdict(); //Create an edict to prevent server crash if plugin is set to extreme levels of witches!
	new Flags = GetCommandFlags("z_spawn");
	SetCommandFlags("z_spawn", Flags & ~FCVAR_CHEAT);
	new bool:exe = false;
	for(new i=1;i<=MaxClients;i++)
	{
		if(exe) return;
		if(IsClientInGame(i) && IsClientConnected(i))
		{
			exe = true;
			FakeClientCommand(i, "z_spawn witch auto");
		}
	}	
	SetCommandFlags("z_spawn", Flags|FCVAR_CHEAT);
	#if(DEBUG)
	{
		PrintToChatAll("AddWitch() Called!");
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
	if(GetConVarInt(Enable) == 1 && IsAllowedGameMode())
	{
		witchcount = 0;
		new spawnct = GetConVarInt(Count);
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
		#if(DEBUG)
		{
			PrintToChatAll("Witch %d Created!", entity);
		}
		#endif
	}
}	