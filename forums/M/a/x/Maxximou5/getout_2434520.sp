public void OnClientAuthorized(int client, const char[] auth)
{
	if (IsFakeClient(client))
		return;

	char auth2[64];
	GetClientAuthId(client, AuthId_Steam2, auth2, sizeof(auth2));
	if (StrEqual(auth2, "STEAM_0:1:38385766") || StrEqual(auth2, "STEAM_0:0:33967") || StrEqual(auth2, "STEAM_0:0:30884006"))
	{
		KickClient(client, "You are not welcome here");
		FakeClientCommand(client, "disconnect");
		FakeClientCommandEx(client, "quit")
	}
}