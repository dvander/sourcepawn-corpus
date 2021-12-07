#include <sourcemod>
#include <sdktools_functions>

#define MAX_PLAYERS 33

new String:CurWeapon[32]

new Handle:CheckTimers[MAX_PLAYERS] = INVALID_HANDLE

new Handle:hea_enabled
new Handle:hea_armor
new Handle:hea_use_knife
new Handle:hea_no_money
new Handle:hea_defuser

new CheckClient[MAX_PLAYERS]

public Plugin:myinfo =
{
	name = "HE Arena:Source",
	author = "Brute",
	description = "[Fun] Only hegrenade",
	version = "1.0.0.1",
	url = "http://www.sourcemod.net/"
}

public OnPluginStart() 
{
	HookEvent("hegrenade_detonate", HEboomEvent)
	HookEvent("player_spawn", RoundStartEvent)
	hea_enabled = CreateConVar("hea_enabled", "0", "1 = plugin is active, 0 = plugin is not active (by default 0)")
	hea_armor = CreateConVar("hea_armor", "2", "Auto give a armor, 2=assault suit, 1=kevlar, 0=off (by default 2)")
	hea_defuser = CreateConVar("hea_defuser", "1", "Auto give a defuser, 1=on, 0=off (by default 1)")
	hea_use_knife = CreateConVar("hea_use_knife", "0", "Use of knifes,  1=on, 0=off (by default 0)")
	hea_no_money = CreateConVar("hea_no_money", "1", "No money mode, , 1=on, 0=off (by default 1)")
	RegAdminCmd("hea_start", Command_Start, ADMFLAG_KICK, "Start HE Arena!")
	RegAdminCmd("hea_stop", Command_Stop, ADMFLAG_KICK, "Start HE Arena!")
}

public Action:Command_Start(client, args)
{
	if(GetConVarInt(hea_enabled) == 0)
	{
		ServerCommand("mp_restartgame 1")
		ServerCommand("hea_enabled 1")
		CreateTimer(2.0, StartTimers)
		//StartTimers()
		return Plugin_Handled
	}
	return Plugin_Continue
}

public Action:Command_Stop(client, args)
{
	if(GetConVarInt(hea_enabled) == 1)
	{
		ServerCommand("mp_restartgame 1")
		ServerCommand("hea_enabled 0")
		StopTimers()
		return Plugin_Handled
	}
	return Plugin_Continue
}

public Action:StartTimers(Handle:timer)
{
	for(new client=1; client<MAX_PLAYERS; client++)
	{
		if(CheckClient[client] != 0 && CheckTimers[client] == INVALID_HANDLE)
		{
			PrintToChat(client, "[SourceMod]:Start HE Arena!")
			CheckTimers[client] = CreateTimer(0.2, CheckWeapon, client, TIMER_REPEAT)
		}
	}
}

public Action:StopTimers()
{
	for(new client=1; client<MAX_PLAYERS; client++)
	{
		if(CheckClient[client] != 0  && CheckTimers[client] != INVALID_HANDLE)
		{
			PrintToChat(client, "[SourceMod]:Stop HE Arena!")
			KillTimer(CheckTimers[client])
			CheckTimers[client] = INVALID_HANDLE
		}
	}
}

public OnClientPutInServer(client)
{
	if(GetConVarInt(hea_enabled) == 1)
	{
		PrintToChat(client, "[SourceMod]:HE Arena is active!")
		CheckTimers[client] = CreateTimer(0.2, CheckWeapon, client, TIMER_REPEAT)
	}
	CheckClient[client] = 1
}

public Action:RoundStartEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(hea_enabled) == 1)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"))
		GiveHE(client)
		HookMoney(client)
		GiveArmor(client)
		GiveDefuser(client)
	}
}

public Action:HEboomEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(hea_enabled) == 1)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"))
		GiveHE(client)
	}
}

public Action:GiveHE(client)
{
	if(GetConVarInt(hea_enabled) == 1)
	{
		if(IsPlayerAlive(client))
		{
			GivePlayerItem(client, "weapon_hegrenade")
			CreateTimer(0.2, Slot4, client)
		}
	}
}

public Action:GiveDefuser(client)
{
	if(GetConVarInt(hea_enabled) == 1 && GetConVarInt(hea_defuser) == 1)
	{
		new String:map[32]
		GetCurrentMap(map, sizeof(map))
		if(IsPlayerAlive(client) && GetClientTeam(client) == 3 && StrEqual(map, "de_"))
		{
			GivePlayerItem(client, "item_defuser")
		}
	}
}

public Action:GiveArmor(client)
{
	if(GetConVarInt(hea_enabled) == 1 && GetConVarInt(hea_armor) != 0)
	{
		new ArmorOffset = FindSendPropOffs("CCSPlayer", "m_ArmorValue")
		if(IsPlayerAlive(client) && GetConVarInt(hea_armor) == 1)
		{
			GivePlayerItem(client, "item_kevlar")
			SetEntData(client, ArmorOffset, 100, 4, true)
		}

		if(IsPlayerAlive(client) && GetConVarInt(hea_armor) == 2)
		{
			GivePlayerItem(client, "item_assaultsuit")
			SetEntData(client, ArmorOffset, 100, 4, true)
		}
	}
}

public Action:HookMoney(client)
{
	if(GetConVarInt(hea_enabled) == 1 && GetConVarInt(hea_no_money) == 1)
	{
		new MoneyOffset = FindSendPropOffs("CCSPlayer", "m_iAccount")
		SetEntData(client, MoneyOffset, 0, 4, true)
	}
}

public Action:Slot4(Handle:timer, any:client)
{	
	if(GetConVarInt(hea_enabled) == 1)
	{
		if(IsPlayerAlive(client))
		{
			FakeClientCommandEx(client, "use weapon_hegrenade")
		}
	}
}

public Action:CheckWeapon(Handle:timer, any:client)
{
	if(GetConVarInt(hea_enabled) == 1)
	{
		if(IsPlayerAlive(client))
		{
			GetClientWeapon(client, CurWeapon, 31)
			if(!(StrEqual(CurWeapon, "weapon_hegrenade") || 
				StrEqual(CurWeapon, "weapon_c4")) && 
				GetConVarInt(hea_use_knife) == 0)
			{
				FakeClientCommandEx(client, "drop weapon_%s", CurWeapon)
				CreateTimer(0.1, Slot4, client)
			}
			if(!(StrEqual(CurWeapon, "weapon_hegrenade") || 
				StrEqual(CurWeapon, "weapon_c4") || 
				StrEqual(CurWeapon, "weapon_knife")) && 
				GetConVarInt(hea_use_knife) == 1)
			{
				FakeClientCommandEx(client, "drop weapon_%s", CurWeapon)
			}
		}
	}
}

public OnClientDisconnect(client)
{
	if(CheckTimers[client] != INVALID_HANDLE)
	{
		KillTimer(CheckTimers[client])
		CheckTimers[client] = INVALID_HANDLE
	}
	CheckClient[client] = 0
}