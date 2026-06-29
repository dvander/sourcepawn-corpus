#include <sourcemod>

public Plugin:myinfo =
{
	name = "SM CS:GO Auto-Precache Particles", 
	author = "Franc1sco franug", 
	description = "", 
	version = "1.0", 
	url = "http://steamcommunity.com/id/franug"
};

public OnMapStart()
{
	Precaching("particles");
}

Precaching(const String:path[])
{
	if (DirExists(path, true)) {

		decl String:dirEntry[PLATFORM_MAX_PATH];
		new Handle:__dir = OpenDirectory(path, true);

		while (ReadDirEntry(__dir, dirEntry, sizeof(dirEntry))) {

			if (StrEqual(dirEntry, ".") || StrEqual(dirEntry, "..")) {
				continue;
			}
			
			Format(dirEntry, sizeof(dirEntry), "%s/%s", path, dirEntry);
			if(FileExists(dirEntry, true)) PrecacheGeneric(dirEntry, true);
			else Precaching(dirEntry);
			
			PrintToServer("[APP] Precached particle %s", dirEntry);
			
		}
		
		CloseHandle(__dir);
	}
}