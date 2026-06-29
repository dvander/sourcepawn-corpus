#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdktools_functions>
//#include <sdkhooks>


#define ZOMBIECLASS_SMOKER	1
#define ZOMBIECLASS_BOOMER	2
#define ZOMBIECLASS_HUNTER	3
#define ZOMBIECLASS_SPITTER	4
#define ZOMBIECLASS_JOCKEY	5
#define ZOMBIECLASS_CHARGER	6 
new ZOMBIECLASS_TANK=	5;
new GameMode;
new L4D2Version;
new g_sprite;
new Handle:SdkShove = INVALID_HANDLE;

new ShoveCount[MAXPLAYERS+1][MAXPLAYERS+1]; 

new Victim[MAXPLAYERS+1]; 
new Attacker[MAXPLAYERS+1];

new Float:ClientScanAngle[MAXPLAYERS+1];
new ClientClass[MAXPLAYERS+1];


new Float:UseDelay[MAXPLAYERS+1];
new Float:ClientButton[MAXPLAYERS+1];

 
#define EnemyArraySize 300
new InfectedsArray[EnemyArraySize];
new InfectedCount;
new Float:ScanTime=0.0;
new ScanIndex[MAXPLAYERS+1];
new ClientEnemy[MAXPLAYERS+1];


new Float:max_distance_of_control=1500.0;
new Float:max_distance_of_attack=1000.0;
new Float:max_distance_of_fellow=500.0;

new Handle:l4d_infected_attack_special_infected ;
new Handle:l4d_infected_attack_common_infected ;
new Handle:l4d_infected_attack_damage ;


new g_PointHurt = 0;
public Plugin:myinfo = 
{
	name = "survivor protector",
	author = " pan xiao hai",
	description = " ",
	version = "1.4",
	url = "http://forums.alliedmods.net"
}
public OnPluginStart()
{ 	 
	GameCheck(); 	
	
	if(GameMode==2)return;

	
	HookEvent("player_shoved", player_shoved); 	
	HookEvent("player_spawn", player_spawn);	
	HookEvent("player_death", player_death); 
	HookEvent("infected_hurt", infected_hurt); 
 
	HookEvent("player_hurt", player_hurt );	
	HookEvent("player_incapacitated_start", player_incapacitated_start);
	HookEvent("player_bot_replace", player_bot_replace );	  
	HookEvent("bot_player_replace", bot_player_replace );	
	
	HookEvent("round_start", round_end);
	HookEvent("round_end", round_end);
	HookEvent("finale_win", round_end);
	HookEvent("mission_lost", round_end);
	HookEvent("map_transition", round_end);	
	
	l4d_infected_attack_damage= CreateConVar("l4d_infected_attack_damage", "100", "damage", FCVAR_PLUGIN);
	l4d_infected_attack_special_infected = CreateConVar("l4d_infected_attack_special_infected", "1", "1 enable, 0 disable", FCVAR_PLUGIN);
	l4d_infected_attack_common_infected = CreateConVar("l4d_infected_attack_common_infected", "1", "1 enable, 0 disable", FCVAR_PLUGIN);	
	AutoExecConfig(true, "l4d_infected_control");  
	
	if(L4D2Version)
	{
	 
		StartPrepSDKCall(SDKCall_Player);
		if (!PrepSDKCall_SetSignature(SDKLibrary_Server, "\x81\xEC\x2A\x2A\x2A\x2A\x56\x8B\xF1\xE8\x2A\x2A\x2A\x2A\x84\xC0\x0F\x2A\x2A\x2A\x2A\x2A\x8B\x8C\x2A\x2A\x2A\x2A\x2A\x55\x33\xED\x3B\xCD\x74", 35))
		{
			PrepSDKCall_SetSignature(SDKLibrary_Server, "@_ZN13CTerrorPlayer18OnShovedBySurvivorEPS_RK6Vector", 0);
		} 
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		SdkShove = EndPrepSDKCall();
		if(SdkShove == INVALID_HANDLE)
		{
			PrintToServer("Unable to find the 'shove' signature");
		} 
	}
	else
	{
		StartPrepSDKCall(SDKCall_Player);
		if (!PrepSDKCall_SetSignature(SDKLibrary_Server, "\x81\xEC\x2A\x2A\x2A\x2A\x56\x8B\xF1\xE8\x2A\x2A\x2A\x2A\x84\xC0\x0F\x2A\x2A\x2A\x2A\x2A\x8B\x8C\x2A\x2A\x2A\x2A\x2A\x85\xC9\x74", 32))
		{
			PrepSDKCall_SetSignature(SDKLibrary_Server, "_ZN13CTerrorPlayer18OnShovedBySurvivorEPS_RK6Vector", 0);
		} 
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
		SdkShove = EndPrepSDKCall();
		if(SdkShove == INVALID_HANDLE)
		{
			PrintToServer("Unable to find the 'shove' signature");
		}  
	} 	
	
}
public OnMapStart()
{
	ResetAllState();

} 
public player_bot_replace(Handle:Spawn_Event, const String:Spawn_Name[], bool:Spawn_Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(Spawn_Event, "player"));
	new bot = GetClientOfUserId(GetEventInt(Spawn_Event, "bot"));   
	UnControl(client, 0);
	UnControl(bot, 0);

}
public bot_player_replace(Handle:Spawn_Event, const String:Spawn_Name[], bool:Spawn_Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(Spawn_Event, "player"));
	new bot = GetClientOfUserId(GetEventInt(Spawn_Event, "bot"));  
	UnControl(client, 0);
	UnControl(bot, 0);
  
}
public Action:player_spawn(Handle:hEvent, const String:strName[], bool:DontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));  
	ResetClientState(client);
	 	
}
public Action:ability_use(Handle:hEvent, const String:strName[], bool:DontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));  
 
	decl String:ability[64];
	GetEventString(hEvent, "ability", ability, 64);
 }
 

public Action:player_death(Handle:hEvent, const String:strName[], bool:DontBroadcast)
{

	new dead_player = GetClientOfUserId(GetEventInt(hEvent, "userid")); 
	
	if(dead_player>0)
	{
		if(GetClientTeam(dead_player)==3)
		{
			UnControl(0,dead_player);
		}
		if(GetClientTeam(dead_player)==2)
		{
			UnControl(dead_player , 0);
		} 
	
	}
	else 
	{
		dead_player= GetEventInt(hEvent, "entityid") ; 
	}

	if(dead_player>0)
	{
		new find_index=-1;
		for(new i=0; i<InfectedCount; i++)
		{
			if(InfectedsArray[i]==dead_player)
			{
				InfectedsArray[i]=InfectedsArray[InfectedCount-1];
				InfectedCount--;
				find_index=i;
				break;
			}
		}
		
		for(new i=1; i<=MaxClients; i++)
		{
			if(ClientEnemy[i]==dead_player) 
			{
				ClientEnemy[i]=0;
			}
			if(ScanIndex[i]>=find_index) 
			{
				if(ScanIndex[i]>0)ScanIndex[i]--;
			}		
		}
		
	} 
	
	
	
}
public Action:player_incapacitated_start(Handle:hEvent, const String:strName[], bool:DontBroadcast)
{ 
	return;
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(client>0)
	{
		if(Victim[client]>0)
		{
			
			UnControl(client, 0);
		}
		if(Attacker[client]>0)
		{
			
			UnControl(0, client);
		} 
		ResetClientState(client); 
	}
}
public Action:player_shoved(Handle:event, String:event_name[], bool:dontBroadcast)
{ 

	new victim  = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker  = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(attacker>0 && victim>0 && GetClientTeam(victim)==3)
	{
		
		if(Victim[attacker]>0 || Attacker[victim]>0)return;
		
	 	if( (GetClientButtons(attacker) & IN_USE))
		{ 
			new class = GetEntProp(victim, Prop_Send, "m_zombieClass"); 
			if(class==ZOMBIECLASS_TANK)return;
		
			ShoveCount[attacker][victim]++;  
			PushBack(attacker, victim);
			if(ShoveCount[attacker][victim]>=1)	Control(attacker, victim, class);
			
		}
	}
  	return  ;
}
PushBack(victim, attacker)
{
	decl Float:victimpos[3];
	decl Float:attackerpos[3];
	decl Float:dir[3]; 
	GetClientAbsOrigin(attacker, attackerpos);
	GetClientAbsOrigin(victim, victimpos);	
	SubtractVectors(victimpos, attackerpos,dir);
	SDKCall(SdkShove, victim, attacker,  dir);
}

public Action:player_hurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	
	new  attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new  victim = GetClientOfUserId(GetEventInt(event, "userid"));  
	
	if(attacker>0 && victim>0)
	{
		
		new human=Attacker[attacker];

		if(human>0)
		{

			if(GetClientTeam(victim)==3)
			{ 
				DoPointHurtForInfected(victim,  human, GetConVarInt(l4d_infected_attack_damage));
				PrintToChat(human, "%N attack %N", attacker, victim);
			}
			
		}

	} 
}
public Action:infected_hurt (Handle:event, const String:name[], bool:dontBroadcast)
{
	
	new  attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new  victim = GetEventInt(event, "entityid");  

	if(attacker>0 && victim>0)
	{
		new human=Attacker[attacker];
		if(human>0)
		{ 
			DoPointHurtForInfected(victim, human, GetConVarInt(l4d_infected_attack_damage));

		}
	} 
}

public Action:round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	ResetAllState();
}
 
public Action:round_end(Handle:event, const String:name[], bool:dontBroadcast)
{  
	ResetAllState();
} 
ResetAllState( )
{	
	InfectedCount=0;
	ScanTime=0.0;

	g_PointHurt=0;
	for(new i=1; i<=MaxClients; i++)
	{
		ResetClientState(i); 
	}
} 
ResetClientState(client)
{
	ScanIndex[client] = 0;
	ClientEnemy[client ] = 0;

	Victim[client]=0;
	Attacker[client]=0; 
	ClientButton [client]=0;
	for(new i=1; i<=MaxClients; i++)
	{
		ShoveCount[client][i]=0;
	}
	
}
UnControl(client, infected)
{  

	if(infected<=0)
	{
		infected=Victim[client]; 
	}
	else if(client<=0)
	{
		client=Attacker[infected];
	}

	Victim[client]=0;
	Attacker[infected]=0; 
	
	ResetClientState(client);
	ResetClientState(infected); 
	

	God(infected, false);
	
	Glow(infected, false);
	
 	if(infected>0 && client>0 && IsClientInGame(infected))PrintToChatAll("%N is run away", infected);

}
 
Control(client, infected, class)
{

	Victim[client]=infected;
	Attacker[infected]=client;
	ClientClass [ client ] = class;
	ClientScanAngle[client]=0.0; 

	God(infected, true);
	Glow(infected, true);
	
	UseDelay[client] = GetEngineTime();
	ClientEnemy[client]=0;
	Z_Spawn();
	PrintToChatAll("%N is controlled by %N ", infected, client);
}
God(client, bool:god)
{
	if (client>0 && IsClientInGame(client) && IsPlayerAlive(client))
    {		 
		if(god)SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);    
		else SetEntProp(client, Prop_Data, "m_takedamage", 2, 1); 
	}
}
Glow(client, bool:glow)
{
	if(L4D2Version)
	{
		if (client>0 && IsClientInGame(client) && IsPlayerAlive(client))
		{
			if(glow)
			{
				SetEntProp(client, Prop_Send, "m_iGlowType", 3 ); //3
				SetEntProp(client, Prop_Send, "m_nGlowRange", 0 ); //0
				SetEntProp(client, Prop_Send, "m_glowColorOverride", 256*100); //1	
			}
			else 
			{
				SetEntProp(client, Prop_Send, "m_iGlowType", 0 ); //3
				SetEntProp(client, Prop_Send, "m_nGlowRange", 0 ); //0
				SetEntProp(client, Prop_Send, "m_glowColorOverride", 0); //1	
			}
			
		
		}
	
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	/*
	if(client==1)
	{
		new Float:angle[3];
	
		GetClientEyeAngles(client, angle);
		PrintVector("", angle);
		return Plugin_Continue;
	}
	*/

	if(Victim[client]>0)
	{
		new infected=Victim[client];
		new human=client;
		if(IsClientInGame(infected) && IsPlayerAlive(infected))
		{
		}
		else 
		{
			UnControl(human, infected);
		}
	}

	new infected=client;
	new human=Attacker[infected];
	

	if(human==0)return Plugin_Continue; 
	
	new Float:engine_time= GetEngineTime();
	ScanAllEnemy(engine_time);
	
	new bool:free=false;

	new last_button=ClientButton[human];
	new current_button = GetClientButtons(human);
	
	/*
	if( (current_button  & IN_USE ) && (current_button  & IN_DUCK )) free=true;
	if(free)
	{
		buttons = buttons & ~IN_ATTACK;
		buttons = buttons & ~IN_ATTACK2;
		if(ClientClass[human] == ZOMBIECLASS_JOCKEY)buttons = buttons & ~IN_JUMP;
		if(ClientClass[human] == ZOMBIECLASS_HUNTER)buttons = buttons & ~IN_DUCK;
		return Plugin_Continue;
	}
	*/
	
	
	// if press e+right click then quit
	if((current_button & IN_USE) && (current_button & IN_ATTACK2))
	{
		if( GetEngineTime() - UseDelay[human] >2.0) 
		{
			UnControl(human, infected);
			return Plugin_Continue;
		}
	}  
	new Float:human_position[3];
	new Float:human_eye_position[3];
	new Float:human_angle[3];
	GetClientEyePosition(human, human_eye_position);
	GetClientAbsOrigin(human, human_position); 
	GetClientEyeAngles(human, human_angle);
	human_position[2]+=35.0;
	new Float:infected_position[3];
	new Float:infected_eye_position[3];
	GetClientEyePosition(infected, infected_eye_position);
	GetClientAbsOrigin(infected, infected_position);
	infected_position[2]+=35.0;
	
	new Float:enemy_position[3];
	
	new Float:distance=GetVectorDistance(human_position, infected_position);
	if(distance>max_distance_of_control )
	{
		UnControl(human, infected);
		return Plugin_Continue;
	} 
	
	new import_enmey=GetClientFrontEnemy(infected,infected_position, 50.0);
	//if(import_enmey>0)PrintToChatAll("%d", import_enmey);
	

	
	new bool:fellow_human=false;
	new bool:hunter_jump=false;
	new Float:target_postion[3];


		
	new bool:have_new_enemy=false;
	// get a new enmey 
	if(ClientEnemy[human] == 0 && InfectedCount>0)
	{

		if(ScanIndex[human]>=InfectedCount)
		{
			ScanIndex[human]=0;
		}
		ClientEnemy[human]=InfectedsArray[ScanIndex[human]];
		ScanIndex[human]++;
		
	}
	
	// ensure the enemy is valid.

	if( IsInfectedTeam(ClientEnemy[human] ))
	{
		GetPostion(ClientEnemy[human], enemy_position);
		ClientEnemy[human]=IsEnemyVisible(infected,ClientEnemy[human], human_position, infected_eye_position, enemy_position);	
	}
	else ClientEnemy[human]=0;

	fellow_human=false;
	if(ClientEnemy[human] != 0 )
	{
		fellow_human=true;
		CopyVector(enemy_position, target_postion);

	}
	



	//PrintToChatAll("scan index %d %d",ScanIndex[human],ClientEnemy[human] );
	new bool:have_enemy=false;
	if(ClientEnemy[human] == 0) have_enemy = false;
	else  have_enemy=true;

	 
	if(!have_enemy)
	{
		new Float:vec[3];
		GetClientEyeAngles(human, vec);
		GetAngleVectors(vec, vec, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector(vec, vec);
		if(buttons & IN_FORWARD)
		{
			ScaleVector(vec, 100.0+100.0);
		}
		else 
		{
			ScaleVector(vec, 100.0);
		}
		
		AddVectors(human_position,vec,target_postion);
	}
	
	if(current_button & IN_USE)
	{
		ClientEnemy[human] = 0;
		fellow_human=true;
		GetLookPosition(human, human_eye_position, human_angle,target_postion);
		
	}
		 
	//hunter jump
	if((current_button & IN_ZOOM) && !(last_button & IN_ZOOM ) && (ClientClass[human]==ZOMBIECLASS_HUNTER))
	{
		hunter_jump=true;
	}
	 
	
	new Float:runspeed=490.0;
	vel[0]=vel[1]=0.0;
	buttons=0;
	 
	new Float:infected_move_direction[3];
 
	SubtractVectors(target_postion,infected_position, infected_move_direction);
	
	distance=GetVectorLength(infected_move_direction);
	GetVectorAngles(infected_move_direction,infected_move_direction);


	buttons = buttons & ~IN_ATTACK;
	buttons = buttons & ~IN_ATTACK2;
	buttons = buttons & ~IN_JUMP;
	
	new bool:attack=false;
	new bool:move_forward=false;
	if(have_enemy)
	{
		move_forward=true;
		if(have_enemy)
		{
			vel[0] = runspeed;
			if(distance <50.0)
			{
				attack = true;
				infected_move_direction[0]=30.0;
			}
		}
	
	}
	else 
	{
		if(distance>20.0)
		{
			
			vel[0] = runspeed;
			move_forward=true;
			if(current_button& IN_FORWARD)
			{ 
			} 
			else 
			{
				if(distance<100.0)  vel[0]=runspeed /3.0; 
				if(distance<50.0)  vel[0]= 0.0;//runspeed /3.0; 
			}
			//PrintToChatAll("%f", vel[0]);
		}
	}
	

	TeleportEntity(infected, NULL_VECTOR,  infected_move_direction, NULL_VECTOR);
	//vel[0]=0;

	if(hunter_jump)
	{
		buttons = buttons | IN_ATTACK;
		move_forward=true;
		vel[0] = runspeed;
	}

	if(current_button& IN_SPEED)buttons = buttons | IN_SPEED;
	if(current_button & IN_JUMP)buttons = buttons | IN_JUMP; 
	if(current_button & IN_DUCK)buttons = buttons | IN_DUCK; 
	if(attack || import_enmey>0) buttons = buttons | IN_ATTACK2;
	if(move_forward) buttons = buttons | IN_FORWARD;
	//if(cb & IN_ZOOM)buttons = buttons | IN_ATTACK2; 
	ClientButton[human]=current_button;
	SetEntProp(infected, Prop_Data, "m_takedamage", 0, 1);  
	return Plugin_Continue;
}
GetLookPosition(client, Float:pos[3], Float:angle[3], Float:hitpos[3])
{
	
	new Handle:trace=TR_TraceRayFilterEx(pos, angle, MASK_ALL, RayType_Infinite, TraceRayDontHitSelfAndProtector, client); 

	if(TR_DidHit(trace))
	{		
	
		TR_GetEndPosition(hitpos, trace);
		
	}
	CloseHandle(trace);  

}
GetPostion(entity, Float:position[3])
{
	if(entity<=MaxClients) GetClientAbsOrigin(entity, position);
	else GetEntPropVector(entity, Prop_Send, "m_vecOrigin", position);
	position[2]+=35.0; 
}
IsEnemyVisible(client, entity, Float:human_position[3], Float:infected_position[3], Float:enemy_position[3])
{	
	if(GetVectorDistance(human_position,enemy_position)>max_distance_of_attack)return 0;
 	new Float:angle[3]; 
	SubtractVectors(enemy_position, infected_position, angle);
	GetVectorAngles(angle, angle); 
	new Handle:trace=TR_TraceRayFilterEx(infected_position, enemy_position, MASK_SHOT, RayType_EndPoint, TraceRayDontHitSelf, client); 	 

	new newenemy=0;
	 
	if(TR_DidHit(trace))
	{		 
		newenemy=TR_GetEntityIndex(trace);  		
	}
	else 
	{
		CloseHandle(trace); 
		return entity;
	}
	CloseHandle(trace); 
	if(newenemy==0)return 0;
	if(newenemy == entity)return entity;

	if(IsInfectedTeam(newenemy))
	{
		return newenemy;
	}	
	return 0; 
}

ScanAllEnemy(Float:time)
{
	if(time-ScanTime>1.0)
	{
		ScanTime=time; 
		InfectedCount = 0;
		if(GetConVarInt(l4d_infected_attack_special_infected)>0)
		{
			for(new i=1 ; i<=MaxClients; i++)
			{
				if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i)==3)
				{
					new class = GetEntProp(i, Prop_Send, "m_zombieClass");  
					InfectedsArray[InfectedCount++]=i;
				}
			}
		}
		if(GetConVarInt(l4d_infected_attack_special_infected)>0)
		{
			new ent=-1;
			while ((ent = FindEntityByClassname(ent,  "infected" )) != -1 && InfectedCount<EnemyArraySize-1)
			{
				InfectedsArray[InfectedCount++]=ent;
			} 
		}
	}
}
GetClientFrontEnemy(client, Float:client_postion[3], Float:range)
{
	new enemy_id=GetClientAimTarget(client, false);

	if(IsInfectedTeam(enemy_id)) 
	{
		new Float:enemy_position[3];
		GetEntPropVector(enemy_id, Prop_Send, "m_vecOrigin", enemy_position);
		if(GetVectorDistance(client_postion,enemy_position)<range)return enemy_id;
	}
	return 0;
}
Float:GetRange(enemy_id, Float:human_position[3], Float:enemy_position[3])
{		
	GetEntPropVector(enemy_id, Prop_Send, "m_vecOrigin", enemy_position);
	enemy_position[2]+=50.0;
	new Float:dis=GetVectorDistance(enemy_position, human_position);
	
	return dis;
}
PrintVector(String:s[], Float:target[3])
{
	PrintToChatAll("%s - %f %f %f", s, target[0], target[1], target[2]); 
}
CopyVector(Float:source[3], Float:target[3])
{
	target[0]=source[0];
	target[1]=source[1];
	target[2]=source[2];
}
SetVector(Float:target[3], Float:x, Float:y, Float:z)
{
	target[0]=x;
	target[1]=y;
	target[2]=z;
}

GameCheck()
{
	decl String:GameName[16];
	GetConVarString(FindConVar("mp_gamemode"), GameName, sizeof(GameName));
	PrintToChatAll("mp_gamemode = %s", GameName);
	
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
		ZOMBIECLASS_TANK=8;
		L4D2Version=true;
	}	
	else
	{
		ZOMBIECLASS_TANK=5;
		L4D2Version=false;
	}
	L4D2Version=!!L4D2Version;
}
Z_Spawn()
{
	
	new bot = CreateFakeClient("Monster");
	if (bot > 0)	
	{		
		ChangeClientTeam(bot,3);
		 
		new random = GetRandomInt(1,6);
		if(!L4D2Version)random=GetRandomInt(1,3);
		switch(random)
		{
			case 1:
			SpawnCommand(bot, "z_spawn", "smoker auto");
			case 2:
			SpawnCommand(bot, "z_spawn", "boomer auto");
			case 3:
			SpawnCommand(bot, "z_spawn", "hunter auto");
			case 4:
			SpawnCommand(bot, "z_spawn", "spitter auto");
			case 5:
			SpawnCommand(bot, "z_spawn", "jockey auto");
			case 6:
			SpawnCommand(bot, "z_spawn", "charger auto");
		}
			
		 
		Kickbot(INVALID_HANDLE, bot);
		//CreateTimer(0.1,Kickbot,bot);
	}	  
}
SpawnCommand(client, String:command[], String:arguments[] = "")
{
	if (client)
	{ 
		new flags = GetCommandFlags(command);
		SetCommandFlags(command, flags & ~FCVAR_CHEAT);
		FakeClientCommand(client, "%s %s", command, arguments);
		SetCommandFlags(command, flags);
	}
} 
public Action:Kickbot(Handle:timer, any:client)
{
	if (IsClientInGame(client))
	{
		if (IsFakeClient(client))
		{
			KickClient(client);
		}
	}
}

ScanEnemy(client, infected, Float:client_postion[3], Float:angle)
{	

	new Float:angle_vec[3] ;
	new Float:`postion[3];
	CopyVector(client_postion,postion);
	postion[2]-=20.0;

	angle_vec[0]=angle_vec[1]=angle_vec[2]=0.0;
	angle_vec[1]=angle;
	//GetEntPropVector(ent, Prop_Send, "m_vecOrigin", hitpos);
	//PrintToChatAll("%f %f", dir[0], dir[1]);
	new Handle:trace=TR_TraceRayFilterEx(postion, angle_vec, MASK_SHOT, RayType_Infinite, TraceRayDontHitSelfAndHuman, infected); 	 
	
	new newenemy=0;
	if(TR_DidHit(trace))
	{		 
		newenemy=TR_GetEntityIndex(trace); 
	} 
	CloseHandle(trace); 
	if(!IsInfectedTeam(newenemy))newenemy=0;
	return newenemy;
}
bool:IsInfectedTeam(ent)
{
	if(ent>0)
	{		 
		if(ent<=MaxClients)
		{
			if(Attacker[ent]==0 && IsClientInGame(ent) && IsPlayerAlive(ent) && GetClientTeam(ent)==3)
			{
				return true;
			}
		}
		else if(IsValidEntity(ent) && IsValidEdict(ent))
		{
			decl String:classname[32];
			GetEdictClassname(ent, classname,32);
			if(StrEqual(classname, "infected", true) || StrEqual(classname, "witch", true) )
			{
				return true;
			}
		}
	} 
	return false;
}
public bool:TraceRayDontHitSelfAndHuman(entity, mask, any:data)
{
	if(entity == data) 
	{
		return false; 
	} 
	if(entity<=MaxClients && entity>0)
	{
		if(IsClientInGame(entity) && IsPlayerAlive(entity) && GetClientTeam(entity)==2)
		{
			return false; 
		}
	}
	return true;
} 
public bool:TraceRayDontHitSelf(entity, mask, any:data)
{
	if(entity == data) 
	{
		return false; 
	} 
	
	return true;
} 
public bool:TraceRayDontHitSelfAndProtector(entity, mask, any:data)
{
	if(entity == data) 	return false;  
	if(entity == Victim[data])	return false;
	return true;
} 
bool:IsVisible(Float:pos1[3], Float:pos2[3], infected)
{	
 	
	new Handle:trace=TR_TraceRayFilterEx(pos1, pos2, MASK_SHOT, RayType_EndPoint, TraceRayDontHitAlive, infected); 	 
	
	new ent=0;
	if(TR_DidHit(trace))
	{		 
		ent=TR_GetEntityIndex(trace); 
	}
	CloseHandle(trace); 

	if(ent>0)return false;
	return true;
		
}
public bool:TraceRayDontHitAlive(entity, mask, any:data)
{
	if(entity==0)return false;
	if(entity == data) 
	{
		return false; 
	} 
	if(entity<=MaxClients && entity>0)
	{
		return false;  
	}
	else 
	{
		decl String:classname[32];
		GetEdictClassname(entity, classname,32);
		if(StrEqual(classname, "infected", true) || StrEqual(classname, "witch", true) )
		{
			return false;  
		}
	}
	return true;
} 
CreatePointHurt()
{
	new pointHurt=CreateEntityByName("point_hurt");
	if(pointHurt)
	{

		DispatchKeyValue(pointHurt,"Damage","10");
		DispatchKeyValue(pointHurt,"DamageType","2");
		DispatchSpawn(pointHurt);
	}
	return pointHurt;
}
new String:N[20];
DoPointHurtForInfected(victim, attacker=0,  damage=0)
{
	if(g_PointHurt > 0)
	{
		if(IsValidEdict(g_PointHurt))
		{
			if(victim>0 && IsValidEdict(victim))
			{		
				Format(N, 20, "target%d", victim);
				DispatchKeyValue(victim,"targetname", N);
				DispatchKeyValue(g_PointHurt,"DamageTarget", N);
				//DispatchKeyValue(g_PointHurt,"classname","");
				DispatchKeyValueFloat(g_PointHurt,"Damage", damage*1.0);
				DispatchKeyValue(g_PointHurt,"DamageType","-2130706430");
				AcceptEntityInput(g_PointHurt,"Hurt",(attacker>0)?attacker:-1);
			}
		}
		else g_PointHurt=CreatePointHurt();
	}
	else g_PointHurt=CreatePointHurt();
}
 