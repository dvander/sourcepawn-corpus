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
new Handle:l4d_revive_enabled = INVALID_HANDLE;
new Handle:l4d_revive_duration = INVALID_HANDLE;
new Handle:l4d_revive_maxtime = INVALID_HANDLE;


new Handle:hRoundRespawn = INVALID_HANDLE;
new Handle:hGameConf = INVALID_HANDLE;

new revive_duration;
new revive_maxtime;
new enable;

public Plugin:myinfo = 
{
	name = "Revive",
	author = "Pan Xiaohai & AtomicStryker & Ivailosp - Code cleanup, small changes by OtterNas3",
	description = "Revive with first aid kit",
	version = PLUGIN_VERSION,	
}
public OnPluginStart()
{
	hGameConf = LoadGameConfigFile("l4drespawn");
	new bool:error=false;
	if (hGameConf != INVALID_HANDLE)
	{
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "RoundRespawn");
		hRoundRespawn = EndPrepSDKCall();
		if (hRoundRespawn == INVALID_HANDLE) 
		{
			error=true;
			SetFailState("L4D_SM_Respawn: RoundRespawn Signature broken");
		}
	}
	else
	{
		SetFailState("could not find gamedata file at addons/sourcemod/gamedata/l4drespawn.txt , you FAILED AT INSTALLING");
		error=true;
	}

	CreateConVar("l4d_revive_version", PLUGIN_VERSION, " ", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	l4d_revive_enabled = CreateConVar("l4d_revive_enabled", "1", " 1 : enable  , 0: disable", FCVAR_PLUGIN);
	l4d_revive_duration = CreateConVar("l4d_revive_duration", "10", "How long does revive take?", FCVAR_PLUGIN);
	l4d_revive_maxtime = CreateConVar("l4d_revive_maxtime", "300", "Dead bodys can be revived up to x seconds", FCVAR_PLUGIN);

	AutoExecConfig(true, "l4d_revive_v10");


	enable=GetConVarInt(l4d_revive_enabled );
	revive_duration=GetConVarInt(l4d_revive_duration );
	revive_maxtime=GetConVarInt(l4d_revive_maxtime) ;

	HookConVarChange(l4d_revive_enabled, ConVarChange);
	HookConVarChange(l4d_revive_duration, ConVarChange);
	HookConVarChange(l4d_revive_maxtime, ConVarChange);

	if(!error)
	{
		HookEvent("round_start", RoundStart);
		HookEvent("player_death", Event_PlayerDeath);
		HookEvent("player_spawn", evtPlayerSpawn);
		Reset();
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
	enable=GetConVarInt(l4d_revive_enabled );
	revive_duration=GetConVarInt(l4d_revive_duration );
	revive_maxtime=GetConVarInt(l4d_revive_maxtime) ;
}

public Action:Event_PlayerDeath(Handle:hEvent, const String:strName[], bool:DontBroadcast)
{
	if(enable==0)return;
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
		for(new i=1; i<=MaxClients; i++)
		{
			if (i != 0 && IsClientInGame(i) && IsPlayerAlive(i) && !IsFakeClient(i) && GetPlayerWeaponSlot(i, 3) !=-1)
			{
				if (revive_maxtime >= 1)
				{
					PrintHintText(i, "!%N DIED! Use Medkit to revive within %d secs!\nGet close to his Dead Body (Blinking light)\nSelect Medkit: press Crouch+Use for %d seconds", victim, revive_maxtime, revive_duration);
				}
			}
		}
	}
}

public Action:evtPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client<=0)return;
	if(GetClientTeam(client)==2)
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
	if(client<=0)return;
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
new Float:timE;
new Float:pOs[3];
new String:weapon[32];
new buttons;

public Action:Watch(Handle:timer, any:client)
{
	if(enable==0)
	{
		timer_handle=INVALID_HANDLE;
		return Plugin_Stop;
	}
	new index=0;
	timE=GetGameTime();
	for (new i = 1; i <= MaxClients; i++)
	{
		if(CanRevive[i])
		{
			if(IsClientInGame(i) && GetClientTeam(i)==2 && !IsPlayerAlive(i))
			{
				if(timE-DeathTime[i]<revive_maxtime)
				{
					DeadMan[index++]=i;
				}
				else
				{
					CanRevive[i]=false;
					if (GhostLight[i]!=0 && IsValidEntity(GhostLight[i]))
					{
						RemoveEdict(GhostLight[i]);
					}
					GhostLight[i]=0;
				}
			}
			else
			{
				CanRevive[i]=false;
				if (GhostLight[i]!=0 && IsValidEntity(GhostLight[i]))
				{
					RemoveEdict(GhostLight[i]);
				}
				GhostLight[i]=0;
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
					if (StrEqual(weapon, "weapon_first_aid_kit"))
					{
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
							ShowBar(j, find, timE-ReviveTime[j], revive_duration);
							if(timE-ReviveTime[j]>=revive_duration)
							{
								if(Revive(j, find))
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


Revive(client, dead)
{
	GetClientWeapon(client, weapon, 32);
	if (StrEqual(weapon, "weapon_first_aid_kit"))
	{
		SDKCall(hRoundRespawn, dead);
		PerformTeleport(client, dead);

		if(IsPlayerAlive(dead))
		{
			RemovePlayerItem(client, GetPlayerWeaponSlot(client, 3));
			PrintToChatAll("\x03%N \x04used his Medkit to revive\x03 %N\x04!", client, dead);
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
ShowBar(client, dead, Float:pos, max) 
{
	new i, j;
	new String:ChargeBar[100];
	Format(ChargeBar, 100, "");
	new String:Gauge1[2] = "[";
	new String:Gauge2[2] = "]";
	new Float:GaugeNum = pos/max*100;
	if(GaugeNum > 100.0)
		GaugeNum = 100.0;
	if(GaugeNum<0.0)
		GaugeNum = 0.0;
	
	for(i=0; i<GaugeNum; i++)
		ChargeBar[i] = Gauge1[0];
	for(j=i; j<99; j++)
		ChargeBar[j] = Gauge2[0];
	PrintCenterText(client, "Revive %N  %3.0f %\n<< %s >>", dead, GaugeNum, ChargeBar);
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

