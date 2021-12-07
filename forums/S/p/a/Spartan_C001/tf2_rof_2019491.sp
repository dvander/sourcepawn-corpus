#include <sourcemod>

#define PLUGIN_VERSION "1.2"

new OffAW = -1

new Float:LastCharge[MAXPLAYERS+1]
new Float:Multi[MAXPLAYERS+1]

new bool:SpeedEnabled[MAXPLAYERS+1]
new bool:InAttack[MAXPLAYERS+1]

new Handle:RoFSniperScope = INVALID_HANDLE
new Handle:RoFHuntsman = INVALID_HANDLE

public Plugin:myinfo = 
{
	name = "[TF2] Rate of Fire",
	author = "EHG",
	description = "Modify weapon rate of fire",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart()
{
	LoadTranslations("common.phrases")
	OffAW = FindSendPropInfo("CBasePlayer", "m_hActiveWeapon")
	RoFSniperScope = CreateConVar("sm_tf2_rof_scope", "0", "Should RoF effect sniper scope?")
	RoFHuntsman = CreateConVar("sm_tf2_rof_huntsman", "0", "Should RoF effect huntsman?")
	RegAdminCmd("sm_rof_version",Command_Version,ADMFLAG_ROOT,"Shows version of loaded plugin.")
	RegAdminCmd("sm_rof", Command_Rof, ADMFLAG_ROOT, "Set Rate of Fire for target(s).")
	for (new i = 0; i <= MaxClients; i++) 
	{
		OnClientPostAdminCheck(i)
	}
}

public OnClientPostAdminCheck(client)
{
	Multi[client] = 1.0
	SpeedEnabled[client] = false
	InAttack[client] = false
	LastCharge[client] = 0.0
}

public Action:Command_Rof(client, args)
{
	new String:bufferString[128]
	if (args < 2 || args > 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_rof <#userid|name> <1.0 - 10.0>")
		return Plugin_Handled
	}
	GetCmdArg(2, bufferString, sizeof(bufferString))
	new Float:amount = StringToFloat(bufferString)
	if (amount < 1 || amount > 10)
	{
		ReplyToCommand(client, "[SM] Usage: sm_rof <#userid|name> <1.0 - 10.0>")
		return Plugin_Handled
	}
	GetCmdArg(1, bufferString, sizeof(bufferString))
	new String:target_name[MAX_TARGET_LENGTH]
	new target_list[MAXPLAYERS]
	new target_count
	new bool:tn_is_ml
	if ((target_count = ProcessTargetString(bufferString,client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
			ReplyToTargetError(client, target_count)
			return Plugin_Handled
	}
	for (new i = 0; i < target_count; i++)
	{
		if (amount == 1)
		{
			Multi[target_list[i]] = 1.0
			SpeedEnabled[target_list[i]] = false
		}
		else
		{
			Multi[target_list[i]] = amount
			SpeedEnabled[target_list[i]] = true
		}
	}
	if (amount == 1)
	{
		PrintToChatAll("[SM] Rate of Fire set to default for %s!", target_name)
		PrintToServer("[SM] Rate of Fire set to default for %s!", target_name)
	}
	else
	{
		PrintToChatAll("[SM] Rate of Fire set to %fx for %s!", amount, target_name)
		PrintToServer("[SM] Rate of Fire set to %fx for %s!", amount, target_name)
	}	
	return Plugin_Handled
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (SpeedEnabled[client] && Multi[client] != 1.0)
	{
		if (buttons & IN_ATTACK2)
		{
			new ent = GetEntDataEnt2(client, OffAW)
			if(ent != -1)
			{
				new String:weap[50]
				GetEdictClassname(ent, weap, sizeof(weap))
				if(strcmp(weap, "tf_weapon_sniperrifle") == 0 && GetConVarInt(RoFSniperScope) == 0)
				{
					InAttack[client] = false
					return Plugin_Continue
				}
				if (strcmp(weap, "tf_weapon_particle_cannon") == 0)
				{
					new Float:charge = GetEntPropFloat(ent, Prop_Send, "m_flChargeBeginTime")
					new Float:chargemod = charge-4.0
					if (charge != 0 && LastCharge[client] != chargemod)
					{
						LastCharge[client] = chargemod
						SetEntPropFloat(ent, Prop_Send, "m_flChargeBeginTime", chargemod)
					}
				}
			}
		}
		if (buttons & IN_ATTACK || buttons & IN_ATTACK2)
		{
			new ent = GetEntDataEnt2(client, OffAW)
			if(ent != -1)
			{
				new String:weap[50]
				GetEdictClassname(ent, weap, sizeof(weap))
				if(strcmp(weap, "tf_weapon_compound_bow") == 0 && GetConVarInt(RoFHuntsman) == 0)
				{
					InAttack[client] = false
					return Plugin_Continue
				}
			}
			InAttack[client] = true
		}
		else
		{
			InAttack[client] = false
		}
	}
	return Plugin_Continue
}

public OnGameFrame()
{
	for(new i=1; i<=MaxClients; i++)
	{
		if (SpeedEnabled[i] && InAttack[i])
		{
			if(IsClientInGame(i) && IsPlayerAlive(i))
			{
				ModRateOfFire(i, Multi[i])
			}
		}
	}
}

public ModRateOfFire(client, Float:amount)
{
	new ent = GetEntDataEnt2(client, OffAW)
	if (ent != -1)
	{
		new Float:m_flNextPrimaryAttack = GetEntPropFloat(ent, Prop_Send, "m_flNextPrimaryAttack")
		new Float:m_flNextSecondaryAttack = GetEntPropFloat(ent, Prop_Send, "m_flNextSecondaryAttack")
		if (amount > 12)
		{
			SetEntPropFloat(ent, Prop_Send, "m_flPlaybackRate", 12.0)
		}
		else
		{
			SetEntPropFloat(ent, Prop_Send, "m_flPlaybackRate", amount)
		}
		new Float:GameTime = GetGameTime()
		new Float:PeTime = (m_flNextPrimaryAttack - GameTime) - ((amount - 1.0) / 50)
		new Float:SeTime = (m_flNextSecondaryAttack - GameTime) - ((amount - 1.0) / 50)
		new Float:FinalP = PeTime+GameTime
		new Float:FinalS = SeTime+GameTime
		SetEntPropFloat(ent, Prop_Send, "m_flNextPrimaryAttack", FinalP)
		SetEntPropFloat(ent, Prop_Send, "m_flNextSecondaryAttack", FinalS)
	}
}

public Action:Command_Version(client,args)
{
	ReplyToCommand(client, "[SM] TF2-RoF Version %s", PLUGIN_VERSION)
	return Plugin_Handled
}