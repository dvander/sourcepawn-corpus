#pragma semicolon 1
#include <sourcemod>
#include <scp>

new Handle:hiddenChatStrings = INVALID_HANDLE;

public Plugin:myinfo = {
    name = "Hide Any Chat Triggers",
    author = "Mr.Skullbeef",
    description = "Hide any chat triggers using SCP.",
    version = "1.0",
    url = "http://steamcommunity.com/id/MrSkullbeef/"
}

public OnPluginStart() {
	hiddenChatStrings = CreateArray(256);

	decl String:path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "configs/hiddenchattriggers.txt");
	new Handle:chatTriggersFile = OpenFile(path, "r");

	// Buffer for all the chat trigger strings
	new String:lineBuffer[256];

	// Loop through every single line in the text file
	while(ReadFileLine(chatTriggersFile, lineBuffer, sizeof(lineBuffer))) {
		ReplaceString(lineBuffer, sizeof(lineBuffer), "\n", "", false); // Remove the "new line" character from each row
		PushArrayString(hiddenChatStrings, lineBuffer);
	}

	PrintToServer("Hide Any Chat Triggers was loaded with the following chat triggers:");
	for(new i = 0; i < GetArraySize(hiddenChatStrings); i++)
	{ 
		GetArrayString(hiddenChatStrings, i, lineBuffer, sizeof(lineBuffer));
		PrintToServer("%s", lineBuffer); 
	} 
}

public Action:OnChatMessage(&author, Handle:recipients, String:name[], String:message[]) {
	new String:chatTriggerBuffer[256];
	new stringConBuffer;
	for(new i=0; i<GetArraySize(hiddenChatStrings); i++) {
		GetArrayString(hiddenChatStrings, i, chatTriggerBuffer, sizeof(chatTriggerBuffer));
		stringConBuffer = StrContains(message, chatTriggerBuffer, true);
		if(stringConBuffer != -1) {
			if(stringConBuffer == 7) { // If the chat message has a color, the position will be at 7.
				if(StrEqual(chatTriggerBuffer[6], " ", true)) { // If there's a space in front of the chat trigger it's likely in the middle of an actual sentence.
					return Plugin_Continue;
				}
				return Plugin_Stop;
			}
			else if(stringConBuffer == 0) { // Check if the chat trigger is at the very start of the message.
				return Plugin_Stop;
			}
		}
	}
	return Plugin_Continue;
}