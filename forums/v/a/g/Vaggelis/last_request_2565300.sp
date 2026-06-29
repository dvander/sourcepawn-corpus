#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <jailbreak>

new guard
new prisoner
new selection
new guard_gun = -1
new prisoner_gun = -1

new bool:last_request

public OnPluginStart()
{
	RegConsoleCmd("sm_lr", CmdLastRequest)
	
	HookEvent("round_start", Event_RoundStart)
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("IsLastRequest", Native_IsLastRequest)

	RegPluginLibrary("jailbreak")
	
	return APLRes_Success
}

public Native_IsLastRequest(Handle:plugin, numParams)
{
	return last_request
}

public OnClientDisconnect(client)
{
	if(client == guard || client == prisoner)
	{
		guard = 0
		prisoner = 0
		guard_gun = -1
		prisoner_gun = -1
	
		last_request = false
		ServerCommand("jb_allowguns")
		
		UnhookEvent("weapon_fire", Event_WeaponFire)
		UnhookEvent("player_death", Event_PlayerDeath)
		
		if(selection > 7)
		{
			selection = 0
			SetConVarInt(FindConVar("sv_infinite_ammo"), 0)
		}
	}
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage)
}

public Action:Hook_OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if(last_request)
	{
		if((attacker == guard && victim == prisoner) || (attacker == prisoner && victim == guard))
		{
			return Plugin_Continue
		}
		else
		{
			damage = 0.0
			
			return Plugin_Changed
		}
	}
	
	return Plugin_Continue
}

public Action:CmdLastRequest(client, args)
{
	if(GetClientTeam(client) == 2 && IsPlayerAlive(client) && !last_request && (!IsSpecialDay() || IsFreeday()))
	{
		new count
		
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
			{
				count++
			}
		}
		
		if(count == 1)
		{
			LastRequestMenu(client)
		}
		else
		{
			PrintToChat(client, "Only the last alive Prisoner can use this command")
		}
	}
	else
	{
		PrintToChat(client, "You cant use this command now")
	}
}

/*
|===========================================|
|					Events					|
|===========================================|
*/

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	guard = 0
	prisoner = 0
	guard_gun = -1
	prisoner_gun = -1
	
	ServerCommand("jb_allowguns")
	
	if(last_request)
	{
		last_request = false
		UnhookEvent("weapon_fire", Event_WeaponFire)
		UnhookEvent("player_death", Event_PlayerDeath)
	}
	
	if(selection > 7)
	{
		selection = 0
		SetConVarInt(FindConVar("sv_infinite_ammo"), 0)
	}
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	
	if(client == guard || client == prisoner)
	{
		guard = 0
		prisoner = 0
		guard_gun = -1
		prisoner_gun = -1
		
		last_request = false
		ServerCommand("jb_allowguns")
		
		UnhookEvent("weapon_fire", Event_WeaponFire)
		UnhookEvent("player_death", Event_PlayerDeath)
		
		if(selection > 7)
		{
			selection = 0
			SetConVarInt(FindConVar("sv_infinite_ammo"), 0)
		}
	}
}

public Action:Event_WeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	
	new String:weapon[32]
	GetEventString(event, "weapon", weapon, sizeof(weapon))
	
	if(!(StrEqual(weapon, "weapon_knife")) && selection < 8)
	{
		if(client == guard)
		{
			SetEntProp(guard_gun, Prop_Send, "m_iPrimaryReserveAmmoCount", 1)
		}
		else if(client == prisoner)
		{
			SetEntProp(prisoner_gun, Prop_Send, "m_iPrimaryReserveAmmoCount", 1)
		}
	}
}

/*
|===========================================|
|					Menus					|
|===========================================|
*/

LastRequestMenu(client)
{
	new Handle:menu = CreateMenu(lrmenu_h, MenuAction_Select | MenuAction_End)
	SetMenuTitle(menu, "Last Request Menu:")
	
	AddMenuItem(menu, "item_1", "Deagle")
	AddMenuItem(menu, "item_2", "SSG 08")
	AddMenuItem(menu, "item_3", "MAG-7")
	AddMenuItem(menu, "item_4", "Box")
	AddMenuItem(menu, "item_5", "AWP")
	AddMenuItem(menu, "item_6", "USP-S")
	AddMenuItem(menu, "item_7", "R8 Revolver")
	AddMenuItem(menu, "item_8", "Dualies")
	AddMenuItem(menu, "item_9", "M249")
	AddMenuItem(menu, "item10", "XM1014")
	AddMenuItem(menu, "item11", "HE Grenade")

	DisplayMenu(menu, client, MENU_TIME_FOREVER)
}

public lrmenu_h(Handle:menu, MenuAction:action, client, param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			new String:item[64]
			GetMenuItem(menu, param2, item, sizeof(item))

			if(StrEqual(item, "item_1"))
			{
				selection = 1
			}
			else if(StrEqual(item, "item_2"))
			{
				selection = 2
			}
			else if(StrEqual(item, "item_3"))
			{
				selection = 3
			}
			else if(StrEqual(item, "item_4"))
			{
				selection = 4
			}
			else if(StrEqual(item, "item_5"))
			{
				selection = 5
			}
			else if(StrEqual(item, "item_6"))
			{
				selection = 6
			}
			else if(StrEqual(item, "item_7"))
			{
				selection = 7
			}
			else if(StrEqual(item, "item_8"))
			{
				selection = 8
			}
			else if(StrEqual(item, "item_9"))
			{
				selection = 9
			}
			else if(StrEqual(item, "item10"))
			{
				selection = 10
			}
			else if(StrEqual(item, "item11"))
			{
				selection = 11
			}
			
			if(selection > 7)
			{
				SetConVarInt(FindConVar("sv_infinite_ammo"), 1)
			}
			
			GuardMenu(client)
		}
		case MenuAction_End:
		{
			CloseHandle(menu)
		}
	}
}

GuardMenu(client)
{
	new String:szName[MAX_NAME_LENGTH]
	new String:szUserID[10]
	
	new Handle:menu = CreateMenu(gmenu_h, MenuAction_Select | MenuAction_End)
	SetMenuTitle(menu, "Select Player:")
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i))
		{
			GetClientName(i, szName, sizeof(szName))
			IntToString(GetClientUserId(i), szUserID, sizeof(szUserID))
			AddMenuItem(menu, szUserID, szName)
		}
	}

	DisplayMenu(menu, client, MENU_TIME_FOREVER)
}

public gmenu_h(Handle:menu, MenuAction:action, client, param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			new String:item[64]
			GetMenuItem(menu, param2, item, sizeof(item))
			
			new info = StringToInt(item)
			new user_id = GetClientOfUserId(info)
			
			if(GetClientTeam(client) == 2 && IsPlayerAlive(client) && !last_request && (!IsSpecialDay() || IsFreeday()))
			{
				new count
				
				for(new i = 1; i <= MaxClients; i++)
				{
					if(IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
					{
						count++
					}
				}
		
				if(count == 1)
				{
					if(IsClientConnected(user_id) && IsPlayerAlive(user_id))
					{
						guard = user_id
						prisoner = client
						
						last_request = true
						
						HookEvent("weapon_fire", Event_WeaponFire)
						HookEvent("player_death", Event_PlayerDeath)
						
						switch(selection)
						{
							case 1:
							{
								LR_Deagle()
							}
							case 2:
							{
								LR_SSG()
							}
							case 3:
							{
								LR_MAG7()
							}
							case 4:
							{
								LR_Box()
							}
							case 5:
							{
								LR_AWP()
							}
							case 6:
							{
								LR_USP()
							}
							case 7:
							{
								LR_Revolver()
							}
							case 8:
							{
								LR_Dualies()
							}
							case 9:
							{
								LR_M249()
							}
							case 10:
							{
								LR_XM1014()
							}
							case 11:
							{
								LR_HE()
							}
						}
					}
					else
					{
						LastRequestMenu(client)
					}
				}
			}
		}
		case MenuAction_End:
		{
			CloseHandle(menu)
		}
	}
}

/*
|===============================================|
|					Functions					|
|===============================================|
*/

LR_Deagle()
{
	ServerCommand("jb_blockguns")
	ServerCommand("jb_removeguns")
	
	PreparePlayer(guard, 100, "weapon_deagle")
	PreparePlayer(prisoner, 100, "weapon_deagle")
}

LR_SSG()
{
	ServerCommand("jb_blockguns")
	ServerCommand("jb_removeguns")
	
	PreparePlayer(guard, 100, "weapon_ssg08")
	PreparePlayer(prisoner, 100, "weapon_ssg08")
}

LR_MAG7()
{
	ServerCommand("jb_blockguns")
	ServerCommand("jb_removeguns")
	
	PreparePlayer(guard, 100, "weapon_mag7")
	PreparePlayer(prisoner, 100, "weapon_mag7")
}

LR_Box()
{
	ServerCommand("jb_blockguns")
	ServerCommand("jb_removeguns")
	
	PreparePlayer_RE(guard, 100)
	PreparePlayer_RE(prisoner, 100)
}

LR_AWP()
{
	ServerCommand("jb_blockguns")
	ServerCommand("jb_removeguns")
	
	PreparePlayer(guard, 100, "weapon_awp")
	PreparePlayer(prisoner, 100, "weapon_awp")
}

LR_USP()
{
	ServerCommand("jb_blockguns")
	ServerCommand("jb_removeguns")
	
	PreparePlayer(guard, 100, "weapon_usp_silencer")
	PreparePlayer(prisoner, 100, "weapon_usp_silencer")
}

LR_Revolver()
{
	ServerCommand("jb_blockguns")
	ServerCommand("jb_removeguns")
	
	PreparePlayer(guard, 100, "weapon_revolver")
	PreparePlayer(prisoner, 100, "weapon_revolver")
}

LR_Dualies()
{
	ServerCommand("jb_blockguns")
	ServerCommand("jb_removeguns")
	
	PreparePlayer(guard, 800, "weapon_elite")
	PreparePlayer(prisoner, 800, "weapon_elite")
}

LR_M249()
{
	ServerCommand("jb_blockguns")
	ServerCommand("jb_removeguns")
	
	PreparePlayer(guard, 2000, "weapon_m249")
	PreparePlayer(prisoner, 2000, "weapon_m249")
}

LR_XM1014()
{
	ServerCommand("jb_blockguns")
	ServerCommand("jb_removeguns")
	
	PreparePlayer(guard, 2000, "weapon_xm1014")
	PreparePlayer(prisoner, 2000, "weapon_xm1014")
}

LR_HE()
{
	ServerCommand("jb_blockguns")
	ServerCommand("jb_removeguns")
	
	PreparePlayer_RE(guard, 100)
	PreparePlayer_RE(prisoner, 100)
	
	GivePlayerItem(guard, "weapon_hegrenade")
	GivePlayerItem(prisoner, "weapon_hegrenade")
}

PreparePlayer(client, health, String:weapon[])
{
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		for(new i = 0; i < 4; i++)
		{
			new ent
			
			while((ent = GetPlayerWeaponSlot(client, i)) != -1)
			{
				RemovePlayerItem(client, ent)
				AcceptEntityInput(ent, "Kill")
			}
			
			if((ent = GetPlayerWeaponSlot(client, 2)) != -1)
			{
				RemovePlayerItem(client, ent)
				AcceptEntityInput(ent, "Kill")
			}
		}
		
		SetEntityHealth(client, health)
		GivePlayerItem(client, "weapon_knife")
		GivePlayerItem(client, "item_assaultsuit")
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0)
		
		if(GetClientTeam(client) == 3)
		{
			guard_gun = GivePlayerItem(client, weapon)
			SetEntProp(guard_gun, Prop_Send, "m_iPrimaryReserveAmmoCount", 0)
			SetEntProp(guard_gun, Prop_Send, "m_iClip1", 1)
			SetEntityRenderColor(client, 0, 0, 255, 255)
		}
		else if(GetClientTeam(client) == 2)
		{
			prisoner_gun = GivePlayerItem(client, weapon)
			SetEntProp(prisoner_gun, Prop_Send, "m_iPrimaryReserveAmmoCount", 0)
			SetEntProp(prisoner_gun, Prop_Send, "m_iClip1", 1)
			SetEntityRenderColor(client, 255, 0, 0, 255)
		}
	}
}

PreparePlayer_RE(client, health)
{
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		for(new i = 0; i < 4; i++)
		{
			new ent
			
			while((ent = GetPlayerWeaponSlot(client, i)) != -1)
			{
				RemovePlayerItem(client, ent)
				AcceptEntityInput(ent, "Kill")
			}
			
			if((ent = GetPlayerWeaponSlot(client, 2)) != -1)
			{
				RemovePlayerItem(client, ent)
				AcceptEntityInput(ent, "Kill")
			}
		}
		
		SetEntityHealth(client, health)
		GivePlayerItem(client, "weapon_knife")
		GivePlayerItem(client, "item_assaultsuit")
		SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", 1.0)
		
		if(GetClientTeam(client) == 3)
		{
			SetEntityRenderColor(client, 0, 0, 255, 255)
		}
		else if(GetClientTeam(client) == 2)
		{
			SetEntityRenderColor(client, 255, 0, 0, 255)
		}
	}
}