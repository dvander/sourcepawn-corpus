#include <sourcemod>
#include <sdktools>

#undef REQUIRE_PLUGIN
#include <mapchooser>
#define REQUIRE_PLUGIN

#undef REQUIRE_EXTENSIONS
#include <cstrike>
#define REQUIRE_EXTENSIONS

#pragma semicolon 1


#define DATA "1.1.3"


new MuertesCT;
new MuertesT;

new bool:GanadoCT;
new bool:GanadoT;

new bool:is_cstrike = false;
new bool:is_mapchooser = false;

new String:ModName[21];

new Handle:cvar_Goal = INVALID_HANDLE;


public Plugin:myinfo =
{
	name = "SM Frag Battle",
	author = "Franc1sco Steam: franug",
	description = "Frag battle",
	version = DATA,
	url = "www.uea-clan.com"
};


public OnPluginStart()
{
	HookEvent("player_death", playerDeath);

	cvar_Goal = CreateConVar("sm_fragbattle_goal", "500", "Goal for win");

	CreateConVar("sm_fragbattle_version", DATA, "version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);

	GetGameFolderName(ModName, sizeof(ModName));
	
	if(StrEqual(ModName, "cstrike", false) || StrEqual(ModName, "csgo", false)) is_cstrike = true;
	else is_cstrike = false;

}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "mapchooser"))
	{
		is_mapchooser = true;
	}
	else if (StrEqual(name, "cstrike"))
	{
		is_cstrike = true;
	}
}


public OnMapStart()
{
	MuertesCT = 0;
	MuertesT = 0;
	GanadoCT = false;
	GanadoT = false;
	if(!StrEqual(ModName, "csgo", false)) CreateTimer(1.0, Temporizador, _,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Temporizador(Handle:timer)
{
	decl String:Mensaje[512];

	if(GanadoCT) Format(Mensaje, sizeof(Mensaje), "Frag Battle\nCounter Terrorist Win!\nT          CT\n%i          %i", GetConVarInt(cvar_Goal), MuertesT, MuertesCT);
	else if(GanadoT) Format(Mensaje, sizeof(Mensaje), "Frag Battle\nTerrorist Win!\nT          CT\n%i          %i", GetConVarInt(cvar_Goal), MuertesT, MuertesCT);
	else Format(Mensaje, sizeof(Mensaje), "Frag Battle\nGoal: %i\nT          CT\n%i          %i", GetConVarInt(cvar_Goal), MuertesT, MuertesCT);

	for (new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			// Send our message
			new Handle:hBuffer = StartMessageOne("KeyHintText", i); 
			BfWriteByte(hBuffer, 1); 
			BfWriteString(hBuffer, Mensaje); 
			EndMessage();
		}
	}
}

public Action:playerDeath(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
 	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(!attacker || GetClientTeam(attacker) == GetClientTeam(client))
		return;

	if(GanadoCT || GanadoT)
		return;

	new Team = GetClientTeam(attacker);

	if(Team == 2) MuertesT++;
	else if(Team == 3) MuertesCT++;

	new Goal = GetConVarInt(cvar_Goal);
	if(MuertesT >= Goal) FinT();
	else if(MuertesCT >= Goal) FinCT();
}

FinCT()
{
	GanadoCT = true;
	PrintToChatAll("\x04[Frag Battle] \x03Counter-Terrorist win the Frag Battle!");

	if(is_mapchooser)
        	InitiateMapChooserVote(MapChange_Instant);
	else
	{

		new Handle:timelimit = FindConVar("mp_timelimit");
    
		if (timelimit == INVALID_HANDLE)
		{
			return;
		}
    
		new flags = GetConVarFlags(timelimit) & FCVAR_NOTIFY;
		SetConVarFlags(timelimit, flags);
    
		SetConVarInt(timelimit, 1);
	}



	if(is_cstrike) CS_TerminateRound(5.0, CSRoundEnd_CTWin);
	else
	{
		for (new client=1; client<=MaxClients; ++client)
			if (IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2)
				ForcePlayerSuicide(client);
	}

}

FinT()
{
	GanadoT = true;
	PrintToChatAll("\x04[Frag Battle] \x03Terrorist win the Frag Battle!");

	if(is_mapchooser) InitiateMapChooserVote(MapChange_Instant);
	else
	{

		new Handle:timelimit = FindConVar("mp_timelimit");
    
		if (timelimit == INVALID_HANDLE)
		{
			return;
		}
    
		new flags = GetConVarFlags(timelimit) & FCVAR_NOTIFY;
		SetConVarFlags(timelimit, flags);
    
		SetConVarInt(timelimit, 1);
	}



	if(is_cstrike) CS_TerminateRound(5.0, CSRoundEnd_TerroristWin);
	else
	{
		for (new client=1; client<=MaxClients; ++client)
			if (IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == 3)
				ForcePlayerSuicide(client);
	}
}

public OnClientDisconnect(client)
{
	CreateTimer(2.0, comprobar);
}

public Action:comprobar(Handle:timer)
{
	new bool:empty = true;
	for (new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			empty = false;
			break;
		}
	}
	
	if(empty)
	{
		MuertesCT = 0;
		MuertesT = 0;
		GanadoCT = false;
		GanadoT = false;
	}
}




