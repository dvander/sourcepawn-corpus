#pragma semicolon 1
#pragma newdecls required
#pragma dynamic 32768

public Plugin myinfo =
{
	name = "Maps Lighting Info",
	description = "Информация о типе освещения карт на сервере",
	author = "Phoenix (˙·٠●Феникс●٠·˙)",
	version = "1.0.0",
	url = "zizt.ru hlmod.ru"
};


#define	LUMP_T_SIZE			16
#define	LUMP_LIGHTING_HDR	53
#define	LUMP_LIGHTING			8

ArrayList g_hMapsList;

static const char g_sLightingType[][] = {"BOTH (LDR + HDR)", "HDR", "LDR", "0_0 No lighting?"};


public void OnPluginStart()
{
	if(GetEngineVersion() != Engine_CSGO)
	{
		SetFailState("[Maps Lighting Info] Плагин только для сервера CSGO");
		return;
	}
	
	g_hMapsList = new ArrayList(ByteCountToCells(PLATFORM_MAX_PATH));
	
	MapsDirectoryRecursive("maps/");
	
	if(g_hMapsList.Length)
	{
		char sPath[PLATFORM_MAX_PATH];
		
		BuildPath(Path_SM, sPath, sizeof sPath, "logs/MapsLightingInfo.log");
		
		File hLog = OpenFile(sPath, "w");
		
		if(hLog)
		{
			int iLength = g_hMapsList.Length;
			
			char[][] sMaps = new char[iLength][PLATFORM_MAX_PATH];
			
			for(int i = 0; i < iLength; i++)
			{
				g_hMapsList.GetString(i, sMaps[i], PLATFORM_MAX_PATH);
			}
			
			SortStrings(sMaps, iLength, Sort_Ascending);
			
			for(int i = 0; i < iLength; i++)
			{
				hLog.WriteLine("%s - %s", g_sLightingType[sMaps[i][0] - 48], sMaps[i][1]);
			}
			
			delete hLog;
		}
		else
		{
			SetFailState("[Maps Lighting Info] Не удалось создать лог '%s'", sPath);
			return;
		}
	}
	
	delete g_hMapsList;
}

void MapsDirectoryRecursive(const char[] sPath)
{
	DirectoryListing hDirectory = OpenDirectory(sPath);
	char sPathFull[PLATFORM_MAX_PATH];
	FileType iType;
	
	while (hDirectory.GetNext(sPathFull, sizeof sPathFull, iType))
	{
		if(sPathFull[0] == '.') continue;
		
		Format(sPathFull, sizeof sPathFull, "%s/%s", sPath, sPathFull);
		
		switch(iType)
		{
			case FileType_Directory:
			{
				MapsDirectoryRecursive(sPathFull);
			}
			case FileType_File:
			{
				MapsLightingInfo(sPathFull);
			}
		}
	}
	
	delete hDirectory;
}

void MapsLightingInfo(const char[] sMap)
{
	int iLen = strlen(sMap);
	
	if(iLen > 3 && strcmp(sMap[iLen-4], ".bsp", false) == 0)
	{
		File hMap = OpenFile(sMap, "rb");
		
		if(hMap)
		{
			int iBuf;
			
			if(hMap.ReadInt32(iBuf) && iBuf == 0x50534256 && hMap.ReadInt32(iBuf) && (iBuf == 20 || iBuf == 21)) //"VBSP" | version 20 21
			{
				int iLighting = 3;
				
				hMap.Seek(8 + LUMP_LIGHTING * LUMP_T_SIZE + 4, SEEK_SET);
				hMap.ReadInt32(iBuf);
				
				if(iBuf > 0) iLighting -= 1;
				
				hMap.Seek(8 + LUMP_LIGHTING_HDR * LUMP_T_SIZE + 4, SEEK_SET);
				hMap.ReadInt32(iBuf);
				
				if(iBuf > 0) iLighting -= 2;
				
				char sBuf[PLATFORM_MAX_PATH];
				
				FormatEx(sBuf, sizeof sBuf, "%d%s", iLighting, sMap[6]);
				
				g_hMapsList.PushString(sBuf);
			}
			
			delete hMap;
		}
	}
}