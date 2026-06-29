#include <sourcemod>
#include <sdktools>

public Plugin myinfo = 
{
	name = "TF2 Hidden Attribuites",
	author = "rafradek",
	description = "Enables the use of hidden dev attributes",
	version = "1.2",
	url = "https://forums.alliedmods.net/showthread.php?t=326853"
};

ConVar enabledCvar;

Handle getItemSchemaPrep;
Handle bInitAttributesPrep;
Handle readEncryptedKVFilePrep;
Handle deleteThisPrep;

Address pFileSystem;

bool wasLoaded;

public void OnPluginStart()
{
	enabledCvar = CreateConVar("sm_hiddenattribs_enabled", "1", "Should the hidden attributes be enabled");
	RegAdminCmd("sm_hiddenattribs_reload", Command_Reload, ADMFLAG_CONFIG, "Reloads configs. Only inserts new attributes");

	AutoExecConfig();

	Handle game_conf = LoadGameConfigFile("tf2.hiddenattribs");

	StartPrepSDKCall(SDKCall_Static);
	if (PrepSDKCall_SetFromConf(game_conf,SDKConf_Signature,"GetItemSchema")) {
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		getItemSchemaPrep = EndPrepSDKCall();
	}

	StartPrepSDKCall(SDKCall_Raw);
	if (PrepSDKCall_SetFromConf(game_conf,SDKConf_Signature,"CEconItemSchema::BInitAttributes")) {
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		bInitAttributesPrep = EndPrepSDKCall();
	}
	
	StartPrepSDKCall(SDKCall_Static);
	if (PrepSDKCall_SetFromConf(game_conf,SDKConf_Signature,"ReadEncryptedKVFile")) {
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		readEncryptedKVFilePrep = EndPrepSDKCall();
	}

	StartPrepSDKCall(SDKCall_Raw);
	if (PrepSDKCall_SetFromConf(game_conf,SDKConf_Signature,"KeyValues::deleteThis")) {
		deleteThisPrep = EndPrepSDKCall();
	}

	pFileSystem = GameConfGetAddress(game_conf, "addr_g_pFullFileSystem");
}

public void OnMapStart()
{
	if (!wasLoaded) {
		LoadAttributes();
	}
}

public Action Command_Reload(int client, int args)
{
	if (GetConVarBool(enabledCvar)) {
		ReplyToCommand(client, "[TF2 Hidden Attributes] Reloaded config files");
		LoadAttributes();
	}
	else
		ReplyToCommand(client, "[TF2 Hidden Attributes] Plugin not enabled");

	return Plugin_Handled;
}

public void LoadAttributes() {
	if (!GetConVarBool(enabledCvar))
		return;
	
	wasLoaded = true;
	char configDir[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, configDir, sizeof(configDir), "configs/tf2nativeattribs");

	if (DirExists(configDir,false)) {
		DirectoryListing list = OpenDirectory(configDir, false);
		FileType fileType;
		char filename[PLATFORM_MAX_PATH];

		while (list.GetNext(filename, sizeof(filename), fileType)) {
			if (fileType == FileType_File) {
				Format(filename, sizeof(filename), "%s/%s", configDir, filename);

				if (strncmp(filename[strlen(filename) - 4], ".txt", 4, false) != 0) {
					PrintToServer("%s%s%s","[TF2 Hidden Attributes] Attributes file ", filename, " does not have a txt extension. Attributes will not be loaded");
					continue;
				}

				//remove txt extension from filename
				filename[strlen(filename) - 4] = 0;

				//txt extension is added automatically by ReadEncryptedKVFilePrep
				Address pKV = SDKCall(readEncryptedKVFilePrep, pFileSystem, filename, 0, 0);

				if (pKV != Address_Null) {
					Address pItemSchema = SDKCall(getItemSchemaPrep);
					SDKCall(bInitAttributesPrep, pItemSchema, pKV, 0);

					//Just in case this is invalid on windows
					if (deleteThisPrep != INVALID_HANDLE)
						SDKCall(deleteThisPrep, pKV);
				}
				else
					PrintToServer("%s%s%s","[TF2 Hidden Attributes] Failed to load file ", filename, ". Attributes will not be loaded");
			}
		}
		
	}
}