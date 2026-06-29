#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <colors>

#define PLGN_VRSN "1.0.1"

public Plugin:myinfo =
{
	name = "ND Structure Killing Mini-Game",
	author = "databomb",
	description = "Provides a mini-game and announcement for structure killing",
	version = PLGN_VRSN,
	url = "vintagejailbreak.org"
};

#define TEAM_EMPIRE		3
#define TEAM_CONSORT	2
#define TEAM_SPEC		1
#define MAX_TEAMS 		4

new StructuresKilled[MAX_TEAMS];
new Handle:gH_Cvar_DisplayTimes = INVALID_HANDLE;

public OnPluginStart()
{
	HookEvent("structure_death", Event_StructDeath);
	gH_Cvar_DisplayTimes = CreateConVar("nd_struct_msg_multiplier", "3", "Number of times the team advantage message is repeated.", FCVAR_PLUGIN, true, 0.0);
}

public OnMapStart()
{
	ClearKills();
}

ClearKills()
{
	for (new idx = 0; idx < MAX_TEAMS; idx++)
	{
		StructuresKilled[idx] = 0;
	}
}

public Event_StructDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));
	new ent = GetEventInt(event, "entindex");
	//new team = GetEventInt(event, "team");
	new team = GetClientTeam(client);
	new type = GetEventInt(event, "type");
	
	decl String:buildingname[32];
	// get building name
	switch (type)
	{
		case 0:
		{
			Format(buildingname, sizeof(buildingname), "the Command Bunker");
		}
		case 1:
		{
			Format(buildingname, sizeof(buildingname), "a Machine Gun Turret");
		}
		case 2:
		{
			Format(buildingname, sizeof(buildingname), "a Transport Gate");
		}
		case 3:
		{
			Format(buildingname, sizeof(buildingname), "a Power Station");
		}
		case 4:
		{
			Format(buildingname, sizeof(buildingname), "a Wireless Repeater");
		}
		case 5:
		{
			Format(buildingname, sizeof(buildingname), "a Relay Tower");
		}
		case 6:
		{
			Format(buildingname, sizeof(buildingname), "a Supply Station");
		}
		case 7:
		{
			Format(buildingname, sizeof(buildingname), "an Assembler");
		}
		case 8:
		{
			Format(buildingname, sizeof(buildingname), "an Armory");
		}
		case 9:
		{
			Format(buildingname, sizeof(buildingname), "an Artillery");
		}
		case 10:
		{
			Format(buildingname, sizeof(buildingname), "a Radar Station");
		}
		case 11:
		{
			Format(buildingname, sizeof(buildingname), "a Flamethrower Turret");
		}
		case 12:
		{
			Format(buildingname, sizeof(buildingname), "a Sonic Turret");
		}
		case 13:
		{
			Format(buildingname, sizeof(buildingname), "a Rocket Turret");
		}
		case 14:
		{
			Format(buildingname, sizeof(buildingname), "a Wall");
		}
		case 15:
		{
			Format(buildingname, sizeof(buildingname), "a Barrier");
		}
		default:
		{
			Format(buildingname, sizeof(buildingname), "a %d (?)", type);
		}
	}
	
	StructuresKilled[team]++;
	
	decl String:sName[64];
	GetEntityClassname(ent, sName, sizeof(sName));
	
	ReplaceString(sName, sizeof(sName), "struct_", "", false);
	
	if (StructuresKilled[TEAM_EMPIRE] + StructuresKilled[TEAM_CONSORT] >= 20)
	{
		ClearKills();
		
		if (team == TEAM_CONSORT)
		{
			new loops = GetConVarInt(gH_Cvar_DisplayTimes);
			for (new idx = 1; idx <= loops; idx++)
			{
				CPrintToChatAll("{red}%N {lightgreen}just gave {red}Consortium {lightgreen}the advantage!", client);
			}
			PrintCenterTextAll("Advantage - Consortium");
			
		}
		else if (team == TEAM_EMPIRE)
		{
			new loops = GetConVarInt(gH_Cvar_DisplayTimes);
			for (new idx = 1; idx <= loops; idx++)
			{
				CPrintToChatAll("{blue}%N {lightgreen}just gave the {blue}Empire {lightgreen}the advantage!", client);
			}
			PrintCenterTextAll("Advantage - Empire");
		}
		
		GiveBonus(team);
		
		return;
	}
	
	if (team == TEAM_CONSORT)
	{
		CPrintToChatAll("{red}%N {lightgreen}destroyed %s for {red}the Consortium", client, buildingname);
	}
	else if (team == TEAM_EMPIRE)
	{
		CPrintToChatAll("{blue}%N {lightgreen}destroyed %s for {blue}the Empire", client, buildingname);
	}
}

GiveBonus(team)
{
	new health = 0;
	new cliteam = 0;
	new Commander = (team == TEAM_CONSORT) ? GameRules_GetPropEnt("m_hCommanders", 0) : GameRules_GetPropEnt("m_hCommanders", 1);
	for (new idx = 1; idx <= MaxClients; idx++)
	{
		if (IsClientInGame(idx) && IsPlayerAlive(idx) && idx != Commander)
		{
			cliteam = GetClientTeam(idx);
			health = GetClientHealth(idx);
			if (cliteam == team)
			{
				health += 175;
			}
			SetEntityHealth(idx, health);
		}
	}
}