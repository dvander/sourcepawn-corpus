#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdktools_functions>
#include <sdkhooks>

 
#define Pai 3.14159265358979323846 
#define DEBUG false
#define State_None 0
#define State_Climb 1
#define State_OnAir 2

#define ZOMBIECLASS_SURVIVOR	9
#define ZOMBIECLASS_SMOKER	1
#define ZOMBIECLASS_BOOMER	2
#define ZOMBIECLASS_HUNTER	3
#define ZOMBIECLASS_SPITTER	4
#define ZOMBIECLASS_JOCKEY	5
#define ZOMBIECLASS_CHARGER	6
new ZOMBIECLASS_TANK=	5;

#define model_zoey 1
#define model_bill 2
#define model_louis 3
#define model_francis 4

#define model_coach 5
#define model_nick 6
#define model_ellis 7
#define model_rochelle 8

#define model_tank 9
#define model_boomer 10
#define model_smoker 11
#define model_hunter 12

#define model_spitter 13
#define model_jockey 14
#define model_charger 15
#define model_boomer_female 16

#define JumpSpeed 300.0 
#define gbodywidth 20.0 
#define bodylength 70.0

new Handle:l4d_climb_enable ;  
new Handle:l4d_climb_team ; 
new Handle:l4d_climb_glow ; 
new Handle:l4d_climb_msg ;
new Handle:l4d_climb_anim[20];
 
new Handle:l4d_climb_speed[10] ; 
new Handle:l4d_climb_infected[10] ; 
new GameMode;
new L4D2Version;
new Colon[MAXPLAYERS+1];
new bool:FirstRun[MAXPLAYERS+1];
new Float:BodyNormal[MAXPLAYERS+1][3];
new Float:Angle[MAXPLAYERS+1];
new State[MAXPLAYERS+1];
new Float:BodyPos[MAXPLAYERS+1][3];
new Float:LastPos[MAXPLAYERS+1][3];
new Float:SafePos[MAXPLAYERS+1][3];
new Float:BodyWidth[MAXPLAYERS+1];
new Float:JumpTime[MAXPLAYERS+1];
new Float:LastTime[MAXPLAYERS+1];
new Float:Intervual[MAXPLAYERS+1];
new Float:GlowTime[MAXPLAYERS+1];
new bool:GlowIndicator[MAXPLAYERS+1];
new Float:ClimbSpeed[MAXPLAYERS+1];
new Float:PlayBackRate[MAXPLAYERS+1];
new Float:StuckIndicator[MAXPLAYERS+1];  

new ShowMsg[MAXPLAYERS+1]; 

new g_sprite;
new g_ghostoffest;

public Plugin:myinfo = 
{
	name = "climb everywhere",
	author = "Pan Xiaohai",
	description = "",
	version = "1.02",	
}
 
public OnPluginStart()
{
	GameCheck(); 	
 	l4d_climb_enable = CreateConVar("l4d_climb_enable", "2", "  0:disable, 1:enable in coop mode, 2: enable in all mode ", FCVAR_PLUGIN);
	l4d_climb_team = CreateConVar("l4d_climb_team", "1", "  1:enable for survivor and infected, 2:enable for survivor, 3:enable for infected ", FCVAR_PLUGIN);	
	l4d_climb_msg=CreateConVar("l4d_climb_msg", "3", "how many times to display usage information ,0 disable  ", FCVAR_PLUGIN);	
	l4d_climb_glow=CreateConVar("l4d_climb_glow", "1", "0 disable 1:enable ", FCVAR_PLUGIN);	
	
	
 
	l4d_climb_infected[ZOMBIECLASS_HUNTER] = CreateConVar("l4d_climb_hunter", "1", "0:disable  1:enable for hunter 2:enable for hunter but can not use in ghost mode", FCVAR_PLUGIN);	
	l4d_climb_infected[ZOMBIECLASS_SMOKER] = CreateConVar("l4d_climb_smoker", "1", " ", FCVAR_PLUGIN);	
	l4d_climb_infected[ZOMBIECLASS_TANK] =   CreateConVar("l4d_climb_tank", "1", " ", FCVAR_PLUGIN);	
	l4d_climb_infected[ZOMBIECLASS_BOOMER] = CreateConVar("l4d_climb_boomer", "1", " ", FCVAR_PLUGIN);	
	l4d_climb_infected[ZOMBIECLASS_JOCKEY] = CreateConVar("l4d_climb_jockey", "1", " ", FCVAR_PLUGIN);	
	l4d_climb_infected[ZOMBIECLASS_SPITTER] =CreateConVar("l4d_climb_spitter", "1", " ", FCVAR_PLUGIN);	
	l4d_climb_infected[ZOMBIECLASS_CHARGER] =CreateConVar("l4d_climb_changer", "1", " ", FCVAR_PLUGIN);	
	
	l4d_climb_speed[0] =                    CreateConVar("l4d_climb_speed", "40", "210 is the walk speed", FCVAR_PLUGIN);	
	l4d_climb_speed[ZOMBIECLASS_SURVIVOR] = CreateConVar("l4d_climb_speed_survivor", "1.0", "survivor's speed is  40.0*1.0", FCVAR_PLUGIN);	
	l4d_climb_speed[ZOMBIECLASS_HUNTER] =   CreateConVar("l4d_climb_speed_hunter", "2.4", "hunter's speed is 40.0*2.4", FCVAR_PLUGIN);	
	l4d_climb_speed[ZOMBIECLASS_SMOKER] =   CreateConVar("l4d_climb_speed_smoker", "2.1", " ", FCVAR_PLUGIN);	
	l4d_climb_speed[ZOMBIECLASS_TANK] =     CreateConVar("l4d_climb_speed_tank", "1.5", " ", FCVAR_PLUGIN);	
	l4d_climb_speed[ZOMBIECLASS_BOOMER] =   CreateConVar("l4d_climb_speed_boomer", "1.8", " ", FCVAR_PLUGIN);	
	l4d_climb_speed[ZOMBIECLASS_JOCKEY] =   CreateConVar("l4d_climb_speed_jockey", "2.4", " ", FCVAR_PLUGIN);	
	l4d_climb_speed[ZOMBIECLASS_SPITTER] =  CreateConVar("l4d_climb_speed_spitter", "2.0", " ", FCVAR_PLUGIN);	
	l4d_climb_speed[ZOMBIECLASS_CHARGER] =  CreateConVar("l4d_climb_speed_changer", "2.5", " ", FCVAR_PLUGIN);	
	
	l4d_climb_speed[ZOMBIECLASS_CHARGER] =  CreateConVar("l4d_climb_speed_changer", "2.5", " ", FCVAR_PLUGIN);		
	
	l4d_climb_anim[model_zoey] =  CreateConVar("l4d_climb_anim_zoey", "0", "zoey's animation, 0:default", FCVAR_PLUGIN);	
	l4d_climb_anim[model_francis] =  CreateConVar("l4d_climb_anim_francis", "0", "francis's animation", FCVAR_PLUGIN);
	l4d_climb_anim[model_louis] =  CreateConVar("l4d_climb_anim_louis", "0", "louis's animation", FCVAR_PLUGIN);
	l4d_climb_anim[model_bill] =  CreateConVar("l4d_climb_anim_bill", "0", "bill's animation", FCVAR_PLUGIN);
	
	l4d_climb_anim[model_coach] =  CreateConVar("l4d_climb_anim_coach", "0", "coach's animation", FCVAR_PLUGIN);
	l4d_climb_anim[model_nick] =  CreateConVar("l4d_climb_anim_nick", "0", "nick's animation", FCVAR_PLUGIN);
	l4d_climb_anim[model_ellis] =  CreateConVar("l4d_climb_anim_ellis", "0", "ellis's animation", FCVAR_PLUGIN);
	l4d_climb_anim[model_rochelle] =  CreateConVar("l4d_climb_anim_rochelle", "0", "rochelle's animation", FCVAR_PLUGIN);
	
	l4d_climb_anim[model_tank] =  CreateConVar("l4d_climb_anim_tank", "0", "tank's animation", FCVAR_PLUGIN);
	l4d_climb_anim[model_boomer] =  CreateConVar("l4d_climb_anim_boomer", "0", "boomer's animation", FCVAR_PLUGIN);
	l4d_climb_anim[model_smoker] =  CreateConVar("l4d_climb_anim_smoker", "0", "smoker's animation", FCVAR_PLUGIN);
	l4d_climb_anim[model_hunter] =  CreateConVar("l4d_climb_anim_hunter", "0", "hunter's animation", FCVAR_PLUGIN);
	
	l4d_climb_anim[model_boomer_female] =  CreateConVar("l4d_climb_anim_boomer_female", "0", "female boomer's animation", FCVAR_PLUGIN);
	l4d_climb_anim[model_jockey] =  CreateConVar("l4d_climb_anim_jockey", "0", "jockey's animation", FCVAR_PLUGIN);
	l4d_climb_anim[model_spitter] =  CreateConVar("l4d_climb_anim_spitter", "0", "spitter's animation", FCVAR_PLUGIN);
	l4d_climb_anim[model_charger] =  CreateConVar("l4d_climb_anim_charger", "0", "charger's animation", FCVAR_PLUGIN);
 
	
	AutoExecConfig(true, "l4d_climb");  
	g_ghostoffest=FindSendPropInfo("CTerrorPlayer", "m_isGhost");
	
	HookEvent("player_bot_replace", player_bot_replace );	 
	HookEvent("player_jump", player_jump);
	if(L4D2Version)
	{
		HookEvent("jockey_ride", infected_ablility);
		HookEvent("charger_carry_start", infected_ablility);
	}
	HookEvent("tongue_grab",  infected_ablility);
	HookEvent("player_ledge_grab",  player_ledge_grab);
	HookEvent("lunge_pounce", infected_ablility);
	HookEvent("player_incapacitated_start", player_incapacitated_start); 	
	HookEvent("player_death", player_death);
	HookEvent("player_spawn", player_spawn);
	
	HookEvent("round_start", round_end);
	HookEvent("round_end", round_end);
	HookEvent("finale_win", round_end);
	HookEvent("mission_lost", round_end);
	HookEvent("map_transition", round_end);	
	
	RegConsoleCmd("sm_anim", sm_anim);
	
	ResetAllState();
}
public Action:sm_anim(client,args)
{
	if(client>0 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		new m=GetEntProp(client, Prop_Send, "m_nSequence" );	
		PrintToChatAll("animation is %d", m);
	}
}
public Action:round_end(Handle:event, const String:name[], bool:dontBroadcast)
{
	ResetAllState();
}
ResetAllState()
{
	for(new i=1; i<=MaxClients; i++)
	{
		Stop(i);
		ShowMsg[i]=0;
	}
}
/*
public OnGameFrame()
{
	
	if(GetClientButtons(1) & IN_USE)
	{
		new m=GetEntProp(1, Prop_Send, "m_nSequence" );
		new all_iVelocity = FindSendPropOffs("CBasePlayer", "m_vecVelocity[0]");
		decl Float:velocity[3];
		GetEntDataVector(1, all_iVelocity, velocity);
		new Float:playrate = GetEntPropFloat(1, Prop_Send, "m_flPlaybackRate");	
		PrintToChatAll("vec %f seq %d", GetVectorLength(velocity), m);
	}
}
*/
public infected_ablility(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(l4d_climb_enable)==0)return;
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));  
	Interrupt(victim);
}
public player_ledge_grab(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(l4d_climb_enable)==0)return;
	new victim = GetClientOfUserId(GetEventInt(event, "userid")); 
	Interrupt(victim);
}
public player_incapacitated_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(l4d_climb_enable)==0)return; 
	new victim = GetClientOfUserId(GetEventInt(event, "userid")); 
	Interrupt(victim);
}
public player_bot_replace(Handle:Spawn_Event, const String:Spawn_Name[], bool:Spawn_Broadcast)
{
	if(GetConVarInt(l4d_climb_enable)==0)return; 
	new client = GetClientOfUserId(GetEventInt(Spawn_Event, "player"));
	new bot = GetClientOfUserId(GetEventInt(Spawn_Event, "bot")); 
	Stop(client);
	Stop(bot); 
}
public Action:player_jump(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));

	if(IsFakeClient(client))return; 
	new bool:isGhost=false;
	if(GetClientTeam(client)==3 && GetEntData(client, g_ghostoffest, 1))isGhost=true; 
	if(!CanUse(client, isGhost))return;
	SDKUnhook( client, SDKHook_PostThinkPost,  PreThink); 
	SDKUnhook(client, SDKHook_SetTransmit, OnSetTransmitClient);
	State[client]=State_OnAir;
	SDKHook( client, SDKHook_PostThinkPost,  PreThink);   // watch it.
	decl Float:pos[3];
	GetClientAbsOrigin(client, pos);
	CopyVector(pos, SafePos[client]);                // save it's postion , if it stucked then teleport it to this postion.
	LastTime[client]=GetEngineTime();
	JumpTime[client]=LastTime[client];
	if(ShowMsg[client]<GetConVarInt(l4d_climb_msg))
	{
		if(CanUse(client))CreateTimer(1.0, ShowInfo,client); 
		ShowMsg[client]++;
	}
	
	return;
 }
public Action:player_death(Handle:hEvent, const String:strName[], bool:DontBroadcast)
{
	if(GetConVarInt(l4d_climb_enable)==0)return;
	new victim = GetClientOfUserId(GetEventInt(hEvent, "userid")); 
	Stop(victim); 
	ShowMsg[victim]=0;
}
public Action:player_spawn(Handle:hEvent, const String:strName[], bool:DontBroadcast)
{
	if(GetConVarInt(l4d_climb_enable)==0)return;
	new victim = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	ShowMsg[victim]=0;
	Stop(victim); 
}
/*
* if a player can use climb 
*/
bool:CanUse(client, bool:isGhost=false)
 {
 	new mode=GetConVarInt(l4d_climb_enable);
	if(mode==0)return false;
	if(mode==1 && GameMode==2)return false;
	if(client==0)return true;
	if(IsClientInGame(client))
	{
		if(IsPlayerAlive(client))
		{
			new teammode=GetConVarInt(l4d_climb_team);
			new team=GetClientTeam(client);
			if(team==2)
			{
				if(teammode==1 || teammode==2)return true;
				else return false;
			}
			else if(team==3)
			{
				if(teammode==1 || teammode==3)
				{
					new c = GetEntProp(client, Prop_Send, "m_zombieClass");
					new m=GetConVarInt(l4d_climb_infected[c]);
					if(m==1)return true;
					else if(m==2 && !isGhost)return true;
					else return false;
				}
				else return false;
			}
			return true;
		}
		return true;
	}
	else return true; 
}
/* 
* interrupt a player's climb
*/
Interrupt(client)
{
	if(State[client]==State_Climb) //if it 's climbing , force it jump and stop climb.
	{
		Jump(client, false, 50.0);
		Stop(client);
	}
	else if(State[client]==State_OnAir) //not climbing but on air, stop it.
	{
		Stop(client);
	}
	
}
/* 
* stop a player from climb mode
*/
Stop(client)
{
	if(State[client]==State_None)return;
	State[client]=State_None;
	if(Colon[client]>0 && IsValidEdict(Colon[client]) && IsValidEntity(Colon[client]) )  // remove dummy body
	{
		AcceptEntityInput(Colon[client], "kill");
		Colon[client]=0;
		
		new b=IsVilidPlayer(client);
		if(b)GotoFirstPerson(client); 
		if(b)VisiblePlayer(client, true);
		if(b)SetEntityMoveType(client, MOVETYPE_WALK); 
		if(b)SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
	}
	
	SDKUnhook( client, SDKHook_PostThinkPost,  PreThink); //stop watching it
	SDKUnhook(client, SDKHook_SetTransmit, OnSetTransmitClient);  //other people can see it's real body.

	if(DEBUG)PrintToChatAll("end");
}
/* 
* get into climb mode
*/
Start(client)
 {
	decl Float:vAngles[3];
	decl Float:vOrigin[3];
	decl Float:hit[3];
	decl Float:normal[3];
	decl Float:up[3];
	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);	 
	 
	GetRay(client,  vOrigin  ,  vAngles , hit, normal,0.0-gbodywidth); 
	if(GetVectorDistance(hit, vOrigin)<gbodywidth*2.0)   //calc distince between body and surfece, if it is close enough, then get into climb mode.
	{
		SetVector(up, 0.0, 0.0, 1.0);
		new Float:f=GetAngle(normal, up)*180/Pai;
		if(f<10.0 || f>170.0) //the surfece is horizontal, can not climb
		{
			if(DEBUG)PrintToChatAll("stopped %f ", GetAngle(BodyNormal[client],  up)*180/Pai ); 
			return;
		}
		//code below get into climb mode
		
		CopyVector(normal,BodyNormal[client]); 
		CopyVector(hit, BodyPos[client]);
	 
		Angle[client]=0.0;
		CopyVector(normal ,BodyNormal[3]);
	 
		new c=CreateClone(client);  //create dummy body
		if(c>0)
		{
			Colon[client]=c; 
			SetEntityMoveType(client, MOVETYPE_NONE); 
			GotoThirdPerson(client); 
			VisiblePlayer(client, false);
			SDKUnhook(client, SDKHook_SetTransmit, OnSetTransmitClient);
			SDKHook(client, SDKHook_SetTransmit, OnSetTransmitClient); //other player can not see it's real body
			SDKUnhook( client, SDKHook_PostThinkPost,  PreThink); 
			SDKHook( client, SDKHook_PostThinkPost,  PreThink);  // watch it.
			SaveWeapon(client );
			State[client]=State_Climb;
			FirstRun[client]=true;
			
			GlowIndicator[client]=false;
			GlowTime[client]=0.0;
		}
		else PrintToChat(client ,"Your model is not allow for climb");
	}
}
/* 
* jump from climb mode  
*/
Jump(client, bool:check=true, Float:speed=JumpSpeed)
{
	new Float:time=GetEngineTime(); 
	if(check)
	{
		if(time-JumpTime[client]<2.0)
		{
			PrintCenterText(client, "you are jump too quick");
			return;
		}
	}
 	if(Colon[client]>0) //remove dummy body
	{
		AcceptEntityInput(Colon[client], "kill");
		Colon[client]=0;
		if(IsVilidPlayer(client))RestoreWeapon(client); 
	}
	SDKUnhook(client, SDKHook_SetTransmit, OnSetTransmitClient);
	if(!IsVilidPlayer(client))return;
	
	GotoFirstPerson(client);
	VisiblePlayer(client, true);
	SetEntityMoveType(client, MOVETYPE_WALK);  
	if(DEBUG)PrintToChatAll( "jump");
	decl Float:vAngles[3];
	decl Float:vOrigin[3];
	decl Float:vec[3];
	decl Float:pos[3];
	GetClientEyePosition(client,vOrigin);
	CopyVector(BodyNormal[client], vec);
	NormalizeVector(vec, vec);
	ScaleVector(vec, BodyWidth[client]);
	AddVectors(vOrigin, vec, pos);
	
	GetClientEyeAngles(client, vAngles);
	GetAngleVectors(vAngles, vec, NULL_VECTOR,NULL_VECTOR);
	NormalizeVector(vec, vec);
	ScaleVector(vec, speed);
	TeleportEntity(client, pos, NULL_VECTOR, vec); // jump into her's look direction
	CopyVector(pos, LastPos[client]);
	JumpTime[client]=time;
	StuckIndicator[client]=0.0;
	State[client]=State_OnAir;                   //state switch to onair
}
public Action:OnSetTransmitClient (climber, client)
{
	
	if(climber!=client)
	{
		new teamClimber=GetClientTeam(climber);
		if(teamClimber==2)return Plugin_Handled; 
		new teamClient=GetClientTeam(client);
		if(teamClimber==3 && teamClient==2)return Plugin_Handled; 
		if(GlowIndicator[climber])return Plugin_Continue;
		return Plugin_Handled; 
	}
	else return Plugin_Continue;
}
public PreThink(client)
{
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		new Float:time=GetEngineTime( );
		new Float:intervual=time-LastTime[client]; 
		Intervual[client]=intervual;
		if(State[client]==State_OnAir)OnAir(client); // player is on air 
		else if(State[client]==State_Climb)Climb(client, intervual); // player is climbing
		LastTime[client]=time;
		if(GetConVarInt(l4d_climb_glow)==1)
		{
			GlowTime[client]+=intervual;
			 
			if(GlowTime[client]>4.0)
			{
				GlowIndicator[client]=false;
				GlowTime[client]=0.0;  
			}
			else if(GlowTime[client]>3.5)
			{			 
				GlowIndicator[client]=true;	 
			}
		}
	}
	else
	{
		Stop(client);
	}

}
/* 
* when a play is jump into air  
*/
OnAir(client)
{
	new flag=GetEntityFlags(client);  //FL_ONGROUND
	if(flag & FL_ONGROUND) // on ground , so stop
	{
		if(DEBUG)PrintToChatAll("on ground");
		Stop(client);
		return;
	}
	new button=GetClientButtons(client);
	if((button & IN_USE) )   // press use key, then start climb
	{ 
		Start(client); 
	}	
	//code below determine if a player is stucked after jump.
	new Float:time=GetEngineTime();
	if(time>JumpTime[client]+1.0)return;
	decl Float:pos[3];
	GetClientAbsOrigin(client, pos);
	StuckIndicator[client]+=GetVectorDistance(pos, LastPos[client]);
	//if(DEBUG)PrintToChatAll("stuck indicator %f", StuckIndicator[client]);
	CopyVector(pos, LastPos[client]);
	if(time>JumpTime[client]+0.5 && StuckIndicator[client]<10.0)
	{
		TeleportEntity(client, SafePos[client], NULL_VECTOR,NULL_VECTOR); 
		PrintHintText(client, "You are stucked");
		Stop(client);
	} 
}
/* 
* when a play is climbing ,this function calculate the player's movement, the dummy body's animation
*/
Climb(client, Float:intervual)
{
	new clone=Colon[client];
	if(clone>0)	
	{ 
		SetEntProp(client, Prop_Send, "m_iAddonBits", 0);
		SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0);
		decl Float:colonPos[3];
		decl Float:clientPos[3];
		decl Float:bodyPos[3]; 
		decl Float:headOffset[3]; 
		decl Float:footOffset[3];
		decl Float:bodyTouchPos[3];
		decl Float:headTouchPos[3];
		decl Float:footTouchPos[3];			
		decl Float:moveDir[3];    
		decl Float:cloneAnge[3];
		decl Float:bodyNormal[3];
		decl Float:eyeNormal[3];
		decl Float:footNormal[3];
		decl Float:normal[3];
		decl Float:temp[3];
		decl Float:up[3];
		SetVector(up, 0.0, 0.0, 1.0); 
		new button=GetClientButtons(client);
		SetEntityMoveType(client, MOVETYPE_NONE); 
		 
		new Float:playrate=0.0;	
		new bool:needprocess=false;
		new bool:moveforward;
		new bool:moveback;
		if(button & IN_FORWARD )
		{
			needprocess=true; 
			moveforward=true;
		}
		else if(button & IN_BACK )
		{
			needprocess=true; 
			moveback=true;
		}
		if(button & IN_MOVELEFT )
		{
			 
			Angle[client]+=intervual*90.0;
			playrate=PlayBackRate[client]*0.5;
			needprocess=true;
		}
		else if(button & IN_MOVERIGHT )
		{
			 
			Angle[client]-=intervual*90.0;
			playrate=PlayBackRate[client]*0.5;
			needprocess=true;
		}
		if( button & IN_JUMP || button & IN_ATTACK || button & IN_ATTACK2)
		{
			Jump(client);
			 	
			return;
		}
 
		while(needprocess  || FirstRun[client])
		{
			FirstRun[client]=false;
			CopyVector(BodyPos[client], bodyPos);  
			CopyVector(BodyNormal[client], normal);
			CopyVector(normal, cloneAnge);
			ScaleVector(cloneAnge, -1.0);
			GetVectorAngles(cloneAnge, cloneAnge); 
			cloneAnge[2]=0.0-Angle[client]; 
			 
			new Float:f=GetAngle(BodyNormal[client], up)*180/Pai;
			if(f<10.0 || f>170.0)
			{
				if(DEBUG)PrintToChatAll("stopped %f ", GetAngle(BodyNormal[client],  up)*180/Pai );
				Jump(client, false, 0.0);
				 
				return;
			}
			
		
			SetVector(headOffset, 0.0, 0.0, 1.0); 
			GetProjection(normal, up, headOffset);  
			RotateVector(normal, headOffset, AngleCovert(Angle[client]), headOffset); 
			CopyVector(headOffset, footOffset);
			NormalizeVector(headOffset, headOffset);
			NormalizeVector(footOffset, footOffset);
			ScaleVector(footOffset, 0.0-bodylength*0.5);
			ScaleVector(headOffset, bodylength*0.5);  
			
			if(DEBUG)ShowDir(1, bodyPos, headOffset, 0.06, GetVectorLength(headOffset));	
			if(DEBUG)ShowDir(1, bodyPos, footOffset, 0.06, GetVectorLength(footOffset));	
			
			AddVectors(bodyPos, headOffset, headTouchPos);
			AddVectors(bodyPos, footOffset, footTouchPos);	
			
			new bool:b=GetRaySimple(client, headTouchPos, footTouchPos, temp);
			if(b)
			{ 
				if(DEBUG)PrintToChatAll("can not move");
				break;
			}
			
			CopyVector(footTouchPos, colonPos);
			
			new Float:disBody=GetRay(client, bodyPos, cloneAnge , bodyTouchPos, bodyNormal, 0.0-BodyWidth[client]);  
			new Float:disHead=GetRay(client, headTouchPos, cloneAnge , headTouchPos, eyeNormal, 0.0-BodyWidth[client]);  
			new Float:disFoot=GetRay(client, footTouchPos, cloneAnge , footTouchPos, footNormal, 0.0-BodyWidth[client]);  


			
			if(disBody>BodyWidth[client]*2.0)
			{
				Jump(client, false, 50.0);				 
				return;
			}
			new bool:needrotatenormal=false;
			if(disHead>BodyWidth[client] )
			{
				disHead=BodyWidth[client] ;
				needrotatenormal=true;
			}
			if(disFoot>BodyWidth[client] )
			{
				disFoot=BodyWidth[client]  ;
				needrotatenormal=true;
			}
			new Float:ft=disHead-disFoot;
			
			if(needrotatenormal)
			{
		 
				ft=ArcSine(ft/SquareRoot( ft*ft +bodylength*0.5*bodylength*0.5 ));
				GetVectorCrossProduct(bodyNormal, headOffset, temp); 
				RotateVector(temp, normal, ft*0.5, normal); 
				CopyVector(normal, normal);
			}
			else
			{
				CopyVector(bodyNormal, normal);
			}
			if(DEBUG)ShowDir(2, headTouchPos ,eyeNormal, 0.06);
			if(DEBUG)ShowDir(3, footTouchPos ,footNormal, 0.06);
			if(DEBUG)ShowDir(1, bodyTouchPos, bodyNormal, 0.06);	

			
			CopyVector(headOffset ,moveDir);
			NormalizeVector(moveDir, moveDir); 
			ScaleVector(moveDir, ClimbSpeed[client]*intervual);  
			
			CopyVector(bodyTouchPos, bodyPos); 
			
			if(moveforward)
			{
				playrate=PlayBackRate[client]; 
				AddVectors(colonPos, moveDir, colonPos);
				AddVectors(bodyPos, moveDir, bodyPos);
			}
			else if(moveback)
			{
			 
				playrate=0.0-PlayBackRate[client];
				SubtractVectors(colonPos, moveDir,colonPos );
				SubtractVectors(bodyPos, moveDir, bodyPos);
			 
			}
			
			CopyVector(bodyPos,clientPos);
			clientPos[2]-=bodylength*0.5;
			TeleportEntity(client,  clientPos, NULL_VECTOR, NULL_VECTOR); 
			TeleportEntity(clone,  colonPos, cloneAnge, NULL_VECTOR); 
			CopyVector(bodyPos, BodyPos[client] );  
			CopyVector(normal, BodyNormal[client] );  
			break;
		}
		SetEntPropFloat(clone, Prop_Send, "m_flPlaybackRate", playrate);			
	}
	else
	{
		Stop(client);
	}
	return;
}
/**
 * create a dummy body
 */
CreateClone(client)
{
	decl Float:vAngles[3];
	decl Float:vOrigin[3];
	GetClientAbsOrigin(client,vOrigin);
	GetClientEyeAngles(client, vAngles);	 
	decl String:playerModel[42]; 
	GetEntPropString(client, Prop_Data, "m_ModelName", playerModel, sizeof(playerModel)); 
	new iAnim=GetModelInfo(playerModel, ClimbSpeed[client] ,PlayBackRate[client], BodyWidth[client]); 
	new clone=0;
	if(iAnim>0)
	{
		clone = CreateEntityByName("prop_dynamic_override"); //prop_dynamic
		SetEntityModel(clone, playerModel);  
	 
		decl Float:vPos[3], Float:vAng[3];
		vPos[0] = -0.0; 
		vPos[1] = -0.0;
		vPos[2] = -30.0;
		
		vAng[2] = -90.0;
		vAng[0] = -90.0;
		vAng[1] =0.0;
	 
		TeleportEntity(clone,  vOrigin, vAngles, NULL_VECTOR); 
		
		
		SetEntProp(clone, Prop_Send, "m_nSequence", iAnim);
		SetEntPropFloat(clone, Prop_Send, "m_flPlaybackRate", 1.0); 
		
		SetEntPropFloat(clone, Prop_Send, "m_fadeMinDist", 10000.0); 
		SetEntPropFloat(clone, Prop_Send, "m_fadeMaxDist", 20000.0); 
		
		if(L4D2Version && GetClientTeam(client)==2)
		{
			SetEntProp(clone, Prop_Send, "m_iGlowType", 3);
			SetEntProp(clone, Prop_Send, "m_nGlowRange", 0);
			SetEntProp(clone, Prop_Send, "m_nGlowRangeMin", 600);
			new red=0;
			new gree=151;
			new blue=0;
			SetEntProp(clone, Prop_Send, "m_glowColorOverride", red + (gree * 256) + (blue* 65536)); 
		} 
	}
	return clone;
}

 
SaveWeapon(client )
{ 
	client=client+1;
}
RestoreWeapon(client )
{ 
	client=client+1;
}
bool:IsVilidPlayer(client)
{
	if(client>0 && IsClientInGame(client) && IsPlayerAlive(client))return true;
	else return false;
}
GetModelInfo(String:model[], &Float:speedvalue , &Float:playbackrate, &Float:bodywidth)
{
	new anim=0;	
	new speed =0;
	new Float:S=0.0;
	bodywidth=gbodywidth;
	new model_type=0;
	if(StrContains(model, "survivor_teenangst")!=-1)
	{ 
		if(L4D2Version)	anim = 633;
		else anim = 494;
		speed=ZOMBIECLASS_SURVIVOR; 
		S=30.0;
		model_type=model_zoey;
	}
	else if(StrContains(model, "survivor_manager")!=-1)
	{
		if(L4D2Version)	anim = 514;
		else anim = 516;
		speed=ZOMBIECLASS_SURVIVOR; 
		S=30.0;
		model_type=model_louis;
	}
	else if(StrContains(model, "survivor_namvet")!=-1)
	{
		if(L4D2Version)	anim = 514;
		else 	anim = 516;
		speed=ZOMBIECLASS_SURVIVOR; 
		S=30.0;
		model_type=model_bill;
	}
	else if(StrContains(model, "survivor_biker")!=-1){ anim = 517;speed=ZOMBIECLASS_SURVIVOR; S=30.0; model_type=model_francis;}
	else if(StrContains(model, "gambler")!=-1){ anim = 605;speed=ZOMBIECLASS_SURVIVOR;S=30.0;model_type=model_bill; model_type=model_nick; }
 	else if(StrContains(model, "producer")!=-1){ anim = 614;speed=ZOMBIECLASS_SURVIVOR; S=30.0; model_type=model_rochelle;}
	else if(StrContains(model, "coach")!=-1){ anim = 606;speed=ZOMBIECLASS_SURVIVOR; S=30.0; model_type=model_coach;}
 	else if(StrContains(model, "mechanic")!=-1){ anim = 610;speed=ZOMBIECLASS_SURVIVOR; S=30.0; model_type=model_ellis;}
	else if(StrContains(model, "hulk")!=-1)
	{
		if(L4D2Version)anim=25;
		else anim = 23;
		speed=ZOMBIECLASS_TANK; 
		if(L4D2Version)S=50.0;
		else S=70.0;
		model_type=model_tank;
	}
	else if(StrContains(model, "hunter")!=-1){ anim = 77;speed=ZOMBIECLASS_HUNTER;S=70.0; model_type=model_hunter;}
	else if(StrContains(model, "smoker")!=-1){ anim = 34;speed=ZOMBIECLASS_SMOKER; S=70.0; bodywidth=25.0; model_type=model_smoker;}
	else if(StrContains(model, "boomette")!=-1){ anim = 34;speed=ZOMBIECLASS_BOOMER; S=50.0; model_type=model_boomer_female;}
	else if(StrContains(model, "boomer")!=-1) 
	{
		if(L4D2Version)anim=35;
		else anim = 32;
		speed=ZOMBIECLASS_BOOMER; 
		S=60.0;
		model_type=model_boomer;
	}

 	else if(StrContains(model, "jockey")!=-1){ anim = 12;speed=ZOMBIECLASS_JOCKEY; S=60.0;model_type=model_jockey;}
	else if(StrContains(model, "spitter")!=-1){ anim = 14;speed=ZOMBIECLASS_SPITTER; S=70.0; model_type=model_spitter;}
	else if(StrContains(model, "charger")!=-1){ anim = 37;speed=ZOMBIECLASS_CHARGER; S=70.0;bodywidth=25.0;model_type=model_charger;}
	speedvalue=GetConVarFloat(l4d_climb_speed[speed])*GetConVarFloat(l4d_climb_speed[0]);
	
	playbackrate = 1.0+(speedvalue-S)/S;
	if(model_type>0)
	{ 
		new d=GetConVarInt(l4d_climb_anim[model_type]);
		if(d>0)anim=d;
	}
	if(DEBUG)PrintToChatAll(" body width %f  speed %f playerback %f" , bodywidth,speedvalue, playbackrate);
	
	return anim;
}

 
VisiblePlayer(client, bool:visible=true)
{
	if(visible)
	{
		SetEntityRenderMode(client, RENDER_NORMAL);
		SetEntityRenderColor(client, 255, 255, 255, 255);		 
	}
    else
	{
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		SetEntityRenderColor(client, 0, 0, 0, 0);
	} 
}

new Float:RayVec[3];
/* 
* Calculate a ray start from pos1 to pos2, 
* output: hitpos is collision positon 
*/
bool:GetRaySimple(client, Float:pos1[3] , Float:pos2[3], Float:hitpos[3])
{
	new Handle:trace ;
	new bool:hit=false;  
	trace= TR_TraceRayFilterEx(pos1, pos2, MASK_SOLID, RayType_EndPoint, DontHitColoeAndOxygentank, client); 
	if(TR_DidHit(trace))
	{			
		 
		TR_GetEndPosition(hitpos, trace); 
		hit=true;
	}
	CloseHandle(trace); 
	return hit;
}
/* 
* Calculate a ray start from pos, 
* output: hitpos is collision positon, normal is the collision plane's normal vector.
* return:distance between pos and hitpos
*/
Float:GetRay(client, Float:pos[3] , Float:angle[3], Float:hitpos[3], Float:normal[3], Float:offset=0.0)
{
	new Handle:trace ;
	new Float:ret=9999.0;
	trace= TR_TraceRayFilterEx(pos, angle, MASK_SOLID, RayType_Infinite, TraceRayDontHitSelfAndColoe, client); 
	if(TR_DidHit(trace))
	{			
		CopyVector(pos, RayVec);
		TR_GetEndPosition(hitpos, trace);
		TR_GetPlaneNormal(trace, normal);
		NormalizeVector(normal, normal); 
		if(offset!=0.0)
		{
			decl Float:t[3];
			GetAngleVectors(angle, t, NULL_VECTOR, NULL_VECTOR );
			NormalizeVector(t, t);
			ScaleVector(t, offset);
			AddVectors(hitpos, t, hitpos); 
		}
		ret=GetVectorDistance(RayVec,hitpos);
		
	}
	CloseHandle(trace); 
	return ret;
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
public bool:DontHitSelf(entity, mask, any:data)
{
	if(entity == data) 
	{
		return false; 
	}
	return true;
}
//draw line between pos1 and pos2
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
//draw line between pos1 and pos2
ShowPos(color, Float:pos1[3], Float:pos2[3],Float:life=10.0, Float:length=200.0, Float:width1=1.0, Float:width2=11.0)
{
	decl Float:t[3];
	if(length!=0.0)
	{
		SubtractVectors(pos2, pos1, t);	 
		NormalizeVector(t,t);
		ScaleVector(t, length);
		AddVectors(pos1, t,t);
	}
	else 
	{
		CopyVector(pos2,t);
	}
	ShowLaser(color,pos1, t, life,   width1, width2);
}
//draw line start from pos, the line's drection is dir.
ShowDir(color,Float:pos[3], Float:dir[3],Float:life=10.0, Float:length=200.0, Float:width1=1.0, Float:width2=11.0)
{
	decl Float:pos2[3];
	CopyVector(dir, pos2);
	NormalizeVector(pos2,pos2);
	ScaleVector(pos2, length);
	AddVectors(pos, pos2,pos2);
	ShowLaser(color,pos, pos2, life,   width1, width2);
}
//draw line start from pos, the line's angle is angle.
ShowAngle(color,Float:pos[3], Float:angle[3],Float:life=10.0, Float:length=200.0, Float:width1=1.0, Float:width2=11.0)
{
	decl Float:pos2[3];
	GetAngleVectors(angle, pos2, NULL_VECTOR, NULL_VECTOR);
 
	NormalizeVector(pos2,pos2);
	ScaleVector(pos2, length);
	AddVectors(pos, pos2,pos2);
	ShowLaser(color,pos, pos2, life, width1, width2);
}
Float:AngleCovert(Float:angle)
{
	return angle/180.0*Pai;
}
/* 
* angle between x1 and x2
*/
Float:GetAngle(Float:x1[3], Float:x2[3])
{
	return ArcCosine(GetVectorDotProduct(x1, x2)/(GetVectorLength(x1)*GetVectorLength(x2)));
}
/* 
* Signed angle  between x1 and x2
*/
Float:GetAngleWithSign(Float:n[3], Float:v1[3], Float:v2[3] )
{
	new Float:t[3];
	GetVectorCrossProduct(v1, n, t);
	NormalizeVector(t, t);
	new Float:s=GetAngle(t, v2);
	new Float:r=0.0;
	if(s<Pai/2.0)
	{
		r=GetAngle(v1, v2);
	}
	else
	{
		r=0.0-GetAngle(v1, v2);
	}
	return r;
}
/* 
* get vector t's projection on a plane, the plane's normal vector is n, r is the result
*/
GetProjection(Float:n[3], Float:t[3], Float:r[3])
{
	new Float:A=n[0];
	new Float:B=n[1];
	new Float:C=n[2];
	
	new Float:a=t[0];
	new Float:b=t[1];
	new Float:c=t[2];
	
	new Float:p=-1.0*(A*a+B*b+C*c)/(A*A+B*B+C*C);
	r[0]=A*p+a;
	r[1]=B*p+b;
	r[2]=C*p+c; 
	//AddVectors(p, r, r);
}
/* 
* rotate vector vec around vector direction alfa degrees
*/
RotateVector(Float:direction[3], Float:vec[3], Float:alfa, Float:result[3])
{
  /*
   on rotateVector (v, u, alfa)
  -- rotates vector v around u alfa degrees
  -- returns rotated vector 
  -----------------------------------------
  u.normalize()
  alfa = alfa*pi()/180 -- alfa in rads
  uv = u.cross(v)
  vect = v + sin (alfa) * uv + 2*power(sin(alfa/2), 2) * (u.cross(uv))
  return vect
	end
   */
   	decl Float:v[3];
	CopyVector(vec,v);
	
	decl Float:u[3];
	CopyVector(direction,u);
	NormalizeVector(u,u);
	
	decl Float:uv[3];
	GetVectorCrossProduct(u,v,uv);
	
	decl Float:sinuv[3];
	CopyVector(uv, sinuv);
	ScaleVector(sinuv, Sine(alfa));
	
	decl Float:uuv[3];
	GetVectorCrossProduct(u,uv,uuv);
	ScaleVector(uuv, 2.0*Pow(Sine(alfa*0.5), 2.0));	
	
	AddVectors(v, sinuv, result);
	AddVectors(result, uuv, result);
	
 
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
		ZOMBIECLASS_TANK=8;
		L4D2Version=true;
	}	
	else
	{
		ZOMBIECLASS_TANK=5;
		L4D2Version=false;
	}
 
}
public OnMapStart()
{
 
	if(L4D2Version)
	{
		g_sprite = PrecacheModel("materials/sprites/laserbeam.vmt");	
		 
	}
	else
	{
		g_sprite = PrecacheModel("materials/sprites/laser.vmt");	
		 
	}

}
 
public bool:TraceRayDontHitSelfAndColoe(entity, mask, any:data)
{
	if(entity == data) 
	{
		return false; 
	}
	else if(data>=1 && data<=MaxClients)
	{
		if(entity==Colon[data])
		{
			return false; 
		}
	}
	return true;
}
new String:g_classname[64];
public bool:DontHitColoeAndOxygentank(entity, mask, any:data)
{
	if(entity == data) 
	{
		return false; 
	}
	else if(data>=1 && data<=MaxClients)
	{
		if(entity==Colon[data])
		{
			return false; 
		}
	}
	 
	{
		GetEdictClassname(entity, g_classname, sizeof(g_classname));
		
		if(StrEqual(g_classname, "prop_physics"))
		{
			GetEntPropString(entity, Prop_Data, "m_ModelName", g_classname, sizeof(g_classname));			
			if(StrEqual(g_classname, "models/props_equipment/oxygentank01.mdl"))
			{
				return false;
			}
		}
	}
	return true;
}
public Action:ShowInfo(Handle:timer, any:client)
{
	if(L4D2Version )DisplayHint(INVALID_HANDLE, client);
	else PrintToChat(client, "\x03Press \x04use \x03button to \x04climb \x03when you jump toward a surface");
}
//code from "DJ_WEST"

public Action:DisplayHint(Handle:h_Timer, any:i_Client)
{
	 
	if ( IsClientInGame(i_Client))	ClientCommand(i_Client, "gameinstructor_enable 1");
	CreateTimer(1.0, DelayDisplayHint, i_Client);
}
public Action:DelayDisplayHint(Handle:h_Timer, any:i_Client)
{
 
	DisplayInstructorHint(i_Client, "Press use button to climb when you jump toward a surface", "+use");
	 
}
public DisplayInstructorHint(i_Client, String:s_Message[256], String:s_Bind[])
{
	decl i_Ent, String:s_TargetName[32], Handle:h_RemovePack;
	
	i_Ent = CreateEntityByName("env_instructor_hint");
	FormatEx(s_TargetName, sizeof(s_TargetName), "hint%d", i_Client);
	ReplaceString(s_Message, sizeof(s_Message), "\n", " ");
	DispatchKeyValue(i_Client, "targetname", s_TargetName);
	DispatchKeyValue(i_Ent, "hint_target", s_TargetName);
	DispatchKeyValue(i_Ent, "hint_timeout", "5");
	DispatchKeyValue(i_Ent, "hint_range", "0.01");
	DispatchKeyValue(i_Ent, "hint_color", "255 255 255");
	DispatchKeyValue(i_Ent, "hint_icon_onscreen", "use_binding");
	DispatchKeyValue(i_Ent, "hint_caption", s_Message);
	DispatchKeyValue(i_Ent, "hint_binding", s_Bind);
	DispatchSpawn(i_Ent);
	AcceptEntityInput(i_Ent, "ShowHint");
	
	h_RemovePack = CreateDataPack();
	WritePackCell(h_RemovePack, i_Client);
	WritePackCell(h_RemovePack, i_Ent);
	CreateTimer(5.0, RemoveInstructorHint, h_RemovePack);
}
	
public Action:RemoveInstructorHint(Handle:h_Timer, Handle:h_Pack)
{
	decl i_Ent, i_Client;
	
	ResetPack(h_Pack, false);
	i_Client = ReadPackCell(h_Pack);
	i_Ent = ReadPackCell(h_Pack);
	CloseHandle(h_Pack);
	
	if (!i_Client || !IsClientInGame(i_Client))
		return Plugin_Handled;
	
	if (IsValidEntity(i_Ent))
			RemoveEdict(i_Ent);
	
	ClientCommand(i_Client, "gameinstructor_enable 0");
		
	DispatchKeyValue(i_Client, "targetname", "");
		
	return Plugin_Continue;
}
/*
* code from SilverShot, [L4D2] Incapped Crawling with Animation
* */
GotoThirdPerson(client)
{
	SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", 0);
	SetEntProp(client, Prop_Send, "m_iObserverMode", 1);
	SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0);
}

GotoFirstPerson(client)
{
	SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", -1);
	SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
	SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
} 
GotoThirdPersonVisible(client)
{
	SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", -1);
	SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
	SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
}