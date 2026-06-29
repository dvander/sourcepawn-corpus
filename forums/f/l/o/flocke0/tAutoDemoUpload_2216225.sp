#pragma semicolon 1
#include <sourcemod>
#include <tEasyFTP>
#undef REQUIRE_EXTENSIONS
#include <bzip2>

#define VERSION 		"0.0.5"

new Handle:g_hCvarEnabled = INVALID_HANDLE;
new bool:g_bEnabled = false;

new Handle:g_hCvarBzip = INVALID_HANDLE;
new g_iBzip2 = 9;

new Handle:g_hCvarFtpTarget = INVALID_HANDLE;
new String:g_sFtpTarget[255];

new Handle:g_hCvarLocation = INVALID_HANDLE;
new String:g_sLocation[255];

new Handle:g_hTvName = INVALID_HANDLE;
new String:g_sTvName[255];

new Handle:g_hCvarDelete = INVALID_HANDLE;
new bool:g_bDelete = false;

new String:g_sDemoPath[PLATFORM_MAX_PATH];
new bool:g_bRecording = false;



public Plugin:myinfo =
{
	name 		= "tAutoDemoUpload",
	author 		= "flobbo (Credits to Thrawn)",
	description = "Uploads demo files to a remote ftp server",
	version 	= VERSION,
};

public String_ToLower(const String:input[], String:output[], size)
{
        size--;

        new x=0;
        while (input[x] != '\0' || x < size) {
                
                if (IsCharUpper(input[x])) {
                        output[x] = CharToLower(input[x]);
                }
                else {
                        output[x] = input[x];
                }
                
                x++;
        }

        output[x] = '\0';
}

public File_GetBaseName(const String:path[], String:buffer[], size)
{       
        if (path[0] == '\0') {
                buffer[0] = '\0';
                return;
        }
        
        new pos_start = FindCharInString(path, '/', true);
        
        if (pos_start == -1) {
                pos_start = FindCharInString(path, '\\', true);
        }
        
        pos_start++;
        
        strcopy(buffer, size, path[pos_start]);
}

public OnPluginStart() {
	CreateConVar("sm_tautodemoupload_version", VERSION, "Uploads demo files to a remote ftp server", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_hCvarEnabled = CreateConVar("sm_tautodemoupload_enable", "1", "Automatically upload demos when finished recording.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(g_hCvarEnabled, Cvar_Changed);

	g_hCvarBzip = CreateConVar("sm_tautodemoupload_bzip2", "9", "Compression level. If set > 0 demos will be compressed before uploading. (Requires bzip2 extension.)", FCVAR_PLUGIN, true, 0.0, true, 9.0);
	HookConVarChange(g_hCvarBzip, Cvar_Changed);

	g_hCvarDelete = CreateConVar("sm_tautodemoupload_delete", "0", "Delete the demo (and the bz2) if upload was successful.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookConVarChange(g_hCvarDelete, Cvar_Changed);
	
	g_hCvarLocation = CreateConVar("sm_tautodemoupload_location", "", "Specify the Location to be shown on successful demo upload", FCVAR_PLUGIN);
	HookConVarChange(g_hCvarLocation, Cvar_Changed);

	g_hCvarFtpTarget = CreateConVar("sm_tautodemoupload_ftptarget", "demos", "The ftp target to use for uploads.", FCVAR_PLUGIN);
	HookConVarChange(g_hCvarFtpTarget, Cvar_Changed);

	g_hTvName = FindConVar("tv_name");
	HookConVarChange(g_hTvName, Cvar_Changed);

	AddCommandListener(CommandListener_Record, "tv_record");
	AddCommandListener(CommandListener_StopRecord, "tv_stoprecord");
}

public OnConfigsExecuted() {
	g_bEnabled = GetConVarBool(g_hCvarEnabled);
	g_iBzip2 = GetConVarBool(g_hCvarBzip);
	g_bDelete = GetConVarBool(g_hCvarDelete);

	GetConVarString(g_hCvarFtpTarget, g_sFtpTarget, sizeof(g_sFtpTarget));
	GetConVarString(g_hCvarLocation, g_sLocation, sizeof(g_sLocation));
	GetConVarString(g_hTvName, g_sTvName, sizeof(g_sTvName));
}

public Cvar_Changed(Handle:convar, const String:oldValue[], const String:newValue[]) {
	OnConfigsExecuted();
}


public OnMapStart() {
	if(GetConVarValueInt("tv_enable") != 1) {
		SetFailState("SourceTV System is disabled. You don't need this plugin.");
		return;
	}

	g_bRecording = false;
}

public Action:CommandListener_Record(client, const String:command[], argc) {
	if(!g_bEnabled)return;
	if(g_bRecording)return;

	GetCmdArg(1, g_sDemoPath, sizeof(g_sDemoPath));
	
	String_ToLower(g_sDemoPath, g_sDemoPath, sizeof(g_sDemoPath));
	
	if(!StrEqual(g_sDemoPath, "")) {
		g_bRecording = true;
	}

	// Append missing .dem
	if(strlen(g_sDemoPath) < 4 || strncmp(g_sDemoPath[strlen(g_sDemoPath)-4], ".dem", 4, false) != 0) {
		Format(g_sDemoPath, sizeof(g_sDemoPath), "%s.dem", g_sDemoPath);
	}
}

public Action:CommandListener_StopRecord(client, const String:command[], argc) {
	if(!g_bEnabled)return;
	if(g_bRecording) {
		new Handle:hDataPack = CreateDataPack();
		CreateDataTimer(5.0, Timer_UploadDemo, hDataPack);
		WritePackString(hDataPack, g_sDemoPath);

		Format(g_sDemoPath, sizeof(g_sDemoPath), "");
	}

	g_bRecording = false;
}

public Action:Timer_UploadDemo(Handle:timer, Handle:hDataPack) {
	ResetPack(hDataPack);

	decl String:sDemoPath[PLATFORM_MAX_PATH];
	ReadPackString(hDataPack, sDemoPath, sizeof(sDemoPath));

	if(g_iBzip2 > 0 && g_iBzip2 < 10 && LibraryExists("bzip2")) {
		decl String:sBzipPath[PLATFORM_MAX_PATH];
		Format(sBzipPath, sizeof(sBzipPath), "%s.bz2", sDemoPath);
		BZ2_CompressFile(sDemoPath, sBzipPath, g_iBzip2, CompressionComplete);
	} else {
		EasyFTP_UploadFile(g_sFtpTarget, sDemoPath, "/", UploadComplete);
	}
}

public CompressionComplete(BZ_Error:iError, String:inFile[], String:outFile[], any:data) {
	if(iError == BZ_OK) {
		LogMessage("%s compressed to %s", inFile, outFile);
		EasyFTP_UploadFile(g_sFtpTarget, outFile, "/", UploadComplete);
	} else {
		LogBZ2Error(iError);
	}
}

public UploadComplete(const String:sTarget[], const String:sLocalFile[], const String:sRemoteFile[], iErrorCode, any:data) {
	if(iErrorCode == 0 && g_bDelete) {
		DeleteFile(sLocalFile);
		if(StrEqual(sLocalFile[strlen(sLocalFile)-4], ".bz2")) {
			new String:sLocalNoCompressFile[PLATFORM_MAX_PATH];
			strcopy(sLocalNoCompressFile, strlen(sLocalFile)-3, sLocalFile);
			DeleteFile(sLocalNoCompressFile);
		}
	}

	for(new client = 1; client <= MaxClients; client++) {
		if(IsClientInGame(client) && GetAdminFlag(GetUserAdmin(client), Admin_Reservation)) {
			if(iErrorCode == 0) {
				if(StrEqual(g_sLocation, ""))
				{
					decl String:buffer[512];
					Format(buffer, sizeof(buffer), "[%s] Demo uploaded successfully", g_sTvName);
					PrintToChat(client, buffer);
				}
				else
				{
					decl String:buffer[512];
					decl String:filename[512];
					Format(buffer, sizeof(buffer), "[%s] Demo uploaded successfully. It can be downloaded here: %s", g_sTvName, g_sLocation);
					File_GetBaseName(sLocalFile, filename, sizeof(filename));
					ReplaceString(buffer, sizeof(buffer)+sizeof(filename), "{FILENAME}", filename);
					PrintToChat(client, buffer);
				}
			} else {
					decl String:buffer[512];
					Format(buffer, sizeof(buffer), "[%s] Failed uploading demo file. Check the server log files.", g_sTvName);
					PrintToChat(client, buffer);
			}
		}
	}
}

public GetConVarValueInt(const String:sConVar[]) {
	new Handle:hConVar = FindConVar(sConVar);
	new iResult = GetConVarInt(hConVar);
	CloseHandle(hConVar);
	return iResult;
}