#include <sourcemod>
#include <sdktools> 
#include <sdkhooks> 
#include <cstrike>
#pragma tabsize 0

public Plugin:myinfo =
{
	name = "teleport plugin for mg_100traps_v4_1",
	author = "AsDiKa",
	description = "level saver/chooser plugin for mg_100traps_v4_1",
	version = "1.0",
	url = ""
};

char currentmap[64];

new Float:levelBoxes[102][4];
new Float:levelSpawns[102][2][3];
new currentPlayerLevel[MAXPLAYERS + 1];
new highestPlayerLevel[MAXPLAYERS + 1];
Database db;
bool trapMap;

public OnClientPutInServer(client)
{
 	if(!trapMap)
	{
		return;
	}
	
	if(IsClientInGame(client) && !IsFakeClient(client))
    {
        SDKHook(client, SDKHook_GroundEntChangedPost, OnClientGroundChangePost);
    }
}

public void OnClientSayCommand_Post(int client, const char[] command, const char[] sArgs)
{
	if(!trapMap)
	{
		return;
	}

	if(strcmp(sArgs, "goto", false) == 0)
	{
		Menu_goto(client);
	}
	
	char sPieces[32][64];
	int iNumPieces = ExplodeString(sArgs, "/", sPieces, sizeof(sPieces), sizeof(sPieces[]));
	
	ExplodeString(sArgs, " ", sPieces, sizeof(sPieces), sizeof(sPieces[]));
	if(iNumPieces && StrEqual(sPieces[0], "goto", true))
	{
		int goto_level	= StringToInt(sPieces[1]);
		if(goto_level && goto_level >= 1 && goto_level <= 100 && goto_level <= highestPlayerLevel[client])
		{
			decl String:nick[64];
			GetClientName(client, nick, sizeof(nick));
			PrintToChatAll("%s changed to level %d", nick, goto_level);
			changeLevel(client, goto_level, true);
		}
	}
}

public Action Menu_goto(int client)
{
	Menu menu = new Menu(MenuHandler1);
	menu.SetTitle("Please choose a level:");
	char strFromInt[4];
	char str[20];
	for(new i = 1; i <= highestPlayerLevel[client] && i <= 100; i++)
	{
		IntToString(i, strFromInt, sizeof(strFromInt));
		Format(str, sizeof(str), "%d. szint", i);
		menu.AddItem(strFromInt, str);
	}

	menu.ExitButton = true;
	menu.Display(client, 20);
 
	return Plugin_Handled;
}

public changeLevel(int client, int level, bool updateCurrentLevel)
{
	if(level < 1 || level > 100)
	{
		level	= 1;
	}
	if(IsClientInGame(client) && !IsFakeClient(client))
	{
		if(updateCurrentLevel)
		{
			currentPlayerLevel[client]	= level;
			char steamid[32];
			GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));

			char query[300];
			Format(query, sizeof(query), "INSERT INTO traps (steamid, currentLevel) VALUES('%s', '%d') ON DUPLICATE KEY UPDATE currentLevel = VALUES(currentLevel), highestLevel = IF(VALUES(currentLevel) > highestLevel, currentLevel, highestLevel)", steamid, level);

			if(!SQL_FastQuery(db, query))
			{
				char error[255];
				SQL_GetError(db, error, sizeof(error));
				PrintToServer("Failed to query (error: %s)", error);
			}
		}
		TeleportEntity(client, levelSpawns[level][0], levelSpawns[level][1], NULL_VECTOR);
		SetEntProp(client, Prop_Data, "m_iFrags", level);
		CS_SetClientAssists(client, highestPlayerLevel[client]);
	}
}

public int MenuHandler1(Menu menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(param2, info, sizeof(info));
		int level	= StringToInt(info);
		changeLevel(client, level, false);
		decl String:nick[64];
		GetClientName(client, nick, sizeof(nick));
		PrintToChatAll("%s changed to level %d", nick, level);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
}

public OnClientGroundChangePost(client)
{
	new Float:PlayerOrigin[3];
	GetClientAbsOrigin(client, PlayerOrigin);
	
	if(clientOnLevel(currentPlayerLevel[client], PlayerOrigin))
	{
		return;
	}

	new level;
	
	if(clientOnLevel(currentPlayerLevel[client] + 1, PlayerOrigin)) // next level reached
	{
		level	= currentPlayerLevel[client] + 1;
	}
	else
	{
		level	= findLevel(PlayerOrigin);
	}
	
	if(level == -1)
	{
		PrintToChat(client, "Cannot find the current level.");
	}
	else
	{
		decl String:nick[64];
		char steamid[32];
		GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
		
		GetClientName(client, nick, sizeof(nick));
		if(highestPlayerLevel[client] < level && level != 101)
		{
			PrintToChatAll("%s reached level %d", nick, level);
		}
		currentPlayerLevel[client]	= level;
		if(level > highestPlayerLevel[client] && level != 101)
		{
			highestPlayerLevel[client]	= level;
		}
		CS_SetClientAssists(client, highestPlayerLevel[client]);
		SetEntProp(client, Prop_Data, "m_iFrags", level);
		char query[300];

		Format(query, sizeof(query), "INSERT INTO traps (steamid, currentLevel) VALUES('%s', '%d') ON DUPLICATE KEY UPDATE currentLevel = VALUES(currentLevel), highestLevel = IF(VALUES(currentLevel) > highestLevel, currentLevel, highestLevel)", steamid, level);

		if(!SQL_FastQuery(db, query))
		{
			char error[255];
			SQL_GetError(db, error, sizeof(error));
			PrintToServer("Failed to query (error: %s)", error);
		}
		
		if(level == 101)
		{
			CreateTimer(0.2, teleportToLevelOne, client);
			CreateTimer(180.0, mp_restartgame, client);
			// before level 100
			//	setpos -3679.951416 15494.071289 -14239.906250;setang 13.844167 169.620560 0.000000
			// after level 100
			//	setpos 213.799866 14318.428711 1344.093750;setang 8.560618 99.887436 0.000000
			PrintToChatAll("%s completed level 100!", nick);
			PrintToChatAll("%s completed level 100!", nick);
			PrintToChatAll("%s completed level 100!", nick);
			PrintToChatAll("%s completed level 100!", nick);
			PrintToChatAll("%s completed level 100!", nick);
			PrintToChatAll("The map will restart after 3 minutes");
		}
	}
	return;
}

public Action teleportToLevelOne(Handle timer, int client)
{
	changeLevel(client, 1, true);
}

public Action mp_restartgame(Handle timer, int client)
{
	ServerCommand("mp_restartgame 1");
}

public clientOnLevel(level, Float:origins[3])
{
	if(level > 101)
	{
		return false;
	}
	if((levelBoxes[level][0] - 3) <= origins[0] && (levelBoxes[level][2] + 3) >= origins[0] && (levelBoxes[level][1] - 3) <= origins[1] && (levelBoxes[level][3] + 3) >= origins[1])
	{
		return true;
	}
	return false;
}

public findLevel(Float:origins[3])
{
	for(new i = 0; i <= 101; i++)
	{
		if(clientOnLevel(i, origins))
		{
			return i;
		}
	}
	return -1;
}

public Action:SpawnEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client	= GetClientOfUserId(GetEventInt(event, "userid"));

	char steamid[32];
	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));

	char querystr[120];
	Format(querystr, sizeof(querystr), "SELECT currentLevel, highestLevel FROM traps WHERE steamid = '%s'", steamid);

	DBResultSet query = SQL_Query(db, querystr);
	if (query == null)
	{
		char error[255];
		SQL_GetError(db, error, sizeof(error));
		PrintToServer("Failed to query (error: %s)", error);
	} 
	else 
	{
		new currentLevel, highestLevel;
		if(SQL_FetchRow(query))
		{
			currentLevel	= SQL_FetchInt(query, 0);
			highestLevel	= SQL_FetchInt(query, 1);
			PrintToChat(client, "Last played level: %d.", currentLevel);
			PrintToChat(client, "Highest level reached: %d.", highestLevel);
		}
		else
		{
			currentLevel	= 1;
			highestLevel	= 1;
		}
		
		CS_SetClientAssists(client, highestLevel);
		highestPlayerLevel[client]	= highestLevel;
		currentPlayerLevel[client]	= currentLevel;

		delete query;
	
		changeLevel(client, currentLevel, true);
		return;
	}
	changeLevel(client, 1, true);
}



public OnMapEnd()
{
	UnhookEvent("player_spawn", SpawnEvent);
	delete db;
}
	
public OnMapStart()
{
	GetCurrentMap(currentmap, sizeof(currentmap));
	if(strcmp(currentmap, "workshop/510119667/mg_100traps_v4_1", false) != 0)
	{
		trapMap	= false;
		return;
	}
	trapMap	= true;
	HookEvent("player_spawn", SpawnEvent);
	

	new String:Error[255];
	db	= SQL_DefConnect(Error, sizeof(Error));
	if(db == null)
	{
		PrintToServer("Cannot connect to MySQL Server: %s", Error);
		CloseHandle(db);
	}
	else
	{
		PrintToServer("Connection Successful");
	}
	
	levelBoxes[0][0]	= -14799.995117;
	levelBoxes[0][1]	= -14791.951172;
	levelBoxes[0][2]	= -13872.031250;
	levelBoxes[0][3]	= -13880.050781;

	levelBoxes[1][0]	= -15055.97;
	levelBoxes[1][1]	= -12271.94;
	levelBoxes[1][2]	= -14640.0;
	levelBoxes[1][3]	= -11792.0;
	levelSpawns[1][0][0]	= -14845.54;
	levelSpawns[1][0][1]	= -12233.30;
	levelSpawns[1][0][2]	= -159.91;
	levelSpawns[1][1][0]	= 0.0;
	levelSpawns[1][1][1]	= 90.0;
	levelSpawns[1][1][2]	= 0.0;

	levelBoxes[2][0]	= -15055.97;
	levelBoxes[2][1]	= -11343.97;
	levelBoxes[2][2]	= -14640.02;
	levelBoxes[2][3]	= -10864.03;
	levelSpawns[2][0][0]	= -14847.38;
	levelSpawns[2][0][1]	= -11321.29;
	levelSpawns[2][0][2]	= -159.91;
	levelSpawns[2][1][0]	= 0.0;
	levelSpawns[2][1][1]	= 90.0;
	levelSpawns[2][1][2]	= 0.0;

	levelBoxes[3][0]	= -15055.968750;
	levelBoxes[3][1]	= -10447.999023;
	levelBoxes[3][2]	= -14640.031250;
	levelBoxes[3][3]	= -9520.057617;
	levelSpawns[3][0][0]	= -14847.363281;
	levelSpawns[3][0][1]	= -10447.999023;
	levelSpawns[3][0][2]	= -927.906189;
	levelSpawns[3][1][0]	= 0.0;
	levelSpawns[3][1][1]	= 90.0;
	levelSpawns[3][1][2]	= 0.0;

	levelBoxes[4][0]	= -15055.979492;
	levelBoxes[4][1]	= -9167.968750;
	levelBoxes[4][2]	= -14640.006836;
	levelBoxes[4][3]	= -8368.031250;
	levelSpawns[4][0][0]	= -14846.287109;
	levelSpawns[4][0][1]	= -9167.999023;
	levelSpawns[4][0][2]	= -703.906189;
	levelSpawns[4][1][0]	= 0.0;
	levelSpawns[4][1][1]	= 90.0;
	levelSpawns[4][1][2]	= 0.0;

	levelBoxes[5][0]	= -15055.968750;
	levelBoxes[5][1]	= -7887.999512;
	levelBoxes[5][2]	= -14640.031250;
	levelBoxes[5][3]	= -7088.042969;
	levelSpawns[5][0][0]	= -14847.772461;
	levelSpawns[5][0][1]	= -7887.882324;
	levelSpawns[5][0][2]	= -703.906189;
	levelSpawns[5][1][0]	= 0.0;
	levelSpawns[5][1][1]	= 90.0;
	levelSpawns[5][1][2]	= 0.0;

	levelBoxes[6][0]	= -15055.968750;
	levelBoxes[6][1]	= -6735.998047;
	levelBoxes[6][2]	= -14640.031250;
	levelBoxes[6][3]	= -5936.004395;
	levelSpawns[6][0][0]	= -14847.902344;
	levelSpawns[6][0][1]	= -6735.670898;
	levelSpawns[6][0][2]	= -703.906189;
	levelSpawns[6][1][0]	= 0.0;
	levelSpawns[6][1][1]	= 90.0;
	levelSpawns[6][1][2]	= 0.0;

	levelBoxes[7][0]	= -15055.998047;
	levelBoxes[7][1]	= -5583.968750;
	levelBoxes[7][2]	= -14640.000977;
	levelBoxes[7][3]	= -5104.031250;
	levelSpawns[7][0][0]	= -14847.529297;
	levelSpawns[7][0][1]	= -5583.995117;
	levelSpawns[7][0][2]	= -575.906189;
	levelSpawns[7][1][0]	= 0.0;
	levelSpawns[7][1][1]	= 90.0;
	levelSpawns[7][1][2]	= 0.0;

	levelBoxes[8][0]	= -15055.974609;
	levelBoxes[8][1]	= -4815.968750;
	levelBoxes[8][2]	= -14640.031250;
	levelBoxes[8][3]	= -4144.006836;
	levelSpawns[8][0][0]	= -14847.761719;
	levelSpawns[8][0][1]	= -4807.772949;
	levelSpawns[8][0][2]	= -575.906189;
	levelSpawns[8][1][0]	= 0.0;
	levelSpawns[8][1][1]	= 90.0;
	levelSpawns[8][1][2]	= 0.0;

	levelBoxes[9][0]	= -15055.968750;
	levelBoxes[9][1]	= -3791.971191;
	levelBoxes[9][2]	= -14640.019531;
	levelBoxes[9][3]	= -3312.015625;
	levelSpawns[9][0][0]	= -14847.870117;
	levelSpawns[9][0][1]	= -3776.753906;
	levelSpawns[9][0][2]	= -575.906189;
	levelSpawns[9][1][0]	= 0.0;
	levelSpawns[9][1][1]	= 90.0;
	levelSpawns[9][1][2]	= 0.0;

	levelBoxes[10][0]	= -15055.999023;
	levelBoxes[10][1]	= -2895.968750;
	levelBoxes[10][2]	= -14640.031250;
	levelBoxes[10][3]	= -1840.031250;
	levelSpawns[10][0][0]	= -14847.714844;
	levelSpawns[10][0][1]	= -2880.689697;
	levelSpawns[10][0][2]	= -575.906189;
	levelSpawns[10][1][0]	= 0.0;
	levelSpawns[10][1][1]	= 90.0;
	levelSpawns[10][1][2]	= 0.0;
	
	levelSpawns[11][0][0]	= -14848.000000;
	levelSpawns[11][0][1]	= -1457.414062;
	levelSpawns[11][0][2]	= -639.968750;
	levelSpawns[11][1][0]	= 0.0;
	levelSpawns[11][1][1]	= 90.0;
	levelSpawns[11][1][2]	= 0.0;
	levelBoxes[11][0]	= -15055.980468;
	levelBoxes[11][1]	= -1487.968750;
	levelBoxes[11][2]	= -14640.031250;
	levelBoxes[11][3]	= -432.031250;

	levelSpawns[12][0][0]	= -14848.382812;
	levelSpawns[12][0][1]	= -49.424571;
	levelSpawns[12][0][2]	= -639.968750;
	levelSpawns[12][1][0]	= 0.0;
	levelSpawns[12][1][1]	= 90.0;
	levelSpawns[12][1][2]	= 0.0;
	levelBoxes[12][0]	= -15055.983398;
	levelBoxes[12][1]	= -79.968750;
	levelBoxes[12][2]	= -14640.031250;
	levelBoxes[12][3]	= 975.968750;

	levelSpawns[13][0][0]	= -14848.059570;
	levelSpawns[13][0][1]	= 1617.245483;
	levelSpawns[13][0][2]	= -639.968750;
	levelSpawns[13][1][0]	= 0.0;
	levelSpawns[13][1][1]	= 90.0;
	levelSpawns[13][1][2]	= 0.0;
	levelBoxes[13][0]	= -15055.998046;
	levelBoxes[13][1]	= 1584.035156;
	levelBoxes[13][2]	= -14640.031250;
	levelBoxes[13][3]	= 2383.968750;

	levelSpawns[14][0][0]	= -14847.803710;
	levelSpawns[14][0][1]	= 2892.712402;
	levelSpawns[14][0][2]	= -639.968750;
	levelSpawns[14][1][0]	= 0.0;
	levelSpawns[14][1][1]	= 90.0;
	levelSpawns[14][1][2]	= 0.0;
	levelBoxes[14][0]	= -15055.996093;
	levelBoxes[14][1]	= 2864.000244;
	levelBoxes[14][2]	= -14640.017578;
	levelBoxes[14][3]	= 4047.968750;

	levelSpawns[15][0][0]	= -14847.976562;
	levelSpawns[15][0][1]	= 4441.036621;
	levelSpawns[15][0][2]	= -639.968750;
	levelSpawns[15][1][0]	= 0.0;
	levelSpawns[15][1][1]	= 90.0;
	levelSpawns[15][1][2]	= 0.0;
	levelBoxes[15][0]	= -15055.998046;
	levelBoxes[15][1]	= 4400.031250;
	levelBoxes[15][2]	= -14640.000976;
	levelBoxes[15][3]	= 5391.968750;
	
	levelSpawns[16][0][0]	= -14848.031250;
	levelSpawns[16][0][1]	= 5837.407714;
	levelSpawns[16][0][2]	= -639.968750;
	levelSpawns[16][1][0]	= 0.0;
	levelSpawns[16][1][1]	= 90.0;
	levelSpawns[16][1][2]	= 0.0;
	levelBoxes[16][0]	= -15055.992187;
	levelBoxes[16][1]	= 5808.031250;
	levelBoxes[16][2]	= -14640.031250;
	levelBoxes[16][3]	= 6607.968750;

	levelSpawns[17][0][0]	= -14848.247070;
	levelSpawns[17][0][1]	= 7249.065917;
	levelSpawns[17][0][2]	= -639.968750;
	levelSpawns[17][1][0]	= 0.0;
	levelSpawns[17][1][1]	= 90.0;
	levelSpawns[17][1][2]	= 0.0;
	levelBoxes[17][0]	= -15055.991210;
	levelBoxes[17][1]	= 7216.001464;
	levelBoxes[17][2]	= -14640.031250;
	levelBoxes[17][3]	= 8015.968750;

	levelSpawns[18][0][0]	= -14847.575195;
	levelSpawns[18][0][1]	= 8528.765625;
	levelSpawns[18][0][2]	= -639.968750;
	levelSpawns[18][1][0]	= 0.0;
	levelSpawns[18][1][1]	= 90.0;
	levelSpawns[18][1][2]	= 0.0;
	levelBoxes[18][0]	= -15055.988281;
	levelBoxes[18][1]	= 8496.031250;
	levelBoxes[18][2]	= -14640.031250;
	levelBoxes[18][3]	= 9423.968750;

	levelSpawns[19][0][0]	= -14849.619140;
	levelSpawns[19][0][1]	= 9942.837890;
	levelSpawns[19][0][2]	= -639.968750;
	levelSpawns[19][1][0]	= 0.0;
	levelSpawns[19][1][1]	= 90.0;
	levelSpawns[19][1][2]	= 0.0;
	levelBoxes[19][0]	= -15055.969726;
	levelBoxes[19][1]	= 9904.031250;
	levelBoxes[19][2]	= -14640.021484;
	levelBoxes[19][3]	= 10703.968750;
	
	levelSpawns[20][0][0]	= -14847.971679;
	levelSpawns[20][0][1]	= 11087.674804;
	levelSpawns[20][0][2]	= -639.968750;
	levelSpawns[20][1][0]	= 0.0;
	levelSpawns[20][1][1]	= 90.0;
	levelSpawns[20][1][2]	= 0.0;
	levelBoxes[20][0]	= -15055.976562;
	levelBoxes[20][1]	= 11056.031250;
	levelBoxes[20][2]	= -14640.031250;
	levelBoxes[20][3]	= 11855.978515;

	levelSpawns[21][0][0]	= -14784.164062;
	levelSpawns[21][0][1]	= 12206.585937;
	levelSpawns[21][0][2]	= -639.968750;
	levelSpawns[21][1][0]	= 0.0;
	levelSpawns[21][1][1]	= 90.0;
	levelSpawns[21][1][2]	= 0.0;
	levelBoxes[21][0]	= -14991.988281;
	levelBoxes[21][1]	= 12176.031250;
	levelBoxes[21][2]	= -14576.000976;
	levelBoxes[21][3]	= 12879.968750;

	levelSpawns[22][0][0]	= -14847.700195;
	levelSpawns[22][0][1]	= 13263.018554;
	levelSpawns[22][0][2]	= -639.968750;
	levelSpawns[22][1][0]	= 0.0;
	levelSpawns[22][1][1]	= 90.0;
	levelSpawns[22][1][2]	= 0.0;
	levelBoxes[22][0]	= -15055.998046;
	levelBoxes[22][1]	= 13232.031250;
	levelBoxes[22][2]	= -14640.031250;
	levelBoxes[22][3]	= 13903.996093;

	levelSpawns[23][0][0]	= -14784.111328;
	levelSpawns[23][0][1]	= 14283.668945;
	levelSpawns[23][0][2]	= -639.968750;
	levelSpawns[23][1][0]	= 0.0;
	levelSpawns[23][1][1]	= 90.0;
	levelSpawns[23][1][2]	= 0.0;
	levelBoxes[23][0]	= -14991.989257;
	levelBoxes[23][1]	= 14256.031250;
	levelBoxes[23][2]	= -14576.031250;
	levelBoxes[23][3]	= 15439.998046;

	levelSpawns[24][0][0]	= -11519.599609;
	levelSpawns[24][0][1]	= -15281.057617;
	levelSpawns[24][0][2]	= -4063.968750;
	levelSpawns[24][1][0]	= 0.0;
	levelSpawns[24][1][1]	= 90.0;
	levelSpawns[24][1][2]	= 0.0;
	levelBoxes[24][0]	= -11727.998046;
	levelBoxes[24][1]	= -15311.968750;
	levelBoxes[24][2]	= -11312.031250;
	levelBoxes[24][3]	= -14384.000976;

	levelSpawns[25][0][0]	= -11519.788085;
	levelSpawns[25][0][1]	= -14017.293945;
	levelSpawns[25][0][2]	= -4063.968750;
	levelSpawns[25][1][0]	= 0.0;
	levelSpawns[25][1][1]	= 90.0;
	levelSpawns[25][1][2]	= 0.0;
	levelBoxes[25][0]	= -11727.995117;
	levelBoxes[25][1]	= -14031.968750;
	levelBoxes[25][2]	= -11312.031250;
	levelBoxes[25][3]	= -12592.031250;

	levelSpawns[26][0][0]	= -11519.836914;
	levelSpawns[26][0][1]	= -12097.206054;
	levelSpawns[26][0][2]	= -4063.968750;
	levelSpawns[26][1][0]	= 0.0;
	levelSpawns[26][1][1]	= 90.0;
	levelSpawns[26][1][2]	= 0.0;
	levelBoxes[26][0]	= -11727.972656;
	levelBoxes[26][1]	= -12111.968750;
	levelBoxes[26][2]	= -11312.031250;
	levelBoxes[26][3]	= -10960.031250;

	levelSpawns[27][0][0]	= -11519.848632;
	levelSpawns[27][0][1]	= -10544.057617;
	levelSpawns[27][0][2]	= -5343.968750;
	levelSpawns[27][1][0]	= 0.0;
	levelSpawns[27][1][1]	= 90.0;
	levelSpawns[27][1][2]	= 0.0;
	levelBoxes[27][0]	= -11727.968750;
	levelBoxes[27][1]	= -10575.999023;
	levelBoxes[27][2]	= -11312.031250;
	levelBoxes[27][3]	= -9648.031250;
	
	levelSpawns[28][0][0]	= -11519.717773;
	levelSpawns[28][0][1]	= -9281.329101;
	levelSpawns[28][0][2]	= -5343.968750;
	levelSpawns[28][1][0]	= 0.0;
	levelSpawns[28][1][1]	= 90.0;
	levelSpawns[28][1][2]	= 0.0;
	levelBoxes[28][0]	= -11727.999023;
	levelBoxes[28][1]	= -9295.968750;
	levelBoxes[28][2]	= -11312.001953;
	levelBoxes[28][3]	= -7984.031250;

	levelSpawns[29][0][0]	= -11519.775390;
	levelSpawns[29][0][1]	= -7617.208007;
	levelSpawns[29][0][2]	= -5343.968750;
	levelSpawns[29][1][0]	= 0.0;
	levelSpawns[29][1][1]	= 90.0;
	levelSpawns[29][1][2]	= 0.0;
	levelBoxes[29][0]	= -11855.996093;
	levelBoxes[29][1]	= -7631.968750;
	levelBoxes[29][2]	= -11184.031250;
	levelBoxes[29][3]	= -6960.031250;

	levelSpawns[30][0][0]	= -11530.135742;
	levelSpawns[30][0][1]	= -6577.592773;
	levelSpawns[30][0][2]	= -5343.968750;
	levelSpawns[30][1][0]	= 0.0;
	levelSpawns[30][1][1]	= 90.0;
	levelSpawns[30][1][2]	= 0.0;
	levelBoxes[30][0]	= -11727.996093;
	levelBoxes[30][1]	= -6607.968750;
	levelBoxes[30][2]	= -11328.031250;
	levelBoxes[30][3]	= -5680.000488;

	levelSpawns[31][0][0]	= -11519.826171;
	levelSpawns[31][0][1]	= -5312.812500;
	levelSpawns[31][0][2]	= -5343.968750;
	levelSpawns[31][1][0]	= 0.0;
	levelSpawns[31][1][1]	= 90.0;
	levelSpawns[31][1][2]	= 0.0;
	levelBoxes[31][0]	= -11727.996093;
	levelBoxes[31][1]	= -5327.983886;
	levelBoxes[31][2]	= -11312.004882;
	levelBoxes[31][3]	= -4144.000488;
	
	levelSpawns[32][0][0]= -11520.903320;
	levelSpawns[32][0][1]= -3763.462890;
	levelSpawns[32][0][2]= -5343.968750;
	levelSpawns[32][1][0]= 0.0;
	levelSpawns[32][1][1]= 90.0;
	levelSpawns[32][1][2]= 0.0;
	levelBoxes[32][0]= -11727.999023;
	levelBoxes[32][1]= -3791.999755;
	levelBoxes[32][2]= -11312.031250;
	levelBoxes[32][3]= -2864.031250;

	levelSpawns[33][0][0]= -11520.390625;
	levelSpawns[33][0][1]= -2483.616943;
	levelSpawns[33][0][2]= -5343.968750;
	levelSpawns[33][1][0]= 0.0;
	levelSpawns[33][1][1]= 90.0;
	levelSpawns[33][1][2]= 0.0;
	levelBoxes[33][0]= -11727.968750;
	levelBoxes[33][1]= -2511.968750;
	levelBoxes[33][2]= -11312.031250;
	levelBoxes[33][3]= -2032.031250;
	
	levelSpawns[34][0][0]= -11520.240234;
	levelSpawns[34][0][1]= -1581.845336;
	levelSpawns[34][0][2]= -5343.968750;
	levelSpawns[34][1][0]= 0.0;
	levelSpawns[34][1][1]= 90.0;
	levelSpawns[34][1][2]= 0.0;
	levelBoxes[34][0]= -11727.977539;
	levelBoxes[34][1]= -1615.968750;
	levelBoxes[34][2]= -11312.001953;
	levelBoxes[34][3]= -1040.001708;

	
	levelSpawns[35][0][0]	= -11519.487304;
	levelSpawns[35][0][1]	= -705.273742;
	levelSpawns[35][0][2]	= -5343.968750;
	levelSpawns[35][1][0]	= 0.0;
	levelSpawns[35][1][1]	= 90.0;
	levelSpawns[35][1][2]	= 0.0;
	levelBoxes[35][0]	= -11727.968750;
	levelBoxes[35][1]	= -719.987670;
	levelBoxes[35][2]	= -11314.193359;
	levelBoxes[35][3]	= 622.033447;

	levelSpawns[36][0][0]= -11520.227539;
	levelSpawns[36][0][1]= 1225.530395;
	levelSpawns[36][0][2]= -5343.968750;
	levelSpawns[36][1][0]= 0.0;
	levelSpawns[36][1][1]= 90.0;
	levelSpawns[36][1][2]= 0.0;
	levelBoxes[36][0]= -11727.968750;
	levelBoxes[36][1]= 1200.031250;
	levelBoxes[36][2]= -11312.031250;
	levelBoxes[36][3]= 2511.968750;

	levelSpawns[37][0][0]= -11520.093750;
	levelSpawns[37][0][1]= 2905.064208;
	levelSpawns[37][0][2]= -5343.968750;
	levelSpawns[37][1][0]= 0.0;
	levelSpawns[37][1][1]= 90.0;
	levelSpawns[37][1][2]= 0.0;
	levelBoxes[37][0]= -11727.968750;
	levelBoxes[37][1]= 2864.031250;
	levelBoxes[37][2]= -11312.031250;
	levelBoxes[37][3]= 3919.968750;
	
	levelSpawns[38][0][0]= -11519.795898;
	levelSpawns[38][0][1]= 4442.480957;
	levelSpawns[38][0][2]= -5343.968750;
	levelSpawns[38][1][0]= 0.0;
	levelSpawns[38][1][1]= 90.0;
	levelSpawns[38][1][2]= 0.0;
	levelBoxes[38][0]= -11983.968750;
	levelBoxes[38][1]= 4400.031250;
	levelBoxes[38][2]= -11056.031250;
	levelBoxes[38][3]= 5455.968750;

	levelSpawns[39][0][0]= -11519.960937;
	levelSpawns[39][0][1]= 5979.701660;
	levelSpawns[39][0][2]= -5343.968750;
	levelSpawns[39][1][0]= 0.0;
	levelSpawns[39][1][1]= 90.0;
	levelSpawns[39][1][2]= 0.0;
	levelBoxes[39][0]= -11727.968750;
	levelBoxes[39][1]= 5936.031250;
	levelBoxes[39][2]= -11312.031250;
	levelBoxes[39][3]= 7247.968750;

	levelSpawns[40][0][0]	= -11519.944335;
	levelSpawns[40][0][1]	= 7742.837890;
	levelSpawns[40][0][2]	= -5343.968750;
	levelSpawns[40][1][0]	= 0.0;
	levelSpawns[40][1][1]	= 90.0;
	levelSpawns[40][1][2]	= 0.0;
	levelBoxes[40][0]	= -11727.999023;
	levelBoxes[40][1]	= 7728.006347;
	levelBoxes[40][2]	= -11312.031250;
	levelBoxes[40][3]	= 8351.994140;
	
	levelSpawns[41][0][0]	= -11520.688476;
	levelSpawns[41][0][1]	= 8912.473632;
	levelSpawns[41][0][2]	= -5343.968750;
	levelSpawns[41][1][0]	= 0.0;
	levelSpawns[41][1][1]	= 90.0;
	levelSpawns[41][1][2]	= 0.0;
	levelBoxes[41][0]	= -11727.998046;
	levelBoxes[41][1]	= 8880.031250;
	levelBoxes[41][2]	= -11312.000976;
	levelBoxes[41][3]	= 9503.995117;

	levelSpawns[42][0][0]	= -11519.838867;
	levelSpawns[42][0][1]	= 10046.904296;
	levelSpawns[42][0][2]	= -5343.968750;
	levelSpawns[42][1][0]	= 0.0;
	levelSpawns[42][1][1]	= 90.0;
	levelSpawns[42][1][2]	= 0.0;
	levelBoxes[42][0]	= -11727.968750;
	levelBoxes[42][1]	= 10032.031250;
	levelBoxes[42][2]	= -11312.031250;
	levelBoxes[42][3]	= 10655.968750;

	levelSpawns[43][0][0]	= -11519.808593;
	levelSpawns[43][0][1]	= 11077.121093;
	levelSpawns[43][0][2]	= -5343.968750;
	levelSpawns[43][1][0]	= 0.0;
	levelSpawns[43][1][1]	= 90.0;
	levelSpawns[43][1][2]	= 0.0;
	levelBoxes[43][0]	= -11727.962890;
	levelBoxes[43][1]	= 11056.031250;
	levelBoxes[43][2]	= -11312.031250;
	levelBoxes[43][3]	= 12335.968750;

	levelSpawns[44][0][0]	= -11519.725585;
	levelSpawns[44][0][1]	= 12749.277343;
	levelSpawns[44][0][2]	= -5343.968750;
	levelSpawns[44][1][0]	= 0.0;
	levelSpawns[44][1][1]	= 90.0;
	levelSpawns[44][1][2]	= 0.0;
	levelBoxes[44][0]	= -11727.996093;
	levelBoxes[44][1]	= 12720.031250;
	levelBoxes[44][2]	= -11312.031250;
	levelBoxes[44][3]	= 14079.968750;

	levelSpawns[45][0][0]	= -8959.622070;
	levelSpawns[45][0][1]	= -15297.166992;
	levelSpawns[45][0][2]	= -8447.968750;
	levelSpawns[45][1][0]	= 0.0;
	levelSpawns[45][1][1]	= 90.0;
	levelSpawns[45][1][2]	= 0.0;
	levelBoxes[45][0]	= -9167.985351;
	levelBoxes[45][1]	= -15311.968750;
	levelBoxes[45][2]	= -8752.031250;
	levelBoxes[45][3]	= -14256.031250;

	levelSpawns[46][0][0]	= -8959.616210;
	levelSpawns[46][0][1]	= -13761.360351;
	levelSpawns[46][0][2]	= -8447.968750;
	levelSpawns[46][1][0]	= 0.0;
	levelSpawns[46][1][1]	= 90.0;
	levelSpawns[46][1][2]	= 0.0;
	levelBoxes[46][0]	= -9295.967773;
	levelBoxes[46][1]	= -13775.968750;
	levelBoxes[46][2]	= -8624.031250;
	levelBoxes[46][3]	= -12464.030273;

	levelSpawns[47][0][0]	= -8959.895507;
	levelSpawns[47][0][1]	= -12096.957031;
	levelSpawns[47][0][2]	= -8415.968750;
	levelSpawns[47][1][0]	= 0.0;
	levelSpawns[47][1][1]	= 90.0;
	levelSpawns[47][1][2]	= 0.0;
	levelBoxes[47][0]	= -9295.967773;
	levelBoxes[47][1]	= -12111.968750;
	levelBoxes[47][2]	= -8624.016601;
	levelBoxes[47][3]	= -10800.003906;
	
	levelSpawns[48][0][0]	= -8959.661132;
	levelSpawns[48][0][1]	= -10433.281250;
	levelSpawns[48][0][2]	= -8415.968750;
	levelSpawns[48][1][0]	= 0.0;
	levelSpawns[48][1][1]	= 90.0;
	levelSpawns[48][1][2]	= 0.0;
	levelBoxes[48][0]	= -9167.975585;
	levelBoxes[48][1]	= -10447.968750;
	levelBoxes[48][2]	= -8752.003906;
	levelBoxes[48][3]	= -9088.031250;

	levelSpawns[49][0][0]	= -8959.598632;
	levelSpawns[49][0][1]	= -8513.125000;
	levelSpawns[49][0][2]	= -8415.968750;
	levelSpawns[49][1][0]	= 0.0;
	levelSpawns[49][1][1]	= 90.0;
	levelSpawns[49][1][2]	= 0.0;
	levelBoxes[49][0]	= -9167.968750;
	levelBoxes[49][1]	= -8527.970703;
	levelBoxes[49][2]	= -8752.031250;
	levelBoxes[49][3]	= -7472.031250;

	levelSpawns[50][0][0]	= -8959.850585;
	levelSpawns[50][0][1]	= -6977.062011;
	levelSpawns[50][0][2]	= -8415.968750;
	levelSpawns[50][1][0]	= 0.0;
	levelSpawns[50][1][1]	= 90.0;
	levelSpawns[50][1][2]	= 0.0;
	levelBoxes[50][0]	= -9167.910156;
	levelBoxes[50][1]	= -6991.978515;
	levelBoxes[50][2]	= -8752.031250;
	levelBoxes[50][3]	= -5808.008789;
	
	levelSpawns[51][0][0]	= -8959.736328;
	levelSpawns[51][0][1]	= -5313.157226;
	levelSpawns[51][0][2]	= -8671.968750;
	levelSpawns[51][1][0]	= 0.0;
	levelSpawns[51][1][1]	= 90.0;
	levelSpawns[51][1][2]	= 0.0;
	levelBoxes[51][0]	= -9167.968750;
	levelBoxes[51][1]	= -5327.968750;
	levelBoxes[51][2]	= -8752.031250;
	levelBoxes[51][3]	= -4272.031250;

	levelSpawns[52][0][0]	= -8959.720703;
	levelSpawns[52][0][1]	= -3777.092773;
	levelSpawns[52][0][2]	= -8415.968750;
	levelSpawns[52][1][0]	= 0.0;
	levelSpawns[52][1][1]	= 90.0;
	levelSpawns[52][1][2]	= 0.0;
	levelBoxes[52][0]	= -9295.951171;
	levelBoxes[52][1]	= -3791.998779;
	levelBoxes[52][2]	= -8624.031250;
	levelBoxes[52][3]	= -2528.031250;

	levelSpawns[53][0][0]	= -8959.674804;
	levelSpawns[53][0][1]	= -2113.464111;
	levelSpawns[53][0][2]	= -8415.968750;
	levelSpawns[53][1][0]	= 0.0;
	levelSpawns[53][1][1]	= 90.0;
	levelSpawns[53][1][2]	= 0.0;
	levelBoxes[53][0]	= -9423.968750;
	levelBoxes[53][1]	= -2127.999511;
	levelBoxes[53][2]	= -8496.031250;
	levelBoxes[53][3]	= -816.031250;

	levelSpawns[54][0][0]	= -8959.681640;
	levelSpawns[54][0][1]	= -449.256378;
	levelSpawns[54][0][2]	= -8415.968750;
	levelSpawns[54][1][0]	= 0.0;
	levelSpawns[54][1][1]	= 90.0;
	levelSpawns[54][1][2]	= 0.0;
	levelBoxes[54][0]	= -9295.998046;
	levelBoxes[54][1]	= -463.968750;
	levelBoxes[54][2]	= -8624.031250;
	levelBoxes[54][3]	= 847.968750;

	levelSpawns[55][0][0]	= -8959.810546;
	levelSpawns[55][0][1]	= 1342.866821;
	levelSpawns[55][0][2]	= -8415.968750;
	levelSpawns[55][1][0]	= 0.0;
	levelSpawns[55][1][1]	= 90.0;
	levelSpawns[55][1][2]	= 0.0;
	levelBoxes[55][0]	= -9167.965820;
	levelBoxes[55][1]	= 1328.031250;
	levelBoxes[55][2]	= -8752.005859;
	levelBoxes[55][3]	= 2383.968750;

	levelSpawns[56][0][0]	= -8959.816406;
	levelSpawns[56][0][1]	= 2750.860107;
	levelSpawns[56][0][2]	= -8415.968750;
	levelSpawns[56][1][0]	= 0.0;
	levelSpawns[56][1][1]	= 90.0;
	levelSpawns[56][1][2]	= 0.0;
	levelBoxes[56][0]	= -9167.966796;
	levelBoxes[56][1]	= 2736.031250;
	levelBoxes[56][2]	= -8752.031250;
	levelBoxes[56][3]	= 3919.968750;

	levelSpawns[57][0][0]	= -8703.722656;
	levelSpawns[57][0][1]	= 4414.456054;
	levelSpawns[57][0][2]	= -8415.968750;
	levelSpawns[57][1][0]	= 0.0;
	levelSpawns[57][1][1]	= 90.0;
	levelSpawns[57][1][2]	= 0.0;
	levelBoxes[57][0]	= -9167.985351;
	levelBoxes[57][1]	= 4400.031250;
	levelBoxes[57][2]	= -8240.001953;
	levelBoxes[57][3]	= 5455.968750;

	levelSpawns[58][0][0]	= -8831.807617;
	levelSpawns[58][0][1]	= 5950.690917;
	levelSpawns[58][0][2]	= -8415.968750;
	levelSpawns[58][1][0]	= 0.0;
	levelSpawns[58][1][1]	= 90.0;
	levelSpawns[58][1][2]	= 0.0;
	levelBoxes[58][0]	= -9167.999023;
	levelBoxes[58][1]	= 5936.031250;
	levelBoxes[58][2]	= -8496.008789;
	levelBoxes[58][3]	= 7119.998046;

	levelSpawns[59][0][0]	= -8927.831054;
	levelSpawns[59][0][1]	= 7614.753417;
	levelSpawns[59][0][2]	= -8415.968750;
	levelSpawns[59][1][0]	= 0.0;
	levelSpawns[59][1][1]	= 90.0;
	levelSpawns[59][1][2]	= 0.0;
	levelBoxes[59][0]	= -9167.996093;
	levelBoxes[59][1]	= 7600.031250;
	levelBoxes[59][2]	= -8688.031250;
	levelBoxes[59][3]	= 9135.968750;
	
	levelSpawns[60][0][0]= -8959.808593;
	levelSpawns[60][0][1]= 9586.528320;
	levelSpawns[60][0][2]= -8415.968750;
	levelSpawns[60][1][0]= 0.0;
	levelSpawns[60][1][1]= 90.0;
	levelSpawns[60][1][2]= 0.0;
	levelBoxes[60][0]= -9167.968750;
	levelBoxes[60][1]= 9520.031250;
	levelBoxes[60][2]= -8752.031250;
	levelBoxes[60][3]= 11215.968750;

	levelSpawns[61][0][0]= -8960.000000;
	levelSpawns[61][0][1]= 11734.368164;
	levelSpawns[61][0][2]= -8415.968750;
	levelSpawns[61][1][0]= 0.0;
	levelSpawns[61][1][1]= 90.0;
	levelSpawns[61][1][2]= 0.0;
	levelBoxes[61][0]= -9167.968750;
	levelBoxes[61][1]= 11696.031250;
	levelBoxes[61][2]= -8754.194335;
	levelBoxes[61][3]= 13391.968750;

	levelSpawns[62][0][0]= -8942.705078;
	levelSpawns[62][0][1]= 13788.423828;
	levelSpawns[62][0][2]= -8415.968750;
	levelSpawns[62][1][0]= 0.0;
	levelSpawns[62][1][1]= 90.0;
	levelSpawns[62][1][2]= 0.0;
	levelBoxes[62][0]= -9167.968750;
	levelBoxes[62][1]= 13744.031250;
	levelBoxes[62][2]= -8720.031250;
	levelBoxes[62][3]= 14959.968750;

	levelSpawns[63][0][0]= -5886.302734;
	levelSpawns[63][0][1]= -15262.449218;
	levelSpawns[63][0][2]= -12511.968750;
	levelSpawns[63][1][0]= 0.0;
	levelSpawns[63][1][1]= 90.0;
	levelSpawns[63][1][2]= 0.0;
	levelBoxes[63][0]= -6095.968750;
	levelBoxes[63][1]= -15311.995117;
	levelBoxes[63][2]= -5680.031250;
	levelBoxes[63][3]= -14224.031250;
	
	levelSpawns[64][0][0]= -5888.290527;
	levelSpawns[64][0][1]= -13734.151367;
	levelSpawns[64][0][2]= -12511.968750;
	levelSpawns[64][1][0]= 0.0;
	levelSpawns[64][1][1]= 90.0;
	levelSpawns[64][1][2]= 0.0;
	levelBoxes[64][0]	= -6095.968750;
	levelBoxes[64][1]	= -13775.999023;
	levelBoxes[64][2]= -5676.832519;
	levelBoxes[64][3]= -12718.416015;

	levelSpawns[65][0][0]= -5887.052246;
	levelSpawns[65][0][1]= -12315.509765;
	levelSpawns[65][0][2]= -12511.968750;
	levelSpawns[65][1][0]= 0.0;
	levelSpawns[65][1][1]= 90.0;
	levelSpawns[65][1][2]= 0.0;
	levelBoxes[65][0]= -6095.968750;
	levelBoxes[65][1]= -12367.968750;
	levelBoxes[65][2]= -5680.031250;
	levelBoxes[65][3]= -11184.031250;

	levelSpawns[66][0][0]= -5889.299316;
	levelSpawns[66][0][1]= -10780.731445;
	levelSpawns[66][0][2]= -12511.968750;
	levelSpawns[66][1][0]= 0.0;
	levelSpawns[66][1][1]= 90.0;
	levelSpawns[66][1][2]= 0.0;
	levelBoxes[66][0]= -6095.968750;
	levelBoxes[66][1]= -10831.968750;
	levelBoxes[66][2]= -5680.031250;
	levelBoxes[66][3]= -9648.031250;

	levelSpawns[67][0][0]= -5890.301269;
	levelSpawns[67][0][1]= -9113.395507;
	levelSpawns[67][0][2]= -12511.968750;
	levelSpawns[67][1][0]= 0.0;
	levelSpawns[67][1][1]= 90.0;
	levelSpawns[67][1][2]= 0.0;
	levelBoxes[67][0]= -6095.968750;
	levelBoxes[67][1]= -9167.550781;
	levelBoxes[67][2]= -5680.031250;
	levelBoxes[67][3]= -7984.031250;

	levelSpawns[68][0][0]= -5886.923828;
	levelSpawns[68][0][1]= -7592.126953;
	levelSpawns[68][0][2]= -12511.968750;
	levelSpawns[68][1][0]= 0.0;
	levelSpawns[68][1][1]= 90.0;
	levelSpawns[68][1][2]= 0.0;
	levelBoxes[68][0]= -6095.968750;
	levelBoxes[68][1]= -7631.968750;
	levelBoxes[68][2]= -5680.031250;
	levelBoxes[68][3]= -6448.031250;

	levelSpawns[69][0][0]= -5848.501465;
	levelSpawns[69][0][1]= -5714.592285;
	levelSpawns[69][0][2]= -12399.222656;
	levelSpawns[69][1][0]= 0.0;
	levelSpawns[69][1][1]= 90.0;
	levelSpawns[69][1][2]= 0.0;
	levelBoxes[69][0]= -6223.968750;
	levelBoxes[69][1]= -5967.968750;
	levelBoxes[69][2]= -5552.031250;
	levelBoxes[69][3]= -4528.009277;
	
	levelSpawns[70][0][0]= -5905.583007;
	levelSpawns[70][0][1]= -4027.975341;
	levelSpawns[70][0][2]= -12511.968750;
	levelSpawns[70][1][0]= 0.0;
	levelSpawns[70][1][1]= 90.0;
	levelSpawns[70][1][2]= 0.0;
	levelBoxes[70][0]= -6095.968750;
	levelBoxes[70][1]= -4047.968750;
	levelBoxes[70][2]= -5680.871093;
	levelBoxes[70][3]= -2736.031250;

	levelSpawns[71][0][0]= -5887.504394;
	levelSpawns[71][0][1]= -2353.251220;
	levelSpawns[71][0][2]= -12511.968750;
	levelSpawns[71][1][0]= 0.0;
	levelSpawns[71][1][1]= 90.0;
	levelSpawns[71][1][2]= 0.0;
	levelBoxes[71][0]= -6095.968750;
	levelBoxes[71][1]= -2383.968750;
	levelBoxes[71][2]= -5680.031250;
	levelBoxes[71][3]= -1328.031250;

	levelSpawns[72][0][0]	= -5887.755859;
	levelSpawns[72][0][1]	= -961.354492;
	levelSpawns[72][0][2]	= -12511.968750;
	levelSpawns[72][1][0]	= 0.0;
	levelSpawns[72][1][1]	= 90.0;
	levelSpawns[72][1][2]	= 0.0;
	levelBoxes[72][0]	= -6095.987304;
	levelBoxes[72][1]	= -975.999450;
	levelBoxes[72][2]	= -5680.000488;
	levelBoxes[72][3]	= -176.024780;
	
	levelSpawns[73][0][0]	= -5887.692382;
	levelSpawns[73][0][1]	= 190.765396;
	levelSpawns[73][0][2]	= -12511.968750;
	levelSpawns[73][1][0]	= 0.0;
	levelSpawns[73][1][1]	= 90.0;
	levelSpawns[73][1][2]	= 0.0;
	levelBoxes[73][0]	= -6095.975585;
	levelBoxes[73][1]	= 176.031250;
	levelBoxes[73][2]	= -5680.031250;
	levelBoxes[73][3]	= 1231.968750;

	levelSpawns[74][0][0]	= -5864.166015;
	levelSpawns[74][0][1]	= 1599.170288;
	levelSpawns[74][0][2]	= -12511.968750;
	levelSpawns[74][1][0]	= 0.0;
	levelSpawns[74][1][1]	= 90.0;
	levelSpawns[74][1][2]	= 0.0;
	levelBoxes[74][0]	= -6095.998046;
	levelBoxes[74][1]	= 1584.031250;
	levelBoxes[74][2]	= -5632.011718;
	levelBoxes[74][3]	= 2383.968750;
	
	levelSpawns[75][0][0]	= -5887.502441;
	levelSpawns[75][0][1]	= 2750.923828;
	levelSpawns[75][0][2]	= -12511.968750;
	levelSpawns[75][1][0]	= 0.0;
	levelSpawns[75][1][1]	= 90.0;
	levelSpawns[75][1][2]	= 0.0;
	levelBoxes[75][0]	= -6095.985351;
	levelBoxes[75][1]	= 2736.008056;
	levelBoxes[75][2]	= -5680.000976;
	levelBoxes[75][3]	= 3663.968750;

	levelSpawns[76][0][0]	= -5887.557128;
	levelSpawns[76][0][1]	= 4030.956542;
	levelSpawns[76][0][2]	= -12511.968750;
	levelSpawns[76][1][0]	= 0.0;
	levelSpawns[76][1][1]	= 90.0;
	levelSpawns[76][1][2]	= 0.0;
	levelBoxes[76][0]	= -6095.976562;
	levelBoxes[76][1]	= 4016.031250;
	levelBoxes[76][2]	= -5680.031250;
	levelBoxes[76][3]	= 4591.968750;

	levelSpawns[77][0][0]	= -5887.852539;
	levelSpawns[77][0][1]	= 5054.970214;
	levelSpawns[77][0][2]	= -12511.968750;
	levelSpawns[77][1][0]	= 0.0;
	levelSpawns[77][1][1]	= 90.0;
	levelSpawns[77][1][2]	= 0.0;
	levelBoxes[77][0]	= -6095.992187;
	levelBoxes[77][1]	= 5040.000488;
	levelBoxes[77][2]	= -5680.005371;
	levelBoxes[77][3]	= 6095.968750;
	
	levelSpawns[78][0][0]	= -5887.670410;
	levelSpawns[78][0][1]	= 6718.723144;
	levelSpawns[78][0][2]	= -12511.968750;
	levelSpawns[78][1][0]	= 0.0;
	levelSpawns[78][1][1]	= 90.0;
	levelSpawns[78][1][2]	= 0.0;
	levelBoxes[78][0]	= -6095.971679;
	levelBoxes[78][1]	= 6704.031250;
	levelBoxes[78][2]	= -5680.031250;
	levelBoxes[78][3]	= 7759.987792;
	
	levelSpawns[79][0][0]	= -5887.787109;
	levelSpawns[79][0][1]	= 8510.868164;
	levelSpawns[79][0][2]	= -12511.968750;
	levelSpawns[79][1][0]	= 0.0;
	levelSpawns[79][1][1]	= 90.0;
	levelSpawns[79][1][2]	= 0.0;
	levelBoxes[79][0]	= -6240.212402;
	levelBoxes[79][1]	= 8466.887695;
	levelBoxes[79][2]	= -5531.928222;
	levelBoxes[79][3]	= 9826.652343;

	levelSpawns[80][0][0]= -5888.115234;
	levelSpawns[80][0][1]= 10316.535156;
	levelSpawns[80][0][2]= -12511.968750;
	levelSpawns[80][1][0]= 0.0;
	levelSpawns[80][1][1]= 90.0;
	levelSpawns[80][1][2]= 0.0;
	levelBoxes[80][0]= -6095.968750;
	levelBoxes[80][1]= 10288.031250;
	levelBoxes[80][2]= -5680.031250;
	levelBoxes[80][3]= 11855.968750;

	levelSpawns[81][0][0]= -5888.415039;
	levelSpawns[81][0][1]= 12379.771484;
	levelSpawns[81][0][2]= -12511.968750;
	levelSpawns[81][1][0]= 0.0;
	levelSpawns[81][1][1]= 90.0;
	levelSpawns[81][1][2]= 0.0;
	levelBoxes[81][0]= -6063.968750;
	levelBoxes[81][1]= 12336.031250;
	levelBoxes[81][2]= -5712.031250;
	levelBoxes[81][3]= 13263.968750;

	levelSpawns[82][0][0]= -5888.112792;
	levelSpawns[82][0][1]= 13675.666992;
	levelSpawns[82][0][2]= -12511.968750;
	levelSpawns[82][1][0]= 0.0;
	levelSpawns[82][1][1]= 90.0;
	levelSpawns[82][1][2]= 0.0;
	levelBoxes[82][0]= -6095.968750;
	levelBoxes[82][1]= 13616.031250;
	levelBoxes[82][2]= -5680.031250;
	levelBoxes[82][3]= 14687.968750;

	levelSpawns[83][0][0]	= -2847.661376;
	levelSpawns[83][0][1]	= -15297.319335;
	levelSpawns[83][0][2]	= -15327.968750;
	levelSpawns[83][1][0]	= 0.0;
	levelSpawns[83][1][1]	= 90.0;
	levelSpawns[83][1][2]	= 0.0;
	levelBoxes[83][0]	= -3023.976562;
	levelBoxes[83][1]	= -15311.968750;
	levelBoxes[83][2]	= -2672.031250;
	levelBoxes[83][3]	= -14384.003906;

	levelSpawns[84][0][0]= -2815.594238;
	levelSpawns[84][0][1]= -13851.839843;
	levelSpawns[84][0][2]= -15327.968750;
	levelSpawns[84][1][0]= 0.0;
	levelSpawns[84][1][1]= 90.0;
	levelSpawns[84][1][2]= 0.0;
	levelBoxes[84][0]= -3023.968750;
	levelBoxes[84][1]= -13903.968750;
	levelBoxes[84][2]= -2608.031250;
	levelBoxes[84][3]= -12336.031250;

	levelSpawns[85][0][0]= -2814.893798;
	levelSpawns[85][0][1]= -11807.021484;
	levelSpawns[85][0][2]= -15327.968750;
	levelSpawns[85][1][0]= 0.0;
	levelSpawns[85][1][1]= 90.0;
	levelSpawns[85][1][2]= 0.0;
	levelBoxes[85][0]= -3151.968750;
	levelBoxes[85][1]= -11855.968750;
	levelBoxes[85][2]= -2480.031250;
	levelBoxes[85][3]= -10288.031250;

	levelSpawns[86][0][0]= -2815.723632;
	levelSpawns[86][0][1]= -9765.757812;
	levelSpawns[86][0][2]= -15327.968750;
	levelSpawns[86][1][0]= 0.0;
	levelSpawns[86][1][1]= 90.0;
	levelSpawns[86][1][2]= 0.0;
	levelBoxes[86][0]	= -3023.966308;
	levelBoxes[86][1]= -9807.968750;
	levelBoxes[86][2]= -2608.031250;
	levelBoxes[86][3]= -8368.031250;

	levelSpawns[87][0][0]= -2815.965087;
	levelSpawns[87][0][1]= -7983.477539;
	levelSpawns[87][0][2]= -15231.968750;
	levelSpawns[87][1][0]= 0.0;
	levelSpawns[87][1][1]= 90.0;
	levelSpawns[87][1][2]= 0.0;
	levelBoxes[87][0]= -3023.968750;
	levelBoxes[87][1]= -8015.968750;
	levelBoxes[87][2]= -2608.031250;
	levelBoxes[87][3]= -6832.031250;

	levelSpawns[88][0][0]	= -2815.685546;
	levelSpawns[88][0][1]	= -6464.895507;
	levelSpawns[88][0][2]	= -15231.968750;
	levelSpawns[88][1][0]	= 0.0;
	levelSpawns[88][1][1]	= 90.0;
	levelSpawns[88][1][2]	= 0.0;
	levelBoxes[88][0]	= -3023.968750;
	levelBoxes[88][1]	= -6479.982421;
	levelBoxes[88][2]	= -2608.031250;
	levelBoxes[88][3]	= -5424.031250;

	levelSpawns[89][0][0]	= -2815.866943;
	levelSpawns[89][0][1]	= -5057.458496;
	levelSpawns[89][0][2]	= -15231.968750;
	levelSpawns[89][1][0]	= 0.0;
	levelSpawns[89][1][1]	= 90.0;
	levelSpawns[89][1][2]	= 0.0;
	levelBoxes[89][0]	= -3023.968750;
	levelBoxes[89][1]	= -5071.969726;
	levelBoxes[89][2]	= -2608.031250;
	levelBoxes[89][3]	= -4032.002685;

	levelSpawns[90][0][0]= -2817.412841;
	levelSpawns[90][0][1]= -3608.729492;
	levelSpawns[90][0][2]= -15231.968750;
	levelSpawns[90][1][0]= 0.0;
	levelSpawns[90][1][1]= 90.0;
	levelSpawns[90][1][2]= 0.0;
	levelBoxes[90][0]= -3020.945556;
	levelBoxes[90][1]= -3663.968750;
	levelBoxes[90][2]= -2608.031250;
	levelBoxes[90][3]= -2480.031250;

	levelSpawns[91][0][0]= -2815.120117;
	levelSpawns[91][0][1]= -2081.452392;
	levelSpawns[91][0][2]= -15231.968750;
	levelSpawns[91][1][0]= 0.0;
	levelSpawns[91][1][1]= 90.0;
	levelSpawns[91][1][2]= 0.0;
	levelBoxes[91][0]	= -3142.128417;
	levelBoxes[91][1]	= -2166.922607;
	levelBoxes[91][2]	= -2491.535400;
	levelBoxes[91][3]	= -1481.823852;
		
	levelSpawns[92][0][0]= -2817.077148;
	levelSpawns[92][0][1]= -1024.074584;
	levelSpawns[92][0][2]= -15183.968750;
	levelSpawns[92][1][0]= 0.0;
	levelSpawns[92][1][1]= 90.0;
	levelSpawns[92][1][2]= 0.0;
	levelBoxes[92][0]= -3023.968750;
	levelBoxes[92][1]= -1071.968750;
	levelBoxes[92][2]= -2608.031250;
	levelBoxes[92][3]= -144.031250;

	levelSpawns[93][0][0]= -2812.528076;
	levelSpawns[93][0][1]= 355.353210;
	levelSpawns[93][0][2]= -15327.968750;
	levelSpawns[93][1][0]= 0.0;
	levelSpawns[93][1][1]= 90.0;
	levelSpawns[93][1][2]= 0.0;
	levelBoxes[93][0]= -3023.968750;
	levelBoxes[93][1]= 304.017364;
	levelBoxes[93][2]= -2608.031250;
	levelBoxes[93][3]= 1103.982055;
	
	levelSpawns[94][0][0]= -2815.719726;
	levelSpawns[94][0][1]= 1506.590820;
	levelSpawns[94][0][2]= -15455.968750;
	levelSpawns[94][1][0]= 0.0;
	levelSpawns[94][1][1]= 90.0;
	levelSpawns[94][1][2]= 0.0;
	levelBoxes[94][0]= -3151.968750;
	levelBoxes[94][1]= 1456.140869;
	levelBoxes[94][2]= -2480.031250;
	levelBoxes[94][3]= 2767.968750;

	levelSpawns[95][0][0]	= -2815.709228;
	levelSpawns[95][0][1]	= 3134.741943;
	levelSpawns[95][0][2]	= -15231.968750;
	levelSpawns[95][1][0]	= 0.0;
	levelSpawns[95][1][1]	= 90.0;
	levelSpawns[95][1][2]	= 0.0;
	levelBoxes[95][0]	= -3023.990722;
	levelBoxes[95][1]	= 3120.000244;
	levelBoxes[95][2]	= -2608.031250;
	levelBoxes[95][3]	= 4687.995605;

	levelSpawns[96][0][0]	= -2815.637451;
	levelSpawns[96][0][1]	= 5182.633300;
	levelSpawns[96][0][2]	= -15455.968750;
	levelSpawns[96][1][0]	= 0.0;
	levelSpawns[96][1][1]	= 90.0;
	levelSpawns[96][1][2]	= 0.0;
	levelBoxes[96][0]	= -3023.981201;
	levelBoxes[96][1]	= 5168.031250;
	levelBoxes[96][2]	= -2608.031250;
	levelBoxes[96][3]	= 5791.998046;

	levelSpawns[97][0][0]	= -2879.940917;
	levelSpawns[97][0][1]	= 6206.854980;
	levelSpawns[97][0][2]	= -15231.968750;
	levelSpawns[97][1][0]	= 0.0;
	levelSpawns[97][1][1]	= 90.0;
	levelSpawns[97][1][2]	= 0.0;
	levelBoxes[97][0]	= -3023.921875;
	levelBoxes[97][1]	= 6192.006347;
	levelBoxes[97][2]	= -2736.031250;
	levelBoxes[97][3]	= 7375.991699;
	
	levelSpawns[98][0][0]	= -2815.668212;
	levelSpawns[98][0][1]	= 7742.805175;
	levelSpawns[98][0][2]	= -15231.968750;
	levelSpawns[98][1][0]	= 0.0;
	levelSpawns[98][1][1]	= 90.0;
	levelSpawns[98][1][2]	= 0.0;
	levelBoxes[98][0]	= -3023.997314;
	levelBoxes[98][1]	= 7728.031250;
	levelBoxes[98][2]	= -2608.031250;
	levelBoxes[98][3]	= 8783.995117;

	levelSpawns[99][0][0]	= -2815.724609;
	levelSpawns[99][0][1]	= 9150.870117;
	levelSpawns[99][0][2]	= -15455.968750;
	levelSpawns[99][1][0]	= 0.0;
	levelSpawns[99][1][1]	= 90.0;
	levelSpawns[99][1][2]	= 0.0;
	levelBoxes[99][0]	= -3023.973632;
	levelBoxes[99][1]	= 9136.010742;
	levelBoxes[99][2]	= -2608.031250;
	levelBoxes[99][3]	= 10831.998046;
	
	levelSpawns[100][0][0]	= -3839.766601;
	levelSpawns[100][0][1]	= 9278.825195;
	levelSpawns[100][0][2]	= -14303.968750;
	levelSpawns[100][1][0]	= 0.0;
	levelSpawns[100][1][1]	= 90.0;
	levelSpawns[100][1][2]	= 0.0;
	levelBoxes[100][0]	= -4047.984619;
	levelBoxes[100][1]	= 9264.001953;
	levelBoxes[100][2]	= -3632.031250;
	levelBoxes[100][3]	= 15567.968750;
	
	levelBoxes[101][0]	= -1023.813476;
	levelBoxes[101][1]	= 13030.647460;
	levelBoxes[101][2]	= 1263.618530;
	levelBoxes[101][3]	= 15385.837890;


}

