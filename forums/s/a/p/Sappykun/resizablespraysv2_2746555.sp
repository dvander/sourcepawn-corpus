/*
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option)
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see http://www.gnu.org/licenses/.
 */

#include <sourcemod>
#include <sdktools>
#include <latedl>

#pragma newdecls required
#pragma semicolon 1

#define PLUGIN_NAME "Resizable Sprays"
#define PLUGIN_DESC "Extends default sprays to allow for scaling and spamming"
#define PLUGIN_AUTHOR "Sappykun"
#define PLUGIN_VERSION "2.0.0-RC5"
#define PLUGIN_URL "https://forums.alliedmods.net/showthread.php?t=332418"

// Normal sprays are 64 Hammer units tall
#define SPRAY_UNIT_DIMENSION_FLOAT 64.0

// TODO: move this to a separate file
char g_vmtTemplate[512] = "LightmappedGeneric\n\
{\n\
\t$basetexture \"resizablespraysv2/%s\"\n\
\t$decalscale %.4f\n\
\t$spriteorientation 3\n\
\t$spriteorigin \"[ 0.50 0.50 ]\"\n\
\t$vertexcolor 1\n\
\t$vertexalpha 1\n\
\t$translucent 1\n\
\t$decal 1\n\
\t$decalsecondpass 1\n\
\tProxies\n\
\t{\n\
\t\tPlayerLogo {}\n\
\t\tAnimatedTexture\n\
\t\t{\n\
\t\t\tanimatedtexturevar $basetexture\n\
\t\t\tanimatedtextureframenumvar $frame\n\
\t\t\tanimatedtextureframerate 5\n\
\t\t}\n\
\t}\n\
}";

enum struct Player {
	bool bSprayHasBeenProcessed;
	bool bIsReadyToSpray;
	int iSprayHeight;
	float fScale;
	float fLastSprayed;
	float fRealSprayLastPosition[3];
}

enum struct Spray {
	int iSprayer; // for sound emission
	int iClient;
	int iPrecache;
	int iEntity;
	int iHitbox;
	int iDecalType;
	int iSprayHeight;
	float fSprayTime; // when was this request made
	float fScaleReal; // The real scale factor based on spray dimensions + clamping
	float fPosition[3];
	char sMaterialName[64];
}

Player g_Players[MAXPLAYERS + 1];
ArrayList g_SprayQueue;

StringMap g_mapProcessedFiles;
bool g_bBuffer;

ConVar cv_bEnabled;
ConVar cv_sAdminFlags;
ConVar cv_fMaxSprayScale;
ConVar cv_fMaxSprayDistance;
ConVar cv_fDecalFrequency;
ConVar cv_fSprayTimeout;

char g_strLogFile[PLATFORM_MAX_PATH];

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	description = PLUGIN_DESC,
	author = PLUGIN_AUTHOR,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}

public void OnPluginStart()
{
	RegConsoleCmd("sm_spray", Command_Spray, "Places a repeatable, scalable version of your spray as a decal.");
	RegConsoleCmd("sm_bspray", Command_Spray, "Places a repeatable, scalable version of your spray as a BSP decal.");

	CreateConVar("rspr_version", PLUGIN_VERSION, "Resizable Sprays version. Don't touch this.", FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY);

	cv_bEnabled = CreateConVar("rspr_enabled", "1.0", "Enables the plugin.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cv_sAdminFlags = CreateConVar("rspr_adminflags", "b", "Admin flags required to bypass restrictions", FCVAR_NONE, false, 0.0, false, 0.0);
	cv_fMaxSprayDistance = CreateConVar("rspr_maxspraydistance", "128.0", "Max range for placing decals. 0 is infinite range", FCVAR_NOTIFY, true, 0.0, false);
	cv_fMaxSprayScale = CreateConVar("rspr_maxsprayscale", "2.0", "Maximum scale for sprays.", FCVAR_NOTIFY, true, 0.0, false, 0.0);
	cv_fDecalFrequency = CreateConVar("rspr_decalfrequency", "0.5", "Spray frequency for non-admins. 0 is no delay.", FCVAR_NOTIFY, true, 0.0, false);
	cv_fSprayTimeout = CreateConVar("rspr_spraytimeout", "10.0", "Max time to wait for clients to download spray files. 0 to wait forever.", FCVAR_NOTIFY, true, 0.0, false);

	AddTempEntHook("Player Decal", PlayerSprayReal);

	AutoExecConfig(true, "resizablesprays");
	LoadTranslations("common.phrases");

	char timebuffer[32];
	FormatTime(timebuffer, sizeof(timebuffer), "%F", GetTime());
	BuildPath(Path_SM, g_strLogFile, sizeof(g_strLogFile), "logs/rspr_%s.log", timebuffer);

	if (!DirExists("materials/resizablespraysv2", false))
		CreateDirectory("materials/resizablespraysv2", 511, false); // 511 decimal = 755 octal

	for (int c = 1; c <= MaxClients; c++)
		if (IsValidClient(c)) {
			OnClientPostAdminCheck(c);
		}
}

public void OnMapStart()
{
	g_mapProcessedFiles = new StringMap();
	g_SprayQueue = new ArrayList(sizeof(Spray));
}

public void OnDownloadSuccess(int iClient, char[] filename)
{
	if (iClient > 0) {
		LogToFile(g_strLogFile, "%N downloaded file '%s'", iClient, filename);
		return;
	}

	LogToFile(g_strLogFile, "All players downloaded file '%s'", filename);
	g_mapProcessedFiles.SetValue(filename, true);
}

public void OnDownloadFailure(int iClient, char[] filename)
{
	if (iClient > 0) {
		if (IsValidClient(iClient)) {
			LogToFile(g_strLogFile, "Client %N did not download file '%s'", iClient, filename);
		}
		return;
	}

	LogToFile(g_strLogFile, "Error adding '%s' to download queue", filename);
}

public void OnClientDisconnect(int client)
{
	ResetSprayInfo(client);
}

public void OnClientPostAdminCheck(int client)
{
	ResetSprayInfo(client);

	if (!cv_bEnabled.BoolValue)
		return;

	PrintToChat(client, "[SM] Preparing your spray...");
	CreateTimer(1.0, Timer_CheckIfSprayIsReady, client, TIMER_REPEAT);
}

public void ResetSprayInfo(int client)
{
	g_Players[client].bIsReadyToSpray = false;
	g_Players[client].bSprayHasBeenProcessed = false;
	g_Players[client].iSprayHeight = 0;
	g_Players[client].fScale = 1.0;
	g_Players[client].fLastSprayed = 0.0;
	g_Players[client].fRealSprayLastPosition[0] = -16384.0;
	g_Players[client].fRealSprayLastPosition[1] = -16384.0;
	g_Players[client].fRealSprayLastPosition[2] = -16384.0;
}

public Action Timer_CheckIfSprayIsReady(Handle timer, int client)
{
	bool bIsReadyVTF = false;

	char playerdecalfile[12];
	char vtfFilePath[PLATFORM_MAX_PATH];

	if (!IsValidClient(client))
		return Plugin_Continue;

	GetPlayerDecalFile(client, playerdecalfile, sizeof(playerdecalfile));
	Format(vtfFilePath, sizeof(vtfFilePath), "materials/resizablespraysv2/%s.vtf", playerdecalfile);

	if (StrEqual(playerdecalfile, "")) {
		PrintToChat(client, "[SM] You don't have a spray.");
		return Plugin_Stop;
	}

	g_mapProcessedFiles.GetValue(vtfFilePath, bIsReadyVTF);
	if (bIsReadyVTF && g_Players[client].bSprayHasBeenProcessed) {
		g_Players[client].bIsReadyToSpray = true;
		PrintToChat(client, "[SM] Your spray is ready!");
		return Plugin_Stop;
	} else {
		if (!g_Players[client].bSprayHasBeenProcessed)
			ForceDownloadPlayerSprayFile(client);
	}

	return Plugin_Continue;
}

public void ForceDownloadPlayerSprayFile(int client)
{
	int dimensions[2] = {0, 0};

	int buffer[4];
	int bytesRead;

	char playerdecalfile[12];
	char vtfFilepath[PLATFORM_MAX_PATH];
	char vtfCopypath[PLATFORM_MAX_PATH];

	GetPlayerDecalFile(client, playerdecalfile, sizeof(playerdecalfile));
	GetPlayerSprayFilePath(client, vtfFilepath, sizeof(vtfFilepath));

	Format(vtfCopypath, sizeof(vtfCopypath), "materials/resizablespraysv2/%s.vtf", playerdecalfile);

	if (!g_mapProcessedFiles.GetValue(vtfCopypath, g_bBuffer) || !g_Players[client].bSprayHasBeenProcessed) {
		Handle vtfFile = OpenFile(vtfFilepath, "r", false);

		if (vtfFile == INVALID_HANDLE) {
			//LogToFile(g_strLogFile, "ForceDownloadPlayerSprayFile: File %s returned an invalid handle.", vtfFilepath);
			return;
		}

		FileSeek(vtfFile, 16, SEEK_SET);
		ReadFile(vtfFile, dimensions, 2, 2);
		g_Players[client].iSprayHeight = dimensions[1];

		if (g_Players[client].iSprayHeight <= 0) {
			LogToFile(g_strLogFile, "%N's spray %s was %d px, this isn't right...", client, vtfFilepath, g_Players[client].iSprayHeight);
			return;
		}

		if (!FileExists(vtfCopypath, false)) {
			// Copy VTF filepath to materials/temp/_______.vtf
			Handle vtfCopy = OpenFile(vtfCopypath, "wb", false);

			FileSeek(vtfFile, 0, SEEK_SET);
			while (!IsEndOfFile(vtfFile)) {
				bytesRead = ReadFile(vtfFile, buffer, sizeof(buffer), 1);
				WriteFile(vtfCopy, buffer, bytesRead, 1);
			}

			CloseHandle(vtfCopy);
		}

		CloseHandle(vtfFile);

		if (!g_Players[client].bSprayHasBeenProcessed) {
			AddFileToDownloadsTable(vtfCopypath);
			AddLateDownload(vtfCopypath, false);
			g_mapProcessedFiles.SetValue(vtfCopypath, 0);
			LogToFile(g_strLogFile, "Adding late download %s", vtfCopypath);
			g_Players[client].bSprayHasBeenProcessed = true;
		}
	}
}

public Action PlayerSprayReal(const char[] szTempEntName, const int[] arrClients, int iClientCount, float flDelay) {
	int client = TE_ReadNum("m_nPlayer");

	if (IsValidClient(client))
		TE_ReadVector("m_vecOrigin", g_Players[client].fRealSprayLastPosition);
}

/*
	Handles the !spray and !bspray commands
	@param ID of client, will use their spray's unique filename
	@param number of args
*/
public Action Command_Spray(int client, int args)
{
	char arg0[64]; GetCmdArg(0, arg0, sizeof(arg0));
	char arg1[64]; GetCmdArg(1, arg1, sizeof(arg1));
	char arg2[64]; GetCmdArg(2, arg2, sizeof(arg2));

	Spray spray;
	spray.iSprayer = client;
	spray.iClient = client;

	if (!IsValidClient(client))
		return Plugin_Handled;

	if (!cv_bEnabled.BoolValue)
		return Plugin_Handled;

	if (GetGameTime() - g_Players[client].fLastSprayed < cv_fDecalFrequency.FloatValue && !IsAdmin(client))
		return Plugin_Handled;
	g_Players[client].fLastSprayed = GetGameTime();

	if (StrEqual(arg0, "sm_bspray") && IsAdmin(client))
		spray.iDecalType = 1;

	if (args > 0) {
		if (!IsAdmin(client) && (args > 1 || !StringToFloatEx(arg1, g_Players[client].fScale))) {
			ReplyToCommand(client, "Usage: %s [desired_scale]", arg0);
			return Plugin_Handled;
		}

		if (IsAdmin(client) && (args > 2 || !StringToFloatEx(arg1, g_Players[client].fScale))) {
			ReplyToCommand(client, "Usage: %s [desired_scale] [user]", arg0);
			return Plugin_Handled;
		}

		if (IsAdmin(client) && args == 2) {
			spray.iClient = FindTarget(client, arg2, true, true);
			if (spray.iClient == -1)
				return Plugin_Handled;

			if (!IsValidClient(spray.iClient)) {
				ReplyToCommand(client, "[SM] This client isn't in game yet! Please try again later.");
				return Plugin_Handled;
			}
		}
	}

	if (!g_Players[spray.iClient].bIsReadyToSpray) {
			ReplyToCommand(client, "[SM] We're still preparing this spray! Please try again later.");
			return Plugin_Handled;
		}

	spray.fScaleReal = GetRealSprayScale(spray.iClient, g_Players[client].fScale);

	CalculateSprayPosition(client, spray);

	if (spray.iEntity > -1) {
		LogToFile(g_strLogFile, "Command_Spray: %N is spraying %N's spray at %0.4f (%0.4f) scale, size %d", client, spray.iClient, g_Players[client].fScale, spray.fScaleReal, g_Players[client].iSprayHeight);
		int sprayIndex;
		if ((sprayIndex = WriteVMT(spray)) != -1)
			CreateTimer(0.0, Timer_PrecacheAndSprayDecal, sprayIndex, TIMER_REPEAT);

	} else {
		ReplyToCommand(client, "[SM] You are too far away from a valid surface to place a spray!");
	}

	return Plugin_Handled;
}

float GetRealSprayScale(int client, float scale)
{
	if (!IsAdmin(client) && scale > cv_fMaxSprayScale.FloatValue)
		scale = cv_fMaxSprayScale.FloatValue;

	if (FloatEqual(g_Players[client].fScale, 0.0, 0.0001)) {
		scale = 1.0;
	}

	// We shouldn't be here if iSprayHeight is 0
	return scale * SPRAY_UNIT_DIMENSION_FLOAT / float(g_Players[client].iSprayHeight);
}

/*
	Writes a VMT file to the server, then sends it to all available clients
	@param ID of client, will use their spray's unique filename
	@param scale of decal for generated material
	@param buffer for material name
*/
public int WriteVMT(Spray spray)
{
	char playerdecalfile[12];

	char data[512];
	char scaleString[16];
	char vmtFilename[128];

	GetPlayerDecalFile(spray.iClient, playerdecalfile, sizeof(playerdecalfile));

	Format(data, 512, g_vmtTemplate, playerdecalfile, spray.fScaleReal);

	// Get rid of the period in float representation. Source engine doesn't like
	// loading files with more than one . in the filename.
	Format(scaleString, 16, "%.4f", spray.fScaleReal); ReplaceString(scaleString, 16, ".", "-", false);

	Format(spray.sMaterialName, 64, "resizablespraysv2/%s_%s", playerdecalfile, scaleString);
	Format(vmtFilename, 128, "materials/%s.vmt", spray.sMaterialName);

	if (g_mapProcessedFiles.GetValue(vmtFilename, g_bBuffer)) {
		spray.fSprayTime = GetGameTime();
		return g_SprayQueue.PushArray(spray);
	}

	if (!FileExists(vmtFilename, false)) {
		File vmt = OpenFile(vmtFilename, "w+", false);
		if (vmt != null)
			WriteFileString(vmt, data, false);
		CloseHandle(vmt);
	}

	AddFileToDownloadsTable(vmtFilename);
	AddLateDownload(vmtFilename, false);
	g_mapProcessedFiles.SetValue(vmtFilename, 0);
	spray.fSprayTime = GetGameTime();
	LogToFile(g_strLogFile, "Adding late download %s", vmtFilename);
	return g_SprayQueue.PushArray(spray);
}

/*
	Precaches the freshly-generated VMT file
*/
public Action Timer_PrecacheAndSprayDecal(Handle timer, int sprayIndex)
{
	Spray spray;
	g_SprayQueue.GetArray(sprayIndex, spray);

	bool bIsReadyVTF = false;
	bool bIsReadyVMT = false;
	float timeWaiting = GetGameTime() - spray.fSprayTime;

	char playerdecalfile[12];
	char vtfFilename[PLATFORM_MAX_PATH];
	char vmtFilename[PLATFORM_MAX_PATH];

	if (!IsValidClient(spray.iClient)) {
		LogToFile(g_strLogFile, "Client %d is invalid even though we verified it before! Aborting spray operation.", spray.iClient);
		return Plugin_Stop;
	}

	GetPlayerDecalFile(spray.iClient, playerdecalfile, sizeof(playerdecalfile));
	Format(vtfFilename, sizeof(vtfFilename), "materials/resizablespraysv2/%s.vtf", playerdecalfile);

	Format(vmtFilename, sizeof(vmtFilename), "materials/%s.vmt", spray.sMaterialName);

	g_mapProcessedFiles.GetValue(vtfFilename, bIsReadyVTF);
	g_mapProcessedFiles.GetValue(vmtFilename, bIsReadyVMT);

	if ((bIsReadyVTF && bIsReadyVMT) || (timeWaiting > cv_fSprayTimeout.FloatValue > 0.0)) {

		if (timeWaiting > cv_fSprayTimeout.FloatValue) {
			LogToFile(g_strLogFile, "Timed out waiting for all clients to download %s, precaching material anyways.", vmtFilename);
			g_mapProcessedFiles.SetValue(vtfFilename, true);
			g_mapProcessedFiles.SetValue(vmtFilename, true);
		}

		spray.iPrecache = PrecacheDecal(spray.sMaterialName, false);
		PlaceSpray(spray);
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

/*
	Calculates where a client is looking and what entity they're looking at
	@param client id
	@return entity client is looking at. 0 means worldspawn (non-entity brushes)
	@error -1 if entity is out of range
	Credit to SM Franug for the original code
	https://forums.alliedmods.net/showthread.php?p=2118030
*/
public void CalculateSprayPosition(int client, Spray spray)
{
	float fAngles[3];
	float fOrigin[3];
	float fVector[3];

	if (!IsValidClient(client) || !IsPlayerAlive(client)) {
		LogToFile(g_strLogFile, "CalculateSprayPosition: client %i is either invalid or dead", client);
		spray.iEntity = -1;
		return;
	}

	GetClientEyeAngles(client, fAngles);
	GetClientEyePosition(client, fOrigin);

	Handle hTrace = TR_TraceRayFilterEx(fOrigin, fAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
	if (TR_DidHit(hTrace))
		TR_GetEndPosition(spray.fPosition, hTrace);

	spray.iEntity = TR_GetEntityIndex(hTrace);
	spray.iHitbox = TR_GetHitBoxIndex(hTrace);

	CloseHandle(hTrace);

	MakeVectorFromPoints(spray.fPosition, fOrigin, fVector);

	if (GetVectorLength(fVector) > cv_fMaxSprayDistance.FloatValue > 0.0 && !IsAdmin(client)) {
		//LogToFile(g_strLogFile, "CalculateSprayPosition: %N is too far from a valid surface (%0.4f > %0.4f)", client, GetVectorLength(fVector), cv_fMaxSprayDistance.FloatValue);
		spray.iEntity = -1;
	}
}

/*
	Places a decal in the world after precaching
	@param client id
	@param precache ID of material to place
	@param entity to place decal on
	@param position to place decal
	@param type of decal to place. 0 is world decal, 1 is BSP decal
*/
public void PlaceSpray(Spray spray)
{
	switch (spray.iDecalType) {
		case 0: {
			TE_Start("Entity Decal");
			TE_WriteVector("m_vecOrigin", spray.fPosition);
			TE_WriteVector("m_vecStart", spray.fPosition);
			TE_WriteNum("m_nEntity", spray.iEntity);
			TE_WriteNum("m_nHitbox", spray.iHitbox);
			TE_WriteNum("m_nIndex", spray.iPrecache);
			TE_SendToAll();
		}
		case 1: {
			TE_Start("BSP Decal");
			TE_WriteVector("m_vecOrigin", spray.fPosition);
			TE_WriteNum("m_nEntity", spray.iEntity);
			TE_WriteNum("m_nIndex", spray.iPrecache);
			TE_SendToAll();
		}
	}

	EmitSoundToAll("player/sprayer.wav", spray.iSprayer, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.6);

	return;
}


public bool TraceEntityFilterPlayer(int iEntity, int iContentsMask)
{
	return iEntity > MaxClients;
}

/*
	Determines if client is actually ready and in game
	@param client id
	@param whether or not to consider bots as valid clients
	@return true if user is ready, false otherwise
*/
stock bool IsValidClient(int client, bool nobots = true)
{
	if (client <= 0 || client > MaxClients || !IsClientConnected(client) || (nobots && IsFakeClient(client)))
		return false;

	return IsClientInGame(client);
}

/*
	Determines if a client can bypass spray restrictions
	@param client id
	@return true if user is allowed to bypass restrictions, false otherwise
*/
public bool IsAdmin(int client)
{
	char adminFlagsBuffer[16];
	cv_sAdminFlags.GetString(adminFlagsBuffer, sizeof(adminFlagsBuffer));

	return CheckCommandAccess(client, "", ReadFlagString(adminFlagsBuffer), false);
}

public bool FloatEqual(float a, float b, float error) {
    return a - b < FloatAbs(error);
}

// Returns player spray save file into string buffer
// Return value depends on engine
public void GetPlayerSprayFilePath(int client, char[] buffer, int length)
{
	char strGame[PLATFORM_MAX_PATH];
	char playerdecalfile[PLATFORM_MAX_PATH];

	GetGameFolderName(strGame, sizeof(strGame));
	GetPlayerDecalFile(client, playerdecalfile, sizeof(playerdecalfile));

	if (strcmp(strGame, "left4dead2") == 0)
		Format(buffer, length, "downloads/%s.dat", playerdecalfile);
	else
		Format(buffer, length, "download/user_custom/%c%c/%s.dat", playerdecalfile[0], playerdecalfile[1], playerdecalfile);
}
