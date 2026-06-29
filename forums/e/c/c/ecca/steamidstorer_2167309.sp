#include <sourcemod>
#include <steamtools>

public OnClientAuthorized(client, const String:auth[])
{
	if (IsFakeClient(client)) return;
	
	decl String:sAuth[20];
	Steam_GetCSteamIDForClient(client, sAuth, sizeof(sAuth));
	
	decl String:path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "mysteamids.txt");
	
	new Handle:hndl = OpenFile(path, "a");
	
	WriteFileLine(hndl,"%s", sAuth);
	
	CloseHandle(hndl);
}