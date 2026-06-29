#include <sourcemod>
#include <sdktools>

public Plugin:myinfo =
{
	name = "BuyShield",
	author = "backwards",
	description = "Allows players to buy shields by typing !buyshield.",
	version = SOURCEMOD_VERSION,
	url = "http://www.steamcommunity.com/id/mypassword"
}

new ShieldCost = 5000
new bool:RequireBuyZone = true;
Handle BuyStartRoundTimer;

public OnPluginStart()
{
	RegConsoleCmd("sm_buyshield", BuyShieldCMD);
	HookEvent("round_prestart", Event_RoundPreStart);
}

public Action BuyShieldCMD(int client, int args) 
{
	if(GetClientTeam(client) != 3)
	{
		PrintToChat(client, "Only CT Can Buy Shield.")
		return Plugin_Handled;
	}
	
	if(RequireBuyZone)
	{
		new bool:InBuyZone = view_as<bool>(GetEntProp(client, Prop_Send, "m_bInBuyZone"));
		if(!InBuyZone)
		{
			PrintToChat(client, "Sorry You're Not In a Buy Zone.");
			return Plugin_Handled;
		}
		if (BuyStartRoundTimer == null)
		{
			PrintToChat(client, "The Buy Time Has Expired For This Round.")
			return Plugin_Handled;
		}
	}
	
	new account = GetEntProp(client, Prop_Send, "m_iAccount");
	if(account < ShieldCost)
	{
		PrintToChat(client, "Sorry you don't have $5000 to buy the shield.");
		return Plugin_Handled;
	}
	
	new weaponIdx = GetPlayerWeaponSlot(client, 11);
	if(weaponIdx != -1)
	{
		if(IsValidEdict(weaponIdx) && IsValidEntity(weaponIdx))
		{
			decl String:className[128];
			GetEntityClassname(weaponIdx, className, sizeof(className));
			
			if(StrEqual("weapon_shield", className))
			{
				PrintToChat(client, "You are already carrying a shield.");
				return Plugin_Handled;
			}
		}
	}
	
	SetEntProp(client, Prop_Send, "m_iAccount", account - ShieldCost);
	GivePlayerItem(client, "weapon_shield");
	PrintToChat(client, "You've bought a shield.");
	
	return Plugin_Handled;
}

public Event_RoundPreStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Float:BuyTime = 45.0;
	ConVar cvarBuyTime = FindConVar("mp_buytime");
	
	if(cvarBuyTime != null)
		BuyTime = float(cvarBuyTime.IntValue);
		
	if (BuyStartRoundTimer != null)
	{
		KillTimer(BuyStartRoundTimer);
		BuyStartRoundTimer = null;
	}
	
	BuyStartRoundTimer = CreateTimer(BuyTime, StopBuying);
}


public Action StopBuying(Handle timer, any client)
{
	BuyStartRoundTimer = null;
	
	return Plugin_Stop;
}