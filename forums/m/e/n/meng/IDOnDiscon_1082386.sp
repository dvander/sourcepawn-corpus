/* STEAM_ID_PRINT_ON_DISCONNECT_SUPER_PRO_by_meng */

public OnClientDisconnect(client)
{
	decl String:sSteamID[32]; GetClientAuthString(client, sSteamID, sizeof(sSteamID));
	PrintToChatAll("%N [%s] has disconnected.", client, sSteamID);
}