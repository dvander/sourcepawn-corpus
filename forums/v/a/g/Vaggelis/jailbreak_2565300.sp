#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <jailbreak>
#include <emitsoundany>
#include <smartjaildoors>

new Simon

new bool:box
new bool:freeday
new bool:special_day

new Handle:fd_timer = INVALID_HANDLE
new Handle:attack_timer = INVALID_HANDLE

public Plugin:myinfo = 
{
	name = "Jailbreak [0]",
	author = "Vaggelis",
	description = "",
	version = "1.0",
	url = ""
}

public OnPluginStart()
{
	RegConsoleCmd("sm_simon", CmdSimon)
	RegConsoleCmd("sm_menu", CmdSimonMenu)
	
	RegAdminCmd("sm_removesimon", CmdRemoveSimon, ADMFLAG_KICK)
	
	HookEvent("round_start", Event_RoundStart)
	HookEvent("player_spawn", Event_PlayerSpawn)
	HookEvent("player_death", Event_PlayerDeath)
}

public OnMapStart()
{
	PrecacheSoundAny("jailbreak/bell.mp3")
	PrecacheSoundAny("jailbreak/siren.mp3")
	
	AddFileToDownloadsTable("sound/jailbreak/bell.mp3")
	AddFileToDownloadsTable("sound/jailbreak/siren.mp3")
	
	PrecacheModel("models/player/custom_player/kuristaja/agent_smith/smith.mdl")
	PrecacheModel("models/player/custom_player/kuristaja/jailbreak/guard3/guard3.mdl")
	PrecacheModel("models/player/custom_player/kuristaja/jailbreak/prisoner3/prisoner3.mdl")
	
	AddFileToDownloadsTable("materials/models/player/kuristaja/agent_smith/shades.vtf")
	AddFileToDownloadsTable("materials/models/player/kuristaja/agent_smith/shades_normal.vtf")
	AddFileToDownloadsTable("materials/models/player/kuristaja/agent_smith/smith_arms.vmt")
	AddFileToDownloadsTable("materials/models/player/kuristaja/agent_smith/smith_arms.vtf")
	AddFileToDownloadsTable("materials/models/player/kuristaja/agent_smith/smith_arms_normal.vtf")
	AddFileToDownloadsTable("materials/models/player/kuristaja/agent_smith/smith_hands.vmt")
	AddFileToDownloadsTable("materials/models/player/kuristaja/agent_smith/smith_hands.vtf")
	AddFileToDownloadsTable("materials/models/player/kuristaja/agent_smith/smith_hands_normal.vtf")
	AddFileToDownloadsTable("materials/models/player/kuristaja/agent_smith/smithbody.vmt")
	AddFileToDownloadsTable("materials/models/player/kuristaja/agent_smith/smithbody.vtf")
	AddFileToDownloadsTable("materials/models/player/kuristaja/agent_smith/smithbody-normal.vtf")
	AddFileToDownloadsTable("materials/models/player/kuristaja/agent_smith/smithhead.vmt")
	AddFileToDownloadsTable("materials/models/player/kuristaja/agent_smith/smithhead.vtf")
	AddFileToDownloadsTable("materials/models/player/kuristaja/agent_smith/smithhead-normal.vtf")
	AddFileToDownloadsTable("materials/models/player/kuristaja/agent_smith/smithshades.vmt")
	AddFileToDownloadsTable("materials/models/player/kuristaja/agent_smith/smithshades2.vmt")
	AddFileToDownloadsTable("materials/models/player/kuristaja/agent_smith/smithshades3.vmt")
	AddFileToDownloadsTable("materials/models/player/kuristaja/agent_smith/smithshoe.vmt")
	AddFileToDownloadsTable("materials/models/player/kuristaja/agent_smith/smithshoe.vtf")
	AddFileToDownloadsTable("materials/models/player/kuristaja/agent_smith/smithshoe-normal.vtf")
	AddFileToDownloadsTable("materials/models/player/kuristaja/agent_smith/urbantemp.vmt")
	AddFileToDownloadsTable("materials/models/player/kuristaja/agent_smith/urbantemp.vtf")
	AddFileToDownloadsTable("models/player/custom_player/kuristaja/agent_smith/smith.dx90.vtx")
	AddFileToDownloadsTable("models/player/custom_player/kuristaja/agent_smith/smith.mdl")
	AddFileToDownloadsTable("models/player/custom_player/kuristaja/agent_smith/smith.phy")
	AddFileToDownloadsTable("models/player/custom_player/kuristaja/agent_smith/smith.vvd")
	
	AddFileToDownloadsTable("materials/models/player/kuristaja/jailbreak/guard3/policeman_ai_d.vmt")
	AddFileToDownloadsTable("materials/models/player/kuristaja/jailbreak/guard3/policeman_head_ai_d.vmt")
	AddFileToDownloadsTable("materials/models/player/kuristaja/jailbreak/guard3/policeman_ai_d.vtf")
	AddFileToDownloadsTable("materials/models/player/kuristaja/jailbreak/guard3/policeman_ai_normal.vtf")
	AddFileToDownloadsTable("materials/models/player/kuristaja/jailbreak/guard3/policeman_head_ai_d.vtf")
	AddFileToDownloadsTable("materials/models/player/kuristaja/jailbreak/guard3/policeman_head_ai_normal.vtf")
	AddFileToDownloadsTable("models/player/custom_player/kuristaja/jailbreak/guard3/guard3.dx90.vtx")
	AddFileToDownloadsTable("models/player/custom_player/kuristaja/jailbreak/guard3/guard3.mdl")
	AddFileToDownloadsTable("models/player/custom_player/kuristaja/jailbreak/guard3/guard3.phy")
	AddFileToDownloadsTable("models/player/custom_player/kuristaja/jailbreak/guard3/guard3.vvd")
	
	AddFileToDownloadsTable("materials/models/player/kuristaja/jailbreak/prisoner3/eyes.vmt")
	AddFileToDownloadsTable("materials/models/player/kuristaja/jailbreak/prisoner3/gi_head_14.vmt")
	AddFileToDownloadsTable("materials/models/player/kuristaja/jailbreak/prisoner3/m_white_13_co.vmt")
	AddFileToDownloadsTable("materials/models/player/kuristaja/jailbreak/prisoner3/eyes.vtf")
	AddFileToDownloadsTable("materials/models/player/kuristaja/jailbreak/prisoner3/gi_head_14.vtf")
	AddFileToDownloadsTable("materials/models/player/kuristaja/jailbreak/prisoner3/gi_head_nml.vtf")
	AddFileToDownloadsTable("materials/models/player/kuristaja/jailbreak/prisoner3/m_white_13_co.vtf")
	AddFileToDownloadsTable("materials/models/player/kuristaja/jailbreak/prisoner3/m_white_13_n.vtf")
	AddFileToDownloadsTable("models/player/custom_player/kuristaja/jailbreak/prisoner3/prisoner3.dx90.vtx")
	AddFileToDownloadsTable("models/player/custom_player/kuristaja/jailbreak/prisoner3/prisoner3.mdl")
	AddFileToDownloadsTable("models/player/custom_player/kuristaja/jailbreak/prisoner3/prisoner3.phy")
	AddFileToDownloadsTable("models/player/custom_player/kuristaja/jailbreak/prisoner3/prisoner3.vvd")
	
	AddFileToDownloadsTable("materials/models/player/kuristaja/jailbreak/shared/brown_eye01_an_d.vmt")
	AddFileToDownloadsTable("materials/models/player/kuristaja/jailbreak/shared/police_body_d.vmt")
	AddFileToDownloadsTable("materials/models/player/kuristaja/jailbreak/shared/prisoner1_body.vmt")
	AddFileToDownloadsTable("materials/models/player/kuristaja/jailbreak/shared/tex_0086_0.vmt")
	AddFileToDownloadsTable("materials/models/player/kuristaja/jailbreak/shared/brown_eye_normal.vtf")
	AddFileToDownloadsTable("materials/models/player/kuristaja/jailbreak/shared/brown_eye01_an_d.vtf")
	AddFileToDownloadsTable("materials/models/player/kuristaja/jailbreak/shared/police_body_d.vtf")
	AddFileToDownloadsTable("materials/models/player/kuristaja/jailbreak/shared/police_body_normal.vtf")
	AddFileToDownloadsTable("materials/models/player/kuristaja/jailbreak/shared/prisoner1_body.vtf")
	AddFileToDownloadsTable("materials/models/player/kuristaja/jailbreak/shared/prisoner1_body_normal.vtf")
	AddFileToDownloadsTable("materials/models/player/kuristaja/jailbreak/shared/tex_0086_0.vtf")
	AddFileToDownloadsTable("materials/models/player/kuristaja/jailbreak/shared/tex_0086_1.vtf")
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("IsFreeday", Native_IsFreeday)
	CreateNative("IsSpecialDay", Native_IsSpecialDay)

	RegPluginLibrary("jailbreak")
	
	return APLRes_Success
}

public Native_IsFreeday(Handle:plugin, numParams)
{
	return freeday
}

public Native_IsSpecialDay(Handle:plugin, numParams)
{
	return special_day
}

public OnClientDisconnect(client)
{
	if(client == Simon)
	{
		Simon = 0
		PrintCenterTextAll("Simon has left the game")
	}
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage)
}

public Action:Hook_OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if(box)
	{
		if(GetClientTeam(attacker) == 3 && GetClientTeam(victim) == 3 && attacker != victim)
		{
			damage = 0.0
			
			return Plugin_Changed
		}
	}
	
	if((!special_day || freeday) && !IsLastRequest())
	{
		if(GetClientTeam(attacker) == 2 && GetClientTeam(victim) == 3 && attacker != victim)
		{
			if(attack_timer == INVALID_HANDLE)
			{
				EmitSoundToAllAny("jailbreak/siren.mp3")
				SetEntityRenderColor(attacker, 255, 0, 0, 255)
				PrintCenterTextAll("%N attacked the Guards", attacker)
				attack_timer = CreateTimer(6.0, AttackTimerEnd)
			}
		}
	}
	
	return Plugin_Continue
}

public Action:AttackTimerEnd(Handle:timer)
{
	ClearTimer(attack_timer)
}

public Action:CmdSimon(client, args)
{
	if(GetClientTeam(client) == 3 && IsPlayerAlive(client) && Simon == 0 && !special_day)
	{
		Simon = client
		SimonMenu(client)
		PrintCenterTextAll("%N is the new Simon", client)
		SetEntityModel(client, "models/player/custom_player/kuristaja/agent_smith/smith.mdl")
	}
	else
	{
		PrintToChat(client, "[Jailbreak] You cant use this command now")
	}
}

public Action:CmdSimonMenu(client, args)
{
	if(client == Simon || GetUserFlagBits(client) & ADMFLAG_KICK)
	{
		SimonMenu(client)
	}
}

public Action:CmdRemoveSimon(client, args)
{
	RemoveSimon()
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	Simon = 0
	
	if(box)
	{
		Box()
	}
	
	freeday = false
	special_day = false
	
	ClearTimer(fd_timer)
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	
	StripWeapons(client)
	
	if(GetClientTeam(client) == 2)
	{
		SetEntityModel(client, "models/player/custom_player/kuristaja/jailbreak/prisoner3/prisoner3.mdl")
	}
	else if(GetClientTeam(client) == 3)
	{
		SetEntityModel(client, "models/player/custom_player/kuristaja/jailbreak/guard3/guard3.mdl")
	}
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	
	if(client == Simon)
	{
		Simon = 0
		CancelClientMenu(client, true)
		PrintCenterTextAll("Simon has died")
	}
}

SimonMenu(client)
{
	new Handle:menu = CreateMenu(smenu_h, MenuAction_Select | MenuAction_End)
	SetMenuTitle(menu, "Simon Menu:")
	
	AddMenuItem(menu, "item_1", "Open Cells")
	
	if(!special_day && !IsLastRequest())
	{
		AddMenuItem(menu, "item_2", "Freeday")
		
		if(box)
		{
			AddMenuItem(menu, "item_3", "Box [ON]")
			AddMenuItem(menu, "item_4", "Games", ITEMDRAW_DISABLED)
		}
		else
		{
			AddMenuItem(menu, "item_3", "Box [OFF]")
			AddMenuItem(menu, "item_4", "Games")
		}
	}
	else
	{
		AddMenuItem(menu, "item_2", "Freeday", ITEMDRAW_DISABLED)
		AddMenuItem(menu, "item_3", "Box", ITEMDRAW_DISABLED)
		AddMenuItem(menu, "item_4", "Games", ITEMDRAW_DISABLED)
	}
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER)
}

public smenu_h(Handle:menu, MenuAction:action, client, param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			new String:item[64]
			GetMenuItem(menu, param2, item, sizeof(item))

			if(StrEqual(item, "item_1"))
			{
				PrintToChatAll("[Jailbreak] %N opened the cells", client)
				SimonMenu(client)
			}
			else if(StrEqual(item, "item_2"))
			{
				FreedayMenu(client)
			}
			else if(StrEqual(item, "item_3"))
			{
				if(!box)
				{
					PrintToChatAll("[Jailbreak] %N started Box", client)
				}
				else
				{
					PrintToChatAll("[Jailbreak] %N stopped Box", client)
				}
				
				Box()
				SimonMenu(client)
			}
			else if(StrEqual(item, "item_4"))
			{
				if(box)
				{
					SimonMenu(client)
				}
				else
				{
					PrintToChat(client, "[Jailbreak] Under Construction")
				}
			}
		}
		case MenuAction_End:
		{
			CloseHandle(menu)
		}
	}
}

FreedayMenu(client)
{
	new Handle:menu = CreateMenu(fdmenu_h, MenuAction_Select | MenuAction_End)
	SetMenuTitle(menu, "Freeday Menu:")
	
	AddMenuItem(menu, "item_1", "All Players")
	AddMenuItem(menu, "item_2", "Select Player")

	DisplayMenu(menu, client, MENU_TIME_FOREVER)
}

public fdmenu_h(Handle:menu, MenuAction:action, client, param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			new String:item[64]
			GetMenuItem(menu, param2, item, sizeof(item))

			if(StrEqual(item, "item_1"))
			{
				Freeday()
				PrintHintTextToAll("Freeday for all")
				PrintToChatAll("[Jailbreak] %N started Freeday for all", client)
			}
			else if(StrEqual(item, "item_2"))
			{
				PlayerFreeday(client)
			}
		}
		case MenuAction_End:
		{
			CloseHandle(menu)
		}
	}
}

PlayerFreeday(client)
{
	new String:szName[MAX_NAME_LENGTH]
	new String:szUserID[10]
	
	new Handle:menu = CreateMenu(pfdmenu_h, MenuAction_Select | MenuAction_End)
	SetMenuTitle(menu, "Select Player:")
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			GetClientName(i, szName, sizeof(szName))
			IntToString(GetClientUserId(i), szUserID, sizeof(szUserID))
			AddMenuItem(menu, szUserID, szName)
		}
	}

	DisplayMenu(menu, client, MENU_TIME_FOREVER)
}

public pfdmenu_h(Handle:menu, MenuAction:action, client, param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			new String:item[64]
			GetMenuItem(menu, param2, item, sizeof(item))
			
			new info = StringToInt(item)
			new user_id = GetClientOfUserId(info)
			
			if(IsClientConnected(user_id) && IsPlayerAlive(user_id))
			{
				SetEntityRenderColor(user_id, 0, 255, 0, 255)
				PrintHintText(user_id, "You got Freeday")
				PrintToChatAll("[Jailbreak] %N gave Freeday to %N", client, user_id)
			}
			else
			{
				PlayerFreeday(client)
			}
		}
		case MenuAction_End:
		{
			CloseHandle(menu)
		}
	}
}

Freeday()
{
	if(box)
	{
		Box()
	}
	
	freeday = true
	special_day = true
	
	RemoveSimon()
	EmitSoundToAllAny("jailbreak/bell.mp3")
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			SetEntityRenderColor(i, 0, 255, 0, 255)
		}
	}
	
	fd_timer = CreateTimer(120.0, FreedayEnd)
}

public Action:FreedayEnd(Handle:timer)
{
	freeday = false
	special_day = false
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			SetEntityRenderColor(i, 255, 255, 255, 255)
		}
	}
	
	ClearTimer(fd_timer)
	EmitSoundToAllAny("jailbreak/bell.mp3")
	PrintToChatAll("[Jailbreak] The Freeday has ended")
}

Box()
{
	if(!box)
	{
		box = true
		
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
			{
				SetEntityHealth(i, 100)
				PrintHintText(i, "Box")
			}
		}
		
		SetConVarInt(FindConVar("mp_friendlyfire"), 1)
		SetConVarInt(FindConVar("ff_damage_reduction_bullets"), 1)
		SetConVarInt(FindConVar("ff_damage_reduction_grenade"), 1)
		SetConVarInt(FindConVar("ff_damage_reduction_grenade_self"), 1)
		SetConVarInt(FindConVar("ff_damage_reduction_other"), 1)
	}
	else
	{
		box = false
		
		SetConVarInt(FindConVar("mp_friendlyfire"), 0)
		SetConVarInt(FindConVar("ff_damage_reduction_bullets"), 0)
		SetConVarInt(FindConVar("ff_damage_reduction_grenade"), 0)
		SetConVarInt(FindConVar("ff_damage_reduction_grenade_self"), 0)
		SetConVarInt(FindConVar("ff_damage_reduction_other"), 0)
	}
}

RemoveSimon()
{
	if(Simon != 0)
	{
		CancelClientMenu(Simon, true)
		SetEntityModel(Simon, "models/player/custom_player/kuristaja/jailbreak/guard3/guard3.mdl")
		Simon = 0
	}
}

StripWeapons(client)
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
		
		GivePlayerItem(client, "weapon_knife")
	}
}

stock ClearTimer(&Handle:timer)
{
	if(timer != INVALID_HANDLE)
	{
		KillTimer(timer)
	}
	
	timer = INVALID_HANDLE
}