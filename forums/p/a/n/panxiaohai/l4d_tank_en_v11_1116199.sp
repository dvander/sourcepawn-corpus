#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#define DEBUG 0

#define PLUGIN_VERSION "2.12"
#define CVAR_FLAGS          FCVAR_PLUGIN|FCVAR_NOTIFY
#define ZOMBIECLASS_SMOKER	1
#define ZOMBIECLASS_BOOMER	2
#define ZOMBIECLASS_HUNTER	3
new ZOMBIECLASS_TANK=5;


new Handle: SuperTank					= INVALID_HANDLE;
new Handle: SuperTankMultiplier	= INVALID_HANDLE;

new Handle:TankEnabled = INVALID_HANDLE;
new Handle:TankDuration = INVALID_HANDLE;
new Handle:TankRadius = INVALID_HANDLE;
new Handle:TankDamage = INVALID_HANDLE;
  new Handle:TankLong = INVALID_HANDLE;
new Handle:TankDelte = INVALID_HANDLE;
new Handle:HelpCount1 = INVALID_HANDLE;
new Handle:HelpCount2 = INVALID_HANDLE;
new Handle:HelpTime = INVALID_HANDLE;
new Handle:HelpEnable = INVALID_HANDLE;
new Handle:HelpP = INVALID_HANDLE;

new Handle:StuckFireP;
new Handle:AngryFireP;

new Handle:SupperP;
new Handle:SupperFireP;
new Handle:SupperHP;
new Handle:SupperShow;
 new Handle:SupperMove;



new Handle:StuckHelpCount1 = INVALID_HANDLE;
new Handle:StuckHelpCount2 = INVALID_HANDLE;
new Handle:StuckHelpTime = INVALID_HANDLE;
new Handle:StuckHelpEnable = INVALID_HANDLE;
new Handle:StuckHelpP = INVALID_HANDLE;

new Handle:timer_handle=INVALID_HANDLE;
new Handle:help_handle=INVALID_HANDLE;
new Handle:msg_handle=INVALID_HANDLE;

new stuckhelptimetick=0;
new helptimetick=0;
new timetick=0;
new start=0;
new tankid=0;
new distindex=0;
new Float:g_pos1[3];
new Float:g_pos2[3];
new Float:dist[1000];
new Float:distance=0;
new Float:totaldistance=0;


new meleeentinfo;
new bool:isintank[MAXPLAYERS+1];
new bool:MeleeDelay[MAXPLAYERS+1];
new propinfoghost;


 	new HumanNum=0;
	new Sum=0;

new CVarFirstMapTank;
new CVarFirstMapTankMinPlayer;
 
new Human[MAXPLAYERS+1];


public Plugin:myinfo = 
{
	name = "punish survivor when tank get stucked v11",
	author = "pan xiaohai",
	description = "punish survivor when tank get stucked",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
}

new L4D2Version;
public OnPluginStart()
{
	decl String:GameName[16];
 	
	GetGameFolderName(GameName, sizeof(GameName));
	if (StrEqual(GameName, "left4dead2", false))
	{
		 
		ZOMBIECLASS_TANK=8;
	}	
 

 	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);

	HookEvent("tank_spawn", Event_Tank_Spawn); 
	HookEvent("tank_killed", Event_TankKilled);
 

 	HelpCount1 = CreateConVar("l4d_tank_angry_helpcountmin", "2", "Tank getting angrt call others minimum number", CVAR_FLAGS);
	HelpCount2 = CreateConVar("l4d_tank_angry_helpcountmax", "4", "Tank getting angrt call others maximum number", CVAR_FLAGS);
	HelpTime = CreateConVar("l4d_tank_angry_helptime", "40", "Tank getting angry call others time duration", CVAR_FLAGS);
	HelpP = CreateConVar("l4d_tank_angry_helpp", "40", "Tank getting angrt call others probility", CVAR_FLAGS);
 	AngryFireP = CreateConVar("l4d_tank_angry_help_firep", "30", "Tank getting angrt fire probility", CVAR_FLAGS);

 	StuckFireP = CreateConVar("l4d_tank_stuck_firep", "50", "stucked tank fire probility", CVAR_FLAGS);
 	StuckHelpCount1 = CreateConVar("l4d_tank_stuck_helpcountmin", "1", "stucked tank call others minimum number", CVAR_FLAGS);
	StuckHelpCount2 = CreateConVar("l4d_tank_stuck_helpcountmax", "3", "stucked tank call others maximum number", CVAR_FLAGS);
	StuckHelpTime = CreateConVar("l4d_tank_stuck_helptime", "4", "stucked tank call others time duration", CVAR_FLAGS);
	StuckHelpP = CreateConVar("l4d_tank_stuck_helpp", "80", "stucked tank call others probility", CVAR_FLAGS);


	TankEnabled = CreateConVar("l4d_tank_stuck_enabled", "1", " enable/disable punish survivor when tank get stucked", CVAR_FLAGS);
	TankDamage = CreateConVar("l4d_tank_stuck_damage", "20", "demage/s when tank get stucked", CVAR_FLAGS);
 	TankDuration = CreateConVar("l4d_tank_stuck_time", "12", "how long tank get stucked ", CVAR_FLAGS);
	TankLong= CreateConVar("l4d_tank_stuck_howlong", "160", "tank move distanc less than this let tank get into stuck state", CVAR_FLAGS);
	TankDelte= CreateConVar("l4d_tank_stuck_delte", "800", "watch tank when move this distance", CVAR_FLAGS);
	TankRadius = CreateConVar("l4d_tank_stuck_radius", "700", "punish radius", CVAR_FLAGS);
	
	CreateConVar("l4d_tank_version", PLUGIN_VERSION, "1.0", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_DONTRECORD);

	// Autoexec config
	AutoExecConfig(true, "l4d_tank");
	 
	tankid=0;

	propinfoghost = FindSendPropInfo("CTerrorPlayer", "m_isGhost");
 
	HookEvent("player_incapacitated", PlayerIncap); 
	

 	CVarFirstMapTank = CreateConVar("l4d_tank_firstmap", "30", "first map tank spawn problity ", FCVAR_PLUGIN);
 	CVarFirstMapTankMinPlayer = CreateConVar("l4d_tank_firstmap_minplayer", "4", "minimum survivors request", FCVAR_PLUGIN);

}
 
 

 public Action:Kin(Handle:timer, Handle:target)
{
	ClientCommand(target, "vocalize PlayerLaugh");
}
public Action:PlayerIncap(Handle:event, String:event_name[], bool:dontBroadcast)
{
 	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
 
 	if(attacker>0 && GetClientTeam(attacker) == 3)
	{

		new class = GetEntProp(attacker, Prop_Send, "m_zombieClass");
		if (class == ZOMBIECLASS_TANK)
		{
			timetick=0;
			helptimetick=0;
			stuckhelptimetick=0;
		}
	}
}
public Action:FirstMapSpawnTank(Handle:timer)
{
		new p=GetConVarInt(CVarFirstMapTank);
		new r=GetRandomInt(0, 100);
 		//PrintToChatAll("%i", r);
		if(r<p)
		{
			new n=	scanplayer();
			if(n>=GetConVarInt(CVarFirstMapTankMinPlayer))
			{
				StripAndExecuteClientCommand(RandomHunman(), "z_spawn", "tank", "auto", "");
			}

		}
}
public Action:rescue_door_open(Handle:event, const String:name[], bool:dontBroadcast)
{
    if(isfirstmap()   )
	{
		//PrintToChatAll("firstmap");
		new r=GetRandomInt(30, 100);
		CreateTimer(r*1.0, FirstMapSpawnTank);
	}
 	return Plugin_Continue;
}
public Action:survivor_rescued(Handle:event, const String:name[], bool:dontBroadcast)
{

    PrintToChatAll("survivor_rescued");
 	return Plugin_Continue;
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	// LogAction(0, -1, "DEBUG:Event_RoundStart 段落");
	ScanTank();
	if(timer_handle != INVALID_HANDLE )
				{
					KillTimer(timer_handle);

					timer_handle=INVALID_HANDLE;
					 
				}
	//if(help_handle != INVALID_HANDLE )
	//			{
	//				KillTimer(help_handle);

	//				help_handle=INVALID_HANDLE;
	//				 
	//			}
 
	if(msg_handle != INVALID_HANDLE )
	{
			KillTimer(msg_handle);
			msg_handle=INVALID_HANDLE;
	}
	if(msg_handle == INVALID_HANDLE)
	{
			msg_handle=CreateTimer(400.0, Msg, 0, TIMER_REPEAT);
	}

	return Plugin_Continue;
}
public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	 
	if(msg_handle != INVALID_HANDLE )
				{
					KillTimer(msg_handle);
					msg_handle=INVALID_HANDLE;
				}
	return Plugin_Continue;
}
public Action:Msg(Handle:timer, any:data)
{
	if (GetConVarInt(TankEnabled) == 1)
	{
		PrintToChatAll("\x05[msg]\x04stuck tank punish is running");
	}
 	return Plugin_Continue;
}
public Action:Event_TankKilled(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(TankEnabled) == 1)
	{
		ScanTank();
		if(tankid==0)
		{
			timetick=0;
			distindex=0;
			start=0;

			if(timer_handle != INVALID_HANDLE )
			{
				KillTimer(timer_handle);
				timer_handle=INVALID_HANDLE;
			}
		}
	}
	return Plugin_Continue;
}
public Action:PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	 
 	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
 	if (client == 0) return Plugin_Continue;
	if (!IsClientInGame(client)) return Plugin_Continue;
	 
 

	if(GetClientTeam(client) == 2)
	{
		helptimetick=0;stuckhelptimetick=0;
	}
	
	
	if(GetClientTeam(client) != 3)
	{
		return Plugin_Continue;
	}

	new class = GetEntProp(client, Prop_Send, "m_zombieClass");

	if (class == ZOMBIECLASS_TANK)
	{
		if (GetConVarInt(TankEnabled) == 1)
		{
			ScanTank();
			if(tankid==0)
			{
				timetick=0;
				distindex=0;
				start=0;

				if(timer_handle != INVALID_HANDLE )
				{
					KillTimer(timer_handle);
					timer_handle=INVALID_HANDLE;
 				}
 			}
		}
 	}	
 	

	return Plugin_Continue;
}
ScanTank()
{
	decl String:player_name[65];
	tankid=0;
 	for(new i=1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 3)
		{ 
			GetClientName(i, player_name, sizeof(player_name));
			if (StrContains(player_name,"Tank") >= 0)
			{
				tankid=i;
				for(new j=0; j<100; j++)
				{
					dist[j]=0.0;
				}
				timetick=0;
				distindex=0;
				start=0;
				g_pos2[0]=-1;
				g_pos2[1]=-1;
				g_pos2[2]=-1;	
 				break;
			}
		}
	
	}
	if(tankid==0)
	{
 	}
}
 

public Action:Event_Tank_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	helptimetick=0;
	stuckhelptimetick=0;
   
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
 	if (client == 0) return Plugin_Continue;
 	if (GetConVarInt(TankEnabled) == 1)
		{
			ScanTank();
			if(tankid>0)
			{
				if(timer_handle == INVALID_HANDLE)
				{
 					timer_handle=CreateTimer(1.0, WatchTank, 0, TIMER_REPEAT);
				}
 
			}
		}
 
	return Plugin_Continue;
	 
}
 
public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	
  
	new attacker = GetEventInt(event, "attacker");
	new client = GetEventInt(event, "userid");
 
	if (GetClientTeam(attacker) == 3)
	{
		new damagetype = GetEventInt(event, "dmg_health");

		new class = GetEntProp(client, Prop_Send, "m_zombieClass");
		if (class == ZOMBIECLASS_TANK)
		{
			if(damagetype>0)
			{
				 timetick=0;
				 PrintToChatAll("hurt");
			}
		}
 	}
	
	return Plugin_Continue;
}
public Action:StartStuckHelp(Handle:timer, any:client)
{

	if(tankid>0)
	{
		new ok=0;
		new count=GetRandomInt(GetConVarInt(StuckHelpCount1),GetConVarInt(StuckHelpCount2) );
		for(new i=0; i<count; i++)
		{
			new r = GetRandomInt(0, 100);
			if(r<50)
			{
				//ExecuteCommand(client, "z_spawn", "smoker");
				StripAndExecuteClientCommand(tankid, "z_spawn hunter", "", "", "");
			}
			else if(r<85)
			{
				//ExecuteCommand(client, "z_spawn", "bomber");
				StripAndExecuteClientCommand(tankid, "z_spawn smoker", "", "", "");
			}
			else  
			{
				StripAndExecuteClientCommand(tankid, "z_spawn bomber", "", "", "");
				//ExecuteCommand(client, "z_spawn", "hunter");
			}
			ok=1;
		}
		new r1 = GetRandomInt(0, 100);
		if(r1<GetConVarInt(StuckFireP))
		{
			StripAndExecuteClientCommand(tankid, "fire", "", "", "");
			ok=1;
		}
		PrintToChatAll("\x03Tank stucked and get angry\x03");
	 
	}
	return Plugin_Continue;
} 
public Action:StartAngryHelp(Handle:timer)
{

	if(tankid>0)
	{
	 	new r1 = GetRandomInt(0, 100);
		if(r1<GetConVarInt(AngryFireP))
		{
			 IgniteEntity(tankid, 360.0, false);
			 PrintToChatAll("\x03 Tank fired\x03");	
		}
		new count=GetRandomInt(GetConVarInt(HelpCount1),GetConVarInt(HelpCount2) );
		for(new i=0; i<count; i++)
		{
			new r = GetRandomInt(0, 100);
			if(r<50)
			{
				//ExecuteCommand(client, "z_spawn", "smoker");
				StripAndExecuteClientCommand(tankid, "z_spawn hunter", "", "", "");
			}
			else if(r<85)
			{
				//ExecuteCommand(client, "z_spawn", "bomber");
				StripAndExecuteClientCommand(tankid, "z_spawn smoker", "", "", "");
			}
			else  
			{
				StripAndExecuteClientCommand(tankid, "z_spawn bomber", "", "", "");
				//ExecuteCommand(client, "z_spawn", "hunter");
			}
		}
		if(count>0)	PrintToChatAll("\x03 Tank call help\x03");	
	}
	return Plugin_Continue;
}
ExecuteCommand(Client, String:strCommand[], String:strParam1[])
{
	new flags = GetCommandFlags(strCommand);
    
	SetCommandFlags(strCommand, flags & ~FCVAR_CHEAT);
	FakeClientCommand(Client, "%s %s", strCommand, strParam1);
	SetCommandFlags(strCommand, flags);
}
public Action:WatchTank(Handle:timer, any:data)
{
	if (tankid >0 && IsClientConnected(tankid) && IsClientInGame(tankid) && IsPlayerAlive(tankid) && GetClientTeam(tankid) == 3)
	{
		 
		if(g_pos2[0]==-1.0 && g_pos2[1]==-1.0 && g_pos2[2]==-1.0)
		{
			GetClientEyePosition(tankid ,g_pos2);
		}

		GetClientEyePosition(tankid ,g_pos1);
		distance= GetVectorDistance(g_pos1, g_pos2);
		g_pos2[0]=g_pos1[0];
		g_pos2[1]=g_pos1[1];
		g_pos2[2]=g_pos1[2];	

		dist[distindex]=distance;
		timetick++;
		distindex++;

		new duration=GetConVarInt(TankDuration);

		if(distindex>=duration)
		{
			distindex=0;
		}
		totaldistance=0;
		for(new k=0; k<duration; k++)
		{
			if(dist[k]<0.0)dist[k]=0.0;
			totaldistance=totaldistance+dist[k];

		}


		if(start==0)
		{
			if(timetick > duration)
			{
 				if(totaldistance>GetConVarFloat(TankDelte))
				{
					start=1;
					timetick=0;
					distindex=0;
				 
				}
			}
		}
		
		if(start==1)
		{
			helptimetick=helptimetick+1;
			 
			
			if(helptimetick>=GetConVarInt(HelpTime))
			{
				helptimetick=0;
				new r1=0;
				r1=GetRandomInt(0, 100);
				if(r1<GetConVarInt(HelpP))
				{
					CreateTimer(0.5, StartAngryHelp);
				}
			}
		}


 		if(timetick > duration && start>0)
		{
			totaldistance=0;
			for(new k=0; k<duration; k++)
			{
				totaldistance=totaldistance+dist[k];
			}
 		
			if(totaldistance<GetConVarFloat(TankLong))
			{
			   //tank get stucked;
	 
 
				decl Float:tankradus;
				tankradus=GetConVarFloat(TankRadius);
				new selectplayer=0;
				decl Float:mindistance;
				mindistance=-1000.0;

				new bool:causedbyhuman=false;

				new damage = GetConVarInt(TankDamage);

				new String:arg1[10];
				Format(arg1, sizeof(arg1), "%i", damage*3);

				new String:arg2[10];
				Format(arg2, sizeof(arg2), "%i", damage);

 				for (new target = 1; target <= MaxClients; target++)
				{
					if (target > 0 && IsClientInGame(target) && GetClientTeam(target) == 2 && IsPlayerAlive(target))
					{
						
						decl Float:targetVector[3];
						GetClientEyePosition(target, targetVector);
								
						distance = GetVectorDistance(targetVector, g_pos1);
						if(mindistance<0)mindistance=distance;
						if(distance<=mindistance)
						{
							mindistance=distance;
							selectplayer=target;
						}
											
						if (distance < tankradus)
						{						
							causedbyhuman=true;
							PrintHintText(target, "you get punished");
 							
		 
 								new Handle:hBf = StartMessageOne("Shake", target);
								BfWriteByte(hBf, 0);
								BfWriteFloat(hBf,6.0);
								BfWriteFloat(hBf,1.0);
								BfWriteFloat(hBf,1.0);
								EndMessage();
								CreateTimer(1.0, StopShake, target);
						 
								
 							
 
							if (IsPlayerIncapped(target))
							{
 								DamageEffect(target, arg1);
								 
								//PrintHintText(target, arg1);
							}
							else
							{
 								DamageEffect(target, arg2);
								 
 								//PrintHintText(target, arg2);
							}
					
						}
						else
						{

							PrintHintText(target, "don't close to stucked tank");
						}
					}
				}

			 
				stuckhelptimetick=stuckhelptimetick+1;
				//PrintToChatAll("stucktick %i", stuckhelptimetick);	
				
				if(stuckhelptimetick>=GetConVarInt(StuckHelpTime) && causedbyhuman)
				{
					stuckhelptimetick=0;
					new r1=0;
					r1=GetRandomInt(0, 100);
					//PrintToChatAll("sle %i", selectplayer);	

					if(r1<GetConVarInt(StuckHelpP))
					{
						CreateTimer(0.5, StartStuckHelp, selectplayer);
					}
				}
 
			}
			else
			{
				stuckhelptimetick=0;
			}
		}
	}
	else
	{
		ScanTank();
	}
	return Plugin_Continue;
}
 

stock DamageEffect(target, String:demage[])
{
	new pointHurt = CreateEntityByName("point_hurt");			// Create point_hurt
	DispatchKeyValue(target, "targetname", "hurtme");			// mark target
	DispatchKeyValue(pointHurt, "Damage", demage);					// No Damage, just HUD display. Does stop Reviving though
	DispatchKeyValue(pointHurt, "DamageTarget", "hurtme");		// Target Assignment
	DispatchKeyValue(pointHurt, "DamageType", "65536");			// Type of damage
	DispatchSpawn(pointHurt);									// Spawn descriped point_hurt
	AcceptEntityInput(pointHurt, "Hurt"); 						// Trigger point_hurt execute
	AcceptEntityInput(pointHurt, "Kill"); 						// Remove point_hurt
	DispatchKeyValue(target, "targetname",	"cake");			// Clear target's mark
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

 

bool:IsPlayerIncapped(client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1)) return true;
	return false;
}

 scanplayer()
 {
	 HumanNum=0;
	 Sum=0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{	
			if (GetClientTeam(i) == 3)
			{
				new class = GetEntProp(i, Prop_Send, "m_zombieClass");
				if (class == ZOMBIECLASS_HUNTER)
				{
 					Sum++;
				}
				else if (class == ZOMBIECLASS_SMOKER)
				{
 					Sum++;
				}
				else if (class == ZOMBIECLASS_BOOMER)
				{
 					Sum++;
				}
				else if (class == ZOMBIECLASS_TANK)
				{
 					 
 				}
			}
			if (GetClientTeam(i) == 2 && !IsFakeClient(i))
			{
				Human[HumanNum++]=i;
			}
		}
	}  
	return HumanNum;
 }
RandomHunman()
{
	new r;
	r= GetRandomInt(0, HumanNum-1);
	return Human[r];
	 
}
isfirstmap()
{
	new String:MapName[80];
	GetCurrentMap(MapName, sizeof(MapName));

 	
	if (StrContains(MapName, "01", false) != -1)
	{
		return true;
	}
	else
	{
		return false;
	}
}
StripAndExecuteClientCommand(client, String:command[], String:param1[], String:param2[], String:param3[])
{
 	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s %s %s", command, param1, param2, param3);
	SetCommandFlags(command, flags);
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