// File:   rank.sp
// Author: ]SoD[ Frostbyte

#include "sodstats\include\sodstats.inc"
#include <sourcemod>
PrintRankToAll(client)
{
	Stats_GetPlayerRank(client, Rank_Callback, client);
}

public Rank_Callback(rank, delta, any:data, error)
{
	new client = data;
	new Handle:pack = CreateDataPack();
	WritePackCell(pack, rank);
	WritePackCell(pack, delta);
	WritePackCell(pack, client);
	Stats_GetPlayerById(client, Rank_PlayerIdCallback, pack);
}

public Rank_PlayerIdCallback(const String:name[], const String:steamid[], any:stats[], any:data, error)
{
	if(error == ERROR_PLAYER_NOT_FOUND)
	{
		LogError("[SoD-Stats] RankCallback: Player not found");
		return;
	}

	new Handle:pack = data;
	ResetPack(pack);
	
	new rank = ReadPackCell(pack);
	new delta = ReadPackCell(pack);
	new client = ReadPackCell(pack);
	
	decl String:text[256];
	
	new bool:isAlive = IsPlayerAlive(client);
	
	if(g_gameid == ID_CSS || g_gameid == ID_TF2)
	{
		Format(text, sizeof(text), "\x04SoD-Stats: \x01Player \x03%s\x01's rank is \x04%i/%i\x01 with \x04%i\x01 points (%i to next rank), \x04%i\x01 kills and \x04%i\x01 deaths", 
								   name, 
								   rank, 
								   g_player_count, 
								   stats[STAT_SCORE] + g_start_points, 
								   delta, 
								   stats[STAT_KILLS], 
								   stats[STAT_DEATHS]);
		
		ColoredToAll(client, text, isAlive);
	}
	else
	{
		Format(text, sizeof(text), "SoD-Stats: Player %s's rank is %i/%i with %i points (%i to next rank), %i kills and %i deaths", 
								   name, 
								   rank, 
								   g_player_count, 
								   stats[STAT_SCORE] + g_start_points, 
								   delta, 
								   stats[STAT_KILLS], 
								   stats[STAT_DEATHS]);
		
		
		
		switch(g_displaymode)
		{
			case DISPLAYMODE_PUBLIC:
				PrintToChatAll(text);
			case DISPLAYMODE_PRIVATE:
				PrintToChat(client, text);
			case DISPLAYMODE_CHAT:
			{
				if(isAlive == true)
				{
					PrintToChatAll(text);
				}
				else
				{
					new maxclients = GetMaxClients();
					for(new i = 1; i <= maxclients; i++)
					{
						if(IsClientInGame(i) && !IsFakeClient(i) && (!IsPlayerAlive(i) || isAlive))
						{
							PrintToChat(i, text);
						}
					}
				}
			}
		}
	}
}

ColoredToAll(client, const String:message[], isAlive)
{
	switch(g_displaymode)
	{
		case DISPLAYMODE_PUBLIC:
		{
			new maxclients = GetMaxClients();
			for(new i = 1; i <= maxclients; i++)
			{
				if(IsClientInGame(i) && !IsFakeClient(i))
				{
					SayText2(i, client, message);
				}
			}
		}
		case DISPLAYMODE_PRIVATE:
			SayText2(client, client, message);
		case DISPLAYMODE_CHAT:
		{
			new maxclients = GetMaxClients();
			for(new i = 1; i <= maxclients; i++)
			{
				if(IsClientInGame(i) && !IsFakeClient(i) && (!IsPlayerAlive(i) || isAlive))
				{
					SayText2(i, client, message);
				}
			}
		}
	}
}

// CREDITS TO DJTSUNAMI FOR THIS
public SayText2(to, from, const String:message[])
{
	new Handle:hMsg = StartMessageOne("SayText2", to);
	
	if (GetUserMessageType() == UM_Protobuf)
	{
		//DUCKS, DUCKS EVERYWHERE !!! thanks to psy for the code, the patch, and more
		PbSetInt(hMsg, "ent_idx", from);
		PbSetBool(hMsg, "chat", true);
		
		PbSetString(hMsg, "msg_name", message);
		
		PbAddString(hMsg, "params", "");
		PbAddString(hMsg, "params", "");
		PbAddString(hMsg, "params", "");
		PbAddString(hMsg, "params", "");
	}
	else
	{
		BfWriteByte(hMsg, from);
		BfWriteByte(hMsg, true);
		BfWriteString(hMsg, message);
	}
	
	EndMessage();
}
