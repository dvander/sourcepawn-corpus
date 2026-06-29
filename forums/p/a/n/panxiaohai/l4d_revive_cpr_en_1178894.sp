#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.0"
#define TICKS 3


new bool:CanRevive[MAXPLAYERS+1];
new GhostLight[MAXPLAYERS+1];
new Float:DeathTime[MAXPLAYERS+1];
new Float:DeathPos[MAXPLAYERS+1][3];


new DeadMan[MAXPLAYERS+1];

new RevivePlayer[MAXPLAYERS+1] ;
new Float:ReviveTime[MAXPLAYERS+1] ;


new Handle:timer_handle=INVALID_HANDLE;
 
new Handle:l4d_revive_duration = INVALID_HANDLE;
new Handle:l4d_revive_maxtime = INVALID_HANDLE;
new Handle:l4d_CPR_maxtime = INVALID_HANDLE;
new Handle:l4d_CPR_duration = INVALID_HANDLE;
new Handle:l4d_revive_health = INVALID_HANDLE;

new Handle:hRoundRespawn = INVALID_HANDLE;
new Handle:hGameConf = INVALID_HANDLE;

new revive_duration;
new revive_maxtime;
new ar_duration;
new ar_maxtime;
new maxtime;
 
 new GameMode;

public Plugin:myinfo = 
{
	name = "Emergency Treatment With First Aid Kit Revive And CPR",
	author = "Pan Xiaohai & AtomicStryker & Ivailosp & OtterNas3",
	description = "Revive with first aid kit and CPR",
	version = PLUGIN_VERSION,	
}
public OnPluginStart()
{
	new bool:error=false;
	hGameConf = LoadGameConfigFile("l4drevive");
	if (hGameConf != INVALID_HANDLE)
	{
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "RoundRespawn");
		hRoundRespawn = EndPrepSDKCall();
		if (hRoundRespawn == INVALID_HANDLE) 
		{
			error=true;
			SetFailState("L4D_SM_Respawn: RoundRespawn Signature broken");
		}
  	}
	else
	{
		SetFailState("could not find gamedata file at addons/sourcemod/gamedata/l4drevive.txt , you FAILED AT INSTALLING");
		error=true;
	}
	
	

	CreateConVar("l4d_revive_version", PLUGIN_VERSION, " ", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
 
	l4d_revive_duration = CreateConVar("l4d_revive_duration", "10", "How long does revive take?", FCVAR_PLUGIN);
	l4d_revive_health = CreateConVar("l4d_revive_health", "50", "Revive health", FCVAR_PLUGIN);	
	l4d_revive_maxtime = CreateConVar("l4d_revive_maxtime", "300", "Dead bodys can be revived up to x seconds, 0:disable revive", FCVAR_PLUGIN);
	l4d_CPR_maxtime = CreateConVar("l4d_CPR_maxtime", "15", "Dead bodys can be CPR within x seconds, 0:disable artificial respiration", FCVAR_PLUGIN);
	l4d_CPR_duration = CreateConVar("l4d_CPR_duration", "6", "How long does CPR take", FCVAR_PLUGIN);
	
	AutoExecConfig(true, "l4d_revive&cpr_v10");
 
	Setting();
 
	 
	HookConVarChange(l4d_revive_duration, ConVarChange);
	HookConVarChange(l4d_revive_maxtime, ConVarChange);
	HookConVarChange(l4d_CPR_maxtime, ConVarChange);
	HookConVarChange(l4d_CPR_duration, ConVarChange);
	if(!error)
	{
		HookEvent("round_start", RoundStart);
		HookEvent("round_end", RoundStart);
		HookEvent("player_death", Event_PlayerDeath);
		HookEvent("player_spawn", evtPlayerSpawn);
		HookEvent("player_bot_replace", player_bot_replace );	
		HookEvent("bot_player_replace", bot_player_replace );	
		Reset();
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
 
}
/*
public OnMapStart()
{
	//PrecacheSound(SOUND_REVIVE, true) ;
}
*/
public ConVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	Setting();
}

Setting()
{
 
	revive_duration=GetConVarInt(l4d_revive_duration );
	revive_maxtime=GetConVarInt(l4d_revive_maxtime) ;
	ar_duration=GetConVarInt(l4d_CPR_duration );
	ar_maxtime=GetConVarInt(l4d_CPR_maxtime) ;
	maxtime=ar_maxtime;
	if(revive_maxtime>maxtime)	maxtime=revive_maxtime;
}
public player_bot_replace(Handle:Spawn_Event, const String:Spawn_Name[], bool:Spawn_Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(Spawn_Event, "player"));
	new bot = GetClientOfUserId(GetEventInt(Spawn_Event, "bot"));
	if(client==0 && !IsPlayerAlive(bot))
	{
		for (new j = 1; j <= MaxClients; j++)
		{
			if (!IsClientInGame(j) && CanRevive[j])
			{
				client=j;
				break;
			}
		}
	}
	replace(client, bot);
	//PrintToChatAll("player_bot_replace %N  place %N", bot, client);
	
}
public bot_player_replace(Handle:Spawn_Event, const String:Spawn_Name[], bool:Spawn_Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(Spawn_Event, "player"));
	new bot = GetClientOfUserId(GetEventInt(Spawn_Event, "bot"));
	replace(bot, client);
	//PrintToChatAll("bot_player_replace %N  place %N", client, bot);
}
replace(client1, client2)
{
	if(CanRevive[client1])
	{
		CanRevive[client2]=CanRevive[client1];
		GhostLight[client2]=GhostLight[client1];
		DeathTime[client2]=DeathTime[client1];
		DeathPos[client2][0]=DeathPos[client1][0];
		DeathPos[client2][1]=DeathPos[client1][1];
		DeathPos[client2][2]=DeathPos[client1][2];
		ReviveTime[client2]=ReviveTime[client1];
		
		CanRevive[client1]=false;
		GhostLight[client1]=0;
		DeathTime[client1]=0.0;
		if(timer_handle==INVALID_HANDLE)
		{
			timer_handle=CreateTimer(1.0/TICKS, Watch, 0, TIMER_REPEAT);
		}
	}
}
public Action:Event_PlayerDeath(Handle:hEvent, const String:strName[], bool:DontBroadcast)
{
	if(GameMode==2)return;
	new victim = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(victim<=0)return;
	if(GetClientTeam(victim)==2)
	{
		GetClientAbsOrigin(victim, DeathPos[victim]);
		DeathPos[victim][2]+=10.0;
		CanRevive[victim]=true;
		DeathTime[victim]=GetGameTime();
		GhostLight[victim]=AddParticle("weapon_pipebomb_blinking_light", DeathPos[victim]);
		if(timer_handle==INVALID_HANDLE)
		{
			timer_handle=CreateTimer(1.0/TICKS, Watch, 0, TIMER_REPEAT);
		}
		RevivePlayer[victim]=0;
		ReviveTime[victim]=0.0;
		CreateTimer(3.0, hint, victim);
	}
}
public Action:hint(Handle:timer, any:victim)
{
	if(IsClientInGame(victim) && !IsPlayerAlive(victim))
	{
		for(new i=1; i<=MaxClients; i++)
		{
			if (i != 0 && IsClientInGame(i) && IsPlayerAlive(i) && !IsFakeClient(i)  )
			{
				if (revive_maxtime >= 1 && GetPlayerWeaponSlot(i, 3) !=-1)
				{
					PrintHintText(i, "!%N FAINT! Use Medkit to revive within %d secs!\nGet close to his Body (Blinking light)\nSelect Medkit: press Crouch+Use for %d seconds", victim, revive_maxtime, revive_duration);
				}
				if (ar_maxtime >= 1 && GetPlayerWeaponSlot(i, 3) ==-1)
				{
					PrintHintText(i, "!%N FAINT! Perform CPR for him within %d secs!\nGet close to his Body (Blinking light)\nPress Crouch+Use for %d seconds", victim, ar_maxtime, ar_duration);
				}	
			}
		}
	}
}
public Action:evtPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	//PrintToChatAll("evtPlayerSpawn %N ", client);
	if(client<=0)return;
	if(GetClientTeam(client)==2)//&& !IsPlayerAlive(client))
	{
		CanRevive[client]=false;
		DeathTime[client]=0.0;
		RevivePlayer[client]=0;
		ReviveTime[client]=0.0;
		if (GhostLight[client]!=0 && IsValidEntity(GhostLight[client]))
		{
			RemoveEdict(GhostLight[client]);
		}
		GhostLight[client]=0;
	}
}
public OnClientDisconnect(client)
{
	//PrintToChatAll("OnClientDisconnect %N", client);
	if(client<=0)return;
	{
		if(IsFakeClient(client))
		{
			CanRevive[client]=false;
			DeathTime[client]=0.0;
			RevivePlayer[client]=0;
			ReviveTime[client]=0.0;
			if (GhostLight[client]!=0 && IsValidEntity(GhostLight[client]))
			{
				RemoveEdict(GhostLight[client]);
			}
			GhostLight[client]=0;
		}
	}
}
new Float:timE;
new Float:pOs[3];
new String:weapon[32];
new buttons;

public Action:Watch(Handle:timer, any:client)
{
 
	new index=0;
	timE=GetGameTime();
	for (new i = 1; i <= MaxClients; i++)
	{
		if(CanRevive[i])
		{
			if(timE-DeathTime[i]>maxtime)
			{
				CanRevive[i]=false;
				DeathTime[i]=0.0;
				RevivePlayer[i]=0;
				ReviveTime[i]=0.0;
				if (GhostLight[i]!=0 && IsValidEntity(GhostLight[i]))
				{
					RemoveEdict(GhostLight[i]);
				}
				GhostLight[i]=0;				
			}
			else if(IsClientInGame(i) && GetClientTeam(i)==2 && !IsPlayerAlive(i))
			{
				DeadMan[index++]=i;
			}
		}
	}
	if(index>0)
	{
		for (new j = 1; j <= MaxClients; j++)
		{
			if (IsClientInGame(j) && IsPlayerAlive(j) && GetClientTeam(j)==2 && !IsFakeClient(j))
			{
				buttons = GetClientButtons(j);
				if((buttons & IN_DUCK) && (buttons & IN_USE))
				{
					GetClientWeapon(j, weapon, 32);
					new bool:firstaidkit=false;
					if (StrEqual(weapon, "weapon_first_aid_kit"))
					{
						firstaidkit=true;
					}
					new Float:dis=0.0;
					new Float:min=10000.0;
					new find=0;
					GetClientAbsOrigin(j, pOs);
					for(new i=0; i<index; i++)
					{
						dis=GetVectorDistance(pOs, DeathPos[DeadMan[i]]);
						if(dis<=min)
						{
							min=dis;
							find=DeadMan[i];
						}
					}
					if(find!=0 && min<100.0)
					{
						if(RevivePlayer[j]!=find)
						{
							ReviveTime[j]=timE;
							//EmitSoundToAll(SOUND_REVIVE, j);
						}
						RevivePlayer[j]=find;
						if(firstaidkit)
						{
							if(timE-DeathTime[find]<revive_maxtime)
							{
								ShowBar(j, find, timE-ReviveTime[j], revive_duration, true);
								if(timE-ReviveTime[j]>=revive_duration)
								{
									if(Revive(j, find, true))
									{
										if (GhostLight[j]!=0 && IsValidEntity(GhostLight[j]))
										{
											RemoveEdict(GhostLight[j]);
										}
										GhostLight[j]=0;
									}
									else
									{
										RevivePlayer[j]=0;
										ReviveTime[j]=0.0;
									}
									//StopSound(j, SNDCHAN_AUTO, SOUND_REVIVE);
								}	
							}
							else
							{
								PrintCenterText(j, "%N already dead", find);
							}
						}
						else
						{
							if(timE-DeathTime[find]<ar_maxtime)
							{
								ShowBar(j, find, timE-ReviveTime[j], ar_duration, false);
								if(timE-ReviveTime[j]>=ar_duration)
								{
									if(Revive(j, find, false))
									{
										if (GhostLight[j]!=0 && IsValidEntity(GhostLight[j]))
										{
											RemoveEdict(GhostLight[j]);
										}
										GhostLight[j]=0;
									}
									else
									{
										RevivePlayer[j]=0;
										ReviveTime[j]=0.0;
									}
									//StopSound(j, SNDCHAN_AUTO, SOUND_REVIVE);
								}	
							}
							else
							{
								PrintCenterText(j, "It is too late, CPR is useless for %N ", find);
							}							
						}

					}
					 
				}
				else
				{
					RevivePlayer[j]=0;
					ReviveTime[j]=0.0;
				}
			}
		}
	}
	else
	{
		timer_handle=INVALID_HANDLE;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}


Revive(client, dead, bool:firstaidkit)
{
	if(firstaidkit)
	{
		GetClientWeapon(client, weapon, 32);
		if (StrEqual(weapon, "weapon_first_aid_kit"))
		{
			SDKCall(hRoundRespawn, dead);
			PerformTeleport(client, dead);

			if(IsPlayerAlive(dead))
			{
				SetEntityHealth(dead,  GetConVarInt(l4d_revive_health));
				RemovePlayerItem(client, GetPlayerWeaponSlot(client, 3));
				PrintToChatAll("\x03%N \x04used his Medkit to revive\x03 %N\x04!", client, dead);
				return true;
			}
		}
	}
	else
	{
		SDKCall(hRoundRespawn, dead);
		PerformTeleport(client, dead);

		if(IsPlayerAlive(dead))
		{
			new propincapcounter = FindSendPropInfo("CTerrorPlayer", "m_currentReviveCount");
			SetEntData(dead, propincapcounter, 2, 1);
				
			new Handle:revivehealth = FindConVar("pain_pills_health_value");  
		 	new temphpoffset = FindSendPropOffs("CTerrorPlayer","m_healthBuffer");
			SetEntDataFloat(dead, temphpoffset, GetConVarFloat(l4d_revive_health), true);
			SetEntityHealth(dead, 1);
			PrintToChatAll("\x03%N \x04used CPR to revive\x03 %N\x04!", client, dead);
			return true;
		}		
	}
	return false;
}

PerformTeleport(client, dead)
{
	new Float:pOs2[3];
	GetClientAbsOrigin(client, pOs2);
	TeleportEntity(dead, pOs2, NULL_VECTOR, NULL_VECTOR);
}

public RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	Reset();
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
	for (new x = 0; x < MAXPLAYERS+1; x++)
	{
		CanRevive[x]=false;
		GhostLight[x]=0;
		DeathTime[x]=0.0;
		RevivePlayer[x]=0;
		ReviveTime[x]=0.0;
	}
}
new String:Gauge1[2] = "-";
new String:Gauge2[2] = "-";
new String:Gauge3[2] = "#";
ShowBar(client, dead, Float:pos, max, bool:firstaidkit) 
{
	new i, j;
	new String:ChargeBar[101];
	Format(ChargeBar, sizeof(ChargeBar), "");

	new Float:GaugeNum = pos/max*100;
	if(GaugeNum > 100.0)
		GaugeNum = 100.0;
	if(GaugeNum<0.0)
		GaugeNum = 0.0;
	
 	for(i=0; i<100; i++)
		ChargeBar[i] = Gauge1[0];
	new p=RoundFloat( GaugeNum);
	if(p>=0 && p<100)ChargeBar[p] = Gauge3[0];
	
	if(firstaidkit)	PrintCenterText(client, "Using First Aid Kit to Revive %N  %3.0f %\n<< %s >>", dead, GaugeNum, ChargeBar);
	else            PrintCenterText(client, "Performing CPR to Revive %N  %3.0f %\n<< %s >>", dead, GaugeNum, ChargeBar);
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
		//CreateTimer(5.0, KillParticle, i_Particle); 
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

