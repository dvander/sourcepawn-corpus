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

char bossname[9][10] =
{
	"", 
	"smoker", 
	"boomer", 
	"hunter", 
	"spitter", 
	"jockey", 
	"charger", 
	"", 
	"tank"
};

public Plugin myinfo = 
{
	name = "superBoss",
	author = "Pan Xiaohai",
	description = "superBoss",
	version = PLUGIN_VERSION,	
}

GlobalForward g_hForward_OnSuperBossSpawn, g_hForward_OnInvisBossSpawn;

int ZOMBIECLASS_TANK = 5;
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion engine = GetEngineVersion();
	if(engine == Engine_Left4Dead)
	{
	    ZOMBIECLASS_TANK = 5;
	}
	else if(engine == Engine_Left4Dead2)
	{
	    ZOMBIECLASS_TANK = 8;
	}
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}

	g_hForward_OnSuperBossSpawn = new GlobalForward("L4D2_OnSuperBossSpawn", ET_Ignore, Param_Cell);
	g_hForward_OnInvisBossSpawn = new GlobalForward("L4D2_OnInvisBossSpawn", ET_Ignore, Param_Cell);
	CreateNative("SB_IsSuperBoss", Native_IsSuperBoss);
	CreateNative("SB_IsInvisBoss", Native_IsInvisBoss);

	RegPluginLibrary("l4d_superboss_en");

	return APLRes_Success;
}

PluginData plugin;
char hintmsg[165];

enum struct PluginCvars
{
	ConVar l4d_superboss_plugin_enable;
	ConVar l4d_super_probability[9];
	ConVar l4d_invisible_probability[9];
	ConVar l4d_super_HPmultiple[9];
	ConVar l4d_super_movemultiple[9];
	ConVar l4d_super_catchfire[9];
	ConVar l4d_invisible_alpha;
	ConVar l4d_superboss_print;
	ConVar l4d_invisible_print;
	ConVar l4d_superboss_enable;
	ConVar l4d_invisible_enable;

	void Init()
	{
		bossname[ZOMBIECLASS_TANK] = "tank";

		this.l4d_superboss_plugin_enable = CreateConVar("this.l4d_superboss_plugin_enable", "1", "super infected plugin 0:disable, 1:eanble", CVAR_FLAGS);
		this.l4d_superboss_enable = CreateConVar("this.l4d_superboss_enable", "1", "super infected 0:disable, 1:eanble", CVAR_FLAGS);
		this.l4d_invisible_enable = CreateConVar("this.l4d_invisible_enable", "1", "invisible infected 0:disable, 1:eanble", CVAR_FLAGS);

		this.l4d_superboss_print = CreateConVar("this.l4d_superboss_print", "1", "print message when super infected spawn, 0:disable, 1:enable", CVAR_FLAGS);
		this.l4d_invisible_print = CreateConVar("this.l4d_invisible_print", "1", "print message when invisible infected spawn, 0:disable, 1:enable", CVAR_FLAGS);	

		this.l4d_super_probability[ZOMBIECLASS_HUNTER]  = CreateConVar("this.l4d_super_probability_hunter", "8.0", "probalility of a hunter become a super hunter[0.0-100.0]", CVAR_FLAGS);
		this.l4d_super_probability[ZOMBIECLASS_SMOKER]  = CreateConVar("this.l4d_super_probability_smoker", "8.0", "", CVAR_FLAGS);	
		this.l4d_super_probability[ZOMBIECLASS_BOOMER]  = CreateConVar("this.l4d_super_probability_boomer", "8.0", "", CVAR_FLAGS);
		this.l4d_super_probability[ZOMBIECLASS_JOCKEY]  = CreateConVar("this.l4d_super_probability_jockey", "8.0", "", CVAR_FLAGS);
		this.l4d_super_probability[ZOMBIECLASS_SPITTER] = CreateConVar("this.l4d_super_probability_spitter", "8.0", "", CVAR_FLAGS);
		this.l4d_super_probability[ZOMBIECLASS_CHARGER] = CreateConVar("this.l4d_super_probability_charger", "8.0", "", CVAR_FLAGS);
		this.l4d_super_probability[ZOMBIECLASS_TANK] = CreateConVar("this.l4d_super_probability_tank", "5.0", "", CVAR_FLAGS);
	 
		this.l4d_invisible_probability[ZOMBIECLASS_HUNTER]  = CreateConVar("this.l4d_invisible_hunter", "25.0", "probalility of a hunter become a invisible hunter[0.0-100.0]", CVAR_FLAGS);
		this.l4d_invisible_probability[ZOMBIECLASS_SMOKER]  = CreateConVar("this.l4d_invisible_smoker", "30.0", "", CVAR_FLAGS);	
		this.l4d_invisible_probability[ZOMBIECLASS_BOOMER]  = CreateConVar("this.l4d_invisible_boomer", "20.0", "", CVAR_FLAGS);
		this.l4d_invisible_probability[ZOMBIECLASS_JOCKEY]  = CreateConVar("this.l4d_invisible_jockey", "20.0", "", CVAR_FLAGS);
		this.l4d_invisible_probability[ZOMBIECLASS_SPITTER] = CreateConVar("this.l4d_invisible_spitter", "50.0", "", CVAR_FLAGS);
		this.l4d_invisible_probability[ZOMBIECLASS_CHARGER] = CreateConVar("this.l4d_invisible_charger", "20.0", "", CVAR_FLAGS);
		this.l4d_invisible_probability[ZOMBIECLASS_TANK] = CreateConVar("this.l4d_invisible_tank", "4.0", "", CVAR_FLAGS);

		this.l4d_invisible_alpha  =	 CreateConVar("this.l4d_invisible_alpha", "90", "0, Completely invisible, 255, Completely visible [0, 255]", CVAR_FLAGS);

		this.l4d_super_HPmultiple[ZOMBIECLASS_HUNTER]  =  CreateConVar("this.l4d_super_HPmultiple_hunter", "5.0", "health multiple of super hunter [0.5-20.0]", CVAR_FLAGS);
		this.l4d_super_HPmultiple[ZOMBIECLASS_SMOKER]  =  CreateConVar("this.l4d_super_HPmultiple_smoker", "5.0", "", CVAR_FLAGS);
		this.l4d_super_HPmultiple[ZOMBIECLASS_BOOMER]  =  CreateConVar("this.l4d_super_HPmultiple_boomer", "5.0", "", CVAR_FLAGS);
		this.l4d_super_HPmultiple[ZOMBIECLASS_JOCKEY]  =  CreateConVar("this.l4d_super_HPmultiple_jockey", "5.0", "", CVAR_FLAGS);
		this.l4d_super_HPmultiple[ZOMBIECLASS_SPITTER]  = CreateConVar("this.l4d_super_HPmultiple_spitter", "5.0", "", CVAR_FLAGS);	
		this.l4d_super_HPmultiple[ZOMBIECLASS_CHARGER]  = CreateConVar("this.l4d_super_HPmultiple_charger", "5.0", "", CVAR_FLAGS);
		this.l4d_super_HPmultiple[ZOMBIECLASS_TANK]  = CreateConVar("this.l4d_super_HPmultiple_tank", "1.3", "", CVAR_FLAGS);

		this.l4d_super_movemultiple[ZOMBIECLASS_HUNTER]  =  CreateConVar("this.l4d_super_movemultiple_hunter", "1.3", "movement multiple of super hunter [0.5-2.0]", CVAR_FLAGS);
		this.l4d_super_movemultiple[ZOMBIECLASS_SMOKER]  =  CreateConVar("this.l4d_super_movemultiple_smoker", "1.3", "", CVAR_FLAGS);	
		this.l4d_super_movemultiple[ZOMBIECLASS_BOOMER]  =  CreateConVar("this.l4d_super_movemultiple_boomer", "1.2", "", CVAR_FLAGS);
		this.l4d_super_movemultiple[ZOMBIECLASS_JOCKEY]  =  CreateConVar("this.l4d_super_movemultiple_jockey", "1.3", "", CVAR_FLAGS);
		this.l4d_super_movemultiple[ZOMBIECLASS_SPITTER]  = CreateConVar("this.l4d_super_movemultiple_spitter", "1.3", "", CVAR_FLAGS);	
		this.l4d_super_movemultiple[ZOMBIECLASS_CHARGER]  = CreateConVar("this.l4d_super_movemultiple_charger", "1.3", "", CVAR_FLAGS);
		this.l4d_super_movemultiple[ZOMBIECLASS_TANK]  = CreateConVar("this.l4d_super_movemultiple_tank", "1.05", "", CVAR_FLAGS); 

		this.l4d_super_catchfire[ZOMBIECLASS_HUNTER]  =  CreateConVar("this.l4d_super_catchfire_hunter", "10.0", "probalility of catch fire when super hunter spawn [0.00-100.0]", CVAR_FLAGS);
		this.l4d_super_catchfire[ZOMBIECLASS_SMOKER]  =  CreateConVar("this.l4d_super_catchfire_smoker", "10.0", "", CVAR_FLAGS);
		this.l4d_super_catchfire[ZOMBIECLASS_BOOMER]  =  CreateConVar("this.l4d_super_catchfire_boomer", "10.0", "", CVAR_FLAGS);
		this.l4d_super_catchfire[ZOMBIECLASS_JOCKEY]  =  CreateConVar("this.l4d_super_catchfire_jockey", "10.0", "", CVAR_FLAGS);
		this.l4d_super_catchfire[ZOMBIECLASS_SPITTER]  = CreateConVar("this.l4d_super_catchfire_spitter", "10.0", "", CVAR_FLAGS);	
		this.l4d_super_catchfire[ZOMBIECLASS_CHARGER]  = CreateConVar("this.l4d_super_catchfire_charger", "10.0", "", CVAR_FLAGS);
		this.l4d_super_catchfire[ZOMBIECLASS_TANK] =  CreateConVar("this.l4d_super_catchfire_tank", "0.0", "", CVAR_FLAGS);

		AutoExecConfig(true, "l4d_superboss_en");

		this.l4d_superboss_plugin_enable.AddChangeHook(OnConVarPluginOnChange);
		this.l4d_superboss_enable.AddChangeHook(OnConVarChange);
		this.l4d_invisible_enable.AddChangeHook(OnConVarChange);
		this.l4d_superboss_print.AddChangeHook(OnConVarChange);
		this.l4d_invisible_print.AddChangeHook(OnConVarChange);
		this.l4d_invisible_alpha.AddChangeHook(OnConVarChange);
	}
}

enum struct PluginData
{
    PluginCvars cvars;
    
    bool bHooked;
    bool bPluginOn;
    bool bSuperBossOn;
    bool bInvisBossOn;
    bool bSuperBossPrint;
    bool bInvisBossPrint;
    int iInvisibleAlpha;
	bool bSuperBoss[MAXPLAYERS + 1];
	bool bInvisBoss[MAXPLAYERS + 1];
	int iClass;
	float hp;
	float fire;
	float move;
	float sp;
	float sI;
	float random;
    
    void Init()
    {
    	this.cvars.Init();
    }
    
    void GetCvarValues()
    {
        this.bSuperBossOn = this.cvars.l4d_superboss_enable.BoolValue;
    	this.bInvisBossOn = this.cvars.l4d_invisible_enable.BoolValue;
    	this.bSuperBossPrint = this.cvars.l4d_superboss_print.BoolValue;
    	this.bInvisBossPrint = this.cvars.l4d_invisible_print.BoolValue;
    	this.iInvisibleAlpha = this.cvars.l4d_invisible_alpha.IntValue;
    }
    
    void IsAllowed()
    {
    	this.bPluginOn = this.cvars.l4d_superboss_plugin_enable.BoolValue;
    	if(!this.bHooked && this.bPluginOn)
    	{
    		this.bHooked = true;
    		HookEvent("player_spawn", Event_Player_Spawn);
    		HookEvent("player_death", Event_Player_Death);
    		HookEvent("player_hurt", Event_Player_Hurt);
    		HookEvent("player_disconnect", Event_Player_Disconnect, EventHookMode_Pre);
    	}
    	else if(this.bHooked && !this.bPluginOn)
    	{
    		this.bHooked = false;
    		UnhookEvent("player_spawn", Event_Player_Spawn);
    		UnhookEvent("player_death", Event_Player_Death);
    		UnhookEvent("player_hurt", Event_Player_Hurt);
    		UnhookEvent("player_disconnect", Event_Player_Disconnect, EventHookMode_Pre);
    	}
    }
}

public void OnPluginStart()
{	
	plugin.Init();
}

public void OnConfigsExecuted()
{
	plugin.IsAllowed();
	plugin.GetCvarValues();
}

void OnConVarPluginOnChange(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	plugin.IsAllowed();
}

void OnConVarChange(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	plugin.GetCvarValues();
}

Action Event_Player_Spawn(Event event, const char[] event_name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if(IsValidAliveInf(client))
    {
    	if(plugin.bSuperBossOn || plugin.bInvisBossOn)
    	{
    		plugin.iClass = GetEntProp(client, Prop_Send, "m_zombieClass");
    		plugin.sp = plugin.cvars.l4d_super_probability[plugin.iClass].FloatValue;
    		plugin.sI = plugin.cvars.l4d_invisible_probability[plugin.iClass].FloatValue;
    		plugin.random = GetRandomFloat(0.0, 100.0);

    		if(plugin.bSuperBossOn)
    		{
    			if(plugin.random < plugin.sp)
    			{
    				CreateTimer(5.0, CreatesuperBoss, client);
    			}
    		}
    
    		if(plugin.bInvisBossOn)
    		{
    			if(plugin.random < plugin.sI)
    			{
    				CreateTimer(7.0, CreateInvisibleBoss, client);
    			}
    		}
    	}
    }
    return Plugin_Continue;
}

Action Event_Player_Hurt(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	if(IsValidInf(victim) && view_as<int>(GetEntProp(victim, Prop_Send, "m_zombieClass")) != 8)
	{
		if(plugin.bSuperBoss[victim])
		{
			if(GetEntityFlags(victim) & FL_ONFIRE) ExtinguishEntity(victim);
			Format(hintmsg, sizeof(hintmsg), "Super %s\nHealth: %d", bossname[plugin.iClass], view_as<int>(GetEntProp(victim, Prop_Send, "m_iHealth")));	
			PrintHintTextToAll("%s ", hintmsg);
		}
	}
	return Plugin_Continue;
}

Action Event_Player_Death(Event event, const char[] event_name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if(IsValidInf(client))
    {
        if(plugin.bSuperBoss[client])
        {
    		plugin.iClass = view_as<int>(GetEntProp(client, Prop_Send, "m_zombieClass"));
    		if (plugin.iClass != 8)
    		{
    			Format(hintmsg, sizeof(hintmsg), "Super %s is dead", bossname[plugin.iClass]);	
    			PrintHintTextToAll("%s ", hintmsg);
    		}
    		plugin.bSuperBoss[client] = false;
        }
        if(plugin.bInvisBoss[client]) plugin.bInvisBoss[client] = false;
    }
    return Plugin_Continue;
}

Action Event_Player_Disconnect(Event event, const char[] event_name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if(client > 0 && IsClientConnected(client))
    {
	    if(plugin.bSuperBoss[client]) plugin.bSuperBoss[client] = false;
	    if(plugin.bInvisBoss[client]) plugin.bInvisBoss[client] = false;
    }
    return Plugin_Continue;
}

Action CreatesuperBoss(Handle timer, any client)
{
	if (IsValidAliveInf(client))
	{
		plugin.bSuperBoss[client] = true;
		plugin.iClass = GetEntProp(client, Prop_Send, "m_zombieClass");
		plugin.hp = plugin.cvars.l4d_super_HPmultiple[plugin.iClass].FloatValue;
		plugin.move = plugin.cvars.l4d_super_movemultiple[plugin.iClass].FloatValue;
		plugin.fire = plugin.cvars.l4d_super_catchfire[plugin.iClass].FloatValue;
		if(plugin.hp > 0.0)
		{
			int HP = RoundFloat((GetEntProp(client, Prop_Send, "m_iHealth") * plugin.hp));
			if (HP > 65535) HP = 65535;
			SetEntProp(client, Prop_Send, "m_iMaxHealth", HP);
			SetEntProp(client, Prop_Send, "m_iHealth", HP);
		}

		if(plugin.move > 0.0) SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue",  plugin.move);
		if(GetRandomFloat(0.0, 100.0) < plugin.fire) IgniteEntity(client, 360.0, false);

		SetEntityRenderMode(client, view_as<RenderMode>(3));
		int c1 = GetRandomInt(0, 255), c2 = GetRandomInt(0, 255), c3 = GetRandomInt(0, 255);
		SetEntityRenderColor(client, c1, c2, c3, 255);

		Call_StartForward(g_hForward_OnSuperBossSpawn);
		Call_PushCell(client);
		Call_Finish();

		if(plugin.bSuperBossPrint)
		{
			Format(hintmsg, sizeof(hintmsg), "\x03super\x04 %s \x03spawn", bossname[plugin.iClass]);	
			PrintToChatAll("%s ", hintmsg);
		}
	}
	return Plugin_Stop;
}

Action CreateInvisibleBoss(Handle timer, any client)
{
	if (IsValidAliveInf(client))
	{
		plugin.bInvisBoss[client] = true;
		plugin.iClass = GetEntProp(client, Prop_Send, "m_zombieClass");   
		SetEntityRenderMode(client, view_as<RenderMode>(3)); 
		SetEntityRenderColor(client, 255, 255, 255, plugin.iInvisibleAlpha);

		Call_StartForward(g_hForward_OnInvisBossSpawn);
		Call_PushCell(client);
		Call_Finish();
		
		if(plugin.bInvisBossPrint)
		{
			Format(hintmsg, sizeof(hintmsg), "\x03invisible\x04 %s \x03spawn", bossname[plugin.iClass]);
			PrintToChatAll("%s ", hintmsg);
		}
	}
	return Plugin_Stop;
}

bool IsValidInf(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3 && IsPlayerAlive(client);
}

bool IsValidAliveInf(int client)
{
	return IsValidInf(client) && IsPlayerAlive(client);
}

public any Native_IsSuperBoss(Handle Plugin, int numParams)
{
	int iClient = GetNativeCell(1);
	return iClient > 0 && plugin.bSuperBoss[iClient];
}

public any Native_IsInvisBoss(Handle Plugin, int numParams)
{
	int iClient = GetNativeCell(1);
	return iClient > 0 && plugin.bInvisBoss[iClient];
}
