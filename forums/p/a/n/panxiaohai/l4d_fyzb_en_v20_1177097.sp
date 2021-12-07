#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.2.0"
#define SOUND_LANDING  "player/jumplanding.wav"
#define SOUND_LANDING2  "player/PZ/fall/Bodyfall_LargeCreature.wav"
 

 new bool:JumpEnabled[MAXPLAYERS+1];
 new KeyBuffer[MAXPLAYERS+1];
 new FlagBuffer[MAXPLAYERS+1];
 new OnAir[MAXPLAYERS+1];
 new MovementState[MAXPLAYERS+1];
 new ReadyButton[MAXPLAYERS+1];
 new Float:FallVol[MAXPLAYERS+1];
 
new Handle:timer_handle=INVALID_HANDLE;
new Handle:l4d_fyzb_showtime = INVALID_HANDLE;
new Handle:l4d_fyzb_enabled = INVALID_HANDLE;
new Handle:l4d_fyzb_init = INVALID_HANDLE;
new Handle:l4d_fyzb_damage = INVALID_HANDLE;
new Handle:l4d_fyzb_damage2 = INVALID_HANDLE;
new Handle:l4d_fyzb_distancediff = INVALID_HANDLE;
new Handle:l4d_fyzb_anglediff1 = INVALID_HANDLE;
new Handle:l4d_fyzb_speed = INVALID_HANDLE;
new Handle:l4d_fyzb_movement = INVALID_HANDLE;
new Handle:l4d_fyzb_safegravity = INVALID_HANDLE;
new Handle:l4d_fyzb_safefallspeed = INVALID_HANDLE;
new Handle:l4d_fyzb_callboss = INVALID_HANDLE;
new Handle:l4d_fyzb_infecteduse = INVALID_HANDLE;
new Handle:l4d_fyzb_god = INVALID_HANDLE;

new all_iVelocity;
new String:sdemage[10];
new String:sdemage2[10];
new Float:speed;
new damage;
new damage2;
new Float:distancediff;
new Float:anglediff1;
new Float:movement;
new Float:safegravity;
new Float:safefallspeed;
new callboss;
new infecteduse;
new godmode;
new Enabled;

new TankClass=5;

public Plugin:myinfo = 
{
	name = "fyzb",
	author = "Pan Xiaohai",
	description = "jump like a hunter",
	version = PLUGIN_VERSION,	
}
 
public OnPluginStart()
{
	CreateConVar("l4d_fyzb_version", PLUGIN_VERSION, " ", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	l4d_fyzb_enabled = CreateConVar("l4d_fyzb_enabled", "1", " 1 : enable , 0: disable ", FCVAR_PLUGIN);
	l4d_fyzb_init = CreateConVar("l4d_fyzb_init", "0", " 1 : initial enable , 0: initial disable ", FCVAR_PLUGIN);
	l4d_fyzb_speed = CreateConVar("l4d_fyzb_speed", "650.0", "jump speed", FCVAR_PLUGIN);
	l4d_fyzb_distancediff = CreateConVar("l4d_fyzb_distancediff", "60.0", "jump difficult >0", FCVAR_PLUGIN);
	l4d_fyzb_anglediff1 = CreateConVar("l4d_fyzb_anglediff1", "9.0", "wall jump difficult >=0", FCVAR_PLUGIN);
  	l4d_fyzb_damage = CreateConVar("l4d_fyzb_damage", "5", "jump damage for survivor", FCVAR_PLUGIN);
 	l4d_fyzb_damage2 = CreateConVar("l4d_fyzb_damage2", "50", "jump damage for infected", FCVAR_PLUGIN);
 	l4d_fyzb_movement = CreateConVar("l4d_fyzb_movement", "0.90", "movement slow [0.5-1.0]", FCVAR_PLUGIN);
 	l4d_fyzb_safegravity = CreateConVar("l4d_fyzb_safegravity", "0.6", "fall down gravity for safe [0.3-1.0]", FCVAR_PLUGIN);
 	l4d_fyzb_safefallspeed = CreateConVar("l4d_fyzb_safefallspeed", "250", "fall down speed great this will use safe gravity[100-1000]", FCVAR_PLUGIN);
 	l4d_fyzb_callboss = CreateConVar("l4d_fyzb_callboss", "5", "call infected probility %", FCVAR_PLUGIN);
 	l4d_fyzb_showtime = CreateConVar("l4d_fyzb_showtime", "80", "message time", FCVAR_PLUGIN);
  	l4d_fyzb_infecteduse = CreateConVar("l4d_fyzb_infecteduse", "0", "0 , disable for infected 1, enable for infected, 3,enable for infected but tank", FCVAR_PLUGIN);
  	l4d_fyzb_god = CreateConVar("l4d_fyzb_god", "1", "0  enable fall damage, 1: disable fall damage", FCVAR_PLUGIN);
	AutoExecConfig(true, "l4d_fyzb_en_v20");

	HookConVarChange(l4d_fyzb_enabled, ConVarChange);
	HookConVarChange(l4d_fyzb_speed, ConVarChange);
 	HookConVarChange(l4d_fyzb_damage, ConVarChange);
	HookConVarChange(l4d_fyzb_distancediff, ConVarChange);
	HookConVarChange(l4d_fyzb_anglediff1, ConVarChange);
	HookConVarChange(l4d_fyzb_movement, ConVarChange);
	HookConVarChange(l4d_fyzb_safefallspeed, ConVarChange);
	HookConVarChange(l4d_fyzb_safegravity, ConVarChange);
	HookConVarChange(l4d_fyzb_callboss, ConVarChange);
 	HookConVarChange(l4d_fyzb_infecteduse, ConVarChange);
  	HookConVarChange(l4d_fyzb_god, ConVarChange);

	damage=GetConVarInt(l4d_fyzb_damage );
 	Format(sdemage, sizeof(sdemage),  "%i", damage);
	damage2=GetConVarInt(l4d_fyzb_damage2 );
 	Format(sdemage2, sizeof(sdemage2),  "%i", damage2);
	speed=GetConVarFloat(l4d_fyzb_speed );
 	damage=GetConVarInt(l4d_fyzb_damage );
	Enabled=GetConVarInt(l4d_fyzb_enabled) ;
	callboss=GetConVarInt(l4d_fyzb_callboss) ;
	distancediff=GetConVarFloat(l4d_fyzb_distancediff);
	anglediff1=GetConVarFloat(l4d_fyzb_anglediff1);
	movement=GetConVarFloat(l4d_fyzb_movement);
	safefallspeed=GetConVarFloat(l4d_fyzb_safefallspeed);
	safegravity=GetConVarFloat(l4d_fyzb_safegravity);
 	infecteduse=GetConVarInt(l4d_fyzb_infecteduse) ;
 	godmode=GetConVarInt(l4d_fyzb_god) ;


  	all_iVelocity = FindSendPropOffs("CBasePlayer", "m_vecVelocity[0]");
    	
	HookEvent("round_end", RoundEnd);
	HookEvent("mission_lost", RoundEnd);
	HookEvent("finale_win", RoundEnd);
	HookEvent("round_start", RoundStart);
   	HookEvent("player_spawn", evtPlayerSpawn);
 	RegConsoleCmd("sm_fyzb", Command_FYZB);
 	RegConsoleCmd("sm_fyzb2", Command_FYZB2);
 	Reset();
}
public OnMapStart()
{
	PrecacheSound(SOUND_LANDING, true) ;
	PrecacheSound(SOUND_LANDING2, true) ;
}
public ConVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	damage=GetConVarInt(l4d_fyzb_damage );
 	Format(sdemage, sizeof(sdemage),  "%i", damage);
	damage2=GetConVarInt(l4d_fyzb_damage2 );
 	Format(sdemage2, sizeof(sdemage2),  "%i", damage2);

	speed=GetConVarFloat(l4d_fyzb_speed );
 	damage=GetConVarInt(l4d_fyzb_damage );
	Enabled=GetConVarInt(l4d_fyzb_enabled) ;
	callboss=GetConVarInt(l4d_fyzb_callboss) ;
	distancediff=GetConVarFloat(l4d_fyzb_distancediff);
	anglediff1=GetConVarFloat(l4d_fyzb_anglediff1);
	movement=GetConVarFloat(l4d_fyzb_movement);
	safefallspeed=GetConVarFloat(l4d_fyzb_safefallspeed);
	safegravity=GetConVarFloat(l4d_fyzb_safegravity);
 	infecteduse=GetConVarInt(l4d_fyzb_infecteduse) ;
 	godmode=GetConVarInt(l4d_fyzb_god) ;

}
 public Action:evtPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
 	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client<=0)return;
	//if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue",  1.0);
		SetEntityGravity(client,1.0);
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
		OnAir[client]=0;
 		MovementState[client]=0;
	}

}

public Action:Msg(Handle:timer, any:data)
{
	PrintToChatAll("\x03input:\x04!fyzb or !fyzb2\x03 enable hunter jump");
  	return Plugin_Continue;
}
public Action:Command_FYZB(client, args)
{
	if (client == 0 || !IsClientInGame(client))return Plugin_Handled;
	JumpEnabled[client]=!JumpEnabled[client];
	ReadyButton[client]=IN_SPEED;
	if(	JumpEnabled[client])
	{
		PrintToChat(client, "\x03Fyzb enabled, press walk+jump (shift+space)");
	}
	else
	{
		PrintToChat(client, "\x03Fyzb disabled");
		SetEntityGravity(client,1.0);
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue",  1.0);
	}
  	return Plugin_Handled;
}
public Action:Command_FYZB2(client, args)
{
	if (client == 0 || !IsClientInGame(client))	return Plugin_Handled;
	JumpEnabled[client]=!JumpEnabled[client];
	ReadyButton[client]=IN_DUCK;
	if(	JumpEnabled[client])
	{
		PrintToChat(client, "\x03Fyzb enabled, press duck+jump (ctrl+space)");
	}
	else
	{
		PrintToChat(client, "\x03Fyzb disabled");
		SetEntityGravity(client,1.0);
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue",  1.0);
	}
  	return Plugin_Handled;
}

new Float:velocity[3];
new Float:clientpos[3];
new Float:clientangle[3];
new Float:reserveclientangle[3];
new Float:reserveclientangle2[3];
new Float:angledir[3];
new Float:clientdirection[3];
new Float:hitpos[3];
new bool:allow=false;
new bool:ground=false;
new bool:hold=false;
new buttons;
new clientflag;
new Float:dis;
new Handle:trace;
new random;
public OnGameFrame()
{
	//new flag=GetEntityFlags(client)  //FL_ONGROUND
	if(	Enabled==0 )return;
  	for (new client = 1; client <= MaxClients; client++)
	{
		if (JumpEnabled[client]  && IsClientInGame(client) && IsPlayerAlive(client) && !IsFakeClient(client))
		{
			Do(client);
		}
	}
	return;
}
new plaerteam;
new bool:canuse;
public Do(client)
{
	buttons = GetClientButtons(client);
	clientflag=GetEntityFlags(client);  //FL_ONGROUND
	
	hold=false;
	if((buttons & ReadyButton[client]))
	{
		if((buttons & IN_JUMP) && !(KeyBuffer[client] & IN_JUMP))
		{
			hold=true;
		}
		//OnPlayerDrop(client);
	}
	plaerteam=GetClientTeam(client);
	canuse=false;
	if(hold)
	{
		 
		if(plaerteam==2)
		{
			canuse=true;
		}
		else if(plaerteam==3)
		{
			if(infecteduse==1)
			{
				canuse=true;
			}
			else if(infecteduse==2) 
			{
				if(!IsPlayerTank(client))
				{
					canuse=true;
				}
			}
		}
		if(canuse)
		{
			ground=false;
			if(FlagBuffer[client] & FL_ONGROUND)
			{
				ground=true;
			}
 			GetClientAbsOrigin(client, clientpos);
			GetClientEyeAngles(client, clientangle);

 			if(ground)
			{
				if(clientangle[0]>-20.0)clientangle[0]=-20.0;
 			}
			else
			{
 
			}
			allow=false;
 			if(!ground)
			{
 				GetAngleVectors(clientangle,angledir, NULL_VECTOR, NULL_VECTOR);
				ScaleVector(angledir, -1.0);
				GetVectorAngles(angledir, reserveclientangle);

				trace = TR_TraceRayFilterEx(clientpos, reserveclientangle, /*MASK_SOLID*/ MASK_ALL,  RayType_Infinite, TraceEntityFilterPlayer);

				if(TR_DidHit(trace))
				{
					TR_GetEndPosition(hitpos, trace);
				}
				CloseHandle(trace);
 	  
				if(dis<distancediff)
				{
					allow=true;
 				}
 
				if(!allow && anglediff1!=0.0)
				{
					reserveclientangle2[0]=reserveclientangle[0]-anglediff1;
					reserveclientangle2[1]=reserveclientangle[1];
					reserveclientangle2[2]=reserveclientangle[2];
	 
					trace = TR_TraceRayFilterEx(clientpos, reserveclientangle2, MASK_ALL,  RayType_Infinite, TraceEntityFilterPlayer);

					if(TR_DidHit(trace))
					{
						TR_GetEndPosition(hitpos, trace);
					}
					CloseHandle(trace);
					dis=GetVectorDistance(hitpos, clientpos);
					if(dis<distancediff)
					{
						allow=true;
					}
	 
				}
			
			}
  		 
			if(allow || ground)
			{
				GetAngleVectors(clientangle, clientdirection, NULL_VECTOR, NULL_VECTOR);
				NormalizeVector(clientdirection,clientdirection);
				{
					ScaleVector(clientdirection, speed);
				}
 				TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, clientdirection);
				FallVol[client]=0.0;

				OnAir[client]=1;
				MovementState[client]=0;

				if(plaerteam==2)
				{
					SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue",  movement);
					SetEntityGravity(client,1.0);
				}
				if(ground)PrintCenterText(client, "hunter jump");
				if(!ground)
				{
					EmitSoundToAll(SOUND_LANDING, client); 
				}
				else
				{
					//EmitSoundToAll(SOUND_LANDING, client); 
				}
				if(damage>0)
				{
					DamageEffect(client, plaerteam);
 				}
				if(callboss>0)
				{
					random=GetRandomInt(0, 100);
					if(random<callboss)
					{
						CreateTimer(0.5, CallBoss, client);
					}
				}
			 
			}
			else
			{
				PrintCenterText(client, "can not jump without catch point");
			}
		}
	}
	else 
	{
		if(OnAir[client]==1)
		{
			if(clientflag & FL_ONGROUND)
			{
				if(plaerteam==2)
				{
					//SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
					SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue",  1.0);
					SetEntityGravity(client, 1.0);
					CreateTimer(0.3, NotGodMode, client);
				}
				OnAir[client]=0;
				MovementState[client]=0;
				SetEntityGravity(client,1.0);
				if(FallVol[client]>600.0)
				{
					new bool:shake=true;
					if(plaerteam==3)
					{
						if(GetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_isGhost"), 1))
						{
							shake=false;
						}
					}
					if(shake)
					{
						GetClientAbsOrigin(client, clientpos);
						Shake(clientpos, FallVol[client]);
					}
					//PrintToChatAll("shake %f", FallVol[client]);
				}
				FallVol[client]=0.0;
 			}
			else
			{
				GetEntDataVector(client, all_iVelocity, velocity);
				//vel=GetVectorLength(velocity);
				//PrintToChatAll("%f", velocity[2]);
				if(0.0-velocity[2]>=FallVol[client])
				{
					FallVol[client]=0.0-velocity[2];
					//PrintToChatAll("shake %f", FallVol[client]);
				}
 				if(0.0-velocity[2]>=safefallspeed)
				{
 					//if(MovementState[client]==0 && team==2)
 					if(plaerteam==2)
					{
						//PrintToChatAll("god %f", velocity[2]);
						if(godmode==1)
						{
							SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);							
						}
						else
						{
							SetEntityGravity(client,safegravity);
						}
					}
					MovementState[client]=1;
				}
				//else
				//{
				//	if(MovementState[client]==1 && team==2)
				//	{
				//		if(godmode==1)
				//		{

				//			CreateTimer(0.1, GodMode, client);
				//			//SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
				//		}
				//		else
				//		{
				//			SetEntityGravity(client,1.0);
				//		}
 			//		}
				//	MovementState[client]=0;

				//}
				
			}
		}
	}
	KeyBuffer[client]=buttons;
	FlagBuffer[client]=clientflag;

}
bool:IsPlayerTank (client)
{
	if(GetEntProp(client,Prop_Send,"m_zombieClass") == 5)
		return true;
	return false;
}
Shake(Float:pos[3], Float:vel)
{
 	new ent1=CreateEntityByName("env_shake");           
 	DispatchKeyValueFloat(ent1, "amplitude", 16.0);               
 	DispatchKeyValueFloat(ent1, "radius", 300.0);                 
 	DispatchKeyValueFloat(ent1, "duration", 0.5);                    
 	DispatchKeyValueFloat(ent1, "frequency", 255.0);               
	DispatchSpawn(ent1);                                       
	TeleportEntity(ent1, pos, NULL_VECTOR, NULL_VECTOR);
 	AcceptEntityInput(ent1, "StartShake");    
 	CreateTimer(1.0, StopShake, ent1);

	new push = CreateEntityByName("point_push");         
  	DispatchKeyValueFloat (push, "magnitude", vel);                     
	DispatchKeyValueFloat (push, "radius", 300.0);                     
  	SetVariantString("spawnflags 24");                             
	AcceptEntityInput(push, "AddOutput");
 	DispatchSpawn(push);   
	TeleportEntity(push, pos, NULL_VECTOR, NULL_VECTOR);  
 	AcceptEntityInput(push, "Enable", -1, -1);
	CreateTimer(0.1, DeletePushForce, push);
 
	EmitAmbientSound(SOUND_LANDING2, pos, SOUND_FROM_WORLD, SNDLEVEL_RAIDSIREN);	
	
}
public Action:DeletePushForce(Handle:timer, any:ent)
{
    if (IsValidEntity(ent))
    {
        new String:classname[64];
        GetEdictClassname(ent, classname, sizeof(classname));
        if (StrEqual(classname, "point_push", false))
		{
 			AcceptEntityInput(ent, "Disable");
			AcceptEntityInput(ent, "Kill");    
			RemoveEdict(ent);
		}
    }
}
public Action:StopShake(Handle:timer, any:ent)
{
    if (IsValidEntity(ent))
    {
 		AcceptEntityInput(ent, "Kill");    
		RemoveEdict(ent);
    }
}
public Action:NotGodMode(Handle:timer, any:client)
{
    if (IsClientInGame(client) && IsPlayerAlive(client))
    {
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);  
		//PrintToChatAll("stop god ");
	}
}
public Action:CallBoss(Handle:timer, any:client)
{
	if(IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client)==2)
	{
			PrintHintText(client, "\x03Your action attracted infected's attention");
			new r=GetRandomInt(0,100);
			if(r<30)CheatCommand(client, "z_spawn", "boomer", "" );
  			else if(r<60)CheatCommand(client, "z_spawn", "hunter", "" );
  			else if(r<90)CheatCommand(client, "z_spawn", "smoker", "" );
  			else CheatCommand(client, "z_spawn", "witch", "" );
	}
}
 public AddParticle( String:s_Effect[100], Float:f_Origin[3])
{
	decl i_Particle;
	 
	i_Particle = CreateEntityByName("info_particle_system");
	
	if (IsValidEdict(i_Particle))
	{
 
		TeleportEntity(i_Particle, f_Origin, NULL_VECTOR, NULL_VECTOR);
  		DispatchKeyValue(i_Particle, "effect_name", s_Effect);
		DispatchSpawn(i_Particle);
 		ActivateEntity(i_Particle);
		AcceptEntityInput(i_Particle, "Start");
		CreateTimer(5.0, KillParticle, i_Particle); 
	}

	return i_Particle;
}
public Action:KillParticle(Handle:timer, any:i_Particle)
{
	if (IsValidEntity(i_Particle))
    {
             RemoveEdict(i_Particle);
       
    }
}
public Action:DamagePlayer(Handle:timer, any:client)
{
	new team1=GetClientTeam(client);
	DamageEffect(client, team1);
}
stock DamageEffect(target, team1)
{
 	new String:N[20];
	Format(N, 20, "target%d", target);
	new pointHurt = CreateEntityByName("point_hurt");			// Create point_hurt
	DispatchKeyValue(target, "targetname", N);			// mark target
	if(team1==2)
		DispatchKeyValue(pointHurt, "Damage", sdemage);					// No Damage, just HUD display. Does stop Reviving though
	else 
		DispatchKeyValue(pointHurt, "Damage", sdemage2);					// No Damage, just HUD display. Does stop Reviving though
	DispatchKeyValue(pointHurt, "DamageTarget", N);		// Target Assignment
	DispatchKeyValue(pointHurt, "DamageType", "65536");			// Type of damage
	DispatchSpawn(pointHurt);									// Spawn descriped point_hurt
	AcceptEntityInput(pointHurt, "Hurt"); 						// Trigger point_hurt execute
	AcceptEntityInput(pointHurt, "Kill"); 						// Remove point_hurt
	//DispatchKeyValue(target, "targetname",	"cake");			// Clear target's mark
	return;
}
 

public Action:RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
 	if(timer_handle != INVALID_HANDLE )
	 {
		KillTimer(timer_handle);
		timer_handle=INVALID_HANDLE;
	}

	return Plugin_Continue;
}

public Action:RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	 
	if(timer_handle != INVALID_HANDLE )
	{
		KillTimer(timer_handle);
		timer_handle=INVALID_HANDLE;
	}
 
	timer_handle=CreateTimer(GetConVarFloat(l4d_fyzb_showtime), Msg, 0, TIMER_REPEAT);
	Reset();
	return Plugin_Continue;
}
 
stock CheatCommand(client, String:command[], String:parameter1[], String:parameter2[])
{
	new userflags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s %s", command, parameter1, parameter2);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, userflags);
}
 
Reset()
{
	new bool:e=GetConVarInt(l4d_fyzb_init)>0;
	for (new x = 1; x   <=MaxClients ; x++)
	{
 		JumpEnabled[x]=e;
		ReadyButton[x]=IN_SPEED;
 		FlagBuffer[x]=0;
		OnAir[x]=0;
 		MovementState[x]=0;
		if(IsClientInGame(x) && IsPlayerAlive(x))
		{
			SetEntPropFloat(x, Prop_Data, "m_flLaggedMovementValue",  1.0);
			SetEntityGravity(x,1.0);
			SetEntProp(x, Prop_Data, "m_takedamage", 2, 1);
		}
	}
}
public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return (entity > GetMaxClients() || !entity);
} 