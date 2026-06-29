#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.0.1" 
 
 
new Handle:l4d_shovepush_enable ;  
new Handle:l4d_shovepush_force ; 
new GameMode;
new L4D2Version;
 

public Plugin:myinfo = 
{
	name = "shove anything",
	author = "Pan Xiaohai",
	description = " ",
	version = PLUGIN_VERSION,	
}

public OnPluginStart()
{
	GameCheck(); 	
 	l4d_shovepush_enable = CreateConVar("l4d_shovepush_enable", "1", " shove push 0:disable, 1:eanble ", FCVAR_PLUGIN);
  	l4d_shovepush_force  =	 CreateConVar("l4d_shovepush_force", "1000.0", "push force", FCVAR_PLUGIN);
 	 
	if(GameMode!=2)
	{ 
		HookEvent("entity_shoved", entity_shoved); 	
	}
	AutoExecConfig(true, "l4d_shove_push");
}
 
GameCheck()
{
	decl String:GameName[16];
	GetConVarString(FindConVar("mp_gamemode"), GameName, sizeof(GameName));
	
	
	if (StrEqual(GameName, "survival", false))
		GameMode = 3;
	else if (StrEqual(GameName, "versus", false) || StrEqual(GameName, "teamversus", false) || StrEqual(GameName, "scavenge", false) || StrEqual(GameName, "teamscavenge", false))
		GameMode = 2;
	else if (StrEqual(GameName, "coop", false) || StrEqual(GameName, "realism", false))
		GameMode = 1;
	else
	{
		GameMode = 0;
 	}
	
 
	GetGameFolderName(GameName, sizeof(GameName));
	if (StrEqual(GameName, "left4dead2", false))
	{
 
		L4D2Version=true;
	}	
	else
	{
 
		L4D2Version=false;
	}
	L4D2Version=!!L4D2Version;
}
 
public Action:entity_shoved(Handle:event, String:event_name[], bool:dontBroadcast)
{
	if(GetConVarInt(l4d_shovepush_enable)==0) return Plugin_Continue; 	 
	new attacker  = GetClientOfUserId(GetEventInt(event, "attacker"));
	new button=GetClientButtons(attacker);
	
	if((button & IN_USE) || (button & IN_DUCK) || (button & IN_SPEED))
	{
		new ent=GetEnt(attacker);
		if(ent>0)
		{
			ThrowEnt(attacker, ent, GetConVarFloat(l4d_shovepush_force));
			PushBack(attacker, ent);
			//PrintToChatAll ( " %N shove %d", attacker,  ent);
		}	 
	}
   	return Plugin_Continue;
}
ThrowEnt(client, ent, Float:force)
{	
	//PrintToChat(client, "throw");
	decl Float:vAngles[3];
	decl Float:vOrigin[3];
	decl Float:pos[3];
	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos); 
 
	decl Float:volicity[3];
	SubtractVectors(pos, vOrigin, volicity);
	NormalizeVector(volicity, volicity);
	ScaleVector(volicity, force);
	TeleportEntity(ent, NULL_VECTOR, NULL_VECTOR, volicity);
	
	decl String:classname[64];
	GetEdictClassname(ent, classname, 64);		
	if(StrContains(classname, "prop_")!=-1)
	{
		SetEntPropEnt(ent, Prop_Data, "m_hPhysicsAttacker", client);
		SetEntPropFloat(ent, Prop_Data, "m_flLastPhysicsInfluenceTime", GetEngineTime());
	}
}
PushBack(attacker, ent)
{
	decl Float:victimpos[3];
	decl Float:attackerpos[3];
	decl Float:v[3];
	decl Float:ang[3];
	GetClientAbsOrigin(attacker, attackerpos);
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", victimpos); 
	SubtractVectors(victimpos, attackerpos, ang);
	GetVectorAngles(ang, ang); 
	
	new flag=GetEntityFlags(attacker);  //FL_ONGROUND
	
	if(flag & FL_ONGROUND )
	{
		ang[0]=GetRandomFloat(2.0, 6.0);
		
	}
	else 
	{
		ang[0]=0.0-GetRandomFloat(10.0, 15.0);
	}
	ang[2]=0.0;
	
	GetAngleVectors(ang, v, NULL_VECTOR,NULL_VECTOR);	
	NormalizeVector(v,v);
	ScaleVector(v, 0.0-340.0);

	attackerpos[2]+=10.0;
	TeleportEntity(attacker, attackerpos, NULL_VECTOR, v); 
}
GetEnt(client)
{
	new ent=0;
	
	decl Float:vAngles[3];
	decl Float:vOrigin[3];
	decl Float:pos[3];

	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);

	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SOLID, RayType_Infinite, TraceRayDontHitSelf, client);

	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(pos, trace);
		ent=TR_GetEntityIndex(trace);
		if(ent>0)
		{
		 
			decl String:classname[64];
			GetEdictClassname(ent, classname, 64);	

			if(StrContains(classname, "ladder")!=-1){ent=0;}
			else if(StrContains(classname, "door")!=-1){ent=0;}
			else if(StrContains(classname, "infected")!=-1){ent=0;}
			else 
			{			 
				/*
				if(StrContains(classname, "prop_")!=-1)
				{
					PrintToChatAll("You push a prop"); 
				}
				if(StrContains(classname, "car")!=-1)
				{
					 
					 
					PrintToChatAll("You push a car");
				}
				if(StrContains(classname, "weapon_")!=-1)
				{
				 
				 
					PrintToChatAll("You push a weapon");
				}
				if(StrContains(classname, "player")!=-1)
				{
					
					PrintToChatAll("You push a player");
				}
				*/
				if(ent<=MaxClients)	
				{						 
					PrintHintText(client, "You can not push a player");
					ent=0;						 
				}				 
				
			}
			  
		}
		else
		{
			//PrintHintText(client, "You push nothing!");
		}
	}
	CloseHandle(trace);	
	return ent;
}
public bool:TraceRayDontHitSelf(entity, mask, any:data)
{
	if(entity == data) 
	{
		return false; 
	}
	return true;
}