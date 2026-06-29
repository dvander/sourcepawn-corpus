
#include <mapchooser>

KeyValues workshopmaps;

public void OnPluginStart()
{
	workshopmaps = new KeyValues("list");
	ReadMaps();
	ReadMissions();
}

Handle tracetimer;
public void OnMapVoteStarted()
{
	tracetimer = CreateTimer(5.0, delay, INVALID_HANDLE, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action delay(Handle timer)
{
	if(tracetimer != timer)
		return Plugin_Stop;

	if(!HasEndOfMapVoteFinished())
		return Plugin_Continue;

	char map[MAX_NAME_LENGTH];
	char value[65];
	GetNextMap(map, sizeof(map));

	//PrintToServer("nextmap %s", map);

	if(IsCustomMap(map))
	{
		PrintToChatAll("\x04  Next map '%s' is custom! You can look list of workshop addons ID from your console, now!", map);
		PrintToConsoleAll("\n\n		Server L4D2 workshop addons list - begin\n");
		workshopmaps.Rewind(false);
		if(!workshopmaps.JumpToKey("id", false) || !workshopmaps.GotoFirstSubKey(false))
			return Plugin_Stop;
		
		do {
			workshopmaps.GetString(NULL_STRING, value, sizeof(value));
			PrintToConsoleAll("https://steamcommunity.com/sharedfiles/filedetails/?id=%s", value);
		}
		while(workshopmaps.GotoNextKey(false))

		PrintToConsoleAll("\n\n		Maps:");

		workshopmaps.Rewind(false);
		if(!workshopmaps.JumpToKey("maps", false) || !workshopmaps.GotoFirstSubKey(false))
			return Plugin_Stop;
		
		do {
			workshopmaps.GetString(NULL_STRING, value, sizeof(value));
			PrintToConsoleAll("%s", value);
		}
		while(workshopmaps.GotoNextKey(false))

		PrintToConsoleAll("\n\n		Server L4D2 workshop addons list - end\n");
	}

	return Plugin_Stop;
}



stock void ReadMaps()
{
	if(workshopmaps == null)
		return;

	DirectoryListing workshopdir = OpenDirectory("maps", true, "Break da system"); // look steam files but, use invalid gameinfo path.

	if(workshopdir == null)
		return;

	workshopmaps.Rewind(true);

	char buffer[PLATFORM_MAX_PATH];
	char key[5];

	FileType type = FileType_Unknown;
	int index = 0;
	int x = 0;

	workshopmaps.JumpToKey("maps", true);

	do {
		if(type != FileType_File)
			continue;

		index = FindCharInString(buffer, '.', true);

		if(index <= 0 || !StrEqual(buffer[index], ".bsp", false))
			continue;

		buffer[index] = '\0';

		Format(key, sizeof(key), "%i", x++);
		workshopmaps.SetString(key, buffer);
	}
	while(workshopdir.GetNext(buffer, sizeof(buffer), type))

	delete workshopdir;

	workshopdir = OpenDirectory("addons/workshop", false); // loose files

	workshopmaps.Rewind(false);

	if(workshopdir == null)
	{
		workshopmaps.ExportToFile("l4d2_map.txt");
		return;
	}

	type = FileType_Unknown;
	index = 0;
	x = 0;

	workshopmaps.JumpToKey("id", true);

	do {
		if(type != FileType_File)
			continue;

		index = FindCharInString(buffer, '.', true);

		if(index <= 0 || !StrEqual(buffer[index], ".vpk", false))
			continue;

		buffer[index] = '\0';

		Format(key, sizeof(key), "%i", x++);
		workshopmaps.SetString(key, buffer);
	}
	while(workshopdir.GetNext(buffer, sizeof(buffer), type))

	delete workshopdir;

	workshopmaps.Rewind(false);
	workshopmaps.ExportToFile("l4d2_map.txt");
}

stock void ReadMissions()
{
	if(workshopmaps == null)
		return;

	workshopmaps.Rewind(true);

	DirectoryListing workshopdir = OpenDirectory("missions", true, "break da system"); // look steam files but, use invalid gameinfo path.

	if(workshopdir == null)
		return;


	char buffer[PLATFORM_MAX_PATH];
	char key[35];

	FileType type = FileType_Unknown;
	int index = 0;
	int x = 0;

	workshopmaps.JumpToKey("mission", true);

	do {
		if(type != FileType_File)
			continue;

		index = FindCharInString(buffer, '.', true);

		if(index <= 0 || !StrEqual(buffer[index], ".txt", false))
			continue;

		Format(key, sizeof(key), "%i", x++);
		workshopmaps.SetString(key, buffer);
	}
	while(workshopdir.GetNext(buffer, sizeof(buffer), type))

	delete workshopdir;

	workshopmaps.Rewind(false);
	workshopmaps.ExportToFile("l4d2_map.txt");
}

stock bool IsCustomMap(const char[] map)
{
	if(workshopmaps == null)
		return false;

	workshopmaps.Rewind(false);

	if(!workshopmaps.JumpToKey("maps", false))
		return false;

	workshopmaps.GotoFirstSubKey(false);

	char value[MAX_NAME_LENGTH];

	do {
		workshopmaps.GetString(NULL_STRING, value, sizeof(value));
		//PrintToServer("value %s", value);
		if(StrEqual(map, value, false))
		{
			return true;
		}
	}
	while(workshopmaps.GotoNextKey(false))

	return false;
}