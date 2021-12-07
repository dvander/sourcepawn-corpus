#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <tf2>
#include <sdkhooks>
#include <sdktools>
#include <sdktools_functions>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

new Float:g_pos[3];
new Float:ReplaceO[3];
new Float:ReplaceA[3];
new heal = 0;
new healhat = 0;

new Boss;


public Plugin:myinfo = {
   name = "Freak Fortress 2: Many sentry possibility",
   author = "LeAlex14",		
   description = "You can spawn sentry and have a freaking sentry on your head, any level, any type",
   version = "0.75.1" // Number of tries for make hat sentry... Yes, I'm crazy
}


public OnPluginStart2()
{
}

public Action:FF2_OnAbility2(index,const String:plugin_name[],const String:ability_name[],action)
{
	
	if (!strcmp(ability_name, "Spawn_sentry"))
		Rage_sentry(ability_name, index);
	
	if (!strcmp(ability_name, "teletrap"))
		teletraps(ability_name, index);
		
	if (!strcmp(ability_name, "sentryhat"))
		Rage_sentryhat(ability_name, index);
		
}


public Action:Healsentry(Handle timer, sentry) // If normal sentry, she has a animation and reset her health, because animation set to normal sentry heal
{
	SetVariantInt(heal);
	AcceptEntityInput(sentry, "SetHealth");

}

public Action:Healsentryhat(Handle timer, sentry) // If normal sentry, she has a animation and reset her health, because animation set to normal sentry heal
{
	SetVariantInt(healhat);
	AcceptEntityInput(sentry, "SetHealth");

}

public Action:Destroysentry(Handle timer, sentry)
{
	if (IsValidEntity(sentry) == true)
	{
		AcceptEntityInput(sentry, "Kill");
	}

}

public Action:Replace_sentry(Handle timer, sentry)
{	
	if (IsValidEntity(sentry) == true)
	{
		GetClientAbsAngles(Boss, ReplaceA);
		GetClientAbsOrigin(Boss, ReplaceO);
		ReplaceO[2] += 50;
		TeleportEntity(sentry, ReplaceO, ReplaceA, NULL_VECTOR);
		CreateTimer(0.05, Replace_sentry, sentry, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:Sentryhattimer(Handle timer, sentry)
{
	if (IsValidEntity(sentry) == true)
	{
		AcceptEntityInput(sentry, "Kill");
	}
}


public Action:Rage_sentry(const String:ability_name[], index)
{
	Boss = GetClientOfUserId(FF2_GetBossUserId(index));
	new level = FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 1, 2);   
	new typesentry = FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 5, 1);
	new random = FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 6, 0);
	
	new Float:flAng[3];
	GetClientEyeAngles(Boss, flAng);
	
	g_pos[2] -= 10.0;
	flAng[0] = 0.0;
	
	if(!SetTeleportEndPoint(Boss))
	{
		PrintToChat(Boss, "[SM] Could not find spawn point.");
		return;
	}
	
	if (random == 1)
	{
		typesentry = GetRandomInt(1 ,3);
		level = GetRandomInt(1 ,3);
	}
	
	if (random == 2)
	{
		level = GetRandomInt(1 ,3);
	}
	
	if (random == 3)
	{
		typesentry = GetRandomInt(1 ,3);
	}
	
	
	if (typesentry == 1)
	{
		SpawnSentry(Boss, g_pos, flAng, level, false);
	}
	
	if (typesentry == 2)
	{
		SpawnSentry(Boss, g_pos, flAng, level, true);
	}
	
	if (typesentry == 3)
	{
		SpawnSentry(Boss, g_pos, flAng, level, false, true);
	}
}

public Action:Rage_sentryhat(const String:ability_name[], index)
{
	Boss = GetClientOfUserId(FF2_GetBossUserId(index));
	new levelhat = FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 1, 2);   
	new typesentryhat = FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 5, 1);
	new randomhat = FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 6, 0);
	
	new Float:flAng[3];
	GetClientEyeAngles(Boss, flAng);
	
	g_pos[2] -= 10.0;
	flAng[0] = 0.0;
	
	if(!SetTeleportEndPoint(Boss))
	{
		PrintToChat(Boss, "[SM] Could not find spawn point.");
		return;
	}
	
	if (randomhat == 1)
	{
		typesentryhat = GetRandomInt(1 ,3);
		levelhat = GetRandomInt(1 ,3);
	}
	
	if (randomhat == 2)
	{
		levelhat = GetRandomInt(1 ,3);
	}
	
	if (randomhat == 3)
	{
		typesentryhat = GetRandomInt(1 ,3);
	}
	
	
	g_pos[2] -= 10.0;
	flAng[0] = 0.0;
	
	
	if (typesentryhat == 1)
	{
		SpawnSentryhat(Boss, g_pos, flAng, levelhat, false);
	}
	
	if (typesentryhat == 2)
	{
		SpawnSentryhat(Boss, g_pos, flAng, levelhat, true);
	}
	
	if (typesentryhat == 3)
	{
		SpawnSentryhat(Boss, g_pos, flAng, levelhat, false, true);
	}
}



stock SpawnSentry(builder, Float:Position[3], Float:Angle[3], level, bool:mini=false, bool:disposable=false, bool:carried=false, flags=4)
{
	static const Float:m_vecMinsMini[3] = {-15.0, -15.0, 0.0}, Float:m_vecMaxsMini[3] = {15.0, 15.0, 49.5};
	static const Float:m_vecMinsDisp[3] = {-13.0, -13.0, 0.0}, Float:m_vecMaxsDisp[3] = {13.0, 13.0, 42.9};
	
	new spawnflag = FF2_GetAbilityArgument(builder,this_plugin_name,"Spawn_sentry", 3, 8); 
	new Float:timeduration = FF2_GetAbilityArgumentFloat(builder,this_plugin_name,"Spawn_sentry", 4, 0.0); 
	new randomheal = FF2_GetAbilityArgument(builder,this_plugin_name,"Spawn_sentry", 7, 0);
	new physiccs = FF2_GetAbilityArgument(builder,this_plugin_name,"Spawn_sentry", 10, 0);
	new sentry = CreateEntityByName("obj_sentrygun");
	
	if (randomheal == 0)
	{
		heal = FF2_GetAbilityArgument(builder,this_plugin_name,"Spawn_sentry", 2, 1000);  
	}
    
	
	if (randomheal == 1)
	{
		new randomhealmax = FF2_GetAbilityArgument(builder,this_plugin_name,"Spawn_sentry", 9, 0);
		new randomhealmin = FF2_GetAbilityArgument(builder,this_plugin_name,"Spawn_sentry", 8, 0);
		heal = GetRandomInt(randomhealmin ,randomhealmax);
	}
	
	
	
	if(IsValidEntity(sentry))
	{
		AcceptEntityInput(sentry, "SetBuilder", builder);
		
		DispatchKeyValueVector(sentry, "origin", Position);
		DispatchKeyValueVector(sentry, "angles", Angle);
		
		if(mini)
		{
			SetEntProp(sentry, Prop_Send, "m_bMiniBuilding", 1);
			SetEntProp(sentry, Prop_Send, "m_iUpgradeLevel", level);
			SetEntProp(sentry, Prop_Send, "m_iHighestUpgradeLevel", level);
			SetEntProp(sentry, Prop_Data, "m_spawnflags", spawnflag);
			SetEntProp(sentry, Prop_Send, "m_bBuilding", 1);
			SetEntProp(sentry, Prop_Send, "m_nSkin", level == 1 ? GetClientTeam(builder) : GetClientTeam(builder) - 2);
			DispatchSpawn(sentry);
			
			SetVariantInt(physiccs);
			AcceptEntityInput(sentry, "SetSolidToPlayer");
			
			SetVariantInt(heal);
			AcceptEntityInput(sentry, "SetHealth");
			
			SetEntPropFloat(sentry, Prop_Send, "m_flModelScale", 0.75);
			SetEntPropVector(sentry, Prop_Send, "m_vecMins", m_vecMinsMini);
			SetEntPropVector(sentry, Prop_Send, "m_vecMaxs", m_vecMaxsMini);
			
			
			
			if (1 <= timeduration)
			{
				CreateTimer(timeduration, Destroysentry, sentry, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		else if(disposable)
		{
			SetEntProp(sentry, Prop_Send, "m_bMiniBuilding", 1);
			SetEntProp(sentry, Prop_Send, "m_bDisposableBuilding", 1);
			SetEntProp(sentry, Prop_Send, "m_iUpgradeLevel", level);
			SetEntProp(sentry, Prop_Send, "m_iHighestUpgradeLevel", level);
			SetEntProp(sentry, Prop_Data, "m_spawnflags", spawnflag);
			SetEntProp(sentry, Prop_Send, "m_bBuilding", 1);
			SetEntProp(sentry, Prop_Send, "m_nSkin", level == 1 ? GetClientTeam(builder) : GetClientTeam(builder) - 2);
			DispatchSpawn(sentry);
			
			SetVariantInt(heal);
			AcceptEntityInput(sentry, "SetHealth");
			
			SetVariantInt(physiccs);
			AcceptEntityInput(sentry, "SetSolidToPlayer");
			
			SetEntPropFloat(sentry, Prop_Send, "m_flModelScale", 0.60);
			SetEntPropVector(sentry, Prop_Send, "m_vecMins", m_vecMinsDisp);
			SetEntPropVector(sentry, Prop_Send, "m_vecMaxs", m_vecMaxsDisp);
			
			if (1 <= timeduration)
			{
				CreateTimer(timeduration, Destroysentry, sentry, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		else
		{
			SetEntProp(sentry, Prop_Send, "m_iUpgradeLevel", level);
			SetEntProp(sentry, Prop_Send, "m_iHighestUpgradeLevel", level);
			SetEntProp(sentry, Prop_Send, "m_iState", 2);
			SetEntProp(sentry, Prop_Data, "m_spawnflags", spawnflag);
			SetEntProp(sentry, Prop_Send, "m_bBuilding", 1);
			SetEntProp(sentry, Prop_Send, "m_nSkin", GetClientTeam(builder) - 2);
			
			DispatchSpawn(sentry);
			
			SetVariantInt(heal);
			AcceptEntityInput(sentry, "SetHealth");
			
			SetVariantInt(physiccs);
			AcceptEntityInput(sentry, "SetSolidToPlayer");
			
			if (2 <= level)
			{
				CreateTimer(1.0, Healsentry, sentry, TIMER_FLAG_NO_MAPCHANGE);
			}
			
			if (3 == level)
			{
				CreateTimer(2.0, Healsentry, sentry, TIMER_FLAG_NO_MAPCHANGE);
			}
			
			if (1 <= timeduration)
			{
				CreateTimer(timeduration, Destroysentry, sentry, TIMER_FLAG_NO_MAPCHANGE);
			}
			
			
			
		}
		
	}
}

stock SpawnSentryhat(builder, Float:Position[3], Float:Angle[3], level, bool:mini=false, bool:disposable=false, bool:carried=false, flags=4)
{
	static const Float:m_vecMinsMini[3] = {-15.0, -15.0, 0.0}, Float:m_vecMaxsMini[3] = {15.0, 15.0, 49.5};
	static const Float:m_vecMinsDisp[3] = {-13.0, -13.0, 0.0}, Float:m_vecMaxsDisp[3] = {13.0, 13.0, 42.9};
	
	new spawnflaghat = FF2_GetAbilityArgument(builder,this_plugin_name,"sentryhat", 3, 8); 
	new Float:hattimeduration = FF2_GetAbilityArgumentFloat(builder,this_plugin_name,"sentryhat", 4, 0.0); 
	new randomhealhat = FF2_GetAbilityArgument(builder,this_plugin_name,"sentryhat", 7, 0);
	new physiccs = FF2_GetAbilityArgument(builder,this_plugin_name,"Spawn_sentry", 10, 0);

	new sentry = CreateEntityByName("obj_sentrygun");
	
	if (randomhealhat == 0)
	{
		healhat = FF2_GetAbilityArgument(builder,this_plugin_name,"sentryhat", 2, 1000);  
	}
    
	
	if (randomhealhat == 1)
	{
		new randomhealmaxhat = FF2_GetAbilityArgument(builder,this_plugin_name,"sentryhat", 9, 0);
		new randomhealminhat = FF2_GetAbilityArgument(builder,this_plugin_name,"sentryhat", 8, 0);
		healhat = GetRandomInt(randomhealminhat ,randomhealmaxhat);
	}
	
	
	
	
	GetClientAbsAngles(builder, Angle);
	GetClientAbsOrigin(builder, Position);
	Position[2] += 100;

	
	if(IsValidEntity(sentry))
	{
		AcceptEntityInput(sentry, "SetBuilder", builder);
		
		DispatchKeyValueVector(sentry, "origin", Position);
		DispatchKeyValueVector(sentry, "angles", Angle);
		
		if(mini)
		{
			SetEntProp(sentry, Prop_Send, "m_bMiniBuilding", 1);
			SetEntProp(sentry, Prop_Send, "m_iUpgradeLevel", level);
			SetEntProp(sentry, Prop_Send, "m_iHighestUpgradeLevel", level);
			SetEntProp(sentry, Prop_Data, "m_spawnflags", spawnflaghat);
			SetEntProp(sentry, Prop_Send, "m_bBuilding", 1);
			SetEntProp(sentry, Prop_Send, "m_nSkin", level == 1 ? GetClientTeam(builder) : GetClientTeam(builder) - 2);
			DispatchSpawn(sentry);
			
			SetVariantInt(healhat);
			AcceptEntityInput(sentry, "SetHealth");
			
			SetVariantInt(physiccs);
			AcceptEntityInput(sentry, "SetSolidToPlayer");
			
			SetEntPropFloat(sentry, Prop_Send, "m_flModelScale", 0.75);
			SetEntPropVector(sentry, Prop_Send, "m_vecMins", m_vecMinsMini);
			SetEntPropVector(sentry, Prop_Send, "m_vecMaxs", m_vecMaxsMini);
			
		}
		else if(disposable)
		{
			SetEntProp(sentry, Prop_Send, "m_bMiniBuilding", 1);
			SetEntProp(sentry, Prop_Send, "m_bDisposableBuilding", 1);
			SetEntProp(sentry, Prop_Send, "m_iUpgradeLevel", level);
			SetEntProp(sentry, Prop_Send, "m_iHighestUpgradeLevel", level);
			SetEntProp(sentry, Prop_Data, "m_spawnflags", spawnflaghat);
			SetEntProp(sentry, Prop_Send, "m_bBuilding", 1);
			SetEntProp(sentry, Prop_Send, "m_nSkin", level == 1 ? GetClientTeam(builder) : GetClientTeam(builder) - 2);
			DispatchSpawn(sentry);
			
			SetVariantInt(healhat);
			AcceptEntityInput(sentry, "SetHealth");
			
			SetEntPropFloat(sentry, Prop_Send, "m_flModelScale", 0.60);
			SetEntPropVector(sentry, Prop_Send, "m_vecMins", m_vecMinsDisp);
			SetEntPropVector(sentry, Prop_Send, "m_vecMaxs", m_vecMaxsDisp);
			
			SetVariantInt(physiccs);
			AcceptEntityInput(sentry, "SetSolidToPlayer");
			
		}
		else
		{
			SetEntProp(sentry, Prop_Send, "m_iUpgradeLevel", level);
			SetEntProp(sentry, Prop_Send, "m_iHighestUpgradeLevel", level);
			SetEntProp(sentry, Prop_Send, "m_iState", 2);
			SetEntProp(sentry, Prop_Data, "m_spawnflags", spawnflaghat);
			SetEntProp(sentry, Prop_Send, "m_bBuilding", 1);
			SetEntProp(sentry, Prop_Send, "m_nSkin", GetClientTeam(builder) - 2);
			
			DispatchSpawn(sentry);
			
			SetVariantInt(healhat);
			AcceptEntityInput(sentry, "SetHealth");
			
			SetVariantInt(physiccs);
			AcceptEntityInput(sentry, "SetSolidToPlayer");
			
			if (2 <= level)
			{
				CreateTimer(1.0, Healsentryhat, sentry, TIMER_FLAG_NO_MAPCHANGE);
			}
			
			if (3 == level)
			{
				CreateTimer(2.0, Healsentryhat, sentry, TIMER_FLAG_NO_MAPCHANGE);
			}
			
		}
		
		
		CreateTimer(hattimeduration, Sentryhattimer, sentry, TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(0.05, Replace_sentry, sentry, TIMER_FLAG_NO_MAPCHANGE);
		
	}
}

public Action:teletraps(const String:ability_name[], index)
{
	Boss = GetClientOfUserId(FF2_GetBossUserId(index));
	new Float:flAng[3];
	SpawnTeleporter(Boss, g_pos, flAng, 1, TFObjectMode_Exit);
	
}

stock SpawnTeleporter(builder, Float:Position[3], Float:Angle[3], level, TFObjectMode:mode, flags=4)
{
	
	new teleheal = FF2_GetAbilityArgument(builder,this_plugin_name,"teletrap", 1, 500); 
	new Float:teleduration = FF2_GetAbilityArgumentFloat(builder,this_plugin_name,"teletrap", 2, 10.0); 
	new Float:Traprange = FF2_GetAbilityArgumentFloat(builder,this_plugin_name,"teletrap", 3, 2500.0); 
	new Notifyhud = FF2_GetAbilityArgument(builder,this_plugin_name,"teletrap", 4, 1); 
	
	decl Float:pos[3];
	decl Float:pos2[3];
	decl Float:distance;
	
	
	GetEntPropVector(builder, Prop_Send, "m_vecOrigin", pos);
	for(new i=1; i<=MaxClients; i++)
    {
        if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i)!=GetClientTeam(builder))
        {
            GetEntPropVector(i, Prop_Send, "m_vecOrigin", pos2);
            distance = GetVectorDistance( pos, pos2 );
            if (distance < Traprange && GetClientTeam(i)!=GetClientTeam(builder))
			{
				new teleporter = CreateEntityByName("obj_teleporter");
				GetClientAbsAngles(i, Angle);
				GetClientAbsOrigin(i, Position);
				Position[2] += 1;
				DispatchKeyValueVector(teleporter, "origin", Position);
				DispatchKeyValueVector(teleporter, "angles", Angle);
				
				SetEntProp(teleporter, Prop_Send, "m_iHighestUpgradeLevel", 1);
				SetEntProp(teleporter, Prop_Data, "m_spawnflags", flags);
				SetEntProp(teleporter, Prop_Send, "m_bBuilding", 1);
				SetEntProp(teleporter, Prop_Data, "m_iTeleportType", mode);
				SetEntProp(teleporter, Prop_Send, "m_iObjectMode", mode);
				SetEntProp(teleporter, Prop_Send, "m_nSkin", GetClientTeam(builder) - 2);
				DispatchSpawn(teleporter);
				
				AcceptEntityInput(teleporter, "SetBuilder", builder);
				
				SetVariantInt(GetClientTeam(builder));
				AcceptEntityInput(teleporter, "SetTeam");
				
				SetVariantInt(teleheal);
				AcceptEntityInput(teleporter, "SetHealth");
				
				CreateTimer(teleduration, Destroysentry, teleporter, TIMER_FLAG_NO_MAPCHANGE);
				
				if (Notifyhud == 1)
				{
					PrintCenterText(i, "You have been teletrapped !");
				}
				
            }
        }    
    }
	
}

SetTeleportEndPoint(client)
{
	decl Float:vAngles[3];
	decl Float:vOrigin[3];
	decl Float:vBuffer[3];
	decl Float:vStart[3];
	decl Float:Distance;
	
	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);
	
    //get endpoint for teleport
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);

	if(TR_DidHit(trace))
	{   	 
   	 	TR_GetEndPosition(vStart, trace);
		GetVectorDistance(vOrigin, vStart, false);
		Distance = -35.0;
   	 	GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
		g_pos[0] = vStart[0] + (vBuffer[0]*Distance);
		g_pos[1] = vStart[1] + (vBuffer[1]*Distance);
		g_pos[2] = vStart[2] + (vBuffer[2]*Distance);
	}
	else
	{
		CloseHandle(trace);
		return false;
	}
	
	CloseHandle(trace);
	return true;
}

public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return entity > MaxClients || !entity;
}

stock bool IsValidClient(int client, bool isPlayerAlive=false)
{
	if (client <= 0 || client > MaxClients) return false;
	if(isPlayerAlive) return IsClientInGame(client) && IsPlayerAlive(client);
	return IsClientInGame(client);
}
