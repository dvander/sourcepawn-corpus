#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.1m"

#define SOUND_KILL1  "/weapons/knife/knife_hitwall1.wav"
#define SOUND_KILL2  "/weapons/knife/knife_deploy.wav"

#define INCAP			 1
#define INCAP_GRAB		 2
#define INCAP_POUNCE	 3
#define INCAP_RIDE		 4
#define INCAP_PUMMEL	 5
#define INCAP_EDGEGRAB	 6

#define TICKS 10
#define STATE_NONE 0
#define STATE_SELFHELP 1
#define STATE_OK 2
#define STATE_FAILED 3

#define TRANSLATIONS_FILENAME	"l4d_selfhelp.phrases"

new HelpState[MAXPLAYERS+1];
new HelpOhterState[MAXPLAYERS+1];
new Attacker[MAXPLAYERS+1];
new IncapType[MAXPLAYERS+1];
new Handle:Timers[MAXPLAYERS+1];

new Float:HelpStartTime[MAXPLAYERS+1];

new Handle:l4d_selfhelp_delay = INVALID_HANDLE;
new Handle:l4d_selfhelp_hintdelay = INVALID_HANDLE;
new Handle:l4d_selfhelp_durtaion = INVALID_HANDLE;
new Handle:l4d_selfhelp_incap = INVALID_HANDLE;
new Handle:l4d_selfhelp_grab = INVALID_HANDLE;
new Handle:l4d_selfhelp_pounce = INVALID_HANDLE;
new Handle:l4d_selfhelp_ride = INVALID_HANDLE;
new Handle:l4d_selfhelp_pummel = INVALID_HANDLE;
new Handle:l4d_selfhelp_edgegrab = INVALID_HANDLE;
new Handle:l4d_selfhelp_eachother = INVALID_HANDLE;
new Handle:l4d_selfhelp_pickup = INVALID_HANDLE;
new Handle:l4d_selfhelp_kill = INVALID_HANDLE;
new Handle:l4d_selfhelp_versus = INVALID_HANDLE;

new L4D2Version=false;

public Plugin:myinfo =
{
	name = "Self Help ",
	author = "Pan Xiaohai",
	description = " ",
	version = PLUGIN_VERSION,
}

public OnPluginStart()
{
	LoadPluginTranslations();

	CreateConVar("l4d_selfhelp_version", PLUGIN_VERSION, " ", FCVAR_NOTIFY|FCVAR_DONTRECORD);

	l4d_selfhelp_incap = CreateConVar("l4d_selfhelp_incap", "3", "self help for incap , 0:disable, 1:pill, 2:medkit, 3:both  ", FCVAR_NOTIFY);
	l4d_selfhelp_grab = CreateConVar("l4d_selfhelp_grab", "3", " self help for grab , 0:disable, 1:pill, 2:medkit, 3:both ", FCVAR_NOTIFY);
	l4d_selfhelp_pounce = CreateConVar("l4d_selfhelp_pounce", "3", " self help for pounce , 0:disable, 1:pill, 2:medkit, 3:both ", FCVAR_NOTIFY);
	l4d_selfhelp_ride = CreateConVar("l4d_selfhelp_ride", "3", " self help for ride , 0:disable, 1:pill, 2:medkit, 3:both ", FCVAR_NOTIFY);
	l4d_selfhelp_pummel = CreateConVar("l4d_selfhelp_pummel", "3", "self help for pummel , 0:disable, 1:pill, 2:medkit, 3:both  ", FCVAR_NOTIFY);
	l4d_selfhelp_edgegrab = CreateConVar("l4d_selfhelp_edgegrab", "3", "self help for edgegrab , 0:disable, 1:pill, 2:medkit, 3:both  ", FCVAR_NOTIFY);
	l4d_selfhelp_eachother = CreateConVar("l4d_selfhelp_eachother", "1", "incap help each other , 0: disable, 1 :enable  ", FCVAR_NOTIFY);
	l4d_selfhelp_pickup = CreateConVar("l4d_selfhelp_pickup", "1", "incap pick up , 0: disable, 1 :enable  ", FCVAR_NOTIFY);
	l4d_selfhelp_kill = CreateConVar("l4d_selfhelp_kill", "1", "kill attacker", FCVAR_NOTIFY);

	l4d_selfhelp_hintdelay = CreateConVar("l4d_selfhelp_hintdelay", "3.0", "hint delay", FCVAR_NOTIFY);
	l4d_selfhelp_delay = CreateConVar("l4d_selfhelp_delay", "1.0", "self help delay", FCVAR_NOTIFY);
	l4d_selfhelp_durtaion = CreateConVar("l4d_selfhelp_durtaion", "3.0", "self help duration", FCVAR_NOTIFY);

	l4d_selfhelp_versus = CreateConVar("l4d_selfhelp_versus", "1", "0: disable in versus, 1: enable in versus", FCVAR_NOTIFY);

	AutoExecConfig(true, "l4d_selfhelp_en");
	GameCheck();

	HookEvent("player_incapacitated", Event_Incap);

	HookEvent("lunge_pounce", lunge_pounce);
	HookEvent("pounce_stopped", pounce_stopped);

	HookEvent("tongue_grab", tongue_grab);
	HookEvent("tongue_release", tongue_release);

	HookEvent("player_ledge_grab", player_ledge_grab);

	HookEvent("heal_success", Event_HealSuccess);
	HookEvent("player_bot_replace", Event_BotReplace);
	HookEvent("bot_player_replace", Event_PlayerReplace);

	HookEvent("round_start", RoundStart);

	if(L4D2Version)
	{
		HookEvent("jockey_ride", jockey_ride);
		HookEvent("jockey_ride_end", jockey_ride_end);

		HookEvent("charger_pummel_start", charger_pummel_start);
		HookEvent("charger_pummel_end", charger_pummel_end);
	}
}

void LoadPluginTranslations()
{
	LoadTranslations("common.phrases");

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, PLATFORM_MAX_PATH, "translations/%s.txt", TRANSLATIONS_FILENAME);
	if (FileExists(sPath))
		LoadTranslations(TRANSLATIONS_FILENAME);
	else
		SetFailState("Missing required translation file on 'translations/%s.txt', please re-download.", TRANSLATIONS_FILENAME);
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

	EngineVersion engine = GetEngineVersion();
	L4D2Version = (engine == Engine_Left4Dead2);
}
public OnMapStart()
{
	if(L4D2Version)	PrecacheSound(SOUND_KILL2, true) ;
	else PrecacheSound(SOUND_KILL1, true) ;

}
public Action:RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	reset();
	return Plugin_Continue;
}

public void Event_HealSuccess(Handle:event, const String:name[], bool:dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "subject"));
	StopSoundPerm(client, "player/heartbeatloop.wav");
}

/****************************************************************************************************/

public void Event_BotReplace(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("player"));
	int bot = GetClientOfUserId(event.GetInt("bot"));

	if (!IsValidClient(client))
		return;

	if (!IsValidClient(bot))
		return;

	if (GetEntProp(client, Prop_Send, "m_currentReviveCount") != GetConVarInt(FindConVar("survivor_max_incapacitated_count")))
		StopSoundPerm(client, "player/heartbeatloop.wav");
}

/****************************************************************************************************/

public void Event_PlayerReplace(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("player"));
	int bot = GetClientOfUserId(event.GetInt("bot"));

	if (!IsValidClient(client))
		return;

	if (!IsValidClient(bot))
		return;

	if (GetEntProp(client, Prop_Send, "m_currentReviveCount") != GetConVarInt(FindConVar("survivor_max_incapacitated_count")))
		StopSoundPerm(client, "player/heartbeatloop.wav");
}

public lunge_pounce (Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GameMode==2 && GetConVarInt(l4d_selfhelp_versus)==0)return;
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!victim) return;
	if (!attacker) return;
	Attacker[victim] = attacker;
	IncapType[victim]=INCAP_POUNCE;
	if(	GetConVarInt(l4d_selfhelp_pounce)>0)
	{
		CreateTimer(GetConVarFloat(l4d_selfhelp_delay), WatchPlayer, victim);
		CreateTimer(GetConVarFloat(l4d_selfhelp_hintdelay), AdvertisePills, victim);
	}
}
public pounce_stopped (Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GameMode==2 && GetConVarInt(l4d_selfhelp_versus)==0)return;
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	if (!victim) return;
	Attacker[victim] = 0;
}
public tongue_grab (Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GameMode==2 && GetConVarInt(l4d_selfhelp_versus)==0)return;
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!victim) return;
	if (!attacker) return;
	Attacker[victim] = attacker;
	IncapType[victim]=INCAP_GRAB;
	if(	GetConVarInt(l4d_selfhelp_grab)>0)
	{
		CreateTimer(GetConVarFloat(l4d_selfhelp_delay), WatchPlayer, victim);
		CreateTimer(GetConVarFloat(l4d_selfhelp_hintdelay), AdvertisePills, victim);
	}
}

public tongue_release (Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GameMode==2 && GetConVarInt(l4d_selfhelp_versus)==0)return;
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!victim) return;
	if (!attacker) return;
	if(Attacker[victim] ==attacker)
	{
		Attacker[victim] = 0;
	}

}
public jockey_ride (Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GameMode==2 && GetConVarInt(l4d_selfhelp_versus)==0)return;
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!victim) return;
	if (!attacker) return;
	Attacker[victim] = attacker;
	IncapType[victim]=INCAP_RIDE;
	if(	GetConVarInt(l4d_selfhelp_ride)>0)
	{
		CreateTimer(GetConVarFloat(l4d_selfhelp_delay), WatchPlayer, victim);
		CreateTimer(GetConVarFloat(l4d_selfhelp_hintdelay), AdvertisePills, victim);
	}
}

public jockey_ride_end (Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GameMode==2 && GetConVarInt(l4d_selfhelp_versus)==0)return;
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!victim) return;
	if (!attacker) return;
	if(Attacker[victim] ==attacker)
	{
		Attacker[victim] = 0;
	}

}

public charger_pummel_start (Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GameMode==2 && GetConVarInt(l4d_selfhelp_versus)==0)return;
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!victim) return;
	if (!attacker) return;
	Attacker[victim] = attacker;
	IncapType[victim]=INCAP_PUMMEL;
	if(	GetConVarInt(l4d_selfhelp_pummel)>0)
	{
		CreateTimer(GetConVarFloat(l4d_selfhelp_delay), WatchPlayer, victim);
		CreateTimer(GetConVarFloat(l4d_selfhelp_hintdelay), AdvertisePills, victim);
	}
}

public charger_pummel_end (Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GameMode==2 && GetConVarInt(l4d_selfhelp_versus)==0)return;
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!victim) return;
	if (!attacker) return;
	if(Attacker[victim] ==attacker)
	{
		Attacker[victim] = 0;
	}

}

public Event_Incap (Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GameMode==2 && GetConVarInt(l4d_selfhelp_versus)==0)return;
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	IncapType[victim]=INCAP;
	if(GetConVarInt(l4d_selfhelp_incap)>0)
	{
		CreateTimer(GetConVarFloat(l4d_selfhelp_delay), WatchPlayer, victim);
		CreateTimer(GetConVarFloat(l4d_selfhelp_hintdelay), AdvertisePills, victim);
	}
}
public Action:player_ledge_grab(Handle:event, String:event_name[], bool:dontBroadcast)
{
	if(GameMode==2 && GetConVarInt(l4d_selfhelp_versus)==0)return;
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	IncapType[victim]=INCAP_EDGEGRAB;
	if(GetConVarInt(l4d_selfhelp_edgegrab)>0)
	{
		CreateTimer(GetConVarFloat(l4d_selfhelp_delay), WatchPlayer, victim);
		CreateTimer(GetConVarFloat(l4d_selfhelp_hintdelay), AdvertisePills, victim);
	}
}


public Action:WatchPlayer(Handle:timer, any:client)
{

	if (!client) return;
	if (!IsClientInGame(client)) return;
	if (!IsPlayerAlive(client)) return;
	if (!IsPlayerIncapped(client) && !IsPlayerGrapEdge(client) && Attacker[client]==0 )return;

	if(Timers[client]!=INVALID_HANDLE)return;

	HelpOhterState[client]=HelpState[client]=STATE_NONE;

	Timers[client]=CreateTimer(1.0/TICKS, PlayerTimer, client, TIMER_REPEAT);
}
public Action:AdvertisePills(Handle:timer, any:client)
{

	if (!client) return;
	if (!IsClientInGame(client)) return;
	if (!IsPlayerAlive(client)) return;

	if(CanSelfHelp(client))
		PrintToChat(client, "%t", "Keyboard Key Self Help");
}
bool:CanSelfHelp(client)
{
	new bool:pills=HavePills(client);
	new bool:kid=HaveKid(client);
	new bool:adrenaline=HaveAdrenaline(client);
	new bool:ok=false;
	new self;
	if(IncapType[client]==INCAP)
	{
		self=GetConVarInt( l4d_selfhelp_incap);
		if((self==1 || self==3) && (pills || adrenaline))ok=true;
		else if ((self==2 || self==3) && kid)ok=true;
	}
	else if(IncapType[client]== INCAP_EDGEGRAB)
	{
		self=GetConVarInt( l4d_selfhelp_edgegrab);
		if((self==1 || self==3) && (pills || adrenaline))ok=true;
		else if ((self==2 || self==3) && kid)ok=true;
	}
	else if(IncapType[client]== INCAP_GRAB)
	{
		self=GetConVarInt( l4d_selfhelp_grab);
		if((self==1 || self==3) && (pills || adrenaline))ok=true;
		else if ((self==2 || self==3) && kid)ok=true;
	}
	else if(IncapType[client]== INCAP_POUNCE)
	{
		self=GetConVarInt( l4d_selfhelp_pounce);
		if((self==1 || self==3) && (pills || adrenaline))ok=true;
		else if ((self==2 || self==3) && kid)ok=true;
	}
	else if(IncapType[client]== INCAP_RIDE)
	{
		self=GetConVarInt( l4d_selfhelp_ride);
		if((self==1 || self==3) && (pills || adrenaline))ok=true;
		else if ((self==2 || self==3) && kid)ok=true;
	}
	else if(IncapType[client]== INCAP_PUMMEL)
	{
		self=GetConVarInt( l4d_selfhelp_pummel);
		if((self==1 || self==3) && (pills || adrenaline))ok=true;
		else if ((self==2 || self==3) && kid)ok=true;
	}
	return ok;
}
SelfHelpUseSlot(client)
{
	new pills = GetPlayerWeaponSlot(client, 4);
	new kid=GetPlayerWeaponSlot(client, 3);
	new solt=-1;
	new self;
	if(IncapType[client]==INCAP)
	{
		self=GetConVarInt( l4d_selfhelp_incap);
		if((self==1 || self==3) && pills!=-1)solt=4;
		else if ((self==2 || self==3) && kid)solt=3;
	}
	else if(IncapType[client]== INCAP_EDGEGRAB)
	{
		self=GetConVarInt( l4d_selfhelp_edgegrab);
		if((self==1 || self==3) && pills!=-1)solt=4;
		else if ((self==2 || self==3) && kid)solt=3;
	}
	else if(IncapType[client]== INCAP_GRAB)
	{
		self=GetConVarInt( l4d_selfhelp_grab);
		if((self==1 || self==3) && pills!=-1)solt=4;
		else if ((self==2 || self==3) && kid)solt=3;
	}
	else if(IncapType[client]== INCAP_POUNCE)
	{
		self=GetConVarInt( l4d_selfhelp_pounce);
		if((self==1 || self==3) && pills!=-1)solt=4;
		else if ((self==2 || self==3) && kid)solt=3;
	}
	else if(IncapType[client]== INCAP_RIDE)
	{
		self=GetConVarInt( l4d_selfhelp_ride);
		if((self==1 || self==3) && pills!=-1)solt=4;
		else if ((self==2 || self==3) && kid)solt=3;
	}
	else if(IncapType[client]== INCAP_PUMMEL)
	{
		self=GetConVarInt( l4d_selfhelp_pummel);
		if((self==1 || self==3) && pills!=-1)solt=4;
		else if ((self==2 || self==3) && kid)solt=3;
	}
	return solt;
}

public Action:PlayerTimer(Handle:timer, any:client)
{
	new Float:time=GetEngineTime();

	if (client==0 )
	{
		HelpOhterState[client]=HelpState[client]=STATE_NONE;
		Timers[client]=INVALID_HANDLE;
		return Plugin_Stop;
	}
	if(!IsClientInGame(client) || !IsPlayerAlive(client)  )
	{
		HelpOhterState[client]=HelpState[client]=STATE_NONE;
		Timers[client]=INVALID_HANDLE;
		return Plugin_Stop;
	}

	if( !IsPlayerIncapped(client) && !IsPlayerGrapEdge(client) && Attacker[client]==0)
	{

		HelpOhterState[client]=HelpState[client]=STATE_NONE;
		Timers[client]=INVALID_HANDLE;
		return Plugin_Stop;
	}

	if(!IsPlayerIncapped(client) && !IsPlayerGrapEdge(client) && Attacker[client]!=0)
	{
		if (!IsClientInGame(Attacker[client]) || !IsPlayerAlive(Attacker[client]))
		{
			HelpOhterState[client]=HelpState[client]=STATE_NONE;
			Timers[client]=INVALID_HANDLE;
			Attacker[client]=0;
			return Plugin_Stop;
		}

	}
	if(HelpState[client]==STATE_OK )
	{
		HelpOhterState[client]=HelpState[client]=STATE_NONE;
		Timers[client]=INVALID_HANDLE;
		return Plugin_Stop;
	}

	new buttons = GetClientButtons(client);

	new haveone=0;
	new PillSlot = GetPlayerWeaponSlot(client, 4);
	new KidSlot=GetPlayerWeaponSlot(client, 3);
	if (PillSlot != -1)
	{
		haveone++;
	}
	if(KidSlot !=-1)
	{
		if(HaveKid(client))haveone++;
	}

	if(haveone>0)
	{
		if((buttons & IN_DUCK) ||  (buttons & IN_USE))
		{
			if(CanSelfHelp(client))
			{
				if(L4D2Version)
				{
					if(HelpState[client]==STATE_NONE)
					{
						HelpStartTime[client]=time;
						SetupProgressBar(client, GetConVarFloat(l4d_selfhelp_durtaion));
						PrintHintText(client, "%t", "Helping Yourself");
					}

				}
				else
				{
					if(HelpState[client]==STATE_NONE) HelpStartTime[client]=time;
					ShowBar(client,"self help ", time-HelpStartTime[client], GetConVarFloat(l4d_selfhelp_durtaion));
				}
				HelpState[client]=STATE_SELFHELP;

				if( time-HelpStartTime[client]>GetConVarFloat(l4d_selfhelp_durtaion))
				{
					if(HelpState[client]!=STATE_OK)
					{
						SelfHelp(client);
						if(L4D2Version)KillProgressBar(client);
					}

				}
			}
			else if(HelpState[client]==STATE_SELFHELP)
			{
				if(L4D2Version)KillProgressBar(client);
				HelpState[client]=STATE_NONE;
			}
		}
		else
		{
			if(HelpState[client]==STATE_SELFHELP)
			{
				if(L4D2Version)
				{
					KillProgressBar(client);
				}
				else
				{
					ShowBar(client, "self help ", 0.0, GetConVarFloat(l4d_selfhelp_durtaion));
				}
				HelpState[client]=STATE_NONE;
			}

		}

	}
	else if(GetConVarInt(l4d_selfhelp_eachother)>0)
	{

		if ((buttons & IN_DUCK) ||  (buttons & IN_USE))
		{

			new Float:dis=50.0;
			new Float:pos[3];
			new Float:targetVector[3];
			GetClientEyePosition(client, pos);
			new bool:findone=false;
			new other=0;
			for (new target = 1; target <= MaxClients; target++)
			{
				if (IsClientInGame(target) && target!=client)
				{
					if (IsPlayerAlive(target))
					{
						if(GetClientTeam(target)==2 && (IsPlayerIncapped(target) || IsPlayerGrapEdge(target)))
						{
							GetClientAbsOrigin(target, targetVector);
							new Float:distance = GetVectorDistance(targetVector, pos);
							if(distance<dis)
							{
								findone=true;
								other=target;
								break;
							}
						}
					}
				}
			}
			if(findone)
			{
				char msg[250];
				Format(msg, sizeof(msg), "%t", "Helping Target", other);
				
				if(HelpOhterState[client]==STATE_NONE)
				{
					if(L4D2Version)
					{
						SetupProgressBar(client, GetConVarFloat(l4d_selfhelp_durtaion));
						PrintHintText(client, msg);
					}
					PrintHintText(other, "%t", "Helping You", other);
					HelpStartTime[client]=time;
				}
				HelpOhterState[client]=STATE_SELFHELP;

				if(!L4D2Version) ShowBar(client, msg, time-HelpStartTime[client], GetConVarFloat(l4d_selfhelp_durtaion));

				if(time-HelpStartTime[client]>GetConVarFloat(l4d_selfhelp_durtaion))
				{
					HelpOther(other, client);
					HelpOhterState[client]=STATE_NONE;
					if(L4D2Version) KillProgressBar(client);
				}

			}
			else
			{
				if(HelpOhterState[client]!=STATE_NONE)
				{
					if(L4D2Version) KillProgressBar(client);
					else ShowBar(client, "help other", 0.0, GetConVarFloat(l4d_selfhelp_durtaion));
				}
				HelpOhterState[client]=STATE_NONE;

			}
		}
		else
		{
			if(HelpOhterState[client]!=STATE_NONE)
			{
				if(L4D2Version) KillProgressBar(client);
				else ShowBar(client, "help other", 0.0, GetConVarFloat(l4d_selfhelp_durtaion));
			}
			HelpOhterState[client]=STATE_NONE;

		}
	}

	if ((buttons & IN_DUCK) && GetConVarInt(l4d_selfhelp_pickup)>0 )
	{
		new bool:pickup=false;
		new Float:dis=100.0;
		new ent = -1;
		if (PillSlot == -1)
		{
			decl Float:targetVector1[3];
			decl Float:targetVector2[3];
			GetClientEyePosition(client, targetVector1);
			ent=-1;
			while ((ent = FindEntityByClassname(ent,  "weapon_pain_pills" )) != -1)
			{
				if (IsValidEntity(ent))
				{
					GetEntPropVector(ent, Prop_Send, "m_vecOrigin", targetVector2);
					if(GetVectorDistance(targetVector1  , targetVector2)<dis)
					{

						CheatCommand(client, "give", "pain_pills", "");
						RemoveEdict(ent);
						pickup=true;
						PrintHintText(client, "%t", "Found Pills");

						break;
					}
				}
			}
			if(!pickup)
			{
				ent = -1;
				while ((ent = FindEntityByClassname(ent,  "weapon_adrenaline" )) != -1)
				{
					if (IsValidEntity(ent))
					{
						GetEntPropVector(ent, Prop_Send, "m_vecOrigin", targetVector2);
						if(GetVectorDistance(targetVector1  , targetVector2)<dis)
						{

							CheatCommand(client, "give", "adrenaline", "");
							RemoveEdict(ent);
							pickup=true;
							PrintHintText(client, "%t", "Found Adrenaline");

							break;
						}
					}
				}

			}
		}
		if (KidSlot == -1 && !pickup)
		{
			decl Float:targetVector1[3];
			decl Float:targetVector2[3];
			GetClientEyePosition(client, targetVector1);
			ent = -1;
			while ((ent = FindEntityByClassname(ent,  "weapon_first_aid_kit" )) != -1)
			{
				if (IsValidEntity(ent))
				{
					GetEntPropVector(ent, Prop_Send, "m_vecOrigin", targetVector2);
					if(GetVectorDistance(targetVector1  , targetVector2)<dis)
					{

						CheatCommand(client, "give", "first_aid_kit", "");
						RemoveEdict(ent);
						pickup=true;
						
						PrintHintText(client, "%t", "Found Medkit");
						break;
					}
				}
			}
		}
		if (GetPlayerWeaponSlot(client, 1)==-1 && !pickup)
		{
			decl Float:targetVector1[3];
			decl Float:targetVector2[3];
			GetClientEyePosition(client, targetVector1);
			ent = -1;
			while ((ent = FindEntityByClassname(ent,  "weapon_pistol" )) != -1)
			{
				if (IsValidEntity(ent))
				{
					GetEntPropVector(ent, Prop_Send, "m_vecOrigin", targetVector2);
					if(GetVectorDistance(targetVector1  , targetVector2)<dis)
					{
						CheatCommand(client, "give", "pistol", "");
						RemoveEdict(ent);
						pickup=true;
						
						PrintHintText(client, "%t", "Found Pistol");
						break;
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

SelfHelp(client)
{

	if (!IsClientInGame(client) || !IsPlayerAlive(client) )
	{
		return;
	}
	if( !IsPlayerIncapped(client) && !IsPlayerGrapEdge(client) && Attacker[client]==0)
	{
		return;
	}
	new bool:pills=HavePills(client);

	new bool:adrenaline=HaveAdrenaline(client);
	new slot=SelfHelpUseSlot(client);
	if(slot!=-1)
	{
		new weaponslot=GetPlayerWeaponSlot(client, slot);
		if(slot ==4)
		{
			if(GetConVarInt(l4d_selfhelp_kill)>0) KillAttack(client);
			RemovePlayerItem(client, weaponslot);

			ReviveClientWithPills(client);


			HelpState[client]=STATE_OK;

			if (adrenaline)
			{
				for (int i = 1; i <= MaxClients; i++)
				{
					if (!IsClientInGame(i))
						continue;

					if (IsFakeClient(i))
						continue;
					
					PrintToChat(i, "%t", "Self Help with Adrenaline", client);
				}
			}
			
			if (pills)
			{
				for (int i = 1; i <= MaxClients; i++)
				{
					if (!IsClientInGame(i))
						continue;

					if (IsFakeClient(i))
						continue;
					
					PrintToChat(i, "%t", "Self Help with Pills", client);
				}
			}
			
			//EmitSoundToClient(client, "player/items/pain_pills/pills_use_1.wav"); // add some sound

		}
		else if(slot==3)
		{
			if(GetConVarInt(l4d_selfhelp_kill)>0) KillAttack(client);
			RemovePlayerItem(client, weaponslot);

			ReviveClientWithKit(client);

			HelpState[client]=STATE_OK;
			
			for (int i = 1; i <= MaxClients; i++)
			{
				if (!IsClientInGame(i))
					continue;

				if (IsFakeClient(i))
					continue;
				
				PrintToChat(i, "%t", "Self Help with Medkit", client);
			}

			//EmitSoundToClient(client, "player/items/pain_pills/pills_use_1.wav"); // add some sound
		}

	}
	else
	{
		PrintHintText(client, "%t", "Self Help Failed");
		HelpState[client]=STATE_FAILED;
	}
}
HelpOther(client, helper)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client) )
		return;

	if( !IsPlayerIncapped(client) && !IsPlayerGrapEdge(client) && Attacker[client]==0)
		return;

	int revivecount = GetEntProp(client, Prop_Send, "m_currentReviveCount");

	new userflags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	new iflags=GetCommandFlags("give");
	SetCommandFlags("give", iflags & ~FCVAR_CHEAT);
	FakeClientCommand(client,"give health");
	SetCommandFlags("give", iflags);
	SetUserFlagBits(client, userflags);

	SetEntProp(client, Prop_Send, "m_currentReviveCount", revivecount + 1);
	if (GetEntProp(client, Prop_Send, "m_currentReviveCount") == GetConVarInt(FindConVar("survivor_max_incapacitated_count")))
	{
		SetEntProp(client, Prop_Send, "m_isGoingToDie", 1);
		if (L4D2Version)
			SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 1);
	}

	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", GetConVarFloat(FindConVar("pain_pills_health_value")));
	SetEntityHealth(client, 1);

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))
			continue;

		if (IsFakeClient(i))
			continue;
		
		PrintToChat(i, "%t", "Self Help Other", helper, client);
	}
}

ReviveClientWithKit(client)
{
	int revivecount = GetEntProp(client, Prop_Send, "m_currentReviveCount");

	new userflags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	new iflags=GetCommandFlags("give");
	SetCommandFlags("give", iflags & ~FCVAR_CHEAT);
	FakeClientCommand(client,"give health");
	SetCommandFlags("give", iflags);
	SetUserFlagBits(client, userflags);

	SetEntProp(client, Prop_Send, "m_currentReviveCount", revivecount + 1);
	if (GetEntProp(client, Prop_Send, "m_currentReviveCount") == GetConVarInt(FindConVar("survivor_max_incapacitated_count")))
	{
		SetEntProp(client, Prop_Send, "m_isGoingToDie", 1);
		SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 1);
	}

	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", GetConVarFloat(FindConVar("first_aid_heal_percent"))*100.0);
	SetEntityHealth(client, 1);
}
ReviveClientWithPills(client)
{
	int revivecount = GetEntProp(client, Prop_Send, "m_currentReviveCount");

	new userflags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	new iflags=GetCommandFlags("give");
	SetCommandFlags("give", iflags & ~FCVAR_CHEAT);
	FakeClientCommand(client,"give health");
	SetCommandFlags("give", iflags);
	SetUserFlagBits(client, userflags);

	SetEntProp(client, Prop_Send, "m_currentReviveCount", revivecount + 1);
	if (GetEntProp(client, Prop_Send, "m_currentReviveCount") == GetConVarInt(FindConVar("survivor_max_incapacitated_count")))
	{
		SetEntProp(client, Prop_Send, "m_isGoingToDie", 1);
		SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 1);
	}

	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", GetConVarFloat(FindConVar("pain_pills_health_value")));
	SetEntityHealth(client, 1);
}

KillAttack(client)
{
	new a=Attacker[client];
	if(GetConVarInt(l4d_selfhelp_kill)==1 && a!=0)
	{
		if(IsClientInGame(a) && GetClientTeam(a)==3 &&  IsPlayerAlive(a))
		{
			ForcePlayerSuicide(a);
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
bool:HaveKid(client)
{
	decl String:weapon[32];
	new KidSlot=GetPlayerWeaponSlot(client, 3);

	if(KidSlot !=-1)
	{
		GetEdictClassname(KidSlot, weapon, 32);
		if(StrEqual(weapon, "weapon_first_aid_kit"))
		{
			return true;
		}
	}
	return false;
}
bool:HavePills(client)
{
	decl String:weapon[32];
	new KidSlot=GetPlayerWeaponSlot(client, 4);

	if(KidSlot !=-1)
	{
		GetEdictClassname(KidSlot, weapon, 32);
		if(StrEqual(weapon, "weapon_pain_pills"))
		{
			return true;
		}
	}
	return false;
}
bool:HaveAdrenaline(client)
{
	decl String:weapon[32];
	new KidSlot=GetPlayerWeaponSlot(client, 4);

	if(KidSlot !=-1)
	{
		GetEdictClassname(KidSlot, weapon, 32);
		if(StrEqual(weapon, "weapon_adrenaline"))
		{
			return true;
		}
	}
	return false;
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


bool:IsPlayerIncapped(client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1)) return true;
	return false;
}
bool:IsPlayerGrapEdge(client)
{
	if (GetEntProp(client, Prop_Send, "m_isHangingFromLedge", 1))return true;
	return false;
}
reset()
{
	for (new x = 0; x <= MaxClients; x++)
	{
			HelpOhterState[x]=HelpState[x]=STATE_NONE;
			Attacker[x]=0;
			HelpStartTime[x]=0.0;
			if(Timers[x]!=INVALID_HANDLE)
			{
				KillTimer(Timers[x]);

			}
			Timers[x]=INVALID_HANDLE;
	}
}
stock SetupProgressBar(client, Float:time)
{
	//KillProgressBar(client);
	//SetEntPropEnt(client, Prop_Send, "m_reviveOwner", -1);
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", time);
	//SetEntPropEnt(client, Prop_Send, "m_reviveOwner", client);
	//SetEntPropEnt(client, Prop_Send, "m_reviveTarget", client);

}

stock KillProgressBar(client)
{
	//SetEntPropEnt(client, Prop_Send, "m_reviveOwner", -1);
	//SetEntityMoveType(client, MOVETYPE_WALK);
	//SetEntPropEnt(client, Prop_Send, "m_reviveTarget", 0);
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", 0.0);
	//SetEntPropEnt(client, Prop_Send, "m_reviveOwner", 0);
}

stock StopSoundPerm(client, String:sound[])
{
	StopSound(client, SNDCHAN_REPLACE, sound);
	StopSound(client, SNDCHAN_AUTO, sound);
	StopSound(client, SNDCHAN_WEAPON, sound);
	StopSound(client, SNDCHAN_VOICE, sound);
	StopSound(client, SNDCHAN_ITEM, sound);
	StopSound(client, SNDCHAN_BODY, sound);
	StopSound(client, SNDCHAN_STREAM, sound);
	StopSound(client, SNDCHAN_STATIC, sound); //Remove heartbeat
	StopSound(client, SNDCHAN_VOICE_BASE, sound);
	StopSound(client, SNDCHAN_USER_BASE, sound);
}

/**
 * Validates if is a valid client.
 *
 * @param client		Client index.
 * @return			  True if client index is valid and client is in game, false otherwise.
 */
bool IsValidClient(int client)
{
	return (1 <= client <= MaxClients && IsClientInGame(client));
}