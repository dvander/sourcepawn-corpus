/*
Copyright (C) 2011 Arnaud "SpheX" Couturier (arnaud.cout@gmail.com)
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.
You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.
*/

#pragma semicolon 1

#include <sourcemod>
#include <cstrike>

#define VERSION "1.0.0"

new players = 0;
new Admin = 0;

public Plugin:myinfo =  {
    name = "EUGATHERSYSTEM",
    author = "Sphex",
    description = "Gather Mod",
    version = VERSION,
    url = "http://www.sphex.fr/"
}

public OnPluginStart()
{
	players = CountPlayers();
	
	RegConsoleCmd("sm_lo3", Command_lo3);
	RegConsoleCmd("sm_ko3", Command_ko3);
	RegConsoleCmd("sm_rs", Command_RS);
	RegConsoleCmd("sm_alltalk", Command_Alltalk);
	RegConsoleCmd("sm_password", Command_Password);
	RegConsoleCmd("sm_gadmin", Command_gAdmin);
	RegConsoleCmd("sm_swap", Command_Swap);
	RegConsoleCmd("sm_map", Command_Map);
}

CountPlayers()
{
	new count = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && !IsFakeClient(i))
		{
			count++;
		}
	}
	return count;
}

public OnClientConnected(client)
{
	if (players == 0)
	{
		Admin = client;
	}
	players++;
}

public OnClientDisconnect(client)
{
	players--;
	
	if (client == Admin)
	{
		Admin = 0;
		CreateTimer(0.1, ResetGather, INVALID_HANDLE);
	}
}

public Action:Command_lo3(client, args)
{
	if (IsClientInGame(client))
	{
		if (client == Admin)
		{
			ServerCommand("zb_lo3");
			PrintToChatAll("[EUGATHERSYSTEM] L'admin du gather(%N) a exécuter (zb_lo3).", client);
		}
		else
		{
			PrintToChat(client, "[EUGATHERSYSTEM] Vous n'êtes pas l'admin du gather.");
		}
	}
}

public Action:Command_ko3(client, args)
{
	if (IsClientInGame(client))
	{
		if (client == Admin)
		{
			ServerCommand("zb_ko3");
			PrintToChatAll("[EUGATHERSYSTEM] L'admin du gather(%N) a exécuter (zb_ko3).", client);
		}
		else
		{
			PrintToChat(client, "[EUGATHERSYSTEM] Vous n'êtes pas l'admin du gather.");
		}
	}
}

public Action:Command_RS(client, args)
{
	if (IsClientInGame(client))
	{
		if (client == Admin)
		{
			ServerCommand("mp_restartgame 3");
			PrintToChatAll("[EUGATHERSYSTEM] L'admin du gather(%N) a relancer la partie.", client);
		}
		else
		{
			PrintToChat(client, "[EUGATHERSYSTEM] Vous n'êtes pas l'admin du gather.");
		}
	}
}

public Action:Command_Alltalk(client, args)
{
	new String:arg1[11];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	if (IsClientInGame(client))
	{
		if (client == Admin)
		{	
			if (StrEqual(arg1, "0") || StrEqual(arg1, "1"))
			{
				new String:command[32];
				Format(command, sizeof(command), "sv_alltalk %s", arg1);
				ServerCommand(command);
				PrintToChatAll("[EUGATHERSYSTEM] L'admin du gather(%N) a modifié le Alltalk en %s.", client, arg1);
			}
			else
			{
				PrintToChat(client, "[EUGATHERSYSTEM] Argument invalide, utilisez 0(désactive le alltalk) ou 1(active le alltalk)");
			}
		}
		else
		{
			PrintToChat(client, "[EUGATHERSYSTEM] Vous n'êtes pas l'admin du gather.");
		}
	}
}

public Action:Command_Password(client, args)
{
	new String:arg1[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	if (IsClientInGame(client))
	{
		if (client == Admin)
		{	
			new String:command[64];
			Format(command, sizeof(command), "sv_password %s", arg1);
			ServerCommand(command);
			PrintToChatAll("[EUGATHERSYSTEM] L'admin du gather(%N) a modifié le mot de passe serveur(Nouveau MDP: %s).", client, arg1);
		}
		else
		{
			PrintToChat(client, "[EUGATHERSYSTEM] Vous n'êtes pas l'admin du gather.");
		}
	}
}

public Action:Command_Map(client, args)
{
	new String:arg1[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	if (IsClientInGame(client))
	{
		if (client == Admin)
		{	
			if (IsMapValid(arg1))
			{
				new String:command[64];
				Format(command, sizeof(command), "changelevel %s", arg1);
				ServerCommand(command);
				PrintToChatAll("[EUGATHERSYSTEM] L'admin du gather(%N) a lancer un changement de map(%s).", client, arg1);
			}
			else
			{
				PrintToChat(client, "[EUGATHERSYSTEM] Map spécifiée invalide.");
			}
		}
		else
		{
			PrintToChat(client, "[EUGATHERSYSTEM] Vous n'êtes pas l'admin du gather.");
		}
	}
}

public Action:Command_gAdmin(client, args)
{
	if (IsClientInGame(client))
	{
		if (IsClientInGame(Admin))
		{
			PrintToChat(client, "[EUGATHERSYSTEM] L'admin du Gather est %N.", Admin);
		}
		else
		{
			PrintToChat(client, "[EUGATHERSYSTEM] Il n'y a aucun admin du Gather connectés.");
		}
	}
}

public Action:Command_Swap(client, args)
{
	new String:arg1[64];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	if (IsClientInGame(client))
	{
		if (client == Admin)
		{	
			new tClient = Client_FindByName(arg1, true, false);
			
			if (GetClientTeam(tClient) == 3)
			{
				CS_SwitchTeam(tClient, 2);
				PrintToChatAll("[EUGATHERSYSTEM] L'admin du gather(%N) a changer %N d'équipe(Terroristes).", client, tClient);
			}
			else if (GetClientTeam(tClient) == 2)
			{
				CS_SwitchTeam(tClient, 3);
				PrintToChatAll("[EUGATHERSYSTEM] L'admin du gather(%N) a changer %N d'équipe(Anti-Terroristes).", client, tClient);
			}
			else
			{
				PrintToChat(client, "[EUGATHERSYSTEM] Vous ne pouvez pas swap ce joueur(en spectateur ou non connecté).");
			}
		}
		else
		{
			PrintToChat(client, "[EUGATHERSYSTEM] Vous n'êtes pas l'admin du gather.");
		}
	}
}

public Action:ResetGather(Handle:timer, any:client)
{
	for (new i = 1; i < MaxClients; i++)
	{
		if (IsClientConnected(i))
		{
			KickClient(i, "L'admin du Gather s'est déconnecté.");
		}
	}
	ServerCommand("exec server.cfg");
}

//Thanks smlib
stock Client_FindByName(const String:name[], bool:partOfName=true, bool:caseSensitive=false)
{
	new String:clientName[64];
	for (new client=1; client <= MaxClients; client++) {
		if (!IsClientAuthorized(client)) {
			continue;
		}
		
		GetClientName(client, clientName, sizeof(clientName));

		if (partOfName) {
			if (StrContains(clientName, name, caseSensitive) != -1) {
				return client;
			}
		}
		else if (StrEqual(name, clientName, caseSensitive)) {
			return client;
		}
	}
	
	return -1;
}