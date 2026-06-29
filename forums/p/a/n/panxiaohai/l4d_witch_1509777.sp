#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdktools_functions>
#include <sdkhooks>

 
#define Pai 3.14159265358979323846 
#define DEBUG false  

#define AccelerationOfGravity (9.8*100.0)
#define State_Ducking	0
#define State_Crawl	1
#define State_Walk  2
#define State_Run 3
#define State_RunCrazy 12
#define State_Attack1 4
#define State_Attack2 5
#define State_Idle 6
#define State_Threaten 7
#define State_LadderUp 8
#define State_LadderDown 9
#define State_JumpUp 10
#define State_JumpDown 11

#define Enemy_Type_CI 1
#define Enemy_Type_Survivor 2
#define Enemy_Type_Infected 3
#define Enemy_Type_Door 4
#define Enemy_Type_Ohter 5

new String:SoundAttack[5][64]={"/npc/witch/voice/attack/female_shriek_1.wav", "/npc/witch/voice/attack/female_shriek_2.wav", " ", " ", " "};
new String:SoundPriAttackHit[5][64]={"/npc/witch/hit/hit_slimesplat3.wav", "/npc/witch/hit/hit_slimesplat4.wav", "/npc/witch/hit/hit_slimesplat5.wav", " ", " "};
new String:SoundSecAttackHit[5][64]={"/npc/infected/hit/hit_punch_03.wav", "", "", " ", " "};

new HookType=SDKHook_PostThink;
 
new anim_ducking=4;
new anim_ducking_angry=27;
new anim_crawl=38;
new anim_standing_angry=2;
new anim_run=8; //8
new anim_run_crazy=6;// 6,7
new anim_walk=10; //10 ,11
new anim_idle=10;
new anim_jump=58;
new anim_fall =54;
new anim_threaten=31; // 31, 28, 29, 40, 7
new anim_attack1[2]={17, 19}; //16 18  boold 17, 19 
new anim_attack2=32;
new anim_ladder_up=70;
new anim_ladder_down=70;
new anim_lookaround=5;

new witch_attack_damage1=110 ;
new witch_attack_damage2=20 ;

new Float:witch_primary_attack_duration=1.6;
new Float:witch_secondary_attack_duration=0.2;
new Float:witch_crawl_speed=90.0;
new Float:witch_walk_speed=110.0;
new Float:witch_run_speed=215.0;
new Float:witch_jump_speed=500.0;
new Float:witch_fall_speed=400.0;

new ZOMBIECLASS_TANK=	5;
 
new Buttons[MAXPLAYERS+1]  ; 
new Float:AttackStartTime[MAXPLAYERS+1];
new Float:AttackingTime[MAXPLAYERS+1];
new Float:WitchPos[MAXPLAYERS+1][3];
new Float:LastTime[MAXPLAYERS+1] ; 
new Float:WitchVolicityVertical[MAXPLAYERS+1] ; 
new Float:WitchVolicityHorizontal[MAXPLAYERS+1] ; 
new Float:WitchMoveDir[MAXPLAYERS+1][3] ;
new bool:WitchJumped[MAXPLAYERS+1]  ;
new WitchState[MAXPLAYERS+1]  ;
new WitchSequence[MAXPLAYERS+1]  ;
new WitchId[MAXPLAYERS+1]; 
new WitchTestId[MAXPLAYERS+1]; 
new Camera[MAXPLAYERS+1]; 
new GameMode;
new L4D2Version;

new g_sprite;
new g_ghostoffest;

new Handle:l4d_witch_enable ;  
new Handle:l4d_witch_team ; 
new Handle:l4d_witch_damage_primary ; 
new Handle:l4d_witch_damage_secondary ; 
 
public Plugin:myinfo = 
{
	name = "Witch Play",
	author = "Pan Xiaohai, thanks to DJ_WEST",
	description = "",
	version = "1.1",	
}
 
public OnPluginStart()
{
	GameCheck();  

	l4d_witch_enable = CreateConVar("l4d_witch_enable", "2", "  0:disable, 1:enable in coop mode, 2: enable in all mode ", FCVAR_PLUGIN);
	l4d_witch_team = CreateConVar("l4d_witch_team", "1", "  1:enable for survivor and infected, 2:enable for survivor, 3:enable for infected ", FCVAR_PLUGIN);	
	l4d_witch_damage_primary = CreateConVar("l4d_witch_damage_primary", "100", "damage for primary attack", FCVAR_PLUGIN);	
	l4d_witch_damage_secondary = CreateConVar("l4d_witch_damage_secondary", "20", "damage for secondary attack", FCVAR_PLUGIN);	
	
	AutoExecConfig(true, "l4d_witch"); 
	
	HookEvent("player_bot_replace", player_bot_replace );	
	HookEvent("player_death", player_death);
	HookEvent("player_jump", player_jump);
	HookEvent("witch_spawn", witch_spawn);
	HookEvent("round_start", round_end);
	HookEvent("round_end", round_end);
	HookEvent("finale_win", round_end);
	HookEvent("mission_lost", round_end);
	HookEvent("map_transition", round_end);	 
	
	g_ghostoffest=FindSendPropInfo("CTerrorPlayer", "m_isGhost");
	Init();
	ResetAllState();
}
public Action:round_end(Handle:event, const String:name[], bool:dontBroadcast)
{
	ResetAllState();
}
public player_bot_replace(Handle:Spawn_Event, const String:Spawn_Name[], bool:Spawn_Broadcast)
{
	if(GetConVarInt(l4d_witch_enable)==0)return; 
	new client = GetClientOfUserId(GetEventInt(Spawn_Event, "player"));
	new bot = GetClientOfUserId(GetEventInt(Spawn_Event, "bot")); 
	Stop(client);
	Stop(bot); 
}
public Action:player_death(Handle:hEvent, const String:strName[], bool:DontBroadcast)
{
	if(GetConVarInt(l4d_witch_enable)==0)return;
	new victim = GetClientOfUserId(GetEventInt(hEvent, "userid")); 
	Stop(victim);  
}
public Action:player_jump(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid")); 
	if(IsFakeClient(client))return; 
	new b=GetClientButtons(client);
	if((b & IN_ZOOM) || (b & IN_DUCK))
	{ 
		new bool:isGhost=false;
		if(GetClientTeam(client)==3 && GetEntData(client, g_ghostoffest, 1))isGhost=true; 
		if(!CanUse(client, isGhost))return;
		Start(client);
	} 
	return;
 }
public Action:witch_spawn(Handle:h_Event, const String:s_Name[], bool:b_DontBroadcast)
{
 
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && !IsFakeClient(i))
		{
			new bool:isGhost=false;
			if(GetClientTeam(i)==3 && GetEntData(i, g_ghostoffest, 1))isGhost=true; 
			if(CanUse(i, isGhost))
			{
				CreateTimer(GetRandomFloat(3.0, 6.0), ShowInfo, i); 
			}
		}
	}
}
 bool:CanUse(client, bool:isGhost=false)
 {
 	new mode=GetConVarInt(l4d_witch_enable);
	if(mode==0)return false;
	if(mode==1 && GameMode==2)return false;
	if(client==0)return true;
	if(IsClientInGame(client))
	{
		if(IsPlayerAlive(client))
		{
			new teammode=GetConVarInt(l4d_witch_team);
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
					return true;
				}
				else return false;
			}
			return true;
		}
		return true;
	}
	else return true; 
}
 
new g_anim=0; 
 
Start(client)
{
	new witch=GetClientAimTarget(client, false);  
	if(witch <=0)return;
	decl String:classname[64];
	GetEdictClassname(witch, classname, sizeof(classname));
	if(!StrEqual(classname, "witch") )
	{
		return;
	} 
	new Float:witchPos[3];
	new Float:clientPos[3];
	GetClientAbsOrigin(client, clientPos);
	GetEntPropVector(witch, Prop_Send, "m_vecOrigin", witchPos); 
	if(GetVectorDistance(clientPos, witchPos)>200.0)
	{
		PrintHintText(client, "It is too far from witch");
		return;
	}
	 
	/* test code
	new button=GetClientButtons(client);
	if(button & IN_DUCK)
	{ 
	   WitchTestId[client]=witch;
	   PrintToChatAll("TEST ");
	   PrintToChatAll("test %d", WitchTestId[client]);
	   return;
	}
	*/
	new c=CreateCamera(witch);
	SetClientViewEntity(client, c);
	Camera[client]=c;
	SetEntityMoveType(client, MOVETYPE_NONE);
	LastTime[client]=GetEngineTime();
	WitchId[client]=witch;
	WitchJumped[client]=false;
	WitchState[client]=State_Ducking;
	SDKUnhook( client, HookType,  PreThink); 
	SDKHook(client, HookType,  PreThink); 
	SetEntPropFloat(witch, Prop_Send, "m_rage", 0.0 ); 
	SetEntProp(witch, Prop_Send, "m_mobRush", 0);
}
Stop(client)
{
	SDKUnhook( client, HookType,  PreThink); 
	if(DEBUG)PrintToChatAll("lost control witch %d ", WitchId[client]);
	new witch=WitchId[client];
	WitchId[client]=0; 
	if(client >0 && IsClientInGame(client) )
	{
		SetClientViewEntity(client, client);
		SetEntityMoveType(client, MOVETYPE_WALK);
	}
	
	if(witch>0 && IsValidEdict(witch) && IsValidEntity(witch) )
	{
		new rush=GetEntProp(witch, Prop_Send, "m_mobRush" );	
		new burning=false;
		if(L4D2Version)burning=GetEntProp(witch, Prop_Send, "m_bIsBurning");
		if(!rush  && !burning)
		{
			new flag=GetEntProp(witch, Prop_Send, "m_fFlags");		
			SetEntProp(witch, Prop_Send, "m_nSequence" ,anim_ducking); 
			SetEntPropFloat(witch, Prop_Send, "m_flPlaybackRate" ,1.0); 
			SetEntPropFloat(witch, Prop_Send, "m_rage", 0.0 ); 
			SetEntProp(witch, Prop_Send, "m_fFlags", flag | FL_DUCKING); 
			if(DEBUG)PrintToChatAll("reset witch state"); 
		}
	}
}
public PreThink(client)
{
	new witch=WitchId[client]; 
	if(witch>0 && IsValidEdict(witch) && IsValidEntity(witch) )
	{
		new Float:time=GetEngineTime( );
		new Float:intervual=time-LastTime[client]; 
		if(IsClientInGame(client) && IsPlayerAlive(client))
		{
			Process(client, time ,intervual);
		}
		else
		{
			Stop(client);
		}
		
		LastTime[client]=time;
	}
	else Stop(client);
	/* test code
	if(WitchTestId[client]>0)
	{
		new witch=WitchTestId[client];
		new m=GetEntProp(witch, Prop_Send, "m_nSequence" ); 
		new Float:playrate = GetEntPropFloat(witch, Prop_Send, "m_flPlaybackRate"); 
		PrintToChatAll("m_nSequence %d rate %f",  m, playrate);
	} 
	*/
	return  ;

}
 
bool:Process(client, Float:time, Float:intervual )
{
	new witch=WitchId[client];  
	SetEntityMoveType(client, MOVETYPE_NONE);
	new rush=GetEntProp(witch, Prop_Send, "m_mobRush" );	
	new button=GetClientButtons(client);
	new bool:change=false;
	 
	decl Float:temp[3];
	 
	decl Float:frontDir[3]; 
	decl Float:up[3];
	decl Float:downAngle[3];
	decl Float:rightDir[3]; 
	decl Float:witchAngle[3]; 
	decl Float:cameraAngle[3]; 
	decl Float:witchPos[3]; 
	decl Float:newWitchPos[3];
	decl Float:clientAngle[3];
	decl Float:hitPos[3]; 
	decl Float:normal[3];
	decl Float:moveDir[3];
	decl Float:newMoveDir[3]; 
	new Float:moveSpeed; 
	new Float:playbackRateSign=1.0; 
	SetVector(up, 0.0, 0.0, 1.0); 
	GetClientEyeAngles(client, clientAngle);
	
	SetVector(witchAngle, 0.0, clientAngle[1], 0.0);
	SetVector(cameraAngle, clientAngle[0], 0.0, 0.0);
	GetEntPropVector(witch, Prop_Send, "m_vecOrigin", witchPos);
	 
	GetAngleVectors(witchAngle, frontDir, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(frontDir,frontDir); 
	SetVector(moveDir, 0.0, 0.0, 0.0);
	if(button & IN_USE)
	{
		if(DEBUG)PrintToChatAll("lost control");
		Stop(client);
		return false;
	}
	if(rush)
	{ 
		return false;
	}
	if (L4D2Version)
	{	
		if(GetEntProp(witch, Prop_Send, "m_bIsBurning"))return false; 
	}
	if(((button & IN_ATTACK) && (button & IN_ATTACK2)) || (button & IN_RELOAD))
	{
		SetEntPropFloat(witch, Prop_Send, "m_rage", 1.0);
		SetEntProp(witch, Prop_Send, "m_mobRush", 1);
		if(DEBUG)PrintToChatAll("witch mad");
		return false;
	}
 
	new flag= GetEntityFlags(witch);
	new bool:move=false;
	new bool:action=false;
	new bool:duck=false;
	new bool:jump=false;
	new bool:angry=false;
	new bool:attack1=false;
	new bool:attack2=false;
	new bool:zoom=false;
	new bool:onground=false;
	new bool:idle=true;
	new bool:fall=false; 
	new bool:attackstart=false;
	onground=!(GetEntPropEnt(witch, Prop_Data, "m_hGroundEntity")==-1);

 
	if(WitchState[client]!=State_Attack1 )
	{
		if(button & IN_MOVELEFT)
		{ 
			GetAngleVectors(witchAngle, NULL_VECTOR, rightDir, NULL_VECTOR);
			NormalizeVector(rightDir,rightDir); 
			SubtractVectors(moveDir,rightDir,moveDir);
			move=true; 
		}
		if(button & IN_MOVERIGHT)
		{
			GetAngleVectors(witchAngle, NULL_VECTOR, rightDir, NULL_VECTOR);
			NormalizeVector(rightDir,rightDir); 
			AddVectors(moveDir,rightDir,moveDir);
			move=true;	 
		}
		if(button & IN_FORWARD)
		{ 
			AddVectors(moveDir,frontDir,moveDir);
			playbackRateSign=-1.0;
			move=true;			
		}
		else if(button & IN_BACK)
		{
			SubtractVectors(moveDir, frontDir, moveDir); 
			playbackRateSign=-1.0; 
			move=true; 
		}
		if(button & IN_JUMP)
		{
			jump=true; 
			NormalizeVector(moveDir, moveDir);
			AddVectors(moveDir,frontDir,moveDir);
			WitchVolicityVertical[client]=witch_jump_speed;
			WitchVolicityHorizontal[client]=moveSpeed;
			WitchJumped[client]=true; 
			idle=false;
			if(DEBUG)PrintToChatAll("start JUMP");
			WitchState[client]=State_JumpUp;
			moveSpeed=0.0;
		} 
		if(button & IN_ATTACK)
		{
			move=false;
			jump=false;
			attack1=true;
			playbackRateSign=1.0;  
			idle=false;
			moveSpeed=0.0;
			if(WitchState[client]!=State_Attack1)
			{
				AttackStartTime[client]=time;
				AttackingTime[client] =time+witch_primary_attack_duration*0.4;
				attackstart=true;   
			} 
			WitchState[client]=State_Attack1;
		}
		else if(button & IN_ATTACK2)
		{
			playbackRateSign=1.0;
			move=false;
			jump=false;
			angry=true;  
			idle=false;
			attack2=true;
			moveSpeed=0.0;
			if(WitchState[client]!=State_Attack2)
			{
				AttackStartTime[client]=time;
				AttackingTime[client] = time  ;
				attackstart=true;  
			} 
			WitchState[client]=State_Attack2;
		}
		else if(button & IN_ZOOM)
		{ 
			jump=false;
			angry=true;  
			idle=false;
			zoom=true;
			playbackRateSign=1.0; 
			WitchState[client]=State_Threaten;
		}
		if(!onground)
 		{
			move=true;
			fall=true; 
			WitchState[client]=State_JumpDown; 				
			SetVector(newMoveDir, 0.0, 0.0, 0.0-witch_fall_speed); 
		} 
		if(move)
		{ 	
			if(fall)
			{
				SetVector(downAngle, 90.0, 0.0, 0.0);
				CopyVector(witchPos,temp);
				temp[2]+=10.0;
				new Float:dis=GetRay(witch, temp, downAngle, hitPos, normal);
				if(dis<10.0)
				{
					move=false;
					fall=false; 
				}
				else
				{
					CopyVector(newMoveDir,temp);
					ScaleVector(temp, intervual);
					AddVectors(witchPos,temp,newWitchPos); 	 
				}
			}
			else
			{
				moveSpeed =witch_walk_speed;
				WitchState[client]=State_Walk;
				if(button & IN_SPEED)
				{ 
					moveSpeed =witch_run_speed;
					WitchState[client]=State_Run;
				}
				else if(button & IN_DUCK)
				{
					duck=true;	 
					moveSpeed =witch_crawl_speed; 
					WitchState[client]=State_Crawl;
				}
				else if(button & IN_ZOOM)
				{
					 
					moveSpeed =witch_run_speed; 
					WitchState[client]=State_RunCrazy;
				}

				idle=false;
				NormalizeVector(moveDir,moveDir);  
				SetVector(downAngle, 90.0, 0.0, 0.0);
				CopyVector(witchPos,temp);
				temp[2]+=10.0;
				new Float:dis=GetRay(witch, temp, downAngle, hitPos, normal);
				GetProjection(normal, moveDir, newMoveDir);
				NormalizeVector(newMoveDir,newMoveDir);
				//PrintToChatAll("dis %f", dis);
				//ShowDir(0, temp, newMoveDir, 0.06);				 
				//ShowDir(1, temp, normal, 0.06);				
				
				CopyVector(newMoveDir,temp);
				ScaleVector(temp, moveSpeed*intervual);
				AddVectors(witchPos,temp,newWitchPos); 	
				
				decl Float:headPos[3];
				decl Float:footPos[3];
				CopyVector(newMoveDir,footPos);
				ScaleVector(footPos, 20.0);
				AddVectors(witchPos,footPos,footPos); 	
				
				CopyVector(footPos, headPos);
				footPos[2]+=15.0; 
				headPos[2]+=65.0; 
				if(duck)headPos[2]-=20.0; 
				 
				new bool:hit1=GetRaySimple(witch, footPos, headPos, temp, false ); 
				if(hit1)
				{
						
					move=false;
					//ShowPos(1, footPos, headPos, 0.06, 0.0, 1.0, 1.0);	
				}
				//else ShowPos(2, footPos, headPos, 0.06, 0.0, 1.0, 1.0);	
				decl Float:offset[3]; 
				if(move)
				{
					CopyVector(newMoveDir, temp);
					temp[2]=0.0;
					GetVectorAngles(temp, temp);
					GetAngleVectors(temp, NULL_VECTOR, temp, NULL_VECTOR);
					NormalizeVector(temp, temp);
					
					CopyVector(temp, offset);
					ScaleVector(offset, -10.0);				
					AddVectors(footPos,offset,footPos); 
					AddVectors(headPos,offset,headPos);
					new bool:hit2=GetRaySimple(witch, footPos, headPos, offset, false );
					 
					if(hit2)
					{					
						move=false;
						//ShowPos(1, footPos, headPos, 0.06, 0.0, 1.0, 1.0);	
					}
					//else ShowPos(2, footPos, headPos, 0.06, 0.0, 1.0, 1.0);	
				}
				if(move)
				{
					CopyVector(temp, offset);
					ScaleVector(offset, 20.0);				
					AddVectors(footPos,offset,footPos); 
					AddVectors(headPos,offset,headPos);
					new bool:hit3=GetRaySimple(witch, footPos, headPos, offset, false );
				 
					if(hit3)
					{					
						move=false;
						//ShowPos(1, footPos, headPos, 0.06, 0.0, 1.0, 1.0);	
					}
					//else ShowPos(2, footPos, headPos, 0.06, 0.0, 1.0, 1.0);	
				}
			}
		}
		else
		{
			if(button & IN_DUCK)
			{
				duck=true; 
				moveSpeed =0.0; 
				WitchState[client]=State_Ducking;
			}
			idle=false;
		} 
		if(idle)
		{
			WitchState[client]=State_Idle;
		}

	}
	new states =WitchState[client];
	new sequence=0;
	new Float:playbackRate=0.0;
	new newFlag=flag;
	new Float:newRage=0.0;
	if(states==State_Ducking)
	{
		sequence=anim_ducking;
		playbackRate=1.0;			
	}
	else if (states==State_Crawl)
	{
		sequence=anim_crawl;
		playbackRate=1.0*playbackRateSign;
		newFlag=flag | FL_DUCKING;
	}
	else if (states==State_Walk)
	{
		sequence=anim_walk; 
		playbackRate=1.0*playbackRateSign; 
		newFlag=flag & ~FL_DUCKING; 
	}
	else if (states==State_Run)
	{
		sequence=anim_run;
		playbackRate=1.0*playbackRateSign;
		newFlag=flag & ~FL_DUCKING; 
	}
	else if (states==State_RunCrazy)
	{
		sequence=anim_run_crazy;
		playbackRate=1.0*playbackRateSign;
		newFlag=flag & ~FL_DUCKING;  
	}
	else if(WitchState[client]==State_JumpDown)
	{
		sequence=anim_fall;
		playbackRate=1.0;		
	}
	else if (states==State_Threaten)
	{
		sequence=anim_threaten;
		playbackRate=1.0 ;
		newFlag=flag & ~FL_DUCKING; 
		newRage=0.8; 
	}
	else if (states==State_Idle)
	{
		sequence=anim_idle;
		playbackRate=1.0 ; 
	} 
	else if (states==State_Attack1)
	{ 
		if(attackstart)
		{
			WitchSequence[client]=anim_attack1[GetRandomInt(0, 1)]; 
			if(DEBUG)PrintToChatAll("attack1 start %f", time);
			EmitSoundToAll(SoundAttack[GetRandomInt(0,1)], 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, witchPos, NULL_VECTOR, false, 0.0);
		}
		sequence=WitchSequence[client];
		playbackRate=1.0 ; 
		newRage=0.0;
		if(time>=AttackingTime[client])
		{
			if(DEBUG)PrintToChatAll("attacking1 %f", time);
			AttackingTime[client]=AttackingTime[client]+witch_primary_attack_duration;
			new v=WitchAttack(client, witch,  witchPos, witchAngle, GetConVarInt(l4d_witch_damage_primary));
			if(v>0)EmitSoundToAll(SoundPriAttackHit[GetRandomInt(0,2)], 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, witchPos, NULL_VECTOR, false, 0.0);
		} 
		if(time>=AttackStartTime[client]+witch_primary_attack_duration)
		{
			WitchState[client]=State_Idle;
			sequence=anim_idle;
			newRage=0.0;
			if(DEBUG)PrintToChatAll("attack1 end %f", time);
		}
		newFlag=flag & ~FL_DUCKING; 
		
	}
	else if (states==State_Attack2)
	{
		sequence=anim_attack2;
		playbackRate=1.0 ; 
		newRage=0.0;
		if(attackstart)
		{
 			if(DEBUG)PrintToChatAll("attack2 start %f", time);
			EmitSoundToAll(SoundAttack[GetRandomInt(0,1)], 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, witchPos, NULL_VECTOR, false, 0.0);
		}
		if(time>=AttackingTime[client])
		{ 
			AttackingTime[client]+=witch_secondary_attack_duration;
			new v=WitchAttack(client, witch,  witchPos, witchAngle, GetConVarInt(l4d_witch_damage_secondary));
			if(v>0)EmitSoundToAll(SoundSecAttackHit[0], 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, witchPos, NULL_VECTOR, false, 0.0);
			if(DEBUG)PrintToChatAll("attacking2 %f", AttackingTime[client]);
		} 
		newFlag=flag & ~FL_DUCKING;  
	} 
	new Float:volicity[3];
	 
	if(move)TeleportEntity(witch, newWitchPos, witchAngle,  NULL_VECTOR);
	else TeleportEntity(witch,NULL_VECTOR, witchAngle, volicity);
	/* test code
	if(g_anim>0)
	{
		sequence=g_anim;
		PrintToChatAll("anim %d", g_anim);
	}
	*/
	SetEntProp(witch, Prop_Send, "m_nSequence" ,sequence); 
	SetEntPropFloat(witch, Prop_Send, "m_flPlaybackRate" ,playbackRate);
	SetEntProp(witch, Prop_Send, "m_fFlags", newFlag );
	SetEntPropFloat(witch, Prop_Send, "m_rage", newRage ); 
	
	//new Float:cameraAngle[3];
	GetEntPropVector(Camera[client], Prop_Send, "m_angRotation", cameraAngle);
	cameraAngle[0]=clientAngle[0]/3.0;
	SetEntPropVector(Camera[client], Prop_Send, "m_angRotation", cameraAngle);
	Buttons[client]=button; 
	change=false;
	return change;  
	 
}
new Enemys[MAXPLAYERS+1];
WitchAttack(client, witch , Float:witchPos[3], Float:witchAngle[3], damage)
{
	new Float:pos[3];
	CopyVector(witchPos, pos);
	pos[2]+=30;
	new type;
	new ent=GetEnt(witch, pos, witchAngle, type);
	if(ent>0)
	{
		if(type==Enemy_Type_CI || type==Enemy_Type_Survivor || type==Enemy_Type_Infected)
		{
			DamagePlayer(client, witch, ent, damage);
		}
		else if(type==Enemy_Type_Ohter)
		{
			ThrowEnt(client, ent, witchPos, witchAngle, damage*10.0 ); 
		} 
		else if(type==Enemy_Type_Door)
		{
			DamagePlayer(client, witch, ent, damage*5 ); 
		}  
		return ent;
	}
	pos[2]+=10;
	new enemyCount=0;
	new hit=0;
	decl Float:enemyPos[3];
	decl Float:witchFront[3];
	GetAngleVectors(witchAngle, witchFront, NULL_VECTOR, NULL_VECTOR);
	witchFront[2]==0.0;
	for(new i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{ 
			GetClientAbsOrigin(i, enemyPos);
			new Float:distance=GetVectorDistance(witchPos, enemyPos); 
			if(distance<50.0)
			{
				
				SubtractVectors(enemyPos, witchPos, enemyPos);
				new Float:a=GetAngle(witchFront, enemyPos); 
				if((a*180.0/Pai)<55.0)
				{
					Enemys[enemyCount++]=i;
					
				} 
			}
		}
	}
	for(new i=0; i<enemyCount; i++)
	{
		DamagePlayer(client, witch, Enemys[i], damage);
		if(DEBUG)PrintToChatAll("witch attack %N", Enemys[i]);
		hit=Enemys[i];
	}
	return hit;
}
DamagePlayer(client, witch, victim, damage)
{
	DoPointHurt(victim, damage, client, 0);
}
new g_PointHurt=0;
CreatePointHurt()
{
	new pointHurt=CreateEntityByName("point_hurt");
	if(pointHurt)
	{

		DispatchKeyValue(pointHurt,"Damage","10");
		DispatchKeyValue(pointHurt,"DamageType","2");
		DispatchSpawn(pointHurt);
	}
	else pointHurt=0;
	return pointHurt;
}
new String:N[20];
DoPointHurt(victim, damage, attacker=0, wtype=0)
{
	if(g_PointHurt==0)g_PointHurt=CreatePointHurt();
	if(g_PointHurt > 0)
	{
		if(IsValidEdict(g_PointHurt))
		{
			if(victim>0 && IsValidEdict(victim))
			{		
				Format(N, 20, "target%d", victim);
				DispatchKeyValue(victim,"targetname", N);
				DispatchKeyValue(g_PointHurt,"DamageTarget", N);
				DispatchKeyValue(g_PointHurt,"classname","weapon_pistol_magnum");
				Format(N, 20, "%d", damage);
				DispatchKeyValue(g_PointHurt,"Damage",N);
				AcceptEntityInput(g_PointHurt,"Hurt",(attacker>0)?attacker:-1);
			}
		}
	} 
}


bool:IsHullHit(client, Float:pos1[3] , Float:dir [3], Float:hitpos[3])
{
	 
	new bool:hit=false;  
	new Float:min[3];
	new Float:max[3];
	SetVector(min, -13.0,-13.0, 0.0);
	SetVector(max, 13.0, 13.0, 5.0);
	CopyVector(dir , hitpos);
	NormalizeVector(hitpos, hitpos);
	ScaleVector(hitpos, 53.0);
	AddVectors(pos1,hitpos,hitpos);
	pos1[2]-=15.0;
	 TR_TraceHullFilter(pos1, hitpos, min, max, MASK_SOLID, TraceRayDontHitSelf, client); 
	if(TR_DidHit( ))
	{	 
		TR_GetEndPosition(hitpos ); 
		hit=true;
	}
	pos1[2]+=15.0;
	return hit;
}
new Float:RayVec[3];
/* 
* Calculate a ray start from pos1 to pos2, 
* output: hitpos is collision positon 
*/
bool:GetRaySimple(client, Float:pos1[3] , Float:pos2[3], Float:hitpos[3], bool:hitinfected )
{
	new Handle:trace ;
	new bool:hit=false;  
	if(hitinfected)	trace= TR_TraceRayFilterEx(pos1, pos2, MASK_SOLID, RayType_EndPoint, TraceRayDontHitSelf, client); 
	else trace= TR_TraceRayFilterEx(pos1, pos2, MASK_SOLID, RayType_EndPoint, TraceRayDontHitSelfAndAlive, client);
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
	trace= TR_TraceRayFilterEx(pos, angle, MASK_SOLID, RayType_Infinite, TraceRayDontHitSelfAndAlive, client); 
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
GetEnt(witch, Float:origin[3], Float:angle[3], &type)
{
	new ent=0; 
	decl Float:pos[3]; 

	new Handle:trace = TR_TraceRayFilterEx(origin, angle, MASK_SOLID, RayType_Infinite, TraceRayDontHitSelf, witch);

	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(pos, trace);
		ent=TR_GetEntityIndex(trace);
		if(ent>0)
		{
			type=Enemy_Type_Ohter;
			decl String:classname[64];
			GetEdictClassname(ent, classname, 64);	
			
			if(ent >=1 && ent<=MaxClients)
			{
				if(GetClientTeam(ent)==2)type=Enemy_Type_Survivor;
				else type=Enemy_Type_Infected;
			}
			if(StrContains(classname, "ladder")!=-1){ent=0;}
			else if(StrContains(classname, "door")!=-1){type=Enemy_Type_Door; }
			else if(StrContains(classname, "infected")!=-1){type=Enemy_Type_CI;} 
			if(ent>0)
			{
				if(GetVectorDistance(origin, pos)>50.0)
				{
					ent=0; 
				}
			} 
		} 
	}
	CloseHandle(trace);	
	return ent;
}
ThrowEnt(client, ent, Float:vOrigin[3], Float:vAngles[3] ,Float:force=1000.0)
{ 
	decl Float:pos[3]; 
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
ShowPos(color, Float:pos1[3], Float:pos2[3],Float:life=10.0, Float:length=0.0, Float:width1=1.0, Float:width2=11.0)
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
  
ResetAllState()
{
	for(new i=1; i<=MaxClients; i++)
	{
		Stop(i); 
		g_PointHurt=0.0;
	}
}
Init()
{
	if(L4D2Version)
	{
		anim_ducking=4;
		anim_ducking_angry=27;
		anim_crawl=38;
		anim_standing_angry=2;
		anim_run=8; //8
		anim_run_crazy=6;// 6,7
		anim_walk=10; //10 ,11
		anim_idle=10;
		anim_jump=58;
		anim_fall =54;
		anim_threaten=31; // 31, 28, 29, 40, 7
		anim_attack1={17, 19}; //16 18  boold 17, 19 
		anim_attack2=32;
		anim_ladder_up=70;
		anim_ladder_down=70;
		anim_lookaround=5;
	}
	else
	{
		anim_ducking=2; //20
		anim_ducking_angry=27;
		anim_crawl=30;
		anim_standing_angry=2;
		anim_run=6; 
		anim_run_crazy=4; 
		anim_walk=6; //10 ,11
		anim_idle=10;
		anim_jump=58;
		anim_fall =6;
		anim_threaten=22;  //23
		anim_attack1={10, 12};  
		anim_attack2=24;
		anim_ladder_up=62;
		anim_ladder_down=63;
		anim_lookaround=3;		
	}
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
	PrecacheSound(SoundAttack[0]);
	PrecacheSound(SoundAttack[1]);
	PrecacheSound(SoundPriAttackHit[0]);
	PrecacheSound(SoundPriAttackHit[1]);		
	PrecacheSound(SoundPriAttackHit[2]);	
	PrecacheSound(SoundSecAttackHit[0]);
	if(L4D2Version)
	{
		g_sprite = PrecacheModel("materials/sprites/laserbeam.vmt");	
	
	}
	else
	{
		g_sprite = PrecacheModel("materials/sprites/laser.vmt");	
		 
	} 
}
public bool:TraceRayDontHitSelf (entity, mask, any:data)
{
	if(entity == data) 
	{
		return false; 
	} 
	return true;
}
public bool:TraceRayDontHitSelfAndAlive (entity, mask, any:data)
{
	if(entity == data) 
	{
		return false; 
	}
	if(entity >=1 && entity<=MaxClients)
	{
		return false;
	}
	if(entity > 0)
	{
		decl String:classname[64];
		GetEdictClassname(entity, classname, 64);	 
		if(StrContains(classname, "infected")!=-1)return false; 
	}
	return true;
}
public Action:ShowInfo(Handle:timer, any:client)
{
	if(L4D2Version)DisplayHint(INVALID_HANDLE, client);
	else PrintToChat(client, "\x03Press \x04Duck+Jump \x03button to \x03control \x04witch");
}
//code from "DJ_WEST"
public CreateCamera(i_Witch)
{
	decl i_Camera, Float:f_Origin[3], Float:f_Angles[3], Float:f_Forward[3], String:s_TargetName[32];
	
	GetEntPropVector(i_Witch, Prop_Send, "m_vecOrigin", f_Origin);
	GetEntPropVector(i_Witch, Prop_Send, "m_angRotation", f_Angles);
	
	i_Camera = CreateEntityByName("prop_dynamic_override");
	if (IsValidEdict(i_Camera))
	{
		GetAngleVectors(f_Angles, f_Forward, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector(f_Forward, f_Forward);
		ScaleVector(f_Forward, -90.0);
		AddVectors(f_Forward, f_Origin, f_Origin);
		f_Origin[2] += 80.0;
		FormatEx(s_TargetName, sizeof(s_TargetName), "witch%d", i_Witch);
		DispatchKeyValue(i_Camera, "model", "models/w_models/weapons/w_eq_pipebomb.mdl");
		DispatchKeyValue(i_Witch, "targetname", s_TargetName);
		DispatchKeyValueVector(i_Camera, "origin", f_Origin);
		f_Angles[0] = 10.0;
		DispatchKeyValueVector(i_Camera, "angles", f_Angles);
		DispatchKeyValue(i_Camera, "parentname", s_TargetName);
		DispatchSpawn(i_Camera);
		SetVariantString(s_TargetName);
		AcceptEntityInput(i_Camera, "SetParent");
		AcceptEntityInput(i_Camera, "DisableShadow");
		ActivateEntity(i_Camera);
		SetEntityRenderMode(i_Camera, RENDER_TRANSCOLOR);
		SetEntityRenderColor(i_Camera, 0, 0, 0, 0);
	
		return i_Camera;
	}
	
	return 0;
}
public Action:DisplayHint(Handle:h_Timer, any:i_Client)
{
	 
	if ( IsClientInGame(i_Client))	ClientCommand(i_Client, "gameinstructor_enable 1");
	CreateTimer(1.0, DelayDisplayHint, i_Client);
}
public Action:DelayDisplayHint(Handle:h_Timer, any:i_Client)
{
 
	DisplayInstructorHint(i_Client, "Press Duck+Jump to control witch", "+jump");
	 
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
 