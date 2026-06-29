//#define DEBUG

#define PLUGIN_NAME           "[L4D/L4D2] Balancer HP Special Infected"
#define PLUGIN_AUTHOR         "z☣"
#define PLUGIN_DESCRIPTION    "Balances the HP of the Special Infecteds, depending on the number of Survivor players in game"
#define PLUGIN_VERSION        "1.0"
#define PLUGIN_URL            ""

#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define IS_VALID_CLIENT(%1) (%1 > 0 && %1 <= MaxClients)
#define IS_CONNECTED_INGAME(%1) (IsClientConnected(%1) && IsClientInGame(%1))
#define IS_SPECTATOR(%1) (GetClientTeam(%1) == 1)
#define IS_SURVIVOR(%1) (GetClientTeam(%1) == 2)
#define IS_INFECTED(%1) (GetClientTeam(%1) == 3)

#define IS_VALID_PLAYER(%1) (IS_VALID_CLIENT(%1) && IS_CONNECTED_INGAME(%1))
#define IS_VALID_BOT(%1) (IS_VALID_INGAME(%1) && IsFakeClient(%1))

#define IS_VALID_SPECTATOR(%1) (IS_VALID_PLAYER(%1) && IS_SPECTATOR(%1))
#define IS_VALID_SURVIVOR(%1) (IS_VALID_PLAYER(%1) && IS_SURVIVOR(%1))
#define IS_VALID_INFECTED(%1) (IS_VALID_PLAYER(%1) && IS_INFECTED(%1))

#define IS_SURVIVOR_ALIVE(%1) (IS_VALID_SURVIVOR(%1) && IsPlayerAlive(%1))
#define IS_INFECTED_ALIVE(%1) (IS_VALID_INFECTED(%1) && IsPlayerAlive(%1))

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

ConVar cvar_enable;
ConVar cvar_players_base;
ConVar cvar_check_mode;

ConVar cvar_hp_base[9];
ConVar cvar_hp_min[9];
ConVar cvar_hp_max[9];
ConVar cvar_hp_factor[9];

ConVar cvar_tank_hp;
ConVar cvar_si_health[9];

//ArrayList convar_hp;

bool IsEnable;
int CheckMode;
int PlayersBase;

char si_name[9][32]=
{
	"",
	"smoker",
	"boomer",
	"hunter",
	"spitter",
	"jockey",
	"charger",
	"witch",
	"tank"
};

/*
 z_hunter_health 
 z_gas_health		//smoker
 z_exploding_health // boomer
 z_charger_health
 z_spitter_health
 z_jockey_health
 z_witch_health
 z_tank_health
 */

public void OnPluginStart()
{
	cvar_enable = CreateConVar("balancer_hp_enable", "1","0: Enable, 1:Disable", FCVAR_NONE, true, 0.0, true, 1.0 );
	cvar_players_base = CreateConVar("balancer_hp_players_base", "4", "Set survivor players default to set hp base", FCVAR_NONE, true, 0.0);
	cvar_check_mode	 = CreateConVar("balancer_hp_check_mode","0","0: Check all players survivor in game, 1: Ignore check idle survivors, 2: Ignore check survivors bot, 4: Ignore check dead survivors, 7: Set all ignore check modes", FCVAR_NONE, true, 0.0, true, 7.0);

	char strCvarName[64],strCvarDesc[256];
	for(int i=1; i < sizeof(si_name); i++){
		
		Format(strCvarName, sizeof strCvarName, "balancer_hp_base_%s", si_name[i]);
		Format(strCvarDesc, sizeof strCvarDesc, " 0: Set Default value for cvar(z_health_%s), Value > 0 : Set Custom HP Base", si_name[i]);
		cvar_hp_base[i] = CreateConVar(strCvarName, "0", strCvarDesc, FCVAR_NONE, true, 0.0 );
		
		Format(strCvarName, sizeof strCvarName, "balancer_hp_min_%s", si_name[i]);
		Format(strCvarDesc, sizeof strCvarDesc, " 0: Disable %s decrement HP(min HP = HP base) , (Value > 0): Set decrement limit HP", si_name[i]);
		cvar_hp_min[i] = CreateConVar(strCvarName, "0", strCvarDesc, FCVAR_NONE, true, 0.0 );

		Format(strCvarName, sizeof strCvarName, "balancer_hp_max_%s", si_name[i]);
		Format(strCvarDesc, sizeof strCvarDesc, " 0: Disable %s limit max HP, (Value > 0): Set increment limit HP", si_name[i]);
		cvar_hp_max[i] = CreateConVar(strCvarName, "0", strCvarDesc, FCVAR_NONE, true, 0.0 );

		Format(strCvarName, sizeof strCvarName, "balancer_hp_factor_%s", si_name[i]);
		Format(strCvarDesc, sizeof strCvarDesc, " 0: Disable %s increment/decrement balance HP, (Value < 1): Set factor percent of HP base [example:0.1 = 1%] to increment/decrement per players), (Value >= 1): Set HP value to increment/decrement per players", si_name[i]);
		cvar_hp_factor[i] = CreateConVar(strCvarName, "0.1", strCvarDesc, FCVAR_NONE, true, 0.0 );
	}
	
	AutoExecConfig(true, "balancer_hp");
	cvar_enable.AddChangeHook(CvarsChanged); 
	cvar_players_base.AddChangeHook(CvarsChanged);
	cvar_check_mode.AddChangeHook(CvarsChanged); 

	HookConVarChange(CreateConVar("z_boomer_health","50", "Boomer health"), CvarChanged_BoomerHealth);
	HookConVarChange(CreateConVar("z_smoker_health","250","Smoker health"), CvarChanged_SmokerHealth);
	
	cvar_tank_hp = FindConVar("z_tank_health");
	
	for(int i=1; i < sizeof(cvar_si_health); i++){
		char cvar_name[32];
		Format(cvar_name, sizeof(cvar_name), "z_%s_health", si_name[i]);
		cvar_si_health[i] = FindConVar(cvar_name);
	}
	GetConvars();
	//HookEvent("tank_spawn", Event_TankSpawn);
}

public void CvarsChanged(ConVar convar, const char[] oldValue, const char[] newValue){
	GetConvars();
}

void GetConvars(){
	
	if(!IsEnable && cvar_enable.BoolValue)
		HookEvent("tank_spawn", Event_TankSpawn);
	else if(IsEnable && !cvar_enable.BoolValue)
		UnhookEvent("tank_spawn", Event_TankSpawn);
	
	IsEnable	     = cvar_enable.BoolValue;
	PlayersBase		= cvar_players_base.IntValue;
	CheckMode	     = cvar_check_mode.IntValue;
}

public void CvarChanged_BoomerHealth(ConVar convar, const char[] oldValue, const char[] newValue)
{
	SetConVarString(FindConVar("z_exploding_health"), newValue);
}

public void CvarChanged_SmokerHealth(ConVar convar, const char[] oldValue, const char[] newValue)
{
	SetConVarString(FindConVar("z_gas_health"), newValue);
}
//fix tank hp increment difficulty
public Event_TankSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if(!IsEnable)
		return;
		
	int client = event.GetInt("tankid");
	if(IsTank(client)){
		SetPlayerHealth(client, cvar_tank_hp.IntValue);
		//PrintToChatAll("set tank hp: %d", cvar_tank_hp.IntValue);
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(!IsEnable)
		return;
	
	for(int i=1; i < sizeof(cvar_si_health); i++){
		if(StrEqual(classname, si_name[i], false)){
			int hp =  GetHPIncrement(i);
			SetConVarInt(cvar_si_health[i], hp);
			//PrintToChatAll("set %s hp: %d ",classname, hp);
			break;
		}	
	}
}

int GetHPIncrement(int iclass){
	int hp_min = cvar_hp_min[iclass].IntValue;
	int hp_max = cvar_hp_max[iclass].IntValue;
	char hpdefault[32];
	cvar_si_health[iclass].GetDefault(hpdefault, sizeof hpdefault);
	int hp_base = (cvar_hp_base[iclass].IntValue > 0) ? cvar_hp_base[iclass].IntValue : StringToInt(hpdefault);
	int survivors = GetSurvivorsCount();
	float hp_factor = ( cvar_hp_factor[iclass].FloatValue < 1 ) ? float(hp_base) * cvar_hp_factor[iclass].FloatValue : cvar_hp_factor[iclass].FloatValue ;
	//int hp_inc = (survivors > PlayersBase ) ? RoundFloat(hp_factor) * ( survivors - PlayersBase ) : 0;
	int hp_inc = RoundFloat(hp_factor) * ( survivors - PlayersBase ) ;
	int hp = hp_base + hp_inc;
	
	if(hp_min == 0)
		hp_min = hp_base;
	if(hp < hp_min)
		return hp_min;
	if(hp_max > 0 && hp > hp_max)
		return hp_max;
		
	return hp;
}

int GetSurvivorsCount(){
	
	int survivors = 0;
	for (int i=1; i <= MaxClients; i++)
	{
		if (IsValidSurvivorCheck(i))
		{
			survivors++;
		}
	}
	return survivors;
}

bool IsValidSurvivorCheck(int client){
	if(IS_VALID_SURVIVOR(client)){
		if((CheckMode & 1) && GetBotOfIdle(client) == client)
			return false;
		if((CheckMode & 2) && IsFakeClient(client) && GetBotOfIdle(client) == 0)
			return false;
		if((CheckMode & 4) && !IsPlayerAlive(client) )
			return false;
			
		return true;
	}
	return false;
}

stock int GetBotOfIdle(client)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if (GetIdlePlayer(i) == client) return i;
	}
	return 0;
}

stock int GetIdlePlayer(int bot)
{
	if(IS_SURVIVOR_ALIVE(bot))
	{
		char sNetClass[12];
		GetEntityNetClass(bot, sNetClass, sizeof(sNetClass));

		if(strcmp(sNetClass, "SurvivorBot") == 0)
		{
			int client = GetClientOfUserId(GetEntProp(bot, Prop_Send, "m_humanSpectatorUserID"));			
			if(IS_VALID_SPECTATOR(client))
			{
				return client;
			}
		}
	}
	return 0;
}

stock bool IsTank(int client)
{
	char classname[32];
	GetEntityNetClass(client, classname, sizeof(classname));
	return ( StrEqual(classname, "Tank", false) );
}

stock void SetPlayerHealth(int client, int amount)
{
	SetEntProp(client, Prop_Send, "m_iMaxHealth", amount);
	SetEntProp(client, Prop_Send, "m_iHealth", amount);
}