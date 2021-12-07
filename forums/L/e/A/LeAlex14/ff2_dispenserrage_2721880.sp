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

new Boss;
new heal;
new Float:timeduration;
new Float:damages;
new Float:radiuss;
new Float:Bombwait;
new r1;
new g1;
new b1;
new r2;
new g2;
new b2;
new Float:dist2;
new Float:dist3;
new spawnflag;
new effect1 = 0;
new effect2 = 0;
new Float:totduration = 0.0;


public Plugin:myinfo = {
   name = "Freak Fortress 2: Dispenser",
   author = "LeAlex14",		
   description = "You can spawn dispenser with any level, any type, you can summon bombspenser and totemspenser",
   version = "0.5" 
}


public OnPluginStart2()
{
}

public Action:Healdisp(Handle timer, disp) // If normal sentry, she has a animation and reset her health, because animation set to normal sentry heal
{
	SetVariantInt(heal);
	AcceptEntityInput(disp, "SetHealth");

}

public Action:FF2_OnAbility2(index,const String:plugin_name[],const String:ability_name[],action)
{
	
	if (!strcmp(ability_name, "Dispenser_S"))
		Rage_dispenser(ability_name, index);
	
	if (!strcmp(ability_name, "Bombspenser"))
		Rage_Bombdispenser(ability_name, index);
		
	if (!strcmp(ability_name, "Totemspenser"))
		Rage_totempenser(ability_name, index);
}

public Action:Destroydisp(Handle timer, disp)
{
	if (IsValidEntity(disp) == true)
	{
		AcceptEntityInput(disp, "Kill");
	}

}

public Action:Setupbomb(Handle timer, disp)
{
	if (IsValidEntity(disp) == true)
	{
		SetVariantInt(heal);
		AcceptEntityInput(disp, "RemoveHealth");
		float vecOrigin[3];
		GetEntPropVector(disp, Prop_Data, "m_vecOrigin", vecOrigin);
		int iBomb = CreateEntityByName("tf_generic_bomb");
		DispatchKeyValueVector(iBomb, "origin", vecOrigin);
		DispatchKeyValueFloat(iBomb, "damage", damages);
		DispatchKeyValueFloat(iBomb, "radius", radiuss);
		DispatchKeyValue(iBomb, "health", "1");
		
		DispatchSpawn(iBomb);
		SDKHooks_TakeDamage(iBomb, Boss, Boss, 5.0);
		AcceptEntityInput(iBomb, "Detonate");
		AcceptEntityInput(iBomb, "Kill");
	}
	
	

}

public Action:ChangedispC1(Handle timer, disp)
{
	Bombwait=Bombwait/2.2;
	if (IsValidEntity(disp) == true)
	{
		SetEntityRenderColor(disp, r1, g1, b1, 192);
		CreateTimer(Bombwait, ChangedispC2, disp, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:ChangedispC2(Handle timer, disp)
{
	Bombwait=Bombwait/2.2;
	if (IsValidEntity(disp) == true)
	{
		SetEntityRenderColor(disp, r2, g2, b2, 192);
		CreateTimer(Bombwait, ChangedispC1, disp, TIMER_FLAG_NO_MAPCHANGE);
		
	}
}

public Action:totemcondm(Handle timer, disp)
{
	new Float:pos[3], Float:pos2[3], Float:dista;
	if (IsValidEntity(disp) == true)
	{
		GetEntPropVector(disp, Prop_Send, "m_vecOrigin", pos);
		for(new target=1; target<=MaxClients; target++)
		{
			if(IsValidClient(target) && IsPlayerAlive(target) && GetClientTeam(target)!= GetClientTeam(Boss))
			{
				GetEntPropVector(target, Prop_Send, "m_vecOrigin", pos2);
				dista=GetVectorDistance(pos,pos2);
				if (dista<dist2 && GetClientTeam(target)!=GetClientTeam(Boss))
				{
					switch(effect1)
					{
						case 0:
							dist2=0.0;
						case 1: 
							TF2_MakeBleed(target, Boss, 0.55);
						case 2:
							TF2_AddCondition(target, TFCond_RestrictToMelee, 0.6);
						case 3:
							TF2_AddCondition(target, TFCond_MarkedForDeath, 0.6);
						case 4:
							TF2_AddCondition(target, TFCond_Milked, 0.6);
						case 5:
							TF2_AddCondition(target, TFCond_Jarated, 0.6);
						case 6:
							TF2_StunPlayer(target, 0.55, 0.0, TF_STUNFLAG_BONKSTUCK, Boss);
						case 7:
							TF2_RemoveCondition(target, TFCond_Cloaked);
						case 8:
							TF2_RemoveCondition(target, TFCond_Disguised);
						case 9:
							TF2_AddCondition(target, TFCond_Dazed, 0.6);
						case 10:
							SetEntProp(target, Prop_Send, "m_bGlowEnabled", 1);
						case 11:
							TF2_IgnitePlayer(target, Boss);
					}
				
				}
			}
		}
		
		switch(effect1)
		{
			case 0:
				dist2=0.0;
			case 1: 
				CreateTimer(0.5, totemcondm, disp, TIMER_FLAG_NO_MAPCHANGE);
			case 2:
				CreateTimer(0.5, totemcondm, disp, TIMER_FLAG_NO_MAPCHANGE);
			case 3:
				CreateTimer(0.5, totemcondm, disp, TIMER_FLAG_NO_MAPCHANGE);
			case 4:
				CreateTimer(0.5, totemcondm, disp, TIMER_FLAG_NO_MAPCHANGE);
			case 5:
				CreateTimer(0.5, totemcondm, disp, TIMER_FLAG_NO_MAPCHANGE);
			case 6:
				CreateTimer(1.5, totemcondm, disp, TIMER_FLAG_NO_MAPCHANGE);
			case 7:
				CreateTimer(0.5, totemcondm, disp, TIMER_FLAG_NO_MAPCHANGE);
			case 8:
				CreateTimer(0.5, totemcondm, disp, TIMER_FLAG_NO_MAPCHANGE);
			case 9:
				CreateTimer(0.5, totemcondm, disp, TIMER_FLAG_NO_MAPCHANGE);
			case 10:
				CreateTimer(0.5, totemcondm, disp, TIMER_FLAG_NO_MAPCHANGE);
			case 11:
				CreateTimer(0.5, totemcondm, disp, TIMER_FLAG_NO_MAPCHANGE);
				
		}
	}
	else
	{
		for(new ni=1; ni<=MaxClients; ni++)
		{
			if(IsValidClient(ni) && IsPlayerAlive(ni) && GetClientTeam(ni)!= GetClientTeam(Boss))
			{
				
				SetEntProp(ni, Prop_Send, "m_bGlowEnabled", 0);
				
			}
		}
	}
}

public Action:totemcondb(Handle timer, disp)
{
	new Float:pos[3], Float:pos2[3], Float:dist;
	if (IsValidEntity(disp) == true)
	{
		GetEntPropVector(disp, Prop_Send, "m_vecOrigin", pos);
		for(new target=1; target<=MaxClients; target++)
		{
			if(IsValidClient(target) && IsPlayerAlive(target) && GetClientTeam(target)== GetClientTeam(Boss))
			{
				GetEntPropVector(target, Prop_Send, "m_vecOrigin", pos2);
				dist=GetVectorDistance(pos,pos2);
				if (dist<dist3 && GetClientTeam(target)==GetClientTeam(Boss))
				{
					switch(effect2)
					{
						case 0:
							dist3=0.0;
						case 1: 
							TF2_AddCondition(target, TFCond_MegaHeal, totduration),
							TF2_AddCondition(target, TFCond_UberchargedOnTakeDamage, totduration),
							TF2_AddCondition(target, TFCond_UberBulletResist, totduration),
							TF2_AddCondition(target, TFCond_UberBlastResist, totduration),
							TF2_AddCondition(target, TFCond_UberFireResist, totduration),
							TF2_AddCondition(target, TFCond_HalloweenCritCandy, totduration);
						case 2:
							TF2_AddCondition(target, TFCond_DefenseBuffed, totduration),
							TF2_AddCondition(target, TFCond_RegenBuffed, totduration),
							TF2_AddCondition(target, TFCond_Buffed, totduration);
						case 3:
							TF2_AddCondition(target, TFCond_HalloweenCritCandy, totduration);
						case 4:
							TF2_AddCondition(target, TFCond_Bonked, totduration);
						case 5:
							TF2_AddCondition(target, TFCond_SpeedBuffAlly, totduration);
					}
				}
			}
		}
		
		switch(effect2)
		{
			case 0:
				dist3=0.0;
			case 1: 
				CreateTimer(0.5, totemcondb, disp, TIMER_FLAG_NO_MAPCHANGE);
			case 2:
				CreateTimer(0.5, totemcondb, disp, TIMER_FLAG_NO_MAPCHANGE);
			case 3:
				CreateTimer(0.5, totemcondb, disp, TIMER_FLAG_NO_MAPCHANGE);
			case 4:
				CreateTimer(0.5, totemcondb, disp, TIMER_FLAG_NO_MAPCHANGE);
			case 6:
				CreateTimer(0.5, totemcondb, disp, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}


public Action:Rage_dispenser(const String:ability_name[], index)
{
	Boss = GetClientOfUserId(FF2_GetBossUserId(index));
	new level = FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 1, 2); 
	heal = FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 2, 450); 
	timeduration = FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name, 3, 0.0);
	spawnflag = FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 4, 0);
	
	new Float:flAng[3];
	GetClientEyeAngles(Boss, flAng);
	
	
	if(!SetTeleportEndPoint(Boss))
	{
		PrintToChat(Boss, "[SM] Could not find spawn point.");
		return;
	}
	
	g_pos[2] -= 10.0;
	flAng[0] = 0.0;
	
	SpawnDispenser(Boss, g_pos, flAng, level);
}


public Action:Rage_Bombdispenser(const String:ability_name[], index)
{
	Boss = GetClientOfUserId(FF2_GetBossUserId(index));
	Bombwait = FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name, 1, 2.0); 
	heal = FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 2, 450); 
	radiuss = FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name, 3, 0.0);
	damages = FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name, 4, 100.0);
	r1 = FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 5, 250); 
	g1 = FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 6, 0); 
	b1 = FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 7, 0); 
	r2 = FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 8, 0); 
	g2 = FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 9, 0); 
	b2 = FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 10, 250); 
	
	new Float:flAng[3];
	GetClientEyeAngles(Boss, flAng);
	
	if(!SetTeleportEndPoint(Boss))
	{
		PrintToChat(Boss, "[SM] Could not find spawn point.");
		return;
	}
	
	g_pos[2] -= 10.0;
	flAng[0] = 0.0;
	
	SpawnDispenserBomb(Boss, g_pos, flAng);
	
}

public Action:Rage_totempenser(const String:ability_name[], index)
{
	Boss = GetClientOfUserId(FF2_GetBossUserId(index));
	effect1 = FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 1, 0);
	effect2 = FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 2, 0);
	dist2 = FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name, 3, 200.0); 
	dist3 = FF2_GetAbilityArgumentFloat(Boss, this_plugin_name, ability_name, 4, 100.0);
	totduration = FF2_GetAbilityArgumentFloat(Boss, this_plugin_name, ability_name, 5, 10.0);
	heal = FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 6, 450); 
	timeduration = FF2_GetAbilityArgumentFloat(index,this_plugin_name,ability_name, 7, 0.0);	
	spawnflag = FF2_GetAbilityArgument(index,this_plugin_name,ability_name, 8, 0);
	
	new Float:flAng[3];
	GetClientEyeAngles(Boss, flAng);
	
	
	if(!SetTeleportEndPoint(Boss))
	{
		PrintToChat(Boss, "[SM] Could not find spawn point.");
		return;
	}
	
	g_pos[2] -= 10.0;
	flAng[0] = 0.0;
	
	SpawnTotempenser(Boss, g_pos, flAng);
}



stock SpawnDispenser(int builder, float Position[3], float Angle[3], int level)
{


	int dispenser = CreateEntityByName("obj_dispenser");
	if(!IsValidEntity(dispenser)) return 0;

	int iTeam = GetClientTeam(builder);

	DispatchKeyValueVector(dispenser, "origin", Position);
	DispatchKeyValueVector(dispenser, "angles", Angle);
	SetEntProp(dispenser, Prop_Send, "m_iHighestUpgradeLevel", level);
	SetEntProp(dispenser, Prop_Data, "m_spawnflags", spawnflag);
	SetEntProp(dispenser, Prop_Send, "m_bBuilding", 1);
	DispatchSpawn(dispenser);

	SetVariantInt(iTeam);
	AcceptEntityInput(dispenser, "SetTeam");
	SetEntProp(dispenser, Prop_Send, "m_nSkin", iTeam -2);

	ActivateEntity(dispenser);
	SetEntPropEnt(dispenser, Prop_Send, "m_hBuilder", builder);
	
	SetVariantInt(heal);
	AcceptEntityInput(dispenser, "SetHealth");
	
	if (2 <= level)
	{
		CreateTimer(1.0, Healdisp, dispenser, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	if (3 == level)
	{
		CreateTimer(2.0, Healdisp, dispenser, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	if (1 <= timeduration)
	{
		CreateTimer(timeduration, Destroydisp, dispenser, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	return dispenser;

}

stock SpawnTotempenser(int builder, float Position[3], float Angle[3])
{


	int dispenser = CreateEntityByName("obj_dispenser");
	if(!IsValidEntity(dispenser)) return 0;

	int iTeam = GetClientTeam(builder);

	DispatchKeyValueVector(dispenser, "origin", Position);
	DispatchKeyValueVector(dispenser, "angles", Angle);
	SetEntProp(dispenser, Prop_Send, "m_iHighestUpgradeLevel", 1);
	SetEntProp(dispenser, Prop_Data, "m_spawnflags", spawnflag);
	SetEntProp(dispenser, Prop_Send, "m_bBuilding", 1);
	DispatchSpawn(dispenser);

	SetVariantInt(iTeam);
	AcceptEntityInput(dispenser, "SetTeam");
	SetEntProp(dispenser, Prop_Send, "m_nSkin", iTeam -2);

	ActivateEntity(dispenser);
	SetEntPropEnt(dispenser, Prop_Send, "m_hBuilder", builder);
	
	SetVariantInt(heal);
	AcceptEntityInput(dispenser, "SetHealth");
	
	if (1 <= timeduration)
	{
		CreateTimer(timeduration, Destroydisp, dispenser, TIMER_FLAG_NO_MAPCHANGE);
	}
	CreateTimer(0.1, totemcondm, dispenser, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.1, totemcondb, dispenser, TIMER_FLAG_NO_MAPCHANGE);
	
	return dispenser;

}

stock SpawnDispenserBomb(int builder, float Position[3], float Angle[3])
{


	int dispenser = CreateEntityByName("obj_dispenser");
	if(!IsValidEntity(dispenser)) return 0;

	int iTeam = GetClientTeam(builder);

	DispatchKeyValueVector(dispenser, "origin", Position);
	DispatchKeyValueVector(dispenser, "angles", Angle);
	SetEntProp(dispenser, Prop_Send, "m_iHighestUpgradeLevel", 1);
	SetEntProp(dispenser, Prop_Send, "m_bBuilding", 1);
	DispatchSpawn(dispenser);

	SetVariantInt(iTeam);
	AcceptEntityInput(dispenser, "SetTeam");
	SetEntProp(dispenser, Prop_Send, "m_nSkin", iTeam -2);

	ActivateEntity(dispenser);
	SetEntPropEnt(dispenser, Prop_Send, "m_hBuilder", builder);
	
	SetVariantInt(heal);
	AcceptEntityInput(dispenser, "SetHealth");
	
	AcceptEntityInput(dispenser, "Disable");
	
	CreateTimer(Bombwait, Setupbomb, dispenser, TIMER_FLAG_NO_MAPCHANGE);
	Bombwait=Bombwait/2;
	CreateTimer(Bombwait, ChangedispC1, dispenser, TIMER_FLAG_NO_MAPCHANGE);

	
	return dispenser;

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
