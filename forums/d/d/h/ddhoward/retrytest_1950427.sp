#include <sourcemod>

public OnPluginStart() {
	RegAdminCmd("sm_retrytest", retryClient, 0, "Forces the player to RETRY connection.");
}

public Action:retryClient(client, args) {
	ClientCommand(client, "retry");
}