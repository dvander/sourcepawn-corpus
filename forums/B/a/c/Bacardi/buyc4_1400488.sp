/**
	[CSS] Buy C4
	Terrorist can buy C4 bomb from buy zone within buy time.

	25.1.2011 Version 0.1
	- released
	26.1.2011 Version 0.2
	- Added chat announce to Terrorist when round start
	- Added work only bomb maps or all maps
	27.1.2011 Version 0.3
	- Add few PrintCenterText notified
	28.1.2011 Version 0.4
	- Little fix, not show "You are not in a buy zone." to dead people
	- Bomb limit added
	29.1.2011 Version 0.5
	- Little fix when work only bomb maps and it have disabled to not show chat announce
*/
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#define PLUGIN_VERSION	"1.0"

new Handle:buyc4_enabled = INVALID_HANDLE;
new Handle:buyc4_cost = INVALID_HANDLE;
new Handle:buyc4_chatannounce = INVALID_HANDLE;
new Handle:buyc4_onlybombmaps = INVALID_HANDLE;
new Handle:buyc4_limit = INVALID_HANDLE;
new Handle:mp_buytime = INVALID_HANDLE;
new Float:buytime;
new Float:roundfreezeend;
new bool:enable;
new count;
new EngineVersion:game;

public Plugin:myinfo =
{
	name		= "[CSS & CSGO] Buy C4",
	author		= "Bacardi",
	description	= "Terrorist can buy C4 bomb",
	version		= PLUGIN_VERSION,
	url			= "www.sourcemod.net"
}


public OnPluginStart()
{
	game = GetEngineVersion();

	RegAdminCmd("sm_buyc4", Cmd_BuyC4, ADMFLAG_SLAY, "Terrorist can buy C4 from buy zone");	// Create command

	buyc4_enabled = CreateConVar("buyc4_enabled", "1", "When enabled, TERRORIST can buy C4 bomb", _, true, 0.0, true, 1.0);	// Create cvar
	buyc4_cost = CreateConVar("buyc4_cost", "13000", "Set price to weapon C4 bomb", _, true, 0.0, true, 16000.0);	// Create cvar
	buyc4_chatannounce = CreateConVar("buyc4_chatannounce", "1", "Print in chat announce to terrorist when round start", _, true, 0.0, true, 1.0);	// Create cvar
	buyc4_onlybombmaps = CreateConVar("buyc4_onlybombmaps", "1", "Works only maps where bomb site", _, true, 0.0, true, 1.0);	// Create cvar
	buyc4_limit = CreateConVar("buyc4_limit", "0", "Limit the number of bombs, 0 = unlimited", _, true, 0.0);	// Create cvar
	mp_buytime = FindConVar("mp_buytime");	// To Hook cvar from srcds
	buytime = game == Engine_CSS ? GetConVarFloat(FindConVar("mp_buytime"))*60:GetConVarFloat(FindConVar("mp_buytime"));	// Convert minutes to seconds

	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_freeze_end", Event_RoundFreezeEnd, EventHookMode_PostNoCopy);
	HookConVarChange(mp_buytime, buytimechanged);	// Check cvar change

	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i)) OnClientPutInServer(i);
	}
}

public OnMapStart()
{
	if(GetConVarBool(buyc4_onlybombmaps) && FindEntityByClassname(-1, "func_bomb_target") == -1)	// cvar 'buyc4_onlybombmaps' enabled and current map have not bomb plant site
	{
		enable = false;
	}
	else	// cvar 'buyc4_onlybombmaps' disabled (or cvar 'buyc4_onlybombmaps' enabled and bomb plant site exist)
	{
		enable = true;
	}
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
}

public Action:OnWeaponCanUse(client, weapon)
{
	if(!IsClientInGame(client) || GetClientTeam(client) < 2)
	{
		return Plugin_Continue;
	}

	new String:clsname[20];
	GetEntityClassname(weapon, clsname, sizeof(clsname));
	if(StrEqual(clsname, "weapon_c4", false) && GetPlayerWeaponSlot(client, 4) != -1)
	{
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(enable && GetConVarBool(buyc4_enabled))
	{
		roundfreezeend = GetGameTime();	// Get current map time
		count = 0;	// Reset counter

		if(GetConVarBool(buyc4_chatannounce))
		{
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && GetClientTeam(i) == 2 && CheckCommandAccess(i, "sm_buyc4", ADMFLAG_SLAY))
				{
					new price = GetConVarInt(buyc4_cost);

					if(price > 0)
					{
						PrintToChat(i, "\x01\x03!buyc4 \x01cost \x03%i\x01$", price);
					}
					else
					{
						PrintToChat(i, "\x01\x03!buyc4 \x01now \x03FREE\x01!");
					}
				}
			}
		}
	}
}

public Event_RoundFreezeEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(enable && GetConVarBool(buyc4_enabled))
	{
		roundfreezeend = GetGameTime();	// Get current map time
	}
}

public Action:Cmd_BuyC4(client, arg)
{
	if(enable)
	{
		if(client == 0)	// Prevent command usage from server input and via RCON
		{
			PrintToConsole(client, "Can't use this command from server input");
			return Plugin_Handled;
		}

		if(!GetConVarBool(buyc4_enabled))
		{
			PrintToConsole(client, "[CSS] Buy C4 is disabled");
			return Plugin_Handled;
		}

		if(GetClientTeam(client) == 2 && GetEntProp(client, Prop_Send, "m_bInBuyZone") == 1) // Client is TERRORIST and inside buy zone
		{
			new Float:buytimeleft = (roundfreezeend + buytime) - GetGameTime();	// Get buy time left

			if(buytimeleft > 0)
			{
				if(GetPlayerWeaponSlot(client, 4) != -1)	// Player have bomb already
				{
					PrintCenterText(client, "You cannot carry any more.");
					return Plugin_Handled;
				}

				new limit = GetConVarInt(buyc4_limit);	// Get bomb limit from cvar

				if(limit > 0)	// limit have been set greater than 0
				{
					new ent = -1;
					count = 0;	// Reset counter
					while ((ent = FindEntityByClassname(ent, "weapon_c4")) != -1) // Find all C4 bombs
					{
						count++; // Count bombs
					}
	
					if(count >= limit)	// Bomb limit reached
					{
						PrintCenterText(client, "C4 Bomb limit reached\nThere is now %i bombs under way", count);
						return Plugin_Handled;
					}
				}

				new cash = GetEntProp(client, Prop_Send, "m_iAccount");	// Check player cash
				new cost = GetConVarInt(buyc4_cost);	// Check C4 price

				if(cash < cost)	// Player not have enough money
				{
					PrintCenterText(client, "You not have enough money\nC4 Bomb cost %i$", cost);
					EmitSoundToClient(client, "weapons/clipempty_rifle.wav");
				}
				else
				{
					new cashback = cash - cost;
					SetEntProp(client, Prop_Send, "m_iAccount", cashback);
					GivePlayerItem(client, "weapon_c4");
					PrintCenterText(client, "You have purchased C4 Bomb");
				}
			}
			else
			{
				PrintCenterText(client, "%0.0f seconds have passed.\nYou can't buy anything now.", buytime);
			}
		}
		else if(IsPlayerAlive(client) && GetClientTeam(client) == 2 && GetEntProp(client, Prop_Send, "m_bInBuyZone") == 0) // Client is TERRORIST and outside buy zone
		{
			PrintCenterText(client, "You are not in a buy zone.");
		}
	}
	return Plugin_Handled;	// This prevent print "Unknow command" in client console
}

public buytimechanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	buytime = game == Engine_CSS ? StringToFloat(newValue)*60:StringToFloat(newValue);// Update buy time and in seconds when mp_buytime change
}