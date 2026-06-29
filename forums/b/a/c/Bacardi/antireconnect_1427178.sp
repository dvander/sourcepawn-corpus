#define PLUGIN_VERSION "0.1"

new String:steamids[100][25];	// Storage 100 steamid, buffer 25 lenght
new times[100];	// Storage 100 timestamp

new Handle:antireconnect_time = INVALID_HANDLE;
new rejecttime;

new Handle:antireconnect_penalty = INVALID_HANDLE;
new bool:penalty;

public Plugin:myinfo =
{
	name = "Anti-reconnect",
	author = "Bacardi",
	description = "Kick all reconnect players",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
}


public OnPluginStart()
{
	CreateConVar("antireconnect_version", PLUGIN_VERSION, "Plugin current version", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD);

	RegAdminCmd("sm_antireconnect_list", AdmCmdAntiReConnectList, ADMFLAG_KICK, "List antireconnect saved disconnected steamids");

	antireconnect_time = CreateConVar("antireconnect_time", "20", "Prevent player join server\n - in this many seconds after disconnect", _, true, 0.0);
	HookConVarChange(antireconnect_time, ConVarChange);
	rejecttime = GetConVarInt(antireconnect_time);

	antireconnect_penalty = CreateConVar("antireconnect_penalty", "0", "Add +antireconnect_time every false connect\n - will add in first false connect", _, true, 0.0, true, 1.0);
	HookConVarChange(antireconnect_penalty, ConVarChange);
	penalty = GetConVarBool(antireconnect_penalty);

	HookEvent("player_disconnect", PlayerDisconnect);	// Hook players "disconnect", not affect when map change :)
}

public ConVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	rejecttime = GetConVarInt(antireconnect_time);	// Update reject time
	penalty = GetConVarBool(antireconnect_penalty);	// Update penalty state
}

public OnMapStart()
{
	new time = GetTime();

	for(new i = 0; i < 100; i++) // Loop through 100 slots
	{
		if(StrContains(steamids[i], "STEAM_") == 0 && times[i] - time + rejecttime < 0)	// Found steamid from steamids[slot] and rejecttime pass
		{
			steamids[i][0] = '\0';	// Remove Steamid
			times[i]	= 0;	// Reset time
		}
	}
}

public Action:AdmCmdAntiReConnectList(client, args)
{
	new String:temp1[512][30];	// Collect here temporary
	new String:tempidtime[30];	// Collect here temporary ids and time
	new String:temp2[512];		// Storage text output here
	new time = rejecttime - GetTime();
	new count = 0;

	for(new i = 0; i < 100; i++) // Loop through 100 slots
	{
		if(StrContains(steamids[i], "STEAM_") == 0)	// Found steamid from steamids[slot]
		{
			Format(tempidtime, sizeof(tempidtime), "%s  %i", steamids[i], time + times[i]);
			temp1[count] = tempidtime;	// Collect steamid and time in temporary string
			count++;	// Count
		}
	}

	ImplodeStrings(temp1, count, "\n", temp2, sizeof(temp2));	// Make all steamids with timeleft string to one string
	PrintToConsole(client, temp2);	// Print to admin console
	return Plugin_Handled;
}

public OnClientPostAdminCheck(client)
{
	// Client is not 0, is not BOT, not have immunity, we have antireconnect_time
	if(client != 0 && !IsFakeClient(client) && !CheckCommandAccess(client, "antireconnect_immunity", ADMFLAG_RESERVATION) && rejecttime > 0)
	{
		decl String:steam[25];
		GetClientAuthString(client, steam, sizeof(steam));	// Get steamid

		if(StrContains(steam, "STEAM_") == 0)	// Client authstring have "STEAM_"
		{
			new time = rejecttime - GetTime();	// 'antireconnect_time' after last disconnect

			for(new i = 0; i < 100; i++) // Loop through 100 slots
			{
				if(StrEqual(steamids[i], steam))	// Found exactly same steamid from steamids[slot]
				{
					new timeleft = time + times[i];	// Check that steamid reject time

					if(timeleft > 0)	// Time still left
					{
						if(penalty)	// When antireconnect_penalty enabled, add +antireconnect_time every false connect
						{
							times[i] += rejecttime;	// Update timestamp by antireconnect_time
							timeleft += rejecttime;	// Update also reject message timeleft
						}
						PrintToChatAll("Player %N left the game (Don't reconnect within %i seconds.)", client, timeleft);
						KickClient(client, "Don't reconnect within %i seconds", timeleft);	// Kick that re-connect player
					}
					else	// Time pass
					{
						steamids[i][0] = '\0';	// Remove Steamid
						times[i]	= 0;	// Reset time
					}
					break;	// Stop loop
				}
			}
		}
	}
}

public Action:PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));	// Get client

	// Client is not 0, client is still in game!, not BOT, not have immunity, we have antireconnect_time
	if(client != 0 && IsClientInGame(client) && !IsFakeClient(client) && !CheckCommandAccess(client, "antireconnect_immunity", ADMFLAG_RESERVATION) && rejecttime > 0)
	{
		decl String:steam[25];
		GetEventString(event, "networkid", steam, sizeof(steam)); // Ok, let's pick that player steamid from event...

		if(StrContains(steam, "STEAM_") == 0)	// Client authstring have "STEAM_"
		{
			new bool:found = false;	// Info when steamid found or not

			for(new i = 0; i < 100; i++) // Loop through 100 slots
			{
				if(StrEqual(steamids[i], steam))	// Found exactly same steamid from steamids[slot]
				{
					found = true;	// steamid found
					break;	// Stop loop
				}
			}

			if(!found)	// Didn't find steamid from previous loop
			{
				for(new i = 0; i < 100; i++) // Loop through 100 slots
				{
					if(StrEqual(steamids[i], ""))	// Found empty steamids[slot] where can save
					{
						strcopy(steamids[i], 25, steam);	// Store client steamid in this steamids[slot]
						times[i] = GetTime()	// Time stamp in same times[slot] ID/number where steamid
						break;	// Stop loop
					}
				}
			}
		}
	}
}