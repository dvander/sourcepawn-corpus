#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.1"

#define SOUND_KILL1  "/weapons/knife/knife_hitwall1.wav"
#define SOUND_KILL2  "/weapons/knife/knife_deploy.wav"

#define NO				0
#define YES				1

#define INCAP	        1
#define INCAP_GRAB	    2
#define INCAP_POUNCE    3
#define INCAP_RIDE		4
#define INCAP_PUMMEL	5
#define INCAP_EDGEGRAB	6
#define INCAP_SPECIAL	7

#define SMOKER			1
#define HUNTER			2
#define JOCKEY			3
#define CHARGER			4

#define TICKS 			10
#define STATE_NONE 		0
#define STATE_SELFHELP 	1
#define STATE_OK 		2
#define STATE_FAILED 	3

new HelpState[MAXPLAYERS+1];
new Attacker[MAXPLAYERS+1];
new IncapType[MAXPLAYERS+1];
new AttackedBySpecial[MAXPLAYERS+1];
new AttackedBy[MAXPLAYERS+1];
new Handle:Timers[MAXPLAYERS+1];

new Float:HelpStartTime[MAXPLAYERS+1];
  
new Handle:l4d_selfhelp_hint_delay = INVALID_HANDLE;
new Handle:l4d_selfhelp_delay = INVALID_HANDLE;
new Handle:l4d_selfhelp_delay_ledge = INVALID_HANDLE;
new Handle:l4d_selfhelp_delay_incap = INVALID_HANDLE;
new Handle:l4d_selfhelp_duration = INVALID_HANDLE;
new Handle:l4d_selfhelp_duration_ledge = INVALID_HANDLE;
new Handle:l4d_selfhelp_duration_incap = INVALID_HANDLE;
new Handle:l4d_selfhelp_incap = INVALID_HANDLE;
new Handle:l4d_selfhelp_grab = INVALID_HANDLE;
new Handle:l4d_selfhelp_pounce = INVALID_HANDLE;
new Handle:l4d_selfhelp_ride = INVALID_HANDLE;
new Handle:l4d_selfhelp_pummel = INVALID_HANDLE;
new Handle:l4d_selfhelp_edgegrab = INVALID_HANDLE;
new Handle:l4d_selfhelp_kill = INVALID_HANDLE;
new Handle:l4d_selfhelp_versus = INVALID_HANDLE;
new Handle:l4d_selfhelp_health_incap = INVALID_HANDLE;
new Handle:l4d_selfhelp_health_ledge = INVALID_HANDLE;

new Handle:HintTimer = INVALID_HANDLE;

//new playerhealth;

new L4D2Version=false;

public Plugin:myinfo = 
{
	name = "Self Help (Free)",
	author = "chinagreenelvis (Thanks to Pan Xiaohai)",
	description = " ",
	version = PLUGIN_VERSION,	
}

public OnPluginStart()
{
	CreateConVar("l4d_selfhelp_version", PLUGIN_VERSION, " ", FCVAR_PLUGIN|FCVAR_DONTRECORD);
	
	l4d_selfhelp_edgegrab = CreateConVar("l4d_selfhelp_edgegrab", "1", "Self help for ledge grabs , 0:Disable, 1:Enable", FCVAR_PLUGIN);		
	l4d_selfhelp_incap = CreateConVar("l4d_selfhelp_incap", "1", "Self help for incapacitation , 0:Disable, 1:Enable", FCVAR_PLUGIN);
	l4d_selfhelp_grab = CreateConVar("l4d_selfhelp_grab", "1", " Self help for smoker grab , 0:Disable, 1:Enable", FCVAR_PLUGIN);
	l4d_selfhelp_pounce = CreateConVar("l4d_selfhelp_pounce", "1", " Self help for hunter pounce , 0:Disable, 1:Enable", FCVAR_PLUGIN);
	l4d_selfhelp_ride = CreateConVar("l4d_selfhelp_ride", "1", " Self help for jockey ride , 0:Disable, 1:Enable", FCVAR_PLUGIN);
	l4d_selfhelp_pummel = CreateConVar("l4d_selfhelp_pummel", "1", "Self help for charger pummel , 0:Disable, 1:Enable", FCVAR_PLUGIN);
	l4d_selfhelp_kill = CreateConVar("l4d_selfhelp_kill", "0", "0: Break free from smokers and jockeys, set fire to hunters and chargers; 1: Knife-kill all attackers", FCVAR_PLUGIN);
	l4d_selfhelp_hint_delay = CreateConVar("l4d_selfhelp_hint_delay", "4.0", "Self help hint delay", FCVAR_PLUGIN);
	l4d_selfhelp_delay = CreateConVar("l4d_selfhelp_delay", "1.0", "Self help delay", FCVAR_PLUGIN);
	l4d_selfhelp_delay_ledge = CreateConVar("l4d_selfhelp_delay_ledge", "1.0", "Self help delay", FCVAR_PLUGIN);
	l4d_selfhelp_delay_incap = CreateConVar("l4d_selfhelp_delay_incap", "1.0", "Self help delay for incapacitation", FCVAR_PLUGIN);
	l4d_selfhelp_duration = CreateConVar("l4d_selfhelp_duration", "5.0", "Self help duration", FCVAR_PLUGIN);
	l4d_selfhelp_duration_ledge = CreateConVar("l4d_selfhelp_duration_ledge", "4.5", "Self help duration for ledge grab", FCVAR_PLUGIN);
	l4d_selfhelp_duration_incap = CreateConVar("l4d_selfhelp_duration_incap", "5.0", "Self help duration for incapacitation", FCVAR_PLUGIN);
	l4d_selfhelp_health_ledge = CreateConVar("l4d_selfhelp_health_ledge", "40.0", "How much health you have after helping yourself up off a ledge.", FCVAR_PLUGIN);	
	l4d_selfhelp_health_incap = CreateConVar("l4d_selfhelp_health_incap", "40.0", "How much health you have after helping yourself up off the ground.", FCVAR_PLUGIN);	
	l4d_selfhelp_versus = CreateConVar("l4d_selfhelp_versus", "0", "0: Disable in versus, 1: Enable in versus", FCVAR_PLUGIN);	
	
	AutoExecConfig(true, "l4d_2_selfhelp_free");
	GameCheck();
 
	HookEvent("player_incapacitated", Event_PlayerIncapacitated);
	HookEvent("lunge_pounce", Event_LungePounce);
	HookEvent("pounce_stopped", Event_PounceStopped);
	HookEvent("tongue_grab", Event_ToungeGrab);
	HookEvent("tongue_release", Event_TongueRelease);
	HookEvent("player_ledge_grab", Event_PlayerLedgeGrab);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_hurt", Event_PlayerHurt);
  	 
	if(L4D2Version)
	{
		HookEvent("jockey_ride", Event_JockeyRide);
		HookEvent("jockey_ride_end", Event_JockeyRideEnd);
		HookEvent("charger_pummel_start", Event_ChargerPummelStart);
		HookEvent("charger_pummel_end", Event_ChargerPummelEnd);
	}
}
new GameMode;
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
 	if(L4D2Version)	PrecacheSound(SOUND_KILL2, true) ;
	else PrecacheSound(SOUND_KILL1, true) ;	 
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	reset();
	return Plugin_Continue;
}

public Event_LungePounce (Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GameMode == 2 && GetConVarInt(l4d_selfhelp_versus) == 0)return;
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!victim) return;
	if (!attacker) return;
	Attacker[victim] = attacker;
	IncapType[victim] = INCAP_POUNCE;
	AttackedBySpecial[victim] = YES;
	AttackedBy[victim] = HUNTER;
	if(	GetConVarInt(l4d_selfhelp_pounce) > 0)
	{
		CreateTimer(GetConVarFloat(l4d_selfhelp_delay), WatchPlayer, victim);	
	}
	//PrintToChatAll("start prounce"); 
}

public Event_PounceStopped (Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GameMode == 2 && GetConVarInt(l4d_selfhelp_versus) == 0)return;	
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	if (!victim) return;
	Attacker[victim] = 0;
	AttackedBySpecial[victim] = NO;
	//PrintToChatAll("end prounce"); 
}

public Event_ToungeGrab (Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GameMode == 2 && GetConVarInt(l4d_selfhelp_versus) == 0)return;
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!victim) return;
	if (!attacker) return;
	Attacker[victim] = attacker;
	IncapType[victim] = INCAP_GRAB;
	AttackedBySpecial[victim] = YES;
	AttackedBy[victim] = SMOKER;
	if(	GetConVarInt(l4d_selfhelp_grab) > 0)
	{
 		CreateTimer(GetConVarFloat(l4d_selfhelp_delay), WatchPlayer, victim);	
	}
}

public Event_TongueRelease (Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GameMode == 2 && GetConVarInt(l4d_selfhelp_versus) == 0)return;
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!victim) return;
	if (!attacker) return;
	if(Attacker[victim] == attacker)
	{
		Attacker[victim] = 0;
		AttackedBySpecial[victim] = NO;
	}
	//PrintToChatAll("end grab"); 
}

public Event_JockeyRide (Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GameMode == 2 && GetConVarInt(l4d_selfhelp_versus) == 0)return;
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!victim) return;
	if (!attacker) return;
	Attacker[victim] = attacker;
	IncapType[victim] = INCAP_RIDE;
	AttackedBySpecial[victim] = YES;
	AttackedBy[victim] = JOCKEY;
	if(	GetConVarInt(l4d_selfhelp_ride) > 0)
	{
 		CreateTimer(GetConVarFloat(l4d_selfhelp_delay), WatchPlayer, victim);	
	}
	//PrintToChatAll("Event_JockeyRide"); 
}

public Event_JockeyRideEnd (Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GameMode == 2 && GetConVarInt(l4d_selfhelp_versus) == 0)return;
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!victim) return;
	if (!attacker) return;
	if(Attacker[victim] == attacker)
	{
		Attacker[victim] = 0;
		AttackedBySpecial[victim] = NO;
	}
	//PrintToChatAll("Event_JockeyRideEnd"); 
}

public Event_ChargerPummelStart (Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GameMode == 2 && GetConVarInt(l4d_selfhelp_versus)==0)return;
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!victim) return;
	if (!attacker) return;
	Attacker[victim] = attacker;
	IncapType[victim] = INCAP_PUMMEL;
	AttackedBySpecial[victim] = YES;
	AttackedBy[victim] = CHARGER;
	if(	GetConVarInt(l4d_selfhelp_pummel) > 0)
	{
 		CreateTimer(GetConVarFloat(l4d_selfhelp_delay), WatchPlayer, victim);	
	}
	//PrintToChatAll("Event_ChargerPummelStart"); 
}

public Event_ChargerPummelEnd (Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GameMode == 2 && GetConVarInt(l4d_selfhelp_versus) == 0)return;
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!victim) return;
	if (!attacker) return;
	if(Attacker[victim] == attacker)
	{
		Attacker[victim] = 0;
		AttackedBySpecial[victim] = NO;
	}
	//PrintToChatAll("Event_ChargerPummelEnd"); 

}
 
public Event_PlayerIncapacitated (Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GameMode == 2 && GetConVarInt(l4d_selfhelp_versus) == 0)return;
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	IncapType[victim] = INCAP;
	if (GetConVarInt(l4d_selfhelp_incap) > 0)
	{
		CreateTimer(GetConVarFloat(l4d_selfhelp_delay_incap), WatchPlayer, victim);	
	}
}

public Action:Event_PlayerLedgeGrab(Handle:event, String:event_name[], bool:dontBroadcast)
{
	if(GameMode == 2 && GetConVarInt(l4d_selfhelp_versus) == 0)return;
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	IncapType[victim] = INCAP_EDGEGRAB;
	if(GetConVarInt(l4d_selfhelp_edgegrab) > 0)
	{
		CreateTimer(GetConVarFloat(l4d_selfhelp_delay_ledge), WatchPlayer, victim);	
 	}
}
 
public Action:WatchPlayer(Handle:timer, any:client)
{
 	if (!client) return;
	if (!IsClientInGame(client)) return;
	if (!IsPlayerAlive(client)) return;
	HintTimer = CreateTimer (GetConVarFloat(l4d_selfhelp_hint_delay), HintDelay, client);
	if (!IsPlayerIncapacitated(client) && !IsPlayerHangingFromLedge(client) && Attacker[client] == 0 )return;
 	if(Timers[client] != INVALID_HANDLE)return;
 	HelpState[client] = STATE_NONE;
	Timers[client] = CreateTimer(1.0/TICKS, PlayerTimer, client, TIMER_REPEAT);
}

public Action:HintDelay(Handle:timer, any:client)
{
	if(CanSelfHelp(client))
	{
		PrintHintText(client, "        \x03Hold \x04DUCK\x03 to help yourself!");
	}
}

bool:CanSelfHelp(client)
{
	new bool:ok = false;
	if(IncapType[client] == INCAP)
	{
		if(GetConVarInt(l4d_selfhelp_incap) == 1 ) ok = true;
	}
	else if(IncapType[client] == INCAP_EDGEGRAB)
	{
		if(GetConVarInt(l4d_selfhelp_edgegrab) == 1 ) ok = true;
	}
	else if(IncapType[client] == INCAP_GRAB)
	{
		if(GetConVarInt(l4d_selfhelp_grab) == 1 ) ok = true;
	}
	else if(IncapType[client] == INCAP_POUNCE)
	{
		if(GetConVarInt(l4d_selfhelp_pounce) == 1 ) ok = true;
	}
	else if(IncapType[client] == INCAP_RIDE)
	{
		if(GetConVarInt(l4d_selfhelp_ride) == 1 ) ok = true;
	}
	else if(IncapType[client] == INCAP_PUMMEL)
	{
		if(GetConVarInt(l4d_selfhelp_pummel) == 1 ) ok = true;
	}
	
	return ok;
}

public Action:PlayerTimer(Handle:timer, any:client)
{
	new Float:time=GetEngineTime();
	 
	if (client==0 )
	{
		HelpState[client] = STATE_NONE;
		Timers[client] = INVALID_HANDLE;
 		return Plugin_Stop;
	}
	if(!IsClientInGame(client) || !IsPlayerAlive(client)  ) 
	{
		HelpState[client] = STATE_NONE;
		Timers[client] = INVALID_HANDLE;
 		return Plugin_Stop;
	}
 
	if( !IsPlayerIncapacitated(client) && !IsPlayerHangingFromLedge(client) && Attacker[client]==0)
	{
	
		HelpState[client] = STATE_NONE;
		Timers[client] = INVALID_HANDLE;
 		return Plugin_Stop;
	}
	
	if(!IsPlayerIncapacitated(client) && !IsPlayerHangingFromLedge(client) && Attacker[client]!=0)
	{
 		if (!IsClientInGame(Attacker[client]) || !IsPlayerAlive(Attacker[client]))
		{
			HelpState[client]=STATE_NONE;
			Timers[client] = INVALID_HANDLE;
			Attacker[client] = 0;
 			return Plugin_Stop;
		}

	}
	if(HelpState[client]==STATE_OK )
	{
 		HelpState[client]=STATE_NONE;
		Timers[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}
 
	new buttons = GetClientButtons(client);
	
	if(buttons & IN_DUCK || buttons & IN_USE)
	{
		if(CanSelfHelp(client))
		{
			if (IncapType[client] == INCAP)
			{
				if (GetConVarFloat(l4d_selfhelp_duration_incap) <= 5.0)
				{
					if(L4D2Version)
					{
						if(HelpState[client] == STATE_NONE)
						{
							HelpStartTime[client] = time;
							if (AttackedBySpecial[client] == NO)
							{
								SetupProgressBarAnimated(client, GetConVarFloat(l4d_selfhelp_duration_incap));
							}
							else
							{
								SetupProgressBar(client, GetConVarFloat(l4d_selfhelp_duration_incap));
							}
							//PrintHintText(client, "You are helping youself...");
						}
					}
					else
					{
						if(HelpState[client] == STATE_NONE) HelpStartTime[client] = time;
						ShowBar(client,"self help ", time-HelpStartTime[client], GetConVarFloat(l4d_selfhelp_duration_incap));
					}
					
					HelpState[client] = STATE_SELFHELP;
					//PrintToChatAll("%f  %f", time-HelpStartTime[client], GetConVarFloat(l4d_selfhelp_duration_incap));
					if(time-HelpStartTime[client] > GetConVarFloat(l4d_selfhelp_duration_incap))
					{
						if(HelpState[client] != STATE_OK)
						{
							SelfHelpIncap(client);
							if(L4D2Version)
							{
								KillProgressBar(client);
								KillProgressBarAnimated(client);
							}
						}
					}
				}
				else
				{
					if(L4D2Version)
					{
						if(HelpState[client] == STATE_NONE)
						{
							HelpStartTime[client] = time;
							SetupProgressBar(client, GetConVarFloat(l4d_selfhelp_duration_incap));
							//PrintHintText(client, "You are helping youself...");
						}
				
					}
					else
					{
						if(HelpState[client] == STATE_NONE) HelpStartTime[client] = time;
						ShowBar(client,"self help ", time-HelpStartTime[client], GetConVarFloat(l4d_selfhelp_duration_incap));
					}
					
					HelpState[client] = STATE_SELFHELP;
					//PrintToChatAll("%f  %f", time-HelpStartTime[client], GetConVarFloat(l4d_selfhelp_duration_incap));
					if(time-HelpStartTime[client] > GetConVarFloat(l4d_selfhelp_duration_incap))
					{
						if(HelpState[client] != STATE_OK)
						{
							SelfHelpIncap(client);
							if(L4D2Version)KillProgressBar(client);
						}
					}
				}
			}
			if (IncapType[client] == INCAP_EDGEGRAB)
			{
				if (GetConVarFloat(l4d_selfhelp_duration_ledge) <= 4.5)
				{
					if(L4D2Version)
					{
						if(HelpState[client] == STATE_NONE)
						{
							HelpStartTime[client] = time;
							SetupProgressBarAnimated(client, GetConVarFloat(l4d_selfhelp_duration_ledge));
							//PrintHintText(client, "You are helping youself...");
						}
					}
					else
					{
						if(HelpState[client] == STATE_NONE) HelpStartTime[client] = time;
						ShowBar(client,"self help ", time-HelpStartTime[client], GetConVarFloat(l4d_selfhelp_duration_ledge));
					}
					
					HelpState[client] = STATE_SELFHELP;
					//PrintToChatAll("%f  %f", time-HelpStartTime[client], GetConVarFloat(l4d_selfhelp_duration_ledge));
					if(time-HelpStartTime[client] > GetConVarFloat(l4d_selfhelp_duration_ledge))
					{
						if(HelpState[client] != STATE_OK)
						{
							SelfHelpLedge(client);
							if(L4D2Version)KillProgressBarAnimated(client);
						}
					}
				}
				else
				{
					if(L4D2Version)
					{
						if(HelpState[client] == STATE_NONE)
						{
							HelpStartTime[client] = time;
							SetupProgressBar(client, GetConVarFloat(l4d_selfhelp_duration_ledge));
							//PrintHintText(client, "You are helping youself...");
						}
					}
					else
					{
						if(HelpState[client] == STATE_NONE) HelpStartTime[client] = time;
						ShowBar(client,"self help ", time-HelpStartTime[client], GetConVarFloat(l4d_selfhelp_duration_ledge));
					}
					
					HelpState[client] = STATE_SELFHELP;
					//PrintToChatAll("%f  %f", time-HelpStartTime[client], GetConVarFloat(l4d_selfhelp_duration_ledge));
					if(time-HelpStartTime[client] > GetConVarFloat(l4d_selfhelp_duration_ledge))
					{
						if(HelpState[client] != STATE_OK)
						{
							SelfHelpLedge(client);
							if(L4D2Version)KillProgressBar(client);
						}
					}
				}
			}
			else
			{
				if(L4D2Version)
				{
					if(HelpState[client] == STATE_NONE)
					{
						HelpStartTime[client] = time;
						SetupProgressBar(client, GetConVarFloat(l4d_selfhelp_duration));
						//PrintHintText(client, "You are helping youself...");
					}
				}
				else
				{
					if(HelpState[client] == STATE_NONE) HelpStartTime[client] = time;
					ShowBar(client,"self help ", time-HelpStartTime[client], GetConVarFloat(l4d_selfhelp_duration));
				}
				
				HelpState[client] = STATE_SELFHELP;
				//PrintToChatAll("%f  %f", time-HelpStartTime[client], GetConVarFloat(l4d_selfhelp_duration));
				if(time-HelpStartTime[client] > GetConVarFloat(l4d_selfhelp_duration))
				{
					if(HelpState[client] != STATE_OK)
					{
						SelfHelp(client);
						if(L4D2Version)KillProgressBar(client);
					}
				}
			}
			if (HintTimer != INVALID_HANDLE)
			{
				KillTimer(HintTimer);
				HintTimer = INVALID_HANDLE;
			}
		}
		else if(HelpState[client] == STATE_SELFHELP)
		{
			if(L4D2Version)KillProgressBar(client);
			HelpState[client] = STATE_NONE;
		}
	}
	else
	{
		if(HelpState[client] == STATE_SELFHELP)
		{
			if(L4D2Version)
			{
				KillProgressBar(client);
				KillProgressBarAnimated(client);
			}
			else 
			{
				ShowBar(client, "self help ", 0.0, GetConVarFloat(l4d_selfhelp_duration));
			}
			HelpState[client] = STATE_NONE;
		}
	}
 	return Plugin_Continue;
}

public Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new damagetype = GetEventInt(event, "type");
	if (damagetype != 131072 && AttackedBySpecial[client] == NO)
	{
		if (IsClientInGame(client) && GetClientTeam(client) == 2 && HelpState[client] == STATE_SELFHELP)
		{
			if(L4D2Version)
			{
				KillProgressBar(client);
				KillProgressBarAnimated(client);
			}
			else 
			{
				ShowBar(client, "self help ", 0.0, GetConVarFloat(l4d_selfhelp_duration));
			}
			HelpState[client] = STATE_NONE;
		}
	}
}

SelfHelp(client)
{ 
 	if (!IsClientInGame(client) || !IsPlayerAlive(client) )
	{
		return;
	} 
	if( !IsPlayerIncapacitated(client) && !IsPlayerHangingFromLedge(client) && Attacker[client]==0) 
	{
		return;
	} 
	
	if(GetConVarInt(l4d_selfhelp_kill) == 0) 
	{
		KnockAttack(client);
	}
	if(GetConVarInt(l4d_selfhelp_kill) > 0) 
	{
		KillAttack(client);
	}
	
	HelpState[client] = STATE_OK;
	//PrintToChatAll("\x04%N\x03 help himself!", client);
	
}

SelfHelpLedge(client)
{ 
 	if (!IsClientInGame(client) || !IsPlayerAlive(client) )
	{
		return;
	} 
	if( !IsPlayerIncapacitated(client) && !IsPlayerHangingFromLedge(client) && Attacker[client]==0) 
	{
		return;
	} 
	ReviveClientLedge(client);
	HelpState[client] = STATE_OK;
	//PrintToChatAll("\x04%N\x03 help himself!", client); 
}

SelfHelpIncap(client)
{ 
 	if (!IsClientInGame(client) || !IsPlayerAlive(client) )
	{
		return;
	} 
	if( !IsPlayerIncapacitated(client) && !IsPlayerHangingFromLedge(client) && Attacker[client]==0) 
	{
		return;
	} 
	if (AttackedBySpecial[client] == YES)
	{
		if(GetConVarInt(l4d_selfhelp_kill) > 0) 
		{
			KillAttack(client);
			ReviveClientIncap(client);
		}
		else
		{
			KnockAttack(client);
			ReviveClientIncap(client);
		}
	}
	else
	{
		ReviveClientIncap(client);
	}
	HelpState[client] = STATE_OK;
	//PrintToChatAll("\x04%N\x03 help himself!", client);  
}

ReviveClientLedge(client)
{
	new propincapcounter = FindSendPropInfo("CTerrorPlayer", "m_currentReviveCount");
	new userflags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	new iflags=GetCommandFlags("give");
	SetCommandFlags("give", iflags & ~FCVAR_CHEAT);
	FakeClientCommand(client,"give health");
	SetCommandFlags("give", iflags);
	SetUserFlagBits(client, userflags);			
	SetEntData(client, propincapcounter, 0, 1);
	new temphpoffset = FindSendPropOffs("CTerrorPlayer","m_healthBuffer");
	SetEntDataFloat(client, temphpoffset, GetConVarFloat(l4d_selfhelp_health_ledge), true);
	SetEntityHealth(client, 1);
}

ReviveClientIncap(client)
{
	new propincapcounter = FindSendPropInfo("CTerrorPlayer", "m_currentReviveCount");
	new userflags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	new iflags=GetCommandFlags("give");
	SetCommandFlags("give", iflags & ~FCVAR_CHEAT);
	FakeClientCommand(client,"give health");
	SetCommandFlags("give", iflags);
	SetUserFlagBits(client, userflags);
	SetEntData(client, propincapcounter, 0, 1);	 
	new temphpoffset = FindSendPropOffs("CTerrorPlayer","m_healthBuffer");
	SetEntDataFloat(client, temphpoffset, GetConVarFloat(l4d_selfhelp_health_incap), true);
	SetEntityHealth(client, 1);
}

KnockAttack(client)
{
	new attacker = Attacker[client];
	{
		if (AttackedBy[client] == SMOKER)
		{
			SlapPlayer(attacker, 0);
		}
		if (AttackedBy[client] == HUNTER)
		{
			IgniteEntity(attacker, 15.0);
		}
		if (AttackedBy[client] == JOCKEY)
		{
			ExecuteCommand(attacker, "dismount");
		}
		if (AttackedBy[client] == CHARGER)
		{
			IgniteEntity(attacker, 20.0);
		}
	}
}

ExecuteCommand(Client, String:strCommand[])
{
	new flags = GetCommandFlags(strCommand);
    
	SetCommandFlags(strCommand, flags & ~FCVAR_CHEAT);
	FakeClientCommand(Client, "%s", strCommand);
	SetCommandFlags(strCommand, flags);
}

KillAttack(client)
{
	new attacker = Attacker[client];
	if( GetConVarInt(l4d_selfhelp_kill) == 1 && attacker != 0)
	{
		if (GetClientTeam(attacker) == 3 && IsClientInGame(attacker) && IsPlayerAlive(attacker) && GetEntProp(attacker, Prop_Send, "m_zombieClass") != 8)
		{
			ForcePlayerSuicide(attacker);
			if(L4D2Version)	EmitSoundToAll(SOUND_KILL2, client); 
			else EmitSoundToAll(SOUND_KILL1, client); 
		}
	}
}

new String:Gauge1[2] = "-";
new String:Gauge3[2] = "#";

ShowBar(client, String:msg[], Float:pos, Float:max)	 
{
	new i ;
	new String:ChargeBar[100];
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
 	/* Display gauge */
	PrintCenterText(client, "%s  %3.0f %\n<< %s >>", msg, GaugeNum, ChargeBar);
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

bool:IsPlayerIncapacitated(client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1)) 
	{
		return true;
	}
 	return false;
}

bool:IsPlayerHangingFromLedge(client)
{
 	if (GetEntProp(client, Prop_Send, "m_isHangingFromLedge", 1))
	{
		return true;
	}
	return false;
}

reset()
{
	for (new x = 0; x < MAXPLAYERS+1; x++)
	{
		HelpState[x] = STATE_NONE;
		Attacker[x] = 0;
		HelpStartTime[x] = 0.0;
		if(Timers[x] != INVALID_HANDLE)
		{
			KillTimer(Timers[x]);
		}
		Timers[x] = INVALID_HANDLE;
	}
}

stock SetupProgressBar(client, Float:time)
{
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", time);
}

stock KillProgressBar(client)
{	
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", 0.0);
}

stock SetupProgressBarAnimated(client, Float:time)
{
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", time);
	SetEntPropEnt(client, Prop_Send, "m_reviveOwner", client);
}

stock KillProgressBarAnimated(client)
{	
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", 0.0);
	SetEntPropEnt(client, Prop_Send, "m_reviveOwner", -1);
}

