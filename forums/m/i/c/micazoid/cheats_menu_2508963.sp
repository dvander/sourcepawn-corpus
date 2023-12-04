#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <clientprefs>
#include <sdkhooks>
#include <sdktools>

char listedCheats[7][64], sSpeedHack[MAXPLAYERS+1][32], sGravityHack[MAXPLAYERS+1][32];
int iInvincible[MAXPLAYERS+1], lastSH[MAXPLAYERS+1], lastGH[MAXPLAYERS+1], iWallHack[MAXPLAYERS+1], iTeleport[MAXPLAYERS+1], iTeleportMode[MAXPLAYERS+1], iAlwaysHeadshot[MAXPLAYERS+1];
Handle savedSH, savedGH, savedInvincibility, savedWH, savedTeleport, savedTeleportMode, savedAlwaysHeadshot;

public Plugin myinfo =
{
	name = "[Any] Admin/VIP Cheats Menu",
	author = "cravenge",
	description = "Provides Menu With Cheats For Admins and VIPs.",
	version = "1.1",
	url = ""
};

public void OnPluginStart()
{
	savedWH = RegClientCookie("cm_wall_hack", "Last Wall Hack Setting", CookieAccess_Protected);
	savedSH = RegClientCookie("cm_speed_hack", "Last Speed Hack Setting", CookieAccess_Protected);
	savedGH = RegClientCookie("cm_gravity_hack", "Last Gravity Hack Setting", CookieAccess_Protected);
	savedInvincibility = RegClientCookie("cm_invincibility", "Last Invincibility Setting", CookieAccess_Protected);
	savedTeleport = RegClientCookie("cm_teleport", "Last Teleport Setting", CookieAccess_Protected);
	savedTeleportMode = RegClientCookie("cm_teleport_mode", "Last Teleport Mode Setting", CookieAccess_Protected);
	savedAlwaysHeadshot = RegClientCookie("cm_always_headshot", "Last Always Headshot Setting", CookieAccess_Protected);
	
	CreateConVar("cheats_menu_version", "1.1", "Admin/VIP Cheats Menu Version", FCVAR_NOTIFY);
	
	HookEvent("player_death", OnPlayerDeath);
	
	RegConsoleCmd("sm_cheatsmenu", DisplayCheatsMenu, "Displays Menu With Cheats");
}

public Action DisplayCheatsMenu(int client, int args)
{
	if (!IsValidClient(client) || !IsAdminOrVIP(client))
	{
		PrintToChat(client, "\x04[CM]\x01 Invalid Access!");
		return Plugin_Handled;
	}
	
	ShowCheatsMenu(client);
	return Plugin_Handled;
}

void ShowCheatsMenu(int client)
{
	Menu cheatsMenu = CreateMenu(CheatsMenuHandler);
	cheatsMenu.SetTitle("Admin/VIP Cheats Menu:");
	
	Format(listedCheats[0], 64, "Wall Hack: [%s]", (iWallHack[client] == 3) ? "All" : ((iWallHack[client] == 1) ? "Enemy" : ((iWallHack[client] == 2) ? "Ally" : "Disabled")));
	cheatsMenu.AddItem("0", listedCheats[0]);
	Format(listedCheats[1], 64, "Speed Hack: [%s]", sSpeedHack[client]);
	cheatsMenu.AddItem("1", listedCheats[1]);
	Format(listedCheats[2], 64, "Gravity Hack: [%s]", sGravityHack[client]);
	cheatsMenu.AddItem("2", listedCheats[2]);
	Format(listedCheats[3], 64, "Invincibility: [%s]", (iInvincible[client] == 1) ? "Enabled" : "Disabled");
	cheatsMenu.AddItem("3", listedCheats[3]);
	Format(listedCheats[4], 64, "Teleport: [%s]", (iTeleport[client] == 1) ? "R" : ((iTeleport[client] == 0) ? "None" : "E"));
	cheatsMenu.AddItem("4", listedCheats[4]);
	Format(listedCheats[5], 64, "Teleport Mode: [%s]", (iTeleportMode[client] == 2) ? "Enemy" : ((iTeleportMode[client] == 0) ? "All" : "Ally"));
	cheatsMenu.AddItem("5", listedCheats[5]);
	Format(listedCheats[6], 64, "Always Headshot: [%s]", (iAlwaysHeadshot[client] == 0) ? "Off" : "On");
	cheatsMenu.AddItem("6", listedCheats[6]);
	
	cheatsMenu.ExitButton = true;
	cheatsMenu.Display(client, MENU_TIME_FOREVER);
}

public int CheatsMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			switch (param2)
			{
				case 0:
				{
					switch (iWallHack[param1])
					{
						case 0:
						{
							iWallHack[param1] = 1;
							
							TranslucentWalls(true);
							for (int i = 1; i <= MaxClients; i++)
							{
								if (!IsClientInGame(i) || GetClientTeam(i) != GetClientTeam(param1))
								{
									continue;
								}
								
								SDKHook(i, SDKHook_SetTransmit, ApplyWallHack);
							}
						}
						case 1:
						{
							iWallHack[param1] = 2;
							for (int i = 1; i <= MaxClients; i++)
							{
								if (!IsClientInGame(i))
								{
									continue;
								}
								
								if (GetClientTeam(i) == GetClientTeam(param1))
								{
									SDKUnhook(i, SDKHook_SetTransmit, ApplyWallHack);
								}
								else
								{
									SDKHook(i, SDKHook_SetTransmit, ApplyWallHack);
								}
							}
						}
						case 2:
						{
							iWallHack[param1] = 3;
							for (int i = 1; i <= MaxClients; i++)
							{
								if (!IsClientInGame(i))
								{
									continue;
								}
								
								if (GetClientTeam(i) != GetClientTeam(param1))
								{
									SDKHook(i, SDKHook_SetTransmit, ApplyWallHack);
								}
							}
						}
						case 3:
						{
							iWallHack[param1] = 0;
							
							TranslucentWalls(false);
							for (int i = 1; i <= MaxClients; i++)
							{
								if (!IsClientInGame(i) || GetClientTeam(i) < 1)
								{
									continue;
								}
								
								SDKUnhook(i, SDKHook_SetTransmit, ApplyWallHack);
							}
						}
					}
					
					char sWHSetting[2];
					IntToString(iWallHack[param1], sWHSetting, 2);
					SetClientCookie(param1, savedWH, sWHSetting);
					
					ShowCheatsMenu(param1);
				}
				case 1:
				{
					switch (GetEntPropFloat(param1, Prop_Send, "m_flLaggedMovementValue"))
					{
						case 1.0:
						{
							lastSH[param1] = 1;
							Format(sSpeedHack[param1], 32, "x 1.2");
							SetEntPropFloat(param1, Prop_Send, "m_flLaggedMovementValue", 1.2);
						}
						case 1.2:
						{
							lastSH[param1] = 2;
							Format(sSpeedHack[param1], 32, "x 1.5");
							SetEntPropFloat(param1, Prop_Send, "m_flLaggedMovementValue", 1.5);
						}
						case 1.5:
						{
							lastSH[param1] = 3;
							Format(sSpeedHack[param1], 32, "x 2");
							SetEntPropFloat(param1, Prop_Send, "m_flLaggedMovementValue", 2.0);
						}
						case 2.0:
						{
							lastSH[param1] = 4;
							Format(sSpeedHack[param1], 32, "x 2.5");
							SetEntPropFloat(param1, Prop_Send, "m_flLaggedMovementValue", 2.5);
						}
						case 2.5:
						{
							lastSH[param1] = 5;
							Format(sSpeedHack[param1], 32, "x 3");
							SetEntPropFloat(param1, Prop_Send, "m_flLaggedMovementValue", 3.0);
						}
						case 3.0:
						{
							SetEntPropFloat(param1, Prop_Send, "m_flLaggedMovementValue", 1.0);
							Format(sSpeedHack[param1], 32, "x 1");
							lastSH[param1] = 0;
						}
					}
					
					char sSHSetting[2];
					IntToString(lastSH[param1], sSHSetting, 2);
					SetClientCookie(param1, savedSH, sSHSetting);
					
					ShowCheatsMenu(param1);
				}
				case 2:
				{
					switch (GetEntPropFloat(param1, Prop_Data, "m_flGravity"))
					{
						case 1.0:
						{
							lastGH[param1] = 1;
							Format(sGravityHack[param1], 32, "x 0.8");
							SetEntPropFloat(param1, Prop_Data, "m_flGravity", 0.8);
						}
						case 0.8:
						{
							lastGH[param1] = 2;
							Format(sGravityHack[param1], 32, "x 0.6");
							SetEntPropFloat(param1, Prop_Data, "m_flGravity", 0.6);
						}
						case 0.6:
						{
							lastGH[param1] = 3;
							Format(sGravityHack[param1], 32, "x 0.5");
							SetEntPropFloat(param1, Prop_Data, "m_flGravity", 0.5);
						}
						case 0.5:
						{
							lastGH[param1] = 4;
							Format(sGravityHack[param1], 32, "x 0.2");
							SetEntPropFloat(param1, Prop_Data, "m_flGravity", 0.2);
						}
						case 0.2:
						{
							lastGH[param1] = 5;
							Format(sGravityHack[param1], 32, "x 0.1");
							SetEntPropFloat(param1, Prop_Data, "m_flGravity", 0.1);
						}
						case 0.1:
						{
							SetEntPropFloat(param1, Prop_Data, "m_flGravity", 1.0);
							Format(sGravityHack[param1], 32, "x 1");
							lastGH[param1] = 0;
						}
					}
					
					char sGHSetting[2];
					IntToString(lastGH[param1], sGHSetting, 2);
					SetClientCookie(param1, savedGH, sGHSetting);
					
					ShowCheatsMenu(param1);
				}
				case 3:
				{
					switch (iInvincible[param1])
					{
						case 0:
						{
							iInvincible[param1] = 1;
							SetEntProp(param1, Prop_Data, "m_takedamage", 0, 1);
							SDKHook(param1, SDKHook_OnTakeDamage, InvincibilityFix);
						}
						case 1:
						{
							SDKUnhook(param1, SDKHook_OnTakeDamage, InvincibilityFix);
							SetEntProp(param1, Prop_Data, "m_takedamage", 2, 1);
							iInvincible[param1] = 0;
						}
					}
					
					char sInvincibilitySetting[2];
					IntToString(iInvincible[param1], sInvincibilitySetting, 2);
					SetClientCookie(param1, savedInvincibility, sInvincibilitySetting);
					
					ShowCheatsMenu(param1);
				}
				case 4:
				{
					switch (iTeleport[param1])
					{
						case 0: iTeleport[param1] = 1;
						case 1: iTeleport[param1] = 2;
						case 2: iTeleport[param1] = 0;
					}
					
					char sTeleportSetting[2];
					IntToString(iTeleport[param1], sTeleportSetting, 2);
					SetClientCookie(param1, savedTeleport, sTeleportSetting);
					
					ShowCheatsMenu(param1);
				}
				case 5:
				{
					switch (iTeleportMode[param1])
					{
						case 0: iTeleportMode[param1] = 1;
						case 1: iTeleportMode[param1] = 2;
						case 2: iTeleportMode[param1] = 0;
					}
					
					char sTeleportModeSetting[2];
					IntToString(iTeleportMode[param1], sTeleportModeSetting, 2);
					SetClientCookie(param1, savedTeleportMode, sTeleportModeSetting);
					
					ShowCheatsMenu(param1);
				}
				case 6:
				{
					switch (iAlwaysHeadshot[param1])
					{
						case 0: iAlwaysHeadshot[param1] = 1;
						case 1: iAlwaysHeadshot[param1] = 0;
					}
					
					char sAlwaysHeadshotSetting[2];
					IntToString(iAlwaysHeadshot[param1], sAlwaysHeadshotSetting, 2);
					SetClientCookie(param1, savedAlwaysHeadshot, sAlwaysHeadshotSetting);
					
					ShowCheatsMenu(param1);
				}
			}
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

public Action ApplyWallHack(int entity, int client)
{
	if (IsValidClient(client) && iWallHack[client] > 0)
	{
		return Plugin_Continue;
	}
}

public Action InvincibilityFix(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if (!IsValidClient(victim) || !IsPlayerAlive(victim))
	{
		return Plugin_Continue;
	}
	
	return Plugin_Handled;
}

public void OnClientPostAdminCheck(int client)
{
	if (IsFakeClient(client) || !IsAdminOrVIP(client))
	{
		return;
	}
	
	char sWHSetting[2], sSHSetting[2], sGHSetting[2], sInvincibilitySetting[2], sTeleportSetting[2], sTeleportModeSetting[2],
		sAlwaysHeadshotSetting[2];
	
	GetClientCookie(client, savedWH, sWHSetting, sizeof(sWHSetting));
	GetClientCookie(client, savedSH, sSHSetting, sizeof(sSHSetting));
	GetClientCookie(client, savedGH, sGHSetting, sizeof(sGHSetting));
	GetClientCookie(client, savedInvincibility, sInvincibilitySetting, sizeof(sInvincibilitySetting));
	GetClientCookie(client, savedTeleport, sTeleportSetting, sizeof(sTeleportSetting));
	GetClientCookie(client, savedTeleportMode, sTeleportModeSetting, sizeof(sTeleportModeSetting));
	GetClientCookie(client, savedAlwaysHeadshot, sAlwaysHeadshotSetting, sizeof(sAlwaysHeadshotSetting));
	
	if (strlen(sWHSetting) && strlen(sSHSetting) && strlen(sGHSetting) && strlen(sInvincibilitySetting) && strlen(sTeleportSetting) && strlen(sTeleportModeSetting) && strlen(sAlwaysHeadshotSetting))
	{
		iWallHack[client] = StringToInt(sWHSetting);
		lastSH[client] = StringToInt(sSHSetting);
		lastGH[client] = StringToInt(sGHSetting);
		iInvincible[client] = StringToInt(sInvincibilitySetting);
		iTeleport[client] = StringToInt(sTeleportSetting);
		iTeleportMode[client] = StringToInt(sTeleportModeSetting);
		iAlwaysHeadshot[client] = StringToInt(sAlwaysHeadshotSetting);
		
		CreateTimer(1.0, DelayCheatsApplied, client, TIMER_REPEAT);
	}
}

public Action DelayCheatsApplied(Handle timer, any client)
{
	if (!IsValidClient(client) || !IsValidEntity(client))
	{
		return Plugin_Continue;
	}
	
	switch (iWallHack[client])
	{
		case 0:
		{
			TranslucentWalls(false);
			for (int i = 1; i <= MaxClients; i++)
			{
				if (!IsClientInGame(i) || GetClientTeam(i) < 1)
				{
					continue;
				}
				
				SDKUnhook(i, SDKHook_SetTransmit, ApplyWallHack);
			}
		}
		case 1:
		{
			TranslucentWalls(true);
			for (int i = 1; i <= MaxClients; i++)
			{
				if (!IsClientInGame(i) || GetClientTeam(i) == GetClientTeam(client))
				{
					continue;
				}
				
				SDKHook(i, SDKHook_SetTransmit, ApplyWallHack);
			}
		}
		case 2:
		{
			TranslucentWalls(true);
			for (int i = 1; i <= MaxClients; i++)
			{
				if (!IsClientInGame(i))
				{
					continue;
				}
				
				if (GetClientTeam(i) != GetClientTeam(client))
				{
					SDKUnhook(i, SDKHook_SetTransmit, ApplyWallHack);
				}
				else
				{
					SDKHook(i, SDKHook_SetTransmit, ApplyWallHack);
				}
			}
		}
		case 3:
		{
			TranslucentWalls(true);
			for (int i = 1; i <= MaxClients; i++)
			{
				if (!IsClientInGame(i))
				{
					continue;
				}
				
				if (GetClientTeam(i) != GetClientTeam(client))
				{
					SDKHook(i, SDKHook_SetTransmit, ApplyWallHack);
				}
			}
		}
	}
	
	switch (lastSH[client])
	{
		case 0:
		{
			SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.0);
			Format(sSpeedHack[client], 32, "x 1");
		}
		case 1:
		{
			SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.2);
			Format(sSpeedHack[client], 32, "x 1.2");
		}
		case 2:
		{
			SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 1.5);
			Format(sSpeedHack[client], 32, "x 1.5");
		}
		case 3:
		{
			SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 2.0);
			Format(sSpeedHack[client], 32, "x 2");
		}
		case 4:
		{
			SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 2.5);
			Format(sSpeedHack[client], 32, "x 2.5");
		}
		case 5:
		{
			SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", 3.0);
			Format(sSpeedHack[client], 32, "x 3");
		}
	}
	
	switch (lastGH[client])
	{
		case 0:
		{
			SetEntityGravity(client, 1.0);
			Format(sGravityHack[client], 32, "x 1");
		}
		case 1:
		{
			SetEntityGravity(client, 0.8);
			Format(sGravityHack[client], 32, "x 0.8");
		}
		case 2:
		{
			SetEntityGravity(client, 0.6);
			Format(sGravityHack[client], 32, "x 0.6");
		}
		case 3:
		{
			SetEntityGravity(client, 0.5);
			Format(sGravityHack[client], 32, "x 0.5");
		}
		case 4:
		{
			SetEntityGravity(client, 0.2);
			Format(sGravityHack[client], 32, "x 0.2");
		}
		case 5:
		{
			SetEntityGravity(client, 0.1);
			Format(sGravityHack[client], 32, "x 0.1");
		}
	}
	
	switch (iInvincible[client])
	{
		case 0:
		{
			SDKUnhook(client, SDKHook_OnTakeDamage, InvincibilityFix);
			SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
		}
		case 1:
		{
			SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
			SDKHook(client, SDKHook_OnTakeDamage, InvincibilityFix);
		}
	}
	
	return Plugin_Stop;
}

void TranslucentWalls(bool apply)
{
	if (apply)
	{
		for (int i = 1; i < GetEntityCount(); i++)
		{
			if (!IsValidEntity(i) || !IsValidEdict(i))
			{
				continue;
			}
			
			char entClassname[128];
			GetEdictClassname(i, entClassname, sizeof(entClassname));
			if (StrContains(entClassname, "env", false) == -1 && StrContains(entClassname, "func", false) == -1 && StrContains(entClassname, "keyframe", false) == -1 && StrContains(entClassname, "light", false) == -1 && StrContains(entClassname, "move", false) == -1 && StrContains(entClassname, "prop", false) == -1)
			{
				continue;
			}
			
			SDKHook(i, SDKHook_SetTransmit, ApplyTranslucentWalls);
		}
	}
	else
	{
		for (int i = 1; i < GetEntityCount(); i++)
		{
			if (!IsValidEntity(i) || !IsValidEdict(i))
			{
				continue;
			}
			
			char entClassname[128];
			GetEdictClassname(i, entClassname, sizeof(entClassname));
			if (StrContains(entClassname, "env", false) == -1 && StrContains(entClassname, "func", false) == -1 && StrContains(entClassname, "keyframe", false) == -1 && StrContains(entClassname, "light", false) == -1 && StrContains(entClassname, "move", false) == -1 && StrContains(entClassname, "prop", false) == -1)
			{
				continue;
			}
			
			SDKUnhook(i, SDKHook_SetTransmit, ApplyTranslucentWalls);
			SetEntityRenderMode(i, RENDER_NORMAL);
			SetEntityRenderColor(i, 255, 255, 255, 255);
		}
	}
}

public Action ApplyTranslucentWalls(int entity, int client)
{
	if (!IsValidClient(client) || iWallHack[client] < 1)
	{
		return Plugin_Continue;
	}
	
	SetEntityRenderMode(entity, RENDER_TRANSALPHA);
	SetEntityRenderColor(entity, 255, 255, 255, 100);
	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		if (((buttons & IN_RELOAD) && iTeleport[client] == 1) || ((buttons & IN_USE) && iTeleport[client] == 2))
		{
			if (iTeleportMode[client] == 0)
			{
				int randTarget = SearchRandomTarget();
				if (randTarget != 0)
				{
					float targetPos[3];
					GetEntPropVector(randTarget, Prop_Send, "m_vecOrigin", targetPos);
					TeleportEntity(client, targetPos, NULL_VECTOR, NULL_VECTOR);
				}
			}
			else if (iTeleportMode[client] == 1)
			{
				int pickedPlayer = PickPlayer(GetClientTeam(client));
				if (pickedPlayer != 0)
				{
					float playerPos[3];
					GetEntPropVector(pickedPlayer, Prop_Send, "m_vecOrigin", playerPos);
					TeleportEntity(client, playerPos, NULL_VECTOR, NULL_VECTOR);
				}
			}
			else if (iTeleportMode[client] == 2)
			{
				int randTarget = SearchRandomTarget();
				if (randTarget != 0 && GetClientTeam(randTarget) != GetClientTeam(client))
				{
					int pickedPlayer = PickPlayer(GetClientTeam(randTarget));
					if (pickedPlayer != 0)
					{
						float playerPos[3];
						GetEntPropVector(pickedPlayer, Prop_Send, "m_vecOrigin", playerPos);
						TeleportEntity(client, playerPos, NULL_VECTOR, NULL_VECTOR);
					}
				}
			}
		}
	}
	
	return Plugin_Continue;
}

public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int causer = GetClientOfUserId(event.GetInt("attacker"));
	if (!IsValidClient(causer) || iAlwaysHeadshot[causer] == 0)
	{
		return;
	}
	
	event.SetBool("headshot", true);
}

int SearchRandomTarget()
{
	int totalPlayers[MAXPLAYERS+1], totalCount;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || GetClientTeam(i) < 2 || !IsPlayerAlive(i))
		{
			continue;
		}
		
		totalPlayers[totalCount++] = i;
	}
	
	return (totalCount == 0) ? 0 : totalPlayers[GetRandomInt(0, totalCount - 1)];
}

int PickPlayer(any team)
{
	int includedPlayers[MAXPLAYERS+1], includedCount;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || GetClientTeam(i) != team || !IsPlayerAlive(i))
		{
			continue;
		}
		
		includedPlayers[includedCount++] = i;
	}
	
	return (includedCount == 0) ? 0 : includedPlayers[GetRandomInt(0, includedCount - 1)];
}

stock bool IsValidClient(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) > 1);
}

stock bool IsAdminOrVIP(int client)
{
	return ((GetUserFlagBits(client) & ADMFLAG_GENERIC) || (GetUserFlagBits(client) & ADMFLAG_ROOT) || (GetUserFlagBits(client) & ADMFLAG_CUSTOM1) || (GetUserFlagBits(client) & ADMFLAG_CUSTOM2) || (GetUserFlagBits(client) & ADMFLAG_CUSTOM3) || (GetUserFlagBits(client) & ADMFLAG_CUSTOM4) || (GetUserFlagBits(client) & ADMFLAG_CUSTOM5) || (GetUserFlagBits(client) & ADMFLAG_CUSTOM6));
}

stock bool IsValidEnt(int entity)
{
	return (entity > 0 && IsValidEntity(entity) && IsValidEdict(entity));
}

