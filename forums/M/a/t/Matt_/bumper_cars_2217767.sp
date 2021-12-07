#include <sourcemod>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>

new Handle:BoostTime
new Handle:ShouldFixHeadSize
new bool:cvar_HeadSizeFix;
new bool:IsABumperCar[MAXPLAYERS+1] = false;
new bool:IsBoosting[MAXPLAYERS+1] = false;

#define PLUGIN_VERSION		"1.4"

public Plugin:myinfo =
{
	name		= "Bumpa Cars",
	author		= "Matt",
	description	= "Woo, bumpa cars!",
	version		= PLUGIN_VERSION,
	url			= "steamcommunity.com/profiles/76561198060352651"
}

public OnPluginStart()
{
	CreateConVar("bumpercars_version", PLUGIN_VERSION, "Plugin version, don't change this", FCVAR_PLUGIN|FCVAR_NOTIFY);
	HookEvent("player_spawn", PlayerSpawn, EventHookMode_Post)
	RegConsoleCmd("bumpercar", BumperCar_public);
	//RegAdminCmd("bumperize", BumperCar_admin, ADMFLAG_CHEATS);
	RegConsoleCmd("bumpercar_boost", BumperCar_boost);
	DoPrecache()
	ShouldFixHeadSize = CreateConVar("bumpercars_fixheadsize", "1", "Fixes those silly big heads. 0 = Don't resize heads(BIG HEAD), 1 = Do resize heads. (Normal head)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	BoostTime = CreateConVar("bumpercars_boost_time", "1.5", "How long the boost lasts, from 0.0 (Infinite) to 15.0", FCVAR_PLUGIN, true, 0.0, true, 15.0)
	HookConVarChange(ShouldFixHeadSize, HeadSizeFix);
	cvar_HeadSizeFix = GetConVarBool(ShouldFixHeadSize);
}

public HeadSizeFix(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	cvar_HeadSizeFix = (StringToInt(newvalue) != 0);
}

public OnMapStart()
{
	DoPrecache()
}
//Public
public Action:BumperCar_public(client, args)
{
	if(IsABumperCar[client] == false)
	{
		BumperCarOn(client)
		return Plugin_Handled;
	}
	if(IsABumperCar[client] == true)
	{
		BumperCarOff(client)
		return Plugin_Handled;
	}
	return Plugin_Handled;
}
/* I HAVE NO IDEA
//Admin
public Action:BumperCar_admin(client, args)
{
	if (args > 0)
	{
		new String:player[64];
		GetCmdArg(1, player, 64);
		new String:target_name[MAX_TARGET_LENGTH]
		new target_list[MAXPLAYERS], target_count
		new bool:tn_is_ml
	 
		if ((target_count = ProcessTargetString(
				player,
				client,
				target_list,
				MAXPLAYERS,
				COMMAND_FILTER_CONNECTED,
				target_name,
				sizeof(target_name),
				tn_is_ml)) <= 0)
		{
			PrintToChat(client, "Target is invalid")
			return Plugin_Handled;			
		}
		for(new i=0; i<target_count; i++)
		{
			for (new trg=1;trg<=MaxClients;trg++)
			{
				if(IsABumperCar[trg] == false)
				{
					BumperCarOn(target_list[i])
					return Plugin_Handled;
				}
				if(IsABumperCar[trg] == true)
				{
					BumperCarOff(target_list[i] )
					return Plugin_Handled;
				}
			}
		}
		return Plugin_Handled;
	}
	if (IsValidClient(client))
	{
			if(IsABumperCar[client] == false)
			{
				BumperCarOn(client)
				return Plugin_Handled;
			}
			if(IsABumperCar[client] == true)
			{
				BumperCarOff(client)
				return Plugin_Handled;
			}
	}
	return Plugin_Handled;
}
*/

public Action:BumperCar_boost(client, args)
{
	new Float:f_BoostTime = GetConVarFloat(BoostTime)
	if (IsABumperCar[client] == true && IsBoosting[client] == false)
	{
		if (f_BoostTime == 0)	
		{
			//POWER! UNLIMITED POWER!!!
			TF2_AddCondition(client, TFCond:83, Float:TFCondDuration_Infinite, 0);
		}
		else
		{
			TF2_AddCondition(client, TFCond:83, f_BoostTime, 0);
			SetEntPropFloat(client, Prop_Send, "m_flKartNextAvailableBoost", GetGameTime() + f_BoostTime + 3.45);
			IsBoosting[client] = true;
			CreateTimer(f_BoostTime + 3.5, BoostTimer, any:client);
		}
	}
	return Plugin_Handled;
}

public Action:BoostTimer(Handle:timer, any:client)
{
	IsBoosting[client] = false;
	return Plugin_Handled;
}

public PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	if (IsValidClient(client) && IsABumperCar[client] == true)
	{
		TF2_AddCondition(client, TFCond:82, Float:TFCondDuration_Infinite, 0);
	}
}

public HeadScaleThinkHook(client)
{
	SetEntPropFloat(client, Prop_Send, "m_flHeadScale", 1.0)
}

public OnClientDisconnect(client)
{
	if (IsClientInGame(client))
	{
		IsABumperCar[client] = false;
	}
}

stock IsValidClient(client)
{
	if (client == 0)
	{
		return false;
	}
	if (!IsClientConnected(client))
	{
		return false;
	}
	if (!IsClientInGame(client))
	{
		return false;
	}
	if (!IsPlayerAlive(client))
	{
		return false;
	}
	return true;
}

DoPrecache()
{
	decl String:name[64];
	//Models
	PrecacheModel("models/player/items/taunts/bumpercar/parts/bumpercar.mdl");
	PrecacheModel("models/player/items/taunts/bumpercar/parts/bumpercar_nolights.mdl");
	//Sounds
	PrecacheSound("sound/weapons/bumper_car_accelerate.wav", true);
	PrecacheSound("weapons/bumper_car_decelerate.wav", true);
	PrecacheSound("weapons/bumper_car_decelerate_quick.wav", true);
	PrecacheSound("weapons/bumper_car_go_loop.wav", true);
	PrecacheSound("weapons/bumper_car_hit_ball.wav", true);
	PrecacheSound("weapons/bumper_car_hit_ghost.wav", true);
	PrecacheSound("weapons/bumper_car_hit_hard.wav", true);
	PrecacheSound("weapons/bumper_car_hit_into_air.wav", true);
	PrecacheSound("weapons/bumper_car_jump.wav", true);
	PrecacheSound("weapons/bumper_car_jump_land.wav", true);
	PrecacheSound("weapons/bumper_car_screech.wav", true);
	PrecacheSound("weapons/bumper_car_spawn.wav", true);
	PrecacheSound("weapons/bumper_car_spawn_from_lava.wav", true);
	PrecacheSound("weapons/bumper_car_speed_boost_start.wav", true);
	PrecacheSound("weapons/bumper_car_speed_boost_stop.wav", true);
	//ty based McKay
	for(new i = 1; i <= 8; i++)
	{
		FormatEx(name, sizeof(name), "weapons/bumper_car_hit%i.wav", i);
		PrecacheSound(name, true);
	}
}

BumperCarOn(client)
{
	IsABumperCar[client] = true;
	ReplyToCommand(client, "You are now riding a bumper car!")
	TF2_AddCondition(client, TFCond:82, Float:TFCondDuration_Infinite, 0);
	SetEntProp(client, Prop_Send, "m_iKartHealth", 0);
	if (cvar_HeadSizeFix)
	{
		SDKHook(client, SDKHook_PreThink, HeadScaleThinkHook);
	}
}

BumperCarOff(client)
{
	IsABumperCar[client] = false;
	ReplyToCommand(client, "You are no longer riding a bumper car!")
	TF2_RemoveCondition(client, TFCond:82);
	if (cvar_HeadSizeFix)
	{
		SDKUnhook(client, SDKHook_PreThink, HeadScaleThinkHook);
	}
}
//Thanks to DR. McKay for some of the code