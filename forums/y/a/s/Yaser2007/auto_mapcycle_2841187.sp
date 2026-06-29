#pragma semicolon 1
#pragma newdecls required

#define MAPCYCLE_FILE "cfg/mapcycle.txt"

File g_hExcludeMaps;

public Plugin myinfo =
{
	name = "Auto Mapcycle",
	author = "Yaser2007",
	description = "Automatically generates mapcycle.",
	version = "1.2",
	url = "https://www.sourcemod.net/plugins.php?cat=0&mod=-1&title=&author=Yaser2007&description=&search=1"
};

public void OnPluginStart()
{
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "configs/mapcycle_excludes.ini");

	if(!FileExists(path))
	{
		File file = OpenFile(path, "w");
		if(file != null)
		{
			if(GetEngineVersion() & Engine_CSS)
			{
				WriteFileLine(file, "test_hardware\ntest_speakers");
			}
			delete file;
		}
	}
	else
	{
		g_hExcludeMaps = OpenFile(path, "r");
	}
}

public void OnPluginEnd()
{
	delete g_hExcludeMaps;
}

public void OnMapStart()
{
	File file = OpenFile(MAPCYCLE_FILE, "w");
	DirectoryListing dir = OpenDirectory("maps", true);
	ArrayList array = CreateArray(64);
	FileType type;
	int len;
	bool exclude;
	char buffer[PLATFORM_MAX_PATH];
	char excludedMap[PLATFORM_MAX_PATH];
	while(ReadDirEntry(dir, buffer, sizeof(buffer), type))
	{
		if(type != FileType_File)
		{
			continue;
		}

		len = strlen(buffer) - 4;
		if(StrContains(buffer, ".bsp", false) != len)
		{
			continue;
		}
		buffer[len] = '\0';

		if(g_hExcludeMaps != null)
		{
			FileSeek(g_hExcludeMaps, SEEK_SET, 0);
			while(!IsEndOfFile(g_hExcludeMaps) && ReadFileLine(g_hExcludeMaps, excludedMap, sizeof(excludedMap)))
			{
				if(StrStartsWith(buffer, excludedMap))
				{
					exclude = true;
					break;
				}
			}
		}

		if(!exclude)
		{
			PushArrayString(array, buffer);
		}

		exclude = false;
	}

	SortADTArray(array, Sort_Ascending, Sort_String);

	len = GetArraySize(array);
	for(int i; i < len; i++)
	{
		GetArrayString(array, i, buffer, sizeof(buffer));
		WriteFileLine(file, buffer);
	}

	delete dir;
	delete file;
	delete array;
}

stock bool StrStartsWith(const char[] str, const char[] subString)
{
	int n;
	while(subString[n] != '\0')
	{
		if(str[n] == '\0' || str[n] != subString[n])
		{
			return false;
		}
		n++;
	}

	return true;
}