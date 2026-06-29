#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

new BossTeam=_:TFTeam_Blue;
new Handle:commandTimers[ MAXPLAYERS + 1 ];


public Plugin:myinfo = {
	name = "Freak Fortress 2: ServerCommandRage",
	author = "frog",
	version = "0.9.7.1",
};

public OnPluginStart2()
{
	HookEvent("arena_round_start", event_round_end);
}

public Action:event_round_end(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (FF2_HasAbility(0,this_plugin_name,"rage_servercommand"))
	{
		new rageCommandMode=FF2_GetAbilityArgument(0,this_plugin_name,"rage_servercommand",7);
		new Boss=GetClientOfUserId(FF2_GetBossUserId(0));
		new a_index=FF2_GetBossIndex(Boss);
		decl String:rageEndCommand[512];
		FF2_GetAbilityArgumentString(a_index,this_plugin_name,"rage_servercommand",5,rageEndCommand,PLATFORM_MAX_PATH);
		decl String:rageEndCommandParameters[512];
		FF2_GetAbilityArgumentString(a_index,this_plugin_name,"rage_servercommand",6,rageEndCommandParameters,PLATFORM_MAX_PATH);
		
		if (rageCommandMode == 0) {
			decl i;
			for( i = 1; i <= MaxClients; i++ )
			{
				if(IsClientInGame(i) && IsPlayerAlive(i))
				{
					ServerCommand("%s #%i %s",rageEndCommand,GetClientUserId(i),rageEndCommandParameters);
				}	
			}
		}
		else if (rageCommandMode == 1)
		{
			ServerCommand("%s %s",rageEndCommand,rageEndCommandParameters);
		}
	}
	return Plugin_Continue;
}


public Action:FF2_OnAbility2(index,const String:plugin_name[],const String:ability_name[],action)
{
	if (!strcmp(ability_name,"rage_servercommand"))		//Execute a server command
		Rage_ServerCommand(ability_name,index);
	return Plugin_Continue;
}


Rage_ServerCommand(const String:ability_name[],index)
{
	new Boss=GetClientOfUserId(FF2_GetBossUserId(index));
	new rageDistance=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 1);	//rage distance
	new rageDuration=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 2);	//rage duration
	new String:rageStartCommand[512];
	FF2_GetAbilityArgumentString(index,this_plugin_name,ability_name,3,rageStartCommand,512); //rage start command
	new String:rageStartCommandParameters[512];
	FF2_GetAbilityArgumentString(index,this_plugin_name,ability_name,4,rageStartCommandParameters,512); //rage start command parameters
	new rageCommandMode=FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 7);	//rage command mode
	
	decl Float:pos[3];
	decl Float:pos2[3];
	decl Float:distance;
	decl i;

	new Float:vel[3];
	vel[2]=20.0;
		
	TeleportEntity( Boss,  NULL_VECTOR, NULL_VECTOR, vel );
	GetEntPropVector( Boss, Prop_Send, "m_vecOrigin", pos );
	
	if (rageCommandMode == 0)
	{
		for( i = 1; i <= MaxClients; i++ )
		{
			if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i)!=BossTeam)
			{
				GetEntPropVector(i, Prop_Send, "m_vecOrigin", pos2);
				distance = GetVectorDistance( pos, pos2 );
				if ( distance < rageDistance )
				{
					ServerCommand("%s #%i %s",rageStartCommand,GetClientUserId(i),rageStartCommandParameters);
					if (rageDuration) {
						commandTimers[i] = CreateTimer(float(rageDuration), EndCommand_Timer, i);
					}
				}
			}	
		}
	} 
	else if (rageCommandMode == 1)
	{
		ServerCommand("%s",rageStartCommand);
		CreateTimer(float(rageDuration), EndCommandGlobal);		
	}
	else if (rageCommandMode == 2)
	{
		ServerCommand("%s #%i %s",rageStartCommand,GetClientUserId(Boss),rageStartCommandParameters);
		if (rageDuration) {
			commandTimers[i] = CreateTimer(float(rageDuration), EndCommand_Timer, Boss);
		}
	}
	else if (rageCommandMode == 3)
	{
		FakeClientCommand(Boss,"%s %s",rageStartCommand,rageStartCommandParameters);
		if (rageDuration) {
			commandTimers[i] = CreateTimer(float(rageDuration), EndCommandBoss_Timer, Boss);
		}
	}
}


public Action:EndCommandGlobal(Handle:timer)
{
	new Boss=GetClientOfUserId(FF2_GetBossUserId(0));
	new a_index=FF2_GetBossIndex(Boss);
	decl String:rageEndCommand[512];
	FF2_GetAbilityArgumentString(a_index,this_plugin_name,"rage_servercommand",5,rageEndCommand,PLATFORM_MAX_PATH);
	decl String:rageEndCommandParameters[512];
	FF2_GetAbilityArgumentString(a_index,this_plugin_name,"rage_servercommand",6,rageEndCommandParameters,PLATFORM_MAX_PATH);
	ServerCommand("%s %s",rageEndCommand,rageEndCommandParameters);
}


public Action:EndCommandBoss_Timer(Handle:timer, any:client)
{
	if ( !IsClientInGame( client ) )
	{
		commandTimers[ client ] = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	new a_index=FF2_GetBossIndex(client);
	decl String:rageEndCommand[512];
	FF2_GetAbilityArgumentString(a_index,this_plugin_name,"rage_servercommand",5,rageEndCommand,PLATFORM_MAX_PATH);
	decl String:rageEndCommandParameters[512];
	FF2_GetAbilityArgumentString(a_index,this_plugin_name,"rage_servercommand",6,rageEndCommandParameters,PLATFORM_MAX_PATH);
	FakeClientCommand(GetClientUserId(client),"%s %s",rageEndCommand,rageEndCommandParameters);
	return Plugin_Handled;
}



public Action:EndCommand_Timer(Handle:timer, any:client)
{
	new Boss=GetClientOfUserId(FF2_GetBossUserId(0));
	new a_index=FF2_GetBossIndex(Boss);

	if ( !IsClientInGame( client ) )
	{
		commandTimers[ client ] = INVALID_HANDLE;
		return Plugin_Stop;
	}

	decl String:rageEndCommand[512];
	FF2_GetAbilityArgumentString(a_index,this_plugin_name,"rage_servercommand",5,rageEndCommand,PLATFORM_MAX_PATH);
	decl String:rageEndCommandParameters[512];
	FF2_GetAbilityArgumentString(a_index,this_plugin_name,"rage_servercommand",6,rageEndCommandParameters,PLATFORM_MAX_PATH);
	ServerCommand("%s #%i %s",rageEndCommand,GetClientUserId(client),rageEndCommandParameters);
	return Plugin_Handled;

}