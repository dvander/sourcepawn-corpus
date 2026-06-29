#include <sourcemod>

/* This code is licensed under the GNU General Public License, version 2 or greater */

public Plugin:myinfo = 
{
	name = "Restrict SteamIDs",
	author = "BAILOPAN",
	description = "Restricts Steam IDs",
	version = "1.0.0.0",
	url = "http://www.sourcemod.net/"
}

new const String:AUTHMETHOD_RESTRICT[] = "steamid_file"

public OnPluginStart()
{
	/* Register our authentication method */
	CreateAuthMethod(AUTHMETHOD_RESTRICT)
}

public OnRebuildAdminCache(AdminCachePart:part)
{
	if (part == AdminCache_Admins)
	{
		ReadAccounts()
	}
}

public OnClientAuthorized(client, const String:auth[])
{
	if (IsFakeClient(client) || !IsClientConnected(client))
	{
		return
	}
	
	/* Try to find an admin entry */
	new AdminId:id = FindAdminByIdentity(AUTHMETHOD_RESTRICT, auth)
	if (id == INVALID_ADMIN_ID)
	{
		new userid = GetClientUserId(client)
		ServerCommand("kickid %d \"SteamID not allowed\"", userid)
	}
	
	/* Don't bind the admin to the client, we just created it for lookup... */
}

ReadAccounts()
{
	/* Try to open the file */
	new String:path[PLATFORM_MAX_PATH]
	BuildPath(Path_SM, path, sizeof(path), "configs/allowed_steamids.txt")
	
	new Handle:file = OpenFile(path, "rt")
	if (file == INVALID_HANDLE)
	{
		LogError("Could not open file: %s", path)
		return
	}
	
	/* Read the file */
	while (!IsEndOfFile(file))
	{
		decl String:line[255];
		
		if (!ReadFileLine(file, line, sizeof(line)))
		{
			break
		}
		
		/* Ignore things that look like comments or blank lines */
		if ((line[0] == '/' && line[1] == '/')
			|| (line[0] == ';' || line[0] == '\0'))
		{
			continue
		}
	
		ParseLine(line)
	}
	
	/* Remember to close the file */
	CloseHandle(file)
}

ParseLine(const String:line[])
{
	/* Parse the steamid out */
	new String:auth[64]
	BreakString(line, auth, sizeof(auth))
	
	/* See if it's a steam id */
	if (StrContains(auth, "STEAM_") == -1)
	{
		return
	}
	
	/* Create and bind an anonymous admin with this steamid */
	new AdminId:id = CreateAdmin()
	BindAdminIdentity(id, AUTHMETHOD_RESTRICT, auth)
}