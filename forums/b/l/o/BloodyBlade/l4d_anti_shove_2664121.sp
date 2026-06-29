#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.1"
#define CVAR_FLAGS FCVAR_NOTIFY
#define ZOMBIECLASS_SMOKER	1
#define ZOMBIECLASS_BOOMER	2
#define ZOMBIECLASS_HUNTER	3
#define ZOMBIECLASS_SPITTER	4
#define ZOMBIECLASS_JOCKEY	5
#define ZOMBIECLASS_CHARGER	6

int ZOMBIECLASS_TANK = 5;
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion engine = GetEngineVersion();
    if (engine == Engine_Left4Dead)
	{
		ZOMBIECLASS_TANK = 5;
	}
	else if (engine == Engine_Left4Dead2)
    {
		ZOMBIECLASS_TANK = 8;
	}
	else
	{
        strcopy(error, err_max, "This plugin only runs in \"Left 4 Dead(2)\" game");
        return APLRes_SilentFailure;
    }
    return APLRes_Success;
}

Handle VisibleTimer[MAXPLAYERS + 1] = {null, ...};
ConVar l4d_antishove_pushback[9], l4d_antishove_invisible[9], l4d_antishove_enable, l4d_antishove_invisible_alpha, l4d_antishove_invisible_time;
ConVar l4d_antishove_modes, l4d_antishove_modes_off, l4d_antishove_modes_tog, MPGameMode;
float fAntiShovePush[9], fAntiShovePushInvisible[9], fAntiShovePushInvTime = 0.0;
int iAntiShoveInvAlpha;
bool bHooked = false, bMapStarted = false;

public Plugin myinfo = 
{
	name = "anti shove",
	author = "Pan Xiaohai(Edit. by BloodyBlade)",
	description = "when you shove special infected you will be pushed back",
	version = PLUGIN_VERSION,	
}

public void OnPluginStart()
{
	CreateConVar("l4d_antishove_version", PLUGIN_VERSION, "[L4D] Anti Shove plugin version.", CVAR_FLAGS|FCVAR_DONTRECORD);
	l4d_antishove_enable = CreateConVar("l4d_antishove_enable", "1", "anti shove 0:disable, 1:eanble ", CVAR_FLAGS);

 	l4d_antishove_pushback[ZOMBIECLASS_HUNTER]  = CreateConVar("l4d_antishove_pushback_hunter", "80.0", "probalility of push back when you shove a hunter[0.0,100.0]", CVAR_FLAGS);
 	l4d_antishove_pushback[ZOMBIECLASS_SMOKER]  = CreateConVar("l4d_antishove_pushback_smoker", "20.0", "", CVAR_FLAGS);
 	l4d_antishove_pushback[ZOMBIECLASS_BOOMER]  = CreateConVar("l4d_antishove_pushback_boomer", "20.0", "", CVAR_FLAGS);
 	l4d_antishove_pushback[ZOMBIECLASS_JOCKEY]  = CreateConVar("l4d_antishove_pushback_jockey", "50.0", "", CVAR_FLAGS);
 	l4d_antishove_pushback[ZOMBIECLASS_SPITTER] = CreateConVar("l4d_antishove_pushback_spitter", "20.0", "", CVAR_FLAGS);	
	l4d_antishove_pushback[ZOMBIECLASS_CHARGER] = CreateConVar("l4d_antishove_pushback_charger", "10.0", "", CVAR_FLAGS);
 	l4d_antishove_pushback[ZOMBIECLASS_TANK] 	= CreateConVar("l4d_antishove_pushback_tank", "20.0", "", CVAR_FLAGS); 
	
	l4d_antishove_invisible[ZOMBIECLASS_HUNTER]  = CreateConVar("l4d_antishove_invisible_hunter", "30.0", "probalility of a hunter become a invisible hunter when you shove him[0.0,100.0]", CVAR_FLAGS);
 	l4d_antishove_invisible[ZOMBIECLASS_SMOKER]  = CreateConVar("l4d_antishove_invisible_smoker", "20.0", "", CVAR_FLAGS);
 	l4d_antishove_invisible[ZOMBIECLASS_BOOMER]  = CreateConVar("l4d_antishove_invisible_boomer", "40.0", "", CVAR_FLAGS);
 	l4d_antishove_invisible[ZOMBIECLASS_JOCKEY]  = CreateConVar("l4d_antishove_invisible_jockey", "20.0", "", CVAR_FLAGS);
 	l4d_antishove_invisible[ZOMBIECLASS_SPITTER] = CreateConVar("l4d_antishove_invisible_spitter", "20.0", "", CVAR_FLAGS);	
	l4d_antishove_invisible[ZOMBIECLASS_CHARGER] = CreateConVar("l4d_antishove_invisible_charger", "20.0", "", CVAR_FLAGS);
 	l4d_antishove_invisible[ZOMBIECLASS_TANK]	= CreateConVar("l4d_antishove_invisible_tank", "10.0", "", CVAR_FLAGS);

 	l4d_antishove_invisible_time = CreateConVar("l4d_antishove_invisible_time", "8", "invisible duration [5, 20]s", CVAR_FLAGS);
	l4d_antishove_invisible_alpha = CreateConVar("l4d_antishove_invisible_alpha", "90", "0,Completely invisible, 255, Completely visible [0, 255]", CVAR_FLAGS);

	l4d_antishove_modes = CreateConVar("l4d_antishove_modes", "", "Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	l4d_antishove_modes_off = CreateConVar("l4d_antishove_modes_off", "", "Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	l4d_antishove_modes_tog = CreateConVar("l4d_antishove_tog", "0", "Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus. Add numbers together.", CVAR_FLAGS );

	l4d_antishove_enable.AddChangeHook(ConVarPluginOnChanged);
	int i;
	for (i = 0; i < 9; i++)
	{
		l4d_antishove_pushback[i].AddChangeHook(ConVarsChanged);
	}

	for (i = 0; i < 9; i++)
	{
	    l4d_antishove_invisible[i].AddChangeHook(ConVarsChanged);
	}

	l4d_antishove_invisible_time.AddChangeHook(ConVarsChanged);
	l4d_antishove_invisible_alpha.AddChangeHook(ConVarsChanged);
	MPGameMode = FindConVar("mp_gamemode");
	MPGameMode.AddChangeHook(ConVarPluginOnChanged);
	l4d_antishove_modes.AddChangeHook(ConVarPluginOnChanged);
	l4d_antishove_modes_off.AddChangeHook(ConVarPluginOnChanged);
	l4d_antishove_modes_tog.AddChangeHook(ConVarPluginOnChanged);

	AutoExecConfig(true, "l4d_anti_shove");
}

public void OnMapStart()
{
	bMapStarted = true;
}

public void OnConfigsExecuted()
{
    IsAllowed();
}

void ConVarPluginOnChanged(ConVar cvar, const char[] OldValue, const char[] NewValue)
{
    IsAllowed();
}

void ConVarsChanged(ConVar cvar, const char[] OldValue, const char[] NewValue)
{
	int i;
	for (i = 0; i < 9; i++)
	{
		fAntiShovePush[i] = l4d_antishove_pushback[i].FloatValue;
	}

	for (i = 0; i < 9; i++)
	{
	    fAntiShovePushInvisible[i] = l4d_antishove_invisible[i].FloatValue;
	}
	fAntiShovePushInvTime = l4d_antishove_invisible_time.FloatValue;
	iAntiShoveInvAlpha = l4d_antishove_invisible_alpha.IntValue;
}

void IsAllowed()
{
	bool bPluginOn = l4d_antishove_enable.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	if(!bHooked && bPluginOn && bAllowMode)
	{
		bHooked = true;
		ConVarsChanged(null, "", "");
		HookEvent("player_shoved", player_shoved); 	
		HookEvent("player_spawn", Event_Player_Spawn);
	}
	else if(bHooked && (!bPluginOn && bAllowMode))
	{
		bHooked = false;
		UnhookEvent("player_shoved", player_shoved); 	
		UnhookEvent("player_spawn", Event_Player_Spawn);
	}
}

int g_iCurrentMode;
bool IsAllowedGameMode()
{
	if( MPGameMode == null )
		return false;

	int iCvarModesTog = l4d_antishove_modes_tog.IntValue;
	if( iCvarModesTog != 0 )
	{
		if(!bMapStarted)
			return false;

		g_iCurrentMode = 0;

		int entity = CreateEntityByName("info_gamemode");
		if( IsValidEntity(entity) )
		{
			DispatchSpawn(entity);
			HookSingleEntityOutput(entity, "OnCoop", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnSurvival", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnVersus", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnScavenge", OnGamemode, true);
			ActivateEntity(entity);
			AcceptEntityInput(entity, "PostSpawnActivate");
			if( IsValidEntity(entity) ) // Because sometimes "PostSpawnActivate" seems to kill the ent.
				RemoveEdict(entity); // Because multiple plugins creating at once, avoid too many duplicate ents in the same frame
		}

		if( g_iCurrentMode == 0 )
			return false;

		if( !(iCvarModesTog & g_iCurrentMode) )
			return false;
	}

	char sGameModes[64], sGameMode[64];
	MPGameMode.GetString(sGameMode, sizeof(sGameMode));
	Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);

	l4d_antishove_modes.GetString(sGameModes, sizeof(sGameModes));
	if( sGameModes[0] )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) == -1 )
			return false;
	}

	l4d_antishove_modes_off.GetString(sGameModes, sizeof(sGameModes));
	if( sGameModes[0] )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) != -1 )
			return false;
	}

	return true;
}

void OnGamemode(const char[] output, int caller, int activator, float delay)
{
	if( strcmp(output, "OnCoop") == 0 )
		g_iCurrentMode = 1;
	else if( strcmp(output, "OnSurvival") == 0 )
		g_iCurrentMode = 2;
	else if( strcmp(output, "OnVersus") == 0 )
		g_iCurrentMode = 4;
	else if( strcmp(output, "OnScavenge") == 0 )
		g_iCurrentMode = 8;
}

public void OnMapEnd()
{
	bMapStarted = false;
}

Action Event_Player_Spawn(Event event, char[] event_name, bool dontBroadcast)
{
	int client  = GetClientOfUserId(event.GetInt("userid"));
  	if(IsValidClient(client) && GetClientTeam(client) == 3)
	{
		VisibleTimer[client] = null;
	}
	return Plugin_Continue;  
}

Action player_shoved(Event event, char[] event_name, bool dontBroadcast)
{
	int victim  = GetClientOfUserId(event.GetInt("userid"));
	int attacker  = GetClientOfUserId(event.GetInt("attacker"));
	int Class = GetEntProp(victim, Prop_Send, "m_zombieClass");
	if(IsValidClient(victim) && GetClientTeam(victim) == 3 && IsValidClient(attacker))
	{
		if(GetRandomFloat(0.0, 100.0) < fAntiShovePush[Class])
		{
			PushBack(victim , attacker);
		}

		if(GetRandomFloat(0.0, 100.0) < fAntiShovePushInvisible[Class])
		{
			
			Invisible(victim , attacker);
		}
	}
  	return Plugin_Continue;
}

void PushBack(int victim, int attacker)
{
    if(IsValidClient(victim) && IsValidClient(attacker))
    {
    	float victimpos[3], attackerpos[3], v[3], ang[3];
    	GetClientAbsOrigin(attacker, attackerpos);
    	GetClientAbsOrigin(victim, victimpos);	
    	SubtractVectors(victimpos, attackerpos, ang);
    	GetVectorAngles(ang, ang); 
    
    	int flag = GetEntityFlags(attacker);  //FL_ONGROUND
    	if(flag & FL_ONGROUND )
    	{
    		ang[0] = GetRandomFloat(2.0, 6.0);
    	}
    	else 
    	{
    		ang[0] = 0.0 - GetRandomFloat(10.0, 15.0);
    	}
    	ang[1] = ang[1] + GetRandomFloat(-65.0, 65.0);//GetRandomFloat(-180.0, 180.0);
    	ang[2] = 0.0;
    	
    	GetAngleVectors(ang, v, NULL_VECTOR,NULL_VECTOR);
    	
    	NormalizeVector(v,v);
    	ScaleVector(v, 0.0 - GetRandomFloat(600.0, 1000.0));
    
    	attackerpos[2] += 20.0;
    	TeleportEntity(attacker, attackerpos, NULL_VECTOR, v);
    }
}

void Invisible(int victim, int attacker)
{
    if(IsValidClient(victim) && IsValidClient(attacker))
    {
    	attacker = attacker * 1;
    	SetEntityRenderMode(victim, view_as<RenderMode>(3)); 
    	SetEntityRenderColor(victim, 255, 255, 255, iAntiShoveInvAlpha);
    
    	if(VisibleTimer[victim] == null)
    	{
    		VisibleTimer[victim] = CreateTimer(fAntiShovePushInvTime, Visible, victim, TIMER_FLAG_NO_MAPCHANGE);
    	}
    }
}

Action Visible(Handle timer, any client)
{
	if (IsValidClient(client))
	{
		SetEntityRenderMode(client, view_as<RenderMode>(3));
		SetEntityRenderColor(client, 255, 255, 255, 255); 
	}
	VisibleTimer[client] = null;
	return Plugin_Stop;
}

bool IsValidClient(int client)
{
    return client > 0 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client);
}
