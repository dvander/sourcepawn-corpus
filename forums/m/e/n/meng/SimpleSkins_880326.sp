#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "2.4"

new Handle:g_CVarEnabled;
new Handle:g_CVarAdminOnly;
new Handle:g_CVarSkinBots;
new Handle:g_CVarCTSkin;
new Handle:g_CVarTSkin;
new String:g_sCTSkin[256];
new String:g_sTSkin[256];
new bool:g_bSkinCT;
new bool:g_bSkinT;
new Handle:g_CVarAdmFlag;
new g_AdmFlag;

public Plugin:myinfo = {

	name = "SimpleSkins",
	author = "meng",
	version = PLUGIN_VERSION,
	description = "Simple Skin Changer",
	url = "http://www.sourcemod.net"
};

public OnPluginStart() {

	CreateConVar("simplecustomskins_version", PLUGIN_VERSION, "simplecustomskins Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_CVarEnabled = CreateConVar("sm_ss_enabled", "1", "<1/0> Set to 1 to enable plugin.");
	g_CVarAdminOnly = CreateConVar("sm_ss_adminonly", "0", "<1/0> Set to 1 to apply skins to admins only.");
	g_CVarSkinBots = CreateConVar("sm_ss_skinbots", "1", "<1/0> Set to 1 to apply skins to bots.");
	g_CVarCTSkin = CreateConVar("sm_ss_ctskin", "off", "The custom ct model path relative to the cstrike directory. Example - models/player/mymodel/ct_urban.mdl");
	g_CVarTSkin = CreateConVar("sm_ss_tskin", "off", "The custom t model path.");
	g_CVarAdmFlag = CreateConVar("sm_ss_adminflag", "s", "Flag required if admin only is enabled.");

	g_AdmFlag = ADMFLAG_CUSTOM5;
	HookConVarChange(g_CVarAdmFlag, CVarChange);

	AutoExecConfig(true, "simpleskins");

	HookEvent("player_spawn", EventPlayerSpawn);
}

public CVarChange(Handle:convar, const String:oldValue[], const String:newValue[]) {

	g_AdmFlag = ReadFlagString(newValue);
}

public OnConfigsExecuted() {

	decl String:sBuffer[256];
	GetConVarString(g_CVarCTSkin, sBuffer, sizeof(sBuffer));
	if (!StrEqual(sBuffer, "off", false)) {
		PrecacheModel(sBuffer);
		Format(g_sCTSkin, sizeof(g_sCTSkin), sBuffer);
		AddDLs(sBuffer);
		Format(sBuffer, sizeof(sBuffer), "materials/%s", g_sCTSkin);
		AddDLs(sBuffer);
		g_bSkinCT = true;
	}
	else
		g_bSkinCT = false;
	GetConVarString(g_CVarTSkin, sBuffer, sizeof(sBuffer));
	if (!StrEqual(sBuffer, "off", false)) {
		PrecacheModel(sBuffer);
		Format(g_sTSkin, sizeof(g_sTSkin), sBuffer);
		AddDLs(sBuffer);
		Format(sBuffer, sizeof(sBuffer), "materials/%s", g_sTSkin);
		AddDLs(sBuffer);
		g_bSkinT = true;
	}
	else
		g_bSkinT = false;
}

AddDLs(String:path[]) {

	new len = strlen(path);
	for (new i = len; i >= 0; i--) {
		if (path[i] != '/')
			path[i] = '\0';
		else {
			path[i] = '\0';
			break;
		}
	}
	TrimString(path);
	if (DirExists(path)) {
		new Handle:dir = OpenDirectory(path);
		new FileType:type;
		decl String:file[256];
		while (ReadDirEntry(dir, file, sizeof(file), type)) {
			if (type == FileType_File) {
				Format(file, sizeof(file), "%s/%s", path, file);
				AddFileToDownloadsTable(file);
			}
		}
		CloseHandle(dir);
	}
	else
		LogError("Directory %s does not exist.", path);
}

public EventPlayerSpawn(Handle:event,const String:name[],bool:dontBroadcast) {

	if (GetConVarInt(g_CVarEnabled)) {
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if (!IsFakeClient(client)) {
			if (GetConVarInt(g_CVarAdminOnly)) {
				if (GetUserFlagBits(client) & g_AdmFlag)
					SetModel(client);
				return;
			}
			SetModel(client);
			return;
		}
		if (GetConVarInt(g_CVarSkinBots))
			SetModel(client);
	}
}

SetModel(client) {

	new team = GetClientTeam(client);
	if ((team == 3) && g_bSkinCT)
		SetEntityModel(client, g_sCTSkin);
	else if ((team == 2) && g_bSkinT)
		SetEntityModel(client, g_sTSkin);
}