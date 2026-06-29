#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.2"

new OffAW = -1;
new Float:LastCharge[MAXPLAYERS+1];
new Float:Multi[MAXPLAYERS+1];
new bool:SpeedEnabled[MAXPLAYERS+1];
new bool:InAttack[MAXPLAYERS+1];
new Handle:g_hcvarSniperScope = INVALID_HANDLE;
new Handle:g_hcvarHuntsman = INVALID_HANDLE;


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
	LoadTranslations("common.phrases");
	OffAW = FindSendPropInfo("CBasePlayer", "m_hActiveWeapon");
	
	CreateConVar("sm_tf2_rof_version", PLUGIN_VERSION, "TF2 Rate of Fire version", FCVAR_PLUGIN|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hcvarSniperScope = CreateConVar("sm_tf2_rof_scope", "0", "Set if rof should effect sniper scope", 0, true, 0.0, true, 1.0);
	g_hcvarHuntsman = CreateConVar("sm_tf2_rof_huntsman", "1", "Set if rof should effect huntsman", 0, true, 0.0, true, 1.0);
	
	RegAdminCmd("sm_rof", Command_Rof, 0, "Set Rate of Fire");
	
	for (new i = 0; i <= MaxClients; i++) OnClientPostAdminCheck(i);
}


public OnClientPostAdminCheck(client)
{
	Multi[client] = 1.0;
	SpeedEnabled[client] = false;
	InAttack[client] = false;
	LastCharge[client] = 0.0;
}


public Action:Command_Rof(client, args)
{
	decl String:arg[65];
	decl String:arg2[20];
	new Float:amount;
	new bool:HasTarget = false;
	
	if (CheckCommandAccess(client, "sm_rof_access_target", ADMFLAG_ROOT))
	{
		if (args < 2)
		{
			ReplyToCommand(client, "[SM] Usage: sm_rof <#userid|name> <1.0 - 10.0>");
			return Plugin_Handled;
		}
		
		GetCmdArg(1, arg, sizeof(arg));
		GetCmdArg(2, arg2, sizeof(arg2));
		
		amount = StringToFloat(arg2);
		
		HasTarget = true;
	}
	else if (CheckCommandAccess(client, "sm_rof_access", ADMFLAG_GENERIC))
	{
		if (args != 1)
		{
			ReplyToCommand(client, "[SM] Usage: sm_rof <1.0 - 10.0>");
			return Plugin_Handled;
		}
		
		GetCmdArg(1, arg, sizeof(arg));
		amount = StringToFloat(arg);
	}
	else
	{
		ReplyToCommand(client, "[SM] You do not have access to this command.");
		return Plugin_Handled;
	}
	
	
	if (amount < 1 || amount > 10)
	{
		ReplyToCommand(client, "[SM] Invalid Amount");
		return Plugin_Handled;
	}
	
	
	decl String:target_name[MAX_TARGET_LENGTH];
	
	if (HasTarget)
	{
		decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
		
		if ((target_count = ProcessTargetString(
				arg,
				client,
				target_list,
				MAXPLAYERS,
				COMMAND_FILTER_CONNECTED,
				target_name,
				sizeof(target_name),
				tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
		
		
		for (new i = 0; i < target_count; i++)
		{
			if (amount == 1)
			{
			SpeedEnabled[target_list[i]] = false;
			Multi[target_list[i]] = amount;
			}
			else
			{
			SpeedEnabled[target_list[i]] = true;
			Multi[target_list[i]] = amount;
			}
		}
		
		if (amount == 1)
		{
			ReplyToCommand(client, "[SM] ROF disabled for %s", target_name);
		}
		else
		{
			ReplyToCommand(client, "[SM] ROF set to: %s for %s", arg2, target_name);
		}
	}
	else
	{
		if (amount == 1)
		{
		SpeedEnabled[client] = false;
		Multi[client] = amount;
		ReplyToCommand(client, "[SM] ROF disabled");
		}
		else
		{
		SpeedEnabled[client] = true;
		Multi[client] = amount;
		ReplyToCommand(client, "[SM] ROF set to: %s", arg);
		}
	}
	
	
	return Plugin_Handled;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (SpeedEnabled[client] && Multi[client] != 1.0)
	{
		if (buttons & IN_ATTACK2)
		{
			new ent = GetEntDataEnt2(client, OffAW);
			if(ent != -1)
			{
				new String:weap[50];
				GetEdictClassname(ent, weap, sizeof(weap));
				if(strcmp(weap, "tf_weapon_sniperrifle") == 0 && GetConVarInt(g_hcvarSniperScope) == 0)
				{
					InAttack[client] = false;
					return Plugin_Continue;
				}
				
				if (strcmp(weap, "tf_weapon_particle_cannon") == 0)
				{
					new Float:charge = GetEntPropFloat(ent, Prop_Send, "m_flChargeBeginTime");
					new Float:chargemod = charge-4.0;
					if (charge != 0 && LastCharge[client] != chargemod)
					{
						LastCharge[client] = chargemod;
						SetEntPropFloat(ent, Prop_Send, "m_flChargeBeginTime", chargemod);
					}
				}
			}
		}
		
		if (buttons & IN_ATTACK || buttons & IN_ATTACK2)
		{
			new ent = GetEntDataEnt2(client, OffAW);
			if(ent != -1)
			{
				new String:weap[50];
				GetEdictClassname(ent, weap, sizeof(weap));
				if(strcmp(weap, "tf_weapon_compound_bow") == 0 && GetConVarInt(g_hcvarHuntsman) == 0)
				{
					InAttack[client] = false;
					return Plugin_Continue;
				}
			}
			InAttack[client] = true;
		}
		else
		{
			InAttack[client] = false;
		}
	}
	return Plugin_Continue;
}

public OnGameFrame()
{
	for(new i=1; i<=MaxClients; i++)
	{
		if (SpeedEnabled[i] && InAttack[i])
		{
			if(IsClientInGame(i) && IsPlayerAlive(i))
			{
				ModRateOfFire(i, Multi[i]);
			}
		}
	}
}

stock ModRateOfFire(client, Float:Amount)
{
	new ent = GetEntDataEnt2(client, OffAW);
	if (ent != -1)
	{
		new Float:m_flNextPrimaryAttack = GetEntPropFloat(ent, Prop_Send, "m_flNextPrimaryAttack");
		new Float:m_flNextSecondaryAttack = GetEntPropFloat(ent, Prop_Send, "m_flNextSecondaryAttack");
		if (Amount > 12)
		{
			SetEntPropFloat(ent, Prop_Send, "m_flPlaybackRate", 12.0);
		}
		else
		{
			SetEntPropFloat(ent, Prop_Send, "m_flPlaybackRate", Amount);
		}
		
		new Float:GameTime = GetGameTime();
		
		new Float:PeTime = (m_flNextPrimaryAttack - GameTime) - ((Amount - 1.0) / 50);
		new Float:SeTime = (m_flNextSecondaryAttack - GameTime) - ((Amount - 1.0) / 50);
		new Float:FinalP = PeTime+GameTime;
		new Float:FinalS = SeTime+GameTime;
		
		
		SetEntPropFloat(ent, Prop_Send, "m_flNextPrimaryAttack", FinalP);
		SetEntPropFloat(ent, Prop_Send, "m_flNextSecondaryAttack", FinalS);
	}
}
