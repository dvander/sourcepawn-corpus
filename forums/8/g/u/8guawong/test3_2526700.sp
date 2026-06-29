BuildPhrases()
{
	decl String:imFile[PLATFORM_MAX_PATH];
	decl String:line[192];
	new i = 0;
	new totalLines = 0;
	
	BuildPath(Path_SM, imFile, sizeof(imFile), "configs/config.ini");
	
	new Handle:file = OpenFile(imFile, "rt");
	
	if(file != INVALID_HANDLE)
	{
		while (!IsEndOfFile(file))
		{
			if (!ReadFileLine(file, line, sizeof(line)))
			{
				break;
			}
			
			TrimString(line);
			if( strlen(line) > 0 )
			{
				FormatEx(g_Phrases[i],192, "%s", line);
				totalLines++;
			}
			
			i++;
			
			//check for max no. of entries
			if( i >= sizeof(g_Phrases) )
			{
				SetFailState("Attempted to add more than the maximum allowed phrases from file");
				break;
			}
		}
				
		CloseHandle(file);
	}
	else
	{
		SetFailState("[SM] no file found (configs/config.ini)");
	}
	
	return totalLines;
}