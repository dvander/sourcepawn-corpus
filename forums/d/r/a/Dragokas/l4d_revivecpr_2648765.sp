#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.4"
#define TICKS 3


bool CanRevive[MAXPLAYERS+1];
int GhostLight[MAXPLAYERS+1];
float DeathTime[MAXPLAYERS+1];
float DeathPos[MAXPLAYERS+1][3];


int DeadMan[MAXPLAYERS+1];

int RevivePlayer[MAXPLAYERS+1] ;
float ReviveTime[MAXPLAYERS+1] ;


Handle timer_handle=INVALID_HANDLE;
 
ConVar l4d_revive_duration;
ConVar l4d_revive_maxtime;
ConVar l4d_CPR_maxtime;
ConVar l4d_CPR_duration;
ConVar l4d_revive_health;

Handle hRoundRespawn = INVALID_HANDLE;
Handle hGameConf = INVALID_HANDLE;

int revive_duration;
int revive_maxtime;
int ar_duration;
int ar_maxtime;
int maxtime;
 
int GameMode;


char g_sPlayerSave[45][] =  // Thanks to SilverShot & cravenge
{
    "m_checkpointAwardCounts",
    "m_missionAwardCounts",
    "m_checkpointZombieKills",
    "m_missionZombieKills",
    "m_checkpointSurvivorDamage",
    "m_missionSurvivorDamage",
    "m_classSpawnCount",
    "m_checkpointMedkitsUsed",
    "m_checkpointPillsUsed",
    "m_missionMedkitsUsed",
    "m_checkpointMolotovsUsed",
    "m_missionMolotovsUsed",
    "m_checkpointPipebombsUsed",
    "m_missionPipebombsUsed",
    "m_missionPillsUsed",
    "m_checkpointDamageTaken",
    "m_missionDamageTaken",
    "m_checkpointReviveOtherCount",
    "m_missionReviveOtherCount",
    "m_checkpointFirstAidShared",
    "m_missionFirstAidShared",
    "m_checkpointIncaps",
    "m_missionIncaps",
    "m_checkpointDamageToTank",
    "m_checkpointDamageToWitch",
    "m_missionAccuracy",
    "m_checkpointHeadshots",
    "m_checkpointHeadshotAccuracy",
    "m_missionHeadshotAccuracy",
    "m_checkpointDeaths",
    "m_missionDeaths",
    "m_checkpointPZIncaps",
    "m_checkpointPZTankDamage",
    "m_checkpointPZHunterDamage",
    "m_checkpointPZSmokerDamage",
    "m_checkpointPZBoomerDamage",
    "m_checkpointPZKills",
    "m_checkpointPZPounces",
    "m_checkpointPZPushes",
    "m_checkpointPZTankPunches",
    "m_checkpointPZTankThrows",
    "m_checkpointPZHung",
    "m_checkpointPZPulled",
    "m_checkpointPZBombed",
    "m_checkpointPZVomited"
};

int 	g_iPlayerData[MAXPLAYERS+1][sizeof(g_sPlayerSave)];
float 	g_fPlayerData[MAXPLAYERS+1][2];
Handle  g_RebornForward;

public Plugin myinfo = 
{
	name = "Emergency Treatment With First Aid Kit Revive And CPR",
	author = "Pan Xiaohai & AtomicStryker & Ivailosp & OtterNas3 & Dragokas",
	description = "Revive with first aid kit and CPR",
	version = PLUGIN_VERSION,	
}

/*
	Fork by Dragokas.

	ChangeLog:
	
	1.0.4 (Dragokas)
	 - Created global forward: void OnClientCPR(int client, int subject, bool bUseMedkit)
	
	1.0.3 (Dragokas)
	 - Fixed the case when player died in the air so you unable to help him.
	
	1.0.2 (Dragokas)
	 - Added translation into Russian
	 - Translated to new syntax and methodmaps
	
	1.0.1 (Dragokas)
	 - Added restoring player statictics
*/

public void OnPluginStart()
{
	LoadTranslations("revive_cpr.phrases");

	bool error=false;
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
	
	CreateConVar("l4d_revive_version", PLUGIN_VERSION, " ", FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
 
	l4d_revive_duration = CreateConVar("l4d_revive_duration", "10", "How long does revive take?", FCVAR_NONE);
	l4d_revive_health = CreateConVar("l4d_revive_health", "50", "Revive health", FCVAR_NONE);	
	l4d_revive_maxtime = CreateConVar("l4d_revive_maxtime", "300", "Dead bodys can be revived up to x seconds, 0:disable revive", FCVAR_NONE);
	l4d_CPR_maxtime = CreateConVar("l4d_CPR_maxtime", "15", "Dead bodys can be CPR within x seconds, 0:disable artificial respiration", FCVAR_NONE);
	l4d_CPR_duration = CreateConVar("l4d_CPR_duration", "6", "How long does CPR take", FCVAR_NONE);
	
	AutoExecConfig(true, "l4d_revive&cpr_v10");
 
	//RegConsoleCmd("sm_tank",	 Cmd_DamageTank, 	"Show damage deal to tank");
	//RegConsoleCmd("sm_floor",	 Cmd_DistFloor, 	"Show distance to the floor");
	
	Setting();
 
	 
	l4d_revive_duration.AddChangeHook(ConVarChange);
	l4d_revive_maxtime.AddChangeHook(ConVarChange);
	l4d_CPR_maxtime.AddChangeHook(ConVarChange);
	l4d_CPR_duration.AddChangeHook(ConVarChange);
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
	
	g_RebornForward = CreateGlobalForward("OnClientCPR", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
}

public Action Cmd_DistFloor(int client, int args) // thanks to Dr. Api
{
	PrintToChat(client, "Distance to floor: %f", GetDistanceToFloor(client));
	return Plugin_Handled;
}

public Action Cmd_DamageTank(int client, int args) // thanks to Dr. Api
{
	int iDamageTank_1 = GetEntProp(client, Prop_Send, "m_checkpointDamageToTank");
	int iDamageTank_2 = GetEntProp(client, Prop_Send, "m_checkpointPZTankDamage");
	
	PrintToChat(client, "Damage to tank: %i (%i)", iDamageTank_1, iDamageTank_2);
	
	return Plugin_Handled;
}

stock void GameCheck()
{
	char GameName[16];
	FindConVar("mp_gamemode").GetString(GameName, sizeof(GameName));
	
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
public void ConVarChange(Handle convar, const char[] oldValue, const char[] newValue)
{
	Setting();
}

void Setting()
{
 
	revive_duration=l4d_revive_duration .IntValue;
	revive_maxtime=l4d_revive_maxtime.IntValue ;
	ar_duration=l4d_CPR_duration .IntValue;
	ar_maxtime=l4d_CPR_maxtime.IntValue ;
	maxtime=ar_maxtime;
	if(revive_maxtime>maxtime)	maxtime=revive_maxtime;
}
public void player_bot_replace(Event Spawn_Event, const char[] Spawn_Name, bool Spawn_Broadcast)
{
	int client = GetClientOfUserId(Spawn_Event.GetInt("player"));
	int bot = GetClientOfUserId(Spawn_Event.GetInt("bot"));
	if(client==0 && !IsPlayerAlive(bot))
	{
		for (int j = 1; j <= MaxClients; j++)
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
public void bot_player_replace(Event Spawn_Event, const char[] Spawn_Name, bool Spawn_Broadcast)
{
	int client = GetClientOfUserId(Spawn_Event.GetInt("player"));
	int bot = GetClientOfUserId(Spawn_Event.GetInt("bot"));
	replace(bot, client);
	//PrintToChatAll("bot_player_replace %N  place %N", client, bot);
}
void replace(int client1, int client2)
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
public Action Event_PlayerDeath(Event hEvent, const char[] strName, bool DontBroadcast)
{
	if(GameMode==2)return;
	int victim = GetClientOfUserId(hEvent.GetInt("userid"));
	if(victim<=0)return;
	if(GetClientTeam(victim)==2)
	{
		GetClientAbsOrigin(victim, DeathPos[victim]);
		
		float fFloorDelta = GetDistanceToFloor(victim);
		
		DeathPos[victim][2]+=10.0 - fFloorDelta;
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

stock float GetDistanceToFloor(int client)
{ 
	float fStart[3], fDistance = 0.0;
	
	if(GetEntPropEnt(client, Prop_Send, "m_hGroundEntity") == 0)
		return 0.0;
	
	GetClientAbsOrigin(client, fStart);
	
	fStart[2] += 10.0;
	
	Handle hTrace = TR_TraceRayFilterEx(fStart, view_as<float>({90.0, 0.0, 0.0}), MASK_PLAYERSOLID, RayType_Infinite, TraceRayNoPlayers, client); 
	if(TR_DidHit(hTrace))
	{
		float fEndPos[3];
		TR_GetEndPosition(fEndPos, hTrace);
		fStart[2] -= 10.0;
		fDistance = GetVectorDistance(fStart, fEndPos);
	}
	else {
		//PrintToChat(client, "Trace did not hit anything!");
	}
	CloseHandle(hTrace);
	return fDistance; 
}

public bool TraceRayNoPlayers(int entity, int mask, any data)
{
    if(entity == data || (entity >= 1 && entity <= MaxClients))
    {
        return false;
    }
    return true;
}  

public Action hint(Handle timer, any victim)
{
	char sUsername[32];
	if(IsClientInGame(victim) && !IsPlayerAlive(victim))
	{
		for(int i=1; i<=MaxClients; i++)
		{
			if (i != 0 && IsClientInGame(i) && IsPlayerAlive(i) && !IsFakeClient(i)  )
			{
				if (revive_maxtime >= 1 && GetPlayerWeaponSlot(i, 3) !=-1)
				{
					GetClientName(victim, sUsername, sizeof(sUsername));
					PrintHintText(i, "%t", "Reborn_Medkit", sUsername); // "You can reborn %N using Medkit! Hold Ctrl + E near his Body"
				}
				if (ar_maxtime >= 1 && GetPlayerWeaponSlot(i, 3) ==-1)
				{
					GetClientName(victim, sUsername, sizeof(sUsername));
					PrintHintText(i, "%t", "Reborn_Hands", sUsername); // You can reborn %N! Hold Ctrl + E near his Body
				}
			}
		}
	}
}
public Action evtPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
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
public void OnClientDisconnect(int client)
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
float timE;
float pOs[3];
char weapon[32];
int buttons;

public Action Watch(Handle timer, any client)
{
	char sUsername[32];
	int index=0;
	timE=GetGameTime();
	for (int i = 1; i <= MaxClients; i++)
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
		for (int j = 1; j <= MaxClients; j++)
		{
			if (IsClientInGame(j) && IsPlayerAlive(j) && GetClientTeam(j)==2 && !IsFakeClient(j))
			{
				buttons = GetClientButtons(j);
				if((buttons & IN_DUCK) && (buttons & IN_USE))
				{
					GetClientWeapon(j, weapon, 32);
					bool firstaidkit=false;
					if (StrEqual(weapon, "weapon_first_aid_kit"))
					{
						firstaidkit=true;
					}
					float dis=0.0;
					float min=10000.0;
					int find=0;
					GetClientAbsOrigin(j, pOs);
					for(int i=0; i<index; i++)
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
								GetClientName(find, sUsername, sizeof(sUsername));
								PrintCenterText(j, "%t", "Already_dead", sUsername); // "%N already dead"
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
								GetClientName(find, sUsername, sizeof(sUsername));
								PrintCenterText(j, "%t", "Too_late", sUsername); // "It is too late, CPR is useless for %N"
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

void MakeForward(int client, int subject, bool bUseMedkit)
{
	Action result;
	Call_StartForward(g_RebornForward);
	Call_PushCell(client);
	Call_PushCell(subject);
	Call_PushCell(bUseMedkit ? 1 : 0);
	Call_Finish(result);
}

bool Revive(int client, int dead, bool firstaidkit)
{
	char sUsername1[32], sUsername2[32];

	if(firstaidkit)
	{
		GetClientWeapon(client, weapon, 32);
		if (StrEqual(weapon, "weapon_first_aid_kit"))
		{
			SaveStats(dead);
		
			SDKCall(hRoundRespawn, dead);
			PerformTeleport(client, dead);

			if(IsPlayerAlive(dead))
			{
				SetEntityHealth(dead,  l4d_revive_health.IntValue);
				RemovePlayerItem(client, GetPlayerWeaponSlot(client, 3));
				GetClientName(client, sUsername1, sizeof(sUsername1));
				GetClientName(dead, sUsername2, sizeof(sUsername2));
				
				CPrintToChatAll("%t", "Used_Medkit", sUsername1, sUsername2); // "\x03%N \x04used his Medkit to revive\x03 %N\x04!"
				
				CreateTimer(1.0, Timer_LoadStatDelayed, GetClientUserId(dead), TIMER_FLAG_NO_MAPCHANGE);
				
				MakeForward(client, dead, true);
				
				return true;
			}
		}
	}
	else
	{
		SaveStats(dead);
	
		SDKCall(hRoundRespawn, dead);
		PerformTeleport(client, dead);

		if(IsPlayerAlive(dead))
		{
			int propincapcounter = FindSendPropInfo("CTerrorPlayer", "m_currentReviveCount");
			SetEntData(dead, propincapcounter, 2, 1);
				
			//new Handle:revivehealth = FindConVar("pain_pills_health_value");  
		 	int temphpoffset = FindSendPropInfo("CTerrorPlayer","m_healthBuffer");
			SetEntDataFloat(dead, temphpoffset, l4d_revive_health.FloatValue, true);
			SetEntityHealth(dead, 1);
			
			GetClientName(client, sUsername1, sizeof(sUsername1));
			GetClientName(dead, sUsername2, sizeof(sUsername2));
			
			CPrintToChatAll("%t", "Used_CPR", sUsername1, sUsername2); // "\x03%N \x04used CPR to revive\x03 %N\x04!"
			
			CreateTimer(1.0, Timer_LoadStatDelayed, GetClientUserId(dead), TIMER_FLAG_NO_MAPCHANGE);
			
			MakeForward(client, dead, false);
			
			return true;
		}		
	}
	return false;
}

void PerformTeleport(int client, int dead)
{
	float pOs2[3];
	GetClientAbsOrigin(client, pOs2);
	TeleportEntity(dead, pOs2, NULL_VECTOR, NULL_VECTOR);
}

public void RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	Reset();
}

stock void CheatCommand(int client, char[] command, char[] parameter1, char[] parameter2)
{
	int userflags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	int flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s %s", command, parameter1, parameter2);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, userflags);
}
void Reset()
{
	for (int x = 0; x < MAXPLAYERS+1; x++)
	{
		CanRevive[x]=false;
		GhostLight[x]=0;
		DeathTime[x]=0.0;
		RevivePlayer[x]=0;
		ReviveTime[x]=0.0;
	}
}
char Gauge1[2] = "-";
//new String:Gauge2[2] = "-";
char Gauge3[2] = "#";
void ShowBar(int client, int dead, float pos, int max, bool firstaidkit) 
{
	char sUsername[32];

	int i;
	char ChargeBar[101];
	Format(ChargeBar, sizeof(ChargeBar), "");

	float GaugeNum = pos/max*100;
	if(GaugeNum > 100.0)
		GaugeNum = 100.0;
	if(GaugeNum<0.0)
		GaugeNum = 0.0;
	
 	for(i=0; i<100; i++)
		ChargeBar[i] = Gauge1[0];
	int p=RoundFloat( GaugeNum);
	if(p>=0 && p<100)ChargeBar[p] = Gauge3[0];
	
	GetClientName(dead, sUsername, sizeof(sUsername));
	
	if(firstaidkit)	PrintCenterText(client, "%t  %3.0f %\n<< %s >>", "Using_Medkit", sUsername, GaugeNum, ChargeBar); // "Reviving {1} using Medkit  %3.0f %\n<< %s >>"
	else            PrintCenterText(client, "%t  %3.0f %\n<< %s >>", "Using_CPR", sUsername, GaugeNum, ChargeBar); //"Heart massage for {1}  %3.0f %\n<< %s >>"
}
public int AddParticle(char s_Effect[100], float f_Origin[3])
{
	int i_Particle;
	
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
public Action KillParticle(Handle timer, any i_Particle)
{
	if (IsValidEntity(i_Particle))
	{
		RemoveEdict(i_Particle);
	}
}


public Action Timer_LoadStatDelayed(Handle timer, int UserId)
{
	int client = GetClientOfUserId(UserId);

	if( client > 0 && IsClientInGame(client)) {

		// not died in 1.0 sec after spawn?
		if (IsPlayerAlive(client)) {

			LoadStats(client);
		}
	}
}

stock void SaveStats(int client) // Thanks to SilverShot
{
	g_fPlayerData[client][0] = GetEntPropFloat(client, Prop_Send, "m_maxDeadDuration");
	g_fPlayerData[client][1] = GetEntPropFloat(client, Prop_Send, "m_totalDeadDuration");
	
	for( int i = 0; i < sizeof(g_iPlayerData[]); i++ )
	{
		g_iPlayerData[client][i] = GetEntProp(client, Prop_Send, g_sPlayerSave[i]);
	}
}

stock void LoadStats(int client) // Thanks to SilverShot
{
	SetEntPropFloat(client, Prop_Send, "m_maxDeadDuration", g_fPlayerData[client][0]);
	SetEntPropFloat(client, Prop_Send, "m_totalDeadDuration", g_fPlayerData[client][1]);
 
	for( int i = 0; i < sizeof(g_iPlayerData[]); i++ )
	{
		SetEntProp(client, Prop_Send, g_sPlayerSave[i], g_iPlayerData[client][i]);
	}
}

stock void CPrintToChatAll(const char[] format, any ...)
{
	char buffer[192];
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && !IsFakeClient(i) )
		{
			SetGlobalTransTarget(i);
			VFormat(buffer, sizeof(buffer), format, 2);
			ReplaceColor(buffer, sizeof(buffer));
			PrintToChat(i, buffer);
		}
	}
}

stock void CPrintCenterTextAll(const char[] format, any ...)
{
	char buffer[192];
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && !IsFakeClient(i) )
		{
			SetGlobalTransTarget(i);
			VFormat(buffer, sizeof(buffer), format, 2);
			ReplaceColor(buffer, sizeof(buffer));
			PrintCenterText(i, buffer);
		}
	}
}

stock void CPrintHintTextToAll(const char[] format, any ...)
{
	char buffer[192];
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) && !IsFakeClient(i) )
		{
			SetGlobalTransTarget(i);
			VFormat(buffer, sizeof(buffer), format, 2);
			ReplaceColor(buffer, sizeof(buffer));
			PrintHintText(i, buffer);
		}
	}
}

stock void ReplaceColor(char[] message, int maxLen)
{
    ReplaceString(message, maxLen, "{white}", "\x01", false);
    ReplaceString(message, maxLen, "{cyan}", "\x03", false);
    ReplaceString(message, maxLen, "{orange}", "\x04", false);
    ReplaceString(message, maxLen, "{green}", "\x05", false);
}