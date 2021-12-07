#include <sourcemod>
#pragma semicolon 1
#pragma newdecls required
#define PLUGIN_VERSION "2.12"

static bool   g_bL4D2Version;

bool bDistance;
bool bNotifications;
bool bSI;
bool bTank;
bool bWitch;
bool IsL4D2;
bool On = false;
Handle hHRFirst;
Handle hHRSecond;
Handle hHRThird;
Handle hHRDistance;
Handle hHRNotifications;
Handle hHRMax;
Handle hHRTank;
Handle hHRWitch;
Handle hHRSI;
int iFirst;
int iSecond;
int iThird;
int iMax;
int zClassTank;

public Plugin myinfo =
{
	name = "[L4D & L4D2] HP Rewards",
	author = "cravenge",
	description = "Grants Full Health After Killing Tanks And Witches, Additional Health For Killing SI.",
	version = PLUGIN_VERSION,
	url = ""
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion engine = GetEngineVersion();

    g_bL4D2Version = (engine == Engine_Left4Dead2);

    return APLRes_Success;
}

public void OnPluginStart()
{
	char game[12];
	GetGameFolderName(game, sizeof(game));
	if(StrEqual(game, "left4dead2"))
	{
		IsL4D2 = true;
		zClassTank = 8;
	}

	else
	{
		IsL4D2 = false;
		zClassTank = 5;
	}
	
	CreateConVar("l4d_hp_rewards_version", PLUGIN_VERSION, "HP Rewards Version", FCVAR_SPONLY|FCVAR_DONTRECORD);
	hHRFirst = CreateConVar("l4d_hp_rewards_first", "1", "Rewarded HP For Killing Boomers And Spitters");
	hHRSecond = CreateConVar("l4d_hp_rewards_second", "3", "Rewarded HP For Killing Smokers And Jockeys");
	hHRThird = CreateConVar("l4d_hp_rewards_third", "5", "Rewarded HP For Killing Hunters And Chargers");
	hHRDistance = CreateConVar("l4d_hp_rewards_distance", "1", "Enable/Disable Distance Calculations");
	hHRNotifications = CreateConVar("l4d_hp_rewards_notify", "1", "Notifications Mode: 0=Center Text, 1=Hint Box");
	hHRMax = CreateConVar("l4d_hp_rewards_max", "200", "Max HP Limit");
	hHRTank = CreateConVar("l4d_hp_rewards_tank", "1", "Enable/Disable Tank Rewards");
	hHRWitch = CreateConVar("l4d_hp_rewards_witch", "1", "Enable/Disable Witch Rewards");
	hHRSI = CreateConVar("l4d_hp_rewards_si", "1", "Enable/Disable Special Infected Rewards");
	HookEvent("round_start", OnRoundStart);
	HookEvent("round_end", OnRewardsReset);
	HookEvent("finale_win", OnRewardsReset);
	HookEvent("mission_lost", OnRewardsReset);
	HookEvent("map_transition", OnRewardsReset);
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("witch_killed", OnWitchKilled);
	iFirst = GetConVarInt(hHRFirst);
	iSecond = GetConVarInt(hHRSecond);
	iThird = GetConVarInt(hHRThird);
	iMax = GetConVarInt(hHRMax);
	bNotifications = GetConVarBool(hHRNotifications);
	bDistance = GetConVarBool(hHRDistance);
	bTank = GetConVarBool(hHRTank);
	bWitch = GetConVarBool(hHRWitch);
	bSI = GetConVarBool(hHRSI);
	HookConVarChange(hHRFirst, HRConfigsChanged);
	HookConVarChange(hHRSecond, HRConfigsChanged);
	HookConVarChange(hHRThird, HRConfigsChanged);
	HookConVarChange(hHRDistance, HRConfigsChanged);
	HookConVarChange(hHRNotifications, HRConfigsChanged);
	HookConVarChange(hHRMax, HRConfigsChanged);
	HookConVarChange(hHRTank, HRConfigsChanged);
	HookConVarChange(hHRWitch, HRConfigsChanged);
	HookConVarChange(hHRSI, HRConfigsChanged);
	AutoExecConfig(true, "l4d_hp_rewards");
}

public void HRConfigsChanged(Handle convar, const char[] oValue, const char[] nValue)
{
	iFirst = GetConVarInt(hHRFirst);
	iSecond = GetConVarInt(hHRSecond);
	iThird = GetConVarInt(hHRThird);
	iMax = GetConVarInt(hHRMax);
	bNotifications = GetConVarBool(hHRNotifications);
	bDistance = GetConVarBool(hHRDistance);
	bTank = GetConVarBool(hHRTank);
	bWitch = GetConVarBool(hHRWitch);
	bSI = GetConVarBool(hHRSI);
}

public void OnMapStart()
{
	On = true;
}

public void OnMapEnd()
{
	On = false;
}

public Action OnRoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	if(On)
	{
		return;
	}

	On = true;
}

public Action OnRewardsReset(Handle event, const char[] name, bool dontBroadcast)
{
	if(!On)
	{
		return;
	}

	On = false;
}

public Action OnPlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	if(On)
	{
		int client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(client <= 0 || client > MaxClients || !IsClientInGame(client) || GetClientTeam(client) != 3)
		{
			return;
		}

		float cOrigin[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", cOrigin);
		if(bTank)
		{
			int tClass = GetEntProp(client, Prop_Send, "m_zombieClass");
			if(tClass == zClassTank)
			{
				for (int attacker=1; attacker<=MaxClients; attacker++)
				{
					if(IsClientInGame(attacker) && GetClientTeam(attacker) == 2 && IsPlayerAlive(attacker) && !IsPlayerIncapped(attacker))
					{
						GiveHealth(attacker);
						SetEntPropFloat(attacker, Prop_Send, "m_healthBufferTime", GetGameTime());
						SetEntPropFloat(attacker, Prop_Send, "m_healthBuffer", 0.0);
						if (g_bL4D2Version)
						{
							SetEntProp(attacker, Prop_Send, "m_iGlowType", 0);
							SetEntProp(attacker, Prop_Send, "m_glowColorOverride", 0);
							SetEntProp(attacker, Prop_Send, "m_bIsOnThirdStrike", 0);
						}
						SetEntProp(attacker, Prop_Send, "m_currentReviveCount", 0);
						SetEntProp(attacker, Prop_Send, "m_isGoingToDie", 0);
					}
				}
			}
		}
		
		if(bSI)
		{
			int shooter = GetClientOfUserId(GetEventInt(event, "attacker"));
			if(shooter <= 0 || shooter > MaxClients || !IsClientInGame(shooter) || GetClientTeam(shooter) != 2 || !IsPlayerAlive(shooter) || IsPlayerIncapped(shooter))
			{
				return;
			}

			float sOrigin[3];
			GetEntPropVector(shooter, Prop_Send, "m_vecOrigin", sOrigin);
			int dHealth;
			float oDistance = GetVectorDistance(cOrigin, sOrigin);
			if(oDistance < 10000.0)
			{
				dHealth = RoundToZero(oDistance * 0.02);
			}

			else if(oDistance >= 10000.0)
			{
				dHealth = 200;
			}

			int aHealth;
			int cClass = GetEntProp(client, Prop_Send, "m_zombieClass");
			if(cClass == 2 || (IsL4D2 && cClass == 4))
			{
				if(bDistance)
				{
					aHealth = iFirst + dHealth;
				}

				else
				{
					aHealth = iFirst;
				}
			}

			else if(cClass == 1 || (IsL4D2 && cClass == 5))
			{
				if(bDistance)
				{
					aHealth = iSecond + dHealth;
				}

				else
				{
					aHealth = iSecond;
				}
			}
			else if(cClass == 3 || (IsL4D2 && cClass == 6))
			{
				if(bDistance)
				{
					aHealth = iThird + dHealth;
				}

				else
				{
					aHealth = iThird;
				}
			}
			
			int sHealth = GetClientHealth(shooter);
			if((sHealth + aHealth) < iMax)
			{
				SetEntProp(shooter, Prop_Send, "m_iHealth", sHealth + aHealth, 1);
			}

			else
			{
				SetEntProp(shooter, Prop_Send, "m_iHealth", iMax, 1);
				SetEntPropFloat(shooter, Prop_Send, "m_healthBufferTime", GetGameTime());
				SetEntPropFloat(shooter, Prop_Send, "m_healthBuffer", 0.0);
			}

			if(cClass != zClassTank)
			{
				if(bNotifications)
				{
					PrintHintText(shooter, "[HR] +%i HP", aHealth);
				}

				else
				{
					PrintCenterText(shooter, "[HR] +%i HP", aHealth);
				}
			}
		}
	}
}

public Action OnWitchKilled(Handle event, const char[] name, bool dontBroadcast)
{
	if(On && bWitch)
	{
		int client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(client > 0 && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
		{
			if(IsPlayerIncapped(client))
			{
				return;
			}
			
			GiveHealth(client);
			SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
			SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);
			SetEntProp(client, Prop_Send, "m_currentReviveCount", 0);
			if (g_bL4D2Version)
				SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 0);
			SetEntProp(client, Prop_Send, "m_isGoingToDie", 0);
			PrintToChatAll("\x03Witch\x04 finally killed by \x03%N!", client);
		}
	}
}

public bool IsPlayerIncapped(int client)
{
	if(GetEntProp(client, Prop_Send, "m_isIncapacitated", 1))
	{
		return true;
	}

	else
	{
		return false;
	}
}

void GiveHealth(int client)
{
	int iflags = GetCommandFlags("give");
	SetCommandFlags("give", iflags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "give health");
	SetCommandFlags("give", iflags);
}
