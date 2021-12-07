#include <sourcemod>
#include <tf2_stocks>
#include <sdktools>

#define PLUGIN_VERSION  "2.0"

#define TF_OBJECT_SENTRY		3
#define MAX_CLIENTS				33
#define MAX_UPGRADE_LIMIT		174

#define TF_TEAM_BLU			3
#define TF_TEAM_RED			2

public Plugin:myinfo = 
{
	name = "Sentry Limit",
	author = "Quaz and Wally",
	description = "Teams have a limit on their sentries and their levels.",
	version = PLUGIN_VERSION,
	url = "https://sites.google.com/site/quazandwallystf2stuff/"
}

///Global Variables

new sl_max_sentry_levels = 3;
new sl_sentry_value[5] = {0, 0, 1, 2, 0};
new sl_upgrade_limit = 100;

new sentryLevel[2048];

new level_sum[2];
//  0 = RED
//  1 = BLU

new bool:refund;

new bool:showValues[MAX_CLIENTS];
new bool:firstLife[MAX_CLIENTS];
new bool:showHud[MAX_CLIENTS];

new oldMetal[MAX_CLIENTS];
new currentMetal[MAX_CLIENTS];

new Handle:sl_cvar_Enable = INVALID_HANDLE;
new Handle:HudMessage;


///Callbacks

public OnPluginStart()
{
	CreateConVar("sm_sentry_limit_version", PLUGIN_VERSION, "The Sentry Limit Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	sl_cvar_Enable = CreateConVar("sm_sentry_limit_enable", "0", "On \"1\" enforces a Sentry Limit (default \"0\").", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	RegAdminCmd("sm_max_parts", change_max_sentry_levels, ADMFLAG_CHEATS);
	RegAdminCmd("sm_sentry_value", change_sentry_values, ADMFLAG_CHEATS);
	RegAdminCmd("sm_upgrade_limit", change_upgrade_limit, ADMFLAG_CHEATS);

	RegConsoleCmd("show_sentry_values", Command_ShowValues, "Determines whether or not to show the sentry level values.");
	RegConsoleCmd("show_sentry_hud", Command_ShowHud, "Determines whether or not to show the sentry limiter hud.");
	
	for (new i = 0; i < MAX_CLIENTS; i++)
	{
		showHud[i] = true;
		firstLife[i] = true;
		showValues[i] = true;
	}
	
	HookConVarChange(sl_cvar_Enable, cvar_Enable);
	AutoExecConfig(true, "plugin_sentry_limit");

	//  Catch when a player attempts to build, so we can stop them.
	RegConsoleCmd("build", Command_Build, "Restrict buildings in TF2.");
	
	//  Catch when a gun is built, so we can check limits.
	HookEvent("player_builtobject", event_Built);
	
	//  Catch when a player dies, so we can turn off the values for his engi hud.
	HookEvent("player_death", event_PlayerDeath);
	
	//  Catch when a gun's health changes, to catch when they upgrade.
	HookEntityOutput("obj_sentrygun",          "OnObjectHealthChanged", sentry_health_change);
	
	//  For displaying the number of remaining critical parts thanks for Allan Button's hphud.
	HudMessage = CreateHudSynchronizer();
}

public OnEventShutdown()
{
	UnhookEvent("player_builtobject", event_Built);
	UnhookEntityOutput("obj_sentrygun",          "OnObjectHealthChanged", sentry_health_change);
	UnhookEvent("player_death", event_PlayerDeath);
}

public OnMapStart() 
{
    CreateTimer(0.5, Timer_ShowParts, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public OnClientDisconnect(client)
{
	if ((GetConVarFloat(sl_cvar_Enable) == 1.0))
	{
		showHud[client] = true;
		showValues[client] = true;
		firstLife[client] = true;
	}
}

////Commands
public Action:Command_ShowValues(client, args)
{
	new String:arg1[32];
	
	if (args < 1)
	{
		PrintToConsole(client, "[SM] show_sentry_values requires a 1 to show the sentry level values.");
		return Plugin_Handled;
	}
	
	/* Get the first argument */
	GetCmdArg(1, arg1, sizeof(arg1));

	new value = 0;
	value = StringToInt(arg1);
	
	if (value != 1 && value != 0)
	{
		PrintToConsole(client, "[SM] show_sentry_values requires a 1 or 0 value. (1 to show, 0 to hide)");
		return Plugin_Handled;
	}
	
	firstLife[client] = false;
	showValues[client] = bool:value;
	
	return Plugin_Handled;
}

public Action:Command_ShowHud(client, args)
{
	new String:arg1[32];
	
	if (args < 1)
	{
		PrintToConsole(client, "[SM] show_sentry_hud requires a 1 to show the sentry hud.");
		return Plugin_Handled;
	}
	
	/* Get the first argument */
	GetCmdArg(1, arg1, sizeof(arg1));

	new value = 0;
	value = StringToInt(arg1);
	
	if (value != 1 && value != 0)
	{
		PrintToConsole(client, "[SM] show_sentry_values requires a 1 or 0 value. (1 to show, 0 to hide)");
		return Plugin_Handled;
	}
	
	showHud[client] = bool:value;
	
	return Plugin_Handled;
}

public Action:change_max_sentry_levels(client, args)
{
	new String:arg1[32];
	
	if (args < 1)
	{
		PrintToConsole(client, "[SM] sm_sl_max_levels requires a new level sum limit for sentries.");
		return Plugin_Handled;
	}
	
	/* Get the first argument */
	GetCmdArg(1, arg1, sizeof(arg1));

	sl_max_sentry_levels = StringToInt(arg1);

	PrintToChatAll("[SM] Teams are now limited to %d crucial part(s).", sl_max_sentry_levels);
	
	return Plugin_Handled;
}

public Action:change_sentry_values(client, args)
{
	new String:arg1[32], String:arg2[32];
	new sentry_level;
	new sentry_value;

	if (args < 1)
	{
		PrintToConsole(client, "[SM] sm_sl_sentry_value requires two parameters (The first is the sentry level, and the second is the integer value)");
		return Plugin_Handled;
	}
	
	/* Get the first argument */
	GetCmdArg(1, arg1, sizeof(arg1));

	sentry_level = StringToInt(arg1);

	/* If there are 2 or more arguments, and the second argument fetch 
	 * is successful, convert it to an integer.
	 */
	if (args >= 2 && GetCmdArg(2, arg2, sizeof(arg2)))
	{
		sentry_value = StringToInt(arg2);
	}
	else
	{
		PrintToConsole(client, "[SM] sm_sl_sentry_value requires two parameters (The first is the sentry level, and the second is the integer value)");
		return Plugin_Handled;
	}

	if (sentry_level < 1 || sentry_level > 3)
	{
		PrintToConsole(client, "[SM] First parameter %d is not valid (1, 2, or 3 for the level sentry you are modifying)", sentry_level);
		return Plugin_Handled;
	}

	if (sentry_value < 0)
	{
		PrintToConsole(client, "[SM] Second parameter %d is not valid (Must be a positive integer)", sentry_value);
		return Plugin_Handled;
	}

	PrintToChatAll("[SM] Level %d sentries now cost %d crucial part(s).", sentry_level, sentry_value);
	sl_sentry_value[sentry_level] = sentry_value;
	
	return Plugin_Handled;
}

public Action:change_upgrade_limit(client, args)
{
	new String:arg1[32];
	
	if (args < 1)
	{
		PrintToConsole(client, "[SM] sm_upgrade_limit requires a new upgrade limit for sentries at their max.");
		return Plugin_Handled;
	}
	
	/* Get the first argument */
	GetCmdArg(1, arg1, sizeof(arg1));

	new temp = StringToInt(arg1);
	
	if (temp < 0 || temp > MAX_UPGRADE_LIMIT)
	{
		PrintToConsole(client, "[SM] sm_upgrade_limit requires a limit value between 0 and %d.", MAX_UPGRADE_LIMIT);
	}

	sl_upgrade_limit = temp;
	
	PrintToChatAll("[SM] Upgrade Limit for maxed sentries now set to %d.", sl_upgrade_limit);
	
	return Plugin_Handled;
}

public cvar_Enable(Handle:convar, const String:oldValue[], const String:newValue[]) 
{
	if (strcmp(newValue, "1") == 0) 
	{
		PrintToChatAll("[SM] \x05Sentry Limit\x01 Enforced.");
	} 
	else 
	{
		PrintToChatAll("[SM] \x05Sentry Limit\x01 Disenforced.");
	}
}


////Events
public Action:event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ((GetConVarFloat(sl_cvar_Enable) == 1.0))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		new TFClassType:class = TF2_GetPlayerClass(client);
		
		if (firstLife[client] && class == TFClass_Engineer)
		{
			firstLife[client] = false;
			showValues[client] = false;
		}
	}
}

public Action:Command_Build(client, args)
{
	if ((GetConVarFloat(sl_cvar_Enable) == 1.0))
	{
		new TFClassType:class = TF2_GetPlayerClass(client);
	
		//  Ignore classes other than engineer
		if (class != TFClass_Engineer)
		{
			return Plugin_Continue;
		}
		
		new String:arg1[32];
		new temp;
				
		/* Get the first argument */
		GetCmdArg(1, arg1, sizeof(arg1));	
		temp = StringToInt(arg1);
		
		//  Only limit sentries
		if (temp != 3)
		{
			return Plugin_Continue;
		}
		
		temp = GetClientTeam(client);

		//  If you can't build a level 1...
		if (!canConstruct(calcSums(temp), 1))
		{
			PrintHintText(client, "Cannot Build!  Your team's max level sum (%d) has been reached!", sl_max_sentry_levels);
			return Plugin_Handled;
		}
		else
		{
			//  After a gun is in the process of being built, don't give refunds that are over the limit.
			refund = false;
		}
	}
	
	return Plugin_Continue;

}
  
public Action:event_Built(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ((GetConVarFloat(sl_cvar_Enable) == 1.0))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		new TFClassType:class = TF2_GetPlayerClass(client);
	
		if (class != TFClass_Engineer)
		{
			return Plugin_Handled;
		}
	
		//  After an engineer builds, don't give refunds that are over the limit.
		refund = false;
	}
	
	return Plugin_Handled;
}
  
public OnGameFrame()
{
	if ((GetConVarFloat(sl_cvar_Enable) == 1.0))
	{
		//  Check upgrade levels.
		checkAllUpgrades();
		
		refund = true;
	}
}
  
public sentry_health_change(const String:output[], caller, activator, Float:delay)
{
	if ((GetConVarFloat(sl_cvar_Enable) == 1.0))
	{
		decl String:object_name[128];
		GetEdictClassname(caller, object_name, sizeof(object_name));
		
		//  Check if sentry (And weed out unbuilt sentries)
		if (GetEntProp(caller, Prop_Send, "m_iTeamNum") >= 2 && strcmp(object_name, "obj_sentrygun") == 0)
		{
			//  Check if sentry has upgraded
			if(sentryLevel[caller] != GetEntProp(caller, Prop_Send, "m_iUpgradeLevel"))
			{
				sentryLevel[caller] = GetEntProp(caller, Prop_Send, "m_iUpgradeLevel");

				//  After a gun upgrades, don't give refunds that are over the limit.
				refund = false;
			}
		}
	}
}  

public Action:Timer_ShowParts(Handle:timer) 
{
	if ((GetConVarFloat(sl_cvar_Enable) == 1.0))
	{
		new TFClassType:class;
		new team;
		
		for (new i = 1; i <= MaxClients; i++) 
		{
			if (IsClientInGame(i) && !IsFakeClient(i) && IsPlayerAlive(i)) 
			{
				if (!showHud[i])
				{
					continue;
				}
				
				class = TF2_GetPlayerClass(i);
				
				if (class != TFClass_Engineer)
				{
					continue;
				}
				
				team = GetClientTeam(i);
				
				new rColor, gColor, bColor, tColor
				
				//  If we're out of parts, turn the hud red
				if (getSum(team) >= sl_max_sentry_levels)
				{
					rColor = 500;
					gColor = 25;
					bColor = 25;
					tColor = 255;
				}
				else
				{
					rColor = 500;
					gColor = 500;
					bColor = 500;
					tColor = 255;
				}
				
				SetHudTextParams(0.2, 0.02, 0.5, rColor, gColor, bColor, tColor);
				
				if (showValues[i])
				{
					ShowSyncHudText(i, HudMessage, "Lvl | Cost\n  1  | %d\n  2  | %d\n  3  | %d\n-------------\nTeam Parts: %d/%d", sl_sentry_value[1], sl_sentry_value[2], sl_sentry_value[3], (sl_max_sentry_levels - getSum(team)), sl_max_sentry_levels);
				}
				else
				{
					ShowSyncHudText(i, HudMessage, "Team Parts: %d/%d", (sl_max_sentry_levels - getSum(team)), sl_max_sentry_levels);
				}
			}
		}
	}

	return Plugin_Continue;
}


////Functions
stock resetSum()
{
	level_sum[0] = 0;
	level_sum[1] = 0;
}

stock addSum(team, value)
{
	level_sum[team - 2] = level_sum[team - 2] + value;
}

stock getSum(team)
{
	return level_sum[team - 2];
}

stock calcSums(teamRequest = 0)
{
	new iEnt = -1;
	new team = 0;
	resetSum();
	
	while ((iEnt = FindEntityByClassname(iEnt, "obj_sentrygun")) != -1)
	{
		team = GetEntProp(iEnt, Prop_Send, "m_iTeamNum");
		
		//  Add existing sentries
		if (team == TF_TEAM_RED || team == TF_TEAM_BLU)
		{
			addSum(team, sl_sentry_value[GetEntProp(iEnt, Prop_Send, "m_iUpgradeLevel")]);
		}
		else
		{
		//  And count non-existent ones too, or else people can prepare a sentry and build once over the limit.
			new builder = GetEntDataEnt2(iEnt, FindSendPropOffs("CObjectSentrygun","m_hBuilder"));
			addSum(GetClientTeam(builder), sl_sentry_value[GetEntProp(iEnt, Prop_Send, "m_iUpgradeLevel")]);
		}
	}

	if (teamRequest == 0)
	{
		return 0;
	}
	else
	{
		return getSum(teamRequest);
	}
}

stock calcMetal()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsClientConnected(i)) 
		{
			new TFClassType:class = TF2_GetPlayerClass(i);
		
			//  Ignore classes other than engineer
			if (class == TFClass_Engineer)
			{
				oldMetal[i] = currentMetal[i];
				currentMetal[i] = GetEntData(i, FindDataMapOffs(i, "m_iAmmo") + (3 * 4), 4);
			}
		}
	}
}

stock canConstruct(sum, level)
{
	return !(((sum - sl_sentry_value[level - 1]) + sl_sentry_value[level]) > sl_max_sentry_levels);
}

stock checkAllUpgrades()
{
	new iEnt = -1;
	new team;
	
	calcSums();
	calcMetal();
	
	while ((iEnt = FindEntityByClassname(iEnt, "obj_sentrygun")) != -1)
	{
		team = GetEntProp(iEnt, Prop_Send, "m_iTeamNum");
		
		//  Ignore unbuilt sentries, check if you can't construct the next level sentry, and if it's metal is over the limit.
		if ((team == TF_TEAM_RED || team == TF_TEAM_BLU) &&
			!canConstruct(getSum(team), GetEntProp(iEnt, Prop_Send, "m_iUpgradeLevel") + 1) && 
			GetEntProp(iEnt, Prop_Send, "m_iUpgradeMetal") > sl_upgrade_limit)
		{
			limitUpgrade(iEnt);
		}
	}
}

stock limitUpgrade(sentry)
{
	new metal;
	
	new builder = GetEntDataEnt2(sentry, FindSendPropOffs("CObjectSentrygun","m_hBuilder"));
	
	//  If giving refunds
	if (refund)
	{
		metal = (GetEntProp(sentry, Prop_Send, "m_iUpgradeMetal") - sl_upgrade_limit);
		
		//  Reset the gun's upgrade metal
		SetEntProp(sentry, Prop_Send, "m_iUpgradeMetal", sl_upgrade_limit);
		
		//  Check the builder's metal
		if (oldMetal[builder] - currentMetal[builder] == metal)
		{
			//  Warn the builder
			PrintHintText(builder, "Your team is at its sentry limit (%d)!  Upgrades limited to %d metal!", sl_max_sentry_levels, sl_upgrade_limit);
		
			//  Refund the builder
			SetEntData(builder, FindDataMapOffs(builder, "m_iAmmo") + (3 * 4), oldMetal[builder], 4, true);
		}
		else
		{
			//  If the builder didn't lose metal, he didn't upgrade the gun.  Look for the engi who did.
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && IsClientConnected(i) && IsPlayerAlive(i))
				{
					new TFClassType:class = TF2_GetPlayerClass(i);

					//  Ignore classes other than engineer and those who aren't on his team.
					if (class == TFClass_Engineer && GetClientTeam(builder) == GetClientTeam(i))
					{
						if (oldMetal[i] - currentMetal[i] == metal)
						{
							//  Warn the builder
							PrintHintText(i, "Your team is at its sentry limit (%d)!  Upgrades limited to %d metal!", sl_max_sentry_levels, sl_upgrade_limit);
								
							//  Refund the helper
							SetEntData(i, FindDataMapOffs(i, "m_iAmmo") + (3 * 4), oldMetal[i], 4, true);
							break;
						}
					}
				}
			}
		}
	}
	else
	{
		//  Reset the gun's upgrade metal
		SetEntProp(sentry, Prop_Send, "m_iUpgradeMetal", sl_upgrade_limit);
		
		//  Warn the builder
		PrintHintText(builder, "Your team is at its sentry limit (%d)!  Upgrades limited to %d metal!", sl_max_sentry_levels, sl_upgrade_limit);
	}
	

}