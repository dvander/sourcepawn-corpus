#pragma semicolon true

#include <sourcemod>

new Handle:cvarExecConfig;
new Handle:cvarExecConfigOnMap;

public OnPluginStart()
{
	RegServerCmd("sm_exec_config_file", ForceExecConfig);	
	
	cvarExecConfig = CreateConVar("sm_autoexec_config_on_load", "1", "Should SourceMod execute the config files after this plugin loads?", FCVAR_PLUGIN);
	cvarExecConfigOnMap = CreateConVar("am_autoexec_config_on_map_change", "1", "Should SourceMod execute the config files after a map is changed?", FCVAR_PLUGIN);
	
	AutoExecConfig(true, "sm.autoexec");
	
}

public OnAllPluginLoaded()
{
	if (GetConVarBool(cvarExecConfig))
		ForceExecConfig(0);
}
public OnMapStart()
{
	if (GetConVarBool(cvarExecConfigOnMap))
		ForceExecConfig(0);
}

public Action:ForceExecConfig(args)
{
	decl   String:filePath[512];
	decl   String:fileName[256];
	decl FileType:fileType;
	decl   Handle:fileHndl;
		
	if (args >= 1)
	{
		GetCmdArg(1, filePath, sizeof(filePath));
		
		fileHndl = OpenFile(filePath, "r");
			
		if (fileHndl != INVALID_HANDLE)
		{
			PrintToServer("[AUTOEXEC] Executing \"%s\"", filePath);
			ReadConfigFile(fileHndl);
			CloseHandle(fileHndl);
		}
		else
		{
			PrintToServer("[AUTOEXEC] Invalid file");
		}
	}
	else
	{
		new Handle:directory = OpenDirectory("./cfg/sourcemod");
	
		if (directory != INVALID_HANDLE)
		{
			while (ReadDirEntry(directory, fileName, sizeof(fileName), fileType))
			{
				if (fileType == FileType_File)
				{
					if ((StrContains(fileName, ".cfg") >= 0) && (StrContains(fileName, ".disable.") < 0) && !StrEqual(fileName, "sourcemod.cfg"))
					{
						Format(filePath, sizeof(filePath), "cfg/sourcemod/%s", fileName);
					
						fileHndl = OpenFile(filePath, "r");
					
						if (fileHndl != INVALID_HANDLE)
						{
							PrintToServer("[AUTOEXEC] Executing \"cfg/sourcemod/%s\"", fileName);
							ReadConfigFile(fileHndl);
							CloseHandle(fileHndl);
						}
					}
				}
			}
		
			CloseHandle(directory);
		}
	}
}

public ReadConfigFile(Handle:file)
{
	decl String:text[2048];
	
	new Handle:cvar = INVALID_HANDLE;
	new iter        = 0;
	new temp        = 0;
	new char        = ' ';
	new mama        = 0;
	new flag        = 0;
	
	if (file != INVALID_HANDLE)
	{
		while (!IsEndOfFile(file))
		{
			ReadFileLine(file, text, sizeof(text));	

			for (temp = 0; temp < 2048; ++temp)
			{
				if (text[temp] == '\n')
				{
					text[temp] = '\0';
					break;
				}
			}
			
			if (iter == -2)
			{
				while (!IsEndOfFile(file))
				{
					ReadFileLine(file, text, sizeof(text));
					
					for (temp = 0; temp < 2048; ++temp)
					{
						if (text[temp] == '*')
						{
							if (temp < 2047)
							{
								if (text[++temp] == '/')
								{
									iter = -1;
									break;
								}
							}
						}
					}
				}
			}
			
			for (iter = 0; (iter < 2048) && (text[iter]); ++iter)
			{
				if ((text[iter] == '/') && (iter < 2047))
				{
					if (text[iter + 1] == '*')
					{
						iter = -2;
						break;
					}
					else if (text[iter + 1] == '/')
					{
						iter = -3;		
						break;
					}
				}
					
				if ((iter < 2048) && (text[iter] > ' '))
					break;
			}
			
			if ((iter >= 0) && (iter < 2048))
			{
				temp = iter++;
				
				while (iter < 2048)
				{
					if (text[iter] <= ' ')
					{
						while (iter < 2048)	
						{
							if (text[iter] > ' ')
								break;
								
							iter++;
						}
						
						break;
					}
					
					if (text[iter] == '\n')
						iter = -4;
						
					iter++;
				}
				
				if ((iter != -4) && (iter < 2048))
				{
					char = text[--iter];
					text[iter] = '\0';
					
					cvar = FindConVar(text[temp]);
					
					if (cvar != INVALID_HANDLE)
					{
						for (mama = iter + 1; mama < 2048; ++mama)
						{
							if (text[mama] == '"')
							{
								flag = 1;
								mama++;
							
								while (mama < 2048)
								{
									if (text[mama] == '"')
									{
										if (mama > 0)
										{
											if (text[mama - 1] == '\\')
												continue;
										}
										
										text[mama] = '\0';
										break;
									}
								
									mama++;
								}
							}
							else 
							{
								if (text[mama] <= ' ')
									text[mama] = '\0';
							}
						}
						
						if (flag)
						{
							iter += 2;
							SetConVarString(cvar, text[iter]);
						}
						else
						{
							iter++;
							SetConVarString(cvar, text[iter]);
						}
						
						flag = 0;				
					}
					else
					{
						text[iter] = char;
						ServerCommand(text[temp]);
					}			
				}
			}
		}
	}
}