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
#define PLUGIN_VERSION "3.4.0"
#define PLUGIN_URL "https://forums.alliedmods.net/showthread.php?t=332418"

// Normal sprays are 64 Hammer units tall
#define SPRAY_UNIT_DIMENSION_FLOAT 64.0
#define CRC_BUFFER_SIZE 9

#define LOG_ERROR 0
#define LOG_WARNING 1
#define LOG_INFO 2
#define LOG_DEBUG 3
#define LOG_TRACE 4

char g_vmtTemplate[512] = "LightmappedGeneric\n\
{\n\
\t$basetexture \"temp/%s\"\n\
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

// Represents a client
enum struct Player {
	bool bSprayHasBeenProcessed;
	bool bIsReadyToSpray;
	bool bTriedToSprayWhenDownloadingVtfs;
	float fScale; //last scale used (in relative units)
	float fLastSprayed;
	float fJoinTime;
	float fRealSprayLastPosition[3];
}

// Represents a logo file (.dat) that belongs to a Player
enum struct Logo {
	int iHeight;
	int iClientsWhoRequestedDat[MAXPLAYERS + 1];
	int iClientsWhoAreDownloadingDat[MAXPLAYERS + 1];
	char sLogoFileShort[CRC_BUFFER_SIZE];
	char sLogoFileFull[PLATFORM_MAX_PATH];
	float fLogoPrecacheTime;
}

// Represents a given material pointing to a Logo
enum struct Material {
	int iReady;
	int iPrecache; // Given precache ID
	int iClientsSuccess[MAXPLAYERS + 1];
	int iClientsDownloadingCount;
	float fScaleReal; // The real scale factor based on spray dimensions + clamping
}

// Represents a decal placed in the world (instance of a Material)
enum struct Spray {
	int iSprayer; // for sound emission
	int iOwner;
	int iEntity;
	int iHitbox;
	int iDecalType;
	float fSprayTime; // when was this request made
	float fPosition[3];
	char sMaterialName[64];
}

Player g_Players[MAXPLAYERS + 1];
Logo g_Logos[MAXPLAYERS + 1];

ArrayList g_SprayList;
StringMap g_MaterialMap;

ConVar cv_bEnabled;
ConVar cv_iLogLevel;
ConVar cv_fMaxSprayScale;
ConVar cv_fMaxSprayScaleAbsolute;
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
	RegConsoleCmd("sm_sprayinfo", Command_SprayInfo, "Prints diagnostic info about the state RSPR thinks your spray is in.");

	CreateConVar("rspr_version", PLUGIN_VERSION, "Resizable Sprays version. Don't touch this.", FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY);

	cv_bEnabled = CreateConVar("rspr_enabled", "1.0", "Enables the plugin.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cv_iLogLevel = CreateConVar("rspr_loglevel", "2", "Logging level. Higher number = more console spam.", FCVAR_NONE, false, 0.0, false, 0.0);
	cv_fMaxSprayDistance = CreateConVar("rspr_maxspraydistance", "128.0", "Max range for placing decals. 0 is infinite range", FCVAR_NOTIFY, true, 0.0, false);
	cv_fMaxSprayScale = CreateConVar("rspr_maxsprayscale", "2.0", "Maximum scale for sprays for regular players.", FCVAR_NOTIFY, true, 0.0, false, 0.0);
	cv_fMaxSprayScaleAbsolute = CreateConVar("rspr_maxsprayscale_absolute", "32.0", "Maximum scale for sprays for admins.", FCVAR_NOTIFY, true, 0.0, false, 0.0);
	cv_fDecalFrequency = CreateConVar("rspr_decalfrequency", "0.5", "Spray frequency for non-admins. 0 is no delay.", FCVAR_NOTIFY, true, 0.0, false);
	cv_fSprayTimeout = CreateConVar("rspr_spraytimeout", "10.0", "Max time to wait for clients to download spray files. 0 to wait forever.", FCVAR_NOTIFY, true, 0.0, false);

	AddTempEntHook("Player Decal", PlayerSprayReal);

	AutoExecConfig(true, "resizablesprays");
	LoadTranslations("common.phrases");

	char timebuffer[32];
	FormatTime(timebuffer, sizeof(timebuffer), "%F", GetTime());
	BuildPath(Path_SM, g_strLogFile, sizeof(g_strLogFile), "logs/rspr_%s.log", timebuffer);

	if (!DirExists("materials", false))
		CreateDirectory("materials", 511, false); // 511 decimal = 755 octal

	if (!DirExists("materials/resizablespraysv3", false))
		CreateDirectory("materials/resizablespraysv3", 511, false);
}

public void OnMapStart()
{
	g_MaterialMap = new StringMap();
	g_SprayList = new ArrayList(sizeof(Spray));
}

public void OnClientPostAdminCheck(int client)
{
	ResetSprayInfo(client);

	if ((!cv_bEnabled.BoolValue) || StrEqual(g_Logos[client].sLogoFileShort, NULL_STRING))
		return;

	PrintToChat(client, "[SM] Preparing your spray for resizing...");

	CreateTimer(2.0, Timer_CheckIfSprayIsReady, client, TIMER_REPEAT);
}

public void ResetSprayInfo(int client)
{
	g_Players[client].bIsReadyToSpray = false;
	g_Players[client].bSprayHasBeenProcessed = false;
	g_Players[client].bTriedToSprayWhenDownloadingVtfs = false;
	g_Players[client].fScale = 1.0;
	g_Players[client].fLastSprayed = 0.0;
	g_Players[client].fJoinTime = GetGameTime();
	g_Players[client].fRealSprayLastPosition[0] = -16380.0;
	g_Players[client].fRealSprayLastPosition[1] = -16380.0;
	g_Players[client].fRealSprayLastPosition[2] = -16380.0;

	g_Logos[client].iHeight = 0;
	g_Logos[client].fLogoPrecacheTime = 0.0;
	g_Logos[client].sLogoFileShort = NULL_STRING;
	g_Logos[client].sLogoFileFull = NULL_STRING;

	for (int c = 1; c <= MaxClients; c++) {
		g_Logos[client].iClientsWhoRequestedDat[c] = 0;
		g_Logos[client].iClientsWhoAreDownloadingDat[c] = 0;
	}

	if (IsValidClient(client)) {
		GetPlayerDecalFile(client, g_Logos[client].sLogoFileShort, sizeof(g_Logos[].sLogoFileShort));
		GetPlayerSprayFilePath(client, false, g_Logos[client].sLogoFileFull, sizeof(g_Logos[].sLogoFileFull));
		RSPR_Log(LOG_DEBUG, "ResetSprayInfo (%N): Spray file path is %s", client, g_Logos[client].sLogoFileFull);
		PlaceRealPlayerLogo(client, client);
	}
}

public Action Timer_CheckIfSprayIsReady(Handle timer, int client)
{
	if (!IsValidClient(client))
		return Plugin_Stop;

	if (g_Players[client].bSprayHasBeenProcessed && !g_Players[client].bIsReadyToSpray && GetSprayQueueCount(client) <= 0) {
		g_Players[client].bIsReadyToSpray = true;
		PrintToChat(client, "[SM] Your spray is ready! Type /spray %d to make big sprays.", RoundToZero(cv_fMaxSprayScale.FloatValue));
		return Plugin_Stop;
	} else {
		if (!g_Players[client].bSprayHasBeenProcessed) {
			if (!ProcessPlayerLogoFile(client)) {
				RSPR_Log(LOG_INFO, "Killing timer for %N.", client);
				return Plugin_Stop;
			}
		}
	}

	return Plugin_Continue;
}

public bool ProcessPlayerLogoFile(int client)
{
	int dimensions[2] = {0, 0};

	if (!g_Players[client].bSprayHasBeenProcessed) {
		Handle vtfFile = OpenFile(g_Logos[client].sLogoFileFull, "r", true, NULL_STRING);

		if (vtfFile == INVALID_HANDLE) {
			RSPR_Log(LOG_TRACE, "ProcessPlayerLogoFile: File %s doesn't exist.", g_Logos[client].sLogoFileFull);
			CloseHandle(vtfFile);
			return true;
		}

		FileSeek(vtfFile, 16, SEEK_SET);
		ReadFile(vtfFile, dimensions, 2, 2);
		g_Logos[client].iHeight = dimensions[1];

		CloseHandle(vtfFile);

		if (g_Logos[client].iHeight <= 0) {
			RSPR_Log(LOG_WARNING, "%N's spray %s is not a VTF file.", client, g_Logos[client].sLogoFileFull); // TODO: check if it's a jingle file
			return false;
		}

		g_Players[client].bSprayHasBeenProcessed = true;
	}

	return true;
}

public void OnDownloadSuccess(int client, const char[] filename)
{
	HandleDownloadConfirmation(client, filename, true);
}

public void OnDownloadFailure(int client, const char[] filename)
{
	HandleDownloadConfirmation(client, filename, false);
}

void HandleDownloadConfirmation(int client, const char[] filename, bool success = false)
{
	int iSprayOwner = GetClientIdFromSprayFile(filename);
	Material material;
	bool isSprayMaterial = g_MaterialMap.GetArray(filename, material, sizeof(material));

	RSPR_Log(LOG_DEBUG, "HandleDownloadConfirmation(%d, %s): %d", client, filename, isSprayMaterial);

	if (!isSprayMaterial) {
		if (StrEqual(filename[strlen(filename)-4], ".dat") && client > 0) {

			if (!IsValidClient(iSprayOwner))
				return;

			g_Logos[iSprayOwner].iClientsWhoRequestedDat[client] = 0;
			g_Logos[iSprayOwner].iClientsWhoAreDownloadingDat[client] = 0;

			if (!IsValidClient(client))
				return;

			if (success) {
				RSPR_Log(LOG_DEBUG, "%N received .dat file %s.", client, filename);
				PlaceRealPlayerLogo(iSprayOwner, client);
			} else
				RSPR_Log(LOG_DEBUG, "%N failed downloading .dat file %s.", client, filename);

			int queue = GetSprayQueueCount(client);
			if (IsValidClient(client) && queue > 0) {
				RSPR_Log(LOG_DEBUG, "HandleDownloadConfirmation: %N is still downloading %d sprays.", client, queue);
				return;
			}

			if (IsValidClient(client) && g_Players[client].bTriedToSprayWhenDownloadingVtfs) {
				g_Players[client].bTriedToSprayWhenDownloadingVtfs = false;
				PrintToChat(client, "[SM] Your client has finished downloading spray files.");
			}

			return;
		}
	}

	if (client > 0) {
		if (success) {
			RSPR_Log(LOG_DEBUG, "%N downloaded file '%s'", client, filename);
			material.iClientsSuccess[client] = GetClientUserId(client);
		} else
			RSPR_Log(LOG_DEBUG, "%c failed downloading file '%s'", client, filename);

		material.iClientsDownloadingCount--;
		if (material.iClientsDownloadingCount == 0) {
			material.iReady = 2;
			RSPR_Log(LOG_INFO, "All players downloaded file '%s'", filename);
		}

		g_MaterialMap.SetArray(filename, material, sizeof(material));
		return;
	}

	if (!success)
		RSPR_Log(LOG_INFO, "Error adding '%s' to download queue", filename);
}

// We're hijacking the standard spray-sending procedure so we can track
// progress of the .dat downloads
public Action OnFileSend(int client, const char[] sFile)
{
	int iSprayOwner = GetClientIdFromSprayFile(sFile);

	// Not a spray file, ignore.
	if (!IsValidClient(iSprayOwner)) {
		return Plugin_Continue;
	}

	if (!IsValidClient(client)) {
                return Plugin_Continue;
        }

	// Mark client as having requested this file
	g_Logos[iSprayOwner].iClientsWhoRequestedDat[client] = GetClientUserId(client);

	// We call AddLateDownload at the end, which immediately calls SendFile again
	// File is already in the queue, so don't worry about it
	if (g_Logos[iSprayOwner].iClientsWhoAreDownloadingDat[client] == GetClientUserId(client)) {
		RSPR_Log(LOG_DEBUG, "OnFileSend(%N, %s): File is in user's DAT queue.", client, sFile);
		return Plugin_Continue;
	}

	// We could let the plugin continue here, but in this case we'll just get
	// CreateFragmentsFromFile: 'filename' doesn't exist
	// so we might as well stop now.
	if (!FileExists(sFile, true, NULL_STRING)) {
		//RSPR_Log(LOG_TRACE, "OnFileSend(%N, %s): File doesn't exist.", client, sFile);
		return Plugin_Handled;
	}

	RSPR_Log(LOG_DEBUG, "OnFileSend: sending %s to %N", sFile, client);
	g_Logos[iSprayOwner].iClientsWhoAreDownloadingDat[client] = GetClientUserId(client);
	AddLateDownload(sFile, false, client, true);

	return Plugin_Handled;
}

/*
	Handles the !spray and !bspray commands
	@param ID of client, will use their spray's unique filename
	@param number of args
*/
public Action Command_Spray(int client, int args)
{
	float scaleReal;
	char arg0[64]; GetCmdArg(0, arg0, sizeof(arg0));
	char arg1[64]; GetCmdArg(1, arg1, sizeof(arg1));
	char arg2[64]; GetCmdArg(2, arg2, sizeof(arg2));
	char vmtFilename[PLATFORM_MAX_PATH];

	Material material;
	Spray spray;
	spray.iSprayer = client;
	spray.iOwner = client;

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
			spray.iOwner = FindTarget(client, arg2, true, true);
			if (spray.iOwner == -1)
				return Plugin_Handled;

			if (!IsValidClient(spray.iOwner)) {
				ReplyToCommand(client, "[SM] This client isn't in game yet! Please try again later.");
				return Plugin_Handled;
			}
		}
	}

	if (!g_Players[spray.iOwner].bIsReadyToSpray) {
		ReplyToCommand(client, "[SM] We're still preparing this spray! Please try again later.");
		return Plugin_Handled;
	}

	scaleReal = GetRealSprayScale(client, spray.iOwner, g_Players[client].fScale);
	WriteVmtMaterialName(spray, scaleReal, vmtFilename, sizeof(vmtFilename));

	if (!g_MaterialMap.GetArray(vmtFilename, material, sizeof(material))) {
		// Client's netchannel is in use
		int queue = GetSprayQueueCount(client);
		if (queue > 0) {
			g_Players[client].bTriedToSprayWhenDownloadingVtfs = true;
			ReplyToCommand(client, "[SM] Your client is currently downloading %d spray files. Please try again later.", queue);
			return Plugin_Handled;
		}
	}

	CalculateSprayPosition(client, spray);

	if (spray.iEntity > -1) {
		RSPR_Log(LOG_INFO, "Command_Spray: %N is spraying %N's spray at %0.4f (%0.4f) scale, size %d", client, spray.iOwner, g_Players[client].fScale, scaleReal, g_Logos[spray.iOwner].iHeight);
		int sprayIndex;
		if ((sprayIndex = WriteVmt(spray, scaleReal)) != -1)
			CreateTimer(0.0, Timer_PrecacheAndSprayDecal, sprayIndex, TIMER_REPEAT);

	} else {
		ReplyToCommand(client, "[SM] You are too far away from a valid surface to place a spray!");
	}

	return Plugin_Handled;
}

public Action Command_SprayInfo(int client, int args)
{
	int target = 0;

	char arg1[64]; GetCmdArg(1, arg1, sizeof(arg1));

	if (args > 2) {
		if (IsAdmin(client))
			ReplyToCommand(client, "Usage: !sm_sprayinfo [client]");
		else
			ReplyToCommand(client, "Usage: !sm_sprayinfo");
		return Plugin_Handled;
	}

	if (IsAdmin(client) && !StrEqual(arg1, NULL_STRING)) {
		target = FindTarget(client, arg1, true, false);
		if (!IsValidClient(target))
			return Plugin_Handled;
	} else {
		target = client;
	}

	// Worst case scenario is each client having a full 32 character name
	// but accounting for that overflows Sourcemod's internal buffers

	char sMessage[2048];
	char sSendingTo[512];
	char sRequestedFrom[512];
	char sDownloadingFrom[36 + MAX_NAME_LENGTH];
	int iDownloadingFrom;

    // get requesters and downloaders of this user's spray
	for (int c = 1; c <= MaxClients; c++) {
		if (!IsValidClient(c)) continue;

		if (g_Logos[target].iClientsWhoRequestedDat[c] == GetClientUserId(c))
			if (StrEqual(sSendingTo, NULL_STRING))
				GetClientName(c, sSendingTo, sizeof(sSendingTo));
			else
				Format(sSendingTo, sizeof(sSendingTo), "%s, %N", sSendingTo, c);

		if (g_Logos[c].iClientsWhoRequestedDat[target] == GetClientUserId(target)) {
			if (g_Logos[c].iClientsWhoAreDownloadingDat[target] == GetClientUserId(target))
				iDownloadingFrom = c;
			else if (StrEqual(sRequestedFrom, NULL_STRING))
				GetClientName(c, sRequestedFrom, sizeof(sRequestedFrom));
			else
				Format(sRequestedFrom, sizeof(sRequestedFrom), "%s, %N", sRequestedFrom, c);
		}
    }

	if (!StrEqual(sSendingTo, NULL_STRING))
		Format(sSendingTo, sizeof(sSendingTo), "Downloading your spray: %s\n", sSendingTo);
	if (!StrEqual(sRequestedFrom, NULL_STRING))
		Format(sRequestedFrom, sizeof(sRequestedFrom), "Queued downloads: %s\n", sRequestedFrom);

	if (iDownloadingFrom > 0)
		Format(sDownloadingFrom, sizeof(sDownloadingFrom), "Currently downloading from: %N", iDownloadingFrom);

	Format(sMessage, sizeof(sMessage), "%s%s%s", sSendingTo, sRequestedFrom, sDownloadingFrom);

	if (StrEqual(sMessage, NULL_STRING))
		Format(sMessage, sizeof(sMessage), "Nothing to report.");

	ReplySource rs = GetCmdReplySource();

	if (strlen(sMessage) > 128) {
		PrintToChat(client, "[SM] See console for output.");
		SetCmdReplySource(SM_REPLY_TO_CONSOLE);
	}

	ReplyToCommand(client, sMessage);
	SetCmdReplySource(rs);

	return Plugin_Handled;
}

float GetRealSprayScale(int sprayer, int owner, float scale)
{
	if (!IsAdmin(sprayer) && scale > cv_fMaxSprayScale.FloatValue)
		scale = cv_fMaxSprayScale.FloatValue;

	if (scale > cv_fMaxSprayScaleAbsolute.FloatValue)
		scale = cv_fMaxSprayScaleAbsolute.FloatValue;

	if (FloatEqual(g_Players[sprayer].fScale, 0.0, 0.001)) {
		scale = 1.0;
	}

	// We shouldn't be here if iSprayHeight is 0
	return scale * SPRAY_UNIT_DIMENSION_FLOAT / float(g_Logos[owner].iHeight);
}

public void WriteVmtMaterialName(Spray spray, float scaleReal, char[] buffer, int bufferSize)
{
	char scaleString[16];

	// Get rid of the period in float representation. Source engine doesn't like
	// loading files with more than one . in the filename.
	Format(scaleString, 16, "%.4f", scaleReal); ReplaceString(scaleString, 16, ".", "-", false);
	Format(spray.sMaterialName, 64, "resizablespraysv3/%s_%s", g_Logos[spray.iOwner].sLogoFileShort, scaleString);
	Format(buffer, bufferSize, "materials/%s.vmt", spray.sMaterialName);
}

/*
	Writes a VMT file to the server, then sends it to all available clients
	@param ID of client, will use their spray's unique filename
	@param scale of decal for generated material
	@param buffer for material name
*/
public int WriteVmt(Spray spray, float scaleReal)
{
	Material material;
	char vmtFilename[PLATFORM_MAX_PATH];
	char data[512];

	material.fScaleReal = scaleReal;
	Format(data, 512, g_vmtTemplate, g_Logos[spray.iOwner].sLogoFileShort, scaleReal);
	Format(vmtFilename, 128, "materials/%s.vmt", spray.sMaterialName);

			// Make new material if it doesn't exist
	if (!g_MaterialMap.GetArray(vmtFilename, material, sizeof(material))) {
		g_MaterialMap.SetArray(vmtFilename, material, sizeof(material));
	}

	// We've already processed this spray
	if (material.iReady) {
		spray.fSprayTime = GetGameTime();
		return g_SprayList.PushArray(spray);
	}

	if (!FileExists(vmtFilename, false)) {
		Handle vmt = OpenFile(vmtFilename, "w+", false);
		if (vmt != INVALID_HANDLE)
			WriteFileString(vmt, data, false);
		CloseHandle(vmt);
	}

	RSPR_Log(LOG_INFO, "Adding late download %s", vmtFilename);

	for (int c = 1; c <= MaxClients; c++) {
		if (!IsValidClient(c)) continue;

		int count = GetSprayQueueCount(c);

		if (count > 0) {
			RSPR_Log(LOG_DEBUG, "WriteVmt: %N is still downloading %d sprays.", c, count);
		} else {
			RSPR_Log(LOG_DEBUG, "WriteVmt: %N isn't downloading any sprays.", c);
			material.iClientsDownloadingCount++;
			AddLateDownload(vmtFilename, false, c);
		}
	}

	material.iReady = 1;
	g_MaterialMap.SetArray(vmtFilename, material, sizeof(material));

	spray.fSprayTime = GetGameTime();
	return g_SprayList.PushArray(spray);
}

/*
	Precaches the freshly-generated VMT file
*/
public Action Timer_PrecacheAndSprayDecal(Handle timer, int sprayIndex)
{
	// this shouldn't be necessary
	if (g_SprayList.Length < sprayIndex) {
		RSPR_Log(LOG_ERROR, "ERROR: Spray queue length is %d but we tried to spray %d!", g_SprayList.Length, sprayIndex);
		return Plugin_Stop;
	}

	Material material;
	Spray spray;
	char vmtFilename[PLATFORM_MAX_PATH];

	g_SprayList.GetArray(sprayIndex, spray);

	Format(vmtFilename, 128, "materials/%s.vmt", spray.sMaterialName);

	if (!g_MaterialMap.GetArray(vmtFilename, material, sizeof(material)))
		RSPR_Log(LOG_ERROR, "ERROR: %s not in global array!", vmtFilename);

	float timeWaiting = GetGameTime() - spray.fSprayTime;

	if (!IsValidClient(spray.iOwner)) {
		RSPR_Log(LOG_INFO, "Client %d is invalid! They most likely have left the server. Aborting spray operation.", spray.iOwner);
		return Plugin_Stop;
	}

	if (material.iReady == 2 || (timeWaiting > cv_fSprayTimeout.FloatValue > 0.0)) {

		if (timeWaiting > cv_fSprayTimeout.FloatValue > 0.0) {
			RSPR_Log(LOG_INFO, "Timed out waiting for all clients to download %s, precaching material anyways.", vmtFilename);
			material.iReady = 2;
		}

		if (g_Logos[spray.iOwner].fLogoPrecacheTime == 0.0)
			g_Logos[spray.iOwner].fLogoPrecacheTime = GetGameTime();

		material.iPrecache = PrecacheDecal(spray.sMaterialName, false);
		g_MaterialMap.SetArray(vmtFilename, material, sizeof(material));

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
		RSPR_Log(LOG_INFO, "CalculateSprayPosition: client %i is either invalid or dead", client);
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
		//RSPR_Log(LOG_INFO, "CalculateSprayPosition: %N is too far from a valid surface (%0.4f > %0.4f)", client, GetVectorLength(fVector), cv_fMaxSprayDistance.FloatValue);
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
	Material material;
	char vmtFilename[PLATFORM_MAX_PATH];

	Format(vmtFilename, 128, "materials/%s.vmt", spray.sMaterialName);

	g_MaterialMap.GetArray(vmtFilename, material, sizeof(material));

	int[] targets = new int[MaxClients];
	int numTargets = 0;

	// Only include known successful downloads
	for (int c = 1; c <= MaxClients; c++) {
		if (IsValidClient(c)
		&& material.iClientsSuccess[c] == GetClientUserId(c)
		&& g_Logos[spray.iOwner].fLogoPrecacheTime > g_Players[c].fJoinTime) {
			targets[numTargets++] = c;
			RSPR_Log(LOG_DEBUG, "PlaceSpray: adding %N for %N's spray", c, spray.iOwner);
			PlaceRealPlayerLogo(spray.iOwner, c);
		}
	}

	switch (spray.iDecalType) {
		case 0: {
			TE_Start("Entity Decal");
			TE_WriteVector("m_vecOrigin", spray.fPosition);
			TE_WriteVector("m_vecStart", spray.fPosition);
			TE_WriteNum("m_nEntity", spray.iEntity);
			TE_WriteNum("m_nHitbox", spray.iHitbox);
			TE_WriteNum("m_nIndex", material.iPrecache);
		}
		case 1: {
			TE_Start("BSP Decal");
			TE_WriteVector("m_vecOrigin", spray.fPosition);
			TE_WriteNum("m_nEntity", spray.iEntity);
			TE_WriteNum("m_nIndex", material.iPrecache);
		}
	}

	TE_Send(targets, numTargets);

	EmitSoundToAll("player/sprayer.wav", spray.iSprayer, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.35);

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
stock bool IsAdmin(int client)
{
	return CheckCommandAccess(client, "rspr_adminoverride", ADMFLAG_KICK, false);
}

stock bool FloatEqual(float a, float b, float error) {
    return a - b < FloatAbs(error);
}

// Returns player spray save file into string buffer
// Return value depends on engine
stock void GetPlayerSprayFilePath(int client, int absolutePath = false, char[] buffer, int length)
{
	char playerdecalfile[12];
	char filePathBuffer[PLATFORM_MAX_PATH];

	GetPlayerDecalFile(client, playerdecalfile, sizeof(playerdecalfile));

	if (GetEngineVersion() > Engine_Left4Dead2) {
		if (absolutePath)
			Format(filePathBuffer, sizeof(filePathBuffer), "%s", "download/user_custom/%c%c/%s.dat");
		else
			Format(filePathBuffer, sizeof(filePathBuffer), "%s", "user_custom/%c%c/%s.dat");

		Format(buffer, length, filePathBuffer, playerdecalfile[0], playerdecalfile[1], playerdecalfile);

	} else {
		Format(buffer, length, "downloads/%s.dat", playerdecalfile);
	}
}

stock void PlaceRealPlayerLogo(int owner, int recipient)
{
	RSPR_Log(LOG_TRACE, "PlaceRealPlayerLogo(%d, %d)", owner, recipient);

	if (!IsValidClient(owner) || !IsValidClient(recipient))
		return;

	TE_Start("Player Decal");
	TE_WriteVector("m_vecOrigin", g_Players[owner].fRealSprayLastPosition);
	TE_WriteNum("m_nEntity", 0);
	TE_WriteNum("m_nPlayer", owner);
	TE_SendToClient(recipient);
}

stock int GetClientIdFromSprayFile(const char[] sprayFile)
{
	char buffer[PLATFORM_MAX_PATH];
	for (int c = 1; c <= MaxClients; c++) {
		if (!IsValidClient(c))
			continue;

		GetPlayerSprayFilePath(c, false, buffer, sizeof(buffer));

		if (StrEqual(buffer, sprayFile)) {
			RSPR_Log(LOG_TRACE, "GetClientIdFromSprayFile(%s): client %N", sprayFile, c);
			return c;
		}
	}

	//RSPR_Log(LOG_TRACE, "GetClientIdFromSprayFile(%s): Failed", sprayFile);
	return -1;
}

public int GetSprayQueueCount(int client)
{
	int num = 0;
	for (int c = 1; c <= MaxClients; c++)
		if (IsValidClient(client) && g_Logos[c].iClientsWhoAreDownloadingDat[client] == GetClientUserId(client))
			num++;
	return num;
}

public Action PlayerSprayReal(const char[] szTempEntName, const int[] arrClients, int iClientCount, float flDelay) {
	int client = TE_ReadNum("m_nPlayer");
	if (IsValidClient(client))
		TE_ReadVector("m_vecOrigin", g_Players[client].fRealSprayLastPosition);
	return Plugin_Continue;
}

void RSPR_Log(int level, char [] format, any ...) {
    static char g_dB[512];

    if (level <= cv_iLogLevel.IntValue) {
        VFormat(g_dB, sizeof(g_dB), format, 3);
        LogToFile(g_strLogFile, g_dB);
    }
}
