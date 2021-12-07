#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2attributes>

#define PLUGIN_VERSION "1.01"

#define TEAM_RED 2
#define TEAM_BLU 3
#define teamDefendingMaxSize 6

new Handle:cvarHealthReduction = INVALID_HANDLE;
new Handle:cvarDamageReduction = INVALID_HANDLE;

new Float:m_healthReductionPerPlayer;
new Float:m_damageReductionPerPlayer;

new m_redTeamPlayerCount;
new m_playersMissingCount;

new Handle:m_tankArray;

public Plugin:myinfo =
{
	name = "TF2 Mann vs Machine Player Scaler",
	author = "JazzMcFly",
	description = "Scales the health and damage output of bots based on the RED team playercount.",
	version = PLUGIN_VERSION
}

public OnPluginStart()
{
	CreateConVar("tf2_mvm_balancer_version", PLUGIN_VERSION, "Plugin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarHealthReduction = CreateConVar("tf2_mvm_balancer_healthreduce", "13.0", "For each player missing from the cap of 6, the robots will have their maxHealth reduced by this percentage. (Example: if this value is 10 and there are 3 players in the server, the robots will have only 70% maxhealth)", 0, true, 0.0, true, 20.0);	
	cvarDamageReduction = CreateConVar("tf2_mvm_balancer_damagereduce", "15.0", "For each player missing from the cap of 6, the robots will have their damage output reduced by this percentage.", 0, true, 0.0, true, 20.0);
	AutoExecConfig(true, "tf2_mvm_balancer");


	RegAdminCmd("sm_sethploss", Command_SetHealthPenaltyPerPlayer, ADMFLAG_ROOT, "Set the percent HP loss of robots per missing player");
	RegAdminCmd("sm_setdmgloss", Command_SetDamagePenaltyPerPlayer, ADMFLAG_ROOT, "Set the percent damage loss of robots per missing player");

	m_tankArray = CreateArray();

	HookEvent("player_spawn", event_PlayerSpawn);
	HookEvent("player_death", event_PlayerDeath);
	HookEvent("mvm_begin_wave", event_BeginWave);
	HookEvent("player_disconnect", event_PlayerDisconnect);
	HookEvent("player_team", event_PlayerChangeTeam);
	HookEvent("mvm_tank_destroyed_by_players", event_TankKilled);
   	
	CreateTimer(5.0, timer_CheckForTanks, _, TIMER_REPEAT);	


}

public OnConfigsExecuted()
{
	m_healthReductionPerPlayer = GetConVarFloat(cvarHealthReduction) / -100.0;
	m_damageReductionPerPlayer = GetConVarFloat(cvarDamageReduction) / -100.0;
	IsValidHandicap();
}

public Action:Command_SetHealthPenaltyPerPlayer(client, args)
{
	if(args == 1)
	{
		decl String:arg1[40];
		GetCmdArg(1, arg1, sizeof(arg1))
		new Float:temp = StringToFloat(arg1);
		if(temp > 0.0)
		{
			temp = -temp;
		}
		m_healthReductionPerPlayer = temp / 100.0;
		if(IsValidHandicap())
		{
			temp *= -1.0; //prepare to print
			PrintToChatAll("\x04MvMBalancer: Robots now lose %f percent of their health for each missing player.", temp);
		}
	}
	else
	{
		ReplyToCommand(client, "Usage: Requires exactly 1 argument.");
	}
}

public Action:Command_SetDamagePenaltyPerPlayer(client, args)
{
	if(args == 1)
	{
		decl String:arg1[40];
		GetCmdArg(1, arg1, sizeof(arg1))
		new Float:temp = StringToFloat(arg1);
		if(temp > 0.0)
		{
			temp = -temp;
		}
		m_damageReductionPerPlayer = temp / 100.0;
		if(IsValidHandicap())
		{
			temp *= -1.0; //prepare to print
			PrintToChatAll("\x04MvMBalancer: Robots now deal %f percent less damage for each missing player.", temp);
		}
	}
	else
	{
		ReplyToCommand(client, "Usage: Requires exactly 1 argument.");
	}
}


public event_BeginWave(Handle:event, const String:name[], bool:dontBroadcast)
{
	ClearArray(m_tankArray);
	CountRedTeam();
	PrintHandicapToAll();
}


public event_PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	new isBot = GetEventBool(event, "is a bot");
	if(!isBot)
	{
		CreateTimer(0.3, timer_ForceTeamRecount);		
	}
}

public event_PlayerChangeTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new team = GetEventInt(event, "team");
	new oldTeam = GetEventInt(event, "oldteam");
	if(team == TEAM_RED && oldTeam != TEAM_RED)
	{
		CreateTimer(0.3, timer_ForceTeamRecount);		
	}
}

public Action:timer_ForceTeamRecount(Handle:timer)
{
	CountRedTeam();
	PrintHandicapToAll();			
}

public event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
 	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(IsClientInGame(client) && GetClientTeam(client) == TEAM_BLU)
	{
    		CreateTimer(0.3, timer_PlayerSpawn, client);
	}
}

public Action:timer_PlayerSpawn(Handle:timer, any:client)
{
	//Have to recheck b/c it is possible that the bot died/joined spectator (Hint hint: this happens on round end for supports that just spawned in.)
	if(IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == TEAM_BLU )
	{

		new Float:healthBonus = 0.0;		

		//Check for the giant healthbonus
		new Address:healthAddress = TF2Attrib_GetByName(client, "hidden maxhealth non buffed");
		if(healthAddress != Address_Null)
		{
			healthBonus = TF2Attrib_GetValue(healthAddress);
			//PrintToChatAll("MvMBalancer: Client %d has a hidden health bonus of %3.2ff", client, healthBonus);
		}
		
		//Find the class health and add it with the giant bonus
		new classMaxHealth = GetEntProp( client, Prop_Data, "m_iMaxHealth" );
		new Float:totalMaxHealth = float(classMaxHealth) + healthBonus;

		//Calculate the health penalty and attach it as an attribute to the client.
    		new Float:healthPenalty = totalMaxHealth * (float(m_playersMissingCount) *  m_healthReductionPerPlayer);
		new newMaxHealth = RoundToZero(totalMaxHealth + healthPenalty);
		TF2Attrib_SetByName(client, "max health additive penalty", healthPenalty);
		SetEntProp(client, Prop_Send, "m_iHealth", newMaxHealth);

		//Calculate damage penalty and attach it as an attribute to the client	
		new Float:damagePenalty = (1.0 + m_healthReductionPerPlayer * float(m_playersMissingCount)); 
//		PrintToChatAll("MvMBalancer: Missing Players = %d, damage Penalty = %f", m_playersMissingCount, damagePenalty);
		TF2Attrib_SetByName(client, "damage penalty", damagePenalty);


		TF2Attrib_ClearCache(client);

//		PrintToChatAll("MvMBalancer: oldMaxHP = %3.2f\tHealth Penalty = %3.2fhp\tnewMaxHp = %d", totalMaxHealth, healthPenalty, newMaxHealth);

		
	}
}


public event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(IsClientInGame(client) && GetClientTeam(client) == TEAM_BLU )
	{
		TF2Attrib_RemoveByName(client, "max health additive penalty");
		TF2Attrib_RemoveByName(client, "damage penalty");
	}

}

public Action:timer_CheckForTanks(Handle:timer)
{
	new ent_tank = -1;
	while ((ent_tank = FindEntityByClassname(ent_tank, "tank_boss")) != -1)
	{
		if (ent_tank > 0 && FindValueInArray(m_tankArray, ent_tank) == -1)
		{
			PushArrayCell(m_tankArray, ent_tank);
			new baseHealth = GetEntProp(ent_tank, Prop_Data, "m_iMaxHealth");
			//Tanks do not seem to ever have any hidden health, but I like to check to be sure.
			new Address:healthAddress = TF2Attrib_GetByName(ent_tank, "hidden maxhealth non buffed");
			if(healthAddress != Address_Null)
			{
				new Float:healthBonus = TF2Attrib_GetValue(healthAddress);
				//PrintToChatAll("MvMBalancer: Tank %d has a hidden health bonus of %3.2ff", ent_tank, healthBonus);
				baseHealth += RoundToZero(healthBonus);
			}

			new Float:healthPenalty = float(baseHealth) * (float(m_playersMissingCount) *  m_healthReductionPerPlayer);					
			new newMaxHealth = RoundToZero(float(baseHealth) + healthPenalty);
			//PrintToChatAll("MvMBalancer: healthPenalty %f\tnewMaxHealth %d", healthPenalty, newMaxHealth);	
			SetVariantInt(newMaxHealth); 
			AcceptEntityInput(ent_tank, "SetHealth");
			SetVariantInt(newMaxHealth); 
			AcceptEntityInput(ent_tank, "SetMaxHealth")
		}
	}
}

public event_TankKilled(Handle:event, const String:name[], bool:dontBroadcast)
{
	//This does not have any event vars so I just need to poll the whole list
	for(new i = 0; i < GetArraySize(m_tankArray); i++)
	{
		new String:testString[64];
		if(GetEntityClassname(GetArrayCell(m_tankArray, i), testString, 64))
		{
			if(strcmp(testString, "tank_boss") != 0)
			{
				RemoveFromArray(m_tankArray, i);
			}
			else
			{
				if(GetEntProp(GetArrayCell(m_tankArray, i), Prop_Data, "m_iHealth") <= 0)
				{
					RemoveFromArray(m_tankArray, i);
				}
			}
		}
		else
		{
			RemoveFromArray(m_tankArray, i);
		}
	}
}

stock CountRedTeam()
{
	new redCount = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) )
		{
			if(GetClientTeam(i) == TEAM_RED)
			{
				redCount++;
			}
		}	
	}
	m_redTeamPlayerCount = redCount;
	m_playersMissingCount = teamDefendingMaxSize - m_redTeamPlayerCount;
} 




stock bool:IsValidHandicap()
{
	new bool:isValid = true;
	if(m_healthReductionPerPlayer <= -0.200)
	{
		m_healthReductionPerPlayer = -0.19;
		new Float:valueToPrint = m_healthReductionPerPlayer * -100.0;
		PrintToChatAll("\x04MvMBalancer: Health Handicap too high, setting to %3.2f per missing player", valueToPrint);
		isValid = false;	
	}
 
	if(m_damageReductionPerPlayer <= -0.200)
	{
		m_damageReductionPerPlayer = -0.19;
		new Float:valueToPrint = m_damageReductionPerPlayer * -100.0;		
		PrintToChatAll("\x04MvMBalancer: Damage Handicap too high, setting to %3.2f per missing player", valueToPrint);	
		isValid = false;
	}   
	return isValid;
}

stock PrintHandicapToAll()
{
	decl String:buffer[400];
	//new missingPlayerCount = teamDefendingMaxSize - m_redTeamPlayerCount;
	new Float:healthPenalty = (1.0 +(m_healthReductionPerPlayer * float(m_playersMissingCount))) * 100.0;
	new Float:damagePenalty = (1.0 + m_healthReductionPerPlayer * float(m_playersMissingCount))  * 100.0;
	//PrintToChatAll("Robot damage penalty per player = %f\t%d", damagePenalty, m_playersMissingCount); 
	Format(buffer, sizeof(buffer), "\x04MvMBalancer: Because there are %d/%d players, the robot horde will only have %3.1f percent health and deal %3.1f percent damage.", m_redTeamPlayerCount, teamDefendingMaxSize, healthPenalty, damagePenalty); 
	PrintToChatAll(buffer);

}


