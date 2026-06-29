#include <sourcemod>
//#include <sdktools>
#include <cstrike>

#define PLUGIN_VERSION "0.4"
#define PLUGIN_AUTHOR "M3fN"

//TODO: Remove timers and go more correct way.
#define DELAYED_RECALCULATION_TIME 0.4
#define FCVAR_DEFAULT FCVAR_NOTIFY

//TODO:
//Detect restart of game, got temporary (or not?) solution by detecting mp_restartgame + CS_OnTerminateRound (When both teams have palyers)
//Expecting that every death by default brings +1, but we cannot sure the influence of other plugins.
//Are GetConVar* slow?
//Optimize memory by making limit for score at 65535. I have an ability to reduce memory consumption twice.

/*
	Changelog:
	
	0.3: 
		Had incorrect frag count on suicide, fixed, can be turned on/off - sm_fragfordamage_blocksuicidepenalty
		Had incorrect frag count when goal done before next hit, fixed, can be turned on/off - sm_fragfordamage_blockgoals
		sm_fragfordamage_kill_bonus
		sm_fragfordamage_kevlar
		Bugfix: Score was not reset if restart is caused by that teams become to have both players.
	0.4:
		Few little fixes.
		sm_fragfordamage_max_per_victim
*/

/*
 * DATA
 */

new Handle:sm_fragfordamage_enabled = INVALID_HANDLE;
new Handle:sm_fragfordamage_healthdivisor = INVALID_HANDLE;
new Handle:sm_fragfordamage_max_per_hit = INVALID_HANDLE;
new Handle:sm_fragfordamage_kevlar = INVALID_HANDLE;
new Handle:sm_fragfordamage_kill_bonus = INVALID_HANDLE;
new Handle:sm_fragfordamage_blockpenalty = INVALID_HANDLE;
new Handle:sm_fragfordamage_blockgoals = INVALID_HANDLE;
new Handle:sm_fragfordamage_max_per_victim = INVALID_HANDLE;

new g_iTotalDamage[MAXPLAYERS + 1];
new g_iFragOffset[MAXPLAYERS + 1];
new g_iRoundDamageDone[MAXPLAYERS + 1][MAXPLAYERS + 1];

new bool:g_bEnabled;

public Plugin:myinfo =
{
	name = "Frag for damage",
	author = PLUGIN_AUTHOR,
	description = "Gives frag for given dagame, disabling giving frag for kills",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};
 
 /* 
  * EVENTS
  */
  
public OnPluginStart()
{
	CreateConVar("sm_fragfordamage_version", PLUGIN_VERSION, "Frag For Damage Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	sm_fragfordamage_enabled = CreateConVar("sm_fragfordamage_enabled","1","Determines the influence of plugin to frags of players",FCVAR_DEFAULT);
	sm_fragfordamage_kevlar = CreateConVar("sm_fragfordamage_kevlar","0","Determines do include kevlar damage to the score",FCVAR_DEFAULT);
	sm_fragfordamage_healthdivisor = CreateConVar("sm_fragfordamage_healthdivisor","120","Points needed for one frag",FCVAR_DEFAULT,true,1.0);
	sm_fragfordamage_max_per_hit = CreateConVar("sm_fragfordamage_max_per_hit","125","Maximum points(health+armor) to be coinsided from one hit",FCVAR_DEFAULT,true,0.0);
	sm_fragfordamage_max_per_victim = CreateConVar("sm_fragfordamage_max_per_victim","125","Maximum points(health+armor) to be coinsided from one victim before it is dead",FCVAR_DEFAULT,true,0.0);
	sm_fragfordamage_kill_bonus = CreateConVar("sm_fragfordamage_kill_bonus","20","Bonus points that are added if you have killed somebody",FCVAR_DEFAULT,true,0.0);
	sm_fragfordamage_blockpenalty = CreateConVar("sm_fragfordamage_blockpenalty","0","Do block default -1 frag on suicide or teamkill",FCVAR_DEFAULT);
	sm_fragfordamage_blockgoals = CreateConVar("sm_fragfordamage_blockgoals","0","Do block changing frags for goals of addon (like bomb explosion)",FCVAR_DEFAULT);
	
	HookConVarChange(FindConVar("mp_restartgame"),ConVar_Restart);
	
	AutoExecConfig(true, "plugin_fragfordamage");
	
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_hurt", Event_PlayerHurt);
	//HookEvent("cs_win_panel_round", Event_RoundEnd); //Does not work
	
	//Events that changing frag count
	HookEvent("bomb_defused", Event_Goal);
	HookEvent("bomb_exploded", Event_Goal);
	
	HookEvent("round_start", Event_RoundStart);
}

public OnConfigsExecuted()
{
	HookConVarChange(sm_fragfordamage_enabled, ConVar_EnabledChanged);
	HookConVarChange(sm_fragfordamage_healthdivisor, ConVar_HealthDivChanged);
	
	g_bEnabled = GetConVarBool(sm_fragfordamage_enabled);
}

public OnClientConnected(client)
{
	ClearClient(client);
}

public Event_Goal(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_bEnabled)
		return;
		
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(IsValidClient(client))
	{
		new bool:blockGoal = GetConVarBool(sm_fragfordamage_blockgoals);
	
		if(!blockGoal)
		{
			RecalculateFragOffset(client);
		}
		else
		{
			DelayedRecalculateFrags(client);
		}
	}
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_bEnabled)
		return;
		
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	SomebodyDied(attacker,victim);
}

public Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_bEnabled)
		return;
	
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	new dmg_health = GetEventInt(event, "dmg_health");
	new dmg_armor = GetEventInt(event, "dmg_armor");
	 
	SomebodyWasHurt(attacker,victim,dmg_health,dmg_armor);
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	ClearAllDD();
}

public Action:CS_OnTerminateRound(&Float:delay, &CSRoundEndReason:reason) //Have players in both teams
{
	if(!g_bEnabled)
		return;
		
	if(reason == CSRoundEnd_GameStart)
	{
		ClearClients();
	}
}

/*public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{ 
	if(!g_bEnabled)
		return;
		
	new CSRoundEndReason:reason = CSRoundEndReason:GetEventInt(event, "final_event");
	
	if(reason == CSRoundEnd_GameStart)
	{
		ClearClients();
	}
}*/

public ConVar_Restart(Handle:cvar, const String:oldVal[], const String:newVal[]) //mp_restartgame
{ 
	if(!g_bEnabled)
		return;
	
	ClearClients();
}

public ConVar_EnabledChanged(Handle:cvar, const String:oldVal[], const String:newVal[]) 
{ 
	if(oldVal[0] == '0' && newVal[0] != '0')
	{
		g_bEnabled = true;
		PluginEnabled();
	}
	else if(oldVal[0] != '0' && newVal[0] == '0')
	{
		g_bEnabled = false;
		PluginDisabled();
	}
}

public ConVar_HealthDivChanged(Handle:cvar, const String:oldVal[], const String:newVal[]) 
{
	if(!g_bEnabled)
		return;
	
	new oldHealth = StringToInt(oldVal);
	new newHealth = StringToInt(newVal);
	
	DivisorChanged(oldHealth,newHealth);
}

 /* 
  * FUNCTIONALITY
  */

PluginEnabled()
{
	new healthDivisor = GetConVarInt(sm_fragfordamage_healthdivisor);
	new bool:clientConnected;
	new clients = GetMaxClients();
	
	for(new i=1;i<=clients;i++)
	{
		clientConnected = IsClientConnected(i);
		
		if(clientConnected)
		{
			g_iTotalDamage[i] = GetClientFrags(i) * healthDivisor;
		}
	}
}

PluginDisabled()
{
	ClearAllDD();
}

DivisorChanged(oldHealth,newHealth)
{
	if(oldHealth != newHealth)
	{
		new Float:relation = float(newHealth) / float(oldHealth);
		new bool:clientConnected;
	
		for(new i=1;i<=MaxClients ;i++)
		{
			clientConnected = IsClientConnected(i);
			
			if(clientConnected)
			{
				g_iTotalDamage[i] = RoundToFloor(float(g_iTotalDamage[i]) * relation);
			}
		}
	}
}

//TODO: here can be a bug when blockPenalty is on - undefined behaviour when you have killed someone of your team and then someone of oponents in less then DELAYED_RECALCULATION_TIME.
SomebodyDied(attacker,victim)
{
	if(IsNormalHurt(attacker,victim))
	{
		new deathBonus = GetConVarInt(sm_fragfordamage_kill_bonus);
		
		if(deathBonus > 0)
		{
			g_iTotalDamage[attacker] += deathBonus;
		}
		
		RecalculateFrags(attacker, true);
	}
	else if(IsValidClient(attacker))
	{
		new bool:blockPenalty = GetConVarBool(sm_fragfordamage_blockpenalty);
	
		if(!blockPenalty)
		{
			RecalculateFragOffset(attacker);
		}
		else
		{
			DelayedRecalculateFrags(attacker);
		}
	}
	
	if(IsValidClient(victim))
	{
		ClearDD(victim);
	}
}

SomebodyWasHurt(attacker,victim,health,armor)
{
	if(IsNormalHurt(attacker,victim))
	{
		new maxOfHit = GetConVarInt(sm_fragfordamage_max_per_hit);
		new maxOfVictim = GetConVarInt(sm_fragfordamage_max_per_victim);
		new bool:addArmor = GetConVarBool(sm_fragfordamage_kevlar);
		new victimDone = GetDD(attacker,victim);
		new val = health;
		
		if(addArmor)
			val += armor;
		
		if(val > maxOfHit)
			val = maxOfHit;
		
		if(victimDone + val < maxOfVictim)
		{
			SetDD(attacker,victim,victimDone+val);
		}
		else
		{
			if(victimDone >= maxOfVictim)
				val = 0;
			else //victimDone + val >= maxOfVictim
			{
				val = maxOfVictim - victimDone;
				
				SetDD(attacker,victim,maxOfVictim);
			}
		}
		
		g_iTotalDamage[attacker] += val;
		
		RecalculateFrags(attacker);
	}
}

ClearClients()
{
	new clientConnected;
	
	for(new i=1;i<=MaxClients ;i++)
	{
		clientConnected = IsClientConnected(i);
		
		if(clientConnected)
		{
			ClearClient(i);
		}
	}
}

ClearClient(client)
{
	g_iTotalDamage[client] = 0;
	g_iFragOffset[client] = 0;
	
	ClearDD(client);
	
	//RecalculateFrags(client);
}

ClearAllDD()
{
	for(new i=1;i<=MaxClients ;i++)
	for(new p=i;p<=MaxClients ;p++)
	{
		SetDD(i,p,0);
		SetDD(p,i,0);
	}
}

ClearDD(client)
{
	for(new i=1;i<=MaxClients ;i++)
	{
		SetDD(client,i,0);
		SetDD(i,client,0);
	}
}

SetDD(attacker,victim,count)
{
	g_iRoundDamageDone[attacker][victim] = count;
}

GetDD(attacker,victim)
{
	return g_iRoundDamageDone[attacker][victim];
}

RecalculateFragOffset(client)
{
	CreateTimer(DELAYED_RECALCULATION_TIME,RecalculateFragOffsetTF,client);
}

public Action:RecalculateFragOffsetTF(Handle:timer, any:client)
{
	DoRecalculateFragOffset(client);
}

DoRecalculateFragOffset(client)
{
	new newFragCount = GetClientFrags(client);
	new stdFragCount = GetStdFrags(client);
	
	g_iFragOffset[client] = newFragCount - stdFragCount;
}

DelayedRecalculateFrags(client)
{
	CreateTimer(DELAYED_RECALCULATION_TIME,RecalculateFragsTF,client);
}

public Action:RecalculateFragsTF(Handle:timer, any:client)
{
	RecalculateFrags(client);
}

RecalculateFrags(client, bool:afterdeath = false)
{
	new newFragCount = GetStdFrags(client) + g_iFragOffset[client];
	
	if(afterdeath)
		newFragCount--;
	
	SetClientFrags(client,newFragCount);
}

GetStdFrags(client)
{
	new healthDivisor = GetConVarInt(sm_fragfordamage_healthdivisor);
	
	return RoundToFloor( float(g_iTotalDamage[client]) / float(healthDivisor) );
}

SetClientFrags(client,count)
{
	SetEntProp(client, Prop_Data, "m_iFrags", count);
}

IsNormalHurt(attacker, victim)
{
    return victim != 0 && attacker != 0 && victim != attacker && GetClientTeam(victim) != GetClientTeam(attacker);
}

stock RecalculateFragsForAll()
{
	new clientConnected;
	new clients = GetMaxClients();
	
	for(new i=1;i<=clients;i++)
	{
		clientConnected = IsClientConnected(i);
		
		if(clientConnected)
		{
			RecalculateFrags(i);
		}
	}
}

stock bool:IsValidClient(client)
{ 
    if (client <= 0 || client > MaxClients || !IsClientConnected(client))
    {
        return false; 
    }
    return IsClientInGame(client); 
}  