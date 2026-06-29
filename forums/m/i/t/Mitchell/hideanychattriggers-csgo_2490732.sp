#pragma semicolon 1
#include <sourcemod>
#include <scp>

ArrayList hiddenChatStrings;
EngineVersion evGame;

public Plugin:myinfo = {
    name = "Hide Any Chat Triggers",
    author = "Mr.Skullbeef | Mitch",
    description = "Hide any chat triggers using SCP.",
    version = "1.0.1",
    url = ""
}

public OnPluginStart() {
	
	evGame = GetEngineVersion();
	
	hiddenChatStrings = new ArrayList(ByteCountToCells(48));

	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "configs/hiddenchattriggers.txt");
	File chatTriggersFile = OpenFile(path, "r");
	char lineBuffer[256];
	while(ReadFileLine(chatTriggersFile, lineBuffer, sizeof(lineBuffer))) {
		ReplaceString(lineBuffer, sizeof(lineBuffer), "\n", "", false); // Remove the "new line" character from each row
		hiddenChatStrings.PushString(lineBuffer);
	}
}

public Action OnChatMessage(int &author, Handle recipients, char[] name, char[] message) {
	char chatTriggerBuffer[256];
	char tempMessage[256];
	strcopy(tempMessage, sizeof(tempMessage), message);
	if(evGame == Engine_CSGO) {
		removeColors(tempMessage, sizeof(tempMessage));
	}
	int stringConBuffer;
	for(int i = 0; i < hiddenChatStrings.Length; i++) {
		hiddenChatStrings.GetString(i, chatTriggerBuffer, sizeof(chatTriggerBuffer));
		stringConBuffer = StrContains(tempMessage, chatTriggerBuffer, true);
		if(stringConBuffer != -1) {
			if(stringConBuffer == 7) {
				if(StrEqual(chatTriggerBuffer[6], " ", true)) {
					return Plugin_Continue;
				}
				return Plugin_Stop;
			} else if(stringConBuffer == 0) {
				return Plugin_Stop;
			}
		}
	}
	return Plugin_Continue;
}

stock void removeColors(char[] szMessage, int maxlength) {
	char tempString[12];
	for(int i = 1; i < 17; i++) {
		Format(tempString, 12, "%c", i);
		ReplaceString(szMessage, maxlength, tempString, "");
	}
}