#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define STARTSHOOTING 1
#define STOPSHOOTING 0
static shoot[MAXPLAYERS + 1] = 0;
static bool:BotShouldShoot = true;
#define CVAR_FLAGS			FCVAR_NOTIFY
ConVar GrenadeTank;
#define PLUGIN_VERSION "1.2"

public Plugin:myinfo = 
{
	name = "[L4D2] Bot Throw Grenade", 
	author = "Edison1318", 
	description = "Force bots to uses/equip/throw their grenades in L4D2 and Throws Vomit jar and Molotov to Tanks.", 
	version = PLUGIN_VERSION, 
	url = "https://forums.alliedmods.net/showthread.php?p=2471263"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	decl String:s_GameFolder[32];
	GetGameFolderName(s_GameFolder, sizeof(s_GameFolder));
	if (!StrEqual(s_GameFolder, "left4dead2", false))
	{
		strcopy(error, err_max, "Sorry, this plugin is for Left 4 Dead 2 only.");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public OnPluginStart()
{	
	AutoExecConfig(true, "l4d2_botgrenade");
	GrenadeTank = CreateConVar("l4d2_tank_grenade", "1" , "Allow bots to throw grenades to tank. 0: Disable bots throwing grenades to tanks. 1: Enable bots throwing grenades to tanks", CVAR_FLAGS, true, 0.0, true, 1.0);
	CreateConVar("sm_bot_grenade_version", PLUGIN_VERSION, "L4D2 BOT GRENADE", CVAR_FLAGS|FCVAR_DONTRECORD);
	CreateTimer(1.0, CheckDistance, _, TIMER_REPEAT);
	RegConsoleCmd("sm_botthrowrandomgrenade", BotThrowRandomGrenade, "Force random bot throw grenade.", ADMFLAG_ROOT);
	RegConsoleCmd("sm_botthrowrandompipebomb", BotThrowRandomPipeBomb, "Force random bot throw pipe bomb.", ADMFLAG_ROOT);
	RegConsoleCmd("sm_botthrowrandommolotov", BotThrowRandomMolotov, "Force random bot throw molotov.", ADMFLAG_ROOT);
	RegConsoleCmd("sm_botthrowrandomvomitjar", BotThrowRandomVomitjar, "Force random bot throw boomer bile.", ADMFLAG_ROOT);
	RegConsoleCmd("sm_botgrenade", BotGrenade, "Force bots to equip grenades", ADMFLAG_ROOT);
	RegConsoleCmd("sm_botthrowgrenade", BotThrowGrenade, "Force bots to throw grenades", ADMFLAG_ROOT);
	RegConsoleCmd("sm_botthrowpipebomb", BotThrowPipeBomb, "Force bots to throw pipe bomb", ADMFLAG_ROOT);
	RegConsoleCmd("sm_botthrowmolotov", BotThrowMolotov, "Force bots to throw molotov", ADMFLAG_ROOT);
	RegConsoleCmd("sm_botthrowvomitjar", BotThrowVomitjar, "Force bots to throw boomer bile", ADMFLAG_ROOT);
	RegConsoleCmd("sm_botpipebomb", BotPipeBomb, "Force bots to equip pipe bomb", ADMFLAG_ROOT);
	RegConsoleCmd("sm_botmolotov", BotMolotov, "Force bots to equip molotov", ADMFLAG_ROOT);
	RegConsoleCmd("sm_botvomitjar", BotVomitjar, "Force bots to equip boomer bile", ADMFLAG_ROOT);
}

public Action:Command_MakeBotShoot(Handle:Timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	shoot[client] = STARTSHOOTING;
}

public Action:StopShooting(Handle:Timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	shoot[client] = STOPSHOOTING;
}

stock GetRandomPlayer(team)
{
	new iClients[MaxClients+1];
	new iNumClients;
	for(new i = 1 ; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == team)
		{
			new String:grenade[32];
			if (IsValidEdict(GetPlayerWeaponSlot(i, 2)))
			{
				GetEdictClassname(GetPlayerWeaponSlot(i, 2), grenade, sizeof(grenade));
				if (StrEqual(grenade, "weapon_molotov") || StrEqual(grenade, "weapon_vomitjar") || StrEqual(grenade, "weapon_pipe_bomb"))
				{
					iClients[iNumClients++] = i;
				}
			}
		}
	}
	return (iNumClients == 0) ? -1 : iClients[GetRandomInt(0, iNumClients-1)];
}

public Action:GrenadeDelay(Handle:timer, any:client)
{
	new i = GetRandomPlayer(2);
	{
		FakeClientCommand(i, "use weapon_molotov");
		FakeClientCommand(i, "use weapon_vomitjar");
		FakeClientCommand(i, "use weapon_pipe_bomb");
		CreateTimer(2.0, Command_MakeBotShoot, GetClientUserId(i));
		CreateTimer(2.8, StopShooting, GetClientUserId(i));
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if (IsPlayerAlive(client) && IsFakeClient(client))
	{
		new grenade = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if (IsValidEntity(grenade))
		{
			decl String:classname[128];
			GetEntityClassname(grenade, classname, sizeof(classname));
			if (grenade == GetPlayerWeaponSlot(client, 2) && (StrEqual(classname, "weapon_pipe_bomb") || StrEqual(classname, "weapon_molotov") || StrEqual(classname, "weapon_vomitjar")))
			{
				if (shoot[client] == STARTSHOOTING)
				{
					buttons |= IN_ATTACK;
				}
				else if (shoot[client] == STOPSHOOTING)
				{
					buttons &= ~IN_ATTACK;
				}
			}
		}
	}
	return Plugin_Continue;
}

public Action:BotGrenade(client, args)
{
	for (new i = 1 ; i <= MaxClients; i++)
	{
		if(IsSurvivorBot(i))
		{
			FakeClientCommand(i, "use weapon_molotov");
			FakeClientCommand(i, "use weapon_vomitjar");
			FakeClientCommand(i, "use weapon_pipe_bomb");
		}
	}
}

public Action:BotThrowMolotov(client, args)
{
	for (new i = 1 ; i <= MaxClients; i++)
	{
		if(IsSurvivorBot(i))
		{
			FakeClientCommand(i, "use weapon_molotov");
			CreateTimer(0.2, Command_MakeBotShoot, GetClientUserId(i));
			CreateTimer(1.0, StopShooting, GetClientUserId(i));
		}
	}
}

public Action:BotThrowPipeBomb(client, args)
{
	for (new i = 1 ; i <= MaxClients; i++)
	{
		if(IsSurvivorBot(i))
		{
			FakeClientCommand(i, "use weapon_pipe_bomb");
			CreateTimer(0.2, Command_MakeBotShoot, GetClientUserId(i));
			CreateTimer(1.0, StopShooting, GetClientUserId(i));
		}
	}
}

public Action:BotThrowVomitjar(client, args)
{
	for (new i = 1 ; i <= MaxClients; i++)
	{
		if(IsSurvivorBot(i))
		{
			FakeClientCommand(i, "use weapon_vomitjar");
			CreateTimer(0.2, Command_MakeBotShoot, GetClientUserId(i));
			CreateTimer(1.0, StopShooting, GetClientUserId(i));
		}
	}
}

public Action:BotThrowRandomGrenade(client, args)
{
	new randomplayer = GetRandomPlayer(2);
	FakeClientCommand(randomplayer, "use weapon_molotov");
	FakeClientCommand(randomplayer, "use weapon_vomitjar");
	FakeClientCommand(randomplayer, "use weapon_pipe_bomb");
	CreateTimer(0.2, Command_MakeBotShoot, GetClientUserId(randomplayer));
	CreateTimer(1.0, StopShooting, GetClientUserId(randomplayer));
}

public Action:BotThrowRandomPipeBomb(client, args)
{
	new randomplayer = GetRandomPlayer(2);
	FakeClientCommand(randomplayer, "use weapon_pipe_bomb");
	CreateTimer(0.2, Command_MakeBotShoot, GetClientUserId(randomplayer));
	CreateTimer(1.0, StopShooting, GetClientUserId(randomplayer));
}

public Action:BotThrowRandomMolotov(client, args)
{
	new randomplayer = GetRandomPlayer(2);
	FakeClientCommand(randomplayer, "use weapon_molotov");
	CreateTimer(0.2, Command_MakeBotShoot, GetClientUserId(randomplayer));
	CreateTimer(1.0, StopShooting, GetClientUserId(randomplayer));
}

public Action:BotThrowRandomVomitjar(client, args)
{
	new randomplayer = GetRandomPlayer(2);
	FakeClientCommand(randomplayer, "use weapon_vomitjar");
	CreateTimer(0.2, Command_MakeBotShoot, GetClientUserId(randomplayer));
	CreateTimer(1.0, StopShooting, GetClientUserId(randomplayer));
}

public Action:BotThrowGrenade(client, args)
{
	for (new i = 1 ; i <= MaxClients; i++)
	{
		if(IsSurvivorBot(i))
		{
			FakeClientCommand(i, "use weapon_molotov");
			FakeClientCommand(i, "use weapon_vomitjar");
			FakeClientCommand(i, "use weapon_pipe_bomb");
			CreateTimer(0.2, Command_MakeBotShoot, GetClientUserId(i));
			CreateTimer(1.0, StopShooting, GetClientUserId(i));
		}
	}
}

public Action:BotPipeBomb(client, args)
{
	for (new i = 1 ; i <= MaxClients; i++)
	{
		if(IsSurvivorBot(i))
		{
			FakeClientCommand(i, "use weapon_pipe_bomb");
		}
	}
}
public Action:BotMolotov(client, args)
{
	for (new i = 1 ; i <= MaxClients; i++)
	{
		if(IsSurvivorBot(i))
		{
			FakeClientCommand(i, "use weapon_molotov");
		}
	}
}
public Action:BotVomitjar(client, args)
{
	for (new i = 1 ; i <= MaxClients; i++)
	{
		if(IsSurvivorBot(i))
		{
			FakeClientCommand(i, "use weapon_vomitjar");
		}
	}
}

stock bool:IsCommonInfected(iEntity)
{
    if(iEntity > 0 && IsValidEntity(iEntity) && IsValidEdict(iEntity))
    {
        decl String:strClassName[64];
        GetEdictClassname(iEntity, strClassName, sizeof(strClassName));
        return StrEqual(strClassName, "infected");
    }
    return false;
}  

stock bool:IsInfected(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3)
	{
		return true;
	}
	return false;
}

stock bool:IsSurvivorBot(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && IsFakeClient(client) && GetClientTeam(client) == 2)
	{
		return true;
	}
	return false;
}

stock bool:IsGrenade(entity)
{
	if (entity > 32 && IsValidEntity(entity))
	{
		decl String: classname[16];
		GetEdictClassname(entity, classname, sizeof(classname));
		if (StrEqual(classname, "weapon_pipe_bomb", false)
		|| StrEqual(classname, "weapon_pipe_bomb_spawn", false)
		|| StrEqual(classname, "weapon_vomitjar", false)
		|| StrEqual(classname, "weapon_vomitjar_spawn", false)
		|| StrEqual(classname, "weapon_molotov", false)
		|| StrEqual(classname, "weapon_molotov_spawn", false))
			return true;
	}
	return false;
}

stock bool:IsHasGrenade(grenade)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsSurvivorBot(i))
		{
			if (GetPlayerWeaponSlot(i, 2) == grenade)
			{
				return true;
			}
		}
	}
	return false;
}

public Action:CheckDistance(Handle:timer)
{
	if (!IsServerProcessing())
	{
		return Plugin_Continue;
	}
	else if (GrenadeTank.BoolValue)
	{
		for (new b = 1; b <= MaxClients; b++)
		{
			new Float:f_HumanOrigin[3];
			if (IsSurvivorBot(b))
			{
				GetClientAbsOrigin(b, f_HumanOrigin);
				new Float:f_AliensOrigin[3];
				for (new i = 1; i <= MaxClients; i++)
				{
					if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 3)
					{
						new ClassType = GetEntProp(i, Prop_Send, "m_zombieClass");
						if (ClassType == 8)
						{
							GetClientAbsOrigin(i, f_AliensOrigin);	
							new Float:distance = GetVectorDistance( f_HumanOrigin, f_AliensOrigin );
							if (distance < 500.0)
							{
								new String:grenade[32];
								if (IsValidEdict(GetPlayerWeaponSlot(b, 2)))
								{
									GetEdictClassname(GetPlayerWeaponSlot(b, 2), grenade, sizeof(grenade));
									if (StrEqual(grenade, "weapon_molotov") || StrEqual(grenade, "weapon_vomitjar"))
									{
										if(BotShouldShoot)
										{
											new target = GetClientAimTarget(b, true);
											if (IsInfected(target))
											{
												FakeClientCommand(b, "use weapon_molotov");
												FakeClientCommand(b, "use weapon_vomitjar");
												if (IsInfected(target))
												{
													CreateTimer(0.2, Command_MakeBotShoot, GetClientUserId(b));
													CreateTimer(1.0, StopShooting, GetClientUserId(b));
												}
											}
										}
										BotShouldShoot = false;
										CreateTimer(3.5, Delay);
									}
								}
							}
						}
					}
				}
			}
		}
		return Plugin_Continue;
	}
	return Plugin_Continue;
}

public Action:Delay(Handle:timer)
{
	BotShouldShoot = true;
}