#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <clientprefs>

new Handle:g_hwasted_enalbed = INVALID_HANDLE;
new bool:g_bwasted_enalbed;
new Handle:g_hTimeOverlay;
new g_bClientPrefHsOverlays[MAXPLAYERS+1];
new Handle:g_hClientCookieWastedOverlays = INVALID_HANDLE;

#define PLUGIN_VERSION "1.2"
public Plugin:myinfo =
{
    name = "[TF2] Wasted",
    author = "TonyBaretta(FoolishBoy)",
    description = "You are dead!",
    version = PLUGIN_VERSION,
    url = "http://steamcommunity.com/groups/foolishserver"
}

public OnMapStart() {
	decl String:file[256];
	BuildPath(Path_SM, file, 255, "configs/tf2_wasted.ini");
	new Handle:fileh = OpenFile(file, "r");
	if (fileh != INVALID_HANDLE)
	{
		decl String:buffer[256];
		decl String:buffer_full[PLATFORM_MAX_PATH];

		while(ReadFileLine(fileh, buffer, sizeof(buffer)))
		{
			TrimString(buffer);
			if ( (StrContains(buffer, "//") == -1) && (!StrEqual(buffer, "")) )
			{
				PrintToServer("Reading overlay_downloads line :: %s", buffer);
				Format(buffer_full, sizeof(buffer_full), "materials/%s", buffer);
				if (FileExists(buffer_full))
				{
					PrintToServer("Precaching %s", buffer);
					PrecacheDecal(buffer, true);
					AddFileToDownloadsTable(buffer_full);
				}
			}
		}
	}
	AddFileToDownloadsTable("sound/wasted/wasted.mp3");
	PrecacheSound("wasted/wasted.mp3", true);
}
public OnPluginStart() {
	CreateConVar("tf_wasted_effect", PLUGIN_VERSION, "[TF2]GTA Wasted Effect", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	HookEvent("player_death", PlayerDeath); //When player suicide
	g_hwasted_enalbed = CreateConVar("sm_wasted_enabled", "1", "set effect");
	g_bwasted_enalbed = GetConVarBool(g_hwasted_enalbed);
	g_hTimeOverlay = CreateConVar("wasted_ovtime", "7.0", "Set overlay time");
	RegConsoleCmd("sm_wasted", Command_HsImpact, "Set on or off overlay");
	g_hClientCookieWastedOverlays = RegClientCookie("Wasted Overlays", "set overlays on / off ", CookieAccess_Private);
}
public OnClientPutInServer(client) {
	LoadClientCookiesFor(client);
	CreateTimer(25.0, WelcomeVersion, client);
}
public LoadClientCookiesFor(client)
{
	new String:buffer[5]
	GetClientCookie(client,g_hClientCookieWastedOverlays,buffer,5)
	if(!StrEqual(buffer,""))
	{
		g_bClientPrefHsOverlays[client] = StringToInt(buffer)
	}
	if(StrEqual(buffer,"")){
		g_bClientPrefHsOverlays[client] = 1;
	}
}
public Action:WelcomeVersion(Handle:timer, any:client){
	if(!IsValidClient(client)) return Plugin_Handled;
	PrintToChat(client, "[★GTA Wasted Effect☆] \x06ver.%s \x01by FoolishBoy", PLUGIN_VERSION);
	PrintToChat(client, "If you want off effect, type !wasted .\x01");
	return Plugin_Handled;
}
public PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_bwasted_enalbed = GetConVarBool(g_hwasted_enalbed);
	new userId = GetEventInt(event, "userid"); 
	new iClient = GetClientOfUserId(userId); 
	new attackerId = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(  GetEventInt( event, "death_flags" ) & TF_DEATHFLAG_DEADRINGER )return;	
	new customkill = GetEventInt(event, "customkill");
	if (IsValidClient(iClient) && IsValidClient(attackerId) && (g_bwasted_enalbed) && (g_bClientPrefHsOverlays[iClient]))
	{
			EmitSoundToClient(iClient, "wasted/wasted.mp3");
			SetClientOverlay(iClient, "wasted/wast");
			
			CreateTimer(GetConVarFloat(g_hTimeOverlay), DeleteOverlay, iClient);
	}
	if (IsValidClient(iClient) && (!g_bwasted_enalbed) && (g_bClientPrefHsOverlays[iClient]))
	{
			EmitSoundToClient(iClient, "wasted/wasted.mp3");
			SetClientOverlay(iClient, "wasted/wast");
			
			CreateTimer(GetConVarFloat(g_hTimeOverlay), DeleteOverlay, iClient);
	}
}
public Action:DeleteOverlay(Handle:hTimer, any:iClient)
{
	if (IsValidClient(iClient)){
		SetClientOverlay(iClient, "");
	}
	return Plugin_Handled;
}

stock bool:IsValidClient(iClient) {
    if (iClient <= 0) return false;
    if (iClient > MaxClients) return false;
    if (!IsClientConnected(iClient)) return false;
    return IsClientInGame(iClient);
}
SetClientOverlay(client, String:strOverlay[])
{
	if (IsValidClient(client)){
		new iFlags = GetCommandFlags("r_screenoverlay") & (~FCVAR_CHEAT);
		SetCommandFlags("r_screenoverlay", iFlags);	
		ClientCommand(client, "r_screenoverlay \"%s\"", strOverlay);
		return true;
	}
	return false;
}
public Action:Command_HsImpact(client, args)
{
	if(!g_bClientPrefHsOverlays[client]){
		g_bClientPrefHsOverlays[client] = 1;
		PrintToChat(client, "ON GTA Wasted Effect");
	}
	else
	if(g_bClientPrefHsOverlays[client]){
		g_bClientPrefHsOverlays[client] = 0;
		PrintToChat(client, "OFF GTA Wasted Effect");
	}
}