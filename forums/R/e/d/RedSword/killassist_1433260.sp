//Works for CS:S only (due to "player_hurt"'s "dmg_health" use)
/**
	Credits : 
	
	thetwistedpanda for an appreciated global code review (which was needed) and 
	information about various things I didn't know.
	
	Hunter-Digital for 1.6 version (Didn't use, thought it exist).
*/
#pragma semicolon 1

#define PLUGIN_VERSION "1.0.2"

public Plugin:myinfo =
{
	name = "Kill Assist",
	author = "RedSword / Bob Le Ponge",
	description = "Gives money for assisting a teamate on a kill.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

new g_dmgToClient[MAXPLAYERS + 1][MAXPLAYERS + 1]; //[victimId][attackId] , [0] is worthless =(

//CVars
new Handle:g_hEnabled; //bool 0/1
new Handle:g_hSplit; //bool 0/1
new Handle:g_hMinDmg; //Minimum dmg dealth required to get assist (Def. 25)
new Handle:g_hReward; //Def. 150
new Handle:g_hEnforceMax;

//Prevent re-running a function
new g_iAccount;

public OnPluginStart()
{
	//CVARs
	CreateConVar("killassistversion", PLUGIN_VERSION, "Kill Assist version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	g_hEnabled		= CreateConVar("kassist", "1.0", "If kill assist is enabled. 1=Yes, Def. 1", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hSplit		= CreateConVar("kassist_split", "1.0", "If kill assist cash is split amongst assisters. 1=Yes, Def. 1", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hMinDmg		= CreateConVar("kassist_minDmg", "25.0", "Minimum damage required to assist a kill.", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 1.0);
	g_hReward		= CreateConVar("kassist_cash", "150.0", "Kill assist cash awarded to assisters.", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 1.0);
	g_hEnforceMax	= CreateConVar("kassist_enfMax", "1.0", 
		"Prevent values from a cash kill to get over $16000 limit. Without it at roundstart it will be reset to $16000. 1=yes", 
		FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
		
	//Config
	AutoExecConfig(true, "killassist");
	
	//Hooks on events
	HookEvent("player_spawn", Event_Spawn); //change arrays : some 0s
	HookEvent("player_hurt", Event_Hurt); //change arrays : add value
	HookEvent("player_death", Event_Death); //check arrays : give assists / add money to players
	
	//Hook on kassist so we keep dmg array clean
	
	HookConVarChange(g_hEnabled, ConVarChange_kassist);
	
	//Prevent re-running a function
	g_iAccount = FindSendPropOffs("CCSPlayer", "m_iAccount");
}

//Clean array
public Event_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new clientId = GetClientOfUserId(GetEventInt(event, "userid"));
	if (clientId != 0 && 
			IsClientInGame(clientId) &&
			GetClientTeam(clientId) >= 2 &&
			GetClientTeam(clientId) <= 3)
	{
		CleanClientIdAsVictim(clientId);
	}
	
	return bool:Plugin_Handled;
}

//Add to array dmg given
public Event_Hurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victimId = GetClientOfUserId(GetEventInt(event, "userid"));
	new attackerId = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if (attackerId != 0 && //The world can't assist killing us.
			IsClientInGame(attackerId) &&
			IsClientInGame(victimId) &&
			GetClientTeam(victimId) != GetClientTeam(attackerId) && //We don't want our allies to assist killing ourself !
			attackerId <= MaxClients) //No random entities can be the killers (ex: barrel (:o))
	{
		g_dmgToClient[victimId][attackerId] += GetEventInt(event, "dmg_health");
	}
	
	return bool:Plugin_Handled;
}

//Give bounty
public Event_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victimId = GetClientOfUserId(GetEventInt(event, "userid"));
	new killerId = GetClientOfUserId(GetEventInt(event, "attacker"));
	new minDmg = GetConVarInt(g_hMinDmg);
	
	if (IsClientInGame(victimId))
	{
		decl assisters[MaxClients]; //Our assisters array
		new nbAssisters; //Its length
		
		for (new i = MaxClients; i >= 1; --i)
			if (g_dmgToClient[victimId][i] >= minDmg && killerId != i)//If the minimum dmg is done && the killer doesn't get assist cash
				assisters[nbAssisters++] = i;
		
		if (nbAssisters > 0) //If we have assisters, we calculate money to give them and give them
		{
			new moneyToGive = GetConVarInt(g_hReward);
			
			if (GetConVarInt(g_hSplit) == 1)
				moneyToGive /= nbAssisters;
				
			GiveMoney(assisters, nbAssisters, moneyToGive);
		}
	}
	
	return bool:Plugin_Handled;
}

//Clean array
public ConVarChange_kassist(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (newValue[0] == '1')
		for (new i = MaxClients; i >= 1; --i)
			for (new j = MaxClients; j >= 1; --j)
				g_dmgToClient[i][j] = 0;
}

//================================End hooks, Begin forward==================================
//Clean array
public OnClientDisconnect(clientId)
{
	if (IsClientInGame(clientId))
		CleanClientIdAsAttacker(clientId);
}
//================================End forward, begin action=================================

//Set to 0 every damage dealt by that player (when a player disconnect; since he won't die we don't care about how he much did get hurt)
public Action:CleanClientIdAsAttacker(any:clientId)
{
	for (new i = MaxClients; i >= 1; --i)
		g_dmgToClient[i][clientId] = 0;
}

//Set to 0 only damage received (prevent useless iterations; at player_spawn; so a player in DM could have assist)
public Action:CleanClientIdAsVictim(any:clientId)
{
	for (new i = MaxClients; i >= 1; --i)
		g_dmgToClient[clientId][i] = 0;
}

//Give money to the clients in the array
public Action:GiveMoney(assisters[], any:nbAssisters, any:cash)
{
	new enforcedMaxCash = GetConVarInt(g_hEnforceMax);
	
	for (new i; i < nbAssisters; ++i)
	{
		new newClientCash = GetEntData(assisters[i], g_iAccount) + cash;
		
		if (newClientCash > 16000 && enforcedMaxCash == 1)
			SetEntData(assisters[i], g_iAccount, 16000);
		else
			SetEntData(assisters[i], g_iAccount, newClientCash);
	}
}