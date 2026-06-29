#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "0.0.1"

#define HEGRENADE 11
#define FLASHBANG 12
#define SMOKEGREN 13
#define HE_COST 300
#define FB_COST 200
#define SG_COST 300


public Plugin:myinfo = 
{
	name = "CSS Grenade Slot",
	author = "KawMAN & Greyscale",
	description = "Player can carry up to 4 any type grenades",
	version = PLUGIN_VERSION,
	url = "http://wsciekle.pl"
}

new offsMoney;
new offsBuyZone;

new limit = 4;


//Cvar Handles
new Handle:g_limit = INVALID_HANDLE;

public OnPluginStart()
{
	
	offsMoney = FindSendPropInfo("CCSPlayer", "m_iAccount");
	if (offsMoney == -1)
	{
		SetFailState("Couldn't find \"m_iAccount\"!");
	}
	
	offsBuyZone = FindSendPropInfo("CCSPlayer", "m_bInBuyZone");
	if (offsBuyZone == -1)
	{
		SetFailState("Couldn't find \"m_bInBuyZone\"!");
	}
	
	//Register Cvars
	CreateConVar("sm_grenade_slot_v", PLUGIN_VERSION, "CSS Grenade Slot version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_limit = CreateConVar("sm_grenade_slot_limit", "4", "Max amount of grenades per player",0,true,1,true,1000);
	
	AutoExecConfig(true, "grenadeslot");
	//Command Hook
	RegConsoleCmd("buy", Command_Buy);
	
	HookConVarChange(g_limit, LimitChanged);
}


public LimitChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	limit=GetConVarInt(g_limit);
}

public Action:Command_Buy(client, argc)
{
	decl String:arg1[32];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	if (StrEqual(arg1, "hegrenade", false))
	{
		new bool:inbuyzone = bool:GetEntData(client, offsBuyZone, 1);
		if (inbuyzone)
		{
			if (GetClientAllGrenades(client) < limit)
			{
				new count=GetClientGrenades(client,HEGRENADE);
				if (count > 0)
				{
					new money = GetEntData(client, offsMoney);
					if (money>=HE_COST)
					{
						SetEntData(client, offsMoney, money - HE_COST);
						new entity = GivePlayerItem(client, "weapon_hegrenade");
						PickupGrenade(client, entity, HEGRENADE);
					}
					return Plugin_Handled;
				}
			}
			else
			{
				//When dont have hegrande and dont have free slot
				return Plugin_Handled;
			}
		}
		return Plugin_Continue;
	}
	if (StrEqual(arg1, "smokegrenade", false))
	{
		new bool:inbuyzone = bool:GetEntData(client, offsBuyZone, 1);
		if (inbuyzone)
		{
			if (GetClientAllGrenades(client) < limit)
			{
				new count=GetClientGrenades(client,SMOKEGREN);
				if (count > 0)
				{
					new money = GetEntData(client, offsMoney);
					if (money>=SG_COST)
					{
						SetEntData(client, offsMoney, money - SG_COST);
						new entity = GivePlayerItem(client, "weapon_smokegrenade");
						PickupGrenade(client, entity, SMOKEGREN);
					}
					return Plugin_Handled;
				}
			}
			else
			{
				//When dont have hegrande and dont have free slot
				return Plugin_Handled;
			}
		}
		return Plugin_Continue;
	}
	if (StrEqual(arg1, "flashbang", false))
	{
		new bool:inbuyzone = bool:GetEntData(client, offsBuyZone, 1);
		if (inbuyzone)
		{
			if (GetClientAllGrenades(client) < limit)
			{
				new count=GetClientGrenades(client,FLASHBANG);
				if (count > 1)
				{
					new money = GetEntData(client, offsMoney);
					if (money>=FB_COST)
					{
						SetEntData(client, offsMoney, money - FB_COST);
						new entity = GivePlayerItem(client, "weapon_flashbang");
						PickupGrenade(client, entity, FLASHBANG);
					}
					return Plugin_Handled;
				}
			}
			else
			{
				//When dont have hegrande and dont have free slot
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}

//Help
public IsValidPlayer (client)
{
	if (client == 0)
		return false;
	
	if (!IsClientConnected(client))
		return false;
	
	if (IsFakeClient(client))
		return false;
	
	if (!IsClientInGame(client))
		return false;
	
	return true;
}

PickupGrenade(client, entity, type)
{
	new Handle:event = CreateEvent("item_pickup");
	if (event != INVALID_HANDLE)
	{
		SetEventInt(event, "userid", GetClientUserId(client));

		SetEventString(event, "item", "hegrenade");
		FireEvent(event);
	}
	
	RemoveEdict(entity);
	
	GiveClientGrenade(client,type);
	
	EmitSoundToClient(client, "items/itempickup.wav");
}

GetClientGrenades(client, slot)
{
	new offsNades = FindDataMapOffs(client, "m_iAmmo") + (slot * 4);
	
	return GetEntData(client, offsNades);
}

GetClientAllGrenades(client)
{
	new offsNades = FindDataMapOffs(client, "m_iAmmo") + (11 * 4);
	new granadesnr=GetEntData(client, offsNades);
	offsNades+=4;
	granadesnr+=GetEntData(client, offsNades);
	offsNades+=4;
	granadesnr+=GetEntData(client, offsNades);
	return granadesnr;
}

GiveClientGrenade(client, slot)
{
	new offsNades = FindDataMapOffs(client, "m_iAmmo") + (slot * 4);
	
	new count = GetEntData(client, offsNades);
	SetEntData(client, offsNades, ++count);
}
