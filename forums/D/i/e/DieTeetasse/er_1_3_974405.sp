#include <sourcemod>

#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_NOTIFY
#define PLUGIN_VERSION "1.3"

//Plugin info
public Plugin:myinfo =
{
	name = "Equip Roulette",
	author = "cyborg7th, Die Teetasse",
	description = "Chance of get a molotov or pipe at start.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=106866"
};

/*
History:

v1.3
- Fixed bug where an infected switching to survivor in the startarea didnt get his promised weapon

v1.2
- Fixed possible bug where 2nd team in versus get weapons even l4d_er_versus is 0
- Changed from event round_start to mapstart function
- Fixed possible bug where roulette could start if somebody was joing in the checkpoint room
- (Hopefully) fixed bug where somebody got weapons twice (no roulette for bots anymore)

v1.1
- Fixed bug, where 2nd team didnt get weapons
*/

//Global variables
new bool:active = true;
new bool:alreadygotsomething[4];
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
	HookEvent("round_end", Event_round_end)
	HookEvent("player_spawn", Event_player_spawned, EventHookMode_Post);
	HookEvent("player_left_start_area", Event_player_left_start_area);
} 

public OnMapStart()
{
	//Get gamemode
	new String:mode[10];
	new Handle:gamemode = FindConVar("mp_gamemode");
	GetConVarString(gamemode, mode, sizeof(mode));

	active = false;
	
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
		init_values();
	}
}

public Action:Event_round_end(Handle:event, const String:name[], bool:dontBroadcast)
{
	//Get gamemode
	new String:mode[10];
	new Handle:gamemode = FindConVar("mp_gamemode");
	GetConVarString(gamemode, mode, sizeof(mode));

	//Sometimes Spawn is before Roundstart in 2nd round (only versus)
	if (StrContains(mode, "versus") > -1)
	{
		init_values();
	}
}

init_values()
{
	//On roundstart survivors are inside saferoom		
	startarea = true;
		
	//Reset player
	for (new i = 0; i < 4; i++)
	{
		alreadygotsomething[i] = false;
	}
}

public Action:Event_player_spawned(Handle:event, const String:name[], bool:dontBroadcast)
{    
	//Startarea and activated?
	if (startarea && active)
	{
		//Get Client
		new id = GetEventInt(event, "userid");
		new client = GetClientOfUserId(id);
		
		//Client survivor and human?
		if (GetClientTeam(client) == 2 && !IsFakeClient(client))
		{
			//Get model
			new String:modelname[200];
			GetClientModel(client, modelname, sizeof(modelname));
			
			new number;
			//Find arraynumber by modelname
			//Zoey
			if(StrContains(modelname, "teenangst", false) != -1)
			{
				number	= 0
			}
			//Francis
			else if(StrContains(modelname, "biker", false) != -1)
			{
				number	= 1
			}	
			//Louis
			else if(StrContains(modelname, "manager", false) != -1)
			{
				number	= 2
			}	
			//Bill
			else if(StrContains(modelname, "namvet", false) != -1)
			{
				number	= 3
			}				
			
			//Model got already something or not?
			if (!alreadygotsomething[number])
			{			
				//Get cvar values
				new Float:molotov = GetConVarFloat(cvar_molotov);
				new Float:pipe = GetConVarFloat(cvar_pipe);
			
				//Checking variables (if molotov + pipe > 1.0 then standard values)
				if (FloatCompare(FloatAdd(molotov, pipe), 1.0) > 0)
				{
					//Standard values
					molotov = 0.3;
					pipe = 0.5;
				}
				
				//Generate random numer
				new Float:num = GetRandomFloat(0.0, 1.0);
					
				//Pipe (num <= pipe)
				if (FloatCompare(pipe, num) > -1)
				{
					//Timer so an infected gets time to switch to the survivor complete
					CreateTimer(0.5, Timer_GivePipe, client);
					PrintToChat(client, "[Equip roulette] You won a pipebomb!");
				}	
				//Molov (pipe < num <= pipe + molotv)
				else
				{	
					if (FloatCompare(FloatAdd(molotov, pipe), num) > -1)
					{
						CreateTimer(0.5, Timer_GiveMolov, client);
						PrintToChat(client, "[Equip roulette] You won an molotov!");
					}
					//Nothing (pipe + molotov < num)
					else
					{
						PrintToChat(client, "[Equip roulette] Sorry, nothing for you!");
					}
				}

				//Save that he might got something...
				alreadygotsomething[number] = true;
			}
		}
    }
}  

public Action:Timer_GivePipe(Handle:timer, any:client)
{
	GiveSurvivorItem(client, "weapon_pipe_bomb");
}

public Action:Timer_GiveMolov(Handle:timer, any:client)
{
	GiveSurvivorItem(client, "weapon_molotov");
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
		//First player left startarea, no more spawns
		startarea = false;
	}
}