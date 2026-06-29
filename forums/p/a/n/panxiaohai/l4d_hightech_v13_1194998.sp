#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdktools_functions>

#define FIRESOUND "weapons/hunting_rifle/gunfire/hunting_rifle_fire_1.wav" 

#define SOUND0 "weapons/hunting_rifle/gunfire/hunting_rifle_fire_1.wav" 
#define SOUND1 "weapons/rifle/gunfire/rifle_fire_1.wav" 
#define SOUND2 "weapons/auto_shotgun/gunfire/auto_shotgun_fire_1.wav" 
#define SOUND3 "weapons/shotgun/gunfire/shotgun_fire_1.wav" 
#define SOUND4 "weapons/SMG/gunfire/smg_fire_1.wav" 
#define SOUND5 "weapons/pistol/gunfire/pistol_fire.wav" 

#define SOUNDCLIPEMPTY           "weapons/ClipEmpty_Rifle.wav" 
#define SOUNDRELOAD              "weapons/shotgun/gunother/shotgun_load_shell_2.wav" 
#define SOUNDREADY          	 "weapons/shotgun/gunother/shotgun_pump_1.wav"
 
#define MODEL0 "weapon_hunting_rifle"
#define MODEL1 "weapon_rifle"
#define MODEL2 "weapon_autoshotgun"
#define MODEL3 "weapon_pumpshotgun"
#define MODEL4 "weapon_smg"
#define MODEL5 "weapon_pistol"


#define CAMERA_MODEL "models/w_models/weapons/w_eq_pipebomb.mdl"
new g_PointHurt=0;
new String:SOUND[9][60]=
{SOUND0, SOUND1, SOUND2, SOUND3, SOUND4, SOUND5, SOUNDCLIPEMPTY, SOUNDRELOAD, SOUNDREADY};

new String:MODEL[6][50]=
{MODEL0, MODEL1, MODEL2, MODEL3, MODEL4, MODEL5 };

new Float:fireinterval[6]={0.25, 0.068, 0.23, 0.65, 0.055, 0.20 };
new Float:bulletaccuracy[6]={0.15, 0.4, 3.5, 3.5, 0.6, 0.7 };
new String:weaponbulletdamage[6][10]={"90", "30", "25", "30", "20", "30"};
new weaponclipsize[6]={15, 50, 10, 8, 50, 30};
new weaponbulletpershot[6]={1, 1, 7, 7, 1, 1};
new weaponauto[6]={1, 1, 1, 0, 1, 0};
new Float:weaponloadtime[6]={2.0, 1.5, 0.3, 0.3, 1.5, 1.5};
new weaponloadcount[6]={15, 50, 1,1, 50, 30};
new bool:weaponloaddisrupt[6]={false,false, true, true,false,false};


new robot[MAXPLAYERS+1];
new keybuffer[MAXPLAYERS+1];
new weapontype[MAXPLAYERS+1];
new bullet[MAXPLAYERS+1];
new Float:firetime[MAXPLAYERS+1];
new bool:reloading[MAXPLAYERS+1];
new Float:reloadtime[MAXPLAYERS+1];

new Handle:l4d_hightech_limit = INVALID_HANDLE;
new Handle:l4d_hightech_speed = INVALID_HANDLE;
new Handle:l4d_hightech_chargetime = INVALID_HANDLE;
new Handle:l4d_hightech_damage = INVALID_HANDLE;
new Handle:l4d_hightech_radius = INVALID_HANDLE;
new Handle:l4d_hightech_pushforce = INVALID_HANDLE;
new Handle:l4d_hightech_style = INVALID_HANDLE;
new Handle:l4d_hightech_damagetype = INVALID_HANDLE;

new Float:MaxSpeed;
new Float:FireChargeTime;
new DamageType;
new g_sprite;
 
new bool:L4D2Version=false;
new GameMode=0;

public Plugin:myinfo = 
{
	name = "high-tech remote control system",
	author = "Pan Xiaohai",
	description = "high-tech remote control system",
	version = "1.0",
	url = "http://forums.alliedmods.net"
}
public OnPluginStart()
{
 	l4d_hightech_limit = CreateConVar("l4d_hightech_limit", "2", "number of players can control robot", FCVAR_PLUGIN);
 	l4d_hightech_speed = CreateConVar("l4d_hightech_speed", "1000.0", "robot fly speed", FCVAR_PLUGIN);
 	l4d_hightech_chargetime = CreateConVar("l4d_hightech_chargetime", "2.0", "charge time", FCVAR_PLUGIN);
 	l4d_hightech_style = CreateConVar("l4d_hightech_style", "2", "explode style, 0:nothing, 1:show particle, 2: show sparks, 3, show explode", FCVAR_PLUGIN);
 	l4d_hightech_damage = CreateConVar("l4d_hightech_damage", "200", "damage", FCVAR_PLUGIN);
 	l4d_hightech_radius = CreateConVar("l4d_hightech_radius", "200", "radius", FCVAR_PLUGIN);
 	l4d_hightech_pushforce = CreateConVar("l4d_hightech_pushforce", "400", "push force", FCVAR_PLUGIN);
 	l4d_hightech_damagetype= CreateConVar("l4d_hightech_damagetype", "0", "0: bullent impact damage; 1: explode damage", FCVAR_PLUGIN);
	
	AutoExecConfig(true, "l4d_hightech_v13");

	HookConVarChange(l4d_hightech_speed, ConVarChange);
	HookConVarChange(l4d_hightech_chargetime, ConVarChange);
	HookConVarChange(l4d_hightech_damagetype, ConVarChange);
	GetConVar();

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
	
 	RegConsoleCmd("sm_ht", sm_ht);
	HookEvent("player_use", player_use);
 
	HookEvent("round_start", RoundStart);
	HookEvent("round_end", RoundEnd);
	HookEvent("finale_win", RoundEnd);
	HookEvent("mission_lost", RoundEnd);
	HookEvent("map_transition", RoundEnd);
	
	HookEvent("player_spawn", Event_Spawn);	 
	HookEvent("player_afk", player_afk );	 
	HookEvent("player_bot_replace", player_bot_replace );	 
	RegConsoleCmd("sm_ht2",third, "change view");
 }
GetConVar()
{
	MaxSpeed=GetConVarFloat(l4d_hightech_speed );
 	FireChargeTime=GetConVarFloat(l4d_hightech_chargetime );
	DamageType=GetConVarInt(l4d_hightech_damagetype );	
}

public ConVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	GetConVar();
}
public PlayerConnectFull(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	ClientCommand(client, "bind \\ \"say /ht2\"");
 }
public OnClientDisconnect(client)
{
	ClientCommand(client, "bind \\ \"\"");
}
public Event_Spawn(Handle:Spawn_Event, const String:Spawn_Name[], bool:Spawn_Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(Spawn_Event, "userid"));
	ClientCommand(client, "bind \\ \"say /ht2\"");
}
public player_afk(Handle:Spawn_Event, const String:Spawn_Name[], bool:Spawn_Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(Spawn_Event, "player"));
	if(robot[client]>0)
	{
		Release(client);	 
	}
}
public player_bot_replace(Handle:Spawn_Event, const String:Spawn_Name[], bool:Spawn_Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(Spawn_Event, "player"));
	if(robot[client]>0)
	{
		Release(client);	 
	} 
	new bot = GetClientOfUserId(GetEventInt(Spawn_Event, "bot"));
	SetEntityMoveType(bot, MOVETYPE_WALK);
 	SetClientViewEntity( bot, bot );
}
public OnMapStart()
{
	PrecacheModel( "models/props_junk/propanecanister001a.mdl", true );
	PrecacheModel( MODEL[0] , true );
	PrecacheModel( MODEL[1] , true );
	PrecacheModel( MODEL[2] , true );
	PrecacheModel( MODEL[3] , true );
	PrecacheModel( MODEL[4] , true );
	PrecacheModel( MODEL[5] , true );

	PrecacheSound(SOUND[0], true) ;
	PrecacheSound(SOUND[1], true) ;
	PrecacheSound(SOUND[2], true) ;
	PrecacheSound(SOUND[3], true) ;
	PrecacheSound(SOUND[4], true) ;
	PrecacheSound(SOUND[5], true) ;
	
	
	PrecacheSound(SOUNDCLIPEMPTY, true) ;
	PrecacheSound(SOUNDRELOAD, true) ;
	PrecacheSound(SOUNDREADY, true) ;	

	
	PrecacheParticle("gas_explosion_pump");
    
	PrecacheModel(CAMERA_MODEL);
	
	
	if(L4D2Version)
	{
		g_sprite = PrecacheModel("materials/sprites/laserbeam.vmt");	
	 	
	}
	else
	{
		g_sprite = PrecacheModel("materials/sprites/laser.vmt");	
 
	}
	
}
public Action:RoundStart (Handle:event, const String:name[], bool:dontBroadcast)
{

	for (new i = 1; i <= MaxClients; i++)
	{
		if(robot[i]>0)
		{
			Release(i, false);	 
 		}
	}
	g_PointHurt=0;
  	return Plugin_Continue;
}
public Action:RoundEnd (Handle:event, const String:name[], bool:dontBroadcast)
{

	for (new i = 1; i <= MaxClients; i++)
	{
		if(robot[i]>0)
		{
			Release(i, false);	 
 		}
	}
	g_PointHurt=0;
  	return Plugin_Continue;
}
public player_use (Handle:hEvent, const String:name[], bool:dontBroadcast)
{
 
	new entity = GetEventInt(hEvent, "targetid");
	for (new i = 1; i <= MaxClients; i++)
	{
		if(robot[i]>0 && robot[i]==entity)
		{
			Release(i);	 
 		}
	} 
	 
}

DelRobot(ent)
{
	if (ent > 0 && IsValidEntity(ent))
    {
        RemoveEdict(ent);
       
    }
}
 
Release(controller, bool:del=true)
{
	new r=robot[controller];
	if(r>0)
	{
		robot[controller]=0;
		if(IsClientInGame(controller) && IsPlayerAlive(controller))
		{
 			SetEntityMoveType(controller, MOVETYPE_WALK);
 			SetClientViewEntity( controller, controller );
			PrintToChatAll("\x04 %N \x03 exit remote control system",controller);
		}
		first(controller,0);
		if(del)DelRobot(r);
	}
}

public Action:sm_ht(client, args)
{  
	if(GameMode==2)return Plugin_Continue;
	if(!IsValidAliveClient(client))	return Plugin_Continue;
	if(robot[client]>0)
	{
		PrintToChat(client, "you are already control a robot");
		return Plugin_Handled;
	}
	new count=0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if(robot[i]>0)
		{
			count++; 
 		}
	}
	
	if(count+1>GetConVarInt(l4d_hightech_limit))
	{
		PrintToChat(client, "no more remote control system");
		return Plugin_Handled;
	}
	
	if(args>=1)
	{
		new String:arg[128];
		GetCmdArg(1, arg, sizeof(arg));
		if(StrEqual(arg, "0")) weapontype[client]=0;
		else if(StrEqual(arg, "1"))  weapontype[client]=1;
		else if(StrEqual(arg, "2"))  weapontype[client]=2;
		else if(StrEqual(arg, "3"))  weapontype[client]=3;
		else if(StrEqual(arg, "4"))  weapontype[client]=4;
		else if(StrEqual(arg, "5"))  weapontype[client]=5;
		else 
		{
			weapontype[client]=GetRandomInt(0, 5);
		}
			
	}	
	else
	{
		weapontype[client]=GetRandomInt(0, 5);
	}
	bullet[client]=weaponclipsize[weapontype[client]];
	
	new Float:vAngles[3];
	new Float:vOrigin[3];
	new Float:pos[3];
 

	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);

	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SOLID,  RayType_Infinite, TraceEntityFilterPlayer);

	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(pos, trace);
	}
	CloseHandle(trace);


	decl Float:v1[3];
	decl Float:v2[3];
	 
	SubtractVectors(vOrigin, pos, v1);
	NormalizeVector(v1, v2);

	ScaleVector(v2, 50.0);

	AddVectors(pos, v2, v1);  // v1 explode taget
	new ent=0;

 	ent=CreateEntityByName(MODEL[weapontype[client]]);            // Create explosion env_physexplosion env_explosion
  	DispatchSpawn(ent);          
  	TeleportEntity(ent, v1, NULL_VECTOR, NULL_VECTOR);
 
	SetEntityMoveType(ent, MOVETYPE_FLY);
	
	SetClientViewEntity( client, ent );
	
	
	
	
	keybuffer[client]=0;
	bullet[client]=0;
	reloading[client]=false;
	reloadtime[client]=0.0;
	firetime[client]=0.0;
	robot[client]=ent;
	third(client, 0);
	PrintHintText(client, "you controlled a robot,press E to exit, press \\ set view");
	PrintToChatAll("\x04 %N \x03use remote control system", client);
	return Plugin_Handled;
} 

new Float:duration=0.0;
new Float:lasttime=0.0;

new button;

new Float:robotpos[3];
new Float:robotdirection1[3];
new Float:cardirection2[3];
 
 
new Float:clientangle[3];

new Float:flyspeed;
new Float:sidespeed;
new Float:chargetime;

bool:IsPlayerIncapped(client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1)) return true;
 	return false;
}

Do(client, Float:currenttime)
{
	if(robot[client]>0)
	{
		if (!IsValidEntity(robot[client]) || IsFakeClient(client) || !IsValidAliveClient(client) || IsPlayerIncapped(client))
		{
			Release(client);
		}
		else  
		{
		
			GetEntPropVector(robot[client], Prop_Send, "m_vecOrigin", robotpos);
 			GetClientEyeAngles(client, clientangle);
			 
			GetAngleVectors(clientangle,robotdirection1, NULL_VECTOR, NULL_VECTOR);
			NormalizeVector(robotdirection1,robotdirection1);
			
			sidespeed=MaxSpeed;
			button=GetClientButtons(client);
			new Float:accuracy=1.2;
			if( button & IN_DUCK  )
			{
				sidespeed=MaxSpeed/2.0;
				flyspeed=MaxSpeed/2.0;
				accuracy=0.6;
			}
			else if( button & IN_SPEED)
			{
				sidespeed=MaxSpeed*1.0;
				flyspeed=MaxSpeed*1.0;
				robotdirection1[2]=0.0;
				accuracy=1.0;
			}
			else
			{
				sidespeed=MaxSpeed;
				flyspeed=MaxSpeed;
			}			

			if(button & IN_FORWARD)
			{
				accuracy=1.4;
			}
			else if(button & IN_BACK)
			{
				flyspeed=(0.0-flyspeed);
				accuracy=1.4;
			}
			else 
			{
				flyspeed=0.0;
			}
		
		 
			if((button & IN_USE) && !(keybuffer[client] & IN_USE))
			{
				Release(client); 
				return;
				
			}
			ScaleVector(robotdirection1, flyspeed);

 			new Float:B=0.0;
			
			if(button & IN_MOVERIGHT)
			{
				 B=-3.1415926/2.0;
				 accuracy=1.4;
	
			}
			else if(button & IN_MOVELEFT)
			{
				B=3.1415926/2.0;
				accuracy=1.4;

 			}
			
/*
new Float:fireinterval[6]={0.25, 0.065, 0.23, 0.65, 0.055, 0.03 };
new Float:bulletaccuracy[6]={0.5, 1.0, 3.0, 3.0, 2.0, 2.2 };
new weaponbulletdamage[6]={90.0, 60.0, 10.0, 10.0, 30.0, 30.0};
new weaponclipsize[6]={15, 30, 10, 10, 30, 30};
new weaponbulletpershot[6]={1, 1, 7, 7, 1, 1};
new weaponauto[6]={1, 1, 1, 0, 1, 0};
new Float:weaponloadtime[6]={2.0, 2.0, 0.5, 0.5, 2.0, 2.0};
new weaponloadcount[6]={15, 30, 1, 1, 30, 30};
*/
			 
					 //EmitSoundToClient(client, "");
			 

			if(reloading[client])
			{
				//PrintToChatAll("%f", reloadtime[client]);
				if(bullet[client]>=weaponclipsize[weapontype[client]] && currenttime-reloadtime[client]>weaponloadtime[weapontype[client]])
				{
					reloading[client]=false;	
					reloadtime[client]=currenttime;
					EmitSound2(client, SOUNDREADY);
					PrintHintText(client, " ");
				}
				else 
				{
					
					if(currenttime-reloadtime[client]>weaponloadtime[weapontype[client]])
					{
						reloadtime[client]=currenttime;
						bullet[client]+=weaponloadcount[weapontype[client]];
						EmitSound2(client, SOUNDRELOAD);
						PrintHintText(client, "reloading %d", bullet[client]);
					}
					
				}
			}
			if(!reloading[client])
			{
				if((button & IN_RELOAD) && !(keybuffer[client] & IN_RELOAD)) 
				{
					if(bullet[client]<weaponclipsize[weapontype[client]])					
					{
						reloading[client]=true;	
						reloadtime[client]=0;
						if(!weaponloaddisrupt[weapontype[client]])
						{
							bullet[client]=0;
						}
						
					}
					
				}	
			}
			if(DamageType>0)chargetime=FireChargeTime;
			else chargetime=fireinterval[weapontype[client]];
			//chargetime=FireChargeTime;	
			if(!reloading[client] || weaponloaddisrupt[weapontype[client]])
			{
				if(currenttime-firetime[client]>chargetime)
				{
	 
					if((button & IN_JUMP) || (button & IN_ATTACK2)) 
					{
						if(weaponauto[weapontype[client]]==1 || !(keybuffer[client] & IN_JUMP))
						{
							if(bullet[client]>0)
							{
								bullet[client]=bullet[client]-1;
								
								if(DamageType==0)	FireBullet(client, robot[client], accuracy);
								else FireExplde(client, robot[client]);
								firetime[client]=currenttime;	
								if(reloading[client]) PrintHintText(client, " ");
								reloading[client]=false;
							}
							else
							{
								firetime[client]=currenttime;
								//PrintHintText(client, "out of ammo");
								EmitSound2(client, SOUNDCLIPEMPTY);
								reloading[client]=true;	
								reloadtime[client]=currenttime;
							}
						}
					}

				}

			}
	
	
			if(B!=0.0)
			{
				GetAngleVectors(clientangle,cardirection2, NULL_VECTOR, NULL_VECTOR);
  				new Float:x0=cardirection2[0];
				new Float:y0=cardirection2[1];
				new Float:x1=x0*Cosine(B)-y0*Sine(B);
				new Float:y1=x0*Sine(B)+y0*Cosine(B);
				cardirection2[0]=x1;
				cardirection2[1]=y1;
				cardirection2[2]=0.0;
				NormalizeVector(cardirection2,cardirection2);
				ScaleVector(cardirection2, sidespeed);
				AddVectors(robotdirection1, cardirection2, robotdirection1);
			}
			 
			{
				TeleportEntity(robot[client], NULL_VECTOR, clientangle, robotdirection1);
			}
			 
			SetEntityMoveType(client, MOVETYPE_NONE);//MOVETYPE_NONE
			keybuffer[client]=button;

		}
	}
}
public OnGameFrame()
{

	new Float:currenttime=GetEngineTime();
	duration=currenttime-lasttime;
	if(duration<0.0)duration=0.0;
	 
	for (new client = 1; client <= MaxClients; client++)
	{
		Do(client, currenttime);
	}
    lasttime=currenttime;
}
FireBullet(controller, bot, Float:accuracy)
{
	decl Float:vAngles[3];
	decl Float:vOrigin[3];
	decl Float:vOrigin2[3];
	decl Float:vAngles2[3];
	decl Float:pos[3];

	GetEntPropVector(bot, Prop_Send, "m_vecOrigin", vOrigin);
 	GetClientEyeAngles(controller, vAngles);
	new Float:arr1, arr2;
	arr1=0.0-bulletaccuracy[weapontype[controller]]*accuracy;	
	arr2=bulletaccuracy[weapontype[controller]]*accuracy;
	
	decl Float:v1[3];
	decl Float:v2[3];
	//PrintToChatAll("%f %f",arr1, arr2);
	for(new c=0; c<weaponbulletpershot[weapontype[controller]];c++)
	{
		//PrintToChatAll("fire");
		vAngles2[0]=vAngles[0]+GetRandomFloat(arr1, arr2);	
		vAngles2[1]=vAngles[1]+GetRandomFloat(arr1, arr2);	
		vAngles2[2]=vAngles[2]+GetRandomFloat(arr1, arr2);	
 
		new hittarget=0;
		new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles2, MASK_SOLID, RayType_Infinite, TraceRayDontHitSelf, bot);
		
		if(TR_DidHit(trace))
		{
			
			TR_GetEndPosition(pos, trace);
			hittarget=TR_GetEntityIndex( trace);
			
		}
		CloseHandle(trace);

			
		if(hittarget>0)		
		{
			/*if(IsValidAliveClient(hittarget))
			{
				//PrintToChatAll("boss");
				DoPointHurtForInfected(100, hittarget, controller,2, "weapon_rifle");
			}
			else
			{
				decl String:edictname[128];
				GetEdictClassname(hittarget, edictname, 128);
				if(StrContains(edictname, "infected")>=0)
				{
					//PrintToChatAll("infected");
					//DoPointHurt(100.0, 50.0, pos);
					DoPointHurtForInfected(100, hittarget, controller,2);
				}
				else
				{
					DoPointHurtForInfected(100, hittarget, controller,2);
				}
			}*/
			DoPointHurtForInfected(weapontype[controller], hittarget, controller,2);
		}
		
		
		SubtractVectors(vOrigin, pos, v1);
		NormalizeVector(v1, v2);	
		ScaleVector(v2, 36.0);
		SubtractVectors(vOrigin, v2, vOrigin2);
	 
		decl color[4];
		color[0] = 200; 
		color[1] = 200;
		color[2] = 200;
		color[3] = 230;
		
		new Float:life=0.06;
		new Float:width1=0.01;
		new Float:width2=0.6;		
	 
  
		TE_SetupBeamPoints(vOrigin2, pos, g_sprite, 0, 0, 0, life, width1, width2, 1, 0.0, color, 0);
		TE_SendToAll();
 
		//EmitAmbientSound(SOUND[weapontype[controller]], vOrigin, controller, SNDLEVEL_RAIDSIREN);
		EmitSoundToAll(SOUND[weapontype[controller]], 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, vOrigin, NULL_VECTOR, false, 0.0);
   
	 
	}
   
}
FireExplde(controller, bot)
{
	decl Float:vAngles[3];
	decl Float:vOrigin[3];
	decl Float:vOrigin2[3];
	decl Float:pos[3];

	GetEntPropVector(bot, Prop_Send, "m_vecOrigin", vOrigin);
 
	GetClientEyeAngles(controller, vAngles);
	vAngles[0]+=GetRandomFloat(-1.0, 1.0);	
	vAngles[1]+=GetRandomFloat(-1.0, 1.0);
	vAngles[2]+=GetRandomFloat(-1.0, 1.0);

	
 	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SOLID, RayType_Infinite, TraceRayDontHitSelf, bot);
	
	if(TR_DidHit(trace))
	{
		
		TR_GetEndPosition(pos, trace);
		
		
	}
	CloseHandle(trace);
	 
	decl Float:v1[3];
	decl Float:v2[3];
	decl Float:v3[3];

	SubtractVectors(vOrigin, pos, v1);
	NormalizeVector(v1, v2);

	v3[0]=v2[0];
	v3[1]=v2[1];
	v3[2]=v2[2];

	ScaleVector(v2, 25.0);

	AddVectors(pos, v2, v1); 
	

	new ent1 = 0;
	new style=GetConVarInt(l4d_hightech_style);

	if(style==3)
	{
		ent1=CreateEntityByName("prop_physics"); 
 		DispatchKeyValue(ent1, "model", "models/props_junk/propanecanister001a.mdl"); 
		DispatchSpawn(ent1); 
		TeleportEntity(ent1, v1, NULL_VECTOR, NULL_VECTOR);
		ActivateEntity(ent1);
		SetEntityRenderMode(ent1, RenderMode:3);
		SetEntityRenderColor(ent1, 0, 0, 0, 0);
		AcceptEntityInput(ent1, "Ignite");
 		AcceptEntityInput(ent1, "break");
		RemoveEdict(ent1);
	}
	else if(style==1 )
	{
		ShowParticle(v1, "gas_explosion_pump", 0.01);	
	}
	
	if(style==2)
	{
		decl Float:vec[3];
 		vec[0]=GetRandomFloat(-1.0, 1.0);
		vec[1]=GetRandomFloat(-1.0, 1.0);
		vec[2]=GetRandomFloat(-1.0, 1.0);
		TE_SetupSparks(v1,vec,255,5);
		TE_SendToAll();
	}
	new Float:damage=GetConVarFloat(l4d_hightech_damage);
	new Float:radius=GetConVarFloat(l4d_hightech_radius);
	new Float:force=GetConVarFloat(l4d_hightech_pushforce);

	
		DoPointHurt(controller,damage, radius, v1);
		if(force>=10.0)
		{
			DoPointPush(force, radius, v1);
		}


	ScaleVector(v3, 36.0);
	SubtractVectors(vOrigin, v3, vOrigin2);
 
	decl color[4];
	color[0] = 200; 
	color[1] = 220;
	color[2] = 220;
	color[3] = 230;
	
	new Float:life;
	new Float:width;
	
	 
		life = 0.2;	
		width = 4.0;
	 

	TE_SetupBeamPoints(vOrigin2, pos, g_sprite, 0, 0, 0, life, width, width, 1, 0.0, color, 0);
	TE_SendToAll();

	//new Handle:hBf = StartMessageOne("Shake", controller);
	//BfWriteByte(hBf, 0);
	//BfWriteFloat(hBf,6.0);
	//BfWriteFloat(hBf,1.0);
	//BfWriteFloat(hBf,1.0);
	//EndMessage();
	//CreateTimer(0.5, StopShake, controller);


	//EmitAmbientSound(SOUND[weapontype[controller]], vOrigin, controller, SNDLEVEL_RAIDSIREN);
	EmitSoundToAll(SOUND[weapontype[controller]], 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, vOrigin, NULL_VECTOR, false, 0.0);
   
}
EmitSound2(client, String:s[50])
{
	decl Float:pos[3];
	GetEntPropVector(robot[client], Prop_Send, "m_vecOrigin", pos);
	EmitSoundToAll(s, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, pos, NULL_VECTOR, false, 0.0);
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
new String:N[10];
DoPointHurtForInfected(wtype ,victim, attacker=0,dmg_type=0)
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
				DispatchKeyValue(g_PointHurt,"Damage",weaponbulletdamage[wtype]);
				AcceptEntityInput(g_PointHurt,"Hurt",(attacker>0)?attacker:-1);
			}
		}
	}
	else g_PointHurt=CreatePointHurt();
}
/*
DoPointHurtForInfected(wtype ,victim, attacker=0,dmg_type=0)
{
	if(victim>0 && IsValidEdict(victim)  )
	{		
		decl String:dmg_type_str[32];
		IntToString(dmg_type,dmg_type_str,32);
		//PrintToChatAll("%s", dmg_str);
		new pointHurt=CreateEntityByName("point_hurt");
		if(pointHurt)
		{
			new String:N[20];
			Format(N, 20, "target%d", victim);
			DispatchKeyValue(victim,"targetname", N);
			DispatchKeyValue(pointHurt,"DamageTarget", N);
			DispatchKeyValue(pointHurt,"Damage",weaponbulletdamage[wtype]);
			DispatchKeyValue(pointHurt,"DamageType",dmg_type_str);
			//DispatchKeyValue(pointHurt,"classname","weapon_ak47");
			DispatchSpawn(pointHurt);
			AcceptEntityInput(pointHurt,"Hurt",(attacker>0)?attacker:-1);
			RemoveEdict(pointHurt);
		}
	}
}
*/

DoPointHurt(attacker,Float:damage, Float:radius, Float:pos[3])
{
	new pointHurt = CreateEntityByName("point_hurt");   
	DispatchKeyValueFloat(pointHurt, "Damage", damage);        
	DispatchKeyValueFloat(pointHurt, "DamageRadius", radius);     
	DispatchKeyValue(pointHurt, "DamageDelay", "0.0");   
 
	DispatchSpawn(pointHurt);
	TeleportEntity(pointHurt,pos, NULL_VECTOR, NULL_VECTOR);  
 
	AcceptEntityInput(pointHurt, "Hurt", attacker);    

	CreateTimer(0.1, DeletePointHurt, pointHurt); 
}
DoPointPush(Float:force, Float:radius, Float:pos[3])
{
	new push = CreateEntityByName("point_push");         
	DispatchKeyValueFloat (push, "magnitude", force);                     
	DispatchKeyValueFloat (push, "radius", radius*1.0);                     
	SetVariantString("spawnflags 24");                     
	AcceptEntityInput(push, "AddOutput");
	DispatchSpawn(push);   
	TeleportEntity(push, pos, NULL_VECTOR, NULL_VECTOR);  
	AcceptEntityInput(push, "Enable");
	CreateTimer(0.5, DeletePushForce, push);
	
	PushAway(pos, force, radius);
}
public Action:StopShake(Handle:timer, any:target)
{
	if (target <= 0) return;
	if (!IsClientInGame(target)) return;
	
	new Handle:hBf=StartMessageOne("Shake", target);
	BfWriteByte(hBf, 0);
	BfWriteFloat(hBf,0.0);
	BfWriteFloat(hBf,0.0);
	BfWriteFloat(hBf,0.0);
	EndMessage();
}

public bool:TraceRayDontHitSelf(entity, mask, any:data)
{
	if(entity == data) 
	{
		return false; 
	}
	return true;
}
PushAway( Float:pos[3], Float:force, Float:radius)
{
 	new Float:limit=200.0;
	new Float:normalfactor=0.8;
	new Float:tankfactor=0.15;
	new Float:survivorfactor=0.4;
	new Float:factor;
	new Float:r;


	for (new target = 1; target <= MaxClients; target++)
	{
		if (IsClientInGame(target))
		{
			if (IsPlayerAlive(target))
			{
					decl Float:targetVector[3];
					GetClientEyePosition(target, targetVector);
													
					new Float:distance = GetVectorDistance(targetVector, pos);

					if(GetClientTeam(target)==2)
					{
						factor=survivorfactor;
						r=radius*0.8;
 					}
					else if(GetClientTeam(target)==3)
					{
 						new class = GetEntProp(target, Prop_Send, "m_zombieClass");
						if(class==5)
						{
							factor=tankfactor;
							r=radius*1.0;
						}
						else
						{
							factor=normalfactor;
							r=radius*1.3;
						}
					}
							
					if (distance < r )
					{
						decl Float:vector[3];
					
						MakeVectorFromPoints(pos, targetVector, vector);
								
						NormalizeVector(vector, vector);
						ScaleVector(vector, force);
						if(vector[2]<0.0)vector[2]=10.0;

						vector[0]*=factor;
						vector[1]*=factor;
						vector[2]*=factor;

						vector[0]*=factor;
						vector[1]*=factor;
						vector[2]*=factor;
						if(vector[0]>limit)
						{
							vector[0]=limit;
						}
						if(vector[1]>limit)
						{
							vector[1]=limit;
						}
						if(vector[2]>limit)
						{
							vector[2]=limit;
						}

						if(vector[0]<-limit)
						{
							vector[0]=-limit;
						}
						if(vector[1]<-limit)
						{
							vector[1]=-limit;
						}
						if(vector[2]<-limit)
						{
							vector[2]=-limit;
						}
 						TeleportEntity(target, NULL_VECTOR, NULL_VECTOR, vector);				
				 
 					}
			 
			}
		}
	}

}
public Action:DeletePushForce(Handle:timer, any:ent)
{
	 if (IsValidEntity(ent))
	 {
		 decl String:classname[64];
		 GetEdictClassname(ent, classname, sizeof(classname));
		 if (StrEqual(classname, "point_push", false))
				{
 					AcceptEntityInput(ent, "Disable");
					AcceptEntityInput(ent, "Kill"); 
					RemoveEdict(ent);
				}
	 }
}
public Action:DeletePointHurt(Handle:timer, any:ent)
{
	 if (IsValidEntity(ent))
	 {
		 decl String:classname[64];
		 GetEdictClassname(ent, classname, sizeof(classname));
		 if (StrEqual(classname, "point_hurt", false))
				{
					AcceptEntityInput(ent, "Kill"); 
					RemoveEdict(ent);
				}
		 }

}
public ShowParticle(Float:pos[3], String:particlename[], Float:time)
{
 new particle = CreateEntityByName("info_particle_system");
 if (IsValidEdict(particle))
 {
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(particle, "effect_name", particlename);
		DispatchKeyValue(particle, "targetname", "particle");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(time, DeleteParticles, particle);
 } 
}
public PrecacheParticle(String:particlename[])
{
 new particle = CreateEntityByName("info_particle_system");
 if (IsValidEdict(particle))
 {
		DispatchKeyValue(particle, "effect_name", particlename);
		DispatchKeyValue(particle, "targetname", "particle");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(0.01, DeleteParticles, particle);
 } 
}
public Action:DeleteParticles(Handle:timer, any:particle)
{
	 if (IsValidEntity(particle))
	 {
		 decl String:classname[64];
		 GetEdictClassname(particle, classname, sizeof(classname));
		 if (StrEqual(classname, "info_particle_system", false))
			{
				AcceptEntityInput(particle, "stop");
				AcceptEntityInput(particle, "kill");
				RemoveEdict(particle);
			}
	 }
}

public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return (entity > MaxClients || !entity);
} 

stock bool:IsValidAliveClient(iClient)
{
    if (iClient <= 0) return false;
    if (iClient > MaxClients) return false;
    if(!IsClientInGame(iClient))return false;
    if (!IsPlayerAlive(iClient)) return false;
 	return true;
}
public Action:third(client, args)
{
 	ClientCommand(client, "thirdpersonshoulder", "");
	ClientCommand(client, "c_thirdpersonshoulderoffset 0", "");
	ClientCommand(client, "c_thirdpersonshoulderaimdist 720", "");
	ClientCommand(client, "cam_ideallag 0", "");
	if(weapontype[client]==0)	{
	    ClientCommand(client, "cam_idealdist 30", "");
		ClientCommand(client, "c_thirdpersonshoulderheight 12", "");
	}
	else if(weapontype[client]==1)
	{
	    ClientCommand(client, "cam_idealdist 30", "");
		ClientCommand(client, "c_thirdpersonshoulderheight 10", "");
	}
	else if(weapontype[client]==2)
	{
	    ClientCommand(client, "cam_idealdist 30", "");
		ClientCommand(client, "c_thirdpersonshoulderheight 8", "");
	}
	else if(weapontype[client]==3)
	{
	    ClientCommand(client, "cam_idealdist 30", "");
		ClientCommand(client, "c_thirdpersonshoulderheight 8", "");
	}
	else if(weapontype[client]==4)
	{
	    ClientCommand(client, "cam_idealdist 30", "");
		ClientCommand(client, "c_thirdpersonshoulderheight 8", "");
	}
	else if(weapontype[client]==5)
	{
	    ClientCommand(client, "cam_idealdist 30", "");
		ClientCommand(client, "c_thirdpersonshoulderheight 5", "");
	}
	else  
	{
	    ClientCommand(client, "cam_idealdist 40", "");
		ClientCommand(client, "c_thirdpersonshoulderheight 15", "");
	}
	return Plugin_Handled;
}
public Action:first(client, args)
{
 	ClientCommand(client, "thirdpersonshoulder");
	ClientCommand(client, "c_thirdpersonshoulder 0");
 	return Plugin_Handled;
}
 