/**
*Tag protection Plugin
*
* by InstantDeath
*customizable flag
*setable ban time
*add or remove tags from in game
*kick or ban option + in game
*
* 
* 
* sm_addtag
* sm_removetag
* sm_tagcfg
*/

#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define PLUGIN_VERSION "1.21.mod4BoC"

#define RED 0
#define GREEN 255
#define BLUE 0
#define ALPHA 255

#define ADMFLAG_TAGPROT ADMFLAG_CUSTOM1

new Handle:tagfile				= INVALID_HANDLE;
new Handle:tagwarntime				= INVALID_HANDLE;
new Handle:tagKicktimer[MAXPLAYERS+1]		= INVALID_HANDLE;
new Handle:tagfileloc				= INVALID_HANDLE;
new String:taglistfile[PLATFORM_MAX_PATH];
new String:fileloc[255];
new bool:kicktimerActive[MAXPLAYERS+1];
new String:WearingTag[MAXPLAYERS+1][255];
new ClientFirstSpawn[MAXPLAYERS+1];

new Float:gTimeLeft[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name = "Tag Protection",
	author = "InstantDeath",
	description = "Prevents unwanted tag usage in names.",
	version = PLUGIN_VERSION,
	url = "http://www.xpgaming.net"
};

public OnPluginStart()
{
	CreateConVar("sm_tagprotection_version", PLUGIN_VERSION, "Tag Protection Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	tagfileloc = CreateConVar("sm_tagcfg" , "configs/taglist.cfg" , "File to load and save tags.", FCVAR_PLUGIN);
	tagwarntime = CreateConVar("sm_tagwarntime" , "60.0" , "Time in seconds to warn player that he has an invalid tag", FCVAR_PLUGIN);
	RegAdminCmd("sm_addtag", Command_AddTag, ADMFLAG_BAN, "[SM] Add tags to the list. Usage: sm_addtag <tag> (time for ban, -1 for kick)");
	RegAdminCmd("sm_removetag", Command_RemoveTag, ADMFLAG_BAN, "[SM] Removes the specified tag from the list. Usage: sm_removetag <tag>");
	HookEvent("player_changename", checkName, EventHookMode_Post);
	HookEvent("player_spawn", checkNameOnce, EventHookMode_Post);

	new i = 0;
	while (i < MAXPLAYERS+1)
	{
		ClientFirstSpawn[i] = 0;
		i++;
	}
}

public checkName(Handle:event, const String:name[], bool:Broadcast)
{
	new clientid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(clientid);

	new flags = GetUserFlagBits(client);

	if (flags & ADMFLAG_TAGPROT || flags & ADMFLAG_ROOT)
	{
		kicktimerActive[client] = false;
		return;
	}

	decl String:clientName[64];
	decl String:buffer[255];
	new time;

	GetEventString(event, "newname", clientName, 64);
	
	// timer is still active, but player has removed illegal tag

	if (kicktimerActive[client] && !tagMatch(clientName, WearingTag[client]))
	{
		PrintToChat(client, "[SM] Thank you for removing the %s tag", WearingTag[client]);
		kicktimerActive[client] = false;
	}

	// Check to see if the player has any banned tags in name
	KvRewind(tagfile);
	KvGotoFirstSubKey(tagfile);
	do{
		KvGetSectionName(tagfile, buffer, sizeof(buffer));
		if (tagMatch(clientName, buffer))
		{
			WearingTag[client] = buffer;
			time = KvGetNum(tagfile, "time");
			if (time == -1)
			{
				//timer is active, we dont need to start the timer again
				if (!kicktimerActive[client] && IsClientInGame(client))
				{
						gTimeLeft[client] = GetConVarFloat(tagwarntime);
						new kicktime = FloatToInt(gTimeLeft[client]);
						tagKicktimer[client] = CreateTimer(1.0, OnTagKick, client, TIMER_REPEAT);
						//TriggerTimer(tagKicktimer, true);
						kicktimerActive[client] = true;
						PrintToChat(client, "[SM] \x04You are not allowed to wear the '%s\x04' tag.", buffer);
						PrintToChat(client, "[SM] \x04You will be kicked in %d\x04 seconds if it is not removed", kicktime);
				}
				
			}
			if (time > -1)
			{
					new String: bName[64];
					new String: bAuth[64];
					GetClientName(client, bName, sizeof(bName));
					GetClientAuthString(client, bAuth, sizeof(bAuth));
					ServerCommand("sm_ban #%d %d Illegal tag", clientid, time);
					LogMessage("[SM] Banned Player %s for illegal tag, SteamID: %s", bName, bAuth);
			}				
		}
	} while (KvGotoNextKey(tagfile));
}

public checkNameOnce(Handle:event, const String:name[], bool:Broadcast)
{
	new clientid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(clientid);

	new flags = GetUserFlagBits(client);

	if (flags & ADMFLAG_TAGPROT || flags & ADMFLAG_ROOT)
	{
		ClientFirstSpawn[client] = 0;
		kicktimerActive[client] = false;
		return;
	}

	if (ClientFirstSpawn[client] == 1)
	{
		decl String:clientName[64];
		decl String:buffer[255];
		new time;

		GetClientName(client, clientName, 64);

		// timer is still active, but player has removed illegal tag

		if (kicktimerActive[client] && !tagMatch(clientName, WearingTag[client]))
		{
			PrintToChat(client, "[SM] Thank you for removing the %s tag", WearingTag[client]);
			kicktimerActive[client] = false;
		}

		// Check to see if the player has any banned tags in name
		KvRewind(tagfile);
		KvGotoFirstSubKey(tagfile);
		do{
			KvGetSectionName(tagfile, buffer, sizeof(buffer));
			if (tagMatch(clientName, buffer))
			{
				WearingTag[client] = buffer;
				time = KvGetNum(tagfile, "time");
				if (time == -1)
				{
					//timer is active, we dont need to start the timer again
					if (!kicktimerActive[client] && IsClientInGame(client))
					{
							gTimeLeft[client] = GetConVarFloat(tagwarntime);
							new kicktime = FloatToInt(gTimeLeft[client]);
							tagKicktimer[client] = CreateTimer(1.0, OnTagKick, client, TIMER_REPEAT);
							//TriggerTimer(tagKicktimer, true);
							kicktimerActive[client] = true;
							PrintToChat(client, "[SM] \x04You are not allowed to wear the '%s\x04' tag.", buffer);
							PrintToChat(client, "[SM] \x04You will be kicked in %d\x04 seconds if it is not removed", kicktime);
					}
				
				}
				if (time > -1)
				{
						new String: bName[64];
						new String: bAuth[64];
						GetClientName(client, bName, sizeof(bName));
						GetClientAuthString(client, bAuth, sizeof(bAuth));
						ServerCommand("sm_ban #%d %d Illegal tag", clientid, time);
						LogMessage("[SM] Banned Player %s for illegal tag, SteamID: %s", bName, bAuth);
				}				
			}
		} while (KvGotoNextKey(tagfile));
		ClientFirstSpawn[client] = 0;
	}
}

public OnMapStart()
{
	GetConVarString(tagfileloc, fileloc, sizeof(fileloc));
	BuildPath(Path_SM,taglistfile,sizeof(taglistfile), fileloc);
	tagfile = CreateKeyValues("taglist");
	FileToKeyValues(tagfile,taglistfile);
	if(!FileExists(taglistfile)) 
	{
		LogMessage("[SM] taglist.cfg not parsed...file doesnt exist!");
		SetFailState("[SM] taglist.cfg not parsed...file doesnt exist! Please install the plugin correctly...");
	}
	new i = 0;
	while (i < MAXPLAYERS+1)
	{
		ClientFirstSpawn[i] = 0;
		i++;
	}
}

public Action:Command_AddTag(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_addtag <tag> (time for ban, -1 for kick)");
		return Plugin_Handled;
	}
	decl String:tag[64];
	decl String:kbtime[32];
	new time;
	
	GetCmdArg(1, tag, sizeof(tag));
	GetCmdArg(2, kbtime, sizeof(kbtime));
	
	if(tagExistCheck(tag))
	{
		PrintToConsole(client, "[SM] This tag already exists!");
		return Plugin_Handled;
	}
	time = StringToInt(kbtime);
		
	KvRewind(tagfile);
	KvJumpToKey(tagfile, tag, true);
	KvSetNum(tagfile, "time", time);
	if(tagExistCheck(tag))
	{
		PrintToConsole(client, "[SM] '%s' tag was successfully added. This will not take effect until the map changes.", tag);
		return Plugin_Handled;
	}

	return Plugin_Handled;
}

public Action:Command_RemoveTag(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_removetag <tag>");
		return Plugin_Handled;
	}
	decl String:Arguments[256];
	
	GetCmdArgString(Arguments, sizeof(Arguments));
		
	if(tagExistCheck(Arguments))
	{
	
		KvRewind(tagfile);
		KvJumpToKey(tagfile, Arguments, false);
		KvDeleteThis(tagfile);
		if(!tagExistCheck(Arguments))
		{
			PrintToConsole(client, "[SM] The tag was successfully removed.");
			return Plugin_Handled;
		}
		else
			PrintToConsole(client, "[SM] The tag could not be found.");
	}
	return Plugin_Handled;
}

public OnClientDisonnect(client)
{
	kicktimerActive[client] = false;
	ClientFirstSpawn[client] = 0;
}

public OnClientPostAdminCheck(client)
{
	ClientFirstSpawn[client] = 1;
}
public OnMapEnd()
{
	KvRewind(tagfile);
	KeyValuesToFile(tagfile, taglistfile);
	CloseHandle(tagfile);
}

public Action:OnTagKick(Handle:timer, any:index)
{
	if (!kicktimerActive[index])
		return Plugin_Stop;

	new time = FloatToInt(GetConVarFloat(tagwarntime)/2);
	new time2 = FloatToInt(GetConVarFloat(tagwarntime)/4);

	if(GetConVarFloat(tagwarntime)/2 == gTimeLeft[index])
	{
		PrintToChat(index, "\x01\x04[SM] You will be kicked in %d seconds if it is not removed", time);
		
	}
	if(GetConVarFloat(tagwarntime)/4 == gTimeLeft[index])
	{
		PrintToChat(index, "\x01\x04[SM] You will be kicked in %d seconds if it is not removed", time2);
	}
	if(gTimeLeft[index] == 10)
	{
		PrintToChat(index, "\x01\x04[SM] You will be kicked in %d seconds if it is not removed", 10);
	}
	if(gTimeLeft[index] == 5)
	{
		PrintToChat(index, "\x01\x04[SM] You will be kicked in %d seconds if it is not removed", 5);
	}
	if (!index || !IsClientInGame(index))
	{
		kicktimerActive[index] = false;
		return Plugin_Stop;
	}
	
	gTimeLeft[index] = gTimeLeft[index] - 1;
	
	if(gTimeLeft[index]<=0)
	{
		kicktimerActive[index] = false;
		new String: kName[64];
		new String: kAuth[64];
		GetClientName(index, kName, sizeof(kName));
		GetClientAuthString(index, kAuth, sizeof(kAuth));
		KickClient(index, "%s", "Illegal Tag");
		LogMessage("[SM] Kicked Player %s for illegal tag, SteamID: %s", kName, kAuth);
		return Plugin_Stop;
	}
		
	return Plugin_Continue;
}

public bool:tagExistCheck(String:Tag[])
{
	KvRewind(tagfile);
	KvGotoFirstSubKey(tagfile);
	decl String:buffer[255];
	do{
		KvGetSectionName(tagfile, buffer, sizeof(buffer));
		if (StrContains(Tag, buffer,false) != -1)
			return true;
		
	} while (KvGotoNextKey(tagfile));
	return false;
}

public bool:tagMatch(const String:name[], const String:tag[])
{
	new tagpos = StrContains(name, tag, false);
	new taglen = strlen(tag);
	new namelen = strlen(name);
	if (tagpos != -1)
	{
		if (tagpos != 0 && tagpos + taglen < namelen)
		{
			if (!IsCharAlpha(name[tagpos-1]) && !IsCharAlpha(name[tagpos+taglen]) && !IsCharNumeric(name[tagpos-1]) && !IsCharNumeric(name[tagpos+taglen]))
				return true;
			else
				return false;
		}
		if (tagpos == 0 && tagpos + taglen < namelen)
		{
			if (!IsCharAlpha(name[tagpos+taglen]) && !IsCharNumeric(name[tagpos+taglen]))
				return true;
			else
				return false;
		}
		if (tagpos != 0 && tagpos + taglen == namelen)
		{
			if (!IsCharAlpha(name[tagpos-1]) && !IsCharNumeric(name[tagpos-1]))
				return true;
			else
				return false;
		}
		if (tagpos == 0 && tagpos + taglen == namelen)
		{
			return true;
		}
		return false;
	}
	else
	{
		return false;
	}
}

public FloatToInt(Float: num)
{
	new String:temp[32];
	FloatToString(num, temp, sizeof(temp));
	return StringToInt(temp);
}

public OnPluginEnd()
{
	CloseHandle(tagfile);
}