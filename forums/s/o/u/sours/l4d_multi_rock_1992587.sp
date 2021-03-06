/* Plugin Template generated by Pawn Studio */

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#define Model_Tank "models/infected/hulk.mdl"
#define Model_Tank_dlc3 "models/infected/hulk_dlc3.mdl"
new ZOMBIECLASS_TANK=	5;

new String:Tank_Model[100];

new GameMode;
new g_sprite;
new g_iVelocity;
new bool:L4D2Version;
public Plugin:myinfo = 
{
	name = "Tank Multi-Rock",
	author = "Pan Xiaohai",
	description = " ",
	version = "1.5",
	url = "<- URL ->"
}

new Handle:l4d_multi_rock_enable ; 
new Handle:l4d_multi_rock_chance_throw;
new Handle:l4d_multi_rock_chance_dead;
new Handle:l4d_multi_rock_damage;
 
new Handle:l4d_multi_rock_intervual; 
new Handle:l4d_multi_rock_durtation; 
 
public OnPluginStart()
{
	GameCheck();
  	l4d_multi_rock_enable = 		CreateConVar("l4d_multi_rock_enable", "1", "  0:disable, 1:enable in coop mode, 2: enable in all mode ");
 
	l4d_multi_rock_chance_throw = 	CreateConVar("l4d_multi_rock_chance_throw", "10", "chance of throw multi-rock when tank throw rock , unseless [0.0, 100.0]");	
 	l4d_multi_rock_chance_dead = 	CreateConVar("l4d_multi_rock_chance_dead", "70", "chance of throw multi-rock when tank dead [0.0, 100.0]");	
	
 	l4d_multi_rock_damage = 	CreateConVar("l4d_multi_rock_damage", "20", "damage of rock[1.0, 100.0]");	
  
 	l4d_multi_rock_intervual= 	CreateConVar("l4d_multi_rock_intervual", "0.5", "throw intervual of dead tank" );	
 	l4d_multi_rock_durtation= 	CreateConVar("l4d_multi_rock_durtation", "35.0", "throw duration of dead tank");
  
	g_iVelocity = FindSendPropOffs("CBasePlayer", "m_vecVelocity[0]");
	
	AutoExecConfig(true, "l4d_multi_rock"); 
 
	HookEvent("round_start", RoundStart);
	HookEvent("round_end", RoundStart);
	HookEvent("finale_win", RoundStart);
	HookEvent("mission_lost", RoundStart);
	HookEvent("map_transition", RoundStart);	
 
	//HookEvent("ability_use", ability_use); 
	HookEvent("player_death", player_death);
	//RegConsoleCmd("sm_nextpos", sm_nextpos); 
 	SetRandomSeed(GetSysTickCount());
	Reset(); 
}
new g_hulk=0;
new g_seq=0;
public Action:sm_nextpos(client, args)
{
	if(g_hulk>0)
	{
		SetEntProp(g_hulk, Prop_Send, "m_nSequence", g_seq);
		SetEntPropFloat(g_hulk, Prop_Send, "m_flPlaybackRate", 1.0);	
		 
		PrintToChatAll("seq %d", g_seq);
		g_seq++;
	}	
}
Reset()
{
	for(new i=1; i<=MaxClients; i++)
	{
 
	}
}
public Action:RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	Reset(); 
}
bool:CanUse()
{
	new mode=GetConVarInt(l4d_multi_rock_enable);
	if(mode==0)return false;
	if(mode==1 && GameMode==2)return false;
	return true;
}
new CurrentEnemy[MAXPLAYERS+1];
public Action:player_death(Handle:hEvent, const String:strName[], bool:DontBroadcast)
{ 
	if(!CanUse())return;
	 
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid")); 
	if(client>0)
	{ 	
		if(GetClientTeam(client)==3 &&  IsInfected(client, ZOMBIECLASS_TANK))
		{
			GetEntPropString(client, Prop_Data, "m_ModelName", Tank_Model, sizeof(Tank_Model));
			new Float:r=GetRandomFloat(0.0, 100.0); 
			if(r<GetConVarFloat(l4d_multi_rock_chance_dead))
			{   
				new Float:pos[3];
				GetClientEyePosition(client, pos);
				new clone = CreateEntityByName("prop_dynamic_override"); //prop_dynamic
				g_hulk=clone;
				SetEntityModel(clone,  Tank_Model);  //Model_Tank_dlc3
				TeleportEntity(clone, pos, NULL_VECTOR, NULL_VECTOR);
				DispatchKeyValueFloat(clone, "fademindist", 10000.0);
				DispatchKeyValueFloat(clone, "fademaxdist", 20000.0);
				DispatchKeyValueFloat(clone, "fadescale", 0.0); 	
				if( L4D2Version)
				{
					SetEntProp(clone, Prop_Send, "m_iGlowType", 3);
					SetEntProp(clone, Prop_Send, "m_nGlowRange", 0);
					SetEntProp(clone, Prop_Send, "m_nGlowRangeMin", 10);
					SetEntProp(clone, Prop_Send, "m_glowColorOverride", 256*100);
				}
				SetEntProp(clone, Prop_Send, "m_nSequence", 3);
				SetEntPropFloat(clone, Prop_Send, "m_flPlaybackRate", 1.0);
				
				new Handle:h=CreateDataPack();				
				WritePackFloat(h, GetEngineTime());
				GetClientEyePosition(client, pos);
				WritePackFloat(h, pos[0]); 
				WritePackFloat(h, pos[1]); 
				WritePackFloat(h, pos[2]+100.0); 		
				WritePackCell(h, clone); 	
				CurrentEnemy[client]=0;
				WritePackCell(h, client);
				new Float:count=0.0;
				for(new i=CurrentEnemy[client]+1; i<=MaxClients; i++)
				{
					if(IsClientInGame(i) && GetClientTeam(i)==2 && IsPlayerAlive(i) && !IsFakeClient(i))
					{
						count+=1.0;
					} 
					 
				}
				if(count==0.0)count=1.0; 
				CreateTimer(GetConVarFloat(l4d_multi_rock_intervual), TimerDeadTankMulitRock, h, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
				PrintToChatAll("\x04Watch the tank's rock!");

			}	
		}
	}
}

public Action:ability_use(Handle:event, const String:name[], bool:dontBroadcast)
{	
	if(!CanUse())return;
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client>0) 
	{
		decl String:s[32];	
		GetEventString(event, "ability", s, 32);
		if(StrEqual(s, "ability_throw", true))
		{	 
			new Float:r=GetRandomFloat(0.0, 100.0); 
			if(false && r<GetConVarFloat(l4d_multi_rock_chance_throw))
			{  
				CreateTimer(1.5, TimerTankThrow, client, TIMER_FLAG_NO_MAPCHANGE);
			}

		}
	}
	
} 
public Action:TimerDeadTankMulitRock(Handle:timer, Handle:h)
{
	ResetPack(h, false);
	new Float:starttime = ReadPackFloat(h);
	new Float:eyepos[3];
	eyepos[0] = ReadPackFloat(h);
	eyepos[1] = ReadPackFloat(h);
	eyepos[2] = ReadPackFloat(h);
	new clone = ReadPackCell(h); 
	new client = ReadPackCell(h); 
	
	if(starttime+GetConVarFloat(l4d_multi_rock_durtation)<GetEngineTime() )
	{
		CloseHandle(h);	
		AcceptEntityInput(clone, "kill");
		return Plugin_Stop;
	}	
	
	new b=NextPlayer(client);
	if(!b)b=NextPlayer(client);
	if(!b)return Plugin_Continue;
	new enemy=CurrentEnemy[client];
	if(clone!=0 && IsValidEntity(clone) && IsValidEdict(clone))
	{	
		StartMultiRock2(  eyepos,eyepos, enemy); 
		return Plugin_Continue;
	} 
	CloseHandle(h);	
	return Plugin_Stop;
}
bool:NextPlayer(client)
{
	new bool:find=false;
	for(new i=CurrentEnemy[client]+1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i)==2 && IsPlayerAlive(i)  && !IsFakeClient(i))
		{
			find=true;
			CurrentEnemy[client]=i;
			break;
		} 
		 
	}
	if(!find)
	{
		CurrentEnemy[client]=0;
	}
	return find;
	 
}
public Action:TimerTankThrow(Handle:timer, any:client)
{ 
	if(client>0 && IsClientInGame(client) && IsPlayerAlive(client) && IsInfected(client, ZOMBIECLASS_TANK) )
	{ 
		new Float:p1[3];
		new Float:p2[3];
		StartMultiRock(client, p1, p2); 	 
	}
}
public Action:TimerStopGodMode(Handle:timer, any:client)
{
    if (client>0 && IsClientInGame(client) && IsPlayerAlive(client))
    {		 
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);    
	}
}
Action:StartMultiRock(client, Float:eyePos[3], Float:footpos[3] )
{  
	if(client>0 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		GetClientEyePosition(client, eyePos);
		GetClientAbsOrigin(client, footpos); 
		SetEntProp(client, Prop_Data, "m_takedamage", 0, 1); 
		CreateTimer(3.0, TimerStopGodMode, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	else client=0;
	 
	new Float:eyepos[3];
	CopyVector(eyePos, eyepos);
	eyepos[2]+=100.0; //100.0
	
	new String:damagestr[32];
	GetConVarString(l4d_multi_rock_damage,damagestr, 32 ); 
 
	 
	new maxsurvivor=0;
	decl Enemy[MAXPLAYERS+1];
	for(new i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i)==2 && IsPlayerAlive(i)  && !IsFakeClient(i))
		{
			Enemy[maxsurvivor++]=i;
		}
	}
	new selectedCount=maxsurvivor;
	for(new i=0; i<maxsurvivor ; i++)
	{ 
		/*
		new s=GetRandomInt(selectedCount,maxsurvivor-1);
		new t=Enemy[selectedCount];
		Enemy[selectedCount]=Enemy[s];
		Enemy[s]=t;
		selectedCount++;
		*/
	}
	decl Float:offset[3];
	decl Float:enmeyPos[3];
	for(new i=0; i<selectedCount; i++)
	{ 
		new enemy=Enemy[i];

		GetClientEyePosition(enemy, enmeyPos);
		SubtractVectors(enmeyPos, eyepos, offset);
		offset[2]=0.0;
		NormalizeVector(offset, offset);
		ScaleVector(offset,  100.0);
		AddVectors(eyepos, offset, offset);
		//ShowLaser(0, offset, enmeyPos, 5.0, 5.0,5.0);
		if(client>0)
		{
			new Float:d1=GetVectorDistance(offset, eyePos); 
			//PrintToChatAll("d1 %f",d1);
			if(d1<100.0  )
			{ 
				//continue;
			}
		}		
		
		//SetEntityMoveType(ent, MOVETYPE_NOCLIP);
	
		new ent=CreateEntityByName("env_rock_launcher");    
		if(ent<=0)return Plugin_Stop;
		DispatchSpawn(ent); 
		DispatchKeyValue(ent, "rockdamageoverride", damagestr);	 

		
		TeleportEntity(ent, offset, NULL_VECTOR,NULL_VECTOR );
		PrintCenterText(enemy, "watch the rock!");
		SetVariantEntity(enemy);		
		AcceptEntityInput(ent, "SetTarget" );
		AcceptEntityInput(ent, "LaunchRock");  
		AcceptEntityInput(ent, "kill");  

	}	
	//AcceptEntityInput(ent, "kill"); 
	return Plugin_Continue;
}
Action:StartMultiRock2( Float:eyePos[3], Float:footpos[3], enemy)
{   
	new Float:eyepos[3];
	CopyVector(eyePos, eyepos); 
	new String:damagestr[32];
	GetConVarString(l4d_multi_rock_damage,damagestr, 32 );
 
	new ent=CreateEntityByName("env_rock_launcher");     
	DispatchSpawn(ent); 
	DispatchKeyValue(ent, "rockdamageoverride", damagestr);	 

	
	TeleportEntity(ent, eyepos, NULL_VECTOR,NULL_VECTOR );
	PrintCenterText(enemy, "watch the rock!");
	
	SetVariantEntity(enemy);		
	AcceptEntityInput(ent, "SetTarget" );
	AcceptEntityInput(ent, "LaunchRock");  
	AcceptEntityInput(ent, "kill"); 
	//PrintToChat(1, "rock %N", enemy);
 
	return Plugin_Continue;
}
ShowLaser(colortype,Float:pos1[3], Float:pos2[3], Float:life=10.0,  Float:width1=1.0, Float:width2=11.0)
{
	decl color[4];
	if(colortype==1)
	{
		color[0] = 200; 
		color[1] = 0;
		color[2] = 0;
		color[3] = 230; 
	}
	else if(colortype==2)
	{
		color[0] = 0; 
		color[1] = 200;
		color[2] = 0;
		color[3] = 230; 
	}
	else if(colortype==3)
	{
		color[0] = 0; 
		color[1] = 0;
		color[2] = 200;
		color[3] = 230; 
	}
	else 
	{
		color[0] = 200; 
		color[1] = 200;
		color[2] = 200;
		color[3] = 230; 		
	}

	
	TE_SetupBeamPoints(pos1, pos2, g_sprite, 0, 0, 0, life, width1, width2, 1, 0.0, color, 0);
	TE_SendToAll();
}
IsInfected(client, type)
{
	new class = GetEntProp(client, Prop_Send, "m_zombieClass");
	if(type==class)return true;
	else return false;
}
   
PrintVector(Float:target[3], String:s[]="")
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
 
public bool:DontHitSelf(entity, mask, any:data)
{
	if(entity == data) 
	{
		return false; 
	}
	return true;
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
		ZOMBIECLASS_TANK=8;
	}	
	else
	{
		L4D2Version=false;
		ZOMBIECLASS_TANK=5;
	}
}

public OnMapStart()
{ 
	//PrecacheModel(Model_Tank);
	//PrecacheModel(Model_Tank_dlc3);
	if(L4D2Version)
	{
		g_sprite = PrecacheModel("materials/sprites/laserbeam.vmt");		 
	}
	else
	{
		g_sprite = PrecacheModel("materials/sprites/laser.vmt");			 	
	} 
}
 