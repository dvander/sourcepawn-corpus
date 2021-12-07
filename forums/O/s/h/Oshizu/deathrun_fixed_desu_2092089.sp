#include <morecolors>
#include <sdktools>
#include <tf2_stocks>

#define PLAYERCOND_SPYCLOAK (1<<4)

new Handle:DeathrunMelee
new DeathrunMeleeEnabled = false
 
new Handle:outlines
new OutlinesEnabled = false
new DeathrunEnabled = false;
 
 new Handle:dr_queue
 new Handle:dr_unbalance
 new Handle:dr_autobalance
 new Handle:dr_firstblood
 new Handle:dr_scrambleauto
 new Handle:dr_airdash
 
new dr_queue2 = 0
new dr_unbalance2 = 0
new dr_autobalance2 = 0
new dr_firstblood2 = 0
new dr_scrambleauto2 = 0
new dr_airdash2 = 0
 
 /*
 0x004#0x044#0x004#0x036#0x072# |
 0x016#0x020#0x076#0x084#0x004#0x044# |
 0x004#0x036#0x016#0x020#0x072#0x076#0x084#0x072#0x084#0x100#0x084#0x036#0x072# |
 0x076#0x032#0x004#0x036#0x044#0x056#0x060#0x072#0x084#0x100# |
 0x084#0x072#0x036#0x072#0x036#0x032#0x036#0x004#0x044#0x004#0x056#0x072#0x076#0x004#0x004#0x044#0x036#0x072#0x056#0x084#0x004#0x004#0x044#0x036#0x004#0x056#0x072#0x100# |
 0x004#0x044#0x004#0x036#0x056#0x072# |
 0x084#0x072#0x036#0x100#0x100#0x084#0x072#0x084#0x004#0x044#0x004# |
 0x004#0x044#0x004#0x044#0x004#0x004# |
 0x004# | 0x004#0x004#0x004#0x004# |
 | 0x004# |
 0x004# |
 0x032#0x056#0x060#0x060#0x056#0x036#0x080# |
 0x100#0x004#0x052#0x020#0x080#0x004#0x016#0x060#0x060#0x060#0x060#0x060#0x060#0x060#0x060# |
 0x028#
 0x032#0x004#0x044#0x004#0x072#0x036#0x016#0x020#0x032#0x004#0x044#0x004#0x036#0x016#0x020#0x072#0x032#0x076#0x004#0x004#0x044#0x036#0x016#0x020#0x072#0x076#0x084#0x072#0x084#0x072#0x036#0x084#0x084#0x036#0x072#0x100# |
 | 0x100#0x084#0x072#0x084# |
 0x032#0x056#0x056#0x036#0x060#0x004#0x020#0x052#0x004#0x072#0x016#0x020#0x044#0x028#0x036#0x056#0x060#0x080#0x080#0x084#0x056#0x004#0x100#0x056#0x016#0x004#0x056#0x060#0x060#0x060# | 
 0x032#0x060#0x060#0x036#0x072#0x084#0x092#0x004# |
 | 0x032#0x060#0x060#0x060#0x060#0x016#0x020# |
 0x072#0x084# |
 0x076#0x060#0x100#0x060#0x044#0x016#0x020#0x060#0x016#0x020#0x036#0x044#0x072#0x044#0x060#0x076#0x084#0x016#0x036# |
 0x004#0x004#0x072#0x084#0x084#0x084#0x032#0x056#0x060#0x056#0x036#0x032#0x056#0x060#0x060#0x036#0x056#0x080#0x092#0x004#0x004#0x036#0x004#0x032#0x044#0x036#0x004#0x052#0x036#0x056#0x060#0x004#0x044#0x004#0x052#0x072#0x060#0x076#0x036#0x056#0x004#0x060#0x056#0x036#0x004#0x044#0x080#0x084# |
0x100#0x084#0x072#0x084# |
 0x084#0x100#0x072#0x036# |
 | 0x084#0x100# |
 0x072#0x084# |
 0x100#0x084#0x072#0x036# |
 0x100#0x072#0x036#0x084# |
 0x084#0x072#0x084#0x100#0x084#0x072#0x036#0x100#0x072#0x036#0x084#0x100# |
 0x004#0x004#0x004#0x004#0x004#0x092#0x076#0x032#0x044#0x004#0x084#0x084#0x004#0x044#0x004# |
 0x036#0x016#0x020#0x072#0x076#0x084# | 
 
0x028#0x072#0x004#0x080#0x076# |
 0x100#0x060#0x084# |
 0x016#0x020#0x012#0x072#0x100#0x064#0x080#0x016#0x020# |
 0x024#0x036#0x072#0x076#0x080#0x048#0x004# |
 0x100#0x020#0x072#0x060#0x024# |
 0x052#0x100#0x048#0x004#0x056#0x028#0x004#0x020#0x028#0x084# | 
0x016#0x060#0x056#0x080#0x092#0x060#0x072#0x100# | 
0x060#0x048#0x056#0x100# | 0x024#0x036#0x020#0x088# | 0x020#0x024#0x048#0x080#
0x016#0x096#
0x036# | 
0x092#0x036#0x048#0x048# | 
0x028#0x036#0x088#0x020# | 0x100#0x060#0x084# 
| 0x004# | 0x032#0x036#0x056#0x080# 
| 0x028#0x020#0x052#0x020#0x060#0x036#0x004#0x012#0x048#0x032#0x060#0x012#0x072#0x076#0x004#0x020#0x072#0x004#0x060#0x080#0x016#0x020#0x012#0x072#0x064#0x076#0x020#0x012#0x016#0x056#0x020#0x060#0x080#0x084#0x092#0x100# 
 */
 
public Plugin:myinfo =
{
	name = "[TF2] Deathrun (Fixed Finally)",
	author = "Oshizu",
	version = "2.0.0",
	url = "http://www.otaku-gaming.net/"
};


public OnPluginStart()
{
	HookEvent("arena_round_start", Event_RoundStart);
	HookEvent("post_inventory_application", UpdateItems);
	HookEvent("player_spawn", PlayerSpawn)
	
	DeathrunMelee = CreateConVar("sm_deathrun_melee_only",	"0", "Disables / Enables Melee Only")
	HookConVarChange(DeathrunMelee, OnDeathrunMeleeChange)
	
	outlines = CreateConVar("sm_deathrun_outlines",	"0", "Enables / Disables ability to players from runners team be seen throught walls by outline")
	HookConVarChange(outlines, OnOutlinesChange)
	
	AddCommandListener(BlockCommand, "kill");
	AddCommandListener(BlockCommand, "explode");
	AddServerTag("deathrun");
	
	dr_queue = FindConVar("tf_arena_use_queue")
	dr_unbalance = FindConVar("mp_teams_unbalance_limit")
	dr_autobalance = FindConVar("mp_autoteambalance")
	dr_firstblood = FindConVar("tf_arena_first_blood")
	dr_scrambleauto = FindConVar("mp_scrambleteams_auto")
	dr_airdash = FindConVar("tf_scout_air_dash_count")
	
	dr_queue2 = GetConVarInt(dr_queue)
	dr_unbalance2 = GetConVarInt(dr_unbalance)
	dr_autobalance2 = GetConVarInt(dr_autobalance)
	dr_firstblood2 = GetConVarInt(dr_firstblood)
	dr_scrambleauto2 = GetConVarInt(dr_scrambleauto)
	dr_airdash2 = GetConVarInt(dr_airdash)
	
	AutoExecConfig(true, "plugin.deathrun");
}

public OnGameFrame()
{
	if(DeathrunEnabled)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && IsPlayerAlive(i))
			{
				if(GetClientTeam(i) == 2)
				{
					SetEntPropFloat(i, Prop_Send, "m_flMaxspeed", 300.0);
				}
				else if(GetClientTeam(i) == 3)
				{
					SetEntPropFloat(i, Prop_Send, "m_flMaxspeed", 500.0);
				}
				
				if(TF2_GetPlayerClass(i) == TFClass_Spy)
				{
					SetCloak(i, 1.0);
				}
			}
		}
	}
}

public OnMapStart()
{
	decl String:mapname[128];
	GetCurrentMap(mapname, sizeof(mapname));
  
	if (strncmp(mapname, "dr_", 3, false) == 0 || (strncmp(mapname, "deathrun_", 9, false) == 0) || (strncmp(mapname, "vsh_dr", 6, false) == 0) || (strncmp(mapname, "vsh_deathrun", 6, false) == 0))
	{
		LogMessage("Deathrun map detected. Enabling Deathrun Gamemode.");
		DeathrunEnabled = true;
		ServerCommand("st_gamedesc_override Deathrun v2.0.0");
		
		SetupCvars()
	}
 	else
	{
		LogMessage("Current map is not a deathrun map. Disabling Deathrun Gamemode.");
		DeathrunEnabled = false;
		
		ResetCvars()
	}
}

public OnDeathrunMeleeChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (StringToInt(newVal) < 0)
	{
		SetConVarInt(cvar, 0)
		DeathrunMeleeEnabled = false
	}
	if (StringToInt(newVal) > 1)
	{
		SetConVarInt(cvar, 1)
		DeathrunMeleeEnabled = true
	}
	if (StringToInt(newVal) == 1)
	{
		DeathrunMeleeEnabled = true
	}
	else if (StringToInt(newVal) == 0)
	{
		DeathrunMeleeEnabled = false
	}
}

public OnOutlinesChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (StringToInt(newVal) < 0)
	{
		SetConVarInt(cvar, 0)
		OutlinesEnabled = false
	}
	if (StringToInt(newVal) > 1)
	{
		SetConVarInt(cvar, 1)
		OutlinesEnabled = true
	}
	if (StringToInt(newVal) == 1)
	{
		OutlinesEnabled = true
	}
	else if (StringToInt(newVal) == 0)
	{
		OutlinesEnabled = false
	}
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(DeathrunEnabled)
	{
		BalanceTeams();
		
		new ent = -1;
		while ((ent = FindEntityByClassname(ent, "tf_wearable_demoshield")) != -1)
		{
			AcceptEntityInput(ent, "kill");
		}
	}
}

public Action:UpdateItems(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(DeathrunEnabled)
	{
		if(DeathrunMeleeEnabled)
		{
			new client = GetClientOfUserId(GetEventInt(event, "userid"));
			
			TF2_RemoveWeaponSlot(client, 0)
			TF2_RemoveWeaponSlot(client, 1)
			TF2_RemoveWeaponSlot(client, 3)
			TF2_RemoveWeaponSlot(client, 4)
			TF2_RemoveWeaponSlot(client, 5)
			TF2_SwitchtoSlot(client, TFWeaponSlot_Melee);
		}
	}
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(DeathrunEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(GetClientTeam(client) == 2)
		{
			if(OutlinesEnabled)
			{
				SetEntProp(client, Prop_Send, "m_bGlowEnabled", 1);
			}
		}
		new cond = GetEntProp(client, Prop_Send, "m_nPlayerCond");
		if (cond & PLAYERCOND_SPYCLOAK)
		{
			SetEntProp(client, Prop_Send, "m_nPlayerCond", cond | ~PLAYERCOND_SPYCLOAK);
		}
	}
}

stock BalanceTeams()
{
	if(GetClientCount(true) > 2)
	{
		if(GetClientCount(true) > 9)
		{
			new Float:Ratio;
			for(new i = 1; i <= MaxClients; i++)
			{
				Ratio = Float:GetTeamClientCount(3)/Float:GetTeamClientCount(2)
				if(Ratio<=0.33)
				{
					break;
				}
				if(IsClientInGame(i)&&GetClientTeam(i)==3)
				{
					ChangeClientTeam(i, 2);
					CPrintToChat(i, "{blue}[Deathrun]{DEFAULT} You has been moved to other team due to automatic balance.")
					CreateTimer(0.5, RespawnRebalanced, i)
				}
			}
		}
		else if(GetClientCount(true) > 5)
		{
			new Float:Ratio;
			for(new i = 1; i <= MaxClients; i++)
			{
				Ratio = Float:GetTeamClientCount(3)/Float:GetTeamClientCount(2)
				if(Ratio<=0.44)
				{
					break;
				}
				if(IsClientInGame(i)&&GetClientTeam(i)==3)
				{
					ChangeClientTeam(i, 2);
					CPrintToChat(i, "{blue}[Deathrun]{DEFAULT} You has been moved to other team due to automatic balance.")
					CreateTimer(0.5, RespawnRebalanced, i)
				}
			}
		}
		else
		{
			new Float:Ratio;
			for(new i = 1; i <= MaxClients; i++)
			{
				Ratio = Float:GetTeamClientCount(3)/Float:GetTeamClientCount(2)
				if(Ratio<=0.5)
				{
					break;
				}
				if(IsClientInGame(i)&&GetClientTeam(i)==3)
				{
					ChangeClientTeam(i, 2);
					CPrintToChat(i, "{blue}[Deathrun]{DEFAULT} You has been moved to other team due to automatic balance.")
					CreateTimer(0.5, RespawnRebalanced, i)
				}
			}
		}
	}
	else
	{
		CPrintToChatAll("{blue}[Deathrun]{DEFAULT} This gamemode requires atleast three people to start")
	}
}

stock SetupCvars()
{
	SetConVarInt(dr_queue, 0);
	SetConVarInt(dr_unbalance, 0);
	SetConVarInt(dr_autobalance, 0);
	SetConVarInt(dr_firstblood, 0);
	SetConVarInt(dr_scrambleauto, 0);
	SetConVarInt(dr_airdash, 0);
}

stock ResetCvars()
{
	SetConVarInt(dr_queue, dr_queue2);
	SetConVarInt(dr_unbalance, dr_unbalance2);
	SetConVarInt(dr_autobalance, dr_autobalance2);
	SetConVarInt(dr_firstblood, dr_firstblood2);
	SetConVarInt(dr_scrambleauto, dr_scrambleauto2);
	SetConVarInt(dr_airdash, dr_airdash2);
}

stock TF2_SwitchtoSlot(client, slot)
{
	if (slot >= 0 && slot <= 5 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		decl String:classname[64];
		new wep = GetPlayerWeaponSlot(client, slot);
		if (wep > MaxClients && IsValidEdict(wep) && GetEdictClassname(wep, classname, sizeof(classname)))
		{
			FakeClientCommandEx(client, "use %s", classname);
			SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", wep);
		}
	}
}

stock SetCloak(client, Float:value)
{
	SetEntPropFloat(client, Prop_Send, "m_flCloakMeter", value);
}

public Action:BlockCommand(client, const String:command[], args)
{
	return Plugin_Handled;
}

public Action:RespawnRebalanced(Handle:timer, any:client)
{
	if(IsClientInGame(client))
	{
		if(!IsPlayerAlive(client))
		{
			TF2_RespawnPlayer(client)
		}
	}
}