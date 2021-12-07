#define PL_AUTHOR "ElPapuh"
#define PL_VERSION "2.0"
//UPDATE 2.0 NOTES:
// Added Metal regen support
// Small code improvements
#define PL_DESC "A better version of HP regen"
#define PL_URL "https://jlovers.ml"
#define UPDATE_URL "https://jlovers.ml/plugins/bettherhp.txt"

#include <updater>
#include <sourcemod>
#include <morecolors>
#include <colors>

new Handle:g_HPEnabled;
new Handle:g_MetalAutoEnable;

new Handle:g_hpAmmount;
new Handle:g_MetalAmmount;

new Handle:g_hpInterval;
new Handle:g_MetalInterval;

new Handle:g_hpRegenTime[MAXPLAYERS + 1];
new Handle:g_meRegenTime[MAXPLAYERS + 1];

public Plugin myinfo =
{
	name = "Better HP regen",
	author = PL_AUTHOR,
	description = PL_DESC,
	version = PL_VERSION,
	url = PL_URL
};

public OnPluginStart()
{
	// In-game commands to cvar management
	RegAdminCmd("sm_interval", HPRegen_Interval, ADMFLAG_GENERIC, "The command to modify the interval from game");
	RegAdminCmd("sm_hpregen", HPRegen_Turn, ADMFLAG_GENERIC, "The command to turn off or on the hp regen");
	RegAdminCmd("sm_ammount", HPRegen_Ammount, ADMFLAG_GENERIC, "The command to set the ammount of hp regenerated");
	RegAdminCmd("sm_metal", MetalRegen_Ammount, ADMFLAG_GENERIC, "The command to set the ammount of metal regenerated");
	RegAdminCmd("sm_metaltime", MetalRegen_Interval, ADMFLAG_GENERIC, "The command to modify the interval of metal regen");
	RegAdminCmd("sm_metalregen", MetalRegen_Turn, ADMFLAG_GENERIC, "The command to turn off or on the metal regen");
	
	// Enable/Disable cvars
	g_HPEnabled = CreateConVar("hp_hpregen", "1", "Enable/Disable hp regen");
	g_MetalAutoEnable = CreateConVar("me_enable", "1", "Enable/Disable the metal auto regen");
	
	// Plugin cvars to control values
	g_hpAmmount = CreateConVar("hp_ammount", "5.0", "Ammount of hp that will be regenerated");
	g_MetalAmmount = CreateConVar("me_ammount", "25", "Ammount of metal that will be regenerated");
	
	// Plugin cvars to control intervals
	g_hpInterval = CreateConVar("hp_interval", "5.0", "Interval (in seconds) of hp regen");
	g_MetalInterval = CreateConVar("me_interval", "2", "Interval (in seconds) of metal regen");
	
	CreateTimer(0.5, CheckEnbaledValues, _, TIMER_REPEAT);
	
	if(GetConVarInt(g_HPEnabled) == 1)
	{
		HookEvent("player_hurt", OnPlayerDamage);
	} else if(GetConVarInt(g_HPEnabled) == 0)
			{
				CreateTimer(1.0, Timer_Check);
			}
}

public OnClientConnected(client)
{
	CreateTimer(10.0, ExecTimer, client);
}

public Action ExecTimer(Handle:timer)
{
	for(new i = 1; i <= MaxClients; i++)
	{
		g_meRegenTime[i] = CreateTimer(GetConVarFloat(g_MetalInterval), RefillInterval, i);
	}
}

public Action RefillInterval(Handle:timer, any:client)
{
	new iMaxMetal = 200;
	if(client == 0)
	{
		return Plugin_Continue;
	}
	if(client != 0 && IsClientInGame(client))
	{
		if(!IsFakeClient(client) && IsClientInGame(client) && IsPlayerAlive(client) && client != 0)
		{
			new iCurrentMetal = GetEntProp(client, Prop_Data, "m_iAmmo", 4, 3);
			
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsClientInGame(client) && IsPlayerAlive(client))
					{	
						if(GetConVarFloat(g_MetalAutoEnable) == 1)
						{
							if(iMaxMetal >= 200 && iCurrentMetal != 200 && iCurrentMetal <= iMaxMetal)
							{
								SetEntData(client, FindDataMapInfo(client, "m_iAmmo")+12, iCurrentMetal + GetConVarInt(g_MetalAmmount));
							} else
								{
									SetEntData(client, FindDataMapInfo(client, "m_iAmmo")+12, iMaxMetal);
								}
						}
						if(GetConVarFloat(g_MetalAutoEnable) == 0)
						{
							SetEntData(client, FindDataMapInfo(client, "m_iAmmo")+12, iCurrentMetal);
						}
					}
			}
		}
	}
	if(client != 0 && !IsClientInGame(client))
	{
		return Plugin_Continue;
	}
	g_meRegenTime[client] = CreateTimer(GetConVarFloat(g_MetalInterval), RefillInterval, client);
	return Plugin_Handled;
}

public Action CheckEnbaledValues(Handle:timer)
{	
	if(GetConVarInt(g_HPEnabled) != 1 && GetConVarInt(g_HPEnabled) != 0)
	{
		ServerCommand("hp_hpregen 1");
		PrintToServer("sm_hpregen 1");
		PrintToServer("[HP] The plugin has detected an issue on a cvar value, returning it to default (1)");
		PrintToServer("[HP] Issue: cvar hp_hpregen had a value that wasn't nor 1 either 0; FIXED");
		
		return Plugin_Continue;
	}
	if(GetConVarInt(g_MetalAutoEnable) != 1 && GetConVarInt(g_MetalAutoEnable) != 0)
	{
		ServerCommand("me_enable 1");
		PrintToServer("sm_metalregen 1");
		PrintToServer("[HP] The plugin has detected an issue on a cvar value, returning it to default (1)");
		PrintToServer("[HP] Issue: cvar me_enable had a value that wasn't nor 1 either 0; FIXED");
		
		return Plugin_Continue;
	}
	return Plugin_Continue;
}

public OnLibraryAdded(const String:name[])
{
    if (StrEqual(name, "updater"))
    {
        Updater_AddPlugin(UPDATE_URL);
    }
}

public Action Timer_Check(Handle:timer)
{
	if(GetConVarInt(g_HPEnabled) == 1)
	{
		HookEvent("player_hurt", OnPlayerDamage);
		CPrintToChatAll("{aqua}[{pink}HP{aqua}] {red}HP regen enabled");
	} else if(GetConVarInt(g_HPEnabled) == 0)
			{
				CreateTimer(1.0, Timer_Check);
			}
}

public OnPlayerDamage(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iUserId = GetEventInt(event, "userid");
	new clientn = GetClientOfUserId(iUserId);

	if(g_hpRegenTime[clientn] == INVALID_HANDLE)
	{
		g_hpRegenTime[clientn] = CreateTimer(GetConVarFloat(g_hpInterval), hpRegen, clientn, TIMER_REPEAT);
	}
}

public Action:hpRegen(Handle:timer, any:client)
{	
	if(IsClientInGame(client) && !IsFakeClient(client))
	{
		
		new ClientHealth = GetClientHealth(client);
		
		if(GetConVarInt(g_HPEnabled) == 0)
		{
			if(ClientHealth < GetEntProp(client, Prop_Data, "m_iMaxHealth"))
			{
				return Plugin_Continue;
			}
			else
			{
				return Plugin_Continue;
			}
		}
		
		if(GetConVarInt(g_HPEnabled) == 1)
		{
			if(ClientHealth < GetEntProp(client, Prop_Data, "m_iMaxHealth"))
			{
				SetClientHP(client, ClientHealth + GetConVarInt(g_hpAmmount));
			}
			else
			{
				SetClientHP(client, ClientHealth + 0);
				g_hpRegenTime[client] = INVALID_HANDLE;
			}
		}
	}
	
	if(!IsClientInGame(client))
	{
		return Plugin_Continue;
	}
	
	if(!IsPlayerAlive(client))
	{
		return Plugin_Continue;
	}
	
	return Plugin_Continue;
}

SetClientHP(client, amount)
{
	new HealthOffs = FindDataMapInfo(client, "m_iHealth");
	SetEntData(client, HealthOffs, amount, true);
}

public Action HPRegen_Turn(client, args)
{		
	if(client != 0)
	{
		if(GetConVarInt(g_HPEnabled) == 1)
		{
			ServerCommand("hp_hpregen 0");
			if(client != 0)
			{
				CPrintToChatAll("{aqua}[{pink}HP{aqua}] {red}HP regen disabled");
			}
			
			return Plugin_Continue;
		}
		if(GetConVarInt(g_HPEnabled) == 0)
		{
			ServerCommand("hp_hpregen 1");
			if(client != 0)
			{
				CPrintToChatAll("{aqua}[{pink}HP{aqua}] {red}HP regen enabled");
			}
			
			return Plugin_Continue;
		}
		if(GetConVarInt(g_HPEnabled) != 1 && GetConVarInt(g_HPEnabled) != 0)
		{
			ServerCommand("hp_hpregen 1");
			if(client != 0)
			{
				CPrintToChat(client, "{aqua}[{pink}HP{aqua}] {red}Can't find the cvar value, returning it to original (1 - enabled)");
			}
			
			return Plugin_Continue;
		}
	}
	if(client == 0)
	{
		if(GetConVarInt(g_HPEnabled) == 1)
		{
			ServerCommand("hp_hpregen 0");
			if(client != 0)
			{
				CPrintToChatAll("{aqua}[{pink}HP{aqua}] {red}HP regen disabled");
			}
			if(client == 0)
			{
				PrintToServer("HP regen disabled");
			}
			
			return Plugin_Continue;
		}
		if(GetConVarInt(g_HPEnabled) == 0)
		{
			ServerCommand("hp_hpregen 1");
			if(client != 0)
			{
				CPrintToChatAll("{aqua}[{pink}HP{aqua}] {red}HP regen enabled");
			}
			if(client == 0)
			{
				PrintToServer("HP regen enabled");
			}
			
			return Plugin_Continue;
		}
		if(GetConVarInt(g_HPEnabled) != 1 && GetConVarInt(g_HPEnabled) != 0)
		{
			ServerCommand("hp_hpregen 1");
			if(client != 0)
			{
				CPrintToChat(client, "{aqua}[{pink}HP{aqua}] {red}Can't find the cvar value, returning it to original (1 - enabled)");
			}
			if(client == 0)
			{
				PrintToServer("Can't find the cvar value, returning it to original (1 - enabled)");
			}
			
			return Plugin_Continue;
		}
	}
	return Plugin_Continue;
}

public Action HPRegen_Ammount(client, args)
{
	if(GetConVarInt(g_HPEnabled) == 1)
	{
		if(client != 0)
		{
			if(args != 1)
			{
				CPrintToChat(client, "{aqua}[{pink}HP{aqua}] {red}Correct usage: sm_ammount <value>");
			}
			
			if(args == 1)
			{
				new String:Ammount[5];
				
				GetCmdArg(1, Ammount, sizeof(Ammount));
			
				ServerCommand("hp_ammount %s", Ammount);
				CPrintToChatAll("{aqua}[{pink}HP{aqua}] {red}Now you'll regenerate %s of HP", Ammount);
			}
		}
		if(client == 0)
		{
			PrintToServer("[HP] That command is for players only");
		}
	}
	if(GetConVarInt(g_HPEnabled) == 0)
	{
		if(client != 0)
		{
			CPrintToChat(client, "{aqua}[{pink}HP{aqua}] {red}HP regen is disabled");
		}
		if(client == 0)
		{
			PrintToServer("HP regen is disabled and that command is for players only");
		}
	}
}

public Action HPRegen_Interval(client, args)
{
	if(GetConVarInt(g_HPEnabled) == 1)
	{
		if(client != 0)
		{
			if(args != 1)
			{
				CPrintToChat(client, "{aqua}[{pink}HP{aqua}] {red}Correct usage: sm_interval <value>");
			}
			
			if(args == 1)
			{
				new String:Interval[5];
				
				GetCmdArg(1, Interval, sizeof(Interval));
			
				ServerCommand("hp_interval %s", Interval);
				CPrintToChatAll("{aqua}[{pink}HP{aqua}] {red}Now you'll regenerate HP for every %s second", Interval);
			}
		}
		if(client == 0)
		{
			PrintToServer("[HP] That command is for players only");
		}
	}
	if(GetConVarInt(g_HPEnabled) == 0)
	{
		if(client != 0)
		{
			CPrintToChat(client, "{aqua}[{pink}HP{aqua}] {red}HP regen is disabled");
		}
		if(client == 0)
		{
			PrintToServer("HP regen is disabled and that command is for players only");
		}
	}
}

public Action MetalRegen_Ammount(client, args)
{
	if(GetConVarInt(g_MetalAutoEnable) == 1)
	{
		if(client != 0)
		{
			if(args != 1)
			{
				CPrintToChat(client, "{aqua}[{pink}HP{aqua}] {red}Correct usage: sm_metal <value>");
			}
			
			if(args == 1)
			{
				new String:Ammount[5];
				
				GetCmdArg(1, Ammount, sizeof(Ammount));
			
				ServerCommand("me_ammount %s", Ammount);
				CPrintToChatAll("{aqua}[{pink}HP{aqua}] {red}Now you'll regenerate %s of metal", Ammount);
			}
		}
		if(client == 0)
		{
			PrintToServer("[HP] That command is for players only");
		}
	}
	if(GetConVarInt(g_MetalAutoEnable) == 0)
	{
		if(client != 0)
		{
			CPrintToChat(client, "{aqua}[{pink}HP{aqua}] {red}Metal regen is disabled");
		}
		if(client == 0)
		{
			PrintToServer("Metal regen is disabled and that command is for players only");
		}
	}
}

public Action MetalRegen_Interval(client, args)
{
	if(GetConVarInt(g_MetalAutoEnable) == 1)
	{
		if(client != 0)
		{
			if(args != 1)
			{
				CPrintToChat(client, "{aqua}[{pink}HP{aqua}] {red}Correct usage: sm_metaltime <value>");
			}
			
			if(args == 1)
			{
				new String:Interval[5];
				
				GetCmdArg(1, Interval, sizeof(Interval));
			
				ServerCommand("me_interval %s", Interval);
				CPrintToChatAll("{aqua}[{pink}HP{aqua}] {red}Now you'll regenerate HP for every %s second", Interval);
			}
		}
		if(client == 0)
		{
			PrintToServer("[HP] That command is for players only");
		}
	}
	if(GetConVarInt(g_MetalAutoEnable) == 0)
	{
		if(client != 0)
		{
			CPrintToChat(client, "{aqua}[{pink}HP{aqua}] {red}Metal regen is disabled");
		}
		if(client == 0)
		{
			PrintToServer("Metal regen is disabled and that command is for players only");
		}
	}
}

public Action MetalRegen_Turn(client, args)
{	
	if(client != 0)
	{
		if(GetConVarInt(g_MetalAutoEnable) == 1)
		{
			ServerCommand("me_enable 0");
			if(client != 0)
			{
				CPrintToChatAll("{aqua}[{pink}HP{aqua}] {red}Metal regen disabled");
			}
			
			return Plugin_Continue;
		}
		if(GetConVarInt(g_MetalAutoEnable) == 0)
		{
			ServerCommand("me_enable 1");
			if(client != 0)
			{
				CPrintToChatAll("{aqua}[{pink}HP{aqua}] {red}Metal regen enabled");
			}
			
			return Plugin_Continue;
		}
		if(GetConVarInt(g_MetalAutoEnable) != 1 && GetConVarInt(g_MetalAutoEnable) != 0)
		{
			ServerCommand("me_enable 1");
			if(client != 0)
			{
				CPrintToChat(client, "{aqua}[{pink}HP{aqua}] {red}Can't find the cvar value, returning it to original (1 - enabled)");
			}
			
			return Plugin_Continue;
		}
	}
	if(client == 0)
	{
		if(GetConVarInt(g_MetalAutoEnable) == 1)
		{
			ServerCommand("me_enable 0");
			if(client != 0)
			{
				CPrintToChatAll("{aqua}[{pink}HP{aqua}] {red}Metal regen disabled");
			}
			if(client == 0)
			{
				PrintToServer("[HP] Metal regen disabled");
			}
			
			return Plugin_Continue;
		}
		if(GetConVarInt(g_MetalAutoEnable) == 0)
		{
			ServerCommand("me_enable 1");
			if(client != 0)
			{
				CPrintToChatAll("{aqua}[{pink}HP{aqua}] {red}Metal regen enabled");
			}
			if(client == 0)
			{
				PrintToServer("[HP] Metal regen enaled");
			}
			
			return Plugin_Continue;
		}
		if(GetConVarInt(g_MetalAutoEnable) != 1 && GetConVarInt(g_MetalAutoEnable) != 0)
		{
			ServerCommand("me_enable 1");
			if(client != 0)
			{
				CPrintToChat(client, "{aqua}[{pink}HP{aqua}] {red}Can't find the cvar value, returning it to original (1 - enabled)");
			}
			if(client == 0)
			{
				PrintToServer("[HP] Can't find the cvar value, returning it to original (1 - enabled)");
			}
			
			return Plugin_Continue;
		}
	}
	return Plugin_Continue;
}