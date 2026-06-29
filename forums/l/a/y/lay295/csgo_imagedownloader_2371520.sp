#include <sourcemod>
#include <sdktools>

public Plugin myinfo = 
{
	name = "Map Image Downloader",
	author = "Mr.Derp",
	description = "",
	version = "1.0",
	url = "http://steamcommunity.com/id/iLoveAnime69"
};

public OnMapStart()
{
	decl String:mapname[128];
	GetCurrentMap(mapname, sizeof(mapname));
	decl String:filepath[128];
	Format(filepath, sizeof(filepath), "maps/%s.jpg", mapname);
	if (FileExists(filepath))
	{
		AddFileToDownloadsTable(filepath);
	}
}