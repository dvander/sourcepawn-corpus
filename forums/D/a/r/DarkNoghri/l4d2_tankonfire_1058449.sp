#include <sourcemod>
#pragma semicolon 1
#define PLUGIN_VERSION "1"

public Plugin:myinfo =
{
	name = "L4D2 Tank-on-fire Speed Booster",
	author = "DarkNoghri",
	description = "Increase the speed of tanks when on fire in versus.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
};

new bool:tank_on_fire;
new Handle:h_cvarBoostEnabled=INVALID_HANDLE;
new Handle:h_cvarTankSpeed=INVALID_HANDLE;
new Handle:h_cvarSpeedBoost=INVALID_HANDLE;
new Handle:h_timerTank=INVALID_HANDLE;
new speed_boosted;
new tank_speed;
new Float:multiplier;

public OnPluginStart()
{
	//create version convar
	CreateConVar("l4d2_tankonfire_version", PLUGIN_VERSION, "Version of L4D2 Tank-on-fire Speed Booster", FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	//possibly get value of mp_gamemode to enable/disable plugin
	
	HookEvent("zombie_ignited", EventZombieIgnited);
	HookEvent("tank_killed", EventTankKilled);
	HookEvent("player_hurt", EventPlayerHurt);
	
	//create option convars
	h_cvarBoostEnabled = CreateConVar("l4d2_tankfire_boost_enable", "1", "0 turns speed boost off, 1 turns it on.", FCVAR_PLUGIN, true, 0, true, 1.0);
	h_cvarSpeedBoost = CreateConVar("l4d2_tankfire_boost_amount", "1.2", "Multiplier for tank speed while on fire.", FCVAR_PLUGIN, true, 0.5, true, 2.0);
	h_cvarTankSpeed = FindConVar("z_tank_speed_vs");
	
	//hook convar changes
	HookConVarChange(h_cvarBoostEnabled, ChangeBoostEnabled);
	HookConVarChange(h_cvarSpeedBoost, ChangeSpeedBoost);
	
	//read values from convars initially
	speed_boosted = GetConVarInt(h_cvarBoostEnabled);
	tank_speed = GetConVarInt(h_cvarTankSpeed);
	multiplier = GetConVarFloat(h_cvarSpeedBoost);
}

public EventZombieIgnited(Handle:event, const String:name[], bool:dontBroadcast)
{
	//boost turned on
	if(speed_boosted == 1)
	{	
		decl String:targetType[64];
		GetEventString(event, "victimname", targetType, sizeof(targetType));
		
		if(StrContains(targetType, "Tank", false) >= 0)
		{
			//tank just got lit on fire
			//PrintToChatAll("TANK ON FIRE!");
			tank_on_fire = true;
			SetConVarInt(h_cvarTankSpeed, RoundFloat(tank_speed*multiplier));
			if(h_timerTank != INVALID_HANDLE)
			{
				//PrintToChatAll("properhandle");
				KillTimer(h_timerTank);
				h_timerTank = CreateTimer(1.0, FlameCheck);
				
			}
			else 
			{
				//PrintToChatAll("invalidhandle");
				h_timerTank = CreateTimer(1.0, FlameCheck);
			}
		}
	}
	
	return Plugin_Continue;
}

//timer finally able to run out, slow back down.
public Action:FlameCheck(Handle:timer)
{
	SetConVarInt(h_cvarTankSpeed, tank_speed);
	tank_on_fire = false;
	//PrintToChatAll("Tank Extinguished");
	h_timerTank = INVALID_HANDLE;
}

public EventTankKilled(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(speed_boosted == 1)
	{
		//tank died
		//PrintToChatAll("TANK DEAD!");
		tank_on_fire = false;
		SetConVarInt(h_cvarTankSpeed, tank_speed);
	}
	
	return Plugin_Continue;
}

public EventPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	/*if(speed_boosted == 1)
	{
		//what hit player?
		decl String:weaponUsed[64];
		GetEventString(event, "weapon", weaponUsed, sizeof(weaponUsed));
		
		//who is it?
		new target = GetClientOfUserId(GetEventInt(event, "userid"));
		decl String:targetModel[128];
		
		if(target == 0) return Plugin_Continue;
		
		GetClientModel(target, targetModel, sizeof(targetModel));
		
		if(StrContains(targetModel, "hulk", false) >= 0) && StrContains(weaponUsed, "entityflame", false) >= 0)
		{
			//its a TANK!!!
			//tank just got lit on fire
			PrintToChatAll("TANK ON FIRE! %s", weaponUsed);
			tank_on_fire = true;
		}
	}*/
	return Plugin_Continue;
}

public OnMapEnd()
{
	tank_on_fire = false;
	SetConVarInt(h_cvarTankSpeed, tank_speed);
}

//convars changed
public ChangeBoostEnabled(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	speed_boosted = StringToInt(newVal);
}

public ChangeSpeedBoost(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	multiplier = StringToFloat(newVal);
}