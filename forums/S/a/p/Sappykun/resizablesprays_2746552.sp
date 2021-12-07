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
#include <filenetmessages>

#pragma newdecls required
#pragma semicolon 1

#define PLUGIN_NAME "Resizable Sprays"
#define PLUGIN_DESC "Extends default sprays to allow for scaling and spamming"
#define PLUGIN_AUTHOR "Sappykun"
#define PLUGIN_VERSION "1.1.2"
#define PLUGIN_URL "https://forums.alliedmods.net/showthread.php?t=332418"

#define DEBUG 1

enum struct Spray {
	int iSprayer;
	int iPrecache;
	int iClient;
	int iEntity;
	int iHitbox;
	int iDecalType;
	float fScale;
	float fPosition[3];
	char sMaterialName[64];
}

// TODO: move this to a separate file
char g_vmtTemplate[512] = "LightmappedGeneric\n\
{\n\
\t$basetexture \"temp/%s\"\n\
\t$vertexcolor 1\n\
\t$vertexalpha 1\n\
\t$translucent 1\n\
\t$decal 1\n\
\tdecalsecondpass 1\n\
\t$decalscale %.4f\n\
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

float g_fClientLastSprayed[MAXPLAYERS + 1];

ConVar cv_sAdminFlags;
ConVar cv_fSprayDelay;
ConVar cv_fMaxSprayScale;
ConVar cv_fMaxSprayDistance;
ConVar cv_fDecalFrequency;

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

	cv_sAdminFlags = CreateConVar("rspr_adminflags", "b", "Admin flags required to bypass restrictions", FCVAR_NONE, false, 0.0, false, 0.0);
	cv_fSprayDelay = CreateConVar("rspr_delay", "0.5", "Time to give to send out a VMT file. Setting this too low\nwill cause material loading errors on clients.", FCVAR_NONE, true, 0.0, false, 0.0);
	cv_fMaxSprayDistance = CreateConVar("rspr_maxspraydistance", "128.0", "Max range for placing decals. 0 is infinite range", FCVAR_NONE, true, 0.0, false);
	cv_fMaxSprayScale = CreateConVar("rspr_maxsprayscale", "0.20", "Maximum scale for sprays. Actual size depends on dimensions of your spray.\nFor reference, a 512x512 spray at 0.25 scale will be 128x128\nhammer units tall, double that of a normal 64x64 spray.", FCVAR_NONE, true, 0.0, false, 0.0);
	cv_fDecalFrequency = CreateConVar("rspr_decalfrequency", "0.5", "Spray frequency for non-admins. 0 is no delay.", FCVAR_NONE, true, 0.0, false);

	AutoExecConfig(true, "resizablesprays");
	LoadTranslations("common.phrases");
}

/*
	Resets decalfrequency timer when client joins
*/
public void OnClientConnected(int client)
{
	g_fClientLastSprayed[client] = 0.0;
}

public void OnMapStart()
{
	for (int c = 0; c < sizeof(g_fClientLastSprayed); c++)
		g_fClientLastSprayed[c] = 0.0;
}


/*
	Handles the !spray and !bspray commands
	@param ID of client, will use their spray's unique filename
	@param number of args
*/
public Action Command_Spray(int client, int args)
{
	Spray spray;
	char arg0[64]; GetCmdArg(0, arg0, sizeof(arg0));
	char arg1[64]; GetCmdArg(1, arg1, sizeof(arg1));
	char arg2[64]; GetCmdArg(2, arg2, sizeof(arg2));

	spray.iSprayer = client;
	spray.iClient = client;

	if (!IsValidClient(client)) {
		return Plugin_Handled;
	}

	if (GetGameTime() - g_fClientLastSprayed[client] < cv_fDecalFrequency.FloatValue && !IsAdmin(client)) {
		return Plugin_Handled;
	}
	g_fClientLastSprayed[client] = GetGameTime();

	if (args > 0) {
		if (!IsAdmin(client) && (args > 1 || !StringToFloatEx(arg1, spray.fScale))) {
			ReplyToCommand(client, "Usage: %s [desired_scale]", arg0);
			return Plugin_Handled;
		}

		if (IsAdmin(client) && (args > 2 || !StringToFloatEx(arg1, spray.fScale))) {
			ReplyToCommand(client, "Usage: %s [desired_scale] [user]", arg0);
			return Plugin_Handled;
		}

		if (IsAdmin(client) && args == 2) {
			spray.iClient = FindTarget(client, arg2, true, true);
			if (spray.iClient == -1) {
				return Plugin_Handled;
			}
		}

		if (!IsAdmin(client) && spray.fScale > cv_fMaxSprayScale.FloatValue)
			spray.fScale = cv_fMaxSprayScale.FloatValue;
	}
	else {
		spray.fScale = cv_fMaxSprayScale.FloatValue;
	}

	if (StrEqual(arg0, "sm_bspray") && IsAdmin(client))
		spray.iDecalType = 1;

	CalculateSprayPosition(spray);

	if (spray.iEntity > -1) {
		WriteVMT(spray);

		// We need to give the players time to download the VMT before we precache it
		// TODO: Perform a more robust check. Might need to replace filenetmessages
		// with latedownloads
		DataPack pack;
		CreateDataTimer(cv_fSprayDelay.FloatValue, Timer_PrecacheAndSprayDecal, pack);
		pack.WriteCell(spray.iSprayer);
		pack.WriteCell(spray.iEntity);
		pack.WriteCell(spray.fPosition[0]);
		pack.WriteCell(spray.fPosition[1]);
		pack.WriteCell(spray.fPosition[2]);
		pack.WriteCell(spray.iHitbox);
		pack.WriteString(spray.sMaterialName);
		pack.WriteCell(spray.iDecalType);
	}

	return Plugin_Handled;
}

/*
	Writes a VMT file to the server, then sends it to all available clients
	@param ID of client, will use their spray's unique filename
	@param scale of decal for generated material
	@param buffer for material name
*/
public void WriteVMT(Spray spray)
{
	char playerdecalfile[12]; GetPlayerDecalFile(spray.iClient, playerdecalfile, sizeof(playerdecalfile));

	char data[512]; Format(data, 512, g_vmtTemplate, playerdecalfile, spray.fScale);

	// Get rid of the period in float representation. Source engine doesn't like
	// loading files with more than one . in the filename.
	char scaleString[16]; Format(scaleString, 16, "%.4f", spray.fScale); ReplaceString(scaleString, 16, ".", "-", false);

	Format(spray.sMaterialName, sizeof(spray.sMaterialName), "resizablesprays/%s_%s", playerdecalfile, scaleString);
	char filename[128]; Format(filename, 128, "materials/%s.vmt", spray.sMaterialName);

	if (!FileExists(filename, false)) {

		if (!DirExists("materials/resizablesprays", false))
			CreateDirectory("materials/resizablesprays", 511, false); // 511 decimal = 755 octal

		File vmt = OpenFile(filename, "w+", false);
		if (vmt != null)
			WriteFileString(vmt, data, false);
		CloseHandle(vmt);
	}

	float empty[3] =  { -16384.0, -16384.0, -16384.0 };

	// Get clients to download spray
	TE_Start("Player Decal");
	TE_WriteVector("m_vecOrigin", empty);
	TE_WriteNum("m_nEntity", 0);
	TE_WriteNum("m_nPlayer", spray.iClient);
	TE_SendToAll();

	// Send file to client
	for (int c = 1; c <= MaxClients; c++) {
		if (IsValidClient(c)) {
			FNM_SendFile(c, filename);
		}
	}
}

/*
	Precaches the freshly-generated VMT file
*/
public Action Timer_PrecacheAndSprayDecal(Handle timer, DataPack pack)
{
	int client;
	int iEntity;
	int iHitbox;
	int decalType;
	float fClientEyeViewPoint[3];
	char materialName[32];

	pack.Reset();
	client = pack.ReadCell();
	iEntity = pack.ReadCell();
	fClientEyeViewPoint[0] = pack.ReadCell();
	fClientEyeViewPoint[1] = pack.ReadCell();
	fClientEyeViewPoint[2] = pack.ReadCell();
	iHitbox = pack.ReadCell();
	pack.ReadString(materialName, sizeof(materialName));
	decalType = pack.ReadCell();

	int precacheId = PrecacheDecal(materialName, false);
	PlaceSpray(client, precacheId, iEntity, fClientEyeViewPoint, iHitbox, decalType);
}

/*
	Calculates where a client is looking and what entity they're looking at
	@param client id
	@param vector respresenting where client is looking
	@return entity client is looking at. 0 means worldspawn (non-entity brushes)
	@error -1 if entity is out of range
	Credit to SM Franug for the original code
	https://forums.alliedmods.net/showthread.php?p=2118030
*/
public void CalculateSprayPosition(Spray spray)
{
	float fAngles[3];
	float fOrigin[3];
	float fVector[3];

	if (!IsValidClient(spray.iSprayer) || !IsPlayerAlive(spray.iSprayer)) {
		spray.iEntity = -1;
		return;
	}

	GetClientEyeAngles(spray.iSprayer, fAngles);
	GetClientEyePosition(spray.iSprayer, fOrigin);

	Handle hTrace = TR_TraceRayFilterEx(fOrigin, fAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);
	if (TR_DidHit(hTrace))
		TR_GetEndPosition(spray.fPosition, hTrace);

	spray.iEntity = TR_GetEntityIndex(hTrace);
	spray.iHitbox = TR_GetHitBoxIndex(hTrace);

	CloseHandle(hTrace);

	MakeVectorFromPoints(fOrigin, spray.fPosition, fVector);

	if (GetVectorLength(fVector) > cv_fMaxSprayDistance.FloatValue > 0 && !IsAdmin(spray.iSprayer))
		spray.iEntity = -1;
}

/*
	Places a decal in the world after precaching
	@param client id
	@param precache ID of material to place
	@param entity to place decal on
	@param position to place decal
	@param type of decal to place. 0 is world decal, 1 is BSP decal
*/
public void PlaceSpray(int client, int precacheId, int iEntity, float fClientEyeViewPoint[3], int hitbox, int decalType)
{
	switch (decalType) {
		case 0: {
			TE_Start("Entity Decal");
			TE_WriteVector("m_vecOrigin", fClientEyeViewPoint);
			TE_WriteVector("m_vecStart", fClientEyeViewPoint);
			TE_WriteNum("m_nEntity", iEntity);
			TE_WriteNum("m_nHitbox", hitbox);
			TE_WriteNum("m_nIndex", precacheId);
			TE_SendToAll();
		}
		case 1: {
			TE_Start("BSP Decal");
			TE_WriteVector("m_vecOrigin", fClientEyeViewPoint);
			TE_WriteNum("m_nEntity", iEntity);
			TE_WriteNum("m_nIndex", precacheId);
			TE_SendToAll();
		}
	}

	EmitSoundToAll("player/sprayer.wav", client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.6);

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
	{
		return false;
	}
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
