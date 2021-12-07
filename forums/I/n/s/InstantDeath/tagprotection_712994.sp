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

#define PLUGIN_VERSION "1.1"

#define RED 0
#define GREEN 255
#define BLUE 0
#define ALPHA 255

#define ADMFLAG_TAGPROT ADMFLAG_CUSTOM1

new Handle:tagfile		= INVALID_HANDLE;
new Handle:tagwarntime		= INVALID_HANDLE;
new Handle:tagKicktimer[MAXPLAYERS+1] = INVALID_HANDLE;
new Handle:tagfileloc		= INVALID_HANDLE;
new String:taglistfile[PLATFORM_MAX_PATH];
new String:fileloc[255];
new bool:tagfile_exist		= false;
new bool:kicktimerActive[MAXPLAYERS+1];
new bool:StillHasTag[MAXPLAYERS+1]	= false;
new String:WearingTag[255];

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
}
public OnMapStart()
{
	GetConVarString(tagfileloc, fileloc, sizeof(fileloc));
	BuildPath(Path_SM,taglistfile,sizeof(taglistfile), fileloc);
	tagfile = CreateKeyValues("taglist");
	FileToKeyValues(tagfile,taglistfile);
	if(!FileExists(taglistfile)) 
	{
		LogMessage("taglist.cfg not parsed...file doesnt exist!");
		tagfile_exist = false;
	}
	else
	{
		tagfile_exist = true;
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
	
	if(tagExistCheck(tag) == 1)
	{
		PrintToConsole(client, "[SM] This tag already exists!");
		return Plugin_Handled;
	}
	time = StringToInt(kbtime);
		
	KvRewind(tagfile);
	KvJumpToKey(tagfile, tag, true);
	KvSetNum(tagfile, "time", time);
	if(tagExistCheck(tag) == 1)
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
		
	if(tagExistCheck(Arguments) == 1)
	{
	
		KvRewind(tagfile);
		KvJumpToKey(tagfile, Arguments, false);
		KvDeleteThis(tagfile);
		if(tagExistCheck(Arguments) == 0)
		{
			PrintToConsole(client, "[SM] The tag was successfully removed.");
			return Plugin_Handled;
		}
		else
			PrintToConsole(client, "[SM] The tag could not be found.");
	}
	return Plugin_Handled;
}

public OnMapEnd()
{
	KvRewind(tagfile);
	KeyValuesToFile(tagfile, taglistfile);
	CloseHandle(tagfile);
}

public OnClientPutInServer(client)
{
	StillHasTag[client] = true;
}

/*
public OnClientAuthorized(client, const String:auth[])
{
	new Float:timer = 10.5;
	if(!IsFakeClient(client))
	{
		if(client != 0)
		{
			if(tagfile_exist == true)
				CreateTimer(timer,tagCheck, client,TIMER_FLAG_NO_MAPCHANGE);	
		}
	}
}
*/

public OnClientSettingsChanged(client)
{
	if(!IsFakeClient(client))
	{
		if(client != 0 && IsClientInGame(client))
		{
			if(tagfile_exist)
				tagCheckChange(client);
		}
	}
}

/*
public Action:tagCheck(Handle: timer, any:client)
{
	decl String:clientName[64];
	decl String:buffer[255];
	new time;
	new clientid = GetClientUserId(client);
	GetClientName(client,clientName,64);
	
	KvRewind(tagfile);
	KvGotoFirstSubKey(tagfile);
	gTimeLeft[client] = GetConVarFloat(tagwarntime);
	new flags = GetUserFlagBits(client);

	do{
		KvGetSectionName(tagfile, buffer, sizeof(buffer));
		if (StrContains(clientName, buffer,false) != -1)
		{
			time = KvGetNum(tagfile, "time");
			if(time == -1)
			{
				if(flags & ADMFLAG_TAGPROT || flags & ADMFLAG_ROOT)
				{
					return Plugin_Handled;
				}
				else 
				{
					tagKicktimer[client] = CreateTimer(1.0, OnTagKick, client, TIMER_REPEAT);
					//TriggerTimer(tagKicktimer, true);
					kicktimerActive[client] = true;
					PrintToChat(client, "[SM] You are not allowed to wear the '%s' tag.", buffer);
					PrintToChat(client, "[SM] You will be kicked in %f seconds if it is not removed", gTimeLeft[client]);
					StillHasTag[client] = true;
					break;
				}
			}
			else if(time > -1)
			{
				new String: bName[64];
				new String: bAuth[64];
				GetClientName(client, bName, sizeof(bName));
				GetClientAuthString(client, bAuth, sizeof(bAuth));
				ServerCommand("sm_ban #%d %s Illegal tag", clientid, time);
				LogMessage("[SM] Banned Player %s for illegal tag, SteamID: %s", bName, bAuth);
			}
		} 
	}while (KvGotoNextKey(tagfile));
				
	return Plugin_Handled;
}
*/

public Action:tagCheckChange(client)
{
	decl String:clientName[64];
	decl String:buffer[255];
	new time;
	new clientid = GetClientUserId(client);
	GetClientName(client,clientName,64);
	gTimeLeft[client] = GetConVarFloat(tagwarntime);
	new kicktime = FloatToInt(gTimeLeft[client]);
	
	KvRewind(tagfile);
	KvGotoFirstSubKey(tagfile);
	new flags = GetUserFlagBits(client);
	
	//timer is still active, but player has removed illegal tag
	if(kicktimerActive[client] && !StillHasTag[client])
	{
		PrintToChat(client,"[SM] Thank you for removing the %s tag", WearingTag);
		//KillTimer(tagKicktimer, false);
		kicktimerActive[client] = false;
	}
	
	do{
		KvGetSectionName(tagfile, buffer, sizeof(buffer));
		if (StrContains(clientName, buffer,false) != -1)
		{
			WearingTag = buffer;
			time = KvGetNum(tagfile, "time");
			if(time == -1)
			{
				//timer is active, we dont need to start the timer again
				if(!kicktimerActive[client])
				{
					if(flags & ADMFLAG_TAGPROT|| flags & ADMFLAG_ROOT)
					{
						return Plugin_Handled;
					}
					else 
					{				
						tagKicktimer[client] = CreateTimer(1.0, OnTagKick, client, TIMER_REPEAT);
						//TriggerTimer(tagKicktimer, true);
						kicktimerActive[client] = true;
						StillHasTag[client] = true;
						PrintToChat(client, "[SM] \x04You are not allowed to wear the '%s\x04' tag.", buffer);
						PrintToChat(client, "[SM] \x04You will be kicked in %d\x04 seconds if it is not removed", kicktime);
						return Plugin_Handled;
					}
				}
				
			}
			if(time > -1)
			{
				new String: bName[64];
				new String: bAuth[64];
				GetClientName(client, bName, sizeof(bName));
				GetClientAuthString(client, bAuth, sizeof(bAuth));
				ServerCommand("sm_ban #%d %s Illegal tag", clientid, time);
				LogMessage("[SM] Banned Player %s for illegal tag, SteamID: %s", bName, bAuth);
				return Plugin_Handled;
			}
				
		}
		else if (StrContains(clientName, buffer,false) == -1)
		{
			StillHasTag[client] = false;
		}
	} while (KvGotoNextKey(tagfile));
		
	return Plugin_Handled;
}

public Action:OnTagKick(Handle:timer, any:index)
{
	new time = FloatToInt(GetConVarFloat(tagwarntime)/2);
	new time2 = FloatToInt(GetConVarFloat(tagwarntime)/4);
	//PrintToChatAll("time left to kick: %f", gTimeLeft[index]);
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
	else if(kicktimerActive[index] == false)
		return Plugin_Stop;
		
	return Plugin_Continue;
}

public tagExistCheck(String:Tag[])
{
	KvRewind(tagfile);
	KvGotoFirstSubKey(tagfile);
	decl String:buffer[255];
	do{
		KvGetSectionName(tagfile, buffer, sizeof(buffer));
		if (StrContains(Tag, buffer,false) != -1)
			return 1;
		
	} while (KvGotoNextKey(tagfile));
	return 0;
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