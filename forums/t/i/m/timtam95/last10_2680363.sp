
ArrayList ips;

public OnPluginStart() {

	ips = CreateArray(32);

	RegAdminCmd("sm_last10", Command_Last10, 0, "");

}

public OnClientDisconnect(client) {

	char steamid[32];

	if (GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid)) == false || StrContains("STEAM_ID_STOP_IGNORING_RETVALS", steamid, false) != -1) {

		int arraysize = GetArraySize(ips);

		if (arraysize >= 10) {

			RemoveFromArray(ips, 0);

		}

		char ip[32];

		GetClientIP(client, ip, sizeof(ip));
		PushArrayString(ips, ip);

	}

}


public Action Command_Last10(client, args) {

	char ip[32];

	PrintToServer("Last 10 IPs with spoofed Steam IDs");
	for (int i = 0; i < GetArraySize(ips); i++) {

		GetArrayString(ips, i, ip, sizeof(ip))
		PrintToServer(ip);
	}

}