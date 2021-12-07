#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.2fixed"

new Handle:_hGrenadeOverlay;
new Handle:_hHeadShotOverlay;
new Handle:_hKnifeOverlay;
new Handle:_hCTWinsOverlay;
new Handle:_hTWinsOverlay;
new Handle:_hKillOverlayNaming;
new Handle:_hMaxKillStreak;
new String:_sGrenadeOverlay[32];
new String:_sHeadShotOverlay[32];
new String:_sKnifeOverlay[32];
new String:_sCTWinsOverlay[32];
new String:_sTWinsOverlay[32];
new String:_sKillOverlayNaming[32];
new _iMaxKillStreak;
new _aiKillStreak[MAXPLAYERS+1];
new _abClientDead[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name = "Kill Message Overlays Basic Triggers",
	author = "Siang Chun & Black Haze",
	description = "Basic Triggers for Kill Message Overlays",
	version = PLUGIN_VERSION,
	url = "bslw.co.uk & beernweed.com"
}

public OnPluginStart()
{
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("round_end", Event_RoundEnd);
	
	_hGrenadeOverlay = CreateConVar("sm_killmessage_bs_grenade", "killsilver_grenade", "Name of the grenade kill overlay (no extension)");
	_hHeadShotOverlay = CreateConVar("sm_killmessage_bs_headshot", "killsilver_headshot", "Name of the headshot kill overlay (no extension)");
	_hKnifeOverlay = CreateConVar("sm_killmessage_bs_knife", "killsilver_knife", "Name of the knife kill overlay (no extension)");
	_hCTWinsOverlay = CreateConVar("sm_killmessage_bs_ctwins", "killsilver_ct_wins", "Name of the CT wins overlay (no extension)");
	_hTWinsOverlay = CreateConVar("sm_killmessage_bs_twins", "killsilver_t_wins", "Name of the T wins overlay (no extension)");
	_hKillOverlayNaming = CreateConVar("sm_killmessage_bs_killnaming", "killsilver_", "Naming convention for the kill overlays (numbers are added automatically,no extension)");
	_hMaxKillStreak = CreateConVar("sm_killmessage_bs_maxkillstreak", "4", "Amount of kills allowed in a killstreak (it'll restart at 1 after the end)");
	
	AutoExecConfig(true, "killmessage_basicsupport");	
}

public OnConfigsExecuted()
{
	GetConVarString(_hGrenadeOverlay, _sGrenadeOverlay, sizeof(_sGrenadeOverlay));
	GetConVarString(_hHeadShotOverlay, _sHeadShotOverlay, sizeof(_sHeadShotOverlay));
	GetConVarString(_hKnifeOverlay, _sKnifeOverlay, sizeof(_sKnifeOverlay));
	GetConVarString(_hCTWinsOverlay, _sCTWinsOverlay, sizeof(_sCTWinsOverlay));
	GetConVarString(_hTWinsOverlay, _sTWinsOverlay, sizeof(_sTWinsOverlay));
	GetConVarString(_hKillOverlayNaming, _sKillOverlayNaming, sizeof(_sKillOverlayNaming));
	_iMaxKillStreak = GetConVarInt(_hMaxKillStreak);

	ServerCommand("sm_killmessage_prepare %s",_sGrenadeOverlay);
	ServerCommand("sm_killmessage_prepare %s",_sHeadShotOverlay);
	ServerCommand("sm_killmessage_prepare %s",_sKnifeOverlay);
	ServerCommand("sm_killmessage_prepare %s",_sCTWinsOverlay);
	ServerCommand("sm_killmessage_prepare %s",_sTWinsOverlay);
	
	new iCounter;
	for (iCounter = 1; iCounter <= _iMaxKillStreak; iCounter++)
	{
		new String:sCounterTemp[64];
		IntToString(iCounter, sCounterTemp,sizeof(sCounterTemp));
		ServerCommand("sm_killmessage_prepare %s%s",_sKillOverlayNaming,sCounterTemp);
	}	
}

public OnClientPutInServer(client)
{
	if(client>0)
	{
		_aiKillStreak[client]=0;
		_abClientDead[client]=false;
	}
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client;
	client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client>0)
	{
		if(_abClientDead[client])
		{
			_aiKillStreak[client]=0;
			_abClientDead[client]=false;
		}
	}
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new String:sAttackerID[32];
	GetEventString(event, "attacker",sAttackerID, sizeof(sAttackerID));
	
	new victim = GetClientOfUserId(GetEventInt(event, "userid"))
	
	_abClientDead[victim]=true;
	
	if(attacker>0)
	{
		if(!IsFakeClient(attacker))
		{
			if(victim != attacker)
			{
				_aiKillStreak[attacker]++;
				if(_aiKillStreak[attacker]>_iMaxKillStreak)
				{
					_aiKillStreak[attacker]=1;
				}
				new bool:headshot = GetEventBool(event, "headshot");
				new String:weapon[32];
				GetEventString(event, "weapon",weapon, sizeof(weapon));

				if(StrEqual(weapon, "hegrenade"))
				{
					ServerCommand("sm_killmessage_show %s %s",sAttackerID,_sGrenadeOverlay);
				}
				else if(StrEqual(weapon,"knife"))
				{
					ServerCommand("sm_killmessage_show %s %s",sAttackerID,_sKnifeOverlay);
				}
				else if(headshot)
				{
					ServerCommand("sm_killmessage_show %s %s",sAttackerID,_sHeadShotOverlay);
				}
				else
				{
					new String:sKillStreakTemp[64];
					IntToString(_aiKillStreak[attacker], sKillStreakTemp,sizeof(sKillStreakTemp));
					ServerCommand("sm_killmessage_show %s %s%s",sAttackerID,_sKillOverlayNaming,sKillStreakTemp);
				}
			}
		}
	}
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iWinningTeam = GetEventInt(event, "winner");
	
	if (iWinningTeam == 2)
	{
		for (new iClientCounter = 1; iClientCounter <= MaxClients; iClientCounter++)
		{
			if(IsClientInGame(iClientCounter))
			{
				ServerCommand("sm_killmessage_show %i %s",GetClientUserId(iClientCounter),_sTWinsOverlay);
			}
		}
	}
	else if (iWinningTeam == 3)
	{
		for (new iClientCounter = 1; iClientCounter <= MaxClients; iClientCounter++)
		{
			if(IsClientInGame(iClientCounter))
			{
				ServerCommand("sm_killmessage_show %i %s",GetClientUserId(iClientCounter),_sCTWinsOverlay);
			}
		}
	}
}