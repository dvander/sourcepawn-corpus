#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

new Handle:g_Cvar_CTC4;
new Handle:g_Cvar_Plant;
new Handle:g_Cvar_Bonus;
new Handle:g_Cvar_Penalty;
new Handle:g_Cvar_Health;
new Handle:g_Timer_ForceAbort = INVALID_HANDLE;
new bool:g_AllowPickup = true;
new bool:g_AllowPlant = true;
new g_Planter = 0;
new g_Winner = CS_TEAM_NONE;
new g_Carrier = 0;
new g_EntityC4 = -1;
new String:g_C4Modle[] = "models/weapons/w_c4.mdl";

public Plugin:myinfo =
{
	name = "CTC4",
	author = "bigbalaboom",
	description = "Allows CTs to pickup/drop/plant the C4, and changes the gameplay with a new C4 rule.",
	version = "3.0.0",
	url = "www.sourcemod.net"
}

public OnPluginStart()
{
	g_Cvar_CTC4	= CreateConVar("sm_ctc4",		"1",	"Enables/disables CTC4 plugin.");
	g_Cvar_Plant	= CreateConVar("sm_ctc4_plant",		"1",	"Enables/disables CTs to plant the C4.");
	g_Cvar_Bonus	= CreateConVar("sm_ctc4_cash_bonus",	"3250",	"Amount of money given to the winning team.");
	g_Cvar_Penalty	= CreateConVar("sm_ctc4_cash_penalty",	"5000",	"Amount of money taken from the losing team.");
	g_Cvar_Health	= CreateConVar("sm_ctc4_hp_penalty",	"70",	"Amount of health for punishing the losing CT planter.");
	AutoExecConfig(true, "ctc4");

	HookEvent("round_start",	Event_RoundStart);
	HookEvent("player_death",	Event_PlayerDeath);
	HookEvent("bomb_dropped",	Event_Dropped);
	HookEvent("bomb_beginplant",	Event_BeginPlant);
	HookEvent("bomb_planted",	Event_Planted);
	HookEvent("bomb_begindefuse",	Event_BeginDefuse);
	HookEvent("bomb_exploded",	Event_Exploded);
	HookEvent("bomb_defused",	Kill_Timer);
	HookEvent("bomb_abortdefuse",	Kill_Timer);

	HookConVarChange(g_Cvar_CTC4, OnConVarChange);

	HookUserMessage(GetUserMessageId("TextMsg"), TextMsg, true);

	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			SDKHook(i, SDKHook_Touch, OnTouch);
			SDKHook(i, SDKHook_WeaponEquip, OnWeaponEquip);
			SDKHook(i, SDKHook_WeaponSwitch, OnWeaponSwitch);
		}
	}
}

public OnMapStart()
{
	PrecacheModel(g_C4Modle);
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_Touch, OnTouch);
	SDKHook(client, SDKHook_WeaponEquip, OnWeaponEquip);
	SDKHook(client, SDKHook_WeaponSwitch, OnWeaponSwitch); 
}

public OnConVarChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if (StrEqual(newvalue, "0") && g_Carrier)
	{
		new c4;
		if ((c4 = GetPlayerWeaponSlot(g_Carrier, _:4)) != -1)
		{
			CS_DropWeapon(g_Carrier, c4, false);
			AcceptEntityInput(g_EntityC4, "Kill"); 
			g_Carrier = 0;
			g_EntityC4 = -1;
		}
	}
}

public Action:TextMsg(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	if (CTC4_Enabled() && IsClientInGame(players[0]) && GetClientTeam(players[0]) == CS_TEAM_CT)
	{
		decl String:buffer[64];
		BfReadString(bf, buffer, sizeof(buffer), false);
		if ((!GetConVarBool(g_Cvar_Plant) && (StrContains(buffer, "C4_Plant_At_Bomb_Spot") != -1 || StrContains(buffer, "C4_Plant_Must_Be_On_Ground") != -1)) || (g_Planter && StrContains(buffer, "C4_Defuse_Must_Be_On_Ground") != -1))
		{
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_Winner)
	{
		new bonus = GetConVarInt(g_Cvar_Bonus);
		new penalty = GetConVarInt(g_Cvar_Penalty);
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				new player_team;
				if(i == g_Planter)
				{
					player_team = CS_TEAM_CT;
				}
				else
				{
					player_team = GetClientTeam(i);
				}

				new current_money = GetEntProp(i, Prop_Send, "m_iAccount");
				if ((g_Winner == CS_TEAM_T && player_team == CS_TEAM_T) || (g_Winner == CS_TEAM_CT && player_team == CS_TEAM_CT))
				{
					SetEntProp(i, Prop_Send, "m_iAccount", current_money + bonus + 3250 >= 16000 ? 16000 : current_money + bonus + 3250);
				}
				if (g_Winner == CS_TEAM_T && player_team == CS_TEAM_CT)
				{
					SetEntProp(i, Prop_Send, "m_iAccount", current_money - penalty - 1400 <= 0 ? 0 : current_money - penalty - 1400);
				}
			}
		}

		if (g_Winner == CS_TEAM_T && g_Planter && IsClientInGame(g_Planter) && IsPlayerAlive(g_Planter))
		{
			CreateTimer(0.2, Timer_Slap, g_Planter, TIMER_REPEAT);
		}
	}

	g_Planter = 0;
	g_AllowPlant = true;
	g_Winner = CS_TEAM_NONE;
	g_Carrier = 0;
	g_EntityC4 = -1;
}

public Action:Timer_Slap(Handle:timer, any:client)
{
	static slapped_health = 0;

	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		new current_health = GetEntProp(client, Prop_Send, "m_iHealth");
		new health_to_slap = GetConVarInt(g_Cvar_Health);
		if (current_health > 1 && slapped_health < health_to_slap)
		{
			if (current_health - 5 <= 0)
			{
				SlapPlayer(client, current_health - 1, true);
				slapped_health += current_health - 1;
			}
			else
			{
				SlapPlayer(client, 5, true);
				slapped_health += 5;
			}
		}

		if (slapped_health >= health_to_slap || current_health == 1)
		{
			slapped_health = 0;
			return Plugin_Stop;
		}
	}
	return Plugin_Handled;
}

public Action:CS_OnTerminateRound(&Float:delay, &CSRoundEndReason:reason)
{
	g_AllowPlant = false;
	if (g_Planter && reason == CSRoundEnd_TerroristWin)
	{
		g_Winner = CS_TEAM_T;
	}
}

Get_Alive_Terrorists()
{
	new alive_ts = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_T)
		{
			alive_ts++;
		}
	}
	return alive_ts;
}

public Event_Exploded(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	KT(client, true);

	if (CTC4_Enabled() && g_Planter && Get_Alive_Terrorists())
	{
		g_Winner = CS_TEAM_T;
	}
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client == g_Carrier && IsValidEdict(g_EntityC4))
	{
		AcceptEntityInput(g_EntityC4, "Kill"); 
		g_Carrier = 0;
		g_EntityC4 = -1;
	}

	if (CTC4_Enabled() && g_Planter && !g_Winner)
	{
		if (!Get_Alive_Terrorists())
		{
			g_Winner = CS_TEAM_CT;

			new ScoreCT = GetTeamScore(CS_TEAM_CT);
			CS_SetTeamScore(CS_TEAM_CT, ScoreCT + 1);
			SetTeamScore(CS_TEAM_CT, ScoreCT + 1);

			CS_TerminateRound(5.0, CSRoundEnd_CTWin);
		}
	}
}

AttachModelC4(client)
{
	new String:ParentName[64];
	Format(ParentName, sizeof(ParentName), "client%i", client);
	DispatchKeyValue(client, "targetname", ParentName);

	g_EntityC4 = CreateEntityByName("prop_dynamic_override");

	new String:EntityName[64];
	Format(EntityName, sizeof(EntityName), "prop_dynamic_ctc4_%i", g_EntityC4);

	DispatchKeyValue(g_EntityC4, "disableshadows", "1");
	DispatchKeyValue(g_EntityC4, "targetname", EntityName);
	DispatchKeyValue(g_EntityC4, "parentname", ParentName);
	DispatchKeyValue(g_EntityC4, "model", g_C4Modle);
	DispatchKeyValue(g_EntityC4, "solid", "0");
	SetEntityModel(g_EntityC4, g_C4Modle);
	DispatchSpawn(g_EntityC4);

	SetVariantString(ParentName);
	AcceptEntityInput(g_EntityC4, "SetParent", g_EntityC4, g_EntityC4, 0);

	SetVariantString("primary");
	AcceptEntityInput(g_EntityC4, "SetParentAttachment", g_EntityC4, g_EntityC4, 0);

	AcceptEntityInput(g_EntityC4, "TurnOn");

	new Float:position[3] = {0.0, 3.3, 3.0};
	new Float:angle[3] = {-52.0, -74.0, -34.0};
	TeleportEntity(g_EntityC4, position, angle, NULL_VECTOR);
}

public OnTouch(client, weapon)
{
	if (CTC4_Enabled() && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == CS_TEAM_CT && IsValidEdict(weapon))
	{
		decl String:weapon_name[64];
		GetEdictClassname(weapon, weapon_name, sizeof(weapon_name));
		if (StrContains(weapon_name, "weapon_c4") != -1 && g_AllowPickup)
		{
			SetEntProp(client, Prop_Send, "m_iTeamNum", CS_TEAM_T);
			AcceptEntityInput(weapon, "Kill"); 
			GivePlayerItem(client, "weapon_c4");
			SetEntProp(client, Prop_Send, "m_iTeamNum", CS_TEAM_CT);

			g_Carrier = client;
			new active_weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			decl String:active_weapon_name[64];
			GetEdictClassname(active_weapon, active_weapon_name, sizeof(active_weapon_name));
			if (!StrEqual(active_weapon_name, "weapon_c4"))
			{
				AttachModelC4(client);
			}

			decl String:player_name[MAX_NAME_LENGTH];
			GetClientName(client, player_name, sizeof(player_name));
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && GetClientTeam(i) == CS_TEAM_CT)
				{
					PrintToChat(i, "\x04[CTC4] %s%s \x01picked up the bomb.", "\x079ACDFF", player_name);
				}
			}
		}
	}
}

// this only happens on GivePlayerItem(client, "weapon_c4");
public Action:OnWeaponEquip(client, weapon)
{
	if (CTC4_Enabled())
	{
		new Handle:pack;
		CreateDataTimer(0.2, Timer_CheckTeam, pack);
		WritePackCell(pack, client);
		WritePackCell(pack, weapon);
	}
}

public Action:Timer_CheckTeam(Handle:timer, Handle:pack)
{
	ResetPack(pack);
	new client = ReadPackCell(pack);
	new weapon = ReadPackCell(pack);

	if (IsClientInGame(client) && GetClientTeam(client) == CS_TEAM_CT && IsValidEdict(weapon))
	{
		decl String:equipped_weapon[32];
		GetEdictClassname(weapon, equipped_weapon, sizeof(equipped_weapon));
		if (StrEqual(equipped_weapon, "weapon_c4"))
		{
			g_Carrier = client;
			new active_weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			decl String:active_weapon_name[64];
			GetEdictClassname(active_weapon, active_weapon_name, sizeof(active_weapon_name));
			if (!StrEqual(active_weapon_name, "weapon_c4") && g_EntityC4 == -1)
			{
				AttachModelC4(client);
			}
		}
	}
}

public Action:OnWeaponSwitch(client, weapon)
{
	if (CTC4_Enabled() && IsClientInGame(client) && GetClientTeam(client) == CS_TEAM_CT && client == g_Carrier)
	{
		decl String:switched_weapon[32];
		GetEdictClassname(weapon, switched_weapon, sizeof(switched_weapon));
		if(IsValidEdict(g_EntityC4))
		{
			SetEntityRenderMode(g_EntityC4, RENDER_TRANSCOLOR);
			if (StrEqual(switched_weapon, "weapon_c4"))
			{
				SetEntityRenderColor(g_EntityC4, _, _, _, 0);
			}
			else
			{
				SetEntityRenderColor(g_EntityC4, _, _, _, 255);
			}
		}
	}
}

public Action:Event_Dropped(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (CTC4_Enabled())
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if (client && GetClientTeam(client) == CS_TEAM_CT)
		{
			g_AllowPickup = false;
			CreateTimer(0.5, Timer_EnablePickup);

			if(client == g_Carrier)
			{
				if(IsValidEdict(g_EntityC4))
				{
					AcceptEntityInput(g_EntityC4, "Kill"); 
					g_EntityC4 = -1;
				}
				g_Carrier = 0;
			}

			decl String:player_name[MAX_NAME_LENGTH];
			GetClientName(client, player_name, sizeof(player_name));

			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && GetClientTeam(i) == CS_TEAM_CT)
				{
					PrintToChat(i, "\x04[CTC4] %s%s \x01dropped the bomb.", "\x079ACDFF", player_name);
				}
			}
		}
	}
}

public Action:Timer_EnablePickup(Handle:timer)
{
	g_AllowPickup = true;
}

public Action:Event_BeginPlant(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (CTC4_Enabled())
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if (GetClientTeam(client) == CS_TEAM_CT && (!GetConVarBool(g_Cvar_Plant) || !g_AllowPlant))
		{
			if (!GetConVarBool(g_Cvar_Plant))
			{
				PrintCenterText(client, "Only terrorists can plant the bomb.");
			}
			else
			{
				PrintCenterText(client, "Bomb is not allowed to be planted at this moment.");
			}

			ClientCommand(client, "slot3");
		}
	}
}

public Action:Event_Planted(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (CTC4_Enabled())
	{
		g_Carrier = 0;

		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if (GetClientTeam(client) == CS_TEAM_CT)
		{
			g_Planter = client;
			PrintCenterTextAll("A counter-terrorist has planted the bomb.");

			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i))
				{
					if (GetClientTeam(i) == CS_TEAM_T)
					{
						PrintToChat(i, "\x04[CTC4] \x01At least one terrorist must survive to win this round.");
					}
					else
					{
						PrintToChat(i, "\x04[CTC4] \x01All terrorists must be eliminated to win this round.");
					}
				}
			}
		}
	}
}

public Action:Event_BeginDefuse(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (CTC4_Enabled() && g_Planter)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		g_Timer_ForceAbort = CreateTimer(GetRandomFloat(0.5, GetEntProp(client, Prop_Send, "m_bHasDefuser") ? 4.8 : 9.8), Timer_ForceAbort, any:client);
	}
}

public Action:Timer_ForceAbort(Handle:timer, any:client)
{
	SetEntProp(client, Prop_Send, "m_fFlags", FL_FLY);
	PrintToChat(client, "\x04[CTC4] \x01You have entered a wrong passcode.");
	KT(client, false);
}

public Action:Kill_Timer(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	KT(client, true);
}

KT(client, set_flag)
{
	if (g_Timer_ForceAbort != INVALID_HANDLE)
	{
		if (set_flag)
		{
			SetEntProp(client, Prop_Send, "m_fFlags", FL_ONGROUND);
		}
		KillTimer(g_Timer_ForceAbort);
		g_Timer_ForceAbort = INVALID_HANDLE;
	}
}

CTC4_Enabled()
{
	decl String:map[64];
	GetCurrentMap(map, sizeof(map));
	if(GetConVarBool(g_Cvar_CTC4) && strncmp(map, "de_", 3, false) == 0)
	{
		return true;
	}
	return false;
}