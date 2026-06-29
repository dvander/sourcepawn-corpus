#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>

new Handle:gH_SlayTimer = INVALID_HANDLE;
new Handle:gH_CellsTimer = INVALID_HANDLE;
new Handle:gH_Menu = INVALID_HANDLE;
new UserMsg:g_FadeUserMsgId;
new bool:g_bRoundJustStarted = false;
new bool:g_bEnabled = false;
new g_Offset_Clip1 = -1;
new g_Offset_Ammo = -1;

#define CHAT_PREFIX "\x03[JailBreak Zombies] \x04"

public Plugin:myinfo = 
{
	name = "JailBreak Zombies",
	author = "Zonx & CoMaNdO",
	description = "CTs are Survivors, Ts are Zombies, a mini-game for Jailbreak servers",
	version = "1.00",
}

public OnPluginStart()
{
	CreateConVar("sm_jbz_opencells", "1", "Enable / Disable the automatic cell opening", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	CreateConVar("sm_jbz_opencells_delay", "60.0", "The delay for opening the cells after round start (requires sm_jbz_opencells 1)", FCVAR_PLUGIN, true, 15.0, true, 90.0);
	CreateConVar("sm_jbz_blindzombies", "1", "Blind zombies while the CTs are hiding? (uses the delay of sm_jbz_opencells_delay)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	CreateConVar("sm_jbz_zombieshealth", "500", "How much health should the zombies have?", FCVAR_PLUGIN, true, 100.0);
	CreateConVar("sm_jbz_zombiesgravity", "0.8", "The gravity of the zombies with the jumping ability (lower than 1.0)", FCVAR_PLUGIN, true, 0.05, true, 0.95);
	CreateConVar("sm_jbz_zombiesspeed", "1.2", "The speed of the zombies with the running ability (higher than 1.0)", FCVAR_PLUGIN, true, 1.1);
	CreateConVar("sm_jbz_unlimitedammo", "1", "Enable / Disable the unlimited ammo", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	CreateConVar("sm_jbz_unlimitedammo_type", "0", "Unlimited ammo type, 0 = add ammo to clip (no reload), 1 = add ammo magazines (reload required)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	AutoExecConfig(true, "sm_jbz");
	
	RegAdminCmd("sm_jbz", Command_AdminJbz, ADMFLAG_SLAY, "Turn it on.");
	
	HookEvent("round_start", RoundStart);
	HookEvent("round_end", RoundEnd);
	HookEvent("player_spawn", PlayerSpawn);
	HookEvent("player_death", PlayerDeath);
	
	gH_Menu = CreateMenu(MenuHandler);
	SetMenuTitle(gH_Menu, "Weapon Selection Menu");
	AddMenuItem(gH_Menu, "m4a1", "M4A1");
	AddMenuItem(gH_Menu, "ak47", "AK47");
	AddMenuItem(gH_Menu, "awp", "AWP");
	AddMenuItem(gH_Menu, "p90", "P90");
	AddMenuItem(gH_Menu, "m249", "M249");
	AddMenuItem(gH_Menu, "mac10", "Mac10");
	AddMenuItem(gH_Menu, "m3", "M3");
	AddMenuItem(gH_Menu, "xm1014", "XM1014");
	
	decl String:sGame[64];
	GetGameFolderName(sGame, sizeof(sGame));
	if (StrEqual(sGame, "cstrike") || StrEqual(sGame, "cstrike_beta"))
	{
		AddMenuItem(gH_Menu, "scout", "Scout");
	}
	else if (StrEqual(sGame, "csgo"))
	{
		AddMenuItem(gH_Menu, "ssg08", "SSG08");
		AddMenuItem(gH_Menu, "negev", "Negev");
		AddMenuItem(gH_Menu, "nova", "Nova");
	}
	
	g_FadeUserMsgId = GetUserMessageId("Fade");
	
	for(new idx = 1; idx <= MaxClients ; idx++)
	{
		if(IsClientInGame(idx))
		{
			SDKHook(idx, SDKHook_WeaponCanUse, OnWeaponDecideUse);
		}
	}
	
	g_Offset_Clip1 = FindSendPropOffs("CBaseCombatWeapon", "m_iClip1");
	if(g_Offset_Clip1 == -1)
	{
		SetFailState("Unable to find clip1 offset.");
	}
	
	g_Offset_Ammo = FindSendPropOffs("CCSPlayer", "m_iAmmo");
	if(g_Offset_Ammo == -1)
	{
		SetFailState("Unable to find ammo offset.");
	}
	
	CreateTimer(1.5, UnlimitedAmmo, _, TIMER_REPEAT);
}

PerformBlind(client, amount)
{
	new targets[2];
	targets[0] = client;
	
	new Handle:message = StartMessageEx(g_FadeUserMsgId, targets, 1);
	BfWriteShort(message, 1536);
	BfWriteShort(message, 1536);
	
	if(amount == 0)
	{
		BfWriteShort(message, (0x0001 | 0x0010));
	}
	else
	{
		BfWriteShort(message, (0x0002 | 0x0008));
	}
	
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, amount);
	
	EndMessage();
}

public OnMapStart()
{
	g_bEnabled = false;
}

public Action:UnlimitedAmmo(Handle:timer)
{
	if(g_bEnabled && GetConVarInt(FindConVar("sm_jbz_unlimitedammo")))
	{
		for(new i = 1; i < MaxClients; i++)
		{
			if(IsClientInGame(i) && IsPlayerAlive(i))
			{
				new WepEntity;
				for(new wep; wep < 4; wep++)
				{
					if((WepEntity = GetPlayerWeaponSlot(i, wep)) != -1)
					{
						if(!GetConVarInt(FindConVar("sm_jbz_unlimitedammo_type")))
						{
							SetEntData(WepEntity, g_Offset_Clip1, 200, 4, true);
						}
						else
						{
							new iPrimeMagOffset = GetEntProp(WepEntity, Prop_Send, "m_iPrimaryAmmoType");
							if(iPrimeMagOffset > 0)
							{
								SetEntData(i, g_Offset_Ammo + (4 * iPrimeMagOffset), 800, _, true)
							}
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action:Command_AdminJbz(client, args)
{
	if(args < 1)
	{
		if(g_bEnabled)
		{
			PrintToChatAll("%sThe plugin is currently \x03enabled.", CHAT_PREFIX);
		}
		else
		{
			PrintToChatAll("%sThe plugin is currently \x03disabled.", CHAT_PREFIX);
		}

		return Plugin_Handled;	
	}
	
	decl String:Argument[128];
	GetCmdArg(1, Argument, sizeof(Argument));
	new iArgument = StringToInt(Argument);
	if(iArgument)
	{
		g_bRoundJustStarted = true;
		PrintToChatAll("%sThe plugin has been \x03enabled.", CHAT_PREFIX);
	}
	else
	{
		for(new i = 1; i < MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				SetEntityGravity(i, 1.0);
				PerformBlind(i, 0);
			}
		}
		PrintToChatAll("%sThe plugin has been \x03disabled.", CHAT_PREFIX);
	}
	
	g_bEnabled = bool:iArgument;
	ServerCommand("mp_restartgame 1");
	
	return Plugin_Handled;
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client > 0 && IsClientInGame(client) && IsPlayerAlive(client) && g_bEnabled)
	{
		new WepEntity;
		for(new wep; wep < 4; wep++)
		{
			if((WepEntity = GetPlayerWeaponSlot(client, wep)) != -1)
			{
				RemovePlayerItem(client, WepEntity);
				AcceptEntityInput(WepEntity, "Kill");
			}
		}
		
		SetEntityGravity(client, 1.0);
		
		if(GetClientTeam(client) == CS_TEAM_T)
		{
			SetEntityHealth(client, GetConVarInt(FindConVar("sm_jbz_zombieshealth")));
			PrintToChat(client, "%sYou are now Zombie you have \x05%d \x04HP!", CHAT_PREFIX, GetConVarInt(FindConVar("sm_jbz_zombieshealth")));
			
			switch (GetRandomInt(1, 2))
			{
				case 1:
				{
					PrintToChat(client, "%sYour zombie ability is \x05jumping.", CHAT_PREFIX);
					SetEntityGravity(client, GetConVarFloat(FindConVar("sm_jbz_zombiesgravity")));
				}
				case 2:
				{
					PrintToChat(client, "%sYour zombie ability is \x05running.", CHAT_PREFIX);
					SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", GetConVarFloat(FindConVar("sm_jbz_zombiesspeed")));
				}
			}
			
			if(GetConVarInt(FindConVar("sm_jbz_blindzombies")) == 1 && gH_CellsTimer != INVALID_HANDLE)
			{
				PerformBlind(client, 255);
			}
		}
		
		SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
		
		CreateTimer(0.1, GiveWeapons, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(g_bEnabled && client > 0 && IsClientInGame(client))
	{
		SetEntityGravity(client, 1.0);
		PerformBlind(client, 0);
	}
}

public Action:RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		g_bRoundJustStarted = true;
		
		for(new i = 1; i < MaxClients; i++)
		{
			if(IsClientInGame(i))
			{
				SetEntityGravity(i, 1.0);
				PerformBlind(i, 0);
			}
		}
	}
}

public Action:RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
	{
		g_bRoundJustStarted = true;
		new Float:fFreezeTime = float(GetConVarInt(FindConVar("mp_freezetime")));
		CreateTimer(1.0 + fFreezeTime, DeleteWeapons, _, TIMER_FLAG_NO_MAPCHANGE);
		gH_CellsTimer = CreateTimer(GetConVarFloat(FindConVar("sm_jbz_opencells_delay")) + fFreezeTime, CellsTimer, _, TIMER_FLAG_NO_MAPCHANGE);
		gH_SlayTimer = CreateTimer((GetConVarInt(FindConVar("mp_roundtime")) * 60.0) + fFreezeTime, ZR_Slay, _, TIMER_FLAG_NO_MAPCHANGE);
		
		for(new i = 1; i < MaxClients; i++)
		{
			if(IsClientInGame(i) && IsPlayerAlive(i))
			{
				if(GetClientTeam(i) == CS_TEAM_T)
				{
					PerformBlind(i, 255);
				}
				SetEntProp(i, Prop_Data, "m_takedamage", 0, 1);
			}
		}
	}
}

public Action:ZR_Slay(Handle:timer)
{
	if(gH_SlayTimer != timer || gH_SlayTimer == INVALID_HANDLE || !g_bEnabled)
	{
		return Plugin_Handled;
	}
	
	gH_SlayTimer = INVALID_HANDLE;
	
	for(new client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && GetClientTeam(client) == CS_TEAM_T)
		{
			ForcePlayerSuicide(client);
		}
	}
	PrintToChatAll("%sTime is up, Terrorists have been slayed.", CHAT_PREFIX);
	return Plugin_Handled;
}

public MenuHandler(Handle:menu, MenuAction:action, client, param2)
{
	if(action == MenuAction_Select)
	{
		if(IsPlayerAlive(client) && GetClientTeam(client) == CS_TEAM_CT)
		{
			decl String:selection[64];
			decl String:selectiondisp[64];
			GetMenuItem(menu, param2, selection, sizeof(selection), _, selectiondisp, sizeof(selectiondisp));
			
			decl String:buffer[64];
			Format(buffer, sizeof(buffer), "weapon_%s", selection);
			GivePlayerItem(client, buffer);
			PrintToChat(client, "%sYou were given %s, go to hide and protect yourself!", CHAT_PREFIX, selectiondisp);
		}
	}
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponDecideUse);
}

public Action:OnWeaponDecideUse(client, weapon)
{
	if(client > 0 && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == CS_TEAM_T)
	{
		decl String:sClassname[128];
		GetEntityClassname(weapon, sClassname, sizeof(sClassname));
		
		if(StrContains(sClassname, "knife", false) == -1)
		{
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public Action:CellsTimer(Handle:timer)
{
	if(gH_CellsTimer != timer || gH_CellsTimer == INVALID_HANDLE)
	{
		return Plugin_Handled;
	}
	
	if(g_bEnabled)
	{
		if(GetConVarInt(FindConVar("sm_jbz_opencells")) == 1)
		{
			gH_CellsTimer = INVALID_HANDLE;
			
			for(new entity = 0; entity < 4096; entity++)
			{
				if(IsValidEntity(entity) || IsValidEdict(entity))
				{
					decl String:sClassname[128];
					GetEntityClassname(entity, sClassname, sizeof(sClassname));
					
					if(StrContains(sClassname, "func_door", false) != -1)
					{
						AcceptEntityInput(entity, "Open");
					}
				}
			}
			PrintToChatAll("%sTerrorists' Cells has been opened!", CHAT_PREFIX);
		}
		for(new i = 1; i < MaxClients; i++)
		{
			if(IsClientInGame(i) && IsPlayerAlive(i))
			{
				if(GetConVarInt(FindConVar("sm_jbz_blindzombies")) == 1 && GetClientTeam(i) == CS_TEAM_T)
				{
					PerformBlind(i, 0);
				}
				SetEntProp(i, Prop_Data, "m_takedamage", 2, 1);
			}
		}
	}
	return Plugin_Handled;
}

public Action:DeleteWeapons(Handle:timer)
{
	if(g_bEnabled)
	{
		for(new entity = 0; entity < 4096; entity++)
		{
			if(IsValidEntity(entity) || IsValidEdict(entity))
			{
				decl String:sClassname[128];
				GetEntityClassname(entity, sClassname, sizeof(sClassname));
				
				if(StrContains(sClassname, "weapon_", false) != -1)
				{
					AcceptEntityInput(entity, "Kill");
				}
			}
		}
		
		g_bRoundJustStarted = false;
		
		for(new i = 1; i < MaxClients; i++)
		{
			CreateTimer(0.0, GiveWeapons, i, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public Action:GiveWeapons(Handle:timer, any:client)
{
	if(g_bEnabled && !g_bRoundJustStarted && IsClientInGame(client) && IsPlayerAlive(client))
	{
		GivePlayerItem(client, "weapon_knife");
		
		if(GetClientTeam(client) == CS_TEAM_CT)
		{
			GivePlayerItem(client, "weapon_deagle");
			DisplayMenu(gH_Menu, client, 0);
		}
	}
	return Plugin_Handled;
}