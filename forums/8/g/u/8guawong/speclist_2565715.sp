#include <sdktools>
#include <clientprefs>

new Handle:HudHintTimers[MAXPLAYERS + 1];
new speclist_stealth[MAXPLAYERS + 1];
new speclist_enabled[MAXPLAYERS + 1];
new g_iSpecEnabled[MAXPLAYERS + 1];
new Handle:g_cEnabled;

public Plugin:myinfo =
{
	name = "[SM] Spectator List",
	description = "",
	author = "AllliedModder",
	version = "1.0",
	url = ""
};

public OnPluginStart()
{
	RegConsoleCmd("sm_speclist", Command_SpecList);
	RegAdminCmd("sm_stealth", Command_Stealth, ADMFLAG_KICK);
	g_cEnabled = RegClientCookie("Speclist_Enabled", "Speclist on or off", CookieAccess_Private);
	HookEvent("player_spawn", Event_Player_Spawn);
	new i = 1;
	while (i <= MaxClients)
	{
		if (IsClientConnected(i) && IsValidClient(i, false, true) && AreClientCookiesCached(i))
		{
			OnClientCookiesCached(i);
		}
		i++;
	}
}

public OnClientPostAdminCheck(client)
{
	CreateHudHintTimer(client);
}

public OnClientPutInServer(client)
{
	speclist_enabled[client] = 1;
	speclist_stealth[client] = 0;
}

public OnClientDisconnect(client)
{
	KillHudHintTimer(client);
}

public OnClientCookiesCached(client)
{
	new String:CookieEnabled[64];
	GetClientCookie(client, g_cEnabled, CookieEnabled, 64);
	g_iSpecEnabled[client] = StringToInt(CookieEnabled);
	if (g_iSpecEnabled[client] == 1)
	{
		speclist_enabled[client] = 1;
	}
	else
	{
		speclist_enabled[client] = 0;
		KillHudHintTimer(client);
	}
}

public Action:Event_Player_Spawn(Handle:event,const String:name[],bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsClientConnected(client) && IsValidClient(client, false, true) && AreClientCookiesCached(client))
		OnClientCookiesCached(client);
}

public Action:Command_Stealth(client, args)
{
	speclist_stealth[client] = !speclist_stealth[client];
	if (speclist_stealth[client] == 1)
		ReplyToCommand(client, "\x01[\x02SM\x01] You will now be hidden from speclist.");
	if (!speclist_stealth[client])
		ReplyToCommand(client, "\x01[\x02SM\x01] You will now be shown on speclist.");
}

public Action:Command_SpecList(client, args)
{
	if (speclist_enabled[client] == 1)
	{
		speclist_enabled[client] = 0;
		KillHudHintTimer(client);
		ReplyToCommand(client, "\x01[\x02SM\x01] Spectator list disabled.");
		SetClientCookie(client, g_cEnabled, "0");
	}
	else
	{
		if (!speclist_enabled[client])
		{
			speclist_enabled[client] = 1;
			CreateHudHintTimer(client);
			ReplyToCommand(client, "\x01[\x02SM\x01] Spectator list enabled.");
			SetClientCookie(client, g_cEnabled, "1");
		}
	}
}

public Action:Timer_UpdateHudHint(Handle:timer, any:client)
{
	new iSpecModeUser = GetEntProp(client, Prop_Send, "m_iObserverMode");
	new iSpecMode;
	new iTarget;
	new iTargetUser;
	new bool:bDisplayHint;
	new String:szText[2048];
	if (IsPlayerAlive(client))
	{
		new i = 1;
		while (i <= MaxClients)
		{
			if (!IsClientInGame(i) || !IsClientObserver(i))
			{
			}
			else
			{
				iSpecMode = GetEntProp(i, Prop_Send, "m_iObserverMode");
				if (!(iSpecMode != 4 && iSpecMode != 5))
				{
					iTarget = GetEntPropEnt(i, Prop_Send, "m_hObserverTarget");
					if (!(speclist_stealth[i] == 1))
					{
						if (client == iTarget)
						{
							if (IsPlayerVip(i) && speclist_stealth[i])
							{
								if (IsPlayerAdmin(i))
									Format(szText, sizeof(szText), "%s<font color='#21618C'>%N.</font> ", szText, i);
								else
									Format(szText, sizeof(szText), "%s<font color='#D4AC0D'>%N.</font> ", szText, i);
							}
							else
								Format(szText, sizeof(szText), "%s%N. ", szText, i);
							bDisplayHint = true;
						}
					}
				}
			}
			i++;
		}
	}
	else
	{
		if (iSpecModeUser == 4 || iSpecModeUser == 5)
		{
			iTargetUser = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
			new i = 1;
			while (i <= MaxClients)
			{
				if (!IsClientInGame(i) || !IsClientObserver(i))
				{
				}
				else
				{
					iSpecMode = GetEntProp(i, Prop_Send, "m_iObserverMode");
					if (!(iSpecMode != 4 && iSpecMode != 5))
					{
						iTarget = GetEntPropEnt(i, Prop_Send, "m_hObserverTarget");
						if (!(speclist_stealth[i] == 1))
						{
							if (iTargetUser == iTarget)
							{
								if (IsPlayerVip(i))
								{
									if (IsPlayerAdmin(i))
										Format(szText, sizeof(szText), "%s<font color='#21618C'>%N.</font> ", szText, i);
									else
										Format(szText, sizeof(szText), "%s<font color='#D4AC0D'>%N.</font> ", szText, i);
								}
								else
									Format(szText, sizeof(szText), "%s%N. ", szText, i);
								bDisplayHint = true;
							}
						}
					}
				}
				i++;
			}
		}
	}
	if (bDisplayHint)
	{
		if (speclist_enabled[client] == 1)
		{
			PrintHintText(client, "<font size='12'><u>Spectators:\n</u></font><font size='15'>%s</font>", szText);
			bDisplayHint = false;
		}
	}
	return Plugin_Continue;
}

stock CreateHudHintTimer(client)
{
	HudHintTimers[client] = CreateTimer(2.5, Timer_UpdateHudHint, client, TIMER_REPEAT);
}

stock KillHudHintTimer(client)
{
	if (HudHintTimers[client])
	{
		KillTimer(HudHintTimers[client]);
		HudHintTimers[client] = INVALID_HANDLE;
	}
}

stock bool:IsPlayerAdmin(client)
{
	if (IsClientInGame(client) && CheckCommandAccess(client, "sm_kick", ADMFLAG_KICK))
		return true;
	return false;
}

stock bool:IsPlayerVip(client)
{
	if (IsClientInGame(client) && CheckCommandAccess(client, "sm_kick", ADMFLAG_KICK))
		return true;
	return false;
}

stock bool:IsValidClient(client, bool:bAllowBots, bool:bAllowDead)
{
	if (client < 1 || client > MaxClients || !IsClientInGame(client) || (IsFakeClient(client) && !bAllowBots) || IsClientSourceTV(client) || IsClientReplay(client) || (!bAllowDead && !IsPlayerAlive(client)))
		return false;
	return true;
}

