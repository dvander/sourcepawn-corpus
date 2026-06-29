#include <sourcemod>

public Plugin myinfo =
{
	name = "Ban User on IP Detection",
	author = "Jacoblairm",
	description = "Ban SteamId on IP Detection, IP is valid for specified seconds 'bb_ip_banlength' (default 5 days or 432000 seconds, 0 for unlimited)",
	version = "1.0",
	url = "http://steamcommunity.com/id/Jacoblairm"
};

public OnPluginStart()
{
	RegAdminCmd("betterban", banUser, ADMFLAG_CUSTOM1, "Ban User on IP Detection");
	CreateConVar("bb_ip_banlength", "432000", "Time in seconds that IP is valid, Default 5 days, 0 for unlimited");
	decl String:path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM,path,PLATFORM_MAX_PATH,"configs/iplist.cfg");
	if(!FileExists(path))
	{
		new Handle:createFile=OpenFile(path,"w");
		CloseHandle(createFile);
	}
}


public void OnClientPostAdminCheck(client)
{
	new String:ip[64];
	new String:line[128];
	GetClientIP(client, ip, sizeof(ip));
	
	decl String:path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM,path,PLATFORM_MAX_PATH,"configs/iplist.cfg");
	if(FileExists(path))
	{
		new Handle:fileHandle=OpenFile(path,"r"); 
		while(!IsEndOfFile(fileHandle)&&ReadFileLine(fileHandle,line,sizeof(line)))
		{
			
			if((line[0] >= '0'&& line[0] <= '9') && StrContains(line, ip, false) > -1)
			{
				char str2[2][32];
				ExplodeString(line, " ", str2, sizeof(str2), sizeof(str2[]));
				int time = StringToInt(str2[1]);
				ConVar bb_banlength = FindConVar("bb_ip_banlength");
				int timeLength = GetConVarInt(bb_banlength);
				if(GetTime() - time < timeLength || timeLength == 0)
				{
					ServerCommand("sm_ban #%d 0 This steam ID has already been banned!", GetClientUserId(client));
					ServerCommand("writeid");
					ServerCommand("exec banned_user.cfg");
					PrintToServer("Detected an account on a Banned IP!");
					
				}
				else //Remove the old ip entry
				{
					new String:textLines[132][128];//132 Entries (Can be increased)
					new lineCount = 0;
					new Handle:fileHandle2=OpenFile(path,"r"); 
					while(!IsEndOfFile(fileHandle2)&&ReadFileLine(fileHandle2,line,sizeof(line))) //Applies each line of iplist.cfg to an array element of textLines
					{
						if((line[0] >= '0'&& line[0] <= '9') && StrContains(line, ip, false) <= -1) //dont include the current ip because being removed.
						{
							textLines[lineCount] = line;
							lineCount++;
						}
						
					}
					CloseHandle(fileHandle2);
					
					fileHandle2=OpenFile(path,"w");//clear old iplist.cfg
					for(int i = 0; i < sizeof(textLines[]); i++) //For each array element of textLines if line starts with a number (ip address), write to iplist.cfg
					{
						if((textLines[i][0] >= '0'&& textLines[i][0] <= '9'))
						{
							WriteFileLine(fileHandle2, "%s", textLines[i]);
						}
					}
					CloseHandle(fileHandle2);
				}
			}
			
		}
		CloseHandle(fileHandle);
	}
	return Plugin_Continue;
}

public Action:banUser(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[BetterBan] Usage: betterban <clientid> [Message to user, put in quotes] (for clientid, type status and use the second userid digit)");
		return Plugin_Handled;
	}

	new String:arg1[16];
	new String:arg2[64];
	new String:ip[64];
	new String:textLines[132][128];//132 Entries (Can be increased a bit more but will eventually produce an error). 
	new lineCount = 0;
	new String:line[128];
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	
	int clientId = StringToInt(arg1[0]);
	if(clientId > 0 && IsClientConnected(clientId))
	{
		GetClientIP(clientId, ip, sizeof(ip))
		decl String:path[PLATFORM_MAX_PATH];
		BuildPath(Path_SM,path,PLATFORM_MAX_PATH,"configs/iplist.cfg");
		new Handle:fileHandle=OpenFile(path,"r"); 
		while(!IsEndOfFile(fileHandle)&&ReadFileLine(fileHandle,line,sizeof(line))) //Applies each line of iplist.cfg to an array element of textLines
		{
			if((line[0] >= '0'&& line[0] <= '9') && StrContains(line, ip, false) <= -1) //dont include the current ip because its already being added again.
			{
				textLines[lineCount] = line;
				lineCount++;
			}
			
		}
		CloseHandle(fileHandle);
		
		new Handle:fileHandle2=OpenFile(path,"w");//clear old iplist.cfg
		for(int i = 0; i < sizeof(textLines[]); i++) //For each array element of textLines if line starts with a number (ip address), write to iplist.cfg
		{
			if((textLines[i][0] >= '0'&& textLines[i][0] <= '9'))
			{
				WriteFileLine(fileHandle2, "%s", textLines[i]);
			}
		}
		WriteFileLine(fileHandle2,"%s %d", ip, GetTime()); //also write the new ip address + timestamp
		PrintToServer("%s %d added to iplist.cfg", ip, GetTime());
		CloseHandle(fileHandle2);
		ServerCommand("sm_ban #%d 0 %s", GetClientUserId(clientId), arg2[0]);
		ServerCommand("writeid");
		ServerCommand("exec banned_user.cfg");
	}
	else
	{
		ReplyToCommand(client, "[BetterBan] Invalid UserID, Type status and use the second 'userid' digit");
	}
	return Plugin_Handled;
}
