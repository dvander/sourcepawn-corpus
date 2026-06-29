#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

new BossTeam=_:TFTeam_Blue;
new Handle:g_commandTimers[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name = "Freak Fortress 2: ServerCommandRage",
	author = "frog",
	version = "0.9.8"
};


public OnPluginStart2()
{
	HookEvent("arena_round_start", Event_RoundStart, EventHookMode_PostNoCopy);
}

public Action:Event_RoundStart(Handle:event,const String:name[],bool:dontBroadcast)
{
	if (FF2_IsFF2Enabled())
	{
		new Boss=GetClientOfUserId(FF2_GetBossUserId(0));
		if (Boss>0)
		{
			if (FF2_HasAbility(0,this_plugin_name,"rage_servercommand"))
			{
				LogMessage("Boss has servercommand rage");
			}
		}
	}
}


public Action:FF2_OnAbility2(index,const String:plugin_name[],const String:ability_name[],action)
{
	if(!strcmp(ability_name,"rage_servercommand"))		//Execute a server command
	{
		Rage_ServerCommand(ability_name,index);
	}
	return Plugin_Continue;
}


Rage_ServerCommand(const String:ability_name[],index)
{
	LogMessage("Rage_ServerCommand used");
	new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
	new rageDistance=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 1);	//rage distance
	new rageDuration=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 2);	//rage duration
	new String:rageStartCommand[PLATFORM_MAX_PATH];
	FF2_GetAbilityArgumentString(index,this_plugin_name,ability_name,3,rageStartCommand,PLATFORM_MAX_PATH); //rage start command
	new String:rageStartCommandParameters[PLATFORM_MAX_PATH];
	FF2_GetAbilityArgumentString(index,this_plugin_name,ability_name,4,rageStartCommandParameters,PLATFORM_MAX_PATH); //rage start command parameters
	new String:rageEndCommand[PLATFORM_MAX_PATH];
	FF2_GetAbilityArgumentString(index,this_plugin_name,"rage_servercommand",5,rageEndCommand,PLATFORM_MAX_PATH); //rage end command
	new String:rageEndCommandParameters[PLATFORM_MAX_PATH];
	FF2_GetAbilityArgumentString(index,this_plugin_name,"rage_servercommand",6,rageEndCommandParameters,PLATFORM_MAX_PATH); //rage end command parameters
	new rageCommandMode=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 7);	//rage command mode
	
	decl Float:pos[3];
	decl Float:pos2[3];
	decl Float:distance;

	new Float:vel[3];
	vel[2]=20.0;
	
	new affected=0;
	
	TeleportEntity(Boss,  NULL_VECTOR, NULL_VECTOR, vel);
	GetEntPropVector(Boss, Prop_Send, "m_vecOrigin", pos);
	
	if(rageCommandMode == 0)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i)!=BossTeam)
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", pos2);
				distance = GetVectorDistance(pos, pos2);
				if(distance < rageDistance)
				{
					affected++;
					LogMessage("%s #%i %s",rageStartCommand,GetClientUserId(i),rageStartCommandParameters);
					ServerCommand("%s #%i %s",rageStartCommand,GetClientUserId(i),rageStartCommandParameters);
					if(rageDuration)
					{
						new Handle:pack = CreateDataPack();
						g_commandTimers[i] = CreateTimer(float(rageDuration), EndCommand_Timer, pack);
						WritePackCell(pack, i);
						WritePackString(pack, rageEndCommand);
						WritePackString(pack, rageEndCommandParameters);
						ResetPack(pack);	
					}
				}
			}	
		}
		LogMessage("Boss used servercommand rage '%s %s' and %i players were within range (%i) of it's effect.",rageStartCommand,rageStartCommandParameters,affected,rageDistance);
	} 
	else if(rageCommandMode == 1)
	{
		ServerCommand("%s",rageStartCommand);
		new Handle:pack = CreateDataPack();
		CreateDataTimer(float(rageDuration), EndCommandGlobal, pack);		
		WritePackString(pack, rageEndCommand);
		WritePackString(pack, rageEndCommandParameters);
		ResetPack(pack);
	}
	else if(rageCommandMode == 2)
	{
		ServerCommand("%s #%i %s",rageStartCommand,GetClientUserId(Boss),rageStartCommandParameters);
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
		FakeClientCommand(Boss,"%s %s",rageStartCommand,rageStartCommandParameters);
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
	ServerCommand("%s %s",rageEndCommand,rageEndCommandParameters);
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
		FakeClientCommand(GetClientUserId(Boss),"%s %s",rageEndCommand,rageEndCommandParameters);
	}
	return Plugin_Handled;
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
		LogMessage("%s #%i %s",rageEndCommand,GetClientUserId(client),rageEndCommandParameters);
		ServerCommand("%s #%i %s",rageEndCommand,GetClientUserId(client),rageEndCommandParameters);
	}
	return Plugin_Handled;
}


public OnClientDisconnect(client)
{
	if (g_commandTimers[client] != INVALID_HANDLE)
	{
		KillTimer(g_commandTimers[client]);
		g_commandTimers[client] = INVALID_HANDLE;
	}
}