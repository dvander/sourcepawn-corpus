#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION "2.1"

new bool:IsL4D2;
new zClassTank;

new bool:On = false;

new Handle:hHRFirst;
new Handle:hHRSecond;
new Handle:hHRThird;
new Handle:hHRDistance;
new Handle:hHRNotifications;
new Handle:hHRMax;
new Handle:hHRTank;
new Handle:hHRWitch;
new Handle:hHRSI;

new iFirst;
new iSecond;
new iThird;
new iMax;

new bool:bNotifications;
new bool:bDistance;
new bool:bTank;
new bool:bWitch;
new bool:bSI;

public Plugin:myinfo =
{
	name = "HP Rewards",
	author = "cravenge",
	description = "Grants Full Health After Killing Tanks And Witches, Additional Health For Killing SI.",
	version = PLUGIN_VERSION,
	url = ""
};

public OnPluginStart()
{
	decl String:game[12];
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
	
	CreateConVar("hp_rewards_version", PLUGIN_VERSION, "HP Rewards Version", FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	hHRFirst = CreateConVar("hp_rewards_first", "1", "Rewarded HP For Killing Boomers And Spitters", FCVAR_NOTIFY);
	hHRSecond = CreateConVar("hp_rewards_second", "3", "Rewarded HP For Killing Smokers And Jockeys", FCVAR_NOTIFY);
	hHRThird = CreateConVar("hp_rewards_third", "5", "Rewarded HP For Killing Hunters And Chargers", FCVAR_NOTIFY);
	hHRDistance = CreateConVar("hp_rewards_distance", "1", "Enable/Disable Distance Calculations", FCVAR_NOTIFY);
	hHRNotifications = CreateConVar("hp_rewards_notify", "1", "Notifications Mode: 0=Center Text, 1=Hint Box", FCVAR_NOTIFY);
	hHRMax = CreateConVar("hp_rewards_max", "200", "Max HP Limit", FCVAR_NOTIFY);
	hHRTank = CreateConVar("hp_rewards_tank", "1", "Enable/Disable Tank Rewards", FCVAR_NOTIFY);
	hHRWitch = CreateConVar("hp_rewards_witch", "1", "Enable/Disable Witch Rewards", FCVAR_NOTIFY);
	hHRSI = CreateConVar("hp_rewards_si", "1", "Enable/Disable Special Infected Rewards", FCVAR_NOTIFY);
	
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
	
	AutoExecConfig(true, "hp_rewards");
}

public HRConfigsChanged(Handle:convar, const String:oValue[], const String:nValue[])
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

public OnMapStart()
{
	On = true;
}

public OnMapEnd()
{
	On = false;
}

public Action:OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(On)
	{
		return;
	}
	On = true;
}

public Action:OnRewardsReset(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!On)
	{
		return;
	}
	On = false;
}

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(On)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(client <= 0 || client > MaxClients || !IsClientInGame(client) || GetClientTeam(client) != 3)
		{
			return;
		}
		
		decl Float:cOrigin[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", cOrigin);
		
		if(bTank)
		{
			new tClass = GetEntProp(client, Prop_Send, "m_zombieClass");
			if(tClass == zClassTank)
			{
				for (new attacker=1; attacker<=MaxClients; attacker++)
				{
					if(IsClientInGame(attacker) && GetClientTeam(attacker) == 2 && IsPlayerAlive(attacker) && !IsPlayerIncapped(attacker))
					{
						GiveHealth(attacker);
						SetEntPropFloat(attacker, Prop_Send, "m_healthBufferTime", GetGameTime());
						SetEntPropFloat(attacker, Prop_Send, "m_healthBuffer", 0.0);
						
						SetEntProp(attacker, Prop_Send, "m_iGlowType", 0);
						SetEntProp(attacker, Prop_Send, "m_glowColorOverride", 0);
						
						SetEntProp(attacker, Prop_Send, "m_currentReviveCount", 0);
						SetEntProp(attacker, Prop_Send, "m_bIsOnThirdStrike", 0);
						SetEntProp(attacker, Prop_Send, "m_isGoingToDie", 0);
					}
				}
			}
		}
		
		if(bSI)
		{
			new shooter = GetClientOfUserId(GetEventInt(event, "attacker"));
			if(shooter <= 0 || shooter > MaxClients || !IsClientInGame(shooter) || GetClientTeam(shooter) != 2 || !IsPlayerAlive(shooter) || IsPlayerIncapped(shooter))
			{
				return;
			}
			
			decl Float:sOrigin[3];
			GetEntPropVector(shooter, Prop_Send, "m_vecOrigin", sOrigin);
			
			new dHealth;
			new Float:oDistance = GetVectorDistance(cOrigin, sOrigin);
			if(oDistance < 10000.0)
			{
				dHealth = RoundToZero(oDistance * 0.02);
			}
			else if(oDistance >= 10000.0)
			{
				dHealth = 200;
			}
			
			new aHealth;
			new cClass = GetEntProp(client, Prop_Send, "m_zombieClass");
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
			
			new sHealth = GetClientHealth(shooter);
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

public Action:OnWitchKilled(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(On && bWitch)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
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
			SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 0);
			SetEntProp(client, Prop_Send, "m_isGoingToDie", 0);
			
			PrintToChatAll("\x03Witch\x04 Finally Killed By \x03%N!", client);
		}
	}
}

public IsPlayerIncapped(client)
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

GiveHealth(client)
{
	new iflags = GetCommandFlags("give");
	SetCommandFlags("give", iflags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "give health");
	SetCommandFlags("give", iflags);
}

