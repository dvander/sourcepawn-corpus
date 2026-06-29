#include <sourcemod>
#include <colors>

#define PLUGIN_VERSION "1.1"

public Plugin:myinfo = {
	name = "Anti Rate Hack",
	author = "Luki",
	description = "This plugin kicks clients who changes their rates too often.",
	version = PLUGIN_VERSION,
	url = "http://luki.net.pl"
};

//#define DEBUG "1"

new String:logfile[255];

new Handle:cvNotifyFlag = INVALID_HANDLE;
new Handle:cvNotifyType = INVALID_HANDLE;
new Handle:cvNotifyThreshold = INVALID_HANDLE;

new Handle:trValues[MAXPLAYERS];

public OnPluginStart() {
	LoadTranslations("antiratehack.phrases");
	
	CreateConVar("sm_antiratehack_version", PLUGIN_VERSION, "", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cvNotifyFlag = CreateConVar("sm_antiratehack_notifyflag", "", "Only people with this flag will see the notice about cheating (empty - everyone)", FCVAR_PLUGIN);
	cvNotifyType = CreateConVar("sm_antiratehack_notifytype", "3", "Notification types: 0 - off 1 - server console, 2 - chat, 4 - player console (can be added up)", FCVAR_PLUGIN);
	cvNotifyThreshold = CreateConVar("sm_antiratehack_notifythreshold", "15", "How many rate changes should be done to show the info on chat and kick the player", FCVAR_PLUGIN);
	
	BuildPath(Path_SM, logfile, sizeof(logfile), "logs/antiratehack.log");
	
	AutoExecConfig();
}

public OnClientPostAdminCheck(client) {
#if defined DEBUG
	PrintToChatAll("OnClientPostAdminCheck; client: %d", client);
#endif
	if(IsFakeClient(client))
		return;
	
	trValues[client] = CreateTrie();
	new String:buff[255];
	GetClientInfo(client, "rate", buff, sizeof(buff));
	SetTrieString(trValues[client], "rate", buff);
	GetClientInfo(client, "cl_cmdrate", buff, sizeof(buff));
	SetTrieString(trValues[client], "cl_cmdrate", buff);
	GetClientInfo(client, "cl_updaterate", buff, sizeof(buff));
	SetTrieString(trValues[client], "cl_updaterate", buff);
	SetTrieValue(trValues[client], "_changecount", 0);
}

public OnClientDisconnect(client) {
#if defined DEBUG
	PrintToChatAll("OnClientDisconnect; client: %d", client);
#endif
	if(IsFakeClient(client) || (trValues[client] == INVALID_HANDLE))
		return;
	
	CloseHandle(trValues[client]);
	trValues[client] = INVALID_HANDLE;
}

public OnClientSettingsChanged(client) {
#if defined DEBUG
	PrintToChatAll("OnClientSettingsChanged; client: %d", client);
#endif
	if(IsFakeClient(client) || (trValues[client] == INVALID_HANDLE))
		return;
	
	new String:rate[255], String:cmdrate[255], String:updrate[255];
	GetClientInfo(client, "rate", rate, sizeof(rate));
	GetClientInfo(client, "cl_cmdrate", cmdrate, sizeof(cmdrate));
	GetClientInfo(client, "cl_updaterate", updrate, sizeof(updrate));
	
	new bool:modified = false, String:buff[255];
	GetTrieString(trValues[client], "rate", buff, sizeof(buff));
	if(strcmp(rate, buff) != 0) {
		modified = true;
		SetTrieString(trValues[client], "rate", rate);
	}
	GetTrieString(trValues[client], "cl_cmdrate", buff, sizeof(buff));
	if(strcmp(cmdrate, buff) != 0) {
		modified = true;
		SetTrieString(trValues[client], "cl_cmdrate", cmdrate);
	}
	GetTrieString(trValues[client], "cl_updaterate", buff, sizeof(buff));
	if(strcmp(updrate, buff) != 0) {
		modified = true;
		SetTrieString(trValues[client], "cl_updaterate", updrate);
	}
	
	if(!modified)
		return;
	
	new changeCount;
	GetTrieValue(trValues[client], "_changecount", changeCount);
	if((++changeCount % GetConVarInt(cvNotifyThreshold)) == 0) {
		//AAA!
		new ntfType = GetConVarInt(cvNotifyType);
		LogToFile(logfile, "%L was kicked for cheating! He changed his rates %d times!", client, changeCount);
		new String:name[255];
		GetClientName(client, name, sizeof(name));
		KickClient(client, "%t", "KickReason");
		if(ntfType == 0)
			return;
		if(ntfType & 0x1)
			PrintToServer("%L was kicked for cheating! He changed his rates %d times!", client, changeCount);
		if((ntfType & 0x2) || (ntfType & 0x4)) {
			new String:ntfFlags[32];
			GetConVarString(cvNotifyFlag, ntfFlags, sizeof(ntfFlags));
			for(new i = 1; i <= MaxClients; i++)
				if(IsClientInGame(i) && !IsFakeClient(i))
					if(HasFlags(i, ntfFlags)) {
						if(ntfType & 0x2)
							CPrintToChat(i, "%t", "KickNotice", name, changeCount); 
						if(ntfType & 0x4)
							PrintToConsole(i, "%t", "KickNotice", name, changeCount);
					}
		}
		SetTrieValue(trValues[client], "_changecount", changeCount);
	}
	else
		SetTrieValue(trValues[client], "_changecount", changeCount);
	
#if defined DEBUG
	PrintToChatAll("changeCount: %d", changeCount);
#endif
}

stock bool:HasFlags(client, const String:flags[]) {
	if(strlen(flags) == 0)
		return true;
	new bits = GetUserFlagBits(client);	
	if (bits & ADMFLAG_ROOT)
		return true;
	new iFlags = ReadFlagString(flags);
	if (bits & iFlags)
		return true;	
	return false;
}