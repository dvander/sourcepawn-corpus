#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>
#include <morecolors>

#define VERSION "v1.2"

new Handle:rondas_mismo_gk = INVALID_HANDLE;

new Handle:sm_soccermod_enable;
new bool:PorteroCT, PorteroT;
new jugadorPorteroCT, jugadorPorteroT;
new contarRondas;

public Plugin:myinfo =
{
	name = "SM SoccerMod",
	author = "Franc1sco Steam: franug",
	description = "Mod of Soccer for CS:S",
	version = VERSION,
	url = "http://servers-cfg.foroactivo.com/"
}

public OnPluginStart()
{
	CreateConVar("sm_SoccerMod", VERSION, "Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	sm_soccermod_enable = CreateConVar("sm_soccermod_enable", "1", "Enables/disables all features of the plugin.", FCVAR_NONE, true, 0.0, true, 1.0);

	HookEvent("round_start", Ronda_Empieza);
	HookEvent("round_end",Event_RoundEnd);
	HookEvent("player_spawn", Event_PlayerSpawn);
	
	RegConsoleCmd("sm_gk",  Command_Portero);
	RegConsoleCmd("sm_nogk",  Command_quitarPortero);
	RegAdminCmd("sm_removegkt", Command_quitarPorteroT,	ADMFLAG_BAN, "Quitar portero del equipo 'T'");
	RegAdminCmd("sm_removegkct", Command_quitarPorteroCT,	ADMFLAG_BAN, "Quitar portero del equipo 'CT'");
	RegAdminCmd("sm_removegkall", Command_quitarPorteroAll,	ADMFLAG_BAN, "Quitar portero de los dos equipos");
	rondas_mismo_gk = CreateConVar("sm_rondas_mismo_gk", "0", "Rondas con el mismo capitan");
}

public OnMapStart()
{
  if (GetConVarInt(sm_soccermod_enable) == 1)
  {
        AddFileToDownloadsTable("materials/models/player/soccermod/termi/2010/home2/skin_foot_a2.vmt");
        AddFileToDownloadsTable("materials/models/player/soccermod/termi/2010/home2/skin_foot_a2.vtf");
        AddFileToDownloadsTable("models/player/soccermod/termi/2010/home2/ct_urban.dx80.vtx");
        AddFileToDownloadsTable("models/player/soccermod/termi/2010/home2/ct_urban.dx90.vtx");
        AddFileToDownloadsTable("models/player/soccermod/termi/2010/home2/ct_urban.mdl");
        AddFileToDownloadsTable("models/player/soccermod/termi/2010/home2/ct_urban.phy");
        AddFileToDownloadsTable("models/player/soccermod/termi/2010/home2/ct_urban.sw.vtx");
        AddFileToDownloadsTable("models/player/soccermod/termi/2010/home2/ct_urban.vvd");
        AddFileToDownloadsTable("models/player/soccermod/termi/2010/home2/ct_urban.xbox.vtx");
        AddFileToDownloadsTable("materials/models/player/soccermod/termi/2010/away2/skin_foot_a2.vmt");
        AddFileToDownloadsTable("materials/models/player/soccermod/termi/2010/away2/skin_foot_a2.vtf");
        AddFileToDownloadsTable("models/player/soccermod/termi/2010/away2/ct_urban.dx80.vtx");
        AddFileToDownloadsTable("models/player/soccermod/termi/2010/away2/ct_urban.dx90.vtx");
        AddFileToDownloadsTable("models/player/soccermod/termi/2010/away2/ct_urban.mdl");
        AddFileToDownloadsTable("models/player/soccermod/termi/2010/away2/ct_urban.phy");
        AddFileToDownloadsTable("models/player/soccermod/termi/2010/away2/ct_urban.sw.vtx");
        AddFileToDownloadsTable("models/player/soccermod/termi/2010/away2/ct_urban.vvd");
        AddFileToDownloadsTable("models/player/soccermod/termi/2010/away2/ct_urban.xbox.vtx");
        AddFileToDownloadsTable("materials/models/player/soccer_mod/termi/2011/gkaway/skin_foot_a2.vmt");
        AddFileToDownloadsTable("materials/models/player/soccer_mod/termi/2011/gkaway/skin_foot_a2.vtf");
        AddFileToDownloadsTable("materials/models/player/soccer_mod/termi/2011/gkhome/skin_foot_a2.vmt");
        AddFileToDownloadsTable("materials/models/player/soccer_mod/termi/2011/gkhome/skin_foot_a2.vtf");
        AddFileToDownloadsTable("models/player/soccer_mod/termi/2011/gkaway/ct_urban.dx80.vtx");
        AddFileToDownloadsTable("models/player/soccer_mod/termi/2011/gkaway/ct_urban.dx90.vtx");
        AddFileToDownloadsTable("models/player/soccer_mod/termi/2011/gkaway/ct_urban.mdl");
        AddFileToDownloadsTable("models/player/soccer_mod/termi/2011/gkaway/ct_urban.phy");
        AddFileToDownloadsTable("models/player/soccer_mod/termi/2011/gkaway/ct_urban.sw.vtx");
        AddFileToDownloadsTable("models/player/soccer_mod/termi/2011/gkaway/ct_urban.vvd");
        AddFileToDownloadsTable("models/player/soccer_mod/termi/2011/gkhome/ct_urban.dx80.vtx");
        AddFileToDownloadsTable("models/player/soccer_mod/termi/2011/gkhome/ct_urban.dx90.vtx");
        AddFileToDownloadsTable("models/player/soccer_mod/termi/2011/gkhome/ct_urban.mdl");
        AddFileToDownloadsTable("models/player/soccer_mod/termi/2011/gkhome/ct_urban.phy");
        AddFileToDownloadsTable("models/player/soccer_mod/termi/2011/gkhome/ct_urban.sw.vtx");
        AddFileToDownloadsTable("models/player/soccer_mod/termi/2011/gkhome/ct_urban.vvd");

	//PrecacheModel("models/player/soccermod/termi/2010/away2/ct_urban.mdl");
	//PrecacheModel("models/player/soccermod/termi/2010/home2/ct_urban.mdl");
  }
  PrecacheModel("models/player/soccermod/termi/2010/home2/ct_urban.mdl");
  PrecacheModel("models/player/soccermod/termi/2010/away2/ct_urban.mdl");
  PrecacheModel("models/player/soccer_mod/termi/2011/gkhome/ct_urban.mdl");
  PrecacheModel("models/player/soccer_mod/termi/2011/gkaway/ct_urban.mdl");
}

public OnClientPutInServer(client)
{
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
  if (GetConVarInt(sm_soccermod_enable) == 1)
  {
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);

        if (GetClientTeam(client) == CS_TEAM_T)
        {
			if(PorteroT)
			{
				if(jugadorPorteroT == client)
				{
					SetEntityModel(client,"models/player/soccer_mod/termi/2011/gkhome/ct_urban.mdl");
					SetEntityHealth(client, 250);
				}
				else
				{
					SetEntityModel(client,"models/player/soccermod/termi/2010/home2/ct_urban.mdl");
					SetEntityHealth(client, 250);
				}
			}
			else
			{
				SetEntityModel(client,"models/player/soccermod/termi/2010/home2/ct_urban.mdl");
				SetEntityHealth(client, 250);
			}
        }
        else if (GetClientTeam(client) == CS_TEAM_CT)
        {
			if(PorteroCT)
			{
				if(jugadorPorteroCT == client)
				{
					SetEntityModel(client,"models/player/soccer_mod/termi/2011/gkaway/ct_urban.mdl");
					SetEntityHealth(client, 250);
				}
				else
				{
					SetEntityModel(client,"models/player/soccermod/termi/2010/away2/ct_urban.mdl");
					SetEntityHealth(client, 250);
				}
			}
			else
			{
				SetEntityModel(client,"models/player/soccermod/termi/2010/away2/ct_urban.mdl");
				SetEntityHealth(client, 250);
			}
        }
  }
}

public Action:Ronda_Empieza(Handle:event,const String:name[],bool:dontBroadcast)
{
	if (GetConVarInt(sm_soccermod_enable) == 1)
	{
		ServerCommand("phys_pushscale 900");
		ServerCommand("phys_timescale 1");
		ServerCommand("sv_turbophysics 0");
		if(GetConVarInt(rondas_mismo_gk) == 0)
		{
			ResetearEquipos();
		}
		else if(contarRondas == GetConVarInt(rondas_mismo_gk))
		{
			ResetearEquipos();
		}
	}
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	contarRondas++;
	
	if(contarRondas > GetConVarInt(rondas_mismo_gk))
	{
		contarRondas = 0;
	}
}

public Action:Command_Portero(client, args)
{
	if(IsValidClient(client))
	{
		if(GetClientTeam(client) == CS_TEAM_T)
		{
			if(!PorteroT)
			{
				PonerPortero(client, CS_TEAM_T);
			}
			else
			{
				new String:nombreJugador[32];
				GetClientName(jugadorPorteroT, nombreJugador, 32);
				CPrintToChat(client, "{default}[{green}SM_SoccerMod{default}] {lightgreen}Actualmente %s es el portero del equipo 'T'. Tu no puedes serlo ahora", nombreJugador);
			}
		}
		
		if(GetClientTeam(client) == CS_TEAM_CT)
		{
			if(!PorteroCT)
			{
				PonerPortero(client, CS_TEAM_CT);
			}
			else
			{
				new String:nombreJugador[32];
				GetClientName(jugadorPorteroCT, nombreJugador, 32);
				CPrintToChat(client, "{default}[{green}SM_SoccerMod{default}] {lightgreen}Actualmente %s es el portero del equipo 'CT'. Tu no puedes serlo ahora", nombreJugador);
			}
		}
	}
}

public Action:Command_quitarPortero(client, args)
{
	if(GetClientTeam(client) == CS_TEAM_T)
	{
		if(PorteroT)
		{
			if(jugadorPorteroT == client)
			{
				SetEntityModel(client,"models/player/soccermod/termi/2010/home2/ct_urban.mdl");
				PorteroT = false;
				new String:nombreJugador[32];
				GetClientName(jugadorPorteroT, nombreJugador, 32);
				CPrintToChat(client, "{default}[{green}SM_SoccerMod{default}] {lightgreen}El jugador %s ya no es el portero del equipo 'T'.", nombreJugador);
			}
			else
			{
				CPrintToChat(client,"{default}[{green}SM_SoccerMod{default}] {lightgreen} Tu no eres el portero de tu equipo!!");
			}
		}
		else
		{
			CPrintToChat(client,"{default}[{green}SM_SoccerMod{default}] {lightgreen}No hay portero en tu equipo, escribe !gk para serlo");
		}
	}
	
	if(GetClientTeam(client) == CS_TEAM_CT)
	{
		if(PorteroCT)
		{
			if(jugadorPorteroCT == client)
			{
				SetEntityModel(client,"models/player/soccermod/termi/2010/away2/ct_urban.mdl");
				PorteroCT = false;
				new String:nombreJugador[32];
				GetClientName(jugadorPorteroCT, nombreJugador, 32);
				CPrintToChat(client, "{default}[{green}SM_SoccerMod{default}] {lightgreen}El jugador %s ya no es el portero del equipo 'CT'.", nombreJugador);
			}
			else
			{
				CPrintToChat(client,"{default}[{green}SM_SoccerMod{default}] {lightgreen}Tu no eres el portero de tu equipo!!");
			}
		}
		else
		{
			CPrintToChat(client,"{default}[{green}SM_SoccerMod{default}] {lightgreen}No hay portero en tu equipo, escribe !gk para serlo");
		}
	}
}

public Action:Command_quitarPorteroAll(client, args)
{
	if(PorteroT)
	{
		SetEntityModel(jugadorPorteroT,"models/player/soccermod/termi/2010/home2/ct_urban.mdl");
		PorteroCT = false;
		CPrintToChatAll("{default}[{green}SM_SoccerMod{default}] {lightgreen}El equipo 'T' ya no tiene portero.");
	}
	else
	{
		CPrintToChat(client, "{default}[{green}SM_SoccerMod{default}] {lightgreen}No hay portero en el equipo 'T'.");
	}
	
	if(PorteroCT)
	{
		SetEntityModel(jugadorPorteroCT,"models/player/soccermod/termi/2010/away2/ct_urban.mdl");
		PorteroCT = false;
		CPrintToChatAll("{default}[{green}SM_SoccerMod{default}] {lightgreen}El equipo 'CT' ya no tiene portero.");
	}
	else
	{
		CPrintToChat(client, "{default}[{green}SM_SoccerMod{default}] {lightgreen}No hay portero en el equipo 'CT'.");
	}
}

public Action:Command_quitarPorteroT(client, args)
{
	if(PorteroT)
	{
		SetEntityModel(jugadorPorteroT,"models/player/soccermod/termi/2010/home2/ct_urban.mdl");
		PorteroCT = false;
		CPrintToChatAll("{default}[{green}SM_SoccerMod{default}] {lightgreen}El equipo 'T' ya no tiene portero.");
	}
	else
	{
		CPrintToChat(client, "{default}[{green}SM_SoccerMod{default}] {lightgreen}No hay portero en el equipo 'T'.");
	}
}

public Action:Command_quitarPorteroCT(client, args)
{
	if(PorteroCT)
	{
		SetEntityModel(jugadorPorteroCT,"models/player/soccermod/termi/2010/away2/ct_urban.mdl");
		PorteroCT = false;
		CPrintToChatAll("{default}[{green}SM_SoccerMod{default}] {lightgreen}El equipo 'CT' ya no tiene portero.");
	}
	else
	{
		CPrintToChat(client, "{default}[{green}SM_SoccerMod{default}] {lightgreen}No hay portero en el equipo 'CT'.");
	}
}

PonerPortero(client, equipo)
{
	if(equipo == CS_TEAM_T)
	{
		SetEntityModel(client,"models/player/soccer_mod/termi/2011/gkhome/ct_urban.mdl");
		PorteroT = true;
		jugadorPorteroT = client;
		CPrintToChat(client, "{default}[{green}SM_SoccerMod{default}] {lightgreen}Ahora eres el portero de tu equipo!");
		new String:nombreJugador[32];
		GetClientName(client, nombreJugador, 32);
		CPrintToChatAll("{default}[{green}SM_SoccerMod{default}] {lightgreen}%s es ahora el portero del equipo 'T'.", nombreJugador);
	}
	else if(equipo == CS_TEAM_CT)
	{
		SetEntityModel(client,"models/player/soccer_mod/termi/2011/gkaway/ct_urban.mdl");
		PorteroCT = true;
		jugadorPorteroCT = client;
		CPrintToChat(client, "{default}[{green}SM_SoccerMod{default}] {lightgreen}Ahora eres el portero de tu equipo!");
		new String:nombreJugador[32];
		GetClientName(client, nombreJugador, 32);
		CPrintToChatAll("{default}[{green}SM_SoccerMod{default}] {lightgreen}%s es ahora el portero del equipo 'CT'.", nombreJugador);
	}
}

ResetearEquipos()
{
	for(new i=0;i<MaxClients;i++)
	{
		if(IsValidClient(i))
		{
			if (GetClientTeam(i) == CS_TEAM_T)
			{
				SetEntityModel(i,"models/player/soccermod/termi/2010/home2/ct_urban.mdl");
			}
			if (GetClientTeam(i) == CS_TEAM_CT)
			{
				SetEntityModel(i,"models/player/soccermod/termi/2010/away2/ct_urban.mdl");
			}
		}
	}
	PorteroCT = false;
	PorteroT = false;
}

public Action:OnTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype)
{
  if (GetConVarInt(sm_soccermod_enable) == 1)
  {
      if (damagetype & DMG_FALL || damagetype & DMG_BULLET || damagetype & DMG_SLASH)
      {
            return Plugin_Handled;
      }
      else if (damagetype & DMG_CRUSH)
      {
            damage = 0.0;
            return Plugin_Changed;
      }
  }
  return Plugin_Continue;
}

public IsValidClient( client ) 
{ 
	if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) || !IsPlayerAlive(client)) 
	return false; 
	
	return true; 
}