#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define TEST_DEBUG			0
#define TEST_DEBUG_LOG		0

static const MELEE_WEAPON_SLOT = 1;

new Handle:WC_hLimitCount;
new String:WC_sLastWeapon[64];
new WC_iLimitCount = 1;
new WC_iLastWeapon = -1;
new WC_iLastClient = -1;

static		Handle:DROPPED_STUFF_ARRAY		= INVALID_HANDLE;


public OnPluginStart()
{
	WC_hLimitCount = CreateConVar("l4d2_limit_melee", "1", "Limits the maximum number of melee weapons at one time to this number");
	HookConVarChange(WC_hLimitCount, WC_ConVarChange);
	WC_iLimitCount = GetConVarInt(WC_hLimitCount);
	
	HookEvent("player_use", WC_PlayerUse_Event);
	HookEvent("weapon_drop", WC_WeaponDrop_Event);
	
	DROPPED_STUFF_ARRAY = CreateArray();
}

public OnMapStart()
{
	ClearArray(DROPPED_STUFF_ARRAY);
	WC_iLimitCount = GetConVarInt(WC_hLimitCount);
}

public WC_ConVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	WC_iLimitCount = GetConVarInt(WC_hLimitCount);
}

public Action:WC_WeaponDrop_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	// this code saves a user and the gun he drops in the moment of dropping, in order to revert this if hes picking up something blocked

	WC_iLastWeapon = GetEventInt(event, "propid");
	WC_iLastClient = GetClientOfUserId(GetEventInt(event, "userid"));
	GetEventString(event, "item", WC_sLastWeapon, sizeof(WC_sLastWeapon));
	
	if (!WC_iLastClient || !IsClientInGame(WC_iLastClient)) return;
	
	PushArrayCell(DROPPED_STUFF_ARRAY, WC_iLastWeapon);
	
	DebugPrintToAll("Player %N dropped event item %s", WC_iLastClient, WC_sLastWeapon);
}

public Action:WC_PlayerUse_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	new item = GetEventInt(event, "targetid");
	
	if (HasBeenDropped(item))
	{
		return;
	}

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!client || !IsClientInGame(client)) return;
	
	new secondary = GetPlayerWeaponSlot(client, MELEE_WEAPON_SLOT);
	
	decl String:stringbuffer[64];
	GetEdictClassname(secondary, stringbuffer, sizeof(stringbuffer));
	
	DebugPrintToAll("Player %N picked %s up", client, stringbuffer);
	
	if (StrEqual(stringbuffer, "weapon_melee"))
	{
		if (GetMeleeWeaponCount() > WC_iLimitCount)
		{
			if (IsValidEdict(secondary))
			{
				RemovePlayerItem(client, secondary);
				PrintToChat(client, "Maximum number of %i melee weapon(s) is enforced.", WC_iLimitCount);
			}
			
			if (WC_iLastClient == client)
			{
				if (IsValidEdict(WC_iLastWeapon))
				{
					if (!StrEqual(WC_sLastWeapon, "melee"))
					{
						AcceptEntityInput(WC_iLastWeapon, "Kill");
						
						Format(stringbuffer, sizeof(stringbuffer), "give %s", WC_sLastWeapon);
					
						new flags = GetCommandFlags("give");
						SetCommandFlags("give", flags ^ FCVAR_CHEAT);
						FakeClientCommand(client, stringbuffer);
						SetCommandFlags("give", flags);
					}
				}
			}
		}
	}
	
	WC_iLastWeapon = -1;
	WC_iLastClient = -1;
}

static GetMeleeWeaponCount()
{
	new count = 0;
	new ent = -1;
	decl String:temp[64];
	
	for (new i = 1; i < MaxClients+1; i++)
	{
		if (IsClientConnected(i)
		&& GetClientTeam(i) == 2
		&& IsPlayerAlive(i))
		{
			ent = GetPlayerWeaponSlot(i, MELEE_WEAPON_SLOT);
			if (IsValidEdict(ent))
			{
				GetEdictClassname(ent, temp, sizeof(temp));
				
				if (StrEqual(temp, "weapon_melee"))
					count++;
			}
		}
	}
	
	DebugPrintToAll("GetMeleeWeaponCount() returns %i", count);
	
	return count;
}

static bool:HasBeenDropped(item)
{
	new index = FindValueInArray(DROPPED_STUFF_ARRAY, item);

	if (index != -1)
	{
		RemoveFromArray(DROPPED_STUFF_ARRAY, index);
		return true;
	}
	
	return false;
}

stock DebugPrintToAll(const String:format[], any:...)
{
	#if (TEST_DEBUG || TEST_DEBUG_LOG)
	decl String:buffer[256];
	
	VFormat(buffer, sizeof(buffer), format, 2);
	
	#if TEST_DEBUG
	PrintToChatAll("[TEST] %s", buffer);
	PrintToConsole(0, "[TEST] %s", buffer);
	#endif
	
	LogMessage("%s", buffer);
	#else
	//suppress "format" never used warning
	if(format[0])
		return;
	else
		return;
	#endif
}