/* Plugin Template generated by Pawn Studio */

/*
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

/* Version History
* 0.x	- Base code (setting up the correct convars and retrieving models).
* 1.0	- First release.
*/

// define
#define PLUGIN_VERSION "1.0"
#define PLUGIN_NAME "L4D Character selector"

// includes
#include <sourcemod>
#include <sdktools>

// Client numbers are dynamic, keep changing according to the spawn order
new bool:g_bSpawned[MAXPLAYERS+1];

// CVars Handles
new Handle:g_hActivate=INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = PLUGIN_NAME,
	author = "MagnoT",
	description = "[L4D] Lets players select a character to play with",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/" //http://driftinc.co.nr
}

public OnPluginStart()
{
	// Clean up the spawn variable (deprecated)
	for(new i=1; i<=GetMaxClients(); ++i)
	{
		g_bSpawned[i]=false;
	}
	
	// convars
	g_hActivate = CreateConVar("l4d_chars_enable", "1", "[L4D] Turn on/off character select panel", FCVAR_PLUGIN|FCVAR_NOTIFY);
	
	//commands
	
	RegConsoleCmd("say", Command_Say);
	
	// config file
	AutoExecConfig(true, "L4D_charselect");
}

public OnClientPutInServer(client)
{
	if (client)
	{
		if(GetConVarInt(g_hActivate)==1)
		CreateTimer(20.0, PlayerPanel, client);
	}
}

public CharPanel(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		switch (param2)
		{
		case 1:
			{
				// get prop
				new offset = FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter");
				new char = GetEntData(param1, offset, 1);
				
				// set char
				char = 1;
				SetEntData(param1, offset, char, 1, true);
				
				// update client model info
				decl String:model[] = "models/survivors/survivor_teenangst.mdl";
				SetEntityModel(param1, model);
				
				PrintToChat(param1, "\x05[ \x01You're now playing with Zoey");
			}
		case 2:
			{
				// get prop
				new offset = FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter");
				new char = GetEntData(param1, offset, 1);

				// set char
				char = 2;
				SetEntData(param1, offset, char, 1, true);
				
				// update client model info
				decl String:model[] = "models/survivors/survivor_biker.mdl";
				SetEntityModel(param1, model);
				
				PrintToChat(param1, "\x05[ \x01You're now playing with Francis");
			}
		case 3:
			{
				// get prop
				new offset = FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter");
				new char = GetEntData(param1, offset, 1);

				// set char
				char = 3;
				SetEntData(param1, offset, char, 1, true);
				
				// update client model info
				decl String:model[] = "models/survivors/survivor_manager.mdl";
				SetEntityModel(param1, model);
				
				PrintToChat(param1, "\x05[ \x01You're now playing with Louis");
			}
		case 4:
			{
				// get prop
				new offset = FindSendPropInfo("CTerrorPlayer", "m_survivorCharacter");
				new char = GetEntData(param1, offset, 1);

				// set char
				char = 4;
				SetEntData(param1, offset, char, 1, true);
				
				// update client model info
				decl String:model[] = "models/survivors/survivor_namvet.mdl";
				SetEntityModel(param1, model);
				
				PrintToChat(param1, "\x05[ \x01You're now playing with Bill");
			}
		}
		
	} else if (action == MenuAction_Cancel)
	{
		
	}
}

public Action:PlayerPanel(Handle:timer, any:client) //client, args)
{
	
	if(!IsClientInGame(client)) return;
	if(GetClientTeam(client)!=2) return;
	
	new Handle:panel = CreatePanel();
	SetPanelTitle(panel, "Choose a character:");

	DrawPanelText(panel, "     ");
	DrawPanelItem(panel, "Zoey");		//1
	DrawPanelItem(panel, "Francis"); 	//2
	DrawPanelItem(panel, "Louis"); 		//3
	DrawPanelItem(panel, "Bill"); 		//4

	if (g_bSpawned[client]==false)
	{
		SendPanelToClient(panel, client, CharPanel, 20);
		//g_bSpawned[client]=true;
	}

	CloseHandle(panel);
}

public Action:Command_Say(client, args)
{
	new String:text[192]
	GetCmdArgString(text, sizeof(text))

	new startidx = 0
	if (text[0] == '"')
	{
		startidx = 1
		/* Strip the ending quote, if there is one */
		new len = strlen(text);
		if (text[len-1] == '"')
		{
			text[len-1] = '\0'
		}
	}

	if (StrEqual(text[startidx], "/changechar"))
	{
		if(GetConVarInt(g_hActivate)==1)
		{
			CreateTimer(0.1, PlayerPanel, client);
		}
		/* Block the client's messsage from broadcasting */
		return Plugin_Handled
	}

	/* Let say continue normally */
	return Plugin_Continue
}