#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

public Plugin:myinfo =
{
	name = "Freak Fortress 2: ServerCommandRage",
	author = "frog",
	version = "1.1"
};


public OnPluginStart2()
{

}


public Action:FF2_OnAbility2(index, const String:plugin_name[], const String:ability_name[], action)
{
	if(!strcmp(ability_name, "rage_servercommand"))		//Execute a server command
	{
		Rage_ServerCommand(ability_name, index);
	}
	return Plugin_Continue;
}


Rage_ServerCommand(const String:ability_name[],index)
{
	new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
	new rageDistance=FF2_GetAbilityArgument(index, this_plugin_name, ability_name, 1);	//rage distance
	new rageDuration=FF2_GetAbilityArgument(index, this_plugin_name, ability_name, 2);	//rage duration
	new String:rageStartCommand[PLATFORM_MAX_PATH];
	FF2_GetAbilityArgumentString(index, this_plugin_name, ability_name, 3, rageStartCommand, PLATFORM_MAX_PATH); //rage start command
	new String:rageStartCommandParameters[PLATFORM_MAX_PATH];
	FF2_GetAbilityArgumentString(index, this_plugin_name, ability_name, 4, rageStartCommandParameters, PLATFORM_MAX_PATH); //rage start command parameters
	new String:rageEndCommand[PLATFORM_MAX_PATH];
	FF2_GetAbilityArgumentString(index, this_plugin_name, "rage_servercommand", 5, rageEndCommand, PLATFORM_MAX_PATH); //rage end command
	new String:rageEndCommandParameters[PLATFORM_MAX_PATH];
	FF2_GetAbilityArgumentString(index, this_plugin_name, "rage_servercommand", 6, rageEndCommandParameters, PLATFORM_MAX_PATH); //rage end command parameters
	new rageCommandMode=FF2_GetAbilityArgument(index, this_plugin_name, ability_name, 7);	//rage command mode
	
	decl Float:pos[3];
	decl Float:pos2[3];
	decl Float:distance;

	new Float:vel[3];
	vel[2]=20.0;
	
	TeleportEntity(Boss,  NULL_VECTOR, NULL_VECTOR, vel);
	GetEntPropVector(Boss, Prop_Send, "m_vecOrigin", pos);
	
	if(rageCommandMode == 0)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) != FF2_GetBossTeam())
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", pos2);
				distance = GetVectorDistance(pos, pos2);
				if(distance < rageDistance)
				{
					ServerCommand("%s #%i %s", rageStartCommand, GetClientUserId(i), rageStartCommandParameters);
					if(rageDuration)
					{
						new Handle:pack = CreateDataPack();
						CreateTimer(float(rageDuration), EndCommand_Timer, pack);
						WritePackCell(pack, i);
						WritePackString(pack, rageEndCommand);
						WritePackString(pack, rageEndCommandParameters);
						ResetPack(pack);	
					}
				}
			}	
		}
	} 
	else if(rageCommandMode == 1)
	{
		ServerCommand("%s", rageStartCommand);
		new Handle:pack = CreateDataPack();
		CreateDataTimer(float(rageDuration), EndCommandGlobal, pack);		
		WritePackString(pack, rageEndCommand);
		WritePackString(pack, rageEndCommandParameters);
		ResetPack(pack);
	}
	else if(rageCommandMode == 2)
	{
		ServerCommand("%s #%i %s", rageStartCommand, GetClientUserId(Boss), rageStartCommandParameters);
		if(rageDuration)
		{
			new Handle:pack = CreateDataPack();
			CreateDataTimer(float(rageDuration), EndCommand_Timer, pack);	
			WritePackCell(pack, Boss);
			WritePackString(pack, rageEndCommand);
			WritePackString(pack, rageEndCommandParameters);
			ResetPack(pack);
		}
	}
	else if(rageCommandMode == 3)
	{
		FakeClientCommand(Boss, "%s %s", rageStartCommand, rageStartCommandParameters);
		if(rageDuration)
		{
			new Handle:pack = CreateDataPack();
			CreateDataTimer(float(rageDuration), EndCommandBoss_Timer, pack);	
			WritePackCell(pack, Boss);
			WritePackString(pack, rageEndCommand);
			WritePackString(pack, rageEndCommandParameters);
			ResetPack(pack);
		}
	}
}


public Action:EndCommandGlobal(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new String:rageEndCommand[PLATFORM_MAX_PATH];
	ReadPackString(pack, rageEndCommand, sizeof(rageEndCommand));
	new String:rageEndCommandParameters[PLATFORM_MAX_PATH];
	ReadPackString(pack, rageEndCommandParameters, sizeof(rageEndCommandParameters));
	ServerCommand("%s %s", rageEndCommand, rageEndCommandParameters);
}


public Action:EndCommandBoss_Timer(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new Boss = ReadPackCell(pack);
	new String:rageEndCommand[PLATFORM_MAX_PATH];
	ReadPackString(pack, rageEndCommand, sizeof(rageEndCommand));
	new String:rageEndCommandParameters[PLATFORM_MAX_PATH];
	ReadPackString(pack, rageEndCommandParameters, sizeof(rageEndCommandParameters));
	
	if(IsClientInGame(Boss))
	{
		FakeClientCommand(GetClientUserId(Boss),"%s %s", rageEndCommand, rageEndCommandParameters);
	}
}


public Action:EndCommand_Timer(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new client = ReadPackCell(pack);
	new String:rageEndCommand[PLATFORM_MAX_PATH];
	ReadPackString(pack, rageEndCommand, sizeof(rageEndCommand));
	new String:rageEndCommandParameters[PLATFORM_MAX_PATH];
	ReadPackString(pack, rageEndCommandParameters, sizeof(rageEndCommandParameters));
	
	if(IsClientInGame(client))
	{
		ServerCommand("%s #%i %s", rageEndCommand, GetClientUserId(client), rageEndCommandParameters);
	}
}


