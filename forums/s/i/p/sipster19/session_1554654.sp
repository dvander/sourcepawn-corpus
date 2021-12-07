// File:   session.sp
// Author: ]SoD[ Frostbyte

#include "sodstats\include\sodstats.inc"

PrintSession(client)
{
	Stats_GetPlayerSession(client, SessionCallback, client);
}

public SessionCallback(const String:name[], const String:steamid[], any:stats[], any:data, error)
{
	if(error == ERROR_PLAYER_NOT_FOUND)
	{
		LogError("[SoD-Stats] SessionCallback: Player not found");
		return;
	}
	
	new client = data;
	
	decl String:text[256];
	new Handle:panel = CreatePanel();
	DrawPanelText(panel, "[SoD-Stats] Player Session Stats");
	DrawPanelItem(panel, "Name");
	Format(text, sizeof(text), "%s", name);
	DrawPanelText(panel, text);
	DrawPanelItem(panel, "Score");
	Format(text, sizeof(text), "%i", stats[STAT_SCORE]);
	DrawPanelText(panel, text);
	DrawPanelItem(panel, "Time played");
	Format(text, sizeof(text), "%id %ih %im", stats[STAT_TIME_PLAYED] / 86400,
											  (stats[STAT_TIME_PLAYED] % 86400) / 3600,
											  (stats[STAT_TIME_PLAYED] % 3600) / 60);
	DrawPanelText(panel, text);
	DrawPanelItem(panel, "Kills/Deaths");
	Format(text, sizeof(text), "%i/%i - %.2f KD", stats[STAT_KILLS], 
											   stats[STAT_DEATHS], 
											   float(stats[STAT_KILLS])/
											   (stats[STAT_DEATHS] > 0 ? 
											    float(stats[STAT_DEATHS]) : 1.0));
	DrawPanelText(panel, text);
	if(stats[STAT_HEADSHOTS] > 0 && stats[STAT_KILLS] != 0)
	{
		DrawPanelItem(panel, "Headshots");
		Format(text, sizeof(text), "%i (%i%%)", stats[STAT_HEADSHOTS], (100*stats[STAT_HEADSHOTS]/stats[STAT_KILLS]));
		DrawPanelText(panel, text);
	}
	if(stats[STAT_SHOTS] > 0)
	{
		DrawPanelItem(panel, "Hits/Shots");
		Format(text, sizeof(text), "%i/%i - %.2f%%", stats[STAT_HITS], 
													 stats[STAT_SHOTS],
													 100.0*float(stats[STAT_HITS])/
													 float(stats[STAT_SHOTS]));
		DrawPanelText(panel, text);
	}
	SendPanelToClient(panel, client, SessionHandler, 10);
	CloseHandle(panel);
}

public SessionHandler(Handle:menu, MenuAction:action, param1, param2)
{
}