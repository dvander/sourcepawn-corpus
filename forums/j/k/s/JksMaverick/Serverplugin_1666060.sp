#include <sourcemod>
#include <sdktools_functions>
#include colors


static START_START = 3
static START_USED = 4
static CURRENT_START_STATE = 3
static Float:current_Start_Time = 0.0;
static CM_START = 5
static CM_USED = 6
static CURRENT_CM_STATE = 5
static Float:current_CM_Time = 0.0;
static String:mapName[100] = ""
static COINFLIP_START = 0
static COINFLIP_USERINPUT = 1
static String:currentCoinflipClient[100] = ""
static CURRENT_STATE = 0
new bool:bAdmin[MAXPLAYERS+1];


public Plugin:myinfo =
{
	name = "Public Match Server",
	author = "<Jks>Maverick",
	description = "Configurable Server Plugin Beta",
	version = "1.6.8",
	url = "http://www.sourcemod.net/"
};



public OnClientPostAdminCheck(client)  
{  	new Handle:authorisation_enabled = FindConVar("sm_authorisation_enabled")
	new bool:sm_authorisation_enabled = GetConVarBool(authorisation_enabled)
	if (sm_authorisation_enabled)
	{
		new flags = GetUserFlagBits(client);
		if ((flags & ADMFLAG_CONFIG) | (flags & ADMFLAG_ROOT))
		{
			bAdmin[client] = true;  
		}
	}
	else
	{
		bAdmin[client] = true;
	}
}

public OnClientDisconnect(client)
{
	bAdmin[client] = false;
}


public OnPluginStart()
{
	
	
	AutoExecConfig()
	CreateConVar("sm_teamplay_switchable", "0", "Enables #.# teamplay")
	CreateConVar("sm_chat_command_prefix", "#.#", "Chat Command prefix")
	CreateConVar("sm_authorisation_enabled","0", "Enables the Requirement of the Sourcemod Admin flag(Root or Config) for several Commands")
	CreateConVar("sm_restart_enabled", "0", "Enables #.# restart")
	CreateConVar("sm_cm_enabled","0", "Enables #.# cm")
	CreateConVar("sm_start_enabled", "0", "Enables #.# start")
	new Handle:authorisation_enabled = FindConVar("sm_authorisation_enabled")
	new bool:sm_authorisation_enabled = false
	sm_authorisation_enabled = GetConVarBool(authorisation_enabled)
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);
	new index = GetMaxClients()
	for (new i = 1; i <= index; i++)
	{
		if(IsClientConnected(i))
		{
			if(IsClientAuthorized(i))
			{
				if(sm_authorisation_enabled)
				{
					new flags = GetUserFlagBits(i);  
					if ((flags & ADMFLAG_CONFIG) | (flags & ADMFLAG_ROOT))
					{
						bAdmin[i] = true;  
					}
				}
				else
				{
					bAdmin[i] = true;
				}
			}
		}
	}		
}

public Action:Command_Say(client, args)
{
	
	new String:clientName[100]
	new String:arg[200]
	new String:args[3][100]
	new String:argsSay[2][200]
	new String:splitter[1] = " "
	new Handle:chat_command_prefix = FindConVar("sm_chat_command_prefix")
	new String:admin_command_prefix[50] = "#.#"
	GetConVarString(chat_command_prefix,admin_command_prefix,sizeof(admin_command_prefix))
	new Handle:teamplay = FindConVar("mp_teamplay")
	new Handle:password = FindConVar("sv_password")
	new String:passwordString[100]
	new Handle:sm_teamplay_switchable = FindConVar("sm_teamplay_switchable")
	new Handle:sm_restart_enabled = FindConVar("sm_restart_enabled")
	new bool:restart_enabled  = false
	new Handle:sm_cm_enabled = FindConVar("sm_cm_enabled")
	new Handle:sm_start_enabled = FindConVar("sm_start_enabled")
	new bool:cm_enabled  = false
	new bool:start_enabled  = false
	
	
	GetCmdArgString(arg, sizeof(arg))
	StripQuotes(arg)
	
	
	if(CURRENT_STATE == COINFLIP_USERINPUT)
	{
		new String:currentClient[100]
		GetClientAuthString(client,currentClient,sizeof(currentClient))
		new String:actual[20]
		new String:other[20]
		if(StrEqual(currentClient,currentCoinflipClient,true))
		{
			new randomInt = GetRandomInt(1,1000)
			
			
			if(randomInt <= 500)
			{
				actual = "heads"
				other  = "tails"
			}
			else 
			{
				actual = "tails"
				other = "heads"
			}
			
			if(StrEqual(arg,actual,false))
			{
				CPrintToChatAll("Actual:  {green}%s		{default}Guess: {green}%s",actual,arg)
				coinflipWinner(client)
				CURRENT_STATE = COINFLIP_START
				currentCoinflipClient = ""
			}
			else if (StrEqual(arg,other,false))
			{
				CPrintToChatAll("Actual:  {green}%s		{default}Guess: {green}%s",actual,arg)
				coinflipLooser(client)
				CURRENT_STATE = COINFLIP_START
				currentCoinflipClient = ""
			}
			else
			{
				CPrintToChat(client,"{green}heads {default}or {green}tails {default}?")
			}
			return Plugin_Handled;
			
		}
		else
		{
			if ((StrEqual(arg,actual,false)) || (StrEqual(arg,other,false)))
			{
				CPrintToChat(client,"{green}Your not Coinflip Player! ")
				return Plugin_Handled;
			}
		}
	}
	
	
	ExplodeString(arg,splitter, args, 3, 100)
	
	if(StrEqual(args[0], admin_command_prefix, true))
	{
		new String:teamplay_switchable = GetConVarInt(sm_teamplay_switchable)
		restart_enabled = GetConVarBool(sm_restart_enabled)
		start_enabled = GetConVarBool(sm_start_enabled)
		cm_enabled = GetConVarBool(sm_cm_enabled)
		
		if(StrEqual(args[1], "pw", false) || StrEqual(args[1], "Password", false))
		{
			
			GetConVarString(password,passwordString,sizeof(passwordString))
			if(StrEqual(passwordString, "", true))
				CPrintToChat(client,"{green}No Password! %s", passwordString);
			else
			CPrintToChat(client,"Password: {green}%s", passwordString);
		}
		
		else if(StrEqual(args[1], "teamplay", false))
		{
			if(teamplay_switchable == 1)
			{
				if(bAdmin[client] ==true)
				{
					new teamplayValue = GetConVarInt(teamplay)
					if((StrEqual(args[2], "0", false) || StrEqual(args[2], "off", false)) && teamplayValue == 1)
					{
						SetConVarBool(teamplay,false,false,true)
						CPrintToChat(client,"Deathmatch {green}activated{default} after mapchange.  %s","");
					}
					else if((StrEqual(args[2], "1", false) || StrEqual(args[2], "on", false)) && teamplayValue == 0)
					{
						SetConVarBool(teamplay,true,false,true)
						CPrintToChat(client,"Team Deathmatch {green}activated{default} after mapchange.  %s","");
					}
					else
					{
						CPrintToChat(client,"use {green}#.# teamplay 1/0 {default}to switch teamplay on/off")
					}
				}
				else
				{
					CPrintToChat(client,"You are {green}not allowed{default} to switch Teamplay-Mode here")
				}
			}
			else
			{
				CPrintToChat(client,"Switching Teamplay-Mode is {green}not enabled{default} here")
			}
		}
		
		else if(StrEqual(args[1], "coinflip", false))
		{
			
			if(GetClientTeam(client) == 1)
				CPrintToChat(client,"{green}U cant Coinflip in Spectate-Mode. Join the Game to do so.")
			else
			{
				GetClientName(client, clientName, sizeof(clientName));
				CPrintToChatAll("Coinflip: Player is {green}%s",clientName)
				CPrintToChat(client,"{green}heads {default}or {green}tails {default}?")
				GetClientAuthString(client,currentCoinflipClient,sizeof(currentCoinflipClient))
				CURRENT_STATE = COINFLIP_USERINPUT
			}
		}
		
		else if(StrEqual(args[1], "restart", false))
		{
			
			
			if(restart_enabled)
			{
				if(bAdmin[client] == true)
				{
					InsertServerCommand("mp_restartgame 5 %s","");
					CreateTimer(4.0, SayRestart_One)
				}
				else
				{
					CPrintToChat(client,"You are {green}not allowed{default} to restart the game here")
				}
			}
			else
			{
				CPrintToChat(client,"You are {green}not allowed{default} to restart here")
			}
		}
		
		else if(StrEqual(args[1], "cm", false))
		{
			if(cm_enabled == true)
			{
				if(bAdmin[client] == true)
				{
					
					if(CURRENT_CM_STATE == CM_USED)
					{
						new Float:currentTime2 = GetEngineTime()
						
						if((currentTime2 - current_CM_Time) <= 6)
						{
							CPrintToChat(client,"Wait {green}till the map has changed{default}, then u can use cm again");
							return Plugin_Handled;
						}
						else
						{
							CURRENT_CM_STATE = CM_START
							current_CM_Time = 0.0
							currentTime2 = 0.0
						}
					}
					new String:buildPath[100]
					BuildPath(Path_SM, buildPath, sizeof(buildPath), "configs/maps.cfg");
					mapName = ""
					new Handle:kv = CreateKeyValues("Maps");
					FileToKeyValues(kv, buildPath);
					if (KvJumpToKey(kv, "Maps"))
						KvGetString(kv, args[2], mapName, 100);
					CloseHandle(kv);
					if(StrEqual(mapName, "", true) || !IsMapValid(mapName))
					{
						CPrintToChat(client,"Map not found! :  {green}%s",args[2]);
					}
					else
					{
						current_CM_Time = GetEngineTime()
						CURRENT_CM_STATE = CM_USED
						CPrintToChatAll("Map will {green}change {default}in 5 Seconds to {green}%s",mapName)
						CreateTimer(5.0,changeMap)
					}
				}
				
				else
				{
					CPrintToChat(client,"You are {green}not allowed{default} to change Map here")
				}
			}
			
			else
			{
				CPrintToChat(client,"Mapchanging is {green}not enabled{default} here")
			}
			
		}
		
		else if(StrEqual(args[1], "start", false))
		{
			if(start_enabled == true)
			{
				if(CURRENT_START_STATE == START_USED)
				{
					new Float:currentTime = GetEngineTime()
					
					if((currentTime - current_Start_Time) <= 60)
					{
						CPrintToChat(client,"Wait {green}60 Seconds{default} till u can use start again");
						return Plugin_Handled;
					}
					else
					{
						CURRENT_START_STATE = START_START
						current_Start_Time = 0.0
						currentTime = 0.0
					}
				}
				
				if(bAdmin[client] == true)
				{
					new String:buildPath[100]
					BuildPath(Path_SM, buildPath, sizeof(buildPath), "configs/Configs.cfg");
					new String:configName[100] = ""
					new Handle:kv = CreateKeyValues("Configs");
					FileToKeyValues(kv, buildPath);
					if (KvJumpToKey(kv, "Configs"))
						KvGetString(kv, args[2], configName, 100);
					CloseHandle(kv);
					if(StrEqual(configName, "", true))
					{
						CPrintToChat(client,"Config not found! :  {green}%s",args[2]);
					}
					else
					{
						current_Start_Time = GetEngineTime()
						CURRENT_START_STATE = START_USED
						new random = GetRandomInt(1111, 9999)
						IntToString(random,passwordString,20);
						InsertServerCommand("sv_password %s",passwordString);
						InsertServerCommand("exec %s",configName);
						InsertServerCommand("tv_stoprecord");
						new String:time[100]
						new String:currentMap[100]
						new String:gametype[100]
						if(GetConVarInt(teamplay) == 1)
							gametype = "tdm"
						else
						gametype = "dm"
						FormatTime(time, 100, "%d%m%Y-%Hh%Mm%Ss");
						GetCurrentMap(currentMap, 100);
						InsertServerCommand("tv_record demos/%s-%s-%s%s", time, currentMap, gametype,".dem");
						CPrintToChatAll("{green}%s","=>!GL!--!LIVE!--!HF!<=")
						InsertServerCommand("mp_weaponstay 0");
						
						CPrintToChatAll("Password was set to: {green}%s",passwordString);
					}
				}
				
				else
				{
					CPrintToChat(client,"You are {green}not allowed {default}to start a Config here")
				}
				
			}
			
			else
			{
				CPrintToChat(client,"Starting is {green}not enabled{default} here")
			}
			
			
		}
		
		else if(StrEqual(args[1], "help", false))
		{
			if(teamplay_switchable == 1)
				CPrintToChat(client,"{green}%s teamplay 1/0 to switch teamplay on/off", admin_command_prefix)
			if(start_enabled)	
				CPrintToChat(client,"{green}%s start <cfg> to start a match", admin_command_prefix)
			if(cm_enabled)
				CPrintToChat(client,"{green}%s cm <mapname> to change the map", admin_command_prefix)
			if(restart_enabled)
				CPrintToChat(client,"{green}%s restart to make a normal restart", admin_command_prefix)
			CPrintToChat(client,"{green}%s password to see the current password", admin_command_prefix)
			CPrintToChat(client,"{green}%s coinflip to flip a coin", admin_command_prefix)
		}	
		
		else if(StrEqual(args[1], "say", false))
			return Plugin_Continue
		
		else if(StrEqual(args[1], "say_team", false))
			return Plugin_Continue
		else
		{
			CPrintToChat(client,"Command not found: {green}%s",args[1])
		}
		
	}
	else
	{
		/*new clientTeam = GetClientTeam(client);
		GetClientName(client, clientName, sizeof(clientName));
		if(clientTeam== 0)
		{
		CPrintToChatAll("{default} %s : %s",clientName,arg)
		}	
		
		else if(clientTeam== 1)
		{
		CPrintToChatAll("{default} *SPECTATOR* %s : %s",clientName,arg)
		}
		
		else if(clientTeam== 2)
		{
		CPrintToChatAll("{blue}%s{default} : %s",clientName,arg)
		}
		
		else if(clientTeam== 3)
		{
		CPrintToChatAll("{red}%s{default} : %s",clientName,arg)
		}
		*/
		return Plugin_Continue
		
	}
	
	return Plugin_Handled;
	
}



public Action:SayRestart_One(Handle:timer)
{
	PrintCenterTextAll(" %s", "Game will restart in 1 SECOND")
	
}

public Action:SayStart_One(Handle:timer)
{
	CPrintToChatAll("{green}%s","Take Score Screenshot.")
}


public Action:SayStart_Two(Handle:timer)
{
	CPrintToChatAll("{green}%s","-----> 5 <-----")
}

public Action:SayStart_Three(Handle:timer)
{
	CPrintToChatAll("{green}%s","----> 4 <----")
}


public Action:SayStart_Four(Handle:timer)
{
	CPrintToChatAll("{green}%s","---> 3 <---")
}


public Action:SayStart_Five(Handle:timer)
{
	CPrintToChatAll("{green}%s","--> 2 <--")
}


public Action:SayStart_Six(Handle:timer)
{
	new Handle:password = FindConVar("sv_password")
	new String:passwordString[100]
	
	CPrintToChatAll("{green}%s","-> 1 <-")
	CPrintToChatAll("{green}%s","=>!GL!--!LIVE!--!HF!<=")
	GetConVarString(password,passwordString,sizeof(passwordString))
	CPrintToChatAll("Password was set to: {green}%s",passwordString)
}


public Action:SayStart_Seven(Handle:timer)
{
	InsertServerCommand("mp_weaponstay 0;mp_restartgame 1")
}


public Action:changeMap(Handle:timer)
{
	InsertServerCommand("changelevel %s",mapName);
}

public Action:coinflipWinner(client)
{
	new clientTeam = GetClientTeam(client);
	new index = GetMaxClients()
	for (new i = 1; i <= index; i++)
	{
		if(clientTeam== 2)
		{
			if(IsClientInGame(i) && GetClientTeam(i) == 2)
				CPrintToChat(i,"{green}You will choose.")
			if(IsClientInGame(i) && GetClientTeam(i) == 3)
				CPrintToChat(i,"{green}Your Opponent Team will choose.")
		}	
		else if(clientTeam == 3)
		{
			if(IsClientInGame(i) && GetClientTeam(i) == 3)
				CPrintToChat(i,"{green}Your Team will choose.")
			if(IsClientInGame(i) && GetClientTeam(i) == 2)
				CPrintToChat(i,"{green}Your Opponent Team will choose.")
		}
		else if(clientTeam == 0)
		{
			if(IsClientInGame(i))
			{
				if(client == i)
					CPrintToChat(i,"{green}You will choose.")
				else
					CPrintToChat(i,"{green}Your Opponent will choose.")
			}
		}
	}
	
	
}

public Action:coinflipLooser(client)
{
	new clientTeam = GetClientTeam(client);
	new index = GetMaxClients()
	for (new i = 1; i <= index; i++)
	{
		if(clientTeam== 2)
		{
			if(IsClientInGame(i) && GetClientTeam(i) == 3)
				CPrintToChat(i,"{green}Your Team will choose.")
			if(IsClientInGame(i) && GetClientTeam(i) == 2)
				CPrintToChat(i,"{green}Your Opponent Team will choose.")
		}	
		else if(clientTeam == 3)
		{
			if(IsClientInGame(i) && GetClientTeam(i) == 2)
				CPrintToChat(i,"{green}Your Team will choose.")
			if(IsClientInGame(i) && GetClientTeam(i) == 3)
				CPrintToChat(i,"{green}Your Opponent Team will choose.")
		}
		else if(clientTeam == 0)
		{
			if(IsClientInGame(i))
			{
				if(client == i)
					CPrintToChat(i,"{green}Your Opponent will choose.")
				else
					CPrintToChat(i,"{green}You will choose.")
			}
		}
	}
	
	
	
}

