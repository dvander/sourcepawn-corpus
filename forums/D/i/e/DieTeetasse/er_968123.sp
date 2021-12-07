#include <sourcemod>

#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_NOTIFY
#define PLUGIN_VERSION "1.0"

//Plugin info
public Plugin:myinfo =
{
	name = "Equip Roulette",
	author = "cyborg7th, Die Teetasse",
	description = "Chance of get a molotov or pipe at start.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=106866"
};

//Global variables
new bool:startarea = true;

new Handle:cvar_molotov;
new Handle:cvar_pipe;

new Handle:cvar_coop;
new Handle:cvar_survival;
new Handle:cvar_versus;

public OnPluginStart()
{
	//Create cvars
	//Version
	CreateConVar("l4d_er_version", PLUGIN_VERSION, "Equip Roulette version", CVAR_FLAGS|FCVAR_DONTRECORD);
	//Chances	
	cvar_molotov = CreateConVar("l4d_er_chance_molotov", "0.3", "Chance of molotov at start", CVAR_FLAGS, true, 0.0, true, 1.0);	
	cvar_pipe = CreateConVar("l4d_er_chance_pipe", "0.5", "Chance of pipe at start", CVAR_FLAGS, true, 0.0, true, 1.0);
	//Modes
	cvar_coop = CreateConVar("l4d_er_coop", "1", "Equip Roulette in coop mode", CVAR_FLAGS);
	cvar_survival = CreateConVar("l4d_er_survival", "1", "Equip Roulette in survival mode", CVAR_FLAGS);
	cvar_versus = CreateConVar("l4d_er_versus", "1", "Equip Roulette in versus mode", CVAR_FLAGS);
	
    //Hook events
	HookEvent("round_start", Event_round_start)
	HookEvent("player_first_spawn", Event_player_spawned, EventHookMode_Post);
	HookEvent("player_left_start_area", Event_player_left_start_area);
} 

public Action:Event_round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	//Get gamemode
	new String:mode[10];
	new Handle:gamemode = FindConVar("mp_gamemode");
	GetConVarString(gamemode, mode, sizeof(mode));

	new bool:active = false;
	//Is coop?
	if (StrContains(mode, "coop") > -1 && GetConVarInt(cvar_coop) == 1)
	{
		active = true;
	}
	else
	{
		//Survival?
		if (StrContains(mode, "survival") > -1 && GetConVarInt(cvar_survival) == 1)
		{
			active = true;
		}		
		else
		{
			//Versus?
			if (StrContains(mode, "versus") > -1 && GetConVarInt(cvar_versus) == 1)
			{
				active = true;
			}
		}
	}
	
	if (active)
	{
		//On roundstart survivors are inside saferoom
		startarea = true;
	}
	else
	{
		//No startarea = no roulette
		startarea = false;
	}
}

public Action:Event_player_spawned(Handle:event, const String:name[], bool:dontBroadcast)
{    
	//Startarea and activated?
	if (startarea)
	{
		//Get Client
		new id = GetEventInt(event, "userid");
		new client = GetClientOfUserId(id);
	
		//Client survivor?
		if (GetClientTeam(client) == 2)
		{
			//Get cvar values
			new Float:molotov = GetConVarFloat(cvar_molotov);
			new Float:pipe = GetConVarFloat(cvar_pipe);
		
			//Checking variables (are both together greater than 1.0?)
			if (FloatCompare(FloatAdd(molotov, pipe), 1.0) > 0)
			{
				//Standard values
				molotov = 0.3;
				pipe = 0.5;
			}
			
			//Generate random numer
			new Float:num = GetRandomFloat(0.0, 1.0);
				
			//Pipe
			if (FloatCompare(pipe, num) > -1)
			{
				GiveSurvivorItem(client, "weapon_pipe_bomb");
				PrintToChat(client, "[Equip roulette] You won a pipebomb!");
			}	
			//Molov
			else
			{	
				if (FloatCompare(FloatAdd(molotov, pipe), num) > -1)
				{
					GiveSurvivorItem(client, "weapon_molotov");
					PrintToChat(client, "[Equip roulette] You won an molotov!");
				}
				else
				{
					PrintToChat(client, "[Equip roulette] Sorry, nothing for you!");
				}
			}
		}
    }
}  

GiveSurvivorItem(client, String:item[])
{
	//Strip cheatflag
	new flags = GetCommandFlags("give")
	SetCommandFlags("give", flags & ~FCVAR_CHEAT)
	
	//Give item
	FakeClientCommand(client, "give %s", item)
	
	//Set cheatflag
	SetCommandFlags("give", flags)
}

public Action:Event_player_left_start_area(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (startarea)
	{
		//First players left startarea, no more spawns
		startarea = false;
	}
}