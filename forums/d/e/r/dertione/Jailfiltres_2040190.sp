#include <sourcemod>
#include <geoip>
#include <colors>
#include <cstrike>


#define PLUGIN_VERSION "1.1.1"


new Handle:jb_filters_mode;
new Handle:jb_filters_countries;
new Handle:jb_TimeOfRespawn;
new Handle:jb_TeamBlocked;
new Handle:jb_TeamSwap;

new g_respawn;

public Plugin:myinfo =
{
	name = "Swap Country Filter",
	author = "Dertione",
	description = "Swap team 2 a foreigner in Jailbreak mod",
	version = PLUGIN_VERSION,
	url = "http://forum.supreme-elite.fr/"
};

/* LE PLUGIN START */
public OnPluginStart()
{
	CreateConVar("jb_filters_version", PLUGIN_VERSION, "", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY);
	jb_filters_countries = CreateConVar("jb_filters_countries", "FRA CAN BEL CHE GUF DZA MAR TUN MCO", "Country under the standard Code ISO 3166-1 alpha 3 (Bang a search engine to know the initials of countries)", FCVAR_PLUGIN);
	jb_filters_mode = CreateConVar("jb_filters_mode", "0", "1 For that countries above are blocked /0 For that countries above are authorized", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	jb_TimeOfRespawn = CreateConVar("jb_TimeOfRespawn", "45.0", "Time to respawn a person when she is moved", FCVAR_PLUGIN, true, 0.0, true, 70.0);
	jb_TeamBlocked = CreateConVar("jb_TeamBlocked", "3", "Team is prohibed (default 3 because its specificaly for jailbreakmod", FCVAR_PLUGIN, true, 1.0, true, 3.0);
	jb_TeamSwap = CreateConVar("jb_TeamSwap", "2", "Team for swap (default 2 or 1 because its specificaly for jailbreakmod", FCVAR_PLUGIN, true, 1.0, true, 3.0);
	AutoExecConfig(true, "jb_filters_countries");
	
	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("round_start", EventRoundStart, EventHookMode_PostNoCopy);
}

/* LE JOUEUR CHOISIS UNE TEAM */
public Action:Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	/* ON CREE LE CLIENT ET LA TEAM */
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new team = GetEventInt(event, "team");
	PrintToChat(client, "tu changes d'equipe");
	/* ON VÉRIFIE LA TEAM DU CLIENT */
	if(team == GetConVarInt(jb_TeamBlocked))
	{
		/* ON CREE DES VALEURS A CARACTERES */
		PrintToChat(client, "tu changes d'equipe CT");
		new String:ip[16];
		new String:code3[3];
		
		/* ON REPREND L'IP DU CLIENT */
		GetClientIP(client, ip, sizeof(ip));
		/* ON REPREND LE PAYS DE L'IP */
		GeoipCode3(ip, code3);

		/* ON VERIFIE QUE L'IP EST REJETER OU PAS */
		if(Reject(code3))
		{
			/* ON CREE LE TIMER QUI VAS SWAP LE CLIENT */
			CreateTimer(0.1, jb_filtersTimer, client);
			CreateTimer(1.0, jb_filtersTimer2, client);
			
		}
	}
	return Plugin_Handled;
}


public EventRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_respawn=1;
	CreateTimer(GetConVarFloat(jb_TimeOfRespawn), RespawnTimer);
}

/* BOOL QUI VERIFIE QUE LE CLIENT EST REJETER OU PAS */
public bool:Reject(const String:code3[])
{
	/* ON VERIFIE QUE LE CODE N'EST PAS VIDE */
	if(StrEqual("", code3))
	return false;
	
	/* ON CREE DES VALEURS A CARACTERES */
	new String:str[255];
	new String:arr[100][4];
	
	/* ON REPREND LA CVAR */
	GetConVarString(jb_filters_countries, str, 255);
	
	/* ON SEPARE TOUT LES INITIALES DES PAYS, avec comme ciseaux le caractère "espace" */
	new total = ExplodeString(str, " ", arr, 100, 4);
	if(total == 0) strcopy(arr[total++], 4, str);

	/* ON VERIFIE LA VALEUR DE LA CVAR */
	if(GetConVarBool(jb_filters_mode))
	{
		for(new i = 0; i < total; i++)
		{
			/*ON VERIFIQUE QUE UN CODE DANS LA CVAR EST EGAL AU CODE DU PAYS */
			
			if(StrEqual(arr[i], code3))    //AVEC CONVAR
			{                                    //AVEC CONVAR
				return true;                    //AVEC CONVAR
			}                                    //AVEC CONVAR
			
		}
		return false;
	}
	else
	{
		for(new i = 0; i < total; i++)
		{
			/*ON VERIFIQUE QUE UN CODE DANS LA CVAR EST EGAL AU CODE DU PAYS */
			
			if(StrEqual(arr[i], code3))
			{
				return false;
			}
			
		}
		return true;
	}
}

/* TIMER QUI CHANGE LA TEAM */
public Action:jb_filtersTimer(Handle:timer, any:client)
{
	/* CHANGEMENT DE LA TEAM DU CLIENT */
	CS_SwitchTeam(client, GetConVarInt(jb_TeamSwap));
	if(g_respawn==1)
	{
		CS_RespawnPlayer(client);
	}
}

public Action:jb_filtersTimer2(Handle:timer, any:client)
{
	CPrintToChat(client,"{green}Your country is restricted. You are obliged to play in terrorist.");
	CPrintToChat(client,"{red}If you are fluent in French, please make a request with the staff to remove this limitation.");
}

public Action:RespawnTimer(Handle:timer, any:client)
{
	/* CHANGEMENT DE LA TEAM DU CLIENT */
	g_respawn=0;
}