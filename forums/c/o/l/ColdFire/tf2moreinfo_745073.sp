
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <logging>


public Plugin:myinfo = 
{
	name = "TF2 More Information",
	author = "ColdFire",
	description = "Log medic/engy heal points and engy's teleports",
	version = "1.0",
	url = "http://www.coldfire.info/"
};

public OnPluginStart()
{
  //HookEvent("player_disconnect", Event_PlayerDisconnect) ;
}

public OnClientDisconnect(client) {
  new healing = 0 ;
  new teleports = 0 ;
  decl String:steamid[64] ;
  decl String:name[32] ;
  decl Int:userId ;
  healing = GetEntProp(client, Prop_Send, "m_iHealPoints") ;
  teleports = GetEntProp(client, Prop_Send, "m_iTeleports")
  GetClientAuthString(client, steamid, sizeof(steamid)) ;
  GetClientName(client, name, sizeof(name)) ;
  userId = GetClientUserId(client) ;
  decl String:team[64];
  GetTeamName(GetClientTeam(client), team, sizeof(team));  
  LogToGame("\"%s<%d><%s><%s>\" triggered \"healed\" (heal \"%d\")",
      name,
      userId,
      steamid,
      team,
      healing) ;
  LogToGame("\"%s<%d><%s><%s>\" triggered \"teleported\" (teleport \"%d\")",
      name,
      userId,
      steamid,
      team,
      teleports) ;
}

