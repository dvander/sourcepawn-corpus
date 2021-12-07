#pragma semicolon true
#include <profiler>

public Plugin:myinfo =
{
	name = "sourcemod.xml generator",
	author = "MCPAN (mcpan@foxmail.com)",
	version = "1.1.0",
	url = "https://forums.alliedmods.net/member.php?u=73370"
}

#define	MAX_WIDTH 28
#define WIDTH MAX_WIDTH - 4

#define SPACE_CHAR	' '
#define SPACE_X4	"    "
#define SPACE_X8	"        "
#define SPACE_X12	"            "
#define SPACE_X16	"                "
#define SPACE_X28	"                            "

#define COMMENT_PARAM		"@param"
#define COMMENT_RETURN		"@return"
#define COMMENT_NORETURN	"@noreturn"
#define COMMENT_ERROR		"@error"

#define PATH_INCLUDE	"addons/sourcemod/scripting/include"
#define FILE_SOURCEMOD	"addons/sourcemod/plugins/sourcemod.xml"
#define FILE_FUNCTIONS	"addons/sourcemod/plugins/all_function.sp"
#define FILE_DEFINES	"addons/sourcemod/plugins/all_define.sp"

new Handle:g_FuncTrie;
new Handle:g_FuncArray;
new Handle:g_DefineArray;
new Handle:g_FileSourcemod;

public OnPluginStart()
{
	RegServerCmd("test", Cmd_Start);
}

public Action:Cmd_Start(argc)
{
	new Handle:prof = CreateProfiler();
	StartProfiling(prof);
	
	new size;
	decl String:buffer[PLATFORM_MAX_PATH];
	new Handle:fileArray = CreateArray(ByteCountToCells(PLATFORM_MAX_PATH));
	
	g_FuncTrie = CreateTrie();
	g_FuncArray = CreateArray(ByteCountToCells(64));
	g_DefineArray = CreateArray(ByteCountToCells(64));
	
	if ((size = ReadDirFileList(fileArray, PATH_INCLUDE, "inc")))
	{
		for (new i; i < size; i++)
		{
			GetArrayString(fileArray, i, buffer, sizeof(buffer));
			ReadIncludeFile(buffer, i);
		}
	}
	
	SortADTArrayCustom(g_FuncArray, SortFuncADTArray);
	SortADTArrayCustom(g_DefineArray, SortFuncADTArray);
	
	new Handle:file = OpenFile(FILE_FUNCTIONS, "wb");
	g_FileSourcemod = OpenFile(FILE_SOURCEMOD, "wb");
	
	WriteFileLine(g_FileSourcemod, "<?xml version=\"1.0\" encoding=\"Windows-1252\" ?>");
	WriteFileLine(g_FileSourcemod, "<NotepadPlus>");
	WriteFileLine(g_FileSourcemod, "%s<AutoComplete language=\"sourcemod\">", SPACE_X4);
	
	if ((size = GetArraySize(g_FuncArray)))
	{
		new value;
		decl String:funcname[64];
		for (new i; i < size; i++)
		{
			GetArrayString(g_FuncArray, i, funcname, sizeof(funcname));
			GetTrieValue(g_FuncTrie, funcname, value);
			GetArrayString(fileArray, value, buffer, sizeof(buffer));
			ReadIncludeFile(buffer, _, funcname);
			WriteFileLine(file, funcname);
		}
	}
	
	WriteFileLine(g_FileSourcemod, "%s</AutoComplete>", SPACE_X4);
	WriteFileLine(g_FileSourcemod, "</NotepadPlus>");
	
	CloseHandle(file);
	CloseHandle(fileArray);
	CloseHandle(g_FuncTrie);
	CloseHandle(g_FuncArray);
	CloseHandle(g_FileSourcemod);
	
	file = OpenFile(FILE_DEFINES, "wb");
	if ((size = GetArraySize(g_DefineArray)))
	{
		for (new i; i < size; i++)
		{
			GetArrayString(g_DefineArray, i, buffer, sizeof(buffer));
			WriteFileLine(file, buffer);
		}
	}
	
	CloseHandle(file);
	CloseHandle(g_DefineArray);
	
	StopProfiling(prof);
	PrintToServer("\n\t\t\t\tDone. time used %fs", GetProfilerTime(prof));
	CloseHandle(prof);
	
	return Plugin_Handled;
}

ReadIncludeFile(String:filepath[], fileArrayIdx=-1, String:search[]="")
{
	new Handle:file;
	if ((file = OpenFile(filepath, "rb")) == INVALID_HANDLE)
	{
		LogError("Open file faild '%s'", filepath);
		return;
	}
	
	new value, i;
	new bool:comment_buffer;
	new bool:found_comment;
	new bool:found_params;
	new bool:found_return;
	new bool:found_error;
	new bool:found_func;
	
	decl String:temp[512];
	decl String:buffer[512];
	decl String:funcprefix[7];
	decl String:func_tag[32];
	decl String:funcname[64];
	decl String:funcparam[32];
	
	new Handle:array_param = CreateArray(ByteCountToCells(512));
	new Handle:array_return = CreateArray(ByteCountToCells(512));
	new Handle:array_error = CreateArray(ByteCountToCells(512));
	new Handle:array_note = CreateArray(ByteCountToCells(512));
	
	while (ReadFileLine(file, buffer, sizeof(buffer)))
	{
		if (!ReadString(buffer, sizeof(buffer), found_comment))
		{
			if (found_comment)
			{
				found_params = false;
				found_return = false;
				found_error = false;
				ClearArray(array_param);
				ClearArray(array_return);
				ClearArray(array_error);
				ClearArray(array_note);
			}
			continue;
		}
		
		if (found_comment)
		{
			if (!search[0])
			{
				continue;
			}
			
			if ((value = FindCharInString(buffer, '*')) != -1)
			{
				strcopy(buffer, sizeof(buffer), buffer[++value]);
			}
			
			TrimString(buffer);
			
			if (!buffer[0])
			{
				continue;
			}
			
			if (StrContains(buffer, COMMENT_PARAM) == -1 &&
				StrContains(buffer, COMMENT_RETURN) == -1 &&
				StrContains(buffer, COMMENT_NORETURN) == -1 &&
				StrContains(buffer, COMMENT_ERROR) == -1)
			{
				if (found_params)
				{
					Format(temp, sizeof(temp), "%s%s", SPACE_X28, buffer);
					PushArrayString(array_param, temp);
				}
				else if (found_return)
				{
					Format(temp, sizeof(temp), "%s%s", SPACE_X4, buffer);
					PushArrayString(array_return, temp);
				}
				else if (found_error)
				{
					Format(temp, sizeof(temp), "%s%s", SPACE_X4, buffer);
					PushArrayString(array_error, temp);
				}
				else
				{
					ReplaceString(buffer, sizeof(buffer), "@note", "");
					ReplaceString(buffer, sizeof(buffer), "@brief", "");
					
					TrimString(buffer);
					Format(temp, sizeof(temp), "%s%s", SPACE_X4, buffer);
					PushArrayString(array_note, temp);
				}
			}
			else if ((value = StrContains(buffer, COMMENT_PARAM)) != -1)
			{
				found_params = true;
				found_return = false;
				found_error = false;
				strcopy(buffer, sizeof(buffer), buffer[value+6]);
				TrimString(buffer);
				
				if (buffer[0] && (value = FindCharInString(buffer, SPACE_CHAR)) != -1)
				{
					strcopy(funcparam, value+1, buffer);
					strcopy(buffer, sizeof(buffer), buffer[value]);
					TrimString(buffer);
					
					if ((value = WIDTH - value) > 0)
					{
						for (i = 0; i < value; i++)
						{
							temp[i] = SPACE_CHAR;
						}
						temp[value] = 0;
					}
					else
					{
						LogMessage("need space, set MAX_WIDTH >= %d", MAX_WIDTH - value);
					}
					
					Format(temp, sizeof(temp), "%s%s%s%s", SPACE_X4, funcparam, value > 0 ? temp : SPACE_X4, buffer);
					PushArrayString(array_param, temp);
				}
			}
			else if ((value = StrContains(buffer, COMMENT_RETURN)) != -1 || StrContains(buffer, COMMENT_NORETURN) != -1)
			{
				found_params = false;
				found_return = true;
				found_error = false;
				
				if (StrContains(buffer, COMMENT_NORETURN) != -1)
				{
					found_return = false;
					continue;
				}
				
				strcopy(buffer, sizeof(buffer), buffer[value+7]);
				TrimString(buffer);
				Format(temp, sizeof(temp), "%s%s", SPACE_X4, buffer);
				PushArrayString(array_return, temp);
			}
			else if ((value = StrContains(buffer, COMMENT_ERROR)) != -1)
			{
				found_params = false;
				found_return = false;
				found_error = true;
				strcopy(buffer, sizeof(buffer), buffer[value+6]);
				TrimString(buffer);
				Format(temp, sizeof(temp), "%s%s", SPACE_X4, buffer);
				PushArrayString(array_error, temp);
			}
			else
			{
				LogMessage(buffer);
			}
		}
		else if (StrContains(buffer, "#pragma deprecated") != -1 && ReadFileLine(file, buffer, sizeof(buffer)))
		{
			strcopy(funcprefix, sizeof(funcprefix), buffer);
			TrimString(funcprefix);
			
			do
			{
				if (StrEqual(funcprefix, "stock") && buffer[0] == '}' ||
					!StrEqual(funcprefix, "stock") && FindCharInString(buffer, ')') != -1)
				{
					break;
				}
			}
			while (ReadFileLine(file, buffer, sizeof(buffer)));
		}
		else
		{
			if ((value = StrContains(buffer, "#define ")) != -1)
			{
				if (search[0] ||
					StrContains(buffer, "_included") != -1 ||
					FindCharInString(buffer, '(') != -1 ||
					FindCharInString(buffer, '[') != -1)
				{
					continue;
				}
				
				strcopy(buffer, sizeof(buffer), buffer[value+7]);
				TrimString(buffer);
				
				if ((value = FindCharInString(buffer, SPACE_CHAR)) != -1)
				{
					strcopy(buffer, ++value, buffer);
					TrimString(buffer);
				}
				
				if (IsValidString(buffer) && FindStringInArray(g_DefineArray, buffer) == -1)
				{
					PushArrayString(g_DefineArray, buffer);
				}
			}
			else if ((value = StrContains(buffer, "enum")) != -1)
			{
				if (search[0])
				{
					continue;
				}
				
				strcopy(buffer, sizeof(buffer), buffer[value+4]);
				TrimString(buffer);
				
				if (value)
				{
					if (IsValidString(buffer) && FindStringInArray(g_DefineArray, buffer) == -1)
					{
						PushArrayString(g_DefineArray, buffer);
					}
					continue;
				}
				
				if ((value = FindCharInString(buffer, '{')) != -1)
				{
					strcopy(temp, ++value, buffer);
					strcopy(buffer, sizeof(buffer), buffer[value]);
					TrimString(temp);
					TrimString(buffer);
					
					if (WriteDefines(g_DefineArray, buffer, sizeof(buffer), FindCharInString(buffer, '}')))
					{
						while (ReadFileLine(file, buffer, sizeof(buffer)))
						{
							if (!WriteDefines(g_DefineArray, buffer, sizeof(buffer), FindCharInString(buffer, '}')))
							{
								break;
							}
						}
					}
				}
				else if (IsValidString(buffer) && FindStringInArray(g_DefineArray, buffer) == -1)
				{
					PushArrayString(g_DefineArray, buffer);
					
					while (ReadFileLine(file, buffer, sizeof(buffer)))
					{
						if (!ReadString(buffer, sizeof(buffer), found_comment, comment_buffer) || comment_buffer)
						{
							continue;
						}
						
						if ((value = FindCharInString(buffer, '{')) != -1)
						{
							strcopy(temp, ++value, buffer);
							strcopy(buffer, sizeof(buffer), buffer[value]);
							TrimString(temp);
							TrimString(buffer);
							
							if (WriteDefines(g_DefineArray, buffer, sizeof(buffer), FindCharInString(buffer, '}')))
							{
								while (ReadFileLine(file, buffer, sizeof(buffer)))
								{
									if (!ReadString(buffer, sizeof(buffer), found_comment, comment_buffer) || comment_buffer)
									{
										continue;
									}
									
									if (!WriteDefines(g_DefineArray, buffer, sizeof(buffer), FindCharInString(buffer, '}')))
									{
										break;
									}
								}
							}
							break;
						}
					}
				}
			}
			else
			{
				strcopy(funcprefix, sizeof(funcprefix), buffer);
				TrimString(funcprefix);
				
				found_func = false;
				if (StrEqual(funcprefix, "forwar"))
				{
					found_func = true;
					strcopy(buffer, sizeof(buffer), buffer[8]);
				}
				else if (StrEqual(funcprefix, "native"))
				{
					found_func = true;
					strcopy(buffer, sizeof(buffer), buffer[7]);
				}
				else if (StrEqual(funcprefix, "stock"))
				{
					found_func = true;
					strcopy(buffer, sizeof(buffer), buffer[6]);
				}
				
				if (found_func && ReadFuncString(buffer, func_tag, funcname) && IsValidString(funcname))
				{
					if (search[0])
					{
						if (StrEqual(funcname, search))
						{
							WriteFileLine(g_FileSourcemod, "%s<KeyWord name=\"%s\" func=\"yes\">", SPACE_X8, funcname);
							WriteFileLine(g_FileSourcemod, "%s<Overload retVal=\"%s\" descr=\"", SPACE_X12, func_tag[0] ? func_tag : "void");
							
							if ((value = GetArraySize(array_param)))
							{
								WriteFileLine(g_FileSourcemod, "Params:");
								for (i = 0; i < value; i++)
								{
									temp[0] = 0;
									GetArrayString(array_param, i, temp, sizeof(temp));
									WriteFileLine(g_FileSourcemod, temp);
								}
							}
							if ((value = GetArraySize(array_note)))
							{
								WriteFileLine(g_FileSourcemod, "Notes:");
								for (i = 0; i < value; i++)
								{
									temp[0] = 0;
									GetArrayString(array_note, i, temp, sizeof(temp));
									WriteFileLine(g_FileSourcemod, temp);
								}
							}
							if ((value = GetArraySize(array_error)))
							{
								WriteFileLine(g_FileSourcemod, "Error:");
								for (i = 0; i < value; i++)
								{
									temp[0] = 0;
									GetArrayString(array_error, i, temp, sizeof(temp));
									WriteFileLine(g_FileSourcemod, temp);
								}
							}
							if ((value = GetArraySize(array_return)))
							{
								WriteFileLine(g_FileSourcemod, "Return:");
								for (i = 0; i < value; i++)
								{
									temp[0] = 0;
									GetArrayString(array_return, i, temp, sizeof(temp));
									WriteFileLine(g_FileSourcemod, temp);
								}
							}
							
							WriteFileLine(g_FileSourcemod, "\">");
							
							if (buffer[0] == '(')
							{
								buffer[0] = SPACE_CHAR;
							}
							
							if (WriteFuncParams(g_FileSourcemod, buffer, sizeof(buffer), FindCharInString(buffer, ')')))
							{
								while (ReadFileLine(file, buffer, sizeof(buffer)))
								{
									if (!WriteFuncParams(g_FileSourcemod, buffer, sizeof(buffer), FindCharInString(buffer, ')')))
									{
										break;
									}
								}
							}
							
							WriteFileLine(g_FileSourcemod, "%s</Overload>", SPACE_X12);
							WriteFileLine(g_FileSourcemod, "%s</KeyWord>", SPACE_X8);
						}
						
						ClearArray(array_param);
						ClearArray(array_return);
						ClearArray(array_error);
						ClearArray(array_note);
					}
					else if (FindStringInArray(g_FuncArray, funcname) == -1)
					{
						PushArrayString(g_FuncArray, funcname);
						SetTrieValue(g_FuncTrie, funcname, fileArrayIdx);
					}
				}
			}
		}
	}
	
	CloseHandle(array_param);
	CloseHandle(array_return);
	CloseHandle(array_error);
	CloseHandle(array_note);
	CloseHandle(file);
}

ReadString(String:buffer[], maxlength, &bool:found_comment=false, &bool:comment_buffer=false)
{
	ReplaceString(buffer, maxlength, "\t", " ");
	ReplaceString(buffer, maxlength, "\"", "'");
	ReplaceString(buffer, maxlength, "%", "%%");
	
	new len;
	if ((len = strlen(buffer)) && !found_comment)
	{
		for (new i; i < len; i++)
		{
			if (buffer[i] == '/' && buffer[i+1] == '/')
			{
				buffer[i] = 0;
				break;
			}
		}
	}
	
	new bool:comment_start;
	new bool:comment_end;
	
	TrimString(buffer);
	if ((len = strlen(buffer)))
	{
		if (found_comment)
		{
			comment_buffer = true;
		}
		
		new pos;
		decl String:temp[512];
		if ((pos = StrContains(buffer, "/*")) != -1)
		{
			comment_start = true;
			strcopy(temp, sizeof(temp), buffer[pos+2]);
			buffer[pos] = 0;
			TrimString(buffer);
			
			if ((pos = StrContains(temp, "*/")) != -1)
			{
				comment_end = true;
				strcopy(temp, sizeof(temp), temp[pos+2]);
				TrimString(temp);
			}
			else
			{
				temp[0] = 0;
			}
			
			if (strlen(buffer) || strlen(temp))
			{
				comment_buffer = false;
				Format(buffer, maxlength, "%s%s", buffer, temp);
			}
			temp[0] = 0;
		}
		else if ((pos = StrContains(buffer, "*/")) != -1)
		{
			comment_end = true;
			comment_buffer = false;
			strcopy(buffer, maxlength, buffer[pos+2]);
		}
		
		TrimString(buffer);
		len = strlen(buffer);
	}
	
	if (comment_start && comment_end)
	{
		comment_start = false;
		comment_end = false;
	}
	
	if (comment_start)
	{
		found_comment = comment_start;
	}
	else if (comment_end)
	{
		found_comment = comment_start;
	}
	
	return len;
}

bool:ReadFuncString(String:buffer[], String:func_tag[], String:funcname[])
{
	func_tag[0] = 0;
	funcname[0] = 0;
	
	new pos, len;
	if ((len = strlen(buffer)) && (pos = FindCharInString(buffer, '(')) != -1)
	{
		strcopy(funcname, pos+1, buffer);
		strcopy(buffer, len, buffer[pos]);
		
		if (StrEqual(funcname, "VerifyCoreVersion") ||
			StrEqual(funcname, "operator%%") ||
			StrContains(funcname, ":operator") != -1)
		{
			return false;
		}
		
		if ((pos = FindCharInString(funcname, ':')) != -1)
		{
			strcopy(func_tag, ++pos, funcname);
			strcopy(funcname, len, funcname[pos]);
		}
		
		return true;
	}
	
	return false;
}

bool:WriteFuncParams(Handle:handle, String:buffer[], maxlength, pos)
{
	if (pos != -1)
	{
		buffer[pos] = 0;
	}
	
	ReplaceString(buffer, maxlength, "\t", " ");
	ReplaceString(buffer, maxlength, "\"", "'");
	ReplaceString(buffer, maxlength, "%", "%%");
	
	TrimString(buffer);
	if (buffer[0])
	{
		decl String:funcparams[32][256];
		new count = ExplodeString(buffer, ",", funcparams, sizeof(funcparams), sizeof(funcparams[]));
		for (new i; i < count; i++)
		{
			TrimString(funcparams[i]);
			if (funcparams[i][0])
			{
				WriteFileLine(handle, "%s<Param name=\"%s\"/>", SPACE_X16, funcparams[i]);
				funcparams[i][0] = 0;
			}
		}
	}
	
	return pos == -1;
}

bool:WriteDefines(&Handle:handle, String:buffer[], maxlength, pos)
{
	if (pos != -1)
	{
		buffer[pos] = 0;
	}
	
	ReplaceString(buffer, maxlength, "\t", " ");
	ReplaceString(buffer, maxlength, "\"", "'");
	
	TrimString(buffer);
	if (buffer[0])
	{
		decl String:defines_temp[32][64];
		new pos2, value = ExplodeString(buffer, ",", defines_temp, sizeof(defines_temp), sizeof(defines_temp[]));
		for (new i; i < value; i++)
		{
			TrimString(defines_temp[i]);
			if (defines_temp[i][0])
			{
				if ((pos2 = FindCharInString(defines_temp[i], '=')) != -1)
				{
					defines_temp[i][pos2] = 0;
					TrimString(defines_temp[i]);
				}
				
				if (IsValidString(defines_temp[i]) && FindStringInArray(handle, defines_temp[i]) == -1)
				{
					PushArrayString(handle, defines_temp[i]);
				}
				
				defines_temp[i][0] = 0;
			}
		}
	}
	
	return pos == -1;
}

bool:IsValidString(String:buffer[])
{
	TrimString(buffer);
	return (buffer[0] &&
			FindCharInString(buffer, SPACE_CHAR) == -1 &&
			FindCharInString(buffer, '*') == -1 &&
			FindCharInString(buffer, '/') == -1 &&
			FindCharInString(buffer, ':') == -1 &&
			FindCharInString(buffer, '(') == -1 &&
			FindCharInString(buffer, '[') == -1 &&
			FindCharInString(buffer, ']') == -1 &&
			FindCharInString(buffer, ')') == -1 &&
			FindCharInString(buffer, '%') == -1);
}

public SortFuncADTArray(index1, index2, Handle:array, Handle:hndl)
{
	decl String:str1[64], String:str2[64];
	GetArrayString(array, index1, str1, sizeof(str1));
	GetArrayString(array, index2, str2, sizeof(str2));
	return strcmp(str1, str2, false);
}

stock ReadDirFileList(&Handle:fileArray, const String:dirPath[], const String:fileExt[]="")
{
	new Handle:dir;
	if ((dir = OpenDirectory(dirPath)) == INVALID_HANDLE)
	{
		LogError("Open dir faild '%s'", dirPath);
		return 0;
	}
	
	new FileType:fileType;
	decl String:buffer[PLATFORM_MAX_PATH];
	decl String:currentPath[PLATFORM_MAX_PATH];
	new Handle:pathArray = CreateArray(ByteCountToCells(PLATFORM_MAX_PATH));
	
	buffer[0] = 0;
	currentPath[0] = 0;
	
	while (ReadDirEntry(dir, buffer, sizeof(buffer), fileType)
		|| ReadSubDirEntry(dir, buffer, sizeof(buffer), fileType, pathArray, dirPath, currentPath))
	{
		switch (fileType)
		{
			case FileType_Directory:
			{
				if (!StrEqual(buffer, ".") && !StrEqual(buffer, ".."))
				{
					Format(buffer, sizeof(buffer), "%s/%s", currentPath, buffer);
					PushArrayString(pathArray, buffer);
				}
			}
			case FileType_File:
			{
				if (fileExt[0] && !CheckFileExt(buffer, fileExt))
				{
					continue;
				}
				
				Format(buffer, sizeof(buffer), "%s%s/%s", dirPath, currentPath, buffer);
				PushArrayString(fileArray, buffer);
			}
		}
	}
	
	CloseHandle(pathArray);
	if (dir != INVALID_HANDLE)
	{
		CloseHandle(dir);
	}
	
	return GetArraySize(fileArray);
}

stock bool:ReadSubDirEntry(&Handle:dir, String:buffer[], maxlength, &FileType:fileType, &Handle:pathArray, const String:dirPath[], String:currentPath[])
{
	if (!GetArraySize(pathArray))
	{
		return false;
	}
	
	GetArrayString(pathArray, 0, currentPath, maxlength);
	RemoveFromArray(pathArray, 0);
	
	CloseHandle(dir);
	dir = INVALID_HANDLE;
	
	Format(buffer, maxlength, "%s%s", dirPath, currentPath);
	if ((dir = OpenDirectory(buffer)) == INVALID_HANDLE)
	{
		LogError("Open sub dir faild '%s'", buffer);
		return false;
	}
	
	return ReadDirEntry(dir, buffer, maxlength, fileType);
}

stock bool:CheckFileExt(String:filename[], const String:extname[])
{
	new pos;
	if ((pos = FindCharInString(filename, '.', true)) == -1)
	{
		return false;
	}
	
	decl String:ext[32];
	strcopy(ext, sizeof(ext), filename[++pos]);
	return StrEqual(ext, extname, false);
}

