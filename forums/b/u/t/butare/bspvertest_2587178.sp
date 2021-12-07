#include <sourcemod>

public Plugin myinfo = 
{
	name = "VBSP Ver tester",
	author = "GAMMA CASE",
	description = "Checks .bsp ver",
	version = "1.0.0",
	url = "http://steamcommunity.com/id/_GAMMACASE_/"
}

public void OnPluginStart()
{
	RegAdminCmd("sm_checkver", SM_Checkver, ADMFLAG_ROOT, "Checks .bsp ver for a specific map or for all maps");
}

public Action SM_Checkver(int client, int args)
{
	if(args < 1)
	{
		ReplyToCommand(client, "[SM] Usage !checkver <mapname> of all to check all maps");
		
		return Plugin_Handled;
	}
	
	char sMapName[PLATFORM_MAX_PATH], sPath[PLATFORM_MAX_PATH];
	int ver;
	GetCmdArgString(sMapName, sizeof(sMapName));
	
	if(StrEqual(sMapName, "all", false))
	{
		char sFile[PLATFORM_MAX_PATH];
		int counter;
		FileType type;
		File outf = OpenFile("cssmaps.txt", "w", true);
		File bsp;
		DirectoryListing dir = OpenDirectory("maps/", true);
		
		outf.WriteLine("CSS Maps in maps/ folder: ");
		
		while(dir.GetNext(sFile, sizeof(sFile), type))
		{
			if(type == FileType_Directory)
				continue;
			
			if(sFile[0] == '.' || (sFile[0] == '.' && sFile[1] == '.'))
				continue;
				
			if(StrContains(sFile, ".bsp", false) == -1)
				continue;
				
			Format(sPath, sizeof(sPath), "maps/%s", sFile);
			
			bsp = OpenFile(sPath, "rb", true);
			
			if(bsp == null)
			{
				ReplyToCommand(client, "[SM] Cannot open file for reading [%s]!", sFile);
				bsp.Close();
				continue;
			}
			
			bsp.Seek(4, SEEK_SET);
			bsp.ReadInt32(ver);
			
			if(ver == 20)
			{
				ReplaceString(sFile, sizeof(sFile), ".bsp", "", false);
				outf.WriteLine("%s", sFile);
				counter++;
			}
			
			bsp.Close();
		}
		
		ReplyToCommand(client, "[SM] Total amount of css maps: %i", counter);
		ReplyToCommand(client, "[SM] Check <csgo/cssmaps.txt> file for full list of css maps!");
		outf.WriteLine("Total amount of css maps: %i", counter);
		outf.Close();
		delete dir;
	}
	else
	{
		Format(sPath, sizeof(sPath), "maps/%s.bsp", sMapName);
		
		File file = OpenFile(sPath, "rb", true);
		
		if(file == null)
		{
			char possiblemap[PLATFORM_MAX_PATH];
			FindMap(sMapName, possiblemap, sizeof(possiblemap));
			
			ReplyToCommand(client, "[SM] Incorrect map name or broken bsp file! Maybe you meant %s?", possiblemap);
			file.Close();
			
			return Plugin_Handled;
		}
		
		file.Seek(4, SEEK_SET);
		file.ReadInt32(ver);
		
		ReplyToCommand(client, "[SM] VBSP ver for %s is %i [%s]", sMapName, ver, (ver == 21) ? "CSGO" : "CSS");
		
		file.Close();
	}
	
	return Plugin_Handled;
}