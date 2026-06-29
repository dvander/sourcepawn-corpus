#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
 
#define SOUND_SPRINT		"UI/helpful_event_1.wav"

new RunButtons[4]={IN_FORWARD, IN_BACK, IN_MOVELEFT, IN_MOVERIGHT};

new KeyBuffer[MAXPLAYERS+1];
new KeyState[MAXPLAYERS+1];

new Float:KeyTime[MAXPLAYERS+1];
new Float:SetTime[MAXPLAYERS+1];
new Float:Energe[MAXPLAYERS+1];
new Float:Speed[MAXPLAYERS+1];
new ShowHint[MAXPLAYERS+1][3];
new bool:Hooked[MAXPLAYERS+1];

new Handle:l4d_sprint_enable = INVALID_HANDLE;

new Handle:l4d_sprint_energe_max = INVALID_HANDLE;
new Handle:l4d_sprint_energe_slowdown = INVALID_HANDLE;
 

new Handle:l4d_sprint_speed_slowdown_min = INVALID_HANDLE;
new Handle:l4d_sprint_speed_slowdown_max = INVALID_HANDLE;

new Handle:l4d_sprint_speed_sprint = INVALID_HANDLE;

new Handle:l4d_sprint_consume_sprint = INVALID_HANDLE;
new Handle:l4d_sprint_consume_run = INVALID_HANDLE;
new Handle:l4d_sprint_consume_walk = INVALID_HANDLE;
new Handle:l4d_sprint_consume_duck = INVALID_HANDLE;
new Handle:l4d_sprint_consume_atrest = INVALID_HANDLE;
new Handle:l4d_sprint_consume_jump = INVALID_HANDLE;

new sprint_enable ;

new Float:sprint_energe_max ;
new Float:sprint_energe_slowdown ;
 

new Float:sprint_speed_slowdown_min;
new Float:sprint_speed_slowdown_max;

new Float:sprint_speed_sprint ;

new Float:sprint_consume_sprint;
new Float:sprint_consume_run;
new Float:sprint_consume_walk;
new Float:sprint_consume_duck;
new Float:sprint_consume_atrest;
new Float:sprint_consume_jump;

new GameMode;
new L4D2Version;

new offsSpeed;
new bool:gamestart ;
new Float:currenttime;
new Float:lasttime;

new Float:duration;
 
new g_iVelocity;


public Plugin:myinfo = 
{
	name = "Sprint",
	author = "Pan Xiaohai",
	description = "Sprint",
	version = "1.0",
	url = " "
}
public OnPluginStart()
{
	
	l4d_sprint_enable = 				CreateConVar("l4d_sprint_enable", "1", "0:disable, 1:enable ", FCVAR_PLUGIN);
	
	l4d_sprint_energe_max = 			CreateConVar("l4d_sprint_energe_max", "150.0", "max amount stamina, [100.0, -]", FCVAR_PLUGIN);
	l4d_sprint_energe_slowdown = 		CreateConVar("l4d_sprint_energe_slowdown", "50.0", "speed slow down when stamina below this, [0.0, l4d_sprint_energe_max)", FCVAR_PLUGIN);
	
	l4d_sprint_speed_slowdown_min = 	CreateConVar("l4d_sprint_speed_slowdown_min", "0.4", "min speed when slow down ,[0.3, l4d_sprint_speed_slowdown_max)", FCVAR_PLUGIN);
	l4d_sprint_speed_slowdown_max = 	CreateConVar("l4d_sprint_speed_slowdown_max", "0.8", "max speed when slow down ,[0.6, 0.9]", FCVAR_PLUGIN);

	l4d_sprint_speed_sprint = 			CreateConVar("l4d_sprint_speed_sprint", "1.4", "sprint speed ,[1.1, 2.0]", FCVAR_PLUGIN);
	
	l4d_sprint_consume_sprint =			CreateConVar("l4d_sprint_consume_sprint", "3.0", "energe consume per second for sprint  [2.0,  10.0]", FCVAR_PLUGIN);
	l4d_sprint_consume_run = 			CreateConVar("l4d_sprint_consume_run", "1.0", "energe consume per second for run [0.5,  3.0]", FCVAR_PLUGIN);
	l4d_sprint_consume_walk = 			CreateConVar("l4d_sprint_consume_walk", "0.5", "energe consume per second for walk [0.2,  2.0]", FCVAR_PLUGIN);	
	l4d_sprint_consume_duck = 			CreateConVar("l4d_sprint_consume_duck", "-0.5", "energe consume per second for duck[-1.0,  1.0]", FCVAR_PLUGIN);	
	l4d_sprint_consume_atrest = 		CreateConVar("l4d_sprint_consume_atrest", "-3.0", "energe consume per second at rest[-10.0, -1.0]", FCVAR_PLUGIN);	
	l4d_sprint_consume_jump = 			CreateConVar("l4d_sprint_consume_jump", "3.0", "energe consume per jump [3.0,  10.0]", FCVAR_PLUGIN);
	
	AutoExecConfig(true, "l4d_sprint");
 	HookEvent("player_spawn", player_spawn);
	HookEvent("player_jump", player_jump);
	
	HookEvent("round_start", round_start);
	HookEvent("round_end", round_end);
	HookEvent("finale_win", round_end);
	HookEvent("mission_lost", round_end);
	HookEvent("map_transition", round_end);
	
	HookConVarChange(l4d_sprint_enable, CvarChanged);
	
	HookConVarChange(l4d_sprint_energe_max, CvarChanged);
	HookConVarChange(l4d_sprint_energe_slowdown, CvarChanged);
 
	
	HookConVarChange(l4d_sprint_speed_slowdown_min, CvarChanged);
	HookConVarChange(l4d_sprint_speed_slowdown_max, CvarChanged);
 
	HookConVarChange(l4d_sprint_speed_sprint, CvarChanged);
	
	HookConVarChange(l4d_sprint_consume_sprint, CvarChanged);
	HookConVarChange(l4d_sprint_consume_run, CvarChanged);
	HookConVarChange(l4d_sprint_consume_walk, CvarChanged);
	HookConVarChange(l4d_sprint_consume_duck, CvarChanged);
	HookConVarChange(l4d_sprint_consume_atrest, CvarChanged);
	HookConVarChange(l4d_sprint_consume_jump, CvarChanged); 
	
	GameCheck();
	g_iVelocity = FindSendPropOffs("CBasePlayer", "m_vecVelocity[0]");
	offsSpeed=FindSendPropInfo("CBasePlayer","m_flLaggedMovementValue");
	gamestart=false;
	Set();
	ResetAllPlayerState();
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
}
public OnMapStart()
{
 
	PrecacheSound(SOUND_SPRINT, true) ;
	 
}
public CvarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	Set();
}
Set()
{
 
	sprint_enable=GetConVarInt(l4d_sprint_enable);
	
	sprint_energe_max=GetConVarFloat(l4d_sprint_energe_max);	
	sprint_energe_slowdown=GetConVarFloat(l4d_sprint_energe_slowdown);
	
	sprint_speed_slowdown_min=GetConVarFloat(l4d_sprint_speed_slowdown_min);
	sprint_speed_slowdown_max=GetConVarFloat(l4d_sprint_speed_slowdown_max);

	sprint_speed_sprint=GetConVarFloat(l4d_sprint_speed_sprint);
	
	sprint_consume_sprint=GetConVarFloat(l4d_sprint_consume_sprint);
	sprint_consume_run=GetConVarFloat(l4d_sprint_consume_run);
	sprint_consume_walk=GetConVarFloat(l4d_sprint_consume_walk);
	sprint_consume_duck=GetConVarFloat(l4d_sprint_consume_duck);
	sprint_consume_atrest=GetConVarFloat(l4d_sprint_consume_atrest);
	sprint_consume_jump=GetConVarFloat(l4d_sprint_consume_jump);	
	
}
public Action:player_jump(Handle:hEvent, const String:name[], bool:dontBroadcast)
{
	if(sprint_enable==0 || GameMode==2)return;
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	Energe[client]-=sprint_consume_jump;
	if(Energe[client]<0.0)Energe[client]=0.0;
}
public OnConfigExecuted()
{
	 
	Set();
}
public Action:round_start(Handle:Spawn_Event, const String:Spawn_Name[], bool:Spawn_Broadcast)
{
	ResetAllPlayerState();
	lasttime=GetEngineTime();
	gamestart=true;
}
public Action:round_end(Handle:event, const String:name[], bool:dontBroadcast)
{
	gamestart=false;
	for(new client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client)==2)
		{
			UnHook(client);
		}
	}
}
public Action:player_spawn(Handle:Spawn_Event, const String:Spawn_Name[], bool:Spawn_Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(Spawn_Event, "userid"));
	ResetPlayerState(client);
}
ResetPlayerState(client )
{
	KeyBuffer[client]=0;
	KeyState[client]=0; 
	KeyTime[client]=0.0;
	SetTime[client]=0.0;
	Speed[client]=1.0;
	ShowHint[client][0]=1;
	ShowHint[client][1]=3;
	ShowHint[client][2]=3;
	Hooked[client]=false;
	Energe[client]= sprint_energe_max*0.8;
	UnHook(client);
}
ResetAllPlayerState()
{
	for(new client = 1; client <= MaxClients; client++)
	{
		ResetPlayerState(client);
		if(IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client)==2 && !IsFakeClient(client))
		{
			//SDKHook(client, SDKHook_PreThinkPost, PreThinkPostHook);
			
		}
	}
}
public OnClientPutInServer(client)
{
    
    //SDKHook(client, SDKHook_PreThinkPost, PreThinkPostHook);
    
}




public OnGameFrame()
{
	if(GameMode==2 || !gamestart || sprint_enable==0)return;
	currenttime=GetEngineTime();
	duration=currenttime-lasttime;
	if(duration<0.0 || duration>1.0)duration=0.0;
  	for(new client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client)==2 && !IsFakeClient(client))
		{
			Do(client);
		}
	}
	lasttime=currenttime;
}
Do(client )
{
	new button=GetClientButtons(client);
	new bool:move=false;
	for(new i=0; i<4; i++)
	{
		if((button & RunButtons[i]))
		{
			move=true;
			break;
		}
 	}
	new bool:walk=false;
	new bool:duck=false;
 
	if(button & IN_DUCK)
	{
		duck=true;
	}
	if (button & IN_SPEED) 
	{
		walk=true;
	}
	//PrintToChat(client, "state %d", KeyState[client]);
	{
 		if(KeyState[client]==0)
		{
			if((button & IN_FORWARD) && !(KeyBuffer[client] & IN_FORWARD))
			{
				KeyState[client]=1;
				KeyTime[client]=currenttime;
				//PrintToChat(client, "state 1");
			}
		} 
		if(KeyState[client]==1)
		{
			if(currenttime-KeyTime[client]<0.5)
			{
				if(!(button & IN_FORWARD) && (KeyBuffer[client] & IN_FORWARD))
				{
					KeyState[client]=2;
					//PrintToChat(client, "state 2");
				}
			}
			else
			{
				KeyState[client]=0;
			}
			 
		} 
		if(KeyState[client]==2)
		{
			if(currenttime-KeyTime[client]<0.5)
			{
				if((button & IN_FORWARD) && !(KeyBuffer[client] & IN_FORWARD))
				{
					
					KeyState[client]=3;
					SetTime[client]=0.0;
					//PrintToChat(client, "state 3");
					/*
					decl Float:velocity[3];
					GetEntDataVector(client, g_iVelocity, velocity);
					NormalizeVector(velocity, velocity);
					ScaleVector(velocity, 200.0*GetConVarFloat(l4d_sprint_speed_sprint));
					velocity[2]=110.0*GetConVarFloat(l4d_sprint_speed_sprint);
					TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
					*/
					
					
					Hook(client);
					if(ShowHint[client][1]>0)
					{
						ShowPlayerHint(client, 1);
					}
					ShowHint[client][0]=1;
					decl Float:pos[3];
					GetClientEyePosition(client, pos);
					EmitSoundToAll(SOUND_SPRINT, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, pos, NULL_VECTOR, false, 0.0);	
				 
					
				}
			}
			else
			{
				KeyState[client]=0;
			}
		}
	}
 
	if(KeyState[client]==3 && !move)
	{
		KeyState[client]=0;
	}
	if(KeyState[client]==3)
	{
		Energe[client]-=sprint_consume_sprint*duration;
		 
	}
	else
	{	
		if(move)
		{
			if(walk) Energe[client]-=sprint_consume_walk*duration;
			else if(duck)Energe[client]-=sprint_consume_duck*duration;
			else  Energe[client]-=sprint_consume_run*duration;
		}
		else
		{
			Energe[client]-=sprint_consume_atrest*duration;
			
		}
	}
	if(Energe[client]<0.0)Energe[client]=0.0;
	if(Energe[client]>sprint_energe_max)Energe[client]=sprint_energe_max;
	//if(currenttime-SetTime[client]>1.0)
	{
		//PrintCenterText(client, "state %d %f ",KeyState[client], Energe[client] );
 
		new Float:speed=1.0;
		if(KeyState[client]==3)
		{
			speed=sprint_speed_sprint;

		}
		if(Energe[client]<sprint_energe_slowdown)
		{
			speed=sprint_speed_slowdown_min+(sprint_speed_slowdown_max-sprint_speed_slowdown_min)*Energe[client]/sprint_energe_slowdown;
			if(ShowHint[client][0]>0)
			{
				ShowPlayerHint(client, 0);
			}
		}
		Speed[client]=speed;
		if(Speed[client]==1.0)
		{
			UnHook(client);			
		}
		else
		{
			Hook(client);
		}
		//SetClientSpeed(client, speed);
		
		SetTime[client]=currenttime;
		
	}
	//PrintCenterText(client, "state %d e:%f  s:%f",KeyState[client], Energe[client],Speed[client]);
 

	KeyBuffer[client]=button;
 		 
}
public PreThinkPostHook(client)
{
    
    if(IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client)==2 && !IsFakeClient(client))
    {    
       	SetEntPropFloat(client, Prop_Send, "m_flMaxspeed", 210.0*Speed[client]);
	}
	else
	{
		Hooked[client]=false;
		SDKUnhook(client, SDKHook_PreThinkPost, PreThinkPostHook);
	}
}
Hook(client)
{
	if(!Hooked[client])
	{

		Hooked[client]=true;
		SDKHook(client, SDKHook_PreThinkPost, PreThinkPostHook);
	}
 
}
UnHook(client)
{
	if(Hooked[client])
	{
		
		Hooked[client]=false;
		SDKUnhook(client, SDKHook_PreThinkPost, PreThinkPostHook);
	}
	 
}
ShowPlayerHint(client, index)
{
	ShowHint[client][index]=ShowHint[client][index]-1;
	if(index==0)
	{
		PrintHintText(client, "Your movement will slow down when lack of stamina, please take a rest. \nPress forward twice quickly to get into sprint mode");
		
	}
	if(index==1)
	{
		PrintHintText(client, "If you press forward twice quickly, you will get into sprint mode");
		
	}
	
}
 
