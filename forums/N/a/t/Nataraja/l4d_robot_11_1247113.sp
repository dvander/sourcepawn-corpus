#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdktools_functions>

#define SOUNDCLIPEMPTY           "weapons/ClipEmpty_Rifle.wav" 
#define SOUNDRELOAD              "weapons/shotgun/gunother/shotgun_load_shell_2.wav" 
#define SOUNDREADY          	 "weapons/shotgun/gunother/shotgun_pump_1.wav"

#define WEAPONCOUNT 17

#define SOUND0 "weapons/hunting_rifle/gunfire/hunting_rifle_fire_1.wav" 
#define SOUND1 "weapons/rifle/gunfire/rifle_fire_1.wav" 
#define SOUND2 "weapons/auto_shotgun/gunfire/auto_shotgun_fire_1.wav" 
#define SOUND3 "weapons/shotgun/gunfire/shotgun_fire_1.wav" 
#define SOUND4 "weapons/SMG/gunfire/smg_fire_1.wav" 
#define SOUND5 "weapons/pistol/gunfire/pistol_fire.wav" 
#define SOUND6 "weapons/magnum/gunfire/magnum_shoot.wav" 
#define SOUND7 "weapons/rifle_ak47/gunfire/rifle_fire_1.wav" 
#define SOUND8 "weapons/rifle_desert/gunfire/rifle_fire_1.wav" 
#define SOUND9 "weapons/sg552/gunfire/sg552-1.wav"
#define SOUND10 "weapons/shotgun_chrome/gunfire/shotgun_fire_1.wav"
#define SOUND11 "weapons/auto_shotgun_spas/gunfire/shotgun_fire_1.wav"
#define SOUND12 "weapons/sniper_military/gunfire/sniper_military_fire_1.wav"
#define SOUND13 "weapons/scout/gunfire/scout_fire-1.wav"
#define SOUND14 "weapons/awp/gunfire/awp1.wav"
#define SOUND15 "weapons/mp5navy/gunfire/mp5-1.wav"
#define SOUND16 "weapons/smg_silenced/gunfire/smg_fire_1.wav"

#define MODEL0 "weapon_hunting_rifle"
#define MODEL1 "weapon_rifle"
#define MODEL2 "weapon_autoshotgun"
#define MODEL3 "weapon_pumpshotgun"
#define MODEL4 "weapon_smg"
#define MODEL5 "weapon_pistol"
#define MODEL6 "weapon_pistol_magnum"
#define MODEL7 "weapon_rifle_ak47"
#define MODEL8 "weapon_rifle_desert"
#define MODEL9 "weapon_rifle_sg552"
#define MODEL10 "weapon_shotgun_chrome"
#define MODEL11 "weapon_shotgun_spas"
#define MODEL12 "weapon_sniper_military"
#define MODEL13 "weapon_sniper_scout"
#define MODEL14 "weapon_sniper_awp"
#define MODEL15 "weapon_smg_mp5"
#define MODEL16 "weapon_smg_silenced"

//我加的
new PropGhost;

new g_PointHurt=0;
new String:SOUND[WEAPONCOUNT+3][70]=
{SOUND0, SOUND1, SOUND2, SOUND3, SOUND4, SOUND5, SOUND6, SOUND7,SOUND8,SOUND9, SOUND10, SOUND11,SOUND12,SOUND13,SOUND14, SOUND15,SOUND16,SOUNDCLIPEMPTY, SOUNDRELOAD, SOUNDREADY};

new String:MODEL[WEAPONCOUNT][32]=
{MODEL0, MODEL1, MODEL2, MODEL3, MODEL4, MODEL5,MODEL6, MODEL7,MODEL8,MODEL9,MODEL10, MODEL11, MODEL12 ,MODEL13,MODEL14, MODEL15, MODEL16};

new String:weaponbulletdamagestr[WEAPONCOUNT][10]={"", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", ""};

//weapon data
new Float:fireinterval[WEAPONCOUNT]={0.25, 0.068, 0.30, 0.65, 0.060, 0.20, 0.33, 0.145, 0.14, 0.064, 0.65, 0.30, 0.265, 0.9, 1.25, 0.065, 0.055};

new Float:bulletaccuracy[WEAPONCOUNT]={1.15, 1.4, 3.5, 3.5, 1.6, 1.7 , 1.7, 1.5, 1.6, 1.5, 3.5, 3.5, 1.15, 1.00, 0.8, 1.6 ,1.6};

new Float:weaponbulletdamage[WEAPONCOUNT]={90.0, 30.0, 25.0, 30.0, 20.0, 30.0, 60.0, 70.0, 40.0, 40.0, 30.0, 30.0, 90.0, 100.0, 150.0, 35.0, 35.0};

new weaponclipsize[WEAPONCOUNT]={15, 50, 10, 8, 50, 30, 8, 40, 20, 50, 8, 10, 30, 15, 20, 50, 50};

new weaponbulletpershot[WEAPONCOUNT]={1, 1, 7, 7, 1, 1, 1, 1, 1, 1, 7, 7,1, 1, 1,1,1};

new Float:weaponloadtime[WEAPONCOUNT]={2.0, 1.5, 0.3, 0.3, 1.5, 1.5, 1.9, 1.5, 1.5, 1.6, 0.3, 0.3, 2.0,2.0, 2.0, 1.5, 1.5};

new weaponloadcount[WEAPONCOUNT]={15, 50, 1,1, 50, 30, 8, 40, 60, 50, 1, 1, 30, 15, 20, 50, 50};

new bool:weaponloaddisrupt[WEAPONCOUNT]={false,false, true, true,false,false, false, false, false, true, true, false, false, false, false, false};
//weapon data

new robot[MAXPLAYERS+1];
new keybuffer[MAXPLAYERS+1];
new weapontype[MAXPLAYERS+1];
new bullet[MAXPLAYERS+1];
new Float:firetime[MAXPLAYERS+1];
new bool:reloading[MAXPLAYERS+1];
new Float:reloadtime[MAXPLAYERS+1];
new Float:scantime[MAXPLAYERS+1];
new Float:botenerge[MAXPLAYERS+1];

new SIenemy[MAXPLAYERS+1];
new CIenemy[MAXPLAYERS+1];
//new Float:CIenemyTime[MAXPLAYERS+1];

new Float:robotangle[MAXPLAYERS+1][3];

new Handle:l4d_robot_limit = INVALID_HANDLE;
new Handle:l4d_robot_reactiontime = INVALID_HANDLE;
new Handle:l4d_robot_scanrange = INVALID_HANDLE; 
new Handle:l4d_robot_energy= INVALID_HANDLE; 
new Handle:l4d_robot_damagefactor= INVALID_HANDLE; 

new Float:robot_reactiontime;
new Float:robot_scanrange; 
new Float:robot_energy;
new Float:robot_damagefactor;

new g_sprite;
 
new bool:L4D2Version=false;
new GameMode=0;

new bool:gamestart=false;

public Plugin:myinfo = 
{
	name = "Robot system",
	author = "Pan Xiaohai",
	description = "Robot system",
	version = "1.1",
	url = "http://forums.alliedmods.net"
}
public OnPluginStart()
{
 	l4d_robot_limit = CreateConVar("l4d_robot_limit", "2", "number of robot [0-3]", FCVAR_PLUGIN);
  	l4d_robot_reactiontime = CreateConVar("l4d_robot_reactiontime", "2.0", "robot reaction time [0.5,5.0]", FCVAR_PLUGIN);
  	l4d_robot_scanrange = CreateConVar("l4d_robot_scanrange", "600.0", "scan enemy range[100.0, 10000.0]", FCVAR_PLUGIN);
 	l4d_robot_energy = CreateConVar("l4d_robot_energy", "5.0", "time limit  of a robot for a player (minutes)[0.0, 100.0]", FCVAR_PLUGIN);
	l4d_robot_damagefactor = CreateConVar("l4d_robot_damagefactor", "0.5", "damage factor [0.2,1.0]", FCVAR_PLUGIN);
	

	AutoExecConfig(true, "l4d_robot_11");
	HookConVarChange(l4d_robot_reactiontime, ConVarChange);
	HookConVarChange(l4d_robot_scanrange, ConVarChange); 
	HookConVarChange(l4d_robot_energy, ConVarChange);
	HookConVarChange(l4d_robot_damagefactor, ConVarChange);
	GetConVar();

	//我加的
	PropGhost	=	FindSendPropInfo("CTerrorPlayer", "m_isGhost");
	
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
 
 	RegConsoleCmd("sm_robot", sm_robot);
	HookEvent("player_use", player_use);
	HookEvent("round_start", RoundStart);
	
	HookEvent("player_hurt", Event_PlayerHurt);
	
	HookEvent("round_end", RoundEnd);
	HookEvent("finale_win", RoundEnd);
	HookEvent("mission_lost", RoundEnd);
	HookEvent("map_transition", RoundEnd);
	HookEvent("player_spawn", Event_Spawn);	 
 	gamestart=false	;
	
}
GetConVar()
{
  	robot_reactiontime=GetConVarFloat(l4d_robot_reactiontime );
  	robot_scanrange=GetConVarFloat(l4d_robot_scanrange );
 	robot_energy=GetConVarFloat(l4d_robot_energy )*60.0;
 	robot_damagefactor=GetConVarFloat(l4d_robot_damagefactor);
	new String:str[10];
	for(new i=0; i<WEAPONCOUNT; i++)
	{
		Format(str, sizeof(str), "%d", RoundFloat(weaponbulletdamage[i]*robot_damagefactor));
		weaponbulletdamagestr[i]=str;
	}
}
public ConVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	GetConVar();
}

public OnMapStart()
{

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

	
	if(L4D2Version)
	{
		g_sprite = PrecacheModel("materials/sprites/laserbeam.vmt");	
		
		for(new i=6; i<WEAPONCOUNT; i++)
		{
			PrecacheModel( MODEL[i] , true );
			PrecacheSound(SOUND[i], true) ;
		}
	}
	else
	{
		g_sprite = PrecacheModel("materials/sprites/laser.vmt");	
 
	}
	gamestart=false	;
	
}

public Action:RoundStart (Handle:event, const String:name[], bool:dontBroadcast)
{

	for (new i = 1; i <= MaxClients; i++)
	{
		if(robot[i]>0)
		{
			Release(i, false);	 
 		}
		botenerge[i]=0.0;
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
	gamestart=false;
	 
  	return Plugin_Continue;
}
public player_use (Handle:hEvent, const String:name[], bool:dontBroadcast)
{
	new client=GetClientOfUserId(GetEventInt(hEvent, "userid"));
	new entity = GetEventInt(hEvent, "targetid");
	for (new i = 1; i <= MaxClients; i++)
	{
		if(robot[i]>0 && robot[i]==entity)
		{
			//RemovePlayerItem(client, entity);
			PrintHintText(i, "%N try to steal your robot", client);
			PrintHintText(client, "you try to steal %N 's robot",i);
			Release(i);	
			AddRobot(i);
 		}
	} 
	 
}
public Event_Spawn(Handle:Spawn_Event, const String:Spawn_Name[], bool:Spawn_Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(Spawn_Event, "userid"));
	robot[client]=0;
}

public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!gamestart)return;
	new  attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new  victim = GetClientOfUserId(GetEventInt(event, "userid"));
	if(attacker>0 )
	{	
		if(attacker!=victim && GetClientTeam(attacker)==3)
		{
			scantime[victim]=GetEngineTime();
			SIenemy[victim]=attacker;
		}
	}
	else
	{
		new ent= GetEventInt(event, "attackerentid");	
		CIenemy[victim]=ent;
	}
}
DelRobot(ent)
{
	if (ent > 0 && IsValidEntity(ent))
    {
		decl String:item[65]; 
		GetEdictClassname(ent, item, sizeof(item));
		if(StrContains(item, "weapon")>=0) 
		{ 
			RemoveEdict(ent);
		}
    }
}
 
Release(controller, bool:del=true)
{
	new r=robot[controller];
	if(r>0)
	{
		robot[controller]=0;
	 
		if(del)DelRobot(r);
	}
	if(gamestart)
	{
		new count=0;
		for (new i = 1; i <= MaxClients; i++)
		{
			if(robot[i]>0)
			{
				count++; 
			}
		}
		if(count==0) gamestart=false;
	}
}

public Action:sm_robot(client, args)
{  
	//if(GameMode==2)return Plugin_Continue;
	if(!IsValidAliveClient(client))	return Plugin_Continue;
	if(robot[client]>0)
	{
		PrintToChat(client, "you already have a robot");
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
	
	if(count+1>GetConVarInt(l4d_robot_limit))
	{
		PrintToChat(client, "no more robot");
		return Plugin_Handled;
	}
	//	#define MODEL0 "weapon_hunting_rifle"
	//#define MODEL1 "weapon_rifle"
	//#define MODEL2 "weapon_autoshotgun"
	//#define MODEL3 "weapon_pumpshotgun"
	//#define MODEL4 "weapon_smg"
	//#define MODEL5 "weapon_pistol"
	//#define MODEL6 "weapon_pistol_magnum"

	if(args>=1)
	{
		new String:arg[128];
		GetCmdArg(1, arg, sizeof(arg));
		if(StrContains(arg, "hunting", false)!=-1) weapontype[client]=0;	
		else if(StrContains(arg, "rifle", false)!=-1) weapontype[client]=1;
		else if(StrContains(arg, "auto", false)!=-1) weapontype[client]=2;
		else if(StrContains(arg, "pump", false)!=-1) weapontype[client]=3;
		else if(StrContains(arg, "smg", false)!=-1) weapontype[client]=4;	
		else if(StrContains(arg, "pistol", false)!=-1) weapontype[client]=5;
		else if(StrContains(arg, "magnum", false)!=-1 && L4D2Version) weapontype[client]=6;
		else if(StrContains(arg, "ak47", false)!=-1 && L4D2Version) weapontype[client]=7;		
		else if(StrContains(arg, "desert", false)!=-1 && L4D2Version) weapontype[client]=8;	
		else if(StrContains(arg, "sg552", false)!=-1 && L4D2Version) weapontype[client]=9;	
		else if(StrContains(arg, "chrome", false)!=-1 && L4D2Version) weapontype[client]=10;		
		else if(StrContains(arg, "spas", false)!=-1 && L4D2Version) weapontype[client]=11;		
		else if(StrContains(arg, "military", false)!=-1 && L4D2Version) weapontype[client]=12;		
		else if(StrContains(arg, "scout", false)!=-1 && L4D2Version) weapontype[client]=13;	
		else if(StrContains(arg, "awp", false)!=-1 && L4D2Version) weapontype[client]=14;	
		else if(StrContains(arg, "mp5", false)!=-1 && L4D2Version) weapontype[client]=15;	
		else if(StrContains(arg, "silenced", false)!=-1 && L4D2Version) weapontype[client]=16;	
		else 
		{
			if(L4D2Version)	weapontype[client]=GetRandomInt(0, WEAPONCOUNT-1);
			else weapontype[client]=GetRandomInt(0, 5);
		}
	}	
	else
	{
		if(L4D2Version)	weapontype[client]=GetRandomInt(0, WEAPONCOUNT-1);
		else weapontype[client]=GetRandomInt(0, 5);
	}
	AddRobot(client, true);
	return Plugin_Handled;
} 
AddRobot(client, bool:showmsg=false)
{
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

 	ent=CreateEntityByName(MODEL[weapontype[client]]);         
  	DispatchSpawn(ent);          
  	TeleportEntity(ent, v1, NULL_VECTOR, NULL_VECTOR);
 
	SetEntityMoveType(ent, MOVETYPE_FLY);
	 
	
	SIenemy[client]=0;
	CIenemy[client]=0;
	scantime[client]=0.0;
	keybuffer[client]=0;
	bullet[client]=0;
	reloading[client]=false;
	reloadtime[client]=0.0;
	firetime[client]=0.0;
	robot[client]=ent;
	if(showmsg)
	{
		PrintHintText(client, "you have a robot,press WALK+USE to turn it off");
		PrintToChatAll("\x04 %N \x03 turn on robot", client);
	}
	gamestart=true;
}

new Float:lasttime=0.0;

new button;

new Float:robotpos[3];
new Float:robotvec[3];
 
 
new Float:clienteyepos[3];



new Float:clientangle[3];
new Float:enemypos[3];
new Float:infectedorigin[3];
new Float:infectedeyepos[3];
 
new Float:chargetime;

Do(client, Float:currenttime, Float:duration)
{
	if(robot[client]>0)
	{
		if (!IsValidEntity(robot[client]) || IsFakeClient(client) || !IsValidAliveClient(client) )
		{
			Release(client);
		}
		else  
		{			
			botenerge[client]+=duration;
			if(botenerge[client]>robot_energy)
			{
				Release(client);
				PrintHintText(client, "your bot' energe is not enough");
				return;
			}
			
			button=GetClientButtons(client);
   		 	GetEntPropVector(robot[client], Prop_Send, "m_vecOrigin", robotpos);	
	 		 
			if((button & IN_USE) && (button & IN_SPEED) && !(keybuffer[client] & IN_USE))
			{
				Release(client);
				PrintToChatAll("\x04 %N \x03 turn off robot", client);
				return;
			}
			if(currenttime - scantime[client]>robot_reactiontime)
			{
				scantime[client]=currenttime;
				SIenemy[client]=ScanEnemy(client,robotpos);
				CIenemy[client]=0;
			}
			new targetok=false;
			if(SIenemy[client]>0 && IsClientInGame(SIenemy[client]) && IsPlayerAlive(SIenemy[client]))
			{
				
				GetClientEyePosition(SIenemy[client], infectedeyepos);
				GetClientAbsOrigin(SIenemy[client], infectedorigin);	
				enemypos[0]=infectedorigin[0]*0.4+infectedeyepos[0]*0.6;
				enemypos[1]=infectedorigin[1]*0.4+infectedeyepos[1]*0.6;
				enemypos[2]=infectedorigin[2]*0.4+infectedeyepos[2]*0.6;
				
				SubtractVectors(enemypos, robotpos, robotangle[client]);
				GetVectorAngles(robotangle[client],robotangle[client]);
				targetok=true;
			}
			else 
			{
				SIenemy[client]=0;
			}
			if(!targetok)
			{
				if( CIenemy[client]>0 && IsValidEntity(CIenemy[client]))
				{
					GetEntPropVector(CIenemy[client], Prop_Send, "m_vecOrigin", enemypos);	
					enemypos[2]+=40.0;
					SubtractVectors(enemypos, robotpos, robotangle[client]);
					GetVectorAngles(robotangle[client],robotangle[client]);
					targetok=true;
				}
				else
				{
					CIenemy[client]=0;
				}
			}
			if(reloading[client])
			{
				//PrintToChatAll("%f", reloadtime[client]);
				if(bullet[client]>=weaponclipsize[weapontype[client]] && currenttime-reloadtime[client]>weaponloadtime[weapontype[client]])
				{
					reloading[client]=false;	
					reloadtime[client]=currenttime;
					EmitSoundToAll(SOUNDREADY, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, robotpos, NULL_VECTOR, false, 0.0);
					//PrintHintText(client, " ");
				}
				else 
				{
					if(currenttime-reloadtime[client]>weaponloadtime[weapontype[client]])
					{
						reloadtime[client]=currenttime;
						bullet[client]+=weaponloadcount[weapontype[client]];
						EmitSoundToAll(SOUNDRELOAD, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, robotpos, NULL_VECTOR, false, 0.0);
						//PrintHintText(client, "reloading %d", bullet[client]);
					}
					
				}
			}
			if(!reloading[client])
			{
				if(!targetok) 
				{
					if(bullet[client]<weaponclipsize[weapontype[client]])					
					{
						reloading[client]=true;	
						reloadtime[client]=0.0;
						if(!weaponloaddisrupt[weapontype[client]])
						{
							bullet[client]=0;
						}
						
					}
					
				}	
			}
			chargetime=fireinterval[weapontype[client]];
			 
			if(!reloading[client])
			{
				if(currenttime-firetime[client]>chargetime)
				{
	 					
					if( targetok) 
					{
						if(bullet[client]>0)
						{
							bullet[client]=bullet[client]-1;
							
							FireBullet(client, robot[client], enemypos, robotpos);
						 
							firetime[client]=currenttime;	
						 	reloading[client]=false;
						}
						else
						{
							firetime[client]=currenttime;
						 	EmitSoundToAll(SOUNDCLIPEMPTY, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, robotpos, NULL_VECTOR, false, 0.0);
							reloading[client]=true;	
							reloadtime[client]=currenttime;
						}
						
					}

				}

			}
	

 			GetClientEyePosition(client,  clienteyepos);
			clienteyepos[2]+=30.0;
			GetClientEyeAngles(client, clientangle);
			new Float:distance = GetVectorDistance(robotpos, clienteyepos);
			 
			if(distance>500.0)
			{
				TeleportEntity(robot[client], clienteyepos,  robotangle[client] ,NULL_VECTOR);
			}
			else if(distance>100.0)		
			{

				MakeVectorFromPoints( robotpos, clienteyepos, robotvec);
				NormalizeVector(robotvec,robotvec);
				ScaleVector(robotvec, 5*distance);
				if (!targetok )
				{
					GetVectorAngles(robotvec, robotangle[client]);
				}
				TeleportEntity(robot[client], NULL_VECTOR,  robotangle[client] ,robotvec);
			}
			else 
			{
				robotvec[0]=robotvec[1]=robotvec[2]=0.0;
				if(!targetok && currenttime-firetime[client]>4.0)robotangle[client][1]+=5.0;
				TeleportEntity(robot[client], NULL_VECTOR,  robotangle[client] ,robotvec);
			}
		 	keybuffer[client]=button;
		}
	}
}
public OnGameFrame()
{
	if(!gamestart)return;
	new Float:currenttime=GetEngineTime();
	new Float:duration=currenttime-lasttime;
	if(duration<0.0 || duration>1.0)duration=0.0;
	for (new client = 1; client <= MaxClients; client++)
	{
		Do(client, currenttime, duration);
	}
	
	lasttime = currenttime;
	return;
}
ScanEnemy(client, Float:rpos[3] )
{
	decl Float:infectedpos[3];
	decl Float:vec[3];
	decl Float:angle[3];
 	new find=0;
	new Float:mindis=100000.0;
	new Float:dis=0.0;
	for (new i = 1; i <= MaxClients; i++)
	{
		//我加的
		if(IsClientInGame(i) && GetClientTeam(i)==3 && IsPlayerAlive(i) && GetEntData(i, PropGhost, 1)!=1)
		{
			GetClientEyePosition(i, infectedpos);
			dis=GetVectorDistance(rpos, infectedpos) ;
			//PrintToChatAll("%f %N" ,dis, i);
			if(dis <robot_scanrange && dis<=mindis)
			{
				SubtractVectors(infectedpos, rpos, vec);
				GetVectorAngles(vec, angle);
				new Handle:trace = TR_TraceRayFilterEx(infectedpos, rpos, MASK_SOLID, RayType_EndPoint, TraceRayDontHitSelfAndLive, robot[client]);
			
				if(TR_DidHit(trace))
				{
	
				}
				else
				{
					find=i;
					mindis=dis;
				}
				CloseHandle(trace);
			}
		}
	}
 
	return find;
}
FireBullet(controller, bot, Float:infectedpos[3], Float:botorigin[3])
{
	decl Float:vAngles[3];
	decl Float:vAngles2[3];
	decl Float:pos[3];
 
	
	SubtractVectors(infectedpos, botorigin, infectedpos);
	GetVectorAngles(infectedpos, vAngles);
	 
	new Float:arr1;
	new Float:arr2;
	arr1=0.0-bulletaccuracy[weapontype[controller]];	
	arr2=bulletaccuracy[weapontype[controller]];
	
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
		new Handle:trace = TR_TraceRayFilterEx(botorigin, vAngles2, MASK_SOLID, RayType_Infinite, TraceRayDontHitSelfAndSurvivor, bot);
		
		if(TR_DidHit(trace))
		{
			
			TR_GetEndPosition(pos, trace);
			hittarget=TR_GetEntityIndex( trace);
			
		}
		CloseHandle(trace);

			
		if(hittarget>0)		
		{
			DoPointHurtForInfected(weapontype[controller], hittarget, controller );
		}
		
		
		SubtractVectors(botorigin, pos, v1);
		NormalizeVector(v1, v2);	
		ScaleVector(v2, 36.0);
		SubtractVectors(botorigin, v2, infectedorigin);
	 
		decl color[4];
		color[0] = 200; 
		color[1] = 200;
		color[2] = 200;
		color[3] = 230;
		
		new Float:life=0.06;
		new Float:width1=0.01;
		new Float:width2=0.3;		
		if(L4D2Version)width2=0.08;
  
		TE_SetupBeamPoints(infectedorigin, pos, g_sprite, 0, 0, 0, life, width1, width2, 1, 0.0, color, 0);
		TE_SendToAll();
 
		//EmitAmbientSound(SOUND[weapontype[controller]], vOrigin, controller, SNDLEVEL_RAIDSIREN);
		EmitSoundToAll(SOUND[weapontype[controller]], 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, botorigin, NULL_VECTOR, false, 0.0);
   
	 
	}
   
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
DoPointHurtForInfected(wtype ,victim, attacker=0)
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
				DispatchKeyValue(g_PointHurt,"classname",MODEL[wtype]);
				DispatchKeyValue(g_PointHurt,"Damage",weaponbulletdamagestr[wtype]);
				AcceptEntityInput(g_PointHurt,"Hurt",(attacker>0)?attacker:-1);
			}
		}
	}
	else g_PointHurt=CreatePointHurt();
}
 
public bool:TraceRayDontHitSelf(entity, mask, any:data)
{
	if(entity == data) 
	{
		return false; 
	}
	return true;
}
public bool:TraceRayDontHitSelfAndLive(entity, mask, any:data)
{
	if(entity == data) 
	{
		return false; 
	}
	else if(entity>0 && entity<=MaxClients)
	{
		if(IsClientInGame(entity))
		{
			return false;
		}
	}
	return true;
}
public bool:TraceRayDontHitSelfAndSurvivor(entity, mask, any:data)
{
	if(entity == data) 
	{
		return false; 
	}
	else if(entity>0 && entity<=MaxClients)
	{
		if(IsClientInGame(entity) && GetClientTeam(entity)==2)
		{
			return false;
		}
	}
	return true;
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
 	else
	{
	return true;
	}
}
 
 