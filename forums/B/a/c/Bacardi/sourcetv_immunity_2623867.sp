#define IMMUNITY_LEVEL 98

public void OnPluginStart()
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && IsFakeClient(client)) OnClientPostAdminCheck(client);
	}
}

public void OnClientPostAdminCheck(int client)
{
	if(IsClientReplay(client) || IsClientSourceTV(client))
	{

		AdminId admin = GetUserAdmin(client);

		if(admin != INVALID_ADMIN_ID) return;


		char name[MAX_NAME_LENGTH];
		Format(name, sizeof(name), "%N", client);

		admin = CreateAdmin(name);
		SetAdminImmunityLevel(admin, IMMUNITY_LEVEL);
		SetUserAdmin(client, admin, true);
		PrintToServer("[SM] Immunity Level %i set to %s", IMMUNITY_LEVEL, name);
	}
}

public void OnRebuildAdminCache(AdminCachePart part)
{
	if(part != AdminCache_Admins) return;

	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && IsFakeClient(client)) OnClientPostAdminCheck(client);
	}
}  