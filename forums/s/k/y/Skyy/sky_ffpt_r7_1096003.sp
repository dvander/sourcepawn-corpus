// Friendly Fire Protection
// And Eventual Removal Tool

/****************************************
This Plugin is an highly customizable
Friendly-Fire Protection Tool.
Permanent Ban or Time Ban, Kicking, How
Many Kicks before ban is allowed,
Slaying, Enable and Disable Reversed
Effect, etc.
****************************************/

/*
/ Version History
/
/ 1.0
/ Initial Release.
/
/ 1.1
/ Changed interface and added warning feature.
/
/ 1.2
/ Added option to enable/disable victim healing of
/ Friendly fire received.
/ Added option to enable/disable redirecting damage
/ Dealt to victim back upon the attacker, regardless
/ Of whether victim is healed or not.
/ Allows administrators to set amount of damage
/ received as a result of the friendly fire.
/
/ 1.3
/ New commands.
/ Forgiveall - Forgives all players of current friendly-fire
/			Amounts. (Admin only)
/ Forgiveme - Forgives the player. (Admin only)
/ damage  - Lets any player check their current recorded
/			Amount in that round.
/
/ 1.4
/ More functionality and customization.
/
/ 1.5
/ Toggle FF To Reset at round end or never reset.
/ 3 options for how to display friendly-fire warning.
/ Option to reset friendly-fire at start of new campaigns,
/ Instead of every round. However, round reset enabled overrides
/ Campaign reset enabled/disabled.
/ Option to display friendly-fire amount in 3 different forms.
/ Disabled by default due to... massive spam.
/ Can now display who the attacker was publicly (privately in next update)
/ As well as select from 3 different forms of display,
/ Also has ability to show in full detail (attacker, victim, damage)

FFProtection_AttackerDisplay
FFProtection_AttackerDType
FFProtection_ShowVictim
FFProtection_ShowDetail
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.2 r7"
#define SURVIVORTEAM 2

new Handle:FFProtection_Enable = INVALID_HANDLE;
new Handle:FFProtection_Punish = INVALID_HANDLE;
new Handle:FFProtection_Limit = INVALID_HANDLE;
new Handle:FFProtection_Kick = INVALID_HANDLE;
new Handle:FFProtection_Ban = INVALID_HANDLE;
new Handle:FFProtection_Warning = INVALID_HANDLE;
new Handle:FFProtection_WarningType = INVALID_HANDLE;
new Handle:FFProtection_WarnDisplay = INVALID_HANDLE;
new Handle:FFProtection_WarnDisplayType = INVALID_HANDLE;
new Handle:FFProtection_AttackerDisplay = INVALID_HANDLE;
new Handle:FFProtection_AttackerDType = INVALID_HANDLE;
new Handle:FFProtection_ShowVictim = INVALID_HANDLE;
new Handle:FFProtection_ShowDetail = INVALID_HANDLE;
new Handle:FFProtection_Slay = INVALID_HANDLE;
new Handle:FFProtection_Fire = INVALID_HANDLE;
new Handle:FFProtection_Incap = INVALID_HANDLE;
new Handle:FFProtection_TimeBan = INVALID_HANDLE;
new Handle:FFProtection_KickMax = INVALID_HANDLE;
new Handle:FFProtection_SlayAllowed = INVALID_HANDLE;
new Handle:FFProtection_Redirect = INVALID_HANDLE;
new Handle:FFProtection_Heal = INVALID_HANDLE;
new Handle:FFProtection_pAmount = INVALID_HANDLE;
new Handle:FFProtection_pRound = INVALID_HANDLE;
new Handle:FFProtection_pCampaign = INVALID_HANDLE;

new totalDamage[MAXPLAYERS + 1];
new kickMax[MAXPLAYERS + 1];
new wasSlayed[MAXPLAYERS + 1];
new firstRound;

public Plugin:myinfo =
{
	name = "Friendly Fire Protection Removal Tool",
	author = "Sky",
	description = "Protects Players From Friendly-Fire, with additional Protective Options",
	version = "1.2 r7",
	url = "http://steamcommunity.com/groups/skygamingorg"
};

public OnPluginStart()
{
	CreateConVar("sky_protect_ver", PLUGIN_VERSION, "Sky_Protect_Ver", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	RegConsoleCmd("damage", damageAmount);
	RegAdminCmd("forgiveall", forgiveAll, ADMFLAG_KICK);
	RegAdminCmd("forgiveme", forgiveMe, ADMFLAG_KICK);
	
	FFProtection_Enable = CreateConVar("l4d2_ffprotection_enable","1","Enable or Disable the plugin.");
	FFProtection_Punish = CreateConVar("l4d2_ffprotection_punish","1","Punish the Attacking Teammate?");
	FFProtection_Limit = CreateConVar("l4d2_ffprotection_fflimit","1","FF Damage Limit Enabled or Disabled. (Must be ON for Kick/Ban/Slay");
	FFProtection_Kick = CreateConVar("l4d2_ffprotection_kick","0","Friendly-Fire Limit at which to Kick Offender. 0 Disables.");
	FFProtection_Ban = CreateConVar("l4d2_ffprotection_ban","0","Friendly-Fire Limit at which to Ban Offender. 0 Disables. (Overrides Kick.)");
	FFProtection_Warning = CreateConVar("l4d2_ffprotection_warn","1","Enable or Disable Warning Attacker.");
	FFProtection_WarningType = CreateConVar("l4d2_ffprotection_warn_type","1","1 - Center Text (that small stuff) 2 - Hint Text 3 - Chat Text. (Defaults to 1 if invalid selection. Should not be same as display type due to conflict)");
	FFProtection_WarnDisplay = CreateConVar("l4d2_ffprotection_warn_display","0","Enables or Disables showing player damage amount caused by their friendly-fire.");
	FFProtection_WarnDisplayType = CreateConVar("l4d2_ffprotection_warn_display_type","1","1 - Center Text 2 - Hint Text 3 - Chat Text. (Defaults to 1 if invalid selection. Should not be same as warn type due to conflict)");	
	FFProtection_AttackerDisplay = CreateConVar("l4d2_ffprotection_attacker_display","0","Enables Display of person who is attacking teammates.");
	FFProtection_AttackerDType = CreateConVar("l4d2_ffprotection_attacker_display_type","0","Attacker Display must be enabled. 1 (Center) 2 (Hint) 3 (Chat). If war, warn display, and attacker display enabled, encourage all 3 different values.)");
	FFProtection_ShowVictim = CreateConVar("l4d2_ffprotection_show_victim","0","If Attacker Display Enabled, Enables or Disables showing the victim.");
	FFProtection_ShowDetail = CreateConVar("l4d2_ffprotection_show_detail","0","If Enabled, shows full detail. Show victim, and attacker display must be enabled for this to work.");
	FFProtection_Slay = CreateConVar("l4d2_ffprotection_slay","0","When set above 0, will kill attacker when they pass the Friendly-Fire Limit set here.");
	FFProtection_Fire = CreateConVar("l4d2_ffprotection_fire","0","Enable or Disable Friendly-Fire through Molotov usage.");
	FFProtection_Incap = CreateConVar("l4d2_ffprotection_slay","1","Allow Friendly-Fire to Incapacitate the attacker?");
	FFProtection_TimeBan = CreateConVar("l4d2_ffprotection_timeban","15","If ban is enabled, the amount of time in minutes to ban the offender.");
	FFProtection_KickMax = CreateConVar("l4d2_ffprotection_kickmax","1","If at least 1, will kick offender this many times prior to ban. If 0, will never kick.");
	FFProtection_SlayAllowed = CreateConVar("l4d2_ffprotection_slay_enabled","1","Enable or Disable the plugin from slaying offenders.");
	FFProtection_Redirect = CreateConVar("l4d2_ffprotection_attacker_redirect","1","Enable or Disable the redirection of Friendly Fire upon the attacker.");
	FFProtection_Heal = CreateConVar("l4d2_ffprotection_victim_heal","1","Enable or Disable healing victim of damage received from Friendly-Fire.");
	FFProtection_pAmount = CreateConVar("l4d2_ffprotection_punish_amount","1","Amount of damage offender receives. If 0, received is same as dealt.");
	FFProtection_pRound = CreateConVar("l4d2_ffprotection_reset_round","1","Reset Friendly-Fire At the end of the round? (Overrides campaign reset)");
	FFProtection_pCampaign = CreateConVar("l4d2_ffprotection_reset_finale","0","Reset Friendly-Fire At the end of the campaign?");
	
	AutoExecConfig(true, "sky_ffpt_r7");
	
	HookConVarChange(FFProtection_Enable, Check_FFProtection_Enable);
	HookConVarChange(FFProtection_Punish, Check_FFProtection_Punish);
	HookConVarChange(FFProtection_Limit, Check_FFProtection_Limit);
	HookConVarChange(FFProtection_Kick, Check_FFProtection_Kick);
	HookConVarChange(FFProtection_Ban, Check_FFProtection_Ban);
	HookConVarChange(FFProtection_Warning, Check_FFProtection_Warning);
	HookConVarChange(FFProtection_WarningType, Check_FFProtection_WarningType);
	HookConVarChange(FFProtection_WarnDisplay, Check_FFProtection_WarnDisplay);
	HookConVarChange(FFProtection_WarnDisplayType, Check_FFProtection_WarnDisplayType);
	HookConVarChange(FFProtection_AttackerDisplay, Check_FFProtection_AttackerDisplay);
	HookConVarChange(FFProtection_AttackerDType, Check_FFProtection_AttackerDType);
	HookConVarChange(FFProtection_ShowVictim, Check_FFProtection_ShowVictim);
	HookConVarChange(FFProtection_ShowDetail, Check_FFProtection_ShowDetail);
	HookConVarChange(FFProtection_Slay, Check_FFProtection_Slay);
	HookConVarChange(FFProtection_Fire, Check_FFProtection_Fire);
	HookConVarChange(FFProtection_Incap, Check_FFProtection_Incap);
	HookConVarChange(FFProtection_TimeBan, Check_FFProtection_TimeBan);
	HookConVarChange(FFProtection_KickMax, Check_FFProtection_KickMax);
	HookConVarChange(FFProtection_SlayAllowed, Check_FFProtection_SlayAllowed);
	HookConVarChange(FFProtection_Redirect, Check_FFProtection_Redirect);
	HookConVarChange(FFProtection_Heal, Check_FFProtection_Heal);
	HookConVarChange(FFProtection_pAmount, Check_FFProtection_pAmount);
	HookConVarChange(FFProtection_pRound, Check_FFProtection_pRound);
	HookConVarChange(FFProtection_pCampaign, Check_FFProtection_pCampaign);
	
	HookEvent("player_hurt", PlayerHurt_Action);
	HookEvent("round_end", RoundEnd);
	
	HookEvent("round_start", RoundStart);
	
	PrintToChatAll("\x03Sky's \x04Friendly-Fire Protection Tool \x03Loaded.");
}

public Check_FFProtection_Enable(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	SetConVarInt(FFProtection_Enable, StringToInt(newVal));
}

public Check_FFProtection_Punish(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	SetConVarInt(FFProtection_Punish, StringToInt(newVal));
}

public Check_FFProtection_Limit(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	SetConVarInt(FFProtection_Limit, StringToInt(newVal));
}

public Check_FFProtection_Kick(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	SetConVarInt(FFProtection_Kick, StringToInt(newVal));
}

public Check_FFProtection_Ban(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	SetConVarInt(FFProtection_Ban, StringToInt(newVal));
}

public Check_FFProtection_Warning(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	SetConVarInt(FFProtection_Warning, StringToInt(newVal));
}

public Check_FFProtection_WarningType(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	SetConVarInt(FFProtection_WarningType, StringToInt(newVal));
}

public Check_FFProtection_WarnDisplay(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	SetConVarInt(FFProtection_WarnDisplay, StringToInt(newVal));
}

public Check_FFProtection_WarnDisplayType(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	SetConVarInt(FFProtection_WarnDisplayType, StringToInt(newVal));
}

public Check_FFProtection_AttackerDisplay(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	SetConVarInt(FFProtection_AttackerDisplay, StringToInt(newVal));
}

public Check_FFProtection_AttackerDType(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	SetConVarInt(FFProtection_AttackerDType, StringToInt(newVal));
}

public Check_FFProtection_ShowVictim(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	SetConVarInt(FFProtection_ShowVictim, StringToInt(newVal));
}

public Check_FFProtection_ShowDetail(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	SetConVarInt(FFProtection_ShowDetail, StringToInt(newVal));
}

public Check_FFProtection_Slay(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	SetConVarInt(FFProtection_Slay, StringToInt(newVal));
}

public Check_FFProtection_Fire(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	SetConVarInt(FFProtection_Fire, StringToInt(newVal));
}

public Check_FFProtection_Incap(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	SetConVarInt(FFProtection_Incap, StringToInt(newVal));
}

public Check_FFProtection_TimeBan(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	SetConVarInt(FFProtection_TimeBan, StringToInt(newVal));
}

public Check_FFProtection_KickMax(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	SetConVarInt(FFProtection_KickMax, StringToInt(newVal));
}

public Check_FFProtection_SlayAllowed(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	SetConVarInt(FFProtection_SlayAllowed, StringToInt(newVal));
}

public Check_FFProtection_Redirect(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	SetConVarInt(FFProtection_Redirect, StringToInt(newVal));
}

public Check_FFProtection_Heal(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	SetConVarInt(FFProtection_Heal, StringToInt(newVal));
}

public Check_FFProtection_pAmount(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	SetConVarInt(FFProtection_pAmount, StringToInt(newVal));
}

public Check_FFProtection_pRound(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	SetConVarInt(FFProtection_pRound, StringToInt(newVal));
}

public Check_FFProtection_pCampaign(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	SetConVarInt(FFProtection_pCampaign, StringToInt(newVal));
}

public Action:RoundStart(Handle:event, String:event_name[], bool:dontBroadcast)
{
	if (firstRound > 3)
	{
		firstRound = 0;
	}
	if (firstRound < 1)
	{
		if (GetConVarInt(FFProtection_pCampaign) == 1)
		{
			for (new index; index <= MaxClients; index++)
			{
				totalDamage[index] = 0;
			}
		}
		firstRound++;
	}
}

public Action:RoundEnd(Handle:event, String:event_name[], bool:dontBroadcast)
{
	if (GetConVarInt(FFProtection_pRound) == 1)
	{
		for (new index; index <= MaxClients;index++)
		{
			totalDamage[index] = 0;
		}
	}
}

public Action:PlayerHurt_Action(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(FFProtection_Enable) != 1)
	{
		return Plugin_Continue;
	}

	new victimUserId = GetClientOfUserId(GetEventInt(event, "userid"));
	new attackerUserId = GetEventInt(event, "attackerentid");
	new attackerHealth;
	new victimHurt = GetEventInt(event, "dmg_health");

	new String:WeaponCallBack[32];
	GetEventString(event, "weapon", WeaponCallBack, 32);

	if ((!IsValidEntity(victimUserId)) || (!IsValidEntity(attackerUserId)))
	{
		return Plugin_Continue;
	}
	if ((strlen(WeaponCallBack) <= 0) || (attackerUserId == victimUserId) || (GetClientTeam(victimUserId) != GetClientTeam(attackerUserId)) || GetClientTeam(attackerUserId) != 2)
	{
		return Plugin_Continue;
	}
	if (StrEqual(WeaponCallBack, "inferno", false))
	{
		if (GetConVarInt(FFProtection_Punish) == 1)
		{
			if (GetConVarInt(FFProtection_Fire) != 1)
			{
				return Plugin_Continue;
			}
		}
	}
	if (IsPlayerAlive(victimUserId) && IsClientInGame(victimUserId))
	{
		new victimHealth = GetClientHealth(victimUserId);
		if (GetConVarInt(FFProtection_Heal) == 1)
		{
			SetEntityHealth(victimUserId, (victimHealth+victimHurt));
		}
	}
	if (GetConVarInt(FFProtection_Punish) == 1)
	{
		//new client = GetClientOfUserId(GetEventInt(event, "userid"));
		new attackerLoss = GetConVarInt(FFProtection_pAmount);
		if (GetConVarInt(FFProtection_pAmount) >= 1)
		{
			totalDamage[attackerUserId] += attackerLoss;
		}
		else
		{
			totalDamage[attackerUserId] += victimHurt;
		}
		if (IsPlayerAlive(attackerUserId) && IsClientInGame(victimUserId))
		{
			new tellClient = GetClientOfUserId(GetEventInt(event, "attacker"));
			if (GetConVarInt(FFProtection_Warning) == 1)
			{
				if (GetConVarInt(FFProtection_WarningType) == 1)
				{
					PrintCenterText(tellClient, "Friendly-Fire Will Not Be Tolerated!");
				}
				else if (GetConVarInt(FFProtection_WarningType) == 2)
				{
					PrintHintText(tellClient, "Friendly-Fire Will Not Be Tolerated!");
				}
				else if (GetConVarInt(FFProtection_WarningType) == 3)
				{
					PrintToChat(tellClient, "Friendly-Fire Will Not Be Tolerated!");
				}
				if (GetConVarInt(FFProtection_WarnDisplay) == 1)
				{
					if (GetConVarInt(FFProtection_WarnDisplayType) == 1)
					{
						PrintCenterText(tellClient, "FF Dealt: %d", victimHurt);
					}
					else if (GetConVarInt(FFProtection_WarnDisplayType) == 2)
					{
						PrintHintText(tellClient, "FF Dealt: %d", victimHurt);
					}
					else if (GetConVarInt(FFProtection_WarnDisplayType) == 3)
					{
						PrintToChat(tellClient, "\x04FF Dealt: \x03 %d", victimHurt);
					}
				}
				if (GetConVarInt(FFProtection_AttackerDisplay) == 1)
				{
					if (GetConVarInt(FFProtection_AttackerDType) == 1)
					{
						if (GetConVarInt(FFProtection_ShowVictim) == 1)
						{
							if (GetConVarInt(FFProtection_ShowDetail) == 1)
							{
								PrintCenterTextAll("%N damaged %N for %d", attackerUserId, victimUserId, victimHurt);
							}
							else
							{
								PrintCenterTextAll("%N damaged %N", attackerUserId, victimUserId);
							}
						}
						else
						{
							PrintCenterTextAll("%N damaged a teammate!", attackerUserId);
						}
					}
					else if (GetConVarInt(FFProtection_AttackerDType) == 2)
					{
						if (GetConVarInt(FFProtection_ShowVictim) == 1)
						{
							if (GetConVarInt(FFProtection_ShowDetail) == 1)
							{
								PrintHintTextToAll("%N damaged %N for %d", attackerUserId, victimUserId, victimHurt);
							}
							else
							{
								PrintHintTextToAll("%N damaged %N", attackerUserId, victimUserId);
							}
						}
						else
						{
							PrintHintTextToAll("%N damaged a teammate!", attackerUserId);
						}
					}
					else if (GetConVarInt(FFProtection_AttackerDType) == 3)
					{
						if (GetConVarInt(FFProtection_ShowVictim) == 1)
						{
							if (GetConVarInt(FFProtection_ShowDetail) == 1)
							{
								PrintToChatAll("\x03 %N \x04damaged \x03 %N \x04for \x03 %d", attackerUserId, victimUserId, victimHurt);
							}
							else
							{
								PrintToChatAll("\x03 %N \x04damaged \x03 %N", attackerUserId, victimUserId);
							}
						}
						else
						{
							PrintToChatAll("\x03 %N \x04damaged a teammate!", attackerUserId);
						}
					}
				}
			}
			if (GetConVarInt(FFProtection_Redirect) == 1)
			{
				if (GetConVarInt(FFProtection_pAmount) >= 1)
				{
					attackerHealth = (GetClientHealth(attackerUserId)-(attackerLoss));
				}
				else
				{
					attackerHealth = (GetClientHealth(attackerUserId)-victimHurt);
				}
			}
			if (GetConVarInt(FFProtection_Incap) == 1)
			{
				SetEntityHealth(attackerUserId, attackerHealth);
			}
			else if (attackerHealth > 0)
			{
				SetEntityHealth(attackerUserId, attackerHealth);
			}
		}
		if (GetConVarInt(FFProtection_Limit) == 1)
		{
			if (GetConVarInt(FFProtection_Slay) > 0 && totalDamage[attackerUserId] >= GetConVarInt(FFProtection_Slay))
			{
				if (GetConVarInt(FFProtection_SlayAllowed) == 1)
				{
					if (wasSlayed[attackerUserId] < 1)
					{
						wasSlayed[attackerUserId] += 1;
						PrintToChat(attackerUserId, "Excessive Friendly Fire. Result: Slay");
						ForcePlayerSuicide(attackerUserId);
					}
				}
			}
			if (GetConVarInt(FFProtection_Kick) > 0 && totalDamage[attackerUserId] >= GetConVarInt(FFProtection_Kick))
			{
				if (totalDamage[attackerUserId] < GetConVarInt(FFProtection_Ban))
				{
					if (kickMax[attackerUserId] != GetConVarInt(FFProtection_KickMax))
					{
						if (GetConVarInt(FFProtection_KickMax) == 1)
						{
							kickMax[attackerUserId] += 1;
						}
						PrintToChatAll("%N Was Kicked due to excessive Friendly-Fire.", attackerUserId);
						KickClient(attackerUserId,"Kicked For Friendly-Fire Violation.");
					}
				}
			}
			if (GetConVarInt(FFProtection_Ban) > 0 && totalDamage[attackerUserId] >= GetConVarInt(FFProtection_Ban))
			{
				PrintToChatAll("%N Was Banned due to excessive Friendly-Fire.", attackerUserId);
				new Float:banTime = GetConVarFloat(FFProtection_TimeBan);
				BanClient(attackerUserId, Float:banTime, BANFLAG_AUTO, "Temp Ban: Excessive Friendly-Fire", "Temp Ban: Excessive Friendly-Fire", "sm_ban", attackerUserId);
			}
		}	
	}
	return Plugin_Continue;
}

public Action:damageAmount(client,args)
{
	ShowDamageAmount(client);
	return Plugin_Handled;
}

public Action:ShowDamageAmount(client)
{
	PrintToChat(client, "\x04Friendly-Fire This Round: \x03 %d",totalDamage[client]);
	return Plugin_Handled;
}

public Action:forgiveAll(client,args)
{
	for (new index; index < MaxClients;index++)
	{
		totalDamage[index] = 0;
	}
	PrintToChatAll("\x04Friendly-Fire Calculations Reset \x03for all clients.");
}

public Action:forgiveMe(client,args)
{
	totalDamage[client] = 0;
	PrintToChat(client, "\x04Friendly-Fire Calculations Reset \x03for %d");
}